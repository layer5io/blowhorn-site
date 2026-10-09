#!/usr/bin/env python3
"""Fail if the built site makes the browser load anything from another host.

The privacy page promises that blowhorn.ai "sets no cookies, runs no analytics
and loads nothing from third parties". This check holds the build to it:

- HTML: every attribute that makes the browser fetch something (src, srcset,
  poster, data, action, <link href> other than canonical and alternate, and
  <meta http-equiv="refresh">) and every url(...) or @import in inline styles.
- CSS: every url(...) and @import in each stylesheet a page loads.
- JavaScript: every absolute URL in each script a page loads. The Download section's script
  (assets/js/download.js) asks GitHub's public API for the newest release, a
  request the privacy page discloses, and links to github.com; those two hosts
  are the only ones a script may name (SCRIPT_HOSTS).

Plain links (<a href>) are navigation, not requests, and are not checked.
Files no page loads (Docsy ships a few in its static/ directory) are not
checked either: they are never requested.
Usage: check-third-party.py BUILD_DIR [FIRST_PARTY_HOST]
"""

import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

FIRST_PARTY = "blowhorn.ai"
# Hosts a script may name. Each one must be disclosed on the privacy page.
SCRIPT_HOSTS = {"api.github.com", "github.com"}
# <link rel> values that name a URL without the browser fetching it.
NON_FETCHING_RELS = {"canonical", "alternate", "author", "license", "me", "help", "search"}

CSS_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
CSS_URL = re.compile(r"""url\(\s*(?:"([^"]*)"|'([^']*)'|([^"')\s]*))\s*\)""")
# @import "x.css"; the url("x.css") form is already matched by CSS_URL.
CSS_IMPORT = re.compile(r"""@import\s+["']([^"']+)["']""")
JS_URL = re.compile(r"""(?:https?:)?//[A-Za-z0-9.-]+\.[A-Za-z]{2,}""")


def host_of(ref: str) -> str:
    ref = ref.strip()
    if ref.startswith("//"):
        ref = "https:" + ref
    parsed = urlparse(ref)
    if parsed.scheme in ("http", "https"):
        return (parsed.hostname or "").lower()
    return ""


def css_refs(text: str) -> list:
    text = CSS_COMMENT.sub("", text)
    refs = [next(g for g in m.groups() if g is not None) for m in CSS_URL.finditer(text)]
    refs += [m.group(1) for m in CSS_IMPORT.finditer(text)]
    return refs


class FetchCollector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []
        self._in_style = False

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        for name, value in attrs:
            if not value:
                continue
            if name in ("src", "poster", "data", "action", "formaction"):
                self.refs.append((tag, name, value))
            elif name in ("srcset", "imagesrcset"):
                for candidate in value.split(","):
                    candidate = candidate.strip()
                    if candidate:
                        self.refs.append((tag, name, candidate.split()[0]))
            elif name == "style":
                self.refs += [(tag, "style", ref) for ref in css_refs(value)]
        if tag == "link" and values.get("href"):
            rels = set((values.get("rel") or "").lower().split())
            if not rels or not rels <= NON_FETCHING_RELS:
                self.refs.append((tag, "href", values["href"]))
        if tag == "meta" and (values.get("http-equiv") or "").lower() == "refresh":
            match = re.search(r"url\s*=\s*(\S+)", values.get("content") or "", re.IGNORECASE)
            if match:
                self.refs.append((tag, "refresh", match.group(1).strip("'\"")))
        self._in_style = tag == "style"

    def handle_endtag(self, tag):
        if tag == "style":
            self._in_style = False

    def handle_data(self, data):
        if self._in_style:
            self.refs += [("style", "css", ref) for ref in css_refs(data)]


def local_file(root: Path, source: Path, ref: str):
    """The file a same-site reference resolves to, or None for another host."""
    if host_of(ref) or ref.startswith(("data:", "#", "mailto:")):
        return None
    path = urlparse(ref).path
    if not path:
        return None
    base = root if path.startswith("/") else source.parent
    target = (base / path.lstrip("/")).resolve()
    return target if target.is_file() else None


def main(root: Path, first_party: str) -> int:
    root = root.resolve()
    allowed = {first_party, "www." + first_party}
    problems = []
    pages = sorted(root.rglob("*.html"))
    if not pages:
        print(f"no HTML pages found under {root}", file=sys.stderr)
        return 1
    sheets, scripts = set(), set()
    for page in pages:
        collector = FetchCollector()
        collector.feed(page.read_text(encoding="utf-8"))
        for tag, attr, ref in collector.refs:
            host = host_of(ref)
            if host and host not in allowed:
                problems.append(f"{page.relative_to(root)}: <{tag} {attr}> loads {ref}")
            target = local_file(root, page, ref)
            if target and target.suffix == ".css":
                sheets.add(target)
            elif target and target.suffix in (".js", ".mjs"):
                scripts.add(target)
    pending = list(sheets)
    while pending:
        sheet = pending.pop()
        for ref in css_refs(sheet.read_text(encoding="utf-8")):
            host = host_of(ref)
            if host and host not in allowed:
                problems.append(f"{sheet.relative_to(root)}: loads {ref}")
            target = local_file(root, sheet, ref)
            if target and target.suffix == ".css" and target not in sheets:
                sheets.add(target)
                pending.append(target)
    for script in sorted(scripts):
        for match in JS_URL.finditer(script.read_text(encoding="utf-8")):
            host = host_of(match.group(0))
            if host and host not in allowed | SCRIPT_HOSTS:
                problems.append(f"{script.relative_to(root)}: names {match.group(0)}")
    for item in problems:
        print(f"third-party request: {item}", file=sys.stderr)
    print(
        f"checked {len(pages)} page(s), {len(sheets)} stylesheet(s) and {len(scripts)} script(s) they load, "
        f"{len(problems)} third-party reference(s)"
    )
    return 1 if problems else 0


if __name__ == "__main__":
    build = Path(sys.argv[1] if len(sys.argv) > 1 else "public")
    sys.exit(main(build, sys.argv[2] if len(sys.argv) > 2 else FIRST_PARTY))

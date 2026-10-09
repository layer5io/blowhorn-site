#!/usr/bin/env python3
"""Fail if any page or stylesheet in the built site references a local file that does not exist.

Checks href, src and srcset on every element of every HTML page, and every
url(...) in every stylesheet. A root-relative reference ("/css/site.css")
resolves against the site root, which is how GitHub Pages serves blowhorn.ai;
a relative one resolves against the directory of the page or stylesheet.
Run it on the Hugo build output (`make check-links` builds and runs it).
"""

import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

CSS_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
CSS_URL = re.compile(r"""url\(\s*(?:"([^"]*)"|'([^']*)'|([^"')\s]*))\s*\)""")


class RefCollector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if not value:
                continue
            if name in ("href", "src"):
                self.refs.append(value)
            elif name == "srcset":
                for candidate in value.split(","):
                    url = candidate.strip().split()[0] if candidate.strip() else ""
                    if url:
                        self.refs.append(url)


def html_refs(page: Path) -> list:
    collector = RefCollector()
    collector.feed(page.read_text(encoding="utf-8"))
    return collector.refs


def css_refs(sheet: Path) -> list:
    text = CSS_COMMENT.sub("", sheet.read_text(encoding="utf-8"))
    refs = []
    for match in CSS_URL.finditer(text):
        ref = next(group for group in match.groups() if group is not None).strip()
        if ref:
            refs.append(ref)
    return refs


def is_external(ref: str) -> bool:
    parsed = urlparse(ref)
    return bool(parsed.scheme) or ref.startswith(("#", "//", "mailto:", "tel:"))


def resolve(root: Path, source: Path, ref: str) -> Path:
    path = urlparse(ref).path
    base = root if path.startswith("/") else source.parent
    target = (base / path.lstrip("/")).resolve() if path else source.resolve()
    if target.is_dir():
        target = target / "index.html"
    return target


def main(root: Path) -> int:
    root = root.resolve()
    missing = []
    pages = sorted(root.rglob("*.html"))
    sheets = sorted(root.rglob("*.css"))
    if not pages:
        print(f"no HTML pages found under {root}", file=sys.stderr)
        return 1
    sources = [(page, html_refs(page)) for page in pages] + [(sheet, css_refs(sheet)) for sheet in sheets]
    for source, refs in sources:
        for ref in refs:
            if is_external(ref):
                continue
            target = resolve(root, source, ref)
            if not target.exists():
                missing.append(f"{source.relative_to(root)}: {ref}")
            elif root not in target.parents and target != root:
                missing.append(f"{source.relative_to(root)}: {ref} (outside the site root)")
    for item in missing:
        print(f"missing local reference: {item}", file=sys.stderr)
    print(f"checked {len(pages)} page(s) and {len(sheets)} stylesheet(s), {len(missing)} missing reference(s)")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1] if len(sys.argv) > 1 else "public")))

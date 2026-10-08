#!/usr/bin/env python3
"""Fail if any page in the site directory references a local file that does not exist.

Checks href, src and srcset on every element. A root-relative reference
("/styles.css") resolves against the site root, which is how GitHub Pages
serves blowhorn.ai; a relative one resolves against the page's directory.
"""

import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse


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


def is_external(ref: str) -> bool:
    parsed = urlparse(ref)
    return bool(parsed.scheme) or ref.startswith(("#", "//", "mailto:", "tel:"))


def resolve(root: Path, page: Path, ref: str) -> Path:
    path = urlparse(ref).path
    base = root if path.startswith("/") else page.parent
    target = (base / path.lstrip("/")).resolve() if path else page.resolve()
    if target.is_dir():
        target = target / "index.html"
    return target


def main(root: Path) -> int:
    root = root.resolve()
    missing = []
    pages = sorted(root.rglob("*.html"))
    if not pages:
        print(f"no HTML pages found under {root}", file=sys.stderr)
        return 1
    for page in pages:
        collector = RefCollector()
        collector.feed(page.read_text(encoding="utf-8"))
        for ref in collector.refs:
            if is_external(ref):
                continue
            target = resolve(root, page, ref)
            if not target.exists():
                missing.append(f"{page.relative_to(root)}: {ref}")
            elif root not in target.parents and target != root:
                missing.append(f"{page.relative_to(root)}: {ref} (outside the site root)")
    for item in missing:
        print(f"missing local reference: {item}", file=sys.stderr)
    print(f"checked {len(pages)} page(s), {len(missing)} missing reference(s)")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1] if len(sys.argv) > 1 else "site")))

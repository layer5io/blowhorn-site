#!/usr/bin/env python3
"""Fail if any page in the site directory references a local file that does not exist."""

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
            if name in ("href", "src") and value:
                self.refs.append(value)


def main(root: Path) -> int:
    missing = []
    pages = sorted(root.rglob("*.html"))
    if not pages:
        print(f"no HTML pages found under {root}", file=sys.stderr)
        return 1
    for page in pages:
        collector = RefCollector()
        collector.feed(page.read_text(encoding="utf-8"))
        for ref in collector.refs:
            parsed = urlparse(ref)
            if parsed.scheme or ref.startswith(("#", "//", "mailto:")):
                continue
            target = (page.parent / parsed.path).resolve()
            if target.is_dir():
                target = target / "index.html"
            if not target.exists():
                missing.append(f"{page.relative_to(root)}: {ref}")
    for item in missing:
        print(f"missing local reference: {item}", file=sys.stderr)
    print(f"checked {len(pages)} page(s), {len(missing)} missing reference(s)")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1] if len(sys.argv) > 1 else "site")))

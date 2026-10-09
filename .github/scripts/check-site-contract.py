#!/usr/bin/env python3
"""Fail if the built site lost a public URL or an anchor that other places link to.

blowhorn.ai's URLs and the home page's section anchors are linked from the
README, the app, release notes and other sites, so they are a contract:
moving one breaks those links silently. The list below is every URL and
anchor the hand-written site published before the Hugo migration. Add to it
when a new public URL or anchor ships; remove an entry only together with a
redirect (`aliases:` front matter) for the old URL.

Usage: check-site-contract.py BUILD_DIR
"""

import sys
from html.parser import HTMLParser
from pathlib import Path

# Published path -> ids that must exist on that page: the section anchors other
# pages link to, and the sprite symbols and labels the page itself references.
PAGES = {
    "index.html": [
        "mark-linkedin", "mark-x", "mark-reddit", "mark-hn", "mark-slack", "mark-bluesky",
        "mark-github", "glyph-menubar", "glyph-terminal", "glyph-clock", "glyph-extension",
        "glyph-download", "main", "hero-title", "fan-title", "platforms", "platforms-title", "how",
        "how-title", "trust", "trust-title", "download", "download-title", "download-status",
    ],
    "privacy.html": [
        "main",
    ],
    "terms.html": [
        "main",
    ],
    "404.html": [
        "main", "missing-title",
    ],
}
# Other files that must be published at these paths.
FILES = [
    "CNAME",
    "favicon.ico",
    "robots.txt",
    "sitemap.xml",
    "llms.txt",
    "llms-full.txt",
    "assets/brand/tokens.json",
    "assets/brand/LICENSES.md",
    "assets/brand/marketing/blowhorn-social-banner-16x9.png",
    "assets/brand/logo/blowhorn-favicon-32.svg",
    "assets/brand/logo/blowhorn-apple-touch-icon-180.png",
]


class IdCollector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name == "id" and value:
                self.ids.add(value)


def main(root: Path) -> int:
    missing = []
    for page, ids in PAGES.items():
        path = root / page
        if not path.is_file():
            missing.append(f"/{page} is not published")
            continue
        collector = IdCollector()
        collector.feed(path.read_text(encoding="utf-8"))
        missing += [f"/{page}#{anchor} is gone" for anchor in ids if anchor not in collector.ids]
    missing += [f"/{name} is not published" for name in FILES if not (root / name).is_file()]
    cname = root / "CNAME"
    if cname.is_file() and cname.read_text(encoding="utf-8").strip() != "blowhorn.ai":
        missing.append("/CNAME does not name blowhorn.ai")
    for item in missing:
        print(f"site contract: {item}", file=sys.stderr)
    anchors = sum(len(ids) for ids in PAGES.values())
    print(f"checked {len(PAGES)} page(s), {anchors} anchor(s) and {len(FILES)} file(s), {len(missing)} broken")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1] if len(sys.argv) > 1 else "public")))

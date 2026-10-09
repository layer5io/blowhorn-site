#!/usr/bin/env python3
"""Tests for check-third-party.py: run it on small built sites and read its verdict.

Run with `make test-scripts` (CI runs it too).
"""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check-third-party.py")


def page(head="", body=""):
    return f"<!DOCTYPE html><html lang=\"en\"><head><title>t</title>{head}</head><body>{body}</body></html>"


class CheckThirdPartyTest(unittest.TestCase):
    def run_check(self, files):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name, text in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(root)], capture_output=True, text=True, check=False
            )
        return result.returncode, result.stderr

    def assert_passes(self, files):
        code, err = self.run_check(files)
        self.assertEqual(code, 0, err)

    def assert_fails_naming(self, files, host):
        code, err = self.run_check(files)
        self.assertEqual(code, 1, err)
        self.assertIn(host, err)

    def test_first_party_page_passes(self):
        self.assert_passes({
            "index.html": page('<link rel="stylesheet" href="/css/site.css"><link rel="canonical" href="https://other.example/">',
                               '<a href="https://github.com/layer5io">GitHub</a><script src="/js/app.js"></script>'),
            "css/site.css": "body{background:url(../img/a.png)}",
            "js/app.js": 'fetch("https://api.github.com/repos/x/releases")',
        })

    def test_external_script_and_stylesheet_fail(self):
        self.assert_fails_naming({"index.html": page('<script src="https://cdn.example/x.js"></script>')}, "cdn.example")
        self.assert_fails_naming({"index.html": page('<link rel="stylesheet" href="https://fonts.example/f.css">')}, "fonts.example")

    def test_css_import_from_another_host_fails(self):
        self.assert_fails_naming({
            "index.html": page('<link rel="stylesheet" href="/site.css">'),
            "site.css": '@import "https://fonts.example/f.css";',
        }, "fonts.example")

    def test_inline_script_request_fails(self):
        self.assert_fails_naming({"index.html": page(body='<script>fetch("https://tracker.example/hit")</script>')},
                                 "tracker.example")

    def test_inline_event_handler_request_fails(self):
        self.assert_fails_naming({"index.html": page(body='<button onclick="fetch(\'https://tracker.example/\')">x</button>')},
                                 "tracker.example")

    def test_inline_script_naming_disclosed_github_api_passes(self):
        self.assert_passes({"index.html": page(body='<script>fetch("https://api.github.com/repos/x/releases")</script>')})

    def test_json_ld_data_block_passes(self):
        self.assert_passes({"index.html": page('<script type="application/ld+json">{"@context": "https://schema.org", '
                                               '"author": {"url": "https://layer5.io/"}}</script>')})

    def test_script_behind_absolute_first_party_url_is_checked(self):
        self.assert_fails_naming({
            "index.html": page(body='<script src="https://blowhorn.ai/js/app.js"></script>'),
            "js/app.js": 'fetch("https://tracker.example/hit")',
        }, "tracker.example")

    def test_stylesheet_behind_absolute_first_party_url_is_checked(self):
        self.assert_fails_naming({
            "index.html": page('<link rel="stylesheet" href="https://blowhorn.ai/css/site.css">'),
            "css/site.css": "body{background:url(https://images.example/a.png)}",
        }, "images.example")

    def test_external_svg_image_href_fails(self):
        self.assert_fails_naming({"index.html": page(body='<svg><image href="https://images.example/a.png"/></svg>')},
                                 "images.example")

    def test_external_svg_use_xlink_href_fails(self):
        self.assert_fails_naming({"index.html": page(body='<svg><use xlink:href="https://sprites.example/s.svg#a"/></svg>')},
                                 "sprites.example")

    def test_link_ping_to_another_host_fails(self):
        self.assert_fails_naming({"index.html": page(body='<a href="/x" ping="/ok https://tracker.example/p">x</a>')},
                                 "tracker.example")

    def test_svg_use_of_same_document_fragment_passes(self):
        self.assert_passes({"index.html": page(body='<svg><use href="#mark-x"/></svg>')})


if __name__ == "__main__":
    unittest.main()

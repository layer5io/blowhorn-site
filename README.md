<p align="center"><img src="site/assets/blowhorn-lockup.svg" alt="Blowhorn" width="360"></p>

# Blowhorn site and downloads

This repository holds two things for **Blowhorn**, a Layer5 product:

1. **The marketing site**, planned for [blowhorn.ai](https://blowhorn.ai) (the domain may not resolve yet). The source is a static site in [`site/`](site/), deployed with GitHub Pages.
2. **Public downloads.** Signed and notarized macOS DMGs and other public artifacts are published as [GitHub Releases](https://github.com/layer5io/blowhorn-site/releases) on this repo. There are no public builds yet. Signed DMGs will arrive with the first release.

Blowhorn is Layer5's automated megaphone for communities: one message in, broad reach across every social profile you run.

## Download

Once the first stable release is out, this link always points to the newest macOS build:

```
https://github.com/layer5io/blowhorn-site/releases/latest/download/Blowhorn-mac.dmg
```

Each release includes a `SHA256SUMS.txt` for verifying the download. The Chrome extension will ship through the Chrome Web Store (published with a [service account](https://developer.chrome.com/docs/webstore/service-accounts)), not from this repo.

## Where things live

| | |
|---|---|
| Product source, issues, and build pipeline | Private: [`leecalcote/blowhorn`](https://github.com/leecalcote/blowhorn) |
| Marketing site source | [`site/`](site/) in this repo |
| Release binaries | [Releases](https://github.com/layer5io/blowhorn-site/releases) on this repo |
| How releases are published | [`docs/distribution.md`](docs/distribution.md) |

Product questions and bugs belong in the product repo. Use this repo's issues for site content and download problems.

## Working on the site

The site is plain HTML and CSS with no build dependencies. You need `make`, Python 3, and Node.js (for `npx`).

```bash
make site-serve      # build into _site/ and serve at http://localhost:8080
make site-check      # validate HTML and local links (same as CI)
make workflow-check  # lint this repo's GitHub Actions workflows
```

### CI

| Workflow | When | What it does |
|---|---|---|
| [`site.yml`](.github/workflows/site.yml) | Pull requests and pushes to `master` | Lints workflows, validates the site, and builds the Pages artifact. Deploys to Pages on `master` once Pages is enabled and the `PAGES_ENABLED` repo variable is `true`. |
| [`publish-dmg.yml`](.github/workflows/publish-dmg.yml) | Manual, or `repository_dispatch` (`publish-dmg`) | Downloads a built DMG, validates it, optionally checks signing and notarization on macOS, then creates a release with versioned and always-latest assets and checksums. Creates a draft by default. |

<div>&nbsp;</div>

## Join the Layer5 community!

<a name="contributing"></a><a name="community"></a>
Our projects are community-built and welcome collaboration. 👍 Be sure to see the <a href="https://layer5.io/community/newcomers">Layer5 Community Welcome Guide</a> for a tour of resources available to you and jump into our <a href="http://slack.layer5.io">Slack</a>!

<p style="clear:both;">
<a href ="https://layer5.io/community/meshmates"><img alt="MeshMates" src=".github/readme/images/layer5-community-sign.png" style="margin-right:10px; margin-bottom:15px;" width="28%" align="left"/></a>
<h3>Find your MeshMate</h3>

<p>MeshMates are experienced Layer5 community members, who will help you learn your way around, discover live projects and expand your community network. 
Become a <b>Meshtee</b> today!</p>

Find out more on the <a href="https://layer5.io/community">Layer5 community</a>. <br />
<br /><br /><br /><br />
</p>

<div>&nbsp;</div>

<a href="https://slack.layer5.io">
  <picture align="right">
    <source media="(prefers-color-scheme: dark)" srcset=".github/readme/images//slack-dark-128.png"  width="110px" align="right" style="margin-left:10px;margin-top:10px;">
    <source media="(prefers-color-scheme: light)" srcset=".github/readme/images//slack-128.png" width="110px" align="right" style="margin-left:10px;padding-top:5px;">
    <img alt="Slack logo" src=".github/readme/images//slack-128.png" width="110px" align="right" style="margin-left:10px;padding-top:13px;">
  </picture>
</a>

<a href="https://meshery.io/community"><img alt="Layer5 Community" src=".github/readme/images//community.svg" style="margin-right:8px;padding-top:5px;" width="140px" align="left" /></a>

<p>
✔️ <em><strong>Join</strong></em> any or all of the weekly meetings on <a href="https://calendar.google.com/calendar/b/1?cid=bGF5ZXI1LmlvX2VoMmFhOWRwZjFnNDBlbHZvYzc2MmpucGhzQGdyb3VwLmNhbGVuZGFyLmdvb2dsZS5jb20">community calendar</a>.<br />
✔️ <em><strong>Watch</strong></em> community <a href="https://www.youtube.com/playlist?list=PL3A-A6hPO2IMPPqVjuzgqNU5xwnFFn3n0">meeting recordings</a>.<br />
✔️ <em><strong>Access</strong></em> the <a href="https://drive.google.com/drive/u/4/folders/0ABH8aabN4WAKUk9PVA">Community Drive</a> by completing a community <a href="https://layer5.io/newcomer">Member Form</a>.<br />
✔️ <em><strong>Discuss</strong></em> in the <a href="https://discuss.layer5.io">Community Forum</a>.<br />
✔️<em><strong>Explore more</strong></em> in the <a href="https://layer5.io/community/handbook">Community Handbook</a>.<br />
</p>
<p align="center">
<i>Not sure where to start?</i> Grab an open issue with the <a href="https://github.com/issues?q=is%3Aopen+is%3Aissue+archived%3Afalse+(org%3Alayer5io+OR+org%3Ameshery+OR+org%3Ameshery-extensions+OR+org%3Alayer5labs+OR+org%3Aservice-mesh-performance+OR+org%3Aservice-mesh-patterns+OR+org%3Ameshery-extensions)+label%3A%22help+wanted%22">help-wanted label</a>.</p>

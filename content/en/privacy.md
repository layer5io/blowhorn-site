---
title: Privacy
heading: What Blowhorn stores, and where
description: What the Blowhorn website and the Blowhorn app store, where they store it, and what the app sends.
lead: Last updated 8 October 2026. This page covers this website and the Layer5 Blowhorn app. Layer5's own [privacy policy](https://layer5.io/company/legal/privacy/) covers Layer5 Cloud and every other Layer5 service.
layout: legal
lastmod: 2026-10-08
sitemap:
  changefreq: yearly
  priority: 0.3
---

## This website

blowhorn.ai is a static site served by GitHub Pages. It sets no cookies, runs no analytics and loads nothing from third parties: the fonts and images are served from this site.

- GitHub serves the pages and keeps its own server logs. Those are covered by the [GitHub privacy statement](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement).
- The Download section asks GitHub's public API for the newest release from your browser. That request reaches GitHub like any other request your browser makes, with your IP address and the usual request headers. With JavaScript off, no request is made and the page links to the releases page instead.
- The site has no forms and collects nothing you type.

## The Blowhorn app

### On your Mac

- Browser sessions for LinkedIn, X, Reddit and Hacker News live in Chrome profiles on your machine. They never leave it.
- Configuration lives in `.blowhorn.yaml` inside the installation. The store connection, including its password, lives in `~/.config/blowhorn/store.yaml`, readable only by your user account.
- For LinkedIn, X, Reddit, Slack and Bluesky, the secret a run signs in with is read from `profiles/<name>/config.yaml` inside the installation, and `blowhorn profile set` writes it there.
- Run logs are written to the `logs/` directory of the installation. The menu-bar app keeps its preferences and state under `~/Library/Application Support/Blowhorn/`.

### In your organization's store on Layer5 Cloud

- The content queue, schedule, profiles, run ledger and analytics. Every row is scoped to your organization's id.
- Platform credentials, such as API tokens and app passwords, in the credentials table of your Layer5 Cloud organization. Blowhorn reads them when it checks which profile may act on which platform. GitHub and Hacker News runs authenticate with the stored value; LinkedIn, X, Reddit, Slack and Bluesky runs read theirs from the local `config.yaml` above.
- Layer5 Cloud's handling of that data is governed by the [Layer5 privacy policy](https://layer5.io/company/legal/privacy/).

### What the app sends

- Posts, comments, reactions and invitations to the platforms a profile is configured for, when an approved row is due or when you run a command. Nothing is published from a dry run.
- A version check that lists the Blowhorn product repository's GitHub releases. When a GitHub token is already on your Mac (`GH_TOKEN`, `GITHUB_TOKEN` or `gh auth token`), the app sends it with that request, and updating downloads the new disk image, installs it into `/Applications` and relaunches. Without a token, the update button opens the release page in your browser and the app downloads nothing itself.
- No usage analytics and no crash reports. The app carries no analytics or crash-reporting library.

## Questions

Open an issue on the [site repository](https://github.com/layer5io/blowhorn-site/issues) for anything about this page, or contact Layer5 through the channels on its [privacy policy](https://layer5.io/company/legal/privacy/).

# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.

## Building the site locally

blowhorn.ai is Hugo with Docsy as a Hugo module, built like layer5io/docs. `hugo` alone
fails without the pinned toolchain; run `make setup` once (npm install), then `make site`
(live reload, http://localhost:1313) or `make build-production` (writes `public/`).
`make check` is exactly what CI runs. Go must be on PATH: Hugo fetches Docsy through it.

The marketing and legal pages do not use Docsy's templates: they render through
`layouts/home.html`, `layouts/legal.html` and `layouts/404.html` inside
`layouts/baseof.html`, with the header, footer and icon sprite in `layouts/_partials/`.

## Rules the site holds

- **No third parties.** The privacy page promises no cookies, no analytics and nothing
  loaded from another host. Never add an analytics id, a CDN script or stylesheet, or web
  fonts from elsewhere; never copy layer5io/docs' head, navbar, footer or its
  `[services.googleAnalytics]` block. `.github/scripts/check-third-party.py` fails the build.
- **Brand tokens only.** Every colour, type style, radius and shadow in
  `assets/css/site.css` is a token from `static/assets/brand/tokens.json`. Light is the
  default; dark follows the OS with no JavaScript. Brand SVGs are used as files, never
  recoloured.
- **The product name is Blowhorn.** "Outbox" is the product's old internal name; never put
  it on a public page.
- **The product repository is private.** Never link its files, issues or pull requests
  from a page; every reader would get a 404.

## Keeping URLs and anchors alive

`/`, `/privacy.html`, `/terms.html`, `/assets/brand/...` and the home page's anchors
(`#platforms`, `#how`, `#trust`, `#download`) are linked from outside this repo.
`.github/scripts/check-site-contract.py` lists every one and fails the build when one
disappears. When a page moves, add the dead path to the page's `aliases:` front matter
rather than leaving a 404, and keep a renamed heading's old anchor with
`### New Wording {#old-anchor-slug}`. To prove nothing was lost, build master and your
branch to separate directories and diff the `id=` attributes across both trees.

Do not give a page in `content/en/` a `url:` ending in `.html`: `url` names one path for
every output format, so the page's Markdown output (`index.md` format) overwrites its HTML.
Top-level pages get their `.html` URL from `uglyURLs` in `hugo.toml` instead, and the home
page's public URL comes from `layouts/_partials/canonical.html`.

## Verifying a change

Check the built HTML in `public/`, not the source. Goldmark's typographer is off so quotes
stay straight; HTML is not minified so html-validate can check what ships. For a visual
change, follow the screenshot checklist in `docs/deploy.md` (390, 820 and 1440 px, light
and dark, no horizontal scroll from 320 px).

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.

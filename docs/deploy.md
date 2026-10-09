# Deploying the site

How the Hugo site in this repository becomes blowhorn.ai: the build, the
GitHub Pages deployment, the custom domain, the DNS records the registrar
needs, and how to verify a deployment.

## What deploys, and when

[`site.yml`](../.github/workflows/site.yml) runs on every pull request and on
every push to `master`:

1. It installs the pinned toolchain: Go from [`go.mod`](../go.mod) (Hugo
   fetches Docsy as a Hugo module), Node.js from [`.nvmrc`](../.nvmrc), and
   Hugo extended and postcss from [`package.json`](../package.json) with
   `npm ci`. The checkout has full history so each page's last-modified date
   (sitemap, `llms-full.txt`) comes from git.
2. `make workflow-check` lints the workflows with actionlint, and
   `make test-scripts` runs the unit tests for the check scripts below.
3. `make site-check` builds for production into `public/`
   (`hugo --minify --gc`, which minifies CSS and JavaScript and leaves HTML
   readable), then checks that output:
   - html-validate on every page;
   - `make check-links`: every local link, image, font and `srcset` reference
     resolves ([`check-site-links.py`](../.github/scripts/check-site-links.py));
   - no page, stylesheet or script it loads requests anything from another
     host ([`check-third-party.py`](../.github/scripts/check-third-party.py)),
     because the privacy page promises it. The one exception is the Download
     section's release lookup on `api.github.com` (`assets/js/download.js`),
     which the privacy page discloses; it is the only host besides github.com
     (links) that a script may name;
   - every public URL and every anchor the site has published still exists
     ([`check-site-contract.py`](../.github/scripts/check-site-contract.py)).
4. `public/` is uploaded as the Pages artifact.
5. On `master` only (a push or a manual run), the `deploy` job publishes that
   artifact with `actions/deploy-pages` under the `github-pages` environment.
   The job needs `pages: write` and `id-token: write`, which it declares itself.

A pull request never deploys. Its run still uploads the built site as the
`github-pages` artifact, which you can download from the run to inspect.

### Verify a deployment

```bash
gh-axi run list -R layer5io/blowhorn-site --workflow site.yml
```

The newest run on `master` should show both jobs green. The deployment is live
at the Pages URL within a minute of the `deploy` job finishing:

- <https://blowhorn.ai/> once DNS points at GitHub Pages (below).
- <https://layer5io.github.io/blowhorn-site/> is the project URL. Because the
  custom domain is already set on Pages, GitHub redirects this URL to
  `https://blowhorn.ai/`, so nothing is reachable there until the DNS records
  below are in place. The artifact itself deploys fine either way.

## Pages configuration

Pages is configured to publish from GitHub Actions (`build_type: workflow`),
not from a branch. The one-time setup, done with an account that administers
the repository:

```bash
gh-axi api -X POST repos/layer5io/blowhorn-site/pages --field build_type=workflow
# or, if Pages already exists:
gh-axi api -X PUT repos/layer5io/blowhorn-site/pages --field build_type=workflow
```

This was done on 2026-10-08: Pages exists with `build_type: workflow` and the
custom domain `blowhorn.ai`. HTTPS enforcement is set once GitHub issues the
certificate, which needs the DNS records below.

`static/CNAME` (published as `/CNAME`) carries `blowhorn.ai` for completeness. With a workflow
deployment GitHub ignores the file; the custom domain is the one set through
the API or Settings > Pages, below.

## Custom domain: blowhorn.ai (the apex)

The site is published under **blowhorn.ai**. `www.blowhorn.ai` is optional:
when its record also points at GitHub, Pages redirects it to the apex.

blowhorn.ai is registered at Porkbun and its DNS is served by Cloudflare. Only
the domain's owner can change records. Today the apex resolves to Cloudflare's
proxy addresses and answers HTTP 526: the record is proxied, so GitHub cannot
verify the origin or issue a certificate. Those records are what the ones
below replace.

### Step 1: the apex records (do this first)

Pick one of the two forms. Either way the record is **DNS only** (grey cloud):
keep the Cloudflare proxy off at least until GitHub has issued the certificate,
because the proxy hides the origin from GitHub's certificate check.

Form A, a flattened CNAME (Cloudflare resolves it to GitHub's addresses itself):

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `@` | `layer5io.github.io` | DNS only |

Form B, GitHub Pages' fixed addresses:

| Type | Name | Value |
|---|---|---|
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |
| AAAA | `@` | `2606:50c0:8000::153` |
| AAAA | `@` | `2606:50c0:8001::153` |
| AAAA | `@` | `2606:50c0:8002::153` |
| AAAA | `@` | `2606:50c0:8003::153` |

Wait until the apex resolves to GitHub:

```bash
dig +short A blowhorn.ai        # expect the four 185.199.* addresses
dig +short AAAA blowhorn.ai     # expect the four 2606:50c0:* addresses
```

The Pages custom domain is already `blowhorn.ai`. Confirm it, watch the
certificate, and enforce HTTPS once GitHub reports it issued (Settings > Pages
shows "Enforce HTTPS" as available):

```bash
gh-axi api repos/layer5io/blowhorn-site/pages --jq '.cname, .https_certificate.state'
printf '{"https_enforced":true}' | gh-axi api -X PUT repos/layer5io/blowhorn-site/pages --input -
```

If the custom domain ever has to be set again:

```bash
gh-axi api -X PUT repos/layer5io/blowhorn-site/pages --field cname=blowhorn.ai
```

Certificate issuance usually takes a few minutes and can take up to a day. If
it stalls, the usual cause is the Cloudflare proxy being on for the record.

### Step 2: the www record (optional)

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `www` | `layer5io.github.io` | DNS only |

With `blowhorn.ai` as the Pages custom domain and this record in place, GitHub
answers `www.blowhorn.ai` with a redirect to `https://blowhorn.ai/`.

```bash
dig +short CNAME www.blowhorn.ai   # expect: layer5io.github.io.
curl -sI https://www.blowhorn.ai   # expect 301 to https://blowhorn.ai/
```

## URLs

Every page and asset reference is root-relative (`/css/site.<hash>.css`,
`/assets/brand/...`), built from `baseURL` in [`hugo.toml`](../hugo.toml)
(`https://blowhorn.ai/`). That is what lets `404.html` work for any missing
path, nested ones included. A build with a different base URL
(`make build-production BASE_URL=...` or `make build-preview`) prefixes every
reference with that URL's path. The project URL
`layer5io.github.io/blowhorn-site/` redirects to blowhorn.ai, so nothing is
served under that path in production.

The public URLs are a contract, checked by `make site-check`:

- `/`, `/privacy.html` and `/terms.html`. The privacy and terms pages live in
  `content/en/` and keep their `.html` URLs through `uglyURLs` in
  `hugo.toml`; their Markdown copies are `/privacy.md` and `/terms.md`.
- The home page's anchors: `#platforms`, `#how`, `#trust`, `#download`.
- `/assets/brand/...` (from `static/assets/brand/`), `/favicon.ico`, `/CNAME`.
- Generated: `/sitemap.xml`, `/robots.txt` (which names the sitemap),
  `/llms.txt`, `/llms-full.txt` and `/index.md`.

The canonical URLs, Open Graph tags, `sitemap.xml` and `robots.txt` name
`https://blowhorn.ai/`. A build with `HUGO_PREVIEW=true` marks every page
`noindex, nofollow` and its `robots.txt` disallows everything.

Docsy's own static files (Font Awesome webfonts, its favicons and a few
scripts) are published too because Docsy is imported as a module, as in
layer5io/docs; no page loads them.

## Local checks and evidence

```bash
make setup         # once: npm install
make check         # production build, html-validate, link, third-party and contract checks, check-script tests, actionlint: what CI runs
make site          # http://localhost:1313 with live reload
```

Before a visual change ships, build for production and serve `public/`, then
take screenshots at 390, 820 and 1440 px wide in both colour schemes and
confirm there is no horizontal scroll from 320 to 1440 px. With
chrome-devtools-axi:

```bash
make build-production && python3 -m http.server 8080 --directory public
chrome-devtools-axi open http://localhost:8080/
chrome-devtools-axi resize 390 844
chrome-devtools-axi emulate --color-scheme dark
chrome-devtools-axi screenshot /path/to/evidence/home-390-dark.png --full-page
chrome-devtools-axi eval 'document.documentElement.scrollWidth > document.documentElement.clientWidth'   # must be false
```

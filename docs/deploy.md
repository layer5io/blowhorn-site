# Deploying the site

How `site/` becomes www.blowhorn.ai: the GitHub Pages deployment, the custom
domain, the DNS records the registrar needs, and how to verify a deployment.

## What deploys, and when

[`site.yml`](../.github/workflows/site.yml) runs on every pull request and on
every push to `master`:

1. `make workflow-check` lints the workflows with actionlint.
2. `make site-check` validates every page with html-validate and checks every
   local link, image, font and `srcset` reference.
3. `make site-build` copies `site/` to `_site/` and adds `.nojekyll`, and the
   result is uploaded as the Pages artifact.
4. On `master` only (a push or a manual run), the `deploy` job publishes that
   artifact with `actions/deploy-pages` under the `github-pages` environment.
   The job needs `pages: write` and `id-token: write`, which it declares itself.

A pull request never deploys. There is no build step, so what is in `site/` on
`master` is exactly what is served.

### Verify a deployment

```bash
gh-axi run list -R layer5io/blowhorn-site --workflow site.yml
```

The newest run on `master` should show both jobs green. The deployment is live
at the Pages URL within a minute of the `deploy` job finishing:

- <https://www.blowhorn.ai/> once DNS points at GitHub Pages (below).
- <https://layer5io.github.io/blowhorn-site/> until then. Once a custom domain
  is set on Pages, GitHub redirects this URL to the custom domain, so set the
  domain only after its DNS record resolves to GitHub.

## Pages configuration

Pages is configured to publish from GitHub Actions (`build_type: workflow`),
not from a branch. The one-time setup, done with an account that administers
the repository:

```bash
gh-axi api -X POST repos/layer5io/blowhorn-site/pages --field build_type=workflow
# or, if Pages already exists:
gh-axi api -X PUT repos/layer5io/blowhorn-site/pages --field build_type=workflow
```

This was done on 2026-10-08: Pages exists with `build_type: workflow`,
`https_enforced: true` and no custom domain yet.

`site/CNAME` carries `www.blowhorn.ai` for completeness. With a workflow
deployment GitHub ignores the file; the custom domain is the one set through
the API or Settings > Pages, below.

## Custom domain: www.blowhorn.ai first, the apex later

The site is published under **www.blowhorn.ai**. The apex `blowhorn.ai` is
optional and can follow later; when both point at GitHub, Pages redirects the
apex to `www`.

blowhorn.ai is registered at Porkbun and its DNS is served by Cloudflare. Only
the domain's owner can change records. Set them in this order.

### Step 1: the www record (do this first)

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `www` | `layer5io.github.io` | DNS only (grey cloud). Keep the Cloudflare proxy off at least until GitHub has issued the certificate. |

Wait until the record resolves:

```bash
dig +short CNAME www.blowhorn.ai   # expect: layer5io.github.io.
```

Then set the custom domain on Pages and, once GitHub reports the certificate
issued (Settings > Pages shows "Enforce HTTPS" as available), enforce HTTPS:

```bash
gh-axi api -X PUT repos/layer5io/blowhorn-site/pages --field cname=www.blowhorn.ai
gh-axi api repos/layer5io/blowhorn-site/pages --jq '.cname, .https_certificate.state'
printf '{"https_enforced":true}' | gh-axi api -X PUT repos/layer5io/blowhorn-site/pages --input -
```

Set the custom domain only after `dig` shows the record, for two reasons:
GitHub starts certificate issuance from the moment the domain is set, and
from that moment it redirects the `layer5io.github.io/blowhorn-site/` URL to
the custom domain, so a domain whose DNS still points elsewhere takes the site
offline at both addresses.

Certificate issuance usually takes a few minutes and can take up to a day. If
it stalls, the usual cause is the Cloudflare proxy being on for the record.

### Step 2: the apex records (optional, later)

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

DNS only, proxy off, like the www record. Remove whatever the apex points at
today (it currently serves a Cloudflare 404). With `www.blowhorn.ai` as the
Pages custom domain and these records in place, GitHub answers the apex with
a redirect to `https://www.blowhorn.ai/`.

```bash
dig +short A blowhorn.ai       # expect the four 185.199.* addresses
curl -sI https://blowhorn.ai   # expect 301 to https://www.blowhorn.ai/
```

## Pages that assume the root

`site/404.html` references its stylesheet and images with root-relative paths
(`/styles.css`) because GitHub serves it for any missing path, including
nested ones, where relative paths would break. At the fallback
`layer5io.github.io/blowhorn-site/` URL the 404 page therefore renders without
styles; at www.blowhorn.ai it is fully styled. Every other page uses relative
paths and works at both hosts.

The canonical URLs, Open Graph tags, `sitemap.xml` and `robots.txt` name
`https://www.blowhorn.ai/`.

## Local checks and evidence

```bash
make check         # html-validate, link check, actionlint: what CI runs
make site-serve    # http://localhost:8080
```

Before a visual change ships, take screenshots at 390, 820 and 1440 px wide
in both colour schemes and confirm there is no horizontal scroll from 360 to
1440 px. With chrome-devtools-axi:

```bash
chrome-devtools-axi open http://localhost:8080/
chrome-devtools-axi resize 390 844
chrome-devtools-axi emulate --color-scheme dark
chrome-devtools-axi screenshot /path/to/evidence/home-390-dark.png --full-page
chrome-devtools-axi eval 'document.documentElement.scrollWidth > document.documentElement.clientWidth'   # must be false
```

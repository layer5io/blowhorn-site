# Deploying the site

How `site/` becomes blowhorn.ai: the GitHub Pages deployment, the custom
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

- <https://blowhorn.ai/> once DNS points at GitHub Pages (below).
- <https://layer5io.github.io/blowhorn-site/> is the project URL. Because the
  custom domain is already set on Pages, GitHub redirects this URL to
  `https://blowhorn.ai/`, which answers with Cloudflare's 404 until the DNS
  records below are in place. The artifact itself deploys fine either way.

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

`site/CNAME` carries `blowhorn.ai` for completeness. With a workflow
deployment GitHub ignores the file; the custom domain is the one set through
the API or Settings > Pages, below.

## Custom domain: blowhorn.ai (the apex)

The site is published under **blowhorn.ai**. `www.blowhorn.ai` is optional:
when its record also points at GitHub, Pages redirects it to the apex.

blowhorn.ai is registered at Porkbun and its DNS is served by Cloudflare. Only
the domain's owner can change records. Today the apex resolves to Cloudflare
addresses that answer 404; those records are what the ones below replace.

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

## Pages that assume the root

`site/404.html` references its stylesheet and images with root-relative paths
(`/styles.css`) because GitHub serves it for any missing path, including
nested ones, where relative paths would break. At the fallback
`layer5io.github.io/blowhorn-site/` URL the 404 page therefore renders without
styles; at blowhorn.ai it is fully styled. Every other page uses relative
paths and works at both hosts.

The canonical URLs, Open Graph tags, `sitemap.xml` and `robots.txt` name
`https://blowhorn.ai/`.

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

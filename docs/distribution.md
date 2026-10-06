# Distributing Blowhorn

This repository is the public distribution point for Blowhorn builds. Product
source and build pipelines stay in the private product repository; only finished,
signed artifacts are published here.

## Where binaries live

**GitHub Releases on `layer5io/blowhorn-site`.** Disk images are never committed
to git (`*.dmg` is in `.gitignore`), and they are not served from GitHub Pages.
Pages hosts only the marketing site and small static files.

| What | Where |
|------|-------|
| Marketing site | GitHub Pages from `site/`, later at <https://blowhorn.ai> |
| macOS DMG | Release asset on this repo |
| Checksums | `SHA256SUMS.txt` attached to each release |
| Update manifest (later) | Release asset next to the DMG (for example `latest-mac.yml` for electron-updater, or a Sparkle `appcast.xml`) |

## Release conventions

- **Tag:** `vMAJOR.MINOR.PATCH`, for example `v1.0.0`. A hyphenated suffix
  (`v1.1.0-beta.1`) makes it a GitHub prerelease, which is never marked "latest".
- **Assets per release:**
  - `Blowhorn-<version>-mac-<arch>.dmg`, where `<arch>` is `universal`, `arm64`, or `x64`
  - `Blowhorn-mac.dmg`, a copy of the same file under a fixed name
  - `SHA256SUMS.txt`
- **Always-latest download URL** (used by the site and install docs):

  ```
  https://github.com/layer5io/blowhorn-site/releases/latest/download/Blowhorn-mac.dmg
  ```

  GitHub resolves `latest` to the newest published, non-draft, non-prerelease
  release. Until the first stable release exists, this URL returns 404 and the
  site shows a placeholder.
- **Versioned URL:**
  `https://github.com/layer5io/blowhorn-site/releases/download/v1.0.0/Blowhorn-1.0.0-mac-universal.dmg`
- Releases are never overwritten. Ship a new patch version instead.

## Publishing a DMG

The DMG must already be built, signed with a Developer ID certificate, notarized,
and stapled before it reaches this repo. That happens in the product repo's
build pipeline.

### Option A: manual run here

1. Put the DMG at an HTTPS URL the runner can download (for example a release
   asset or a presigned object-storage URL).
2. Actions > **Publish DMG release** > **Run workflow**, then fill in `version`
   and `dmg_url`. Leave `draft` checked to review before publishing.
3. Check `require_notarized` once builds are signed. A macOS runner then runs
   `codesign`, `spctl`, and `stapler validate` and refuses to publish on failure.
4. Review the draft release and publish it.

If `dmg_url` needs a bearer token (for example a GitHub API asset URL on a
private repo, with `Accept: application/octet-stream`), store it as the
`DMG_SOURCE_TOKEN` repository secret.

### Option B: triggered from product CI

After it signs and notarizes, the product pipeline sends a `repository_dispatch`
event to this repo. This needs a token that can write to `layer5io/blowhorn-site`
(a GitHub App installation token or a fine-grained token with Contents: write),
stored as a secret in the product repo:

```bash
gh api repos/layer5io/blowhorn-site/dispatches \
  -f event_type=publish-dmg \
  -F 'client_payload[version]=v1.0.0' \
  -F 'client_payload[dmg_url]=https://example.com/Blowhorn-1.0.0.dmg' \
  -F 'client_payload[arch]=universal' \
  -F 'client_payload[draft]=true' \
  -F 'client_payload[require_notarized]=true'
```

The same `publish-dmg.yml` workflow runs, so validation, naming, and checksums
are identical for both paths.

### Option C: direct upload from product CI

The product pipeline can also run `gh release create` against this repo with
the same token. It must follow the asset naming above (including the
`Blowhorn-mac.dmg` alias and `SHA256SUMS.txt`) so the always-latest URL keeps
working. Prefer Option B so the naming rules live in one place.

## Chrome extension

The Blowhorn Chrome extension is published to the Chrome Web Store, not
distributed from this repo. CI publishes it with a
[Chrome Web Store service account](https://developer.chrome.com/docs/webstore/service-accounts).
That plan is tracked with the product repo's productization work.

## Local checks

```bash
make site-check                        # html-validate + local link check
make site-build                        # writes _site/ (the Pages artifact)
make site-serve                        # http://localhost:8080
make workflow-check                    # actionlint on this repo's workflows
make dmg-check DMG=path/to/file.dmg    # UDIF sanity check before publishing
```

#!/usr/bin/env bash
# Download the DMG at $DMG_URL to dist/source.dmg over HTTPS only.
# Env: DMG_URL; optional DMG_SOURCE_TOKEN, sent only to GitHub hosts.
# Run through make (see the dmg-* targets); publish-dmg.yml calls the same targets.
set -euo pipefail
mkdir -p dist
args=(--proto '=https' --proto-redir '=https' --fail --location --silent --show-error --retry 3 --output dist/source.dmg)
if [[ -n "${DMG_SOURCE_TOKEN:-}" ]]; then
  case "$DMG_URL" in
    https://api.github.com/*|https://github.com/*|https://objects.githubusercontent.com/*|https://release-assets.githubusercontent.com/*)
      echo "dmg_url is on a GitHub host; sending DMG_SOURCE_TOKEN"
      args+=(--header "Authorization: Bearer $DMG_SOURCE_TOKEN" --header "Accept: application/octet-stream")
      ;;
    *)
      echo "::notice::dmg_url is not on a GitHub host; downloading without credentials"
      ;;
  esac
fi
curl "${args[@]}" "$DMG_URL"

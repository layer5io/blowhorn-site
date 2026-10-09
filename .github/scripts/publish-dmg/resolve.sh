#!/usr/bin/env bash
# Validate the release inputs and write them to $GITHUB_OUTPUT.
# Env: IN_VERSION, IN_URL, IN_ARCH, IN_DRAFT, IN_NOTARIZED, optional IN_NOTES, GITHUB_OUTPUT.
# Writes notes.md (the release notes) in the current directory.
# Run through make (see the dmg-* targets); publish-dmg.yml calls the same targets.
set -euo pipefail
if [[ ! "$IN_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]]; then
  echo "::error::version must look like v1.2.3 or v1.2.3-beta.1 (got '$IN_VERSION')"
  exit 1
fi
if [[ ! "$IN_URL" =~ ^https://[^/]+/ ]]; then
  echo "::error::dmg_url must be an https:// URL with a host and a path"
  exit 1
fi
arch="${IN_ARCH:-universal}"
case "$arch" in universal|arm64|x64) ;; *) echo "::error::arch must be universal, arm64, or x64"; exit 1 ;; esac
prerelease=false
[[ "$IN_VERSION" == *-* ]] && prerelease=true
draft=true
[[ "${IN_DRAFT,,}" == "false" ]] && draft=false
notarized=true
[[ "${IN_NOTARIZED,,}" == "false" ]] && notarized=false
if [[ "$draft" == "false" && "$notarized" == "false" ]]; then
  echo "::error::a public release must be verified: set require_notarized=true, or keep draft=true to review an unverified image"
  exit 1
fi
{
  echo "version=$IN_VERSION"
  echo "arch=$arch"
  echo "prerelease=$prerelease"
  echo "draft=$draft"
  echo "require_notarized=$notarized"
} >>"$GITHUB_OUTPUT"
printf '%s' "${IN_NOTES:-}" >notes.md
echo "Publishing $IN_VERSION ($arch) draft=$draft prerelease=$prerelease require_notarized=$notarized"

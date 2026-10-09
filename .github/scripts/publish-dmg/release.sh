#!/usr/bin/env bash
# Create the GitHub Release from dist/; refuses to overwrite an existing tag.
# Env: GH_TOKEN, GH_REPO, VERSION, PRERELEASE, DRAFT, GITHUB_SHA, GITHUB_STEP_SUMMARY.
# Run through make (see the dmg-* targets); publish-dmg.yml calls the same targets.
set -euo pipefail
if gh release view "$VERSION" >/dev/null 2>&1; then
  echo "::error::release $VERSION already exists; refusing to overwrite"
  exit 1
fi
versioned=(dist/Blowhorn-*-mac-*.dmg)
{
  if [[ -s dist/notes.md ]]; then cat dist/notes.md; echo; echo; fi
  echo "## Download"
  echo
  echo "- macOS: \`$(basename "${versioned[0]}")\`"
  echo "- Always-latest link: https://github.com/${GH_REPO}/releases/latest/download/Blowhorn-mac.dmg"
  echo
  echo "## SHA-256"
  echo
  echo '```'
  cat dist/SHA256SUMS.txt
  echo '```'
} >release-notes.md
flags=(--title "Blowhorn ${VERSION}" --notes-file release-notes.md --target "${GITHUB_SHA}")
[[ "$DRAFT" == "true" ]] && flags+=(--draft)
if [[ "$PRERELEASE" == "true" ]]; then
  flags+=(--prerelease --latest=false)
else
  flags+=(--latest)
fi
gh release create "$VERSION" "${flags[@]}" dist/*.dmg dist/SHA256SUMS.txt
echo "### Release ${VERSION} created (draft=${DRAFT}, prerelease=${PRERELEASE})" >>"$GITHUB_STEP_SUMMARY"

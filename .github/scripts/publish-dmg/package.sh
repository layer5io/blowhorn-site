#!/usr/bin/env bash
# Check dist/source.dmg, give it its versioned and always-latest names, and
# write SHA256SUMS.txt; move dmg-resolve's notes.md into dist/ for dmg-release.
# Env: VERSION (v1.2.3), ARCH (universal, arm64, x64).
# Run through make (see the dmg-* targets); publish-dmg.yml calls the same targets.
set -euo pipefail
.github/scripts/check-dmg.sh dist/source.dmg
versioned="Blowhorn-${VERSION#v}-mac-${ARCH}.dmg"
mv dist/source.dmg "dist/$versioned"
# Stable, version-less alias so /releases/latest/download/Blowhorn-mac.dmg
# always points at the newest published release.
cp "dist/$versioned" dist/Blowhorn-mac.dmg
(cd dist && sha256sum -- *.dmg >SHA256SUMS.txt && cat SHA256SUMS.txt)
mv notes.md dist/notes.md

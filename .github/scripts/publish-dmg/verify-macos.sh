#!/usr/bin/env bash
# Verify each dist/Blowhorn-*-mac-*.dmg: image integrity, code signature,
# Gatekeeper assessment and stapled notarization. macOS only.
# Run through make (see the dmg-* targets); publish-dmg.yml calls the same targets.
set -euo pipefail
for dmg in dist/Blowhorn-*-mac-*.dmg; do
  hdiutil verify "$dmg"
  codesign --verify --verbose=2 "$dmg"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg"
  xcrun stapler validate "$dmg"
done

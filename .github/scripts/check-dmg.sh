#!/usr/bin/env bash
# Cheap, platform-independent sanity check that a file is a UDIF disk image
# (.dmg). UDIF images end with a 512-byte trailer whose first 4 bytes are "koly".
# Signing and notarization are verified separately on macOS.
set -euo pipefail

dmg="${1:?usage: check-dmg.sh <file.dmg>}"
[[ -f "$dmg" ]] || { echo "not a file: $dmg" >&2; exit 1; }

size=$(wc -c <"$dmg")
if (( size < 1024 )); then
  echo "too small to be a DMG ($size bytes): $dmg" >&2
  exit 1
fi

magic=$(dd if="$dmg" bs=1 skip=$((size - 512)) count=4 2>/dev/null)
if [[ "$magic" != "koly" ]]; then
  echo "missing UDIF 'koly' trailer; not a DMG: $dmg" >&2
  exit 1
fi
echo "ok: $dmg looks like a UDIF disk image ($size bytes)"

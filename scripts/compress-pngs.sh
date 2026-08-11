#!/bin/bash
#
# Compress every PNG in the repo. Default is lossless (oxipng: pixel data
# unchanged, only encoding and safe-to-strip metadata are optimized).
# With --lossy, runs pngquant first with a high quality floor (files that
# can't be quantized without visible loss are left alone), then oxipng.
# Skips _site since Jekyll regenerates it from the source files.
#
# Usage: scripts/compress-pngs.sh [--lossy]
#
# Requires oxipng (brew install oxipng); --lossy also needs pngquant.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOSSY=0
[[ "${1:-}" == "--lossy" ]] && LOSSY=1

if ! command -v oxipng >/dev/null; then
  echo "error: oxipng not found — install with: brew install oxipng" >&2
  exit 1
fi
if [[ $LOSSY -eq 1 ]] && ! command -v pngquant >/dev/null; then
  echo "error: pngquant not found — install with: brew install pngquant" >&2
  exit 1
fi

before=$(find "$ROOT" -name '*.png' -not -path "$ROOT/_site/*" -not -path "$ROOT/.git/*" -print0 |
  xargs -0 stat -f %z | awk '{s+=$1} END {print s}')

if [[ $LOSSY -eq 1 ]]; then
  # 90 floor: pngquant skips any file where quantization would drop below it,
  # so icons/logos with flat color pass through untouched rather than banding.
  find "$ROOT" -name '*.png' -not -path "$ROOT/_site/*" -not -path "$ROOT/.git/*" -print0 |
    xargs -0 pngquant --quality 90-100 --speed 1 --skip-if-larger --force --ext .png || true
fi

find "$ROOT" -name '*.png' -not -path "$ROOT/_site/*" -not -path "$ROOT/.git/*" -print0 |
  xargs -0 oxipng -o max --strip safe --alpha

after=$(find "$ROOT" -name '*.png' -not -path "$ROOT/_site/*" -not -path "$ROOT/.git/*" -print0 |
  xargs -0 stat -f %z | awk '{s+=$1} END {print s}')

printf 'done: %d KB -> %d KB (saved %d KB)\n' $((before / 1024)) $((after / 1024)) $(((before - after) / 1024))

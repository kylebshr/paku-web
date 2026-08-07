#!/bin/bash
#
# Pull framed marketing screenshots from the paku-ios generated folder into
# the website as full-resolution WebP, and rebuild the press kit zip.
#
# Usage: scripts/update-screenshots.sh [path-to-generated-screenshots]
#        (defaults to ../paku-ios/Marketing/generated/iphone-17)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/../paku-ios/Marketing/generated/iphone-17}"
IMAGES="$ROOT/images"
PRESS_ZIP="$ROOT/press/images.zip"

if [[ ! -d "$SRC" ]]; then
  echo "error: source folder not found: $SRC" >&2
  exit 1
fi

# Screenshots used on the website (framed variants; dark copied when present).
SHOTS=(sf-home home-widgets lock-widgets bay-temperature)

echo "==> Generating website assets"
for base in "${SHOTS[@]}"; do
  for variant in "" "-dark"; do
    src="$SRC/${base}${variant}-framed.png"
    if [[ ! -f "$src" ]]; then
      [[ -z "$variant" ]] && { echo "error: missing $src" >&2; exit 1; }
      continue
    fi
    name="${base}${variant}-framed"
    # Expect native-3x framed masters (1350px wide). A ~900px source means the
    # generator downscaled to @2x already; using it as @3x double-resamples.
    w=$(sips -g pixelWidth "$src" | awk '/pixelWidth/{print $2}')
    if [[ "$w" -lt 1100 ]]; then
      echo "error: $src is ${w}px wide — expected native-3x (~1350px)." >&2
      echo "       Regenerate with paku-ios scripts/screenshots (downscale step removed)." >&2
      exit 1
    fi
    magick "$src" -quality 82 "$IMAGES/${name}.webp"
    echo "    $name.webp"
  done
done

echo "==> Rebuilding press kit zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/images"
cp "$SRC"/*.png "$tmp/images/"
(cd "$tmp" && zip -q -r -X images.zip images)
mv "$tmp/images.zip" "$PRESS_ZIP"
echo "    $(unzip -l "$PRESS_ZIP" | tail -1 | awk '{print $2}') files -> press/images.zip"

echo "done"

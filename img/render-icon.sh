#!/bin/bash
# Render img/icon.svg into every size of the app icon set (needs Google Chrome and ImageMagick).
set -euo pipefail
cd "$(dirname "$0")/.."
SET=QuickRecorder/Assets.xcassets/AppIcon.appiconset
TMP=$(mktemp -d)
printf '<html><body style="margin:0;background:transparent"><img src="%s" width="1024" height="1024"></body></html>' \
    "file://$PWD/img/icon.svg" > "$TMP/icon.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --hide-scrollbars \
    --default-background-color=00000000 --window-size=1024,1024 --screenshot="$TMP/icon.png" "file://$TMP/icon.html" 2>/dev/null
for s in 16 32 128 256 512; do
    magick "$TMP/icon.png" -filter Lanczos -resize ${s}x${s} "$SET/icon_${s}x${s}.png"
    magick "$TMP/icon.png" -filter Lanczos -resize $((s*2))x$((s*2)) "$SET/icon_${s}x${s}@2x.png"
done
cp "$TMP/icon.png" img/icon.png
rm -rf "$TMP"
echo "Rendered $SET"

#!/bin/bash
# Build Kurip (Release), zip it and write a Sparkle-signed appcast.xml for it.
#   ./release.sh            build + sign + update appcast.xml (local only)
#   ./release.sh --publish  also create the GitHub release and push appcast.xml
# Version comes from MARKETING_VERSION / CURRENT_PROJECT_VERSION in the Xcode project.
# Release notes: put them in notes.md (Markdown) before running; it is embedded in the appcast.
set -euo pipefail
cd "$(dirname "$0")"

DD=build/dd
OUT=build/updates
REPO=inoxixi7/Kurip

xcodebuild -project Kurip.xcodeproj -scheme Kurip -configuration Release -derivedDataPath "$DD" build -quiet
APP="$DD/Build/Products/Release/Kurip.app"
VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
TAG="v$VER"

# only the newest build goes in the feed: Sparkle just needs the latest item
rm -rf "$OUT"; mkdir -p "$OUT"
ditto -c -k --keepParent "$APP" "$OUT/Kurip-$VER.zip"
# Sparkle 2.6 reads .html notes only: turn the "## heading / - item / text" Markdown into a fragment
if [ -f notes.md ]; then
    awk '/^## /{sub(/^## /,""); print "<h2>" $0 "</h2>"; next}
         /^- /{if(!ul){print "<ul>"; ul=1} sub(/^- /,""); print "<li>" $0 "</li>"; next}
         {if(ul){print "</ul>"; ul=0}} NF{print "<p>" $0 "</p>"}
         END{if(ul) print "</ul>"}' notes.md > "$OUT/Kurip-$VER.html"
fi

# signs with the EdDSA key stored in the login Keychain under account "Kurip"
"$DD/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast" \
    --account Kurip --embed-release-notes \
    --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" \
    -o appcast.xml "$OUT"
echo "Built $OUT/Kurip-$VER.zip and updated appcast.xml for $TAG"

if [ "${1:-}" = "--publish" ]; then
    # the zip must be downloadable before the feed points at it
    gh release create "$TAG" "$OUT/Kurip-$VER.zip" -R "$REPO" --title "Kurip $VER" \
        $([ -f notes.md ] && echo --notes-file notes.md || echo --generate-notes)
    git add appcast.xml
    git commit -m "Appcast for $TAG"
    git push origin HEAD
fi

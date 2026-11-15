#!/bin/sh
# Captures the raw App Store screenshots from a booted iPad simulator, in English and Danish.
# Needs a Debug build installed (the screenshot scenes exist in debug builds only):
#   appstore/capture.sh <simulator-udid>
# Then compose the posters with the hub's tool: see appstore/README.md.
set -eu
udid="${1:?usage: appstore/capture.sh <simulator-udid>}"
app=com.iamjarl.whiskerling
cd "$(dirname "$0")"
mkdir -p raw

xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularMode notSupported

for lang in en da; do
  locale=$([ "$lang" = da ] && echo da_DK || echo en_US)
  for scene in room gate fish wardrobe night; do
    sky=$([ "$scene" = night ] && echo night || echo day)
    xcrun simctl terminate "$udid" "$app" 2>/dev/null || true
    xcrun simctl launch "$udid" "$app" -screenshots -screen "$scene" -debugSky "$sky" \
      -AppleLanguages "($lang)" -AppleLocale "$locale" >/dev/null
    sleep "${WAIT:-9}"
    xcrun simctl io "$udid" screenshot "raw/$lang-$scene.png" >/dev/null
    echo "raw/$lang-$scene.png"
  done
done
xcrun simctl terminate "$udid" "$app" 2>/dev/null || true
xcrun simctl status_bar "$udid" clear

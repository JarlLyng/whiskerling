#!/bin/sh
# Laver ikonerne ved at tage et skærmbillede af tools/icon.html med Chrome:
#   public/icon.png (180x180) til web-versionen og
#   Whiskerling/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024x1024) til appen.
set -e
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
shot() {
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --window-size="$1,$1" \
    --screenshot="$PWD/$2" "file://$PWD/tools/icon.html?size=$1" >/dev/null 2>&1
  sips -g pixelWidth -g pixelHeight "$2"
}
shot 180 public/icon.png
sleep 1
shot 1024 Whiskerling/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png

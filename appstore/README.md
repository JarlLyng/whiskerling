# App Store screenshots

One folder per release (`1.0/`), locales in subfolders, one file per slot: `1.0/en/ipad-13-1.png`
and so on. Superseded sets are deleted; git history keeps them. The app is iPad only, so the set
is the 13-inch iPad slot (2064 × 2752), which App Store Connect scales for the smaller iPads.

## The 1.0 set

| # | Scene | English | Danish |
|---|---|---|---|
| 1 | `room` | Your own kitten / to *look after* | Din egen killing / at *passe på* |
| 2 | `gate` | No ads, and / purchases are / *for grown-ups* | Ingen reklamer, / og køb er / *for voksne* |
| 3 | `fish` | In the garden, / it *catches fish* | Ude i haven / *fanger den fisk* |
| 4 | `wardrobe` | Earn hearts, / *dress it up* | Få hjerter, / *og pynt den* |
| 5 | `night` | It sleeps at night, / and it *never dies* | Den sover trygt, / og den *dør aldrig* |

The first shot says what it is, the second answers the parent's first worry, then the rest follows
the play. No prices on any shot, as Apple asks.

## Making it again

1. **Capture.** Debug builds have a screenshot mode: `-screenshots -screen <scene>` with
   `-debugSky day|night` stages a sample cat called Luna in its own storage (a real cat is never
   touched), shows Pro as bought, and freezes the world so every capture is the same. With a Debug
   build installed on a booted iPad simulator:
   ```bash
   appstore/capture.sh <simulator-udid>
   ```
   It writes `raw/<lang>-<scene>.png` in English and Danish. Crop the status bar off (the top
   64 px on an 11-inch iPad), since the simulator shows its own date.
2. **Compose** with the IAMJARL hub's poster tool, with the hub cloned next to this repo:
   ```bash
   python3 ../iamjarl-strategy/tools/appstore_screenshots.py batch appstore/manifest.json
   ```
   `manifest.json` holds the captions, the light warm ground and the pink accent (`#C2416A`,
   above 3:1 on the ground). Captions alternate top and bottom; the top ones bleed.
3. **Check** the captions (no em-dashes, no hype) and that the tool printed no warnings, then
   upload through App Store Connect's Asset Library.

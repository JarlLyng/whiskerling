# Contributing to Whiskerling

Thanks for your interest. Whiskerling is open source (MIT) and maintained by one person, so two
asks before you start:

- **Open an issue before a large pull request.** The app is deliberately small and gentle, and
  not every good idea fits it. `AGENTS.md` has the feature list and the list of things the app
  deliberately doesn't do (no accounts, no network features, no ads, no analytics).
- By submitting a contribution you agree it's licensed under the project's [MIT](LICENSE) license.

Security issues go through [SECURITY.md](SECURITY.md), not public issues.

## Setup

- Xcode 27 and XcodeGen (`brew install xcodegen`).
- `xcodegen generate`, then open `Whiskerling.xcodeproj`. The project file and `Info.plist` are
  generated and git-ignored; change `project.yml` and run `xcodegen generate` again.
- The first build fetches the `IAMJARLDesignTokens` Swift package from GitHub, so it needs network.
- The run scheme uses `Whiskerling.storekit`, so Pro can be bought in the simulator.

## Build and test

```bash
xcodebuild -project Whiskerling.xcodeproj -scheme Whiskerling \
  -destination 'platform=iOS Simulator,name=<an iPad>' test
```

CI runs the same build and tests on every pull request to `main`.

## Conventions

- **Kids first.** Anything that leaves the app (links, purchases, the rating prompt) goes behind
  the parental gate. No third-party SDKs, no analytics, no ads: Apple's Kids category rules them out.
- **Everything is drawn in code.** The room, the cat and the garden are drawn with `Pen`, a
  canvas-style wrapper around SwiftUI's `GraphicsContext`. There are no image assets besides the icon.
- **Texts in two languages.** Add English in `Whiskerling/Core/Localization/L10n.swift` and Danish
  in `tools/l10n.py`, then run `/usr/bin/python3 tools/l10n.py` to rebuild the String Catalog.
  `--check` fails if a key lacks Danish.
- **Player-facing text:** no em-dashes, no hype. Short and plain, as if you were saying it to a child.
- **Tests never touch a real cat.** World tests use their own `UserDefaults` suite
  (`GardenTests` shows how).
- Update `CHANGELOG.md` and, if a feature changes, the feature lists in `AGENTS.md`.

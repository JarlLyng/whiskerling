# Xcode Cloud

For **maintainers**. How Whiskerling gets archived and uploaded to TestFlight.

## Where the configuration lives

**Workflows live in App Store Connect, not in this repo.** Nothing in git controls them. `ci_scripts/`
and this file are the only traces Xcode Cloud leaves here, so their presence says nothing about whether a
workflow exists or which branch it builds. Look in:

- **App Store Connect** → the app (ID `6835849162`) → Xcode Cloud, to see whether the product exists.
- **Xcode** → Report Navigator (**⌘9**) → **Cloud**, to create or edit workflows.

## What Xcode Cloud builds

- **Project:** `Whiskerling.xcodeproj` and `Whiskerling/Info.plist`, generated from `project.yml` with
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) **2.46.0** and committed, because Xcode Cloud builds
  what is in git. Run `xcodegen generate` after every change to `project.yml` and commit the project with
  it. CI regenerates the project with the same XcodeGen version and fails when the committed one differs,
  so a forgotten regeneration can't reach a release. Another XcodeGen version can write the same project
  differently: bump the version in `.github/workflows/ci.yml` (with its checksum) and in `project.yml`'s
  header together.
- **Scheme:** `Whiskerling` (shared, committed in `Whiskerling.xcodeproj/xcshareddata`).
- **Script:** `ci_scripts/ci_pre_xcodebuild.sh`, next to the project, which is where Xcode Cloud looks
  for it. It sets the build number from `CI_BUILD_NUMBER` with `agvtool` (the project uses
  `VERSIONING_SYSTEM = apple-generic`) and does nothing outside Xcode Cloud.
- **Packages:** the one package, `iamjarl-design` (public), is pinned in
  `Whiskerling.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. Xcode Cloud resolves
  from that file with automatic package resolution turned off and fails if a package is missing from it.
  CI builds the same way (`-disableAutomaticPackageResolution`).
- **No crash reporting and no dSYM upload,** on purpose. Whiskerling is in the Kids category, has no
  analytics or crash-reporting SDK, and sends nothing. Apple's own crash reports, from people who share
  them with developers, show up in Xcode's Organizer.

## Before the first workflow (the owner)

- The bundle ID `com.iamjarl.whiskerling` is registered, and the App Store Connect record exists
  (created by Xcode on 2026-11-17, app ID `6835849162`).
- **Push `main` to `release` before creating the workflow** (`git push origin main:release`), so the
  branch has the committed project and the shared scheme. Xcode Cloud reads them from the branch, and
  without them it can't offer the Archive action for the scheme. That happened on 2026-11-18: the
  workflow was created while `release` didn't have the project yet, so it got only a Build action. Its
  first build built the app but didn't archive it, and nothing reached TestFlight. If a workflow shows
  only a Build action, edit it to match [the workflow](#the-workflow) below and start a build on
  `release` by hand. The branch doesn't need another push.
- Sign in to Xcode with an account that can create workflows (Account Holder, Admin or App Manager).
- **Grant Xcode Cloud access** to `JarlLyng/whiskerling` on GitHub when Xcode asks, while creating the
  first workflow.
- **Set the next build number** (below) before the first build.

## The workflow

- **Start condition:** branch changes on **`release`**, like the other IAMJARL apps. `main` is the
  development branch and never starts a release build.
- **Action:** Archive, iOS, scheme `Whiskerling`, deployment preparation **TestFlight and App Store**.
  A Build action alone doesn't archive or upload anything.
- **Post-action:** TestFlight internal testing.
- **Environment:** nothing. No secrets are needed.

## Build numbers

Xcode Cloud counts its own build numbers and starts at 1, but App Store Connect accepts each version and
build pair only once. Builds 1 and 2 of 1.0 were uploaded from Xcode (on 2026-11-17 and 2026-11-18). So **before the first Xcode Cloud build, set Xcode Cloud's next build number
above the highest build uploaded for 1.0**, as Apple describes in
[Setting the next build number for Xcode Cloud builds](https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds).
After that, every Xcode Cloud build gets a higher number by itself.

`CURRENT_PROJECT_VERSION` in `project.yml` only matters for builds from Xcode on this Mac. Xcode Cloud
replaces it with its own number in the clone it builds.

## Cutting a release

1. Bump `MARKETING_VERSION` in `project.yml`, run `xcodegen generate`, and update `CHANGELOG.md`.
2. Open a pull request to `main` and merge it once CI is green. `main` takes changes only through pull
   requests with a passing CI check (the "Protect main" ruleset).
3. Push `main` to `release`: `git push origin main:release`. That starts the workflow. The `release`
   branch can't be deleted or force-pushed (the "Protect release" ruleset), so it only ever moves
   forward to a commit that is already on `main`.

## Archiving by hand

How builds 1 and 2 were made, and still the way to check an archive without Xcode Cloud. Set
`CURRENT_PROJECT_VERSION` in `project.yml` above every build uploaded for the version, run
`xcodegen generate`, then in Xcode: **Any iOS Device**, Product → Archive, and Distribute App → App Store
Connect. Xcode Cloud's next build number then has to go above that one too.

**Reference:** [Xcode Cloud documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)

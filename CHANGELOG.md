# Changelog

All notable changes to Whiskerling are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- The game follows Reduce Motion. Hearts and sparkles fade where they appear instead of flying
  out, the cat hops a little instead of leaping, fish rise low and slow and slip back without
  spinning, and a low need's icon stays large instead of pulsing. The games and their hearts are
  the same ([#14](https://github.com/JarlLyng/whiskerling/issues/14)).

### Fixed
- Rate in the grown-ups' menu opens Whiskerling's review page in the App Store. It asked for
  Apple's rating prompt, which the system may choose not to show, so the button could do nothing
  ([#12](https://github.com/JarlLyng/whiskerling/issues/12)).
- Purchases that complete later, like a parent approving Ask to Buy, are now finished once Pro
  is unlocked, so the App Store doesn't hand them over again on every launch
  ([#13](https://github.com/JarlLyng/whiskerling/issues/13)).
- The app works in small and resized windows. In a narrow window the needs get a row of their
  own in the top bar, the food and game choices become a list, and the start screen's kittens
  shrink to fit. The food and game cards, the parental gate and the grown-ups' menu scroll when
  a window is too short for them, so they no longer cover the bars or cut off OK and Close. A
  window resized during Catch the fish or the feather keeps the game going where things now are
  ([#15](https://github.com/JarlLyng/whiskerling/issues/15)).

## [1.0.0] - not released yet (build 4)

### Added
- The first iPad version of the game, rebuilt in SwiftUI from the web version (Min Mis):
  a kitten to feed, play with, wash and put to bed, with a litter box, hearts and accessories.
  It grows over a week, and time passes while the app is closed.
- Whiskerling Pro, a one-time in-app purchase behind a parental gate: all six coats, every
  accessory, the garden and Catch the fish.
- The garden, a second room with a pond, an apple tree and butterflies, and stars and fireflies
  at night.
- Catch the fish, a mini-game at the garden pond where nobody loses.
- A grown-ups' menu behind the gate: Pro, restore, sound, send feedback, rate, the privacy policy
  and starting over.
- English and Danish.
- App Store screenshots for the 13-inch iPad in English and Danish, made from a debug-only
  screenshot mode.
- The site, whiskerling.iamjarl.com, in English and Danish, with the privacy policy and support.

- The paywall and the site say that what is added to Pro later, like new cats and games, is
  included ([#5](https://github.com/JarlLyng/whiskerling/issues/5)).

### Changed
- CI and the site deploy check out the code with `actions/checkout` v7
  ([#1](https://github.com/JarlLyng/whiskerling/pull/1)).
- The parental gate asks the small times table (6 to 9 times 6 to 9) instead of sums with
  three-digit answers, and the site's example is 7 × 8
  ([#2](https://github.com/JarlLyng/whiskerling/issues/2)).
- Buying or restoring Pro from a locked item closes the paywall by itself and finishes the tap:
  out to the garden, Catch the fish, or the coat or accessory put on
  ([#3](https://github.com/JarlLyng/whiskerling/issues/3)).
- Releases are built by Xcode Cloud from the `release` branch and go to TestFlight. The generated
  Xcode project is committed, and CI checks it matches `project.yml`
  ([#7](https://github.com/JarlLyng/whiskerling/issues/7)).

### Fixed
- The cat no longer stutters in Catch the fish. It eased after a drifting fish in stops and
  steps; now it follows in one smooth walk
  ([#4](https://github.com/JarlLyng/whiskerling/issues/4)).

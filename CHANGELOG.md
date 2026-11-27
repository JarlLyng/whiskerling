# Changelog

All notable changes to Whiskerling are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- The text follows the system's text size. Everything outside the room grows with it, up to the
  largest accessibility sizes: the start screen, the food, game and room cards, the wardrobe, the
  parental gate, the paywall and the grown-ups' menu. With large text the choices stand in rows,
  the coats and the wardrobe's tiles sit fewer to a row, and the keys and buttons grow with their
  words. The bars above and below the room grow up to the largest standard size, so the room stays
  in view, and at the larger sizes a long press on a need or a button shows it large
  ([#42](https://github.com/JarlLyng/whiskerling/issues/42)).

## [1.1.0] - not released yet

### Added
- Seasons, from the iPad's date. Snow falls past the window and piles on the sill in winter,
  blossom drifts by in spring and leaves in autumn. In the garden the lawn, the fence and the
  bushes get snow, the apple tree is bare in winter, blossoms in spring and turns orange in
  autumn, flowers and butterflies come in spring and summer, and fireflies on summer nights.
  South of the equator the seasons are the other way round. Debug builds take
  `-debugSeason winter|spring|summer|autumn` ([#16](https://github.com/JarlLyng/whiskerling/issues/16)).
- The grown-up cat. When it grows up there's a party in the room, with balloons and a cake, on
  the next visit if nobody was there that day. It has a birthday each year on the day it was
  adopted (28 February in other years for a 29 February cat), with its age in a speech bubble and
  a candle for each year, also when the app wasn't open on the day. A content grown-up cat now and
  then naps on the rug, stretches with a yawn, or brings the child a ball of yarn; a tap wakes it.
  A cat that grew up in 1.0 gets its party late, on the first visit after the update
  ([#17](https://github.com/JarlLyng/whiskerling/issues/17)).
- Things for the living room, unlocked with hearts after the crown, so the hearts keep leading
  somewhere. A plant and a pink rug are free; a cat tree, heart wallpaper, a picture of the cat
  in its own coat and fairy lights, which shine when the light is off, come with Pro. They're put
  up and taken away in a new Room section of the wardrobe, and the bowl, the basket and the litter
  box stay where they are ([#18](https://github.com/JarlLyng/whiskerling/issues/18)).
- Three more coats with Pro: tuxedo, Siamese, and ginger and white, with two new markings, a white
  bib and blaze, and a Siamese's dark mask, ears, paws and tail. The start screen shows the nine
  coats in three rows, or in two on a short, wide screen like an iPad mini on its side, and the
  paywall names them all ([#19](https://github.com/JarlLyng/whiskerling/issues/19)).
- Hide and seek, a new game with Pro, in the living room or the garden. While a big 1, 2, 3 counts,
  the cat hides with its ears or its tail peeking out: in the basket, behind the litter box, under
  the rug or behind the curtain indoors, and behind the apple tree, over the fence or behind the
  pond outside. A tap finds it, and it pops out and hides again, eight times. There is no timer
  and no score, and now and then it meows from the hiding place as a hint
  ([#20](https://github.com/JarlLyng/whiskerling/issues/20)).
- A second cat with Pro. Once the first cat is grown up, a "+" next to its name lets a kitten come
  to live with it. One bowl feeds both, the light puts both to bed in the basket, and the litter
  box is shared, while the sponge and a stroke go to the cat that's touched. With company, fun
  and clean fall more slowly and each cat visits the litter box less often, so two cats aren't
  twice the chores. The top bar shows one cat at a time, with the other as a small picture to
  tap. Each grows from its own adoption date, and the two groom each other, chase, nap together
  and sit at the window, and otherwise keep a cat's width apart, so neither hides behind the
  other. Losing Pro removes no cat, and Start over removes both
  ([#21](https://github.com/JarlLyng/whiskerling/issues/21)).
- The kitchen, a third room with Pro. A tap on the mixing bowl bakes fish cookies: fish and flour
  into the bowl, a stir, six fish cut out of the dough, and the oven, with every tap moving it on
  and every batch turning out. The cookies go into a jar, and Feed offers them as a treat while
  the jar has some. The cat watches from the counter, looks in the fridge, and now and then takes
  a cookie. "Go to" replaces the garden button and chooses between the living room, the kitchen
  and the garden, and hide and seek has four hiding places in the kitchen
  ([#38](https://github.com/JarlLyng/whiskerling/issues/38)).
- A cat's name can be changed in the grown-ups' menu, for each cat when there are two
  ([#48](https://github.com/JarlLyng/whiskerling/pull/48)).

### Changed
- The game follows Reduce Motion. Hearts and sparkles fade where they appear instead of flying
  out, the cat hops a little instead of leaping, fish rise low and slow and slip back without
  spinning, and a low need's icon stays large instead of pulsing. The games and their hearts are
  the same ([#14](https://github.com/JarlLyng/whiskerling/issues/14)).
- Better contrast. The grey notes are darker, so they reach the contrast small text needs on
  every card, tile and button, in light and dark. Locked and not yet unlocked items, and the
  buttons while the cat sleeps, now fade only their picture, not their words. With the system's
  Increase Contrast on, the notes turn as dark as the text and the buttons and tiles get an
  outline. The pink of the text buttons and links is darker, so it reads on the cream cards, and
  the links in the grown-ups' menu are underlined and easier to hit
  ([#43](https://github.com/JarlLyng/whiskerling/issues/43)).

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

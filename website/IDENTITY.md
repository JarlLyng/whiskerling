# Site identity

Six decisions about how whiskerling.iamjarl.com looks, made on purpose rather than inherited.

| Decision | Whiskerling |
|---|---|
| **Ground** | Warm cream, `#FDF1E0`, light only: the start screen of the game, a sunny room. Cards one step lighter, `#FFF8EE`. |
| **Accent** | The pink of the kitten's bow and the curtains, `#E76B86`, for fills and lines only (2.7:1). A deeper `#A8325A` for links and any text (5.8:1 on the ground). |
| **Type voice** | The app's own face: SF Rounded on Apple devices, the system face elsewhere. Nothing to download. |
| **Imagery mode** | The game itself: real screens, frameless, with the iPad's rounded corners. No photographs and no drawings beside the game's own. |
| **Motion** | None. Nothing on the page moves. |
| **Signature** | The cat clock and the cream room, carried by the screens rather than by decoration. |

## How it is enforced

- **The design system comes from one release, served from this site:**
  `assets/iamjarl-design@v1.37.0/`, with SRI on every sheet. Only `tokens.css` and `kit/kit.css`
  are used. The files are copied from the tag, never edited, and checked against the tag's
  `dist/sri.json`. A bump is a new folder plus changed links, never a file changed in place.
- **The identity lives in `site.css` for now,** on the kit's own variable names (`--ij-color-*`,
  `--ij-font-display`). When `iamjarl-design` ships `dist/identity/whiskerling.css`, the sheet
  replaces that block and the markup doesn't change. Adding Whiskerling to `apps.json` there is
  also what lets the page use `<ij-footer>` with the portfolio's cross-links; until then the footer
  is plain HTML.
- **Light only.** There is no `prefers-color-scheme` rule; `color-scheme: light` holds the page in
  the cream room whatever the visitor's setting. One `theme-color`, `#FDF1E0`.
- **Not on the App Store yet:** the hero and the closing say "Coming soon to the App Store" as
  plain text. No App Store badge and no Smart App Banner until there is a real store link; then
  both come from the design system's store registry.
- **Nothing third-party but Umami:** the one script from elsewhere is IAMJARL's own cookieless Umami
  instance (#45). No cookies, no fonts from elsewhere. The privacy pages describe exactly what the
  site loads, so changing that means changing both pages in the same commit.
- **Everything is in the served HTML,** including the FAQ, so crawlers that don't run JavaScript
  read the whole page. The FAQ is also in the JSON-LD, and the visible page and the JSON-LD say the
  same price: free, with one optional purchase.

## The screens

`assets/<lang>-<scene>.jpg` are the raw App Store captures (`appstore/raw/`), scaled to 900 px.
Make them again whenever the screenshots are made again. `og-image.png` is the social card
(1200 × 630): the name, one line of outcome and the room.

# Hacker News Dark

A dark theme for news.ycombinator.com that follows your system appearance, with a
`theme` link in HN's own top bar to flip it.

## Install

From the Chrome Web Store — *listing pending review; the link lands here once
it is live.*

Or run it from source:

1. Open `chrome://extensions`
2. Turn on **Developer mode** (top right)
3. Click **Load unpacked** and select this folder
4. Open [news.ycombinator.com](https://news.ycombinator.com)

## The two settings

There is no options page, because there are only two meaningful states — and both
are reachable from the `theme` link in the top bar, immediately right of
`logout`:

| State | Behaviour |
| --- | --- |
| **Match system** (default) | Dark when your OS is in dark mode, light when it isn't |
| **Opposite of system** | Light when your OS is in dark mode, dark when it isn't |

Because the stored state is *relative* to the system rather than an absolute
"dark" or "light", automatic switching comes for free: when macOS or Windows
flips at sunset, HN flips with it, in whichever direction you last chose. The
choice is stored in `chrome.storage.sync`, so it follows your Chrome profile
across devices and updates every open HN tab at once.

Hover the `theme` link to see which state you're in.

## What it looks like

Vanilla HN with the grayscale flipped. The layout is untouched: same Verdana,
same 10pt/9pt/7pt type scale, same 5px story spacers, same table widths, same
square corners, no shadows, no added padding. Every declaration in
`hn-dark.css` sets a `background-color` or a `color` and nothing else.

HN's page is three grays plus the bar: `#ffffff` behind the table, `#f6f6ef`
inside it, `#000000` for links and comment text, `#828282` for everything
secondary. The first three are inverted around the page background. `#828282`
is not — it sits in the middle of the ramp and reads on either ground (4.5:1
against this background, better than the 3:1 it manages on HN's cream), so
keeping the literal value leaves the metadata exactly where HN puts it.

The orange top bar is left alone, including the logo's inline white border,
the black nav links and the white selected item. If it reads too hot against
a dark page, section 5 of `hn-dark.css` carries a commented-out two-selector
block that dims the bar and the footer rule together.

**Light mode is untouched, deliberately.** Every rule in `hn-dark.css` is gated
behind `html[data-hn-theme="dark"]`, so flipping to light gives you back
byte-for-byte vanilla HN.

## Files

| File | Role |
| --- | --- |
| `manifest.json` | MV3 manifest; injects the CSS and JS at `document_start` |
| `hn-dark.css` | The theme. Five palette tokens at the top, then sections per HN surface |
| `content.js` | Resolves system + inverted state into `data-hn-theme`, inserts the `theme` link |
| `icons/` | Generated PNGs (split dark/orange square with a Y) |
| `test/` | Saved HN pages, plus the assertions run against them |
| `scripts/` | Package, test, screenshot, version, and Chrome Web Store setup |
| `store/` | The listing copy and its graphic assets |
| `docs/chrome-web-store-release.md` | How a release reaches the store |

Those four are the whole extension: `manifest.json`, `hn-dark.css`,
`content.js`, `icons/`. Everything else is repo furniture and never ships —
`scripts/build-zip.sh` puts only those four in the package.

## Development

There is no build step and nothing to install. Edit the CSS, reload the
extension, look at Hacker News.

```sh
./scripts/smoke-test.sh          # assert the colors against saved HN pages
./scripts/build-zip.sh           # dist/hn-dark-<version>.zip, as the store gets it
./scripts/build-screenshots.sh   # regenerate store/screenshots/
```

The smoke test is the one worth knowing about. A theme layered over someone
else's stylesheet fails by cascade, not by exception: a plausible-looking edit
leaves text the same color as its background, and the diff looks fine. So
`test/fixtures/` holds real saved pages — front page, comment thread, a poll,
a `yc.css` doc page — with HN's own `news.css` and `yc.css` vendored beside
them, and `test/assertions.js` checks the computed colors that come out. Every
assertion in it is a shape that has actually broken.

It needs Chrome and `python3`, and nothing else. Note that headless Chrome no
longer loads unpacked extensions, so the test injects `content.js` the way the
manifest does rather than through the extension machinery.

## Releasing

```sh
# Write the CHANGELOG section for the new version first, then:
./scripts/bump-version.sh 0.0.2
git push --follow-tags
```

The tag runs [`.github/workflows/release.yml`](.github/workflows/release.yml),
which packages the extension, cuts a GitHub Release, and publishes the same zip
to the Chrome Web Store. The first submission has to be made by hand — see
[`docs/chrome-web-store-release.md`](docs/chrome-web-store-release.md).

## Privacy

No servers, no analytics, no network requests. One boolean is the only thing
stored. See [`PRIVACY.md`](PRIVACY.md).

## Implementation notes

- **No flash of light.** The CSS is a manifest content script, so Chrome applies
  it before first paint. `content.js` also runs at `document_start` and mirrors
  the setting into `localStorage`, which is synchronous — `chrome.storage` is
  async and would paint the wrong theme for a frame before resolving. The synced
  value reconciles a tick later.
- **Specificity, and the tax it charges.** The `html[data-hn-theme="dark"]` gate
  adds a type + attribute selector to every rule, which outranks HN's `news.css`
  at equal class counts — so no `!important` anywhere. The cost is that the
  gated `a:link` rule also outranks `news.css`'s own one-class link rules
  (`.subtext a:link`, `.comhead a:link`, `.hnmore a:link`, `.topsel a:link`,
  `.pagetop a:visited`), which would repaint HN's metadata as primary text.
  Section 4 restates those grays at HN's own values; it changes nothing
  visually, it just puts the cascade back.
- **`color-scheme: dark` does the form controls.** Submit buttons, checkboxes,
  radios and scrollbars are left native — which is what they are on HN — and
  the browser darkens them. Only text fields are painted, plus `input[readonly]`,
  which `news.css` fills with the light page cream.
- **Custom `topcolor` accounts.** Nothing overrides the header or footer
  `bgcolor` attribute, so a profile `topcolor` comes through untouched.
- **The vote arrows need no help.** HN's `triangle.svg` is filled `#999`, a
  mid-gray that reads on either background.
- **Poll options are `<font color="#000000">`.** A `color` attribute is a
  presentational hint on the `font` element itself, so `news.css`'s
  `td { color:#828282 }` never reaches it and the text really is black —
  invisible here until it is remapped. HN's only other `<font color>` is
  `#AFAFAF`, a deliberate downweight that reads fine on this ground, which is
  why the black is remapped on its own rather than with a blanket
  `font[color]` rule.
- **Downweighted comments.** Comment bodies take their color from HN's `c00`…`cdd`
  classes rather than from `.commtext`, so that ramp *is* the comment text color.
  `news.css` runs it `#000000`→`#dddddd`, fading toward a white page; it is
  inverted here to fade toward this one, ending just above the background
  exactly as HN's ends just below its own.
- **The doc pages are a second template.** Guidelines, FAQ, Security, Welcome
  and Bookmarklet ship `yc.css`, not `news.css`: no `#hnmain`, a `#fafaf0`
  panel on a `#ffffff` body, and no author color on the body text at all.
  `color-scheme: dark` turns that UA-default text white, which is invisible
  until the panel goes dark with it — section 8, keyed off the one
  `bgcolor="#fafaf0"` on the site. (`formatdoc` and `lists` look like these
  pages but are served with `news.css`.) The YC banner at the top of them is
  a GIF and stays white.
- **The one non-color rule.** `.hn-anim` transitions `color`, `background-color`
  and `border-color` for 180ms. `content.js` adds it on click only, so it never
  applies on load and nothing ever moves.
- **Scope.** `news.ycombinator.com` only. HN's search results live on
  `hn.algolia.com`, a separate site with unrelated markup, and are not themed.

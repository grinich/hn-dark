# Hacker News Dark

A dark theme for news.ycombinator.com that follows your system appearance, with a
`theme` link in HN's own top bar to flip it.

## Install

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

Dark mode is a full restyle: a warm-neutral surface palette, HN's orange kept as
an accent for the active nav item and buttons rather than as a full bleed
header, brighter story titles against dimmer metadata, a system font stack at a
readable size, comment bodies at 13.5px/1.56 instead of 12px, subtle indent
guides down comment threads, inset code blocks, and a pill-shaped **More**
button.

**Light mode is untouched, deliberately.** Every rule in `hn-dark.css` is gated
behind `html[data-hn-theme="dark"]`, so flipping to light gives you back
byte-for-byte vanilla HN — same Verdana, same cream, same orange bar. If you'd
rather keep the typography improvements in light mode too, lift the rules in
section 3 of `hn-dark.css` out of that gate.

## Files

| File | Role |
| --- | --- |
| `manifest.json` | MV3 manifest; injects the CSS and JS at `document_start` |
| `hn-dark.css` | The theme. Palette tokens at the top, then sections per HN surface |
| `content.js` | Resolves system + inverted state into `data-hn-theme`, inserts the `theme` link |
| `icons/` | Generated PNGs (split dark/orange square with a Y) |

## Implementation notes

- **No flash of light.** The CSS is a manifest content script, so Chrome applies
  it before first paint. `content.js` also runs at `document_start` and mirrors
  the setting into `localStorage`, which is synchronous — `chrome.storage` is
  async and would paint the wrong theme for a frame before resolving. The synced
  value reconciles a tick later.
- **Specificity over `!important`.** The `html[data-hn-theme="dark"]` gate adds
  a type + attribute selector to every rule, which outranks HN's `news.css` at
  equal class counts. `!important` is used only where HN sets a value in an
  inline `style` attribute (the logo's white border, the story spacer height).
- **Custom `topcolor` accounts.** If your HN profile sets a custom top bar
  color, HN paints both the header cell and the footer rule in it. Both are
  overridden — the footer rule matches on `td[bgcolor]:empty` rather than on a
  specific hex, so it works for any `topcolor`.
- **Downweighted comments.** HN dims flagged comments through a `c00`…`cdd`
  class ramp that runs dark-to-light for a white page. The ramp is re-mapped
  light-to-dark so the ordering still reads as "progressively quieter".
- **Scope.** `news.ycombinator.com` only. HN's search results live on
  `hn.algolia.com`, a separate site with unrelated markup, and are not themed.

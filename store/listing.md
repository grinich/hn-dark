# Chrome Web Store listing

Everything the developer console asks for on a first submission, written out to
be pasted. Field names match the console's own labels.

---

## Store listing

**Item name** (45 char limit)

```
Hacker News Dark
```

> See "Known review risks" in [`../docs/chrome-web-store-release.md`](../docs/chrome-web-store-release.md):
> if a reviewer objects to leading with the product name, `Dark Mode for Hacker News`
> is the shape that reliably passes.

**Summary** (132 char limit — this is the manifest `description`, and the
console prefills it)

```
Dark mode for Hacker News. Only the colors change — same layout, same Verdana. Follows your system appearance.
```

**Description**

```
A dark theme for news.ycombinator.com that changes the colors and nothing else.

Hacker News is a table layout in 10pt Verdana with 5px between the stories, and
that is exactly what you keep. No system font stack, no rounded corners, no
extra padding, no restyled buttons, no "improved" spacing. Same page, dark.

FOLLOWS YOUR SYSTEM

Dark when your computer is in dark mode, light when it isn't. When macOS or
Windows flips at sunset, Hacker News flips with it.

If you'd rather have the opposite — dark HN on a light desktop, or the reverse —
click the "theme" link that appears in HN's own top bar, right of login. The
setting is stored relative to your system rather than as a fixed choice, so
automatic switching keeps working in whichever direction you picked. It syncs
across your signed-in Chrome profiles and updates every open HN tab at once.

WHAT IT ACTUALLY DOES

HN's page is three grays plus the orange bar: white behind the table, cream
inside it, black for links and comment text, #828282 for everything secondary.
The first three are inverted around the page background. #828282 is left alone,
because it reads on either ground — and better on this one than on HN's cream.

The orange top bar stays orange, the logo keeps its white border, and the nav
keeps its black-on-orange. If you've set a custom topcolor in your HN profile,
that comes through untouched too.

Every page on the site is covered, including the ones that don't share HN's
stylesheet — Guidelines, FAQ and Security are a separate template that needs
its own handling, and poll options are painted by a color attribute that no
amount of CSS on the surrounding cell can reach.

NO FLASH OF LIGHT

The stylesheet ships as a content script, so Chrome applies it before the first
paint rather than after. You never see the white page appear and then correct
itself.

LIGHT MODE IS UNTOUCHED

Every rule is gated behind a single attribute. Switch to light and you get
byte-for-byte vanilla Hacker News back — the extension contributes nothing.

NO DATA COLLECTION

No servers, no accounts, no analytics, and no network requests of any kind. The
extension stores exactly one true/false value: whether to match your system
appearance or invert it. It runs on news.ycombinator.com and nowhere else, and
it never reads the content of the page.

The whole thing is one CSS file, one JavaScript file and four icons — around
350 lines, all of it readable at github.com/grinich/hn-dark.

Not affiliated with, endorsed by, or associated with Hacker News or
Y Combinator.
```

**Category**

```
Functionality & UI
```

**Language**

```
English
```

---

## Graphic assets

| Asset | File | Size |
| --- | --- | --- |
| Store icon | `../icons/icon128.png` | 128×128 |
| Screenshot 1 | `screenshots/1-front-page.png` | 1280×800 |
| Screenshot 2 | `screenshots/2-comments.png` | 1280×800 |
| Screenshot 3 | `screenshots/3-same-layout.png` | 1280×800 |
| Screenshot 4 | `screenshots/4-theme-link.png` | 1280×800 |
| Small promo tile | `promo-tile-440x280.png` | 440×280 |

---

## Privacy practices

**Single purpose description**

```
Hacker News Dark restyles news.ycombinator.com in dark colors. That is its only
function: it applies a stylesheet to one site, and adds a link to that site's
header for switching between matching and inverting the system appearance.
```

**Permission justification — `storage`**

```
The extension stores one boolean: whether the theme should match the system
appearance or be the opposite of it. It is written when the user clicks the
"theme" link in the header and read on page load to decide which way to paint
the page. chrome.storage.sync is used so the choice follows the user's Chrome
profile across their own devices and updates other open tabs. Nothing else is
stored, and the value never leaves the user's browser.
```

**Permission justification — host permission `*://news.ycombinator.com/*`**

```
This is the site being themed. The content script injects the stylesheet and
sets one attribute on the <html> element so the stylesheet can take effect, and
inserts the "theme" link into the site's own header. It runs on this host only,
makes no network requests, and does not read the content of the page.
```

**Remote code** — No. Everything executed is in the package; there is no
`eval`, no injected `<script src>`, and no remote configuration.

**Data usage** — every box unchecked. The extension collects none of:

| Category | Collected |
| --- | --- |
| Personally identifiable information | No |
| Health information | No |
| Financial and payment information | No |
| Authentication information | No |
| Personal communications | No |
| Location | No |
| Web history | No |
| User activity | No |
| Website content | No |

**The three certifications** — all three can be checked truthfully:

- I do not sell or transfer user data to third parties, outside of the approved
  use cases
- I do not use or transfer user data for purposes that are unrelated to my
  item's single purpose
- I do not use or transfer user data to determine creditworthiness or for
  lending purposes

**Privacy policy URL**

```
https://github.com/grinich/hn-dark/blob/main/PRIVACY.md
```

---

## Distribution

- **Visibility**: Public
- **Distribution**: All regions
- **Pricing**: Free

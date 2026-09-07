# Chrome Web Store listing

Every field the developer console asks for, in the order the console asks for
it, written to be pasted. Character counts are against the console's own limits.

**Item ID:** `gkmchehifmhmmnmlpkmafggdnmaobhgn`
**Listing:** https://chromewebstore.google.com/detail/gkmchehifmhmmnmlpkmafggdnmaobhgn
**Console:** https://chrome.google.com/webstore/devconsole

---

# Package

Upload `dist/hn-dark-<version>.zip` from `./scripts/build-zip.sh`.

The **store icon is not a separate upload** — it is the 128×128 icon inside the
ZIP. It is 96×96 of artwork centred in a 128×128 canvas with 16px of
transparent padding on every side, which is what Google specifies.

---

# Store listing

**Item name** — 45 char limit

```
Hacker News Dark
```

> If a reviewer objects to a name that leads with someone else's product name,
> `Dark Mode for Hacker News` is the shape that reliably passes. See "Known
> review risks" in [`../docs/chrome-web-store-release.md`](../docs/chrome-web-store-release.md).

**Summary** — 132 char limit. Prefilled from the manifest `description`.

```
Dark mode for Hacker News. Only the colors change — same layout, same Verdana. Follows your system appearance.
```

**Description** — 16,000 char limit

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

**Category:** `Functionality & UI`
**Language:** `English`

**Graphic assets**

| Field | File | Size |
| --- | --- | --- |
| Screenshot 1 | `screenshots/1-front-page.png` | 1280×800 |
| Screenshot 2 | `screenshots/2-comments.png` | 1280×800 |
| Screenshot 3 | `screenshots/3-same-layout.png` | 1280×800 |
| Screenshot 4 | `screenshots/4-theme-link.png` | 1280×800 |
| Small promo tile | `promo-tile-440x280.png` | 440×280 |

---

# Privacy

## Single purpose description — 1,000 char limit (used: 250)

```
Hacker News Dark restyles news.ycombinator.com in dark colors. That is its only function. It applies a stylesheet to that one site, and adds a link to that site's header so the reader can switch between matching and inverting their system appearance.
```

## Permission justification

### `storage` justification — 1,000 char limit (used: 516)

```
The extension stores one boolean: whether the theme should match the system appearance or be the opposite of it. It is written when the user clicks the "theme" link in the header, and read on page load to decide which way to paint the page. chrome.storage.sync is used so that the choice follows the user's own Chrome profile across their devices and updates other open tabs. Nothing else is stored, the value never leaves the user's browser, and removing the extension removes it. No other data is read or retained.
```

### Host permission justification — 1,000 char limit (used: 668)

```
The single host is news.ycombinator.com, the site the extension themes. It is declared in content_scripts rather than as a broad host permission, so the extension cannot run anywhere else.

On that host the content script does two things: it sets one attribute on the <html> element, which is the switch the bundled stylesheet is gated on, and it inserts a "theme" link into the page's existing header so the user can flip between matching and inverting their system appearance.

It does not read the content of the page — not story titles, comments, usernames, or whether the user is signed in. It makes no network requests of any kind, and it sends nothing anywhere.
```

> The console warns that a host permission "may require an in-depth review which
> will delay publishing." Expect that; a single named host with no data
> collection is the easy case, but it is still a slower path than none.

### Are you using remote code?

**`No, I am not using Remote code`**

Everything executed ships in the package: one CSS file and one JavaScript file.
No `<script src>`, no modules pointing at external files, no `eval()`, no
remote configuration.

## Data usage

**Leave every box unchecked.** The extension collects none of it:

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

"Website content" is the one worth a second look, since a content script *could*
read the page. This one does not — it sets an attribute and appends a link.

## Certifications — check all three

- ☑ I do not sell or transfer user data to third parties, outside of the approved use cases
- ☑ I do not use or transfer user data for purposes that are unrelated to my item's single purpose
- ☑ I do not use or transfer user data to determine creditworthiness or for lending purposes

## Privacy policy URL — 2,048 char limit

```
https://github.com/grinich/hn-dark/blob/main/PRIVACY.md
```

---

# Distribution

- **Visibility:** Public
- **Distribution:** All regions
- **Pricing:** Free

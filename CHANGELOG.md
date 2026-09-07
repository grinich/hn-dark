# Changelog

## 0.0.1

First public release.

A dark theme for news.ycombinator.com that changes only the colors. The layout
is vanilla HN: same Verdana, same 10pt/9pt/7pt scale, same 5px story spacers,
same table widths, same square corners, same orange top bar — a profile
`topcolor` included.

- Follows your system appearance, with a `theme` link in HN's own top bar to
  flip it. The stored state is *relative* to the system, so when macOS or
  Windows switches at sunset, HN switches with it in whichever direction you
  last chose.
- The choice syncs across your Chrome profiles through `chrome.storage.sync`
  and updates every open HN tab at once.
- No flash of light on load: the CSS is a manifest content script, so Chrome
  applies it before first paint.
- Light mode is byte-for-byte vanilla HN — every rule is gated behind
  `html[data-hn-theme="dark"]`.
- Themes every page template on the site, including the `yc.css` document
  pages (Guidelines, FAQ, Security) that don't share HN's stylesheet.
- No network requests, no analytics, no data collection. One boolean is the
  only thing stored.

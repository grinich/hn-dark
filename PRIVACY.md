# Privacy Policy for Hacker News Dark

_Last updated: 6 September 2026_

Hacker News Dark is a Chrome extension that restyles news.ycombinator.com in
dark colors. It is an independent project and is **not affiliated with,
endorsed by, or associated with Hacker News or Y Combinator**.

## The short version

The extension collects nothing. There is no server, no account, no analytics,
and no network request of any kind. It stores exactly one value — a single
true/false — and that value never leaves your own Chrome profile.

## What it stores

One boolean, under the key `invert`:

- `false` — the theme matches your system appearance (the default)
- `true` — the theme is the opposite of your system appearance

It is written when you click the `theme` link in Hacker News' top bar, and read
on every page load to decide which way round to paint the page.

It is kept in two places, both local to your browser:

- **`chrome.storage.sync`**, the source of truth. Chrome replicates this to
  your other signed-in Chrome instances, the same way it syncs your bookmarks.
  That replication is between you and Google; the developer of this extension
  has no access to it and no way to read it.
- **`localStorage` on news.ycombinator.com**, as a mirror. `chrome.storage` is
  asynchronous, which would mean a frame of the wrong theme on every page load;
  `localStorage` is synchronous, so it is read first and reconciled a moment
  later.

You can erase both at any time by removing the extension.

## What it does not do

The extension does not collect, transmit, sell, or share any data. Concretely,
it does not handle:

- personally identifiable information, names, addresses, or email addresses
- health, financial, or payment information
- authentication information, passwords, or credentials
- personal communications — it never reads the text of any story or comment
- location
- web browsing history, clicks, mouse position, or scroll position
- your Hacker News username, karma, votes, or whether you are logged in at all

It makes **no network requests**. It has no host permissions beyond the single
site it themes, no background service worker, no remote code, and no third-party
libraries. The entire extension is one CSS file, one JavaScript file, four PNG
icons, and a manifest — around 350 lines in total, all of it readable at
<https://github.com/grinich/hn-dark>.

## What it can see, and why that is narrower than it sounds

The content script runs on `news.ycombinator.com` and nowhere else, so pages on
every other site are outside its reach entirely.

On Hacker News itself, a content script is technically able to read the page it
runs in. This one does not. Its whole job is to set one attribute on the `<html>`
element and to add a `theme` link to the header, and the source is short enough
to confirm that by reading it.

## Permissions

| Permission | Why |
| --- | --- |
| `storage` | To remember the single boolean above, and to sync it across your own Chrome profiles |
| `news.ycombinator.com` | The site being themed. The extension does not run anywhere else |

## Changes

If this policy ever changes, the new version will be committed to this
repository and the date at the top will be updated. The commit history is the
full record.

## Contact

Open an issue at <https://github.com/grinich/hn-dark/issues>.

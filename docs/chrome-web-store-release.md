# Releasing to the Chrome Web Store

The first submission is manual. Every one after that is a tag.

That split is not a choice — the Chrome Web Store API can upload a package and
publish it, but it cannot create a listing, write a description, set a category,
upload screenshots, or answer the privacy disclosures. Those exist only in the
developer console, and the console cannot be driven by a browser extension
either: Chrome hardcodes `chromewebstore.google.com` as un-scriptable, so no
automation reaches it. Do the first one by hand.

## One time: create the listing

1. **Pay the developer fee.** $5, once per Google account, at the
   [developer dashboard](https://chrome.google.com/webstore/devconsole). Use the
   account that should own the listing forever — moving an item between accounts
   later is a support ticket, not a setting.

2. **Build the package.**

   ```sh
   ./scripts/build-zip.sh        # -> dist/hn-dark-<version>.zip
   ```

3. **Upload it** as a new item, then fill in the listing. Everything you need to
   paste — summary, description, category, permission justifications, and the
   privacy disclosure answers — is written out in
   [`store/listing.md`](../store/listing.md). The screenshots and the promo tile
   are in [`store/`](../store/).

4. **Submit for review.** First reviews have historically taken anywhere from a
   few hours to a couple of weeks. A theme with one host permission, no remote
   code and no data collection is about as simple as a review gets, but see
   [Known review risks](#known-review-risks) below.

5. **Record the ID.** Once the item exists, its 32-character ID is in the
   listing URL: `https://chromewebstore.google.com/detail/<id>`. Keep it — the
   next step needs it, and it never changes.

## One time: let CI publish

```sh
./scripts/setup-cws-secrets.sh
```

It asks for the extension ID and a Google OAuth client, opens the consent
screen, catches the callback on a loopback port, verifies the token can
actually reach *your* listing, and writes three secrets plus one variable to
the repo. Nothing touches disk or argv.

The OAuth client is a **Desktop app** client in a Google Cloud project with the
**Chrome Web Store API** enabled, created under the same Google account that
owns the listing. If the consent screen is left in *Testing* the refresh token
expires every seven days; move it to *In production* and it lasts until you
revoke it at [myaccount.google.com/permissions](https://myaccount.google.com/permissions).

## Every time after that

```sh
# 1. Write the section for the new version at the top of CHANGELOG.md.
# 2. Then:
./scripts/bump-version.sh 0.0.2
git push --follow-tags
```

`bump-version.sh` refuses to run on a dirty tree, refuses a version with no
CHANGELOG section, runs the smoke test, then commits the manifest and tags it.
Pushing the tag runs [`.github/workflows/release.yml`](../.github/workflows/release.yml),
which packages the extension, checks the tag matches the manifest, cuts a
GitHub Release with the CHANGELOG section as its notes, and uploads and
publishes the same zip to the store.

Two deliberate behaviours in that workflow:

- **A hyphenated tag is a beta.** `v0.1.0-rc.1` is marked as a prerelease on
  GitHub and skips the store entirely.
- **Missing store credentials skip, they don't fail.** Tagging works before the
  listing exists; the store job just reports that it was skipped.

## Known review risks

Worth knowing before the first submission, in rough order of likelihood:

- **The name.** "Hacker News Dark" leads with someone else's product name.
  Chrome Web Store policy allows referring to a product you're compatible with
  but not implying you are it, and reviewers apply that unevenly to names that
  *start* with the trademark. "Dark Mode for Hacker News" is the shape that
  reliably passes. The description already carries the disclaimer either way.
- **The icon.** A white Y on an orange square is close to Y Combinator's mark.
  If a rejection cites trademark or impersonation, the icon is the first thing
  to change, not the name.
- **Single purpose.** Fine here — one theme, one site — but it is the rule most
  first submissions trip over, so keep it that way.
- **Host permission breadth.** `*://news.ycombinator.com/*` is a single host,
  which is the easy case. Adding `hn.algolia.com` later would need its own
  justification.

## If a release fails

- `Upload rejected` with `MANIFEST_ERROR` — usually a version that is not
  strictly greater than the published one. The store never accepts a re-upload
  of the same version; bump and tag again.
- `Could not mint an access token` — the refresh token was revoked, or the
  consent screen fell back to *Testing*. Re-run `setup-cws-secrets.sh`.
- `ITEM_PENDING_REVIEW` in the summary is success, not a failure: the package
  is uploaded and queued. Nothing more to do.

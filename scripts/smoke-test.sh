#!/usr/bin/env bash
#
# Load saved Hacker News pages with the real content script and the real
# stylesheet, and assert the colors that come out.
#
#   ./scripts/smoke-test.sh
#
# Why this exists: the theme is layered over someone else's stylesheet, so its
# failures are cascade failures — text the same color as its background, with
# nothing wrong-looking in the diff. Every assertion in test/assertions.js is
# a shape that has actually broken.
#
# Chrome will not load an unpacked extension in headless mode any more, so the
# content script is injected the same way the manifest injects it (at
# document_start, before the page's own markup is parsed) rather than through
# the extension machinery. The fixtures are served over HTTP because the
# script's localStorage fast path needs a real origin; file:// has none.
#
# Needs: Google Chrome, python3. No npm, no node, nothing to install.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. "$(dirname "${BASH_SOURCE[0]}")/chrome.sh"
find_chrome

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"; [ -n "${SERVER_PID:-}" ] && kill "$SERVER_PID" 2>/dev/null || true' EXIT

cp hn-dark.css content.js "$WORK/"
cp test/assertions.js "$WORK/"
# The stylesheets, the saved pages, and the three assets HN's markup
# references relatively (the Y logo, the vote arrow, the 1x1 spacer that
# carries comment indentation). Without the last group the pages render
# with broken-image icons where the chrome should be.
cp test/fixtures/* "$WORK/"

# One runner per fixture: the saved page, with the extension's own two files
# injected into <head> exactly as the manifest would, plus the assertions at
# the end of <body>.
#
# The seeded `invert` is computed in the page rather than hardcoded, because
# the theme is deliberately *relative* to the system: hardcoding it would make
# the test pass or fail depending on whether the machine running it happens to
# be in dark mode. Deriving it exercises the real relationship — theme =
# system XOR invert — and pins the outcome either way.
python3 - "$WORK" <<'PY'
import sys, pathlib, re

work = pathlib.Path(sys.argv[1])
cases = [
    ("news", "news.html", "dark"),
    ("item", "item.html", "dark"),
    ("poll", "poll.html", "dark"),
    ("guidelines", "guidelines.html", "dark"),
    ("light", "news.html", "light"),  # the extension must add nothing here
]

for name, fixture, want in cases:
    html = (work / fixture).read_text(encoding="utf-8")
    head = (
        # HN sends its charset in the Content-Type header, not the markup, and
        # http.server does not reproduce that — without this the fixtures are
        # decoded as windows-1252.
        '<meta charset="utf-8">'
        "<script>(function(){"
        "var systemDark=matchMedia('(prefers-color-scheme: dark)').matches;"
        "try{localStorage.setItem('hnDark:invert',systemDark!==%s?'1':'0')}catch(e){}"
        "window.__HN_TEST_FIXTURE='%s';})();</script>"
        '<link rel="stylesheet" href="hn-dark.css">'
        '<script src="content.js"></script>'
    ) % ("true" if want == "dark" else "false", name)

    if "<head>" in html:
        html = html.replace("<head>", "<head>" + head, 1)
    else:  # the yc.css pages open with <html>\n<head> on separate lines
        html = re.sub(r"(<head>)", r"\1" + head, html, count=1)

    html = html.replace("</body>", '<script src="assertions.js"></script></body>', 1)
    if "assertions.js" not in html:  # some HN pages have no </body> at all
        html += '<script src="assertions.js"></script>'

    (work / f"run-{name}.html").write_text(html, encoding="utf-8")
    print(name)
PY

# A real origin, so localStorage works and the stylesheet loads the way it
# does in the browser.
serve_dir "$WORK"

PROFILE="$WORK/profile"
failures=0
total=0

for name in news item poll guidelines light; do
  # The assertions write into <pre id="hn-test-results">; that is what the
  # guard waits for before stopping the browser.
  chrome_run "$WORK/dom-$name.html" 'grep -q hn-test-results "$1"' \
    --user-data-dir="$PROFILE" --virtual-time-budget=5000 \
    --dump-dom "http://127.0.0.1:$SERVE_PORT/run-$name.html" || true
  DOM=$(cat "$WORK/dom-$name.html" 2>/dev/null || true)

  RESULTS=$(printf '%s' "$DOM" | python3 -c '
import sys, re, html
dom = sys.stdin.read()
match = re.search(r"<pre id=\"hn-test-results\">(.*?)</pre>", dom, re.S)
print(html.unescape(match.group(1)) if match else "FAIL assertions did not run")
')

  printf '\n%s\n' "$name"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    total=$((total + 1))
    case "$line" in
      PASS*) printf '  \033[32m✓\033[0m %s\n' "${line#PASS }" ;;
      *)     printf '  \033[31m✗\033[0m %s\n' "${line#FAIL }"; failures=$((failures + 1)) ;;
    esac
  done <<< "$RESULTS"
done

printf '\n%d checks, %d failed\n' "$total" "$failures"
[ "$failures" -eq 0 ] || exit 1

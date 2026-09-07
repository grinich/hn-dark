#!/usr/bin/env bash
#
# Regenerate the Chrome Web Store screenshots and promo tile.
#
#   ./scripts/build-screenshots.sh        -> store/screenshots/*.png, store/promo-tile-440x280.png
#
# The store wants 1280x800. These are real renders of the real stylesheet over
# the saved pages in test/fixtures — the same fixtures the smoke test uses, so
# the screenshots cannot drift from what the extension actually does.
#
# Needs: Google Chrome, python3.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. "$(dirname "${BASH_SOURCE[0]}")/chrome.sh"
find_chrome

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"; [ -n "${SERVER_PID:-}" ] && kill "$SERVER_PID" 2>/dev/null || true' EXIT

cp hn-dark.css content.js "$WORK/"
# The stylesheets, the saved pages, and the three assets HN's markup
# references relatively (the Y logo, the vote arrow, the 1x1 spacer that
# carries comment indentation). Without the last group the pages render
# with broken-image icons where the chrome should be.
cp test/fixtures/* "$WORK/"

python3 - "$WORK" <<'PY'
import sys, pathlib

work = pathlib.Path(sys.argv[1])

# name, fixture, wanted theme. The invert flag is derived in the page from the
# machine's own appearance setting, so these come out the same whether the
# machine running the script is in light or dark mode.
for name, fixture, want in [
    ("front-dark", "news.html", "dark"),
    ("front-light", "news.html", "light"),
    ("comments-dark", "item.html", "dark"),
    ("front-dark-zoom", "news.html", "dark"),  # same page, rendered larger
]:
    html = (work / fixture).read_text(encoding="utf-8")
    head = (
        # Without this the saved markup is decoded as windows-1252 and every
        # em dash in a story title renders as mojibake.
        '<meta charset="utf-8">'
        "<script>(function(){"
        "var systemDark=matchMedia('(prefers-color-scheme: dark)').matches;"
        "try{localStorage.setItem('hnDark:invert',systemDark!==%s?'1':'0')}catch(e){}"
        "})();</script>"
        '<link rel="stylesheet" href="hn-dark.css">'
        '<script src="content.js"></script>'
    ) % ("true" if want == "dark" else "false")
    (work / f"{name}.html").write_text(html.replace("<head>", "<head>" + head, 1), encoding="utf-8")

# The "only the colors change" shot: one page, light above, dark below, cut
# across the middle. Horizontally rather than vertically because HN's titles
# are left-weighted — a vertical cut would put the dark half where the page is
# mostly empty. Both halves are the same render, so the row rhythm continues
# straight through the seam, which is the whole claim.
(work / "split.html").write_text("""<!doctype html><meta charset="utf-8">
<style>
  html,body{margin:0;width:1280px;height:800px;overflow:hidden;background:#121212}
  img{position:absolute;inset:0;width:1280px;height:800px}
  .dark{clip-path:inset(400px 0 0 0)}
  .seam{position:absolute;left:0;top:399px;width:1280px;height:2px;background:#ff6600}
</style>
<img src="shot-front-light.png"><img class="dark" src="shot-front-dark.png">
<div class="seam"></div>
""", encoding="utf-8")

(work / "promo.html").write_text("""<!doctype html><meta charset="utf-8">
<style>
  html,body{margin:0;width:440px;height:280px;overflow:hidden}
  body{background:#121212;display:grid;place-items:center;
       font:400 13px Verdana,Geneva,sans-serif;color:#828282}
  .card{width:376px}
  .bar{background:#ff6600;color:#000;font-weight:700;font-size:12px;
       padding:5px 8px;display:flex;gap:6px;align-items:center}
  .y{width:13px;height:13px;border:1px solid #fff;color:#fff;font-size:10px;
     display:grid;place-items:center;font-weight:700}
  .nav{font-weight:400}
  .body{background:#1a1a1a;padding:10px 8px 12px}
  .row{margin-bottom:7px;line-height:1.35}
  .t{color:#e0e0e0}
  .m{font-size:10px}
  h1{margin:0 0 10px;font:600 19px -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
     color:#e0e0e0;letter-spacing:-.02em}
  h1 span{color:#ff6600}
  p{margin:9px 0 0;font-size:11px;color:#828282}
</style>
<div class="card">
  <h1>Hacker News, <span>dark</span></h1>
  <div class="bar"><span class="y">Y</span><span>Hacker News</span>
    <span class="nav">new | past | comments</span></div>
  <div class="body">
    <div class="row"><span class="t">1. &nbsp;Cloud in a Bottle: self-hosting for everyone</span><br>
      <span class="m">&nbsp;&nbsp;&nbsp;&nbsp;208 points by zplizzi 3 hours ago | 84 comments</span></div>
    <div class="row"><span class="t">2. &nbsp;Learn Programming with OCaml</span><br>
      <span class="m">&nbsp;&nbsp;&nbsp;&nbsp;194 points by elvis70 11 hours ago | 78 comments</span></div>
  </div>
  <p>Only the colors change. Same layout, same Verdana.</p>
</div>
""", encoding="utf-8")
PY

serve_dir "$WORK"

PROFILE="$WORK/profile"
shoot() { # name, window size, [device scale]
  # Stop the browser as soon as the PNG is complete.
  local png="$WORK/shot-$1.png"
  chrome_run "$WORK/chrome-$1.log" "png_complete '$png'" \
    --user-data-dir="$PROFILE" --force-device-scale-factor="${3:-1}" \
    --virtual-time-budget=6000 --window-size="$2" --screenshot="$png" \
    "http://127.0.0.1:$SERVE_PORT/$1.html" || true
  [ -s "$png" ] || { echo "error: no screenshot for $1" >&2; return 1; }
}

shoot front-dark 1280,800
shoot front-light 1280,800
shoot comments-dark 1280,800
# 800x500 at 1.6x lands on 1280x800 with everything large enough to read the
# "theme" link the content script adds to the header.
shoot front-dark-zoom 800,500 1.6

mkdir -p store/screenshots
cp "$WORK/shot-front-dark.png" store/screenshots/1-front-page.png
cp "$WORK/shot-comments-dark.png" store/screenshots/2-comments.png
cp "$WORK/shot-front-dark-zoom.png" store/screenshots/4-theme-link.png

# The split needs both halves rendered first.
shoot split 1280,800
cp "$WORK/shot-split.png" store/screenshots/3-same-layout.png

shoot promo 440,280
cp "$WORK/shot-promo.png" store/promo-tile-440x280.png

for f in store/screenshots/*.png store/promo-tile-440x280.png; do
  printf '%s  ' "$f"
  python3 - "$f" <<'PY'
import struct, sys
with open(sys.argv[1], "rb") as handle:
    handle.read(16)
    width, height = struct.unpack(">II", handle.read(8))
print(f"{width}x{height}")
PY
done

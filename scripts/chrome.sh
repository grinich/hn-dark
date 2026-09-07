#!/usr/bin/env bash
#
# Shared Chrome plumbing for smoke-test.sh and build-screenshots.sh.
# Sourced, not run.

# Locate a Chrome. CHROME=/path/to/chrome overrides the search.
find_chrome() {
  if [ -n "${CHROME:-}" ]; then
    [ -x "$CHROME" ] || { echo "error: CHROME=$CHROME is not executable" >&2; return 1; }
    return 0
  fi
  local candidate
  for candidate in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "$(command -v google-chrome-stable || true)" \
    "$(command -v google-chrome || true)" \
    "$(command -v chromium || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      CHROME="$candidate"
      return 0
    fi
  done
  echo "error: could not find Chrome. Set CHROME=/path/to/chrome" >&2
  return 1
}

# Run headless Chrome, wait for it to produce what we asked for, then kill it.
#
#   chrome_run <output file> <ready test> [chrome args...]
#
# Headless Chrome on macOS routinely writes its --screenshot or --dump-dom
# output and then never exits — there are 8-day-old ones in `ps` on this
# machine to prove it. Waiting on the process is therefore not an option, and
# there is no portable `timeout` on macOS either. So: watch for the artifact,
# and stop the browser the moment it appears. <ready test> is a shell snippet
# evaluated against "$1" = the output file; it should succeed once the file is
# complete.
chrome_run() {
  local out=$1 ready=$2
  shift 2

  rm -f "$out"

  # CI runners have no usable namespace sandbox; a developer machine does, and
  # should keep it.
  [ -n "${CI:-}" ] && set -- --no-sandbox "$@"

  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --no-first-run --no-default-browser-check "$@" >"$out" 2>/dev/null &
  local pid=$!

  # Ticks are 100ms, so the default cap is three minutes. That is generous on
  # purpose: Chrome's *first* launch against a fresh --user-data-dir builds the
  # profile and can take well over a minute on a cold machine, while every
  # launch after it against the same profile takes seconds.
  #
  # Wait on the artifact and nothing else. Not on the process: launching
  # Chrome on macOS can hand off to a browser that outlives the PID we
  # started, so "$pid has exited" says nothing about whether the work is done
  # — it is why there are 8-day-old headless Chromes in `ps` on this machine.
  # The ready test owns the whole verdict, including "the file exists at all";
  # --screenshot writes nothing to stdout, so checking $out for content here
  # would mean waiting out the cap on every screenshot.
  local waited=0
  while [ "$waited" -lt "${CHROME_WAIT_TICKS:-1800}" ]; do
    # pipefail off inside the test: a ready test is naturally a pipeline whose
    # consumer exits early (`... | grep -q`), which kills the producer with
    # SIGPIPE — and pipefail would then report the whole pipeline as failed
    # precisely when it succeeded.
    if ( set +o pipefail; set -- "$out"; eval "$ready" ) 2>/dev/null; then
      break
    fi
    sleep 0.1
    waited=$((waited + 1))
  done

  kill -9 "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  # Anything the handoff left behind, gone too — otherwise they accumulate.
  # Guarded: an empty PROFILE would make this pattern match every Chrome on
  # the machine, including the one the developer is reading this in.
  [ -n "${PROFILE:-}" ] && pkill -9 -f "user-data-dir=$PROFILE" 2>/dev/null
  true
}

# True once a PNG is completely written: its last 8 bytes are the IEND chunk
# type plus its CRC. Done in python rather than `tail | grep` because grep's
# handling of binary input varies between the greps on PATH — the BSD one on
# macOS reports no match on the same bytes GNU grep matches.
png_complete() {
  python3 -c 'import sys; sys.exit(0 if open(sys.argv[1],"rb").read()[-8:][:4] == b"IEND" else 1)' \
    "$1" 2>/dev/null
}

# Serve a directory over HTTP and export SERVE_PORT. The extension's
# localStorage fast path needs a real origin; file:// has none.
serve_dir() {
  local dir=$1
  SERVE_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
  python3 -m http.server "$SERVE_PORT" --bind 127.0.0.1 --directory "$dir" >/dev/null 2>&1 &
  SERVER_PID=$!
  local _
  for _ in $(seq 1 50); do
    curl -sf "http://127.0.0.1:$SERVE_PORT/" >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  echo "error: local server did not come up" >&2
  return 1
}

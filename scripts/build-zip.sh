#!/usr/bin/env bash
#
# Package the extension for the Chrome Web Store.
#
#   ./scripts/build-zip.sh          -> dist/hn-dark-<version>.zip
#
# There is no build step and no dependency to install: what ships is what is
# in the repo. This script exists to make sure only the five things Chrome
# needs go in the zip, and that the manifest is sane before it does.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Everything the extension needs at runtime, and nothing else. README, PRIVACY,
# docs/, scripts/, store/ and .github/ are repo furniture — shipping them just
# gives the reviewer more surface to ask about.
FILES=(manifest.json hn-dark.css content.js icons)

command -v zip >/dev/null 2>&1 || { echo "error: zip is not installed" >&2; exit 1; }

VERSION=$(python3 -c 'import json; print(json.load(open("manifest.json"))["version"])')

# The store rejects any uploaded manifest carrying a `key`, which is the field
# that pins a sideloaded extension to a fixed ID. This repo has never had one;
# fail loudly if that ever changes rather than at upload time.
python3 - <<'PY'
import json, sys

manifest = json.load(open("manifest.json"))
problems = []

if "key" in manifest:
    problems.append('manifest has a "key" field; the store rejects it')
if len(manifest.get("description", "")) > 132:
    problems.append("description is over the store's 132-character limit")
if len(manifest.get("name", "")) > 45:
    problems.append("name is over the store's 45-character limit")
if manifest.get("manifest_version") != 3:
    problems.append("manifest_version must be 3")

for key in ("16", "32", "48", "128"):
    if key not in manifest.get("icons", {}):
        problems.append(f"missing the {key}px icon")

if problems:
    print("\n".join("error: " + p for p in problems), file=sys.stderr)
    sys.exit(1)
PY

for path in "${FILES[@]}"; do
  [ -e "$path" ] || { echo "error: missing $path" >&2; exit 1; }
done

mkdir -p dist
ZIP="dist/hn-dark-$VERSION.zip"
rm -f "$ZIP"

# -X drops the extra file attributes (uid/gid, times) that make the archive
# differ run to run on the same tree.
zip -q -r -X "$ZIP" "${FILES[@]}" -x '**/.DS_Store'

echo "$ZIP"
# -Z1 is the one listing format that is identical on BSD and GNU unzip.
unzip -Z1 "$ZIP" | sed 's/^/  /'

#!/usr/bin/env bash
#
# Set the version, commit it, and tag it.
#
#   ./scripts/bump-version.sh 0.0.2
#   git push --follow-tags
#
# Write the CHANGELOG section for the new version first — the release workflow
# reads it back out as the GitHub Release notes, and refuses to guess.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

VERSION="${1:-}"
[ -n "$VERSION" ] || { echo "usage: $0 <version>   e.g. $0 0.0.2" >&2; exit 1; }

# Chrome wants one to four dot-separated integers, each 0-65535.
python3 - "$VERSION" <<'PY'
import sys
version = sys.argv[1]
parts = version.split(".")
if not 1 <= len(parts) <= 4 or not all(p.isdigit() and 0 <= int(p) <= 65535 for p in parts):
    sys.exit(f"error: {version!r} is not a valid Chrome extension version")
PY

[ -z "$(git status --porcelain)" ] || { echo "error: working tree is dirty" >&2; exit 1; }
git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null &&
  { echo "error: tag v$VERSION already exists" >&2; exit 1; }

grep -q "^## $VERSION\b" CHANGELOG.md ||
  { echo "error: CHANGELOG.md has no '## $VERSION' section yet" >&2; exit 1; }

python3 - "$VERSION" <<'PY'
import collections, json, sys
path = "manifest.json"
manifest = json.load(open(path), object_pairs_hook=collections.OrderedDict)
manifest["version"] = sys.argv[1]
with open(path, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2, ensure_ascii=False)
    handle.write("\n")
PY

./scripts/smoke-test.sh >/dev/null || { git checkout -- manifest.json; echo "error: smoke test failed" >&2; exit 1; }

git add manifest.json
git commit -q -m "Release $VERSION"
git tag -a "v$VERSION" -m "v$VERSION"

echo "Tagged v$VERSION. Push it with:  git push --follow-tags"

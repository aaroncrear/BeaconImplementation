#!/usr/bin/env bash
# Builds a delta package (package.xml + destructiveChanges.xml) of the metadata
# that changed since the last successful deploy to a target org.
#
# Usage: build-delta.sh <baseline-tag> <output-dir> [from-ref-override]
#
# The "from" commit is chosen in this order:
#   1. from-ref-override, if given (manual runs)
#   2. the baseline tag, which the workflow moves after every successful deploy
#   3. the commit where this branch split from master (first run)
# Diffing from the last *successful* deploy means a failed deploy's changes are
# retried on the next push, rather than being skipped.
set -euo pipefail

BASELINE_TAG="$1"
OUT_DIR="$2"
FROM_OVERRIDE="${3:-}"

if [[ -n "$FROM_OVERRIDE" ]]; then
  FROM="$(git rev-parse "$FROM_OVERRIDE^{commit}")"
  REASON="manual override ($FROM_OVERRIDE)"
elif git rev-parse -q --verify "refs/tags/$BASELINE_TAG" >/dev/null; then
  FROM="$(git rev-parse "refs/tags/$BASELINE_TAG^{commit}")"
  REASON="last successful deploy (tag $BASELINE_TAG)"
else
  FROM="$(git merge-base HEAD origin/master)"
  REASON="branch point from master (no previous deploy recorded)"
fi
TO="$(git rev-parse HEAD)"

echo "Delta from ${FROM:0:7} -> ${TO:0:7}: $REASON"

rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"
sf sgd source delta --from "$FROM" --to "$TO" --source-dir unpackaged \
  --output-dir "$OUT_DIR" --json > "$OUT_DIR/sgd-result.json"

PKG="$OUT_DIR/package/package.xml"
DESTRUCTIVE="$OUT_DIR/destructiveChanges/destructiveChanges.xml"
has_types() { [[ -f "$1" ]] && grep -q '<types>' "$1"; }

HAS_CHANGES=false; HAS_DELETES=false
has_types "$PKG" && HAS_CHANGES=true
has_types "$DESTRUCTIVE" && HAS_DELETES=true

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "from=$FROM"
    echo "to=$TO"
    echo "reason=$REASON"
    echo "has_changes=$HAS_CHANGES"
    echo "has_deletes=$HAS_DELETES"
  } >> "$GITHUB_OUTPUT"
fi
echo "has_changes=$HAS_CHANGES has_deletes=$HAS_DELETES"

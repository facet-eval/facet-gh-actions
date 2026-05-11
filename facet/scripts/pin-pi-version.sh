#!/usr/bin/env bash
# pin-pi-version.sh <spec-path> <facet-repo-path>
#
# Reads metadata.harness.version from <spec_path>/spec.yaml and pins the
# @mariozechner/pi-coding-agent dependency in <facet_repo_path> to that exact
# version when it diverges from the lockfile.
#
# Exit code is 0 on success or no-op. Non-zero only if the pnpm add command
# itself fails.

set -euo pipefail

SPEC_PATH="${1:?usage: pin-pi-version.sh <spec-path> <facet-repo-path>}"
FACET_REPO="${2:?facet repo path required}"

if [[ ! -f "$SPEC_PATH/spec.yaml" ]]; then
  echo "ERROR: $SPEC_PATH/spec.yaml not found" >&2
  exit 2
fi

if [[ ! -d "$FACET_REPO" ]]; then
  echo "ERROR: facet_repo_path '$FACET_REPO' is not a directory" >&2
  exit 2
fi

if ! python3 -c "import yaml" 2>/dev/null; then
  echo "  → installing pyyaml (needed for YAML parsing)"
  pip3 install --quiet pyyaml
fi

SPEC_VERSION=$(python3 - "$SPEC_PATH/spec.yaml" <<'PY'
import sys, yaml
with open(sys.argv[1]) as f:
    doc = yaml.safe_load(f) or {}
meta = doc.get('metadata') or {}
harness = meta.get('harness') or {}
print(harness.get('version') or '')
PY
)

if [[ -z "$SPEC_VERSION" ]]; then
  echo "  ℹ spec does not declare metadata.harness.version — skipping Pi SDK pin"
  exit 0
fi

LOCK_FILE="$FACET_REPO/pnpm-lock.yaml"
if [[ ! -f "$LOCK_FILE" ]]; then
  echo "  ⚠ no pnpm-lock.yaml at $LOCK_FILE — running pnpm add to install Pi SDK $SPEC_VERSION"
  ( cd "$FACET_REPO" && pnpm add "@mariozechner/pi-coding-agent@$SPEC_VERSION" --filter @facet/harness-pi )
  exit 0
fi

# Best-effort lockfile version extraction: pnpm-lock.yaml encodes deps as keys
# like "'@mariozechner/pi-coding-agent@0.70.2(...)'". Grab the version after @.
LOCK_VERSION=$(grep -oE "'@mariozechner/pi-coding-agent@[0-9][^()'@]*" "$LOCK_FILE" \
  | head -1 \
  | sed -E "s|.*pi-coding-agent@||" \
  || true)

if [[ -z "$LOCK_VERSION" ]]; then
  echo "  ⚠ could not detect current Pi SDK version in lockfile — running pnpm add"
  ( cd "$FACET_REPO" && pnpm add "@mariozechner/pi-coding-agent@$SPEC_VERSION" --filter @facet/harness-pi )
  exit 0
fi

if [[ "$LOCK_VERSION" == "$SPEC_VERSION" ]]; then
  echo "  ✓ Pi SDK $SPEC_VERSION already pinned in lockfile"
  exit 0
fi

echo "  → Pi SDK version drift: lockfile=$LOCK_VERSION spec=$SPEC_VERSION — pinning to spec"
( cd "$FACET_REPO" && pnpm add "@mariozechner/pi-coding-agent@$SPEC_VERSION" --filter @facet/harness-pi )
echo "  ✓ pinned Pi SDK to $SPEC_VERSION"

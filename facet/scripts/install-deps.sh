#!/usr/bin/env bash
# install-deps.sh <experiment-package-path>
#
# Reads ALL scenarios and ALL referenced profiles in the spec tree and installs
# the union of all their declared binaries BEFORE Pi Coding Agent starts.
#
# Designed for Ubuntu runners (apt-based). On other OSes, extend bin-map.sh
# with alternative install helpers — the traversal logic here stays the same.
#
# Inputs:
#   $1                 — path to the experiment package directory (with spec.yaml).
#   FACET_REPO_PATH    — (env, optional) path to the FACET monorepo so that
#                        npm-style profile refs (e.g. "@facet/preset-pi-graph")
#                        can be resolved via <repo>/node_modules/<ref>/. If unset,
#                        falls back to the current working directory.
#   DRY_RUN=1          — (env, optional) preview installs without executing them.
#
# Exit code: 0 if all required binaries are installed or already present,
#            non-zero only if a binary install command itself failed.
# Unknown binaries (no recipe in bin-map.sh) produce a warning but do not fail —
# `pnpm facet spec validate` is the authoritative gate that catches them.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./bin-map.sh
source "$SCRIPT_DIR/bin-map.sh"

SPEC_PATH="${1:?usage: install-deps.sh <experiment-package-path>}"
FACET_REPO_PATH="${FACET_REPO_PATH:-$PWD}"

if [[ ! -f "$SPEC_PATH/spec.yaml" ]]; then
  echo "ERROR: $SPEC_PATH/spec.yaml not found" >&2
  exit 2
fi

# --- Bootstrap pyyaml --------------------------------------------------------

if ! python3 -c "import yaml" 2>/dev/null; then
  echo "  → installing pyyaml (needed for YAML parsing)"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "    [dry-run] pip3 install pyyaml"
  else
    pip3 install --quiet pyyaml
  fi
fi

# --- YAML helpers ------------------------------------------------------------

# yaml_read <file> <python expr that returns iterable or scalar from 'doc'>
yaml_eval() {
  local file="$1"
  local expr="$2"
  python3 - "$file" <<PY
import sys, yaml
with open(sys.argv[1]) as f:
    doc = yaml.safe_load(f) or {}
result = (lambda doc: $expr)(doc)
if result is None:
    pass
elif isinstance(result, (list, tuple, set)):
    for v in result:
        if v is not None:
            print(v)
else:
    print(result)
PY
}

# --- Step 1: Parse spec.yaml -------------------------------------------------

echo "  Experiment package: $SPEC_PATH"

# scenario refs (relative paths from spec_path)
mapfile -t SCENARIO_REFS < <(yaml_eval "$SPEC_PATH/spec.yaml" \
  "[ s.get('ref') for s in (doc.get('scenarios') or []) if isinstance(s, dict) and s.get('ref') ]")

# profile refs (npm package names like '@facet/preset-pi-default' or local paths)
mapfile -t PROFILE_REFS < <(yaml_eval "$SPEC_PATH/spec.yaml" \
  "[ l.get('ref') for f in (doc.get('varying_factors') or []) if isinstance(f, dict) and f.get('id') == 'profile' for l in (f.get('levels') or []) if isinstance(l, dict) and l.get('ref') ]")

echo "  Scenarios: ${SCENARIO_REFS[*]:-<none>}"
echo "  Profile refs: ${PROFILE_REFS[*]:-<none>}"
echo ""

# --- Step 2: Collect binaries from scenarios ---------------------------------

declare -A BIN_SET=()
declare -A ORIGIN=()

remember() {
  local bin="$1" origin="$2"
  BIN_SET["$bin"]=1
  if [[ -z "${ORIGIN[$bin]:-}" ]]; then
    ORIGIN["$bin"]="$origin"
  else
    ORIGIN["$bin"]="${ORIGIN[$bin]}, $origin"
  fi
}

for ref in "${SCENARIO_REFS[@]}"; do
  meta="$SPEC_PATH/$ref/meta.yaml"
  if [[ ! -f "$meta" ]]; then
    echo "  ⚠ scenario meta missing: $meta — skipping"
    continue
  fi
  scenario_id=$(yaml_eval "$meta" "doc.get('id') or ''")
  mapfile -t bins < <(yaml_eval "$meta" "doc.get('requires_binaries') or []")
  for b in "${bins[@]}"; do
    [[ -z "$b" ]] && continue
    remember "$b" "scenario $scenario_id"
  done
done

# --- Step 3: Resolve and collect binaries from profile extensions ------------

resolve_profile_extensions() {
  local ref="$1"
  if [[ "$ref" == @* ]]; then
    # npm-style: <facet_repo>/node_modules/<ref>/profile/extensions.yaml
    local candidate="$FACET_REPO_PATH/node_modules/$ref/profile/extensions.yaml"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    # workspace fallback: <facet_repo>/packages/<name>/profile/extensions.yaml
    local name="${ref#@*/}"
    candidate="$FACET_REPO_PATH/packages/$name/profile/extensions.yaml"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    return 1
  fi
  # local path relative to spec_path
  local candidate="$SPEC_PATH/$ref/extensions.yaml"
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  candidate="$SPEC_PATH/$ref/profile/extensions.yaml"
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

for ref in "${PROFILE_REFS[@]}"; do
  if ext_file=$(resolve_profile_extensions "$ref"); then
    # top-level requires_binaries
    mapfile -t bins < <(yaml_eval "$ext_file" "doc.get('requires_binaries') or []")
    for b in "${bins[@]}"; do
      [[ -z "$b" ]] && continue
      remember "$b" "profile $ref"
    done
    # per-scenario requires_binaries
    mapfile -t per_scn < <(yaml_eval "$ext_file" \
      "[ b for arr in (doc.get('requires_binaries_per_scenario') or {}).values() if isinstance(arr, list) for b in arr ]")
    for b in "${per_scn[@]}"; do
      [[ -z "$b" ]] && continue
      remember "$b" "profile $ref (per-scenario)"
    done
    # language_servers — values may be strings or lists of strings
    mapfile -t lang < <(yaml_eval "$ext_file" \
      "[ s for v in (doc.get('language_servers') or {}).values() for s in (v if isinstance(v, list) else [v]) if s ]")
    for b in "${lang[@]}"; do
      [[ -z "$b" ]] && continue
      remember "$b" "profile $ref (language_servers)"
    done
  else
    echo "  ℹ profile '$ref' has no extensions.yaml (or could not be resolved) — skipping"
  fi
done

# --- Step 4: Install -------------------------------------------------------

if [[ ${#BIN_SET[@]} -eq 0 ]]; then
  echo ""
  echo "  No binaries declared by spec. Nothing to install."
  exit 0
fi

echo ""
echo "  Unique binaries across spec: ${#BIN_SET[@]}"
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "  Mode: DRY_RUN — nothing will be installed."
fi
echo ""

installed=0
skipped=0
warned=0
failed=0

for bin in "${!BIN_SET[@]}"; do
  origin="${ORIGIN[$bin]}"
  if command -v "$bin" >/dev/null 2>&1; then
    echo "  → $bin (already on PATH; from $origin)"
    skipped=$((skipped + 1))
    continue
  fi
  echo "  → $bin (needed by $origin)"
  if install_binary "$bin"; then
    installed=$((installed + 1))
  else
    rc=$?
    if [[ $rc -eq 1 ]]; then
      warned=$((warned + 1))
    else
      failed=$((failed + 1))
      echo "  ✗ install command failed for '$bin' (exit $rc)"
    fi
  fi
done

echo ""
echo "  Summary: $installed installed, $skipped already present, $warned without recipe, $failed failed"

if [[ $failed -gt 0 ]]; then
  exit 1
fi
exit 0

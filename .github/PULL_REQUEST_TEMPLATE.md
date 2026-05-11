## Summary

<!-- One or two sentences. What changes and why. -->

## Files touched

<!-- Tick all that apply. Leave others unchecked. -->

- [ ] `facet/action.yml` (composite action surface — inputs, outputs, steps)
- [ ] `facet/scripts/install-deps.sh` (spec traversal logic)
- [ ] `facet/scripts/bin-map.sh` (**trust boundary** — see checklist below)
- [ ] `facet/scripts/pin-pi-version.sh` (Pi SDK version pinning)
- [ ] `.github/workflows/*.yml` (selftest, examples)
- [ ] `README.md` / `CONTRIBUTING.md` / templates
- [ ] Other: <describe>

## Compatibility

- [ ] No breaking change to `inputs` (no input removed, no default changed in a way that flips behavior).
- [ ] No breaking change to `outputs` (no output removed or renamed).
- [ ] If a breaking change: this PR bumps the major (`v2`) — see CONTRIBUTING.md "Versioning".

## Security checklist (only if `bin-map.sh` changed)

- [ ] Each new entry has been verified with `apt show <pkg>` or PyPI lookup.
- [ ] Source is **official Ubuntu apt** or trusted PyPI — no PPAs, no `curl | bash`.
- [ ] Version is pinned where it matters.
- [ ] An issue from the `New binary in bin-map.sh` template was opened first (or this PR closes one).
- [ ] At least one reviewer other than the author has independently verified the package name.

## Tests

- [ ] `bash -n facet/scripts/*.sh` passes locally.
- [ ] If `install-deps.sh` traversal changed: ran `DRY_RUN=1` against at least one real spec and pasted the output in the PR description.
- [ ] If `action.yml` changed: the selftest workflow on this PR is green.

## Out of scope (confirm)

- [ ] No FACET runtime code (`@facet/core`, `@facet/sdk`, `@facet/harness-pi`, presets) — that goes to `facet-eval/facet-system`.
- [ ] No new experiment specs or scenarios — those belong upstream.
- [ ] No Pi SDK changes — those belong to `@mariozechner/pi-coding-agent`.

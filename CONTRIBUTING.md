# Contributing to `facet-gh-actions`

Thanks for the interest. This repo ships a composite GitHub Action and three companion shell scripts that run [FACET](https://github.com/facet-eval/facet-system) experiments in CI. Keep contributions narrow and reviewable: a single concern per PR.

## Scope

In scope:

- The composite action under `facet/action.yml`.
- Shell scripts under `facet/scripts/`.
- The self-test and example workflows under `.github/workflows/`.
- README, CONTRIBUTING, LICENSE, issue + PR templates.
- Future `facet-summary/` action and any sibling actions.

Out of scope:

- Anything inside the FACET runtime (`@facet/core`, `@facet/sdk`, `@facet/harness-pi`, preset packages). That lives at [`facet-eval/facet-system`](https://github.com/facet-eval/facet-system).
- Experiment specs, scenarios, profiles. Those live in the runtime monorepo or in consumer repos.
- The Pi SDK itself.

If you find a bug in the runtime, open an issue against `facet-eval/facet-system`, not this repo.

## Local dev

The repo is plain shell + YAML — no build step. To validate before pushing:

```bash
# Parse-check all scripts
for f in facet/scripts/*.sh; do bash -n "$f" || exit 1; done

# (Optional) shellcheck
shellcheck -S warning facet/scripts/*.sh

# (Optional) yamllint
yamllint -d "{extends: default, rules: {line-length: disable, document-start: disable, truthy: disable}}" \
  facet/action.yml .github/workflows/*.yml

# Smoke-test install-deps.sh against a spec
DRY_RUN=1 FACET_REPO_PATH=/path/to/facet-system \
  bash facet/scripts/install-deps.sh /path/to/examples/ring-default-specific
```

Bash 4+ is required (`declare -A`). macOS users: install `brew install bash` and run scripts with `/opt/homebrew/bin/bash`.

The CI selftest job (`.github/workflows/selftest.yml`) exercises the action end-to-end against `examples/hello-world-experiment` from `facet-eval/facet-system` in `dry` mode on every push and PR.

## Adding a new binary to `bin-map.sh`

`facet/scripts/bin-map.sh` is the **trust boundary** of this repo. Every entry maps a binary name to an install command that runs with `sudo` on the runner. Before adding an entry:

1. Confirm the experiment scenario or profile actually declares the binary in `requires_binaries` / `requires_binaries_per_scenario` / `language_servers`.
2. Pick the Ubuntu package name carefully — `apt show <pkg>` to verify it provides the right binary and that the source is the official Ubuntu repository (not a third-party PPA).
3. Pin the version where it matters (`clangd-12`, not `clangd`).
4. Prefer `install_apt` over `install_pip`. Never add an entry that pipes `curl` to `bash`.
5. In your PR description, link the upstream package and explain why the binary is needed by which experiment.

Reviewer must explicitly confirm the security checklist in the PR template (`.github/PULL_REQUEST_TEMPLATE.md`).

## Commits

This repo follows the same trunk-based + gitmoji + conventional commits style as the FACET monorepo. No AI attribution (no "Co-Authored-By: Claude", no "🤖", no "Anthropic").

| Gitmoji | Type | Use when |
|---|---|---|
| ✨ | `feat` | New feature (e.g., new action input, new script) |
| 🐛 | `fix` | Bug fix |
| 🔧 | `chore` | Config / tooling / maintenance |
| 📝 | `docs` | Documentation only |
| ✅ | `test` | Adding or updating tests / selftest workflow |
| ♻️ | `refactor` | Refactor without behavior change |
| 🚀 | `perf` | Performance improvement |
| 🚧 | `wip` | Work in progress — do not merge |

Examples:

- `✨ feat(action): add artifact_compression input`
- `🐛 fix(install-deps): handle missing extensions.yaml gracefully`
- `🔧 chore: bump pnpm/action-setup to v5`

## Versioning

| Tag | Stability |
|---|---|
| `v0.1.0`, `v0.1.1`, `v0.2.0`, … | Immutable. Reproducible builds pin here. |
| `v1` | Rolling. Tracks the latest patch + minor of the current major. |

Breaking input/output changes bump the major and move `v2` to the new tip.

## Releasing

Only maintainers cut releases. The process:

1. Land all changes on `main`. Selftest must be green.
2. Tag `vX.Y.Z` with an annotated message summarizing the changes.
3. Force-update the rolling major tag (`v1`, `v2`, …) to point at the new commit.
4. Push both tags.
5. Open a GitHub Release pointing at the new immutable tag.

```bash
git tag -a v0.2.0 -m "v0.2.0 — <summary>"
git tag -f v1   -m "v1 — rolling → v0.2.0"
git push origin v0.2.0
git push --force origin v1
gh release create v0.2.0 --title "v0.2.0" --notes "..."
```

## Security

Report security issues via private channel — open a security advisory at https://github.com/facet-eval/facet-gh-actions/security/advisories/new. Do not file public issues for vulnerabilities.

## License

By contributing you agree your changes will be licensed under MIT (see `LICENSE`).

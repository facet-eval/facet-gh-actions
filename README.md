# facet-gh-actions

Composite GitHub Action to run [FACET](https://github.com/facet-eval/facet-system) experiments in CI.

The action treats `pnpm facet` as a black-box CLI. It does the surrounding plumbing:

- Sets up Node + pnpm.
- Pins the Pi SDK to the version the spec declares (`metadata.harness.version`).
- Installs the FACET monorepo and builds it.
- Installs every binary that the spec's scenarios + profiles declare (`requires_binaries`).
- Writes a `.env` from API key secrets.
- Validates the spec.
- Runs the experiment (or skips with `run_mode: dry`).
- Packages the result bundle and uploads it as a GitHub Actions artifact.

## Quickstart

This action lives in its own repository so that consumers can reference it independently from the FACET runtime. The runtime itself lives at [`facet-eval/facet-system`](https://github.com/facet-eval/facet-system); your workflow checks both out side by side.

```yaml
# .github/workflows/run-experiment.yml in your experiment repo
name: Run Experiment

on:
  workflow_dispatch:
    inputs:
      run_mode:
        type: choice
        options: [full, single, dry]
        default: single

jobs:
  experiment:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4              # your experiment repo

      - uses: actions/checkout@v4              # the FACET runtime
        with:
          repository: facet-eval/facet-system
          path: facet

      - uses: facet-eval/facet-gh-actions/facet@v1
        id: facet
        with:
          command: run
          spec_path: ${{ github.workspace }}
          facet_repo_path: ${{ github.workspace }}/facet
          run_mode: ${{ inputs.run_mode }}
          artifact_mode: minimal
        env:
          OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
          ANTHROPIC_API_KEY:  ${{ secrets.ANTHROPIC_API_KEY }}
          OPENAI_API_KEY:     ${{ secrets.OPENAI_API_KEY }}
```

Pin a fixed version with `facet-eval/facet-gh-actions/facet@v0.1.0`. Track the latest patch of the current major with `@v1`.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `command` | no | `run` | FACET subcommand: `run`, `validate`, `spec-show`, `hash-profile` |
| `spec_path` | yes | — | Path to the experiment package directory (with `spec.yaml`) |
| `facet_repo_path` | no | `.` | Path to the checked-out FACET monorepo |
| `run_mode` | no | `full` | `full` = entire matrix, `single` = first cell, `dry` = validate only |
| `artifact_mode` | no | `minimal` | `minimal` = aggregated/ + tests.json only; `full` = entire bundle |
| `timeout_minutes` | no | `60` | Timeout for `pnpm facet run` |
| `node_version` | no | `22` | Node.js version |
| `pnpm_version` | no | `9` | pnpm version |
| `build` | no | `true` | Run `pnpm install --frozen-lockfile && pnpm build` |
| `auto_install_deps` | no | `true` | Run `install-deps.sh` before validation |
| `upload_results` | no | `true` | Upload the result bundle as an artifact |
| `retention_days` | no | `7` | Artifact retention period |
| `strict_schema` | no | `false` | Set `FACET_STRICT_SCHEMA=true` |

## API key secrets

Composite GitHub Actions do not support `secrets:` directly. The caller workflow exposes API keys via `env:` on the action step (see Quickstart). The action writes a `.env` file inside `facet_repo_path` containing only the keys that were provided and non-empty. Supported keys:

- `OPENROUTER_API_KEY`
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`

The FACET CLI then resolves each provider's key from `${PROVIDER}_API_KEY` based on the spec's `model_swap` varying factor.

## Outputs

| Output | Description |
|---|---|
| `result_bundle_path` | Absolute path to the generated `result-*/` directory |
| `result_bundle_name` | Basename of the bundle directory |
| `artifact_name` | Name of the uploaded artifact (`.tar.gz`) |
| `exit_code` | FACET CLI exit code |
| `run_count` | Number of runs executed (parsed from `manifest.yaml`) |

## Dependency installer

`facet/scripts/install-deps.sh` reads the spec tree and installs the union of:

- `requires_binaries` declared by each scenario's `meta.yaml`.
- `requires_binaries` / `requires_binaries_per_scenario.*` / `language_servers.*` declared by each profile's `extensions.yaml`.

It maps each binary name to an install command via `facet/scripts/bin-map.sh`. **Every entry in `bin-map.sh` is a trust boundary** — `install_apt` runs `sudo apt-get install` and `install_pip` runs `pip3 install`. Review carefully before adding entries. Set `DRY_RUN=1` to preview installs without executing.

Unknown binaries produce a warning, not a failure. `pnpm facet spec validate` is the authoritative gate.

## Versioning

| Tag | Stability |
|---|---|
| `v0.1.0`, `v0.2.0`, … | Immutable. Reproducible builds pin here. |
| `v1` | Rolling. Tracks the latest patch of the current major. |

Breaking input/output changes bump the major and move `v2` to the new tip.

## License

MIT — see [LICENSE](LICENSE).

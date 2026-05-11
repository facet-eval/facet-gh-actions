---
name: Bug report
about: Something in the action or scripts misbehaves
title: "[bug] "
labels: bug
---

## What broke

<!-- One sentence: what did you expect vs. what happened. -->

## Repro

<!-- The smallest possible thing that triggers the bug.
     Workflow snippet + spec.yaml excerpt + the failing CI run URL beats prose. -->

```yaml
# minimal workflow that fails
```

```yaml
# minimal spec.yaml excerpt
```

CI run URL (public log): <https://github.com/...>

## Environment

- Action ref: `facet-eval/facet-gh-actions/facet@vX.Y.Z` (or commit sha)
- FACET runtime ref (`facet-eval/facet-system`): <commit / tag>
- Pi SDK version (`metadata.harness.version` from your spec): <e.g. 0.70.2>
- Runner OS: `ubuntu-latest` (or other)
- `run_mode`, `artifact_mode`, `auto_install_deps`: <values>

## Logs

<!-- Copy the failing step's output. Trim aggressively — keep ~30 relevant lines. -->

```
...
```

## What I tried

<!-- Workarounds, things you ruled out. -->

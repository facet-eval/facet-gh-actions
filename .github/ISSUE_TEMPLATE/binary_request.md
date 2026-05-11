---
name: New binary in bin-map.sh
about: Request that an entry be added to facet/scripts/bin-map.sh
title: "[bin-map] add "
labels: enhancement, security
---

> `bin-map.sh` is a trust boundary. Every entry installs software with `sudo`
> on the CI runner. Every field below is mandatory before review.

## Binary

- **Name** (the command the experiment expects on `PATH`): `<e.g. rustc>`
- **Ubuntu package** that provides it: `<e.g. rustc>` — confirmed with `apt show <pkg>` ✅ / ❌
- **Pinned version** (if any): `<e.g. 1.75 — via apt package rustc-1.75>`
- **Install helper** to use: `install_apt` / `install_pip`

## Where it's declared

Which scenario or profile references this binary?

- File: `<scenarios/foo/meta.yaml or packages/preset-pi-X/profile/extensions.yaml>` in `facet-eval/facet-system`
- Field: `requires_binaries` / `requires_binaries_per_scenario.<id>` / `language_servers.<id>`
- Why it's needed (which oracle / build step / runtime tool uses it)

## Security checklist

- [ ] Package name verified with `apt show <pkg>` — no typo-squatting risk.
- [ ] Source is the **official Ubuntu apt repository**, not a third-party PPA, not `curl | bash`.
- [ ] Version pinned where it matters (e.g. `clangd-12`, not bare `clangd`).
- [ ] No post-install hooks that run network calls outside the apt cache.
- [ ] If `install_pip`: package name reviewed against PyPI typosquatting.

## Links

- Ubuntu package page: <https://packages.ubuntu.com/...>
- Upstream tool docs: <https://...>

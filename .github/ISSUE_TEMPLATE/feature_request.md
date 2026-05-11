---
name: Feature request
about: Propose a change to the action, scripts, or workflows
title: "[feat] "
labels: enhancement
---

## Problem

<!-- The concrete situation that motivates the request. Skip the "wouldn't it be nice" — what experiment / consumer / use case is blocked or harder than it should be? -->

## Proposed change

<!-- What you'd change. New input? New script step? New helper? Be specific about
     the action.yml / scripts/* file. -->

## Why this fits the scope

<!-- This repo ships ONLY the GitHub Action wrapper around `pnpm facet`.
     Confirm the change does not push responsibility into the action that
     belongs in the FACET runtime (facet-eval/facet-system) or in the
     consumer workflow. -->

## Alternatives considered

<!-- One or two. Especially: "the caller workflow could do this with X" — sometimes
     the answer is "this is a consumer concern, not an action concern". -->

## Out of scope (already)

- Anything in `@facet/core`, `@facet/sdk`, `@facet/harness-pi`, presets → file at `facet-eval/facet-system`.
- New experiment definitions → file in the runtime monorepo or the consumer repo.
- New Pi SDK features → file upstream at `@mariozechner/pi-coding-agent`.

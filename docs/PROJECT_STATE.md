# Project State

This is a compact supported-state snapshot for cold starts. It is not a
roadmap, task log, release history, or substitute for live `git status` and
GitHub state. Update it only when a durable supported feature, known limitation,
or verification fact changes.

## Product and supported state

Selkie's Moon is a 640x360 GameMaker vertical scrolling shooter with two
playable ships, normal and practice runs, persistent scores and configuration,
a CG Gallery, and a Music Room. A normal run has five themed stages, story and
ending flow, route-specific final encounters, pause/continue handling, then
credits.

The executable facts below are intentionally a checked discovery summary, not a
second place to tune gameplay:

- Consolidated stages: `5`. The director reuses material from `10` legacy wave
  sections; this is not a ten-stage runtime.
- Rank range: `0-50`. A normal run starts at `0`; `50` is the established
  default pressure point for compatibility and practice calculations.
- Boss stage phase counts: `3,5,3+3+shared,7,15`. Stage 3 gives Mira and Aisha
  three personal phases each before their synchronized shared finale.
- GMTL tests declared: `126`.
- Visual-tour captures declared: `26`.

`scr_gameplay_helpers` owns the gameplay constants and encounter descriptors;
`test_bootstrap` and `scr_test_helpers` own the declared test and capture
counts. See [Architecture](ARCHITECTURE.md) for runtime ownership and
[Gameplay Systems](GAMEPLAY_SYSTEMS.md) for player-facing rules.

## Repository state

- `dev` is the normal integration branch. `main` remains the published-release
  source tree and moves only through an explicitly authorized promotion.
- The current source-authority contract is [Asset Pipeline](ASSET_PIPELINE.md):
  BLEND, KRA, and Logic projects are the canonical 3D, raster, and audio
  masters; runtime and interchange files are derivatives.
- CI uses repository hygiene, pull-request governance, and a licensed hosted
  Windows GMTL run. Exact pull-request-head review evidence is governed by
  [Agent Review Policy](AGENT_REVIEW_POLICY.md), not this snapshot.

## Known limits and next reading

- Historical GameMaker names, timeline remnants, and legacy pattern sections
  are compatibility or regression context; they are not alternate live owners.
- Local GameMaker compiler or runner crashes without both GMTL summary lines are
  infrastructure failures, not test passes. Use the hosted Windows result when
  local execution cannot provide an authoritative summary.
- The remote default-branch decision, rulesets, and automatic invalidation of
  review evidence remain tracked as the unresolved governance work described in
  [Governance Handoff](GOVERNANCE_HANDOFF.md).

For a task, begin with [Governance Handoff](GOVERNANCE_HANDOFF.md), use
[Architecture](ARCHITECTURE.md) to find the subsystem owner, and select a
validation tier from [Validation](VALIDATION.md). For interrupted work that
cannot be recovered from version control and logs, copy
[Handoff Template](HANDOFF_TEMPLATE.md) into a task-specific note.

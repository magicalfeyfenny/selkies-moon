# Project State

This is the compact current-state snapshot for cold starts. It is not a roadmap,
task log, release history, or substitute for live `git status`. Update it only
when a durable supported feature, known gap, owner, or validation fact changes.

## Product and supported state

Selkie's Moon is a 640x360 GameMaker vertical scrolling shooter. The current
runtime supports two playable ships, normal and practice runs, five consolidated
stages, route-specific final encounters, story/ending/credits flow, pause and
continue handling, persistent scores and configuration, a CG Gallery, and a
Music Room.

Current facts that governance verification binds to executable sources:

- Consolidated stages: `5`. The director reuses material from `10` legacy wave
  sections; that is not a ten-stage runtime.
- Rank range: `0-50`. A normal run starts at `0`; `50` is the established/default
  pressure point used by compatibility and practice calculations.
- Boss stage phase counts: `3,5,3+shared,7,15`. Stage 3 gives each personal boss
  three phases, then runs one synchronized shared finale.
- GMTL tests declared: `128`.
- Visual-tour captures declared: `26`.
- Editable Logic projects present: `0/15`.

The canonical mutable values are the constants and factories in
`scripts/scr_gameplay_helpers` and `scripts/scr_setup`; the numbers above are a
checked discovery summary, not a second place to tune them.

## Validation snapshot

- `scripts/test_bootstrap/test_bootstrap.gml` contains 128 regression tests.
- `tools/run_gmtl_tests.zsh` is the supported local full-suite entry point.
- `.github/workflows/gamemaker-tests.yml` runs the Windows VM suite for `dev`
  pull requests, `dev` pushes, and manual dispatches when the licensed secret is
  available. Its separate governance job is unlicensed and runs on every
  workflow invocation, including fork pull requests.
- `art/audio_production/loop_validation.json` records all 15 score masters as
  completed with no missing cues; the matching runtime sound metadata uses the
  production durations.

Record actual run evidence in the active task, commit, or handoff rather than
continually appending dated results here.

## Known incomplete or intentionally limited work

- The score manifest names 15 editable `logic_projects/*.logicx` sources, but
  none are present in this checkout. Validated lossless masters, source MIDI,
  cue sheets, and runtime encodes are present. Treat the absent Logic projects
  as an editable-production-source gap, not a runtime-audio failure.
- Legacy timeline resources and legacy enemy objects are retained as idle or
  regression fixtures. They are not alternate live owners and should not be
  revived during unrelated changes.
- No other durable incomplete subsystem is declared here. A task should not
  infer missing work merely from old names, comments, or generated artifacts;
  establish it from the routed owner and focused validation.

## Where to go next

Use the task-routing table in [`ARCHITECTURE.md`](ARCHITECTURE.md), then read only
the linked guide and owner files. Validation tiers are in
[`VALIDATION.md`](VALIDATION.md); generated asset and audio ownership is in
[`ASSET_PIPELINES.md`](ASSET_PIPELINES.md).

For an interrupted task whose state cannot be recovered from a clean commit and
test output, copy [`HANDOFF_TEMPLATE.md`](HANDOFF_TEMPLATE.md) to a descriptive
task-specific note. Delete or archive obsolete handoffs instead of loading them
as permanent governance.

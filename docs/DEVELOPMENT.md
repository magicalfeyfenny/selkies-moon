# Development Guide

This guide contains the common implementation workflow. Start with
[`PROJECT_STATE.md`](PROJECT_STATE.md), then use the task-routing table in
[`ARCHITECTURE.md`](ARCHITECTURE.md) instead of scanning the project tree.

## Prerequisites and project

- GameMaker IDE 2024.14.4.222 or a compatible newer version.
- A compatible installed GameMaker runtime.
- zsh, rsync, and standard macOS command-line tools for the local harness.

The project is
`Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp`. F5 in GameMaker runs
the normal game; command-line and hosted validation are documented in
[`VALIDATION.md`](VALIDATION.md).

## Repository layout

```text
.
├── AGENTS.md                  # compact authority and cold start
├── README.md                  # player-facing overview
├── docs/                      # routed architecture and subsystem contracts
├── tools/                     # validation and deterministic production tools
├── art/                       # editable/generated asset sources and manifests
└── Selkie's Moon ~ until we meet again ~/
    ├── Selkies Moon.yyp
    ├── datafiles/
    ├── objects/
    ├── rooms/
    ├── scripts/
    ├── sounds/
    ├── sprites/
    └── timelines/
```

GameMaker `.yy` and `.yyp` files are resource metadata. A new script or resource
needs its implementation or binary, matching `.yy`, and an entry in the `.yyp`.
Do not hand-edit image or audio binaries.

`output/`, `cache/`, and `test-results/` are disposable local build products.
`tmp/` is ignored scratch space. The GMTL harness recreates
`output/gmtl-project`; never treat it as source.

## Coding conventions

- Prefix project functions with `Game`.
- Prefix arguments and locals with `_`; short loop counters are allowed.
- Give every top-level function a `/// @func` signature and behavior contract.
- Start each object event with its ownership or event-order role.
- Prefer structs for state and array descriptors for plans/specifications.
- Keep object events thin; shared calculations and spawning belong in the routed
  script owner.
- In combat child Step events, call `event_inherited()` first and then obey
  `combat_step_blocked`.
- Route input through verbs and one-shot audio through named helpers.
- Call `GameRuntimeGameplayEnsure()` before compatibility-sensitive runtime
  reads.
- Preserve parseable player data through explicit migrations.

## Change workflow

1. Read `PROJECT_STATE.md` and route the task through `ARCHITECTURE.md`.
2. Inspect `git status --short`; preserve unrelated changes.
3. Open the owner, its adjacent `/// @func` contracts, and focused GMTL tests.
4. Add or update tests before changing a sensitive rule.
5. Preserve object/room event ordering and data migration guarantees.
6. Update only the relevant guide; do not copy mutable facts into several docs.
7. Run the smallest sufficient tier from `VALIDATION.md`.
8. Review `.yyp`/`.yy` changes for accidental GameMaker metadata churn.

Test-created instances must be destroyed before return. Persistence tests use
automation-prefixed files and delete them in setup/teardown. Prefer pure helper
tests for calculations and representative event simulations for inheritance or
object-order behavior.

Generated art, 3D, portrait, and audio procedures are intentionally excluded
from this common guide. Load [`ASSET_PIPELINES.md`](ASSET_PIPELINES.md) only for
those tasks.

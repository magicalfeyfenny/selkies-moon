# Development Guide

## Prerequisites

- GameMaker IDE 2024.14.4.222 or a compatible newer version.
- A matching installed GameMaker runtime.
- zsh, rsync, and standard macOS command-line tools for the local test harness.

Open `Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp` in GameMaker. Press F5 to run the normal game.

## Repository layout

~~~text
.
├── README.md
├── docs/
├── tools/
│   ├── regenerate_stage_timeline.zsh
│   └── run_gmtl_tests.zsh
└── Selkie's Moon ~ until we meet again ~/
    ├── Selkies Moon.yyp
    ├── datafiles/
    ├── objects/
    ├── rooms/
    ├── scripts/
    ├── sounds/
    ├── sprites/
    └── timelines/
~~~

GameMaker `.yy` and `.yyp` files are resource metadata. A new script needs its `.gml`, matching `.yy`, and a resource entry in the `.yyp`. Do not hand-edit image or audio binaries.

`output/`, `cache/`, and `test-results/` are local build products. The GMTL harness recreates its project copy under `output/gmtl-project`.

## Automated tests

Run the full suite from the repository root:

~~~zsh
GMTL_TEST_ATTEMPTS=8 ./tools/run_gmtl_tests.zsh
~~~

The harness:

1. finds the newest installed GameMaker runtime and licensed user directory;
2. copies the project into an isolated output tree;
3. removes non-macOS platform options from that copy;
4. creates an automation marker;
5. builds and runs GMTL;
6. retries transient compiler/runner crashes;
7. fails if summary lines are missing, zero tests ran, or any test failed.

The current expected result is `96 passed, 96 total`. GameMaker's asset compiler can intermittently throw `System.AccessViolationException` before compilation. A retry that later reaches the complete passing summary is valid; a GML compiler error or a completed failing test is not transient.

Run these lightweight checks after editing:

~~~zsh
git diff --check
git status --short
~~~

## Test organization

`scripts/test_bootstrap/test_bootstrap.gml` contains one GMTL suite with these sections:

- Game setup
- Title menu
- Gameplay
- Controller, pause, practice, and rank
- Story UI

Tests that create instances must destroy them before returning. Persistence tests use automation-prefixed files and call `GameTestPersistenceFilesDelete()` in setup/teardown. Prefer pure helper tests for calculations and representative event simulations for inheritance or object-order behavior.

`GameStageBalanceReportCreate()` is intentionally test-facing. It models stage pressure so tuning changes can be checked against no-continue viability bounds without playing ten complete runs.

## Visual QA tour

`scr_test_helpers` contains an opt-in 27-capture tour covering title pages, every stage notice, representative combat, the final boss, story, credits, practice, and pause pages.

Launch with `--visual-tour` or create `.visual-tour.txt` in GameMaker's runtime working directory. Captures are saved under the runtime sandbox's `visual-tour/` directory. The debug log prints the sandbox paths and capture progress. The marker is deleted when all captures finish.

The capture is queued during Step and written in Draw GUI End so world and GUI layers are complete.

## Timeline regeneration

The stage timeline is mechanical. To regenerate its moments after changing `STAGE_LENGTH_FRAMES`:

~~~zsh
./tools/regenerate_stage_timeline.zsh
~~~

The script deletes existing `moment_*.gml` files, recreates turret/bee/mayfly cadence moments, and rewrites `tml_stage.yy`. Review the entire generated diff and run GMTL afterward. Stage Director variant waves are code-driven and are not generated into the timeline.

## Coding conventions

- Prefix project functions with `Game`.
- Prefix arguments and locals with `_`; loop counters may be short names.
- Document every top-level function with `/// @func` and a behavior contract.
- Start each object event with a comment describing its ownership or event-order role.
- Use structs for state and array-based descriptors for plans/specifications.
- Keep object events thin; shared calculations and spawning belong in scripts.
- Call `event_inherited()` first in combat child Step events, then obey `combat_step_blocked`.
- Route input through verbs instead of reading keys in gameplay/UI code.
- Route one-shot audio through named audio helpers.
- Use `GameRuntimeGameplayEnsure()` before reading compatibility-sensitive runtime fields.
- Preserve player save data through migrations; never silently discard a parseable older payload.

## Change checklist

1. Identify the owning module and data contract.
2. Add or update tests before changing a sensitive rule.
3. Keep room/object event ordering intact.
4. Update inline docs and the relevant document in `docs/`.
5. Run GMTL with retries.
6. Run `git diff --check`.
7. Review `.yyp`/`.yy` changes for accidental GameMaker metadata churn.

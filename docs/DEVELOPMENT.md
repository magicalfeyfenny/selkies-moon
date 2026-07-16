# Development Guide

## Prerequisites

- GameMaker IDE 2024.14.4.222 or a compatible newer version.
- A matching installed GameMaker runtime.
- Git LFS 3.x, installed before checkout or followed by `git lfs pull` in an
  existing checkout.
- Krita 5.3 or compatible, available through `KRITA_BIN`, `PATH`, or the normal macOS app location.
- Python 3 with Pillow for KRA export validation and declared image transforms.
- Blender for rebuilding 3D geometry exports and Logic Pro for production audio work.
- zsh, rsync, and standard macOS command-line tools for the local test harness.

Open `Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp` in GameMaker. Press F5 to run the normal game.

## Branch workflow

`dev` is the normal integration branch. Start bounded work on a feature branch,
push that branch to the remote, and merge it into `dev` through a pull request.
`main` is reserved for the exact source tree corresponding to the currently
published binary release. See [Branch and Release Policy](BRANCH_AND_RELEASE_POLICY.md)
for release promotion, tagging, hotfixes, and the narrowly scoped history-rewrite
exception used by coordinated repository migrations such as Git LFS.

## Repository layout

~~~text
.
├── README.md
├── docs/
├── tools/
│   ├── export_krita_runtime.py
│   ├── check_repository_hygiene.py
│   ├── migrate_legacy_raster_to_krita.py
│   ├── run_gmtl_tests_ci.ps1
│   ├── run_gmtl_tests.zsh
│   └── run_yyc_playtest.zsh
└── Selkie's Moon ~ until we meet again ~/
    ├── Selkies Moon.yyp
    ├── datafiles/
    ├── objects/
    ├── rooms/
    ├── scripts/
    ├── sounds/
    └── sprites/
~~~

GameMaker `.yy` and `.yyp` files are resource metadata. A new script needs its `.gml`, matching `.yy`, and a resource entry in the `.yyp`. Follow [Asset Pipeline](ASSET_PIPELINE.md): edit production 3D, raster, and audio only in their declared BLEND, KRA, or Logic master, never in generated runtime files.

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

The current expected result is `126 passed, 126 total`. GameMaker's asset compiler can intermittently throw `System.AccessViolationException` before compilation. A retry that later reaches the complete passing summary is valid; a GML compiler error or a completed failing test is not transient.

After staging the intended snapshot, run these lightweight checks:

~~~zsh
python3 tools/check_repository_hygiene.py
python3 -m unittest discover -s tools/tests -p 'test_*.py'
git diff --cached --check
git status --short
~~~

The hygiene command deliberately checks the staged index and refuses unstaged
or untracked non-ignored files so package metadata, Git attributes, and payload
ownership can never be validated from a mixed snapshot.

## GitHub Actions unit tests

`.github/workflows/gamemaker-tests.yml` first runs the fast repository-hygiene and package-ownership gate, including a full PR-range check for large ordinary Git blobs and tracked junk. Same-repository changes also fetch and hash every changed final-state LFS payload. Forks cannot upload LFS objects to the repository remote, so fork pull requests that change LFS paths fail with instructions to transfer the commit onto a maintainer-owned branch. The workflow then runs the GMTL suite for pull requests targeting `dev`, pushes to `dev`, and manual dispatches. The Windows runner installs the pinned GameMaker runtime, builds a VM executable, launches it with `--run-test`, validates the GMTL summary, and retains the runner and compiler logs for 14 days.

The repository must have an Actions secret named `ACCESS_KEY`. Generate one on the [GameMaker account access-key page](https://gamemaker.io/account/access_keys), then add it under **Settings > Secrets and variables > Actions**. Never commit the key or paste it into a workflow file. Licensed CI is skipped for fork pull requests because GitHub does not provide repository secrets to untrusted fork code.

## Test organization

`scripts/test_bootstrap/test_bootstrap.gml` contains one GMTL suite with these sections:

- Game setup
- Title menu
- Gameplay
- Controller, pause, practice, and rank
- Story UI

Tests that create instances must destroy them before returning. Persistence tests use automation-prefixed files and call `GameTestPersistenceFilesDelete()` in setup/teardown. Prefer pure helper tests for calculations and representative event simulations for inheritance or object-order behavior.

`GameStageBalanceReportCreate()` is intentionally test-facing. It models stage pressure so tuning changes can be checked against no-continue viability bounds without playing five complete runs.

## Visual QA tour

`scr_test_helpers` contains an opt-in 26-capture tour covering title pages (including the three audio meters), every stage notice, representative combat (including the final-stage insects), the sisters' shared dual-boss finale on its alternate background route, the final boss, story, credits, practice, pause pages, and the continue prompt.

Launch with `--visual-tour` or create `.visual-tour.txt` in GameMaker's runtime working directory. Captures are saved under the runtime sandbox's `visual-tour/` directory. The debug log prints the sandbox paths and capture progress. The marker is deleted when all captures finish.

The capture is queued during Step and written in Draw GUI End so world and GUI layers are complete.

## Asset production and YYC

Every shipped 2D raster asset has one canonical `.kra` master. Runtime PNGs flow one way from that master through `tools/export_krita_runtime.py`; a normal build cannot create or overwrite a KRA, rewrite a sprite `.yy`, or draw replacement production art in Pillow. The exporter renders with Krita into staging, applies only declared transforms such as the story backgrounds' 2x nearest-neighbor scale, validates dimensions and decoded pixels, and atomically promotes only the manifest-declared GameMaker/runtime targets. GameMaker root frames and required editor-layer copies may both be targets, but the production source tree does not maintain separate ORA, named layer-export, imported-runtime PNG, or preview mirrors.

Use a Pillow-capable Python environment:

```sh
python3 tools/export_krita_runtime.py
python3 tools/export_krita_runtime.py --check
```

Use repeatable `--family` arguments for `core`, `enemy`, `story`, `stage3d`, `imported`, `text`, or `standalone`. The all-family check proves coverage of all 77 sprite resources and 84 active frames, six standalone runtime assets, nine registered source-only masters, all 92 KRAs, and the exact 174-PNG GameMaker/runtime target set. Standalone and source-only assets are declared in `art/krita_runtime_export_manifest.json`. Set `KRITA_BIN` when Krita is not on `PATH` or installed in the normal macOS application location.

Legacy material was migrated once and promoted to genuine KRA masters. Migration tooling is not part of the current build and must never replace an existing KRA. If a downstream interchange file is required for an external handoff, create it in staging or artifact storage rather than adding a parallel source authority. Immutable creator-selected references remain `reference-only` and are never rewritten by the exporter; transient candidate pools, contact sheets, and archived mirrors belong in review/artifact storage rather than the production source tree.

The former procedural/reverse-import entry points remain as compatibility wrappers around the central KRA exporter. They no longer generate art, copy runtime PNGs back into sources, or mutate story data. Font atlas artwork is mastered in `art/font_sources/runtime_atlases/`; the corresponding `.yy` remains the authoritative glyph-metrics and packing contract.

The five native `.blend` scenes under `art/3d_stage_sources/` are the sole canonical 3D masters. Their raster texture atlases are mastered in the five KRAs under `art/3d_stage_sources/textures/`. The normal Blender command opens those existing masters without saving them and currently creates geometry-only triangulated OBJ build intermediates; the buffer compiler then creates GameMaker-ready VBUFF runtime caches:

```sh
blender --background --python tools/blender_build_stage_scenes.py
python3 tools/build_stage3d_runtime_buffers.py
```

Procedural scene construction is a destructive migration/bootstrap operation and requires the explicit Blender argument `-- --bootstrap-masters`; never use it for routine export. OBJ plus MTL is the portable 3D interchange contract, although the current atlas-driven exporter has no material-bearing export and emits no MTL. A future material-bearing export must emit and reference MTL. Runtime code and the YYP package load only the five VBUFF files. The five OBJ exports remain repository-only inputs to the buffer compiler, as declared in `art/runtime_package_manifest.json`. All native 3D rendering stays in `obj_scene_manager` Draw Begin so no gameplay, effect, bullet, hitbox, or UI coordinate can inherit its matrices or depth state.

The sole canonical score masters are the fifteen native Logic projects.
`tools/build_logic_score_midi.py` maintains bootstrap note/arrangement data and
cue sheets, and `tools/validate_logic_score.py` checks those musical and loop
contracts before and around Logic production. The MIDI, cue, and manifest files
are reproducibility metadata rather than competing masters. Run
`python3 tools/finalize_logic_loops.py --require-all` to create validated
lossless WAV derivatives from two-cycle bounces; `tools/install_logic_masters.py`
then encodes the fifteen runtime OGG files.

The native Logic SFX suite project is likewise the sole SFX master.
`tools/build_logic_sfx_suite.py` provides bootstrap MIDI/cue metadata; the
24-bit bounce and per-cue runtime WAVs are derivatives installed by
`tools/install_logic_sfx.py`. `tools/build_audio_assets.py` is retired and must
not be used to replace Logic-derived music or SFX. See
`docs/AUDIO_DIRECTION.md` for the cue, leitmotif, export, SFX, and mixer
contracts.

The audited asset families and existing history are stored through Git LFS as
recorded in [Git LFS Migration](LFS_MIGRATION.md). CI hydrates only registered
runtime VBUFF, font, option-icon, sound, and sprite payloads. Repository-only
OBJ exports and authoring/reference files remain pointers unless a production
workflow explicitly fetches them.

Use `./tools/run_yyc_playtest.zsh` for native macOS validation. It isolates the checkout, retries GameMaker's unstable YYC emission, builds the generated Xcode project with `/Applications/Xcode.app`, and opens the resulting app unless `YYC_NO_RUN=1` is set. Local builds are ad-hoc signed by default so they retain a valid bundle seal without needing login-keychain approval behind the screen lock. Release automation can set `YYC_CODE_SIGN_IDENTITY` and `YYC_DEVELOPMENT_TEAM` for Developer ID signing before the normal notarization workflow. All live waves are code-driven; the superseded `tml_stage` resource no longer ships.

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
6. Run `python3 tools/check_repository_hygiene.py`.
7. Run `git diff --check`.
8. Review `.yyp`/`.yy` changes for accidental GameMaker metadata churn.

# Architecture

This document describes the runtime ownership and code boundaries of Selkie's Moon. Function-level contracts live beside the implementation as `/// @func` comments; this guide explains how those functions cooperate.

## Runtime flow

~~~mermaid
flowchart LR
    Boot["obj_app_init<br/>persistent bootstrap"] --> Title["rm_title"]
    Title --> Opening["rm_opening"]
    Opening --> Game["rm_game"]
    Game -->|stages 1-4| Game
    Game -->|stage 5 clear| Ending["rm_ending"]
    Ending --> Credits["rm_credits"]
    Credits --> Title
    Title -->|practice| Game
    Game -->|practice complete or abort| Title
~~~

`obj_app_init` and `obj_input_manager` persist across rooms. Room-owned controllers and UI objects are recreated with their rooms. The bootstrap owns initialization, music synchronization, automated-test shutdown, and the visual QA tour.

## Global state

Five global structs are the shared contracts between objects:

| Global | Owner | Purpose |
| --- | --- | --- |
| `global.game_config` | `scr_setup` | Display dimensions, scale, fullscreen, target FPS, audio gains, and independent keyboard/gamepad bindings |
| `global.game_save` | `scr_setup` | Per-ship high scores, starts, clears, and continues |
| `global.game_runtime` | `scr_setup` and `scr_gameplay_helpers` | Current run, stage, player resources, rank, overlays, practice request, and story request |
| `global.game_input` | `obj_input_manager` and `scr_input_helpers` | Device-neutral movement and verb edges |
| `global.game_audio` | `scr_audio_helpers` | Current room track, Music Room preview ownership, and sound-effect cycling |

`GameRuntimeDataCreateDefault()` is the canonical runtime schema. `GameRuntimeGameplayEnsure()` fills fields introduced by newer builds without overwriting live values. Add new runtime fields to the default factory first; the compatibility pass will then inherit them automatically.

## Script modules

| Script | Responsibility |
| --- | --- |
| `scr_setup` | Schema versions, default structs, save/config migration, score persistence, display application, and boot |
| `scr_input_helpers` | Persistent keyboard/gamepad maps, remap labels and collision handling, device snapshots, input verbs, active-device selection, and menu cursor movement |
| `scr_audio_helpers` | Room music routing, Music Room preview ownership, master/category gain application, and named sound-effect entry points |
| `scr_gameplay_helpers` | Gameplay constants, practice/pause state, rank, stage flow, player rules, encounter descriptors, pickups, and enemy specifications |
| `scr_boss_patterns` | Runtime interpretation of boss phase descriptors and shared bullet-spawn primitives |
| `scr_story_helpers` | Story JSON loading, dialogue state, text layout, portrait/background rendering, and ornate UI primitives |
| `scr_stage_3d` | Native vertex-buffer loading, modular camera paths, stage lighting/fog shader parameters, and background atmosphere |
| `scr_title_helpers` | Title page state, character metadata, practice configuration UI, Music Room controls, and title drawing |
| `scr_ui_crystal` | Clean-backdrop capture, GUI-to-surface mapping, and reusable crystal-pane shader orchestration |
| `scr_test_helpers` | Test-launch isolation and the 26-frame visual QA tour |
| `test_bootstrap` | GMTL regression suite |
| `GMTL_*` | Vendored GameMaker Testing Library; do not refactor as project-owned code |

Native Logic projects are the sole canonical score and SFX masters.
`tools/build_logic_score_midi.py`, `tools/build_logic_sfx_suite.py`, and their
manifests provide bootstrap and validation metadata; they do not compete with
Logic as source authority. `tools/validate_logic_score.py` verifies the score
catalog, lossless WAVs carry validated bounces, and
`tools/install_logic_masters.py` derives the fifteen streamed runtime OGGs.
The SFX installer slices the declared 24-bit suite bounce into fifteen runtime
WAVs. `tools/build_audio_assets.py` is retired and owns no production output.
The complete contracts are documented in [Asset Pipeline](ASSET_PIPELINE.md)
and [Audio Direction](AUDIO_DIRECTION.md).

## Asset authority

Shipped 2D raster art has one authority: its declared KRA. The KRA exporter may
render, crop, scale, pack, validate, and atomically install manifest-owned PNG
targets, but it cannot draw production pixels or modify a master. The normal
tree has no parallel ORA, named layer-export, imported-runtime PNG, or preview
source mirrors. GameMaker-required root-frame and editor-layer PNGs are both
runtime derivatives of the same KRA.

Native `.blend` scenes are the sole canonical 3D masters. The normal Blender
exporter opens them without saving; procedural scene construction is isolated
behind an explicit destructive bootstrap flag. OBJ plus MTL is the portable
interchange contract. The current exporter is geometry-only and emits OBJ
without MTL; any future material-bearing export must provide MTL. OBJ is
compiled into each stage's VBUFF runtime cache, and `scr_stage_3d` loads only
VBUFF. The current YYP still registers the five OBJ exports as Included Files;
that redundant packaging metadata is a known follow-up outside the LFS rewrite.
Interchange files should remain outside the package so authoring derivatives do
not become accidental runtime content.

These canonical masters and required binary derivatives are stored through Git
LFS. Storage representation does not change source authority. See
[Asset Pipeline](ASSET_PIPELINE.md) and [Git LFS Migration](LFS_MIGRATION.md).

Project-owned public helpers should carry a `/// @func` signature and a one-line contract. Keep object events orchestration-focused and move reusable rules into the owning script.

## Object ownership

### Application and UI

- `obj_app_init`: persistent application lifecycle and ownership of the 640x360 GUI and clean crystal-backdrop surfaces.
- `obj_input_manager`: persistent input polling in Begin Step.
- `obj_UI_title`: delegates title state and drawing to `scr_title_helpers`.
- `obj_UI_story`: owns a local story queue and requests room transitions after dialogue.
- `obj_UI_gameplay`: renders side gutters, resources, rank, boss segments, stage notices, and continue overlays.
- `obj_UI_menu`: owns pause navigation. Resume is deferred to End Step so every gameplay object observes a complete frozen frame.
- `obj_UI_credits`: caches final results, scrolls credits, then resets the runtime.

### Gameplay

- `obj_scene_manager`: owns the gameplay camera target, an independent presentation clock for the true-3D modular background, and stage mode (`scroll`, `boss_intro`, `boss_fight`, `boss_outro`, `stage_clear`). Its Draw Begin event restores every world/view/projection and depth state before normal 2D drawing begins.
- `obj_player`: owns local action state; shared resources remain in `global.game_runtime`. Its normal Draw places the ship below enemy bullets, while Draw End isolates the visible hitbox above them.
- `obj_player_shot`: carries a normalized shot specification into collision and rendering.
- `obj_enemy_parent`: centralizes freeze, damage, defeat rewards, and movement.
- `obj_enemy_variant`: resolves one of 20 stage-authored identities, then runs role movement and its redistributed attack family after the parent Step. Legacy turret/bee/mayfly objects are test fixtures, not live roster entries.
- `obj_bullet_parent`: centralizes freeze, bomb cancellation, medal conversion, linear motion, and culling.
- `obj_bullet_bead`, `obj_bullet_diamond`, `obj_bullet_blade`: specialize visuals or motion while retaining parent cancellation rules.
- `obj_boss_parent`: owns phase transitions, health refills, destruction, score, and scene completion.
- `obj_boss_sunset`: selects encounter identity, stays camera-relative, and delegates the active descriptor to `scr_boss_patterns`.
- `obj_powerup` and `obj_medal`: move, collect, and apply rewards.

Child Step events that call `event_inherited()` must immediately stop when the parent sets `combat_step_blocked`. This preserves pause, destruction, cancellation, and defeat guards atomically.

## Stage and encounter data flow

`GameStageDirectorStep()` is the sole live wave source. It resolves one four-entry roster through `GameStageEnemyRosterCreate()`, spawns camera-relative waves above the visible field, and scales cadence with the legacy pattern-section mapping plus rank. The old GameMaker timeline is held permanently idle. `obj_scene_manager` stops the director when scrolling ends, but its 3D presentation clock continues and blends onto a second valid downward-looping camera route. The manager clears ordinary combat actors, queues boss dialogue, and creates either one boss or the stage-three dual encounter after the intro seam. A boss defeat may queue an outro; the frozen dialogue signal keeps the manager in `boss_outro` until it can enter the normal stage-clear seam without freezing the background route.

Bosses use a two-layer design:

1. `GameBossEncounterInfoCreate()` chooses identity and creates a `phase_plan`.
2. `GameBossPhaseAttackStep()` interprets the current phase and creates bullets.

Encounter plans fit each character's motif seeds to the consolidated structure: Shalmii has 3 phases, Aster 5, Mira and Aisha each have 3 personal phases, Caelia has 7, and the route-final opponent has 15. Mira's interpreters use casino odds, cards, dice, and roulette; Aisha's use spell circles, mirrored hexes, grimoires, and grand sorcery. When both sisters' personal plans are defeated, they reform for one synchronized `sisters_grand_illusion` phase with shared HP. Moon's final opponent uses rose patterns; Selkie's final opponent uses chakram patterns. Total endurance is normalized by `GameBossPhaseHpGet()` and incoming damage by `GameBossDamageScaleGet()`.

`GameCharacterBossInfoCreate()` maps stages 1, 2, and 4 to Shalmii, Aster, and Caelia. Stage 3 uses `GameDualBossIdentityCreate()` and configures separate Mira and Aisha boss objects, health, personal phase plans, positions, and HUD bars. Each defeated sister becomes harmless while her sibling still fights; the second personal defeat replaces both plans with the shared finale and synchronizes damage across both objects. Stage 5 selects the route opponent. `GameCharacterBossStoryFileGet()` resolves route/seam files from this encounter registry; the combined Stage 3 dialogue identifies Mira and Aisha as sisters, while portraits remain data-driven through sprite names in JSON and can be replaced independently.

`obj_UI_gameplay` reads the active descriptor directly from the boss identity and uses `phase_timer` to display a two-second phase-title banner. Formatting and fade calculations remain pure gameplay helpers; drawing stays in the GUI event and reuses the shared ornate story-frame theme.

There is deliberately no legacy fallback attack. An empty or unknown phase descriptor fails closed and logs a warning, making invalid encounter data visible during development.

## Persistence

`game.sav` and `config.sav` are JSON payloads stored through GameMaker's save sandbox. Schema versions are independent. Loading follows this order:

1. read the text payload;
2. parse JSON defensively;
3. reject and back up future versions;
4. migrate recognized older fields into a fresh default struct;
5. rewrite only when normalization changed the payload.

Automated runs use `automation-` filenames so tests never touch player data.

## Extension rules

- New persistent field: update its default factory, migration/validation, schema version, and tests.
- New runtime-only field: update `GameRuntimeDataCreateDefault()` and tests.
- New input action: add the verb to `GameInputVerbNamesCreate()`, `GameInputBindingsCreateDefault()`, `GameInputStateCreate()`, both device snapshots, the title remap labels, and `GameInputSnapshotApply()`.
- New stage enemy: add configuration/spawn helpers and stop it through the parent inheritance contract.
- New boss pattern: add a descriptor seed and one `shot_kind` interpreter case in the owning family function under `scr_boss_patterns`; preserve complete seed/variant sets and keep the appended finale unique.
- New story asset: follow [DATA_FORMATS.md](DATA_FORMATS.md) and register the JSON under `IncludedFiles`.

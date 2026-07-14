# Architecture

This document describes the runtime ownership and code boundaries of Selkie's Moon. Function-level contracts live beside the implementation as `/// @func` comments; this guide explains how those functions cooperate.

## Runtime flow

~~~mermaid
flowchart LR
    Boot["obj_app_init<br/>persistent bootstrap"] --> Title["rm_title"]
    Title --> Opening["rm_opening"]
    Opening --> Game["rm_game"]
    Game -->|stages 1-9| Game
    Game -->|stage 10 clear| Ending["rm_ending"]
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
| `global.game_config` | `scr_setup` | Display dimensions, scale, fullscreen, target FPS, and preferred input device |
| `global.game_save` | `scr_setup` | Per-ship high scores, starts, clears, and continues |
| `global.game_runtime` | `scr_setup` and `scr_gameplay_helpers` | Current run, stage, player resources, rank, overlays, practice request, and story request |
| `global.game_input` | `obj_input_manager` and `scr_input_helpers` | Device-neutral movement and verb edges |
| `global.game_audio` | `scr_audio_helpers` | Current room track, Music Room preview ownership, and sound-effect cycling |

`GameRuntimeDataCreateDefault()` is the canonical runtime schema. `GameRuntimeGameplayEnsure()` fills fields introduced by newer builds without overwriting live values. Add new runtime fields to the default factory first; the compatibility pass will then inherit them automatically.

## Script modules

| Script | Responsibility |
| --- | --- |
| `scr_setup` | Schema versions, default structs, save/config migration, score persistence, display application, and boot |
| `scr_input_helpers` | Keyboard/gamepad snapshots, input verbs, active-device selection, and menu cursor movement |
| `scr_audio_helpers` | Room music routing, Music Room preview ownership, and named sound-effect entry points |
| `scr_gameplay_helpers` | Gameplay constants, practice/pause state, rank, stage flow, player rules, encounter descriptors, pickups, and enemy specifications |
| `scr_boss_patterns` | Runtime interpretation of boss phase descriptors and shared bullet-spawn primitives |
| `scr_story_helpers` | Story JSON loading, dialogue state, text layout, portrait/background rendering, and ornate UI primitives |
| `scr_title_helpers` | Title page state, character metadata, practice configuration UI, Music Room controls, and title drawing |
| `scr_test_helpers` | Test-launch isolation and the 27-frame visual QA tour |
| `test_bootstrap` | GMTL regression suite |
| `GMTL_*` | Vendored GameMaker Testing Library; do not refactor as project-owned code |

Every project-owned top-level function has a `/// @func` signature and a one-line contract. Keep object events orchestration-focused and move reusable rules into the owning script.

## Object ownership

### Application and UI

- `obj_app_init`: persistent application lifecycle.
- `obj_input_manager`: persistent input polling in Begin Step.
- `obj_UI_title`: delegates title state and drawing to `scr_title_helpers`.
- `obj_UI_story`: owns a local story queue and requests room transitions after dialogue.
- `obj_UI_gameplay`: renders side gutters, resources, rank, boss segments, stage notices, and continue overlays.
- `obj_UI_menu`: owns pause navigation. Resume is deferred to End Step so every gameplay object observes a complete frozen frame.
- `obj_UI_credits`: caches final results, scrolls credits, then resets the runtime.

### Gameplay

- `obj_scene_manager`: owns the camera target and stage mode (`scroll`, `boss_intro`, `boss_fight`, `boss_outro`, `stage_clear`).
- `obj_player`: owns local action state; shared resources remain in `global.game_runtime`.
- `obj_player_shot`: carries a normalized shot specification into collision and rendering.
- `obj_enemy_parent`: centralizes freeze, damage, defeat rewards, and movement.
- `obj_enemy_turret`, `obj_enemy_bee`, `obj_enemy_mayfly`, `obj_enemy_variant`: run only specialized movement and firing after the parent Step.
- `obj_bullet_parent`: centralizes freeze, bomb cancellation, medal conversion, linear motion, and culling.
- `obj_bullet_bead`, `obj_bullet_diamond`, `obj_bullet_blade`: specialize visuals or motion while retaining parent cancellation rules.
- `obj_boss_parent`: owns phase transitions, health refills, destruction, score, and scene completion.
- `obj_boss_sunset`: selects encounter identity, stays camera-relative, and delegates the active descriptor to `scr_boss_patterns`.
- `obj_powerup` and `obj_medal`: move, collect, and apply rewards.

Child Step events that call `event_inherited()` must immediately stop when the parent sets `combat_step_blocked`. This preserves pause, destruction, cancellation, and defeat guards atomically.

## Stage and encounter data flow

Timeline moments call `GameStageTimeline*Spawn()` helpers. The helpers choose stage-aware positions above the visible field and configure enemy instances. The parallel `GameStageDirectorStep()` adds later-stage variant waves. `obj_scene_manager` stops both sources when scrolling ends, clears ordinary combat actors, queues character or final-boss dialogue when needed, and creates the boss after the intro seam. A character-boss defeat may queue an outro; the frozen dialogue signal keeps the manager in `boss_outro` until it can enter the normal stage-clear seam.

Bosses use a two-layer design:

1. `GameBossEncounterInfoCreate()` chooses identity and creates a `phase_plan`.
2. `GameBossPhaseAttackStep()` interprets the current phase and creates bullets.

Every encounter plan has the same ordering contract: play each seed once, play each complete tuned variant set, then append one non-repeated signature finale. Stages 1-2 use two seeds, stages 3-6 use three, stages 7-9 use four, and route-final encounters use five seeds with two variant sets. This produces total phase counts of 5, 7, 9, and 16 respectively.

Every stage owns a separate family interpreter. The abstract encounters retain Tideglass, Saltwind, Kelp, and Bloodtide. Character stages use Poker (Mira), Rune (Shalmii), Desire (Aisha), Ribbon (Aster), and Astral (Caelia). Moon's final opponent uses rose patterns; Selkie's final opponent uses chakram patterns. Total endurance is normalized by `GameBossPhaseHpGet()` and incoming damage by `GameBossDamageScaleGet()`.

`GameCharacterBossInfoCreate()` maps stages 2, 5, 6, 7, and 9 to character presentation metadata. The same stage number selects the character's motif-specific descriptor plan through `GameMemoryCorePhasePlanCreate(stage)`. This preserves the common scheduling, practice, balance, and signature machinery without coupling it to portraits. `GameCharacterBossStoryFileGet()` derives four route/seam files from the registry's `story_id`; portraits remain data-driven through sprite names in JSON and can be replaced independently.

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
- New input action: add the verb to `GameInputStateCreate()`, both device snapshots, and `GameInputSnapshotApply()`.
- New stage enemy: add configuration/spawn helpers and stop it through the parent inheritance contract.
- New boss pattern: add a descriptor seed and one `shot_kind` interpreter case in the owning family function under `scr_boss_patterns`; preserve complete seed/variant sets and keep the appended finale unique.
- New story asset: follow [DATA_FORMATS.md](DATA_FORMATS.md) and register the JSON under `IncludedFiles`.

# Structural Decomposition Plan

This is the durable audit and migration plan for oversized production owners.
It is not authorization to change production code. Each milestone is a separate,
bounded task and must follow the current repository guidance and validation
rules.

The companion [module ownership map](MODULE_OWNERSHIP_MAP.md) records current
symbols, state, callers, side effects, proposed destinations, compatibility
decisions, characterization gaps, and migration status.

## Audit scope and method

The audit used the production GML size inventory, the routed owners in
[`ARCHITECTURE.md`](ARCHITECTURE.md), `/// @func` declarations, targeted direct
caller searches, focused event callers, the GMTL suite, and visual-tour setup.
It excluded vendored `GMTL_*` implementation, binary assets, generated output,
caches, archives, and absent Logic projects.

Caller breadth below is the number of external GML files with a direct reference
to at least one function declared by the candidate. It is an approximation of
structural reach, not a claim that every reference is an independent runtime
caller. Direct GMTL references are reported separately because indirect event
coverage can exist without a direct function call.

## Ranked target inventory

Ranking prioritizes recurring context reduction, responsibility count, caller
breadth, hidden coupling, characterization difficulty, deterministic or
persistence sensitivity, and likelihood that future tasks must reopen the file.
Line count is evidence, not the ranking rule.

| Rank | Production file | Lines | Documented owner and broad purpose | Apparent responsibilities | Direct external GML files | Shared mutable state and runtime centrality | Recurring context cost | Structural risk | Expected decomposition benefit |
| ---: | --- | ---: | --- | ---: | ---: | --- | --- | --- | --- |
| 1 | `Selkie's Moon ~ until we meet again ~/scripts/scr_gameplay_helpers/scr_gameplay_helpers.gml` | 4,006 | `scr_gameplay_helpers`: run flow, rank, stages, players, encounters, pickups, enemies | 14 domain clusters plus a cross-domain balance report; 190 functions and 162 macros | 44: 36 object-event files and 8 other scripts | Co-owns `global.game_runtime`, mutates `global.game_save`, many player/enemy/boss instances, rooms, and entity populations; active in nearly every gameplay Step | Extreme; unrelated gameplay tasks repeatedly load constants, UI, plans, spawning, combat, and rewards together | Extreme: shared RNG stream, frame order, initialization, persistence calls, instance mutation, and balance coupling | Extreme; domain seams can remove most unrelated context from routine work |
| 2 | `Selkie's Moon ~ until we meet again ~/scripts/scr_setup/scr_setup.gml` | 798 | `scr_setup`: schemas, defaults, persistence, display, boot | 6: defaults/runtime schema, persistence transport, migration/validation, result tables, display application, boot | 11: 5 object-event files and 6 scripts | Owns `global.game_config`, `global.game_save`, `global.game_runtime`, and delayed window globals; boot-critical and save-critical | High despite moderate size because every schema, save, run-end, config, and display task crosses the file | Extreme: circular dependency with gameplay helpers, save compatibility, boot order, file I/O, and delayed window timing | High; separating persistence, runtime schema, results, and display makes ownership and validation much narrower |
| 3 | `Selkie's Moon ~ until we meet again ~/scripts/scr_title_helpers/scr_title_helpers.gml` | 1,398 | `scr_title_helpers`: title pages, selection, practice, music, options, drawing | 7: content catalogs, title state, options, remapping, practice setup, music preview, view/draw | 8: 5 object-event files and 3 scripts | Mutates `global.game_config`; reads `global.game_input` and `global.game_save`; owns a large local title-state struct and audio preview side effects | High; menu work loads unrelated catalogs, config persistence, practice, audio, and rendering | Medium-high: raw input capture, save/config writes, room actions, audio ownership, and draw-state leakage | High; options and shared UI seams reduce both title and gameplay-pause context |
| 4 | `Selkie's Moon ~ until we meet again ~/scripts/scr_story_helpers/scr_story_helpers.gml` | 1,209 | `scr_story_helpers`: JSON loading, story state, text layout, portraits/backgrounds, UI primitives | 6: data loading, normalization, reveal state, route/room flow, story presentation, shared ornate UI | 9: 6 object-event files and 3 scripts | Mutates `global.game_runtime.story` and `signals.dialogue`; ending flow calls result persistence and room transitions | High; story tasks load file I/O, state timing, ending progression, and shared UI geometry together | High: Included File resolution, fixed-step reveal timing, room transition ordering, and save-on-ending | High; data, flow, view, and shared UI can become independently characterized owners |
| 5 | `Selkie's Moon ~ until we meet again ~/scripts/scr_boss_patterns/scr_boss_patterns.gml` | 1,543 | `scr_boss_patterns`: descriptor interpretation and bullet primitives | 4 cohesive subdomains: spawn primitives, family interpreters, dispatch, scheduled attack/redirect | 3: 2 object-event files and GMTL | No globals, but mutates boss instance pattern state and creates bullets; one `random_range` draw per gap-safe burst | High for boss-family work, but most responsibilities remain within one domain | High: visual geometry, bullet counts, RNG consumption, cadence, redirect timing, and guaranteed gaps | Medium-high; family modules reduce boss-specific context, but premature splitting could obscure the descriptor contract |
| 6 | `Selkie's Moon ~ until we meet again ~/scripts/scr_input_helpers/scr_input_helpers.gml` | 607 | `scr_input_helpers`: bindings, snapshots, verbs, remapping, menu motion | 4: schema/normalization, labels/remapping, device polling, verb/menu state | 9: 4 object-event files and 5 scripts | Owns `global.game_input` and reads/mutates `global.game_config`; Begin Step feeds every UI and gameplay consumer | Medium-high recurring reach, but the module is internally cohesive | High if split: sub-frame taps, device arbitration, and Begin Step ordering | Medium; a split is possible, but current cohesion makes it lower priority |
| 7 | `Selkie's Moon ~ until we meet again ~/scripts/scr_audio_helpers/scr_audio_helpers.gml` | 415 | `scr_audio_helpers`: music routing, preview, gains, semantic SFX | 4: state/assets, gains, music routing/preview, semantic SFX | 17: 12 object-event files and 5 scripts | Owns `global.game_audio`, reads `global.game_config`; broad semantic call surface | Medium due to broad reach, low per-task context due to clear naming | Medium: audio preview ownership and room synchronization | Low-medium; broad caller count alone does not justify disrupting a cohesive semantic API |
| 8 | `Selkie's Moon ~ until we meet again ~/scripts/scr_stage_3d/scr_stage_3d.gml` | 540 | `scr_stage_3d`: buffers, paths, lighting/fog, atmosphere | 4: resource/buffer setup, authored configuration, path sampling, rendering | 3: 2 scene-manager events and GMTL | No globals; mutates scene-owned GPU buffers and render state | Medium and specialized | Medium-high: GPU lifecycle and visual-only contracts are difficult to automate | Low-medium; current low caller breadth and cohesive rendering contract favor leaving it intact |
| 9 | `Selkie's Moon ~ until we meet again ~/objects/obj_UI_gameplay/Draw_64.gml` | 310 | `obj_UI_gameplay`: HUD, notices, boss segments, continue overlay | 5 draw concerns in one event | Event-local consumer rather than a shared callee | Reads runtime, boss, scene, input labels, and shared UI styles every draw | Medium | Medium: draw order and state restoration | Medium after shared UI and HUD functions have clear owners; not a first extraction |
| 10 | `Selkie's Moon ~ until we meet again ~/objects/obj_player/Step_0.gml` | 189 | `obj_player`: local action orchestration | Movement, pause/continue, death, bomb, firing, sword collisions, bullet hits | Event-local orchestrator | Coordinates local `player_state`, `global.game_runtime`, scene, bullets, enemies, bosses, and shots | High reasoning density despite modest size | Extreme if behavior is moved without frame traces | Indirect; keep the event orchestration-focused and shrink it only as domain functions gain owners |

`test_bootstrap.gml` is approximately 3,297 lines but is not a production target.
Its monolithic shape is relevant only as the current characterization home.

## High-priority findings

### 1. Gameplay helpers

The file is not one oversized subsystem. It combines practice and pause UI, run
lifecycle, rank, stage state and geometry, RNG-backed wave spawning, enemy
catalogs, boss data and dual-boss runtime mutation, player weapons, survival,
rewards, HUD drawing, enemy projectile specifications, and a production
balance-report function that depends on several of those domains.

The most expensive hidden edges are:

- `GameRuntimeGameplayEnsure()` calls setup-owned
  `GameRuntimeDataCreateDefault()`, while setup's runtime factory calls
  gameplay-owned constructors and macros.
- `GameStageBalanceReportCreate()` reaches wave cadence, rank, drop cadence,
  both player shot plans, boss HP, phase counts, and damage scaling. It is a
  test-facing integration report, not a natural owner for any one subsystem.
- `obj_scene_manager` advances background presentation before the freeze guard,
  then rank, Berserk drain, stage notice, wave spawning, and stage advancement
  in a fixed Step sequence.
- `obj_player`, parent/child enemies, parent/child bullets, and parent/child
  bosses rely on inherited guard flags and on cancellation/defeat being resolved
  before specialized child behavior.
- all 162 macros live at the top of the file even though they belong to camera,
  player combat, rank, bosses, rewards, practice, and enemy catalogs.

The module map separates these into domain-owned clusters without imposing a
file-size target.

### 2. Setup

`scr_setup` contains a boot owner, three schemas, persistence transport,
validators and migrations, result insertion, runtime reset, and display/window
application. Its small line count understates its cost because both save
compatibility and initialization depend on it.

The runtime schema is especially sensitive: `obj_app_init` calls
`GameInitialize()` before it creates `obj_input_manager`, but the default config
factory already calls input binding constructors, the runtime factory calls
gameplay constructors, and config application calls audio and presentation
functions. A runtime-schema extraction must characterize the complete boot
checkpoint and preserve this order.

### 3. Title helpers

The title state machine mixes pure catalog data with raw keyboard/gamepad
capture, config persistence, audio preview ownership, practice normalization,
room actions, and all view drawing. Pause options also call title-owned config
functions, and gameplay/story/title all call UI primitives declared in either
the title or story script. The first seam is therefore the shared ornate UI
owner, followed by options and title-local state/view owners.

### 4. Story helpers

Story loading, reveal timing, run-level dialogue signals, ending result saving,
room transitions, and shared UI primitives are separate contracts. The current
file makes `obj_UI_story` a thin orchestrator, but it also makes non-story UI
depend on the story resource for frames, gauges, hearts, and ornaments.

### 5. Boss patterns

The file is large but more cohesive than the four higher-ranked candidates.
Descriptor construction already lives elsewhere and the runtime has only two
production entry points: pattern firing and scheduled attack stepping. Family
functions are nevertheless large enough that a change to one character loads
every other family. Split family interpreters only after geometry and RNG
checkpoints exist; keep the descriptor contract and dispatcher authoritative.

## Dangerous or uncertain coupling

| Coupling | Evidence | Consequence for implementation |
| --- | --- | --- |
| Runtime-schema cycle | setup's `GameRuntimeDataCreateDefault()` calls gameplay constructors/constants; gameplay's ensure/start/abort paths call setup defaults, save, and reset | Characterize boot and runtime fields first. Use temporary legacy wrappers while moving schema ownership; do not move only one side of the cycle casually. |
| One unowned RNG stream | wave X positions, enemy `fire_timer`/`wave_phase`, boss burst jitter, blade redirect direction, bullet flash phase, and power-up pulse consume GameMaker RNG; no production seed owner was found | `$determinism-validation` is mandatory for wave, enemy, bullet, boss-pattern, entity-order, or visual-tour extraction. Record RNG state or a reproducible seed at comparable checkpoints before moving calls. Cosmetic Create-event draws can shift later gameplay draws. |
| Step and inherited-event ordering | scene manager orders rank/drain/notice/director/advance; child enemy/bullet/boss Steps immediately honor `combat_step_blocked` after `event_inherited()` | Preserve parent-first guards and the exact frame on which defeat, cancellation, phase transition, spawning, and destruction occur. |
| Local/global mirrored state | bomb timer is local to `player_state` and mirrored into `global.game_runtime`; pause and story use nested runtime signals | Check both copies at each frame checkpoint and preserve mutation ownership. |
| Boss-plan/weapon balance edge | boss HP calculation reads both full-power shot specifications; the balance report also reads both domains | Move pure plan construction only with its explicit weapon dependency; keep the integration report late and separate. |
| Dual-boss shared mutation | damage, medals, phase plan replacement, HP, transition timers, visibility, and bullet cancellation are synchronized across two live boss instances | Characterize member order and the first shared-finale frame before extraction. |
| Ending persistence | story completion calls `GameRunResultSave()` before entering credits; game-over and abort use different result/reset paths | Save/load and run-result checkpoints are required; never infer equivalence from compilation. |
| Shared draw primitives and draw state | title owns outlined text; story owns ornate frames, gauges, hearts, and ornaments; gameplay pause/HUD call both | Establish visual-tour captures and draw-state postconditions before moving them to `scr_ui_ornate`. |
| GameMaker resource metadata | every proposed script is a new `.gml` plus `.yy` plus `.yyp` entry; existing project-owned scripts use the project root as Asset Browser parent | Every extraction invokes `$gamemaker-resource-change`. Use physical `scripts/<resource>/` directories and the existing root parent; do not bundle IDE reorganization. |

No alarm or sequence dependency was found in the audited high-priority script
clusters. The legacy stage timeline fields remain initialized but the live
director explicitly keeps the timeline idle. Room, object-event, resource, and
Included File dependencies remain material and are listed in the module map.

### Runtime dependency inventory

- Initialization: `obj_app_init/Create_0.gml` calls `GameInitialize()`, then
  ensures `obj_input_manager`, then synchronizes music. `obj_scene_manager` later
  initializes the run and scene before creating or repositioning the camera,
  player, gameplay HUD, and pause UI.
- Step/event order: the audited contracts cross `obj_app_init` Step/Draw,
  `obj_scene_manager` Create/Step, `obj_player` Create/Step/Draw,
  `obj_enemy_parent` and `obj_enemy_variant` Create/Step,
  `obj_bullet_parent` and `obj_bullet_blade` Create/Step,
  `obj_boss_parent` and `obj_boss_sunset` Create/Step/Draw,
  `obj_player_shot`, `obj_powerup`, and `obj_medal` Create/Step, plus the title,
  story, gameplay, and pause UI events.
- Object and room dependencies: the main clusters create, enumerate, mutate, or
  destroy camera, player, player-shot, enemy, bullet, medal, power-up, scene,
  boss, and UI objects. Room transitions cover `rm_title`, `rm_opening`,
  `rm_game`, `rm_ending`, and `rm_credits`.
- Timeline/sequence/alarm dependencies: `tml_stage` fields are initialized by the
  scene manager but deliberately kept idle; no live sequence or alarm call was
  found in the audited clusters.
- Resource dependencies: gameplay data binds playable/boss/enemy/bullet/pickup
  sprites and the `Instances` layer; title binds roster/gallery sprites and all
  15 music-room sound assets; story binds packaged JSON Included Files,
  portraits/backgrounds, textbox/arrow sprites, and UI fonts; boss patterns bind
  bead, blade, and diamond bullet objects. Setup depends on input defaults,
  audio application, window/display APIs, the application surface, and the save
  sandbox rather than art resources.

## Characterization gaps

| Gap | Affected clusters | Existing evidence | Required characterization before extraction |
| --- | --- | --- | --- |
| No owned/reproducible gameplay RNG seed or consumption trace | waves, enemy configure, boss patterns, blade redirect, entity creation | GMTL checks representative geometry and spawn families; visual tour has repeatable setup but does not seed the runtime RNG | Capture initial RNG state, inputs, ordered draws, spawned object types/positions, and first divergent frame for a bounded scenario. Include cosmetic Create-event draws in the trace. |
| Runtime ensure and boot order are not directly characterized as one contract | runtime schema, run lifecycle, setup boot | default-runtime and `GameInitialize` tests exist; `GameRuntimeGameplayEnsure` has no direct GMTL reference | Assert config/save/runtime field sets, preserved live values, nested structs, run-mode request retention, input/audio availability, and post-boot globals at explicit checkpoints. |
| Run transition matrix is incomplete | normal start, practice restart/return, abort, death/continue, ending, credits reset | focused tests cover normal start, practice, continue, game-over, and ending transitions | Add a table-driven trace for result-write/no-write behavior and runtime fields across every exit path. |
| Exact frame sequence across scene/player/bullets is not captured | rank, Berserk, bombs, cancellation, medals, waves | focused unit/event tests cover individual behaviors | Record per-frame stage frame, rank counters, meter, bomb state, spawn/cancel/medal events, and entity counts through freeze/unfreeze boundaries. |
| Dual-boss finale transition lacks a complete ordered trace | boss runtime | GMTL verifies both personal defeats unlock the shared finale | Record member enumeration order, both instances' HP/phase/timers/visibility, bullet count, medal markers, and scene completion through the finale seam. |
| Shared ornate UI lacks runner-confirmed assertions, approved stable captures, and pixel baselines | shared ornate UI, title view, story view, gameplay HUD | 26-capture visual tour covers title, story, bosses, practice, and pause; focused tests now define palettes, caller-visible state/layout boundaries, and current alpha/color/alignment/font/filter postconditions; the project compiles with those assertions | Obtain passing GMTL summaries and save approved captures `01`, `05`, `06`, `16`, and `21`-`24` from an authorized runner, then compare dimensions and representative pixels or hashes where stable. Do not normalize the characterized ornament/divider color side effect during extraction. |
| Story data failure behavior is only partly exercised | story data and flow | Included File loading, wrapping, reveal, and room-flow tests exist | Characterize missing, malformed, empty, array-root, and struct-root JSON without changing the current failure contract. |
| Most boss family functions are covered through the dispatcher, not direct family contracts | boss pattern families | configured-shot-kind, representative geometry, and variance tests exist; only 2 of 17 functions have direct GMTL references | For each family move, assert recognized shot kinds, bullet type/count/order, key angles/speeds, boss state toggles, RNG draw count, unknown-value behavior, and one visual capture. |
| Persistence helper coverage is integration-heavy | persistence transport/migration/results | strong load, migration, malformed/future-version, isolation, initialization, and non-qualifying-score tests | Add direct backup/rewrite/no-rewrite and qualifying-score alignment checks before changing ownership. Never write player filenames in tests. |

Direct function references in GMTL currently cover 101 of 190 gameplay-helper
functions, 16 of 39 setup functions, 13 of 47 title functions, 17 of 50 story
functions, and 2 of 17 boss-pattern functions. These counts do not substitute
for behavior coverage; they identify where facade/draw/event behavior is mostly
indirect.

## Ordered independently testable milestones

Every extraction preserves existing public function names unless a row
explicitly requires a temporary facade. New script resources use the current
Asset Browser root (`Selkies Moon`) and a physical
`Selkie's Moon ~ until we meet again ~/scripts/<resource>/` directory. No
milestone includes gameplay tuning, renaming churn, or folder reorganization.

Abbreviations: **DV** = `$determinism-validation`; **GRC** =
`$gamemaker-resource-change`.

| Order | Fresh-thread milestone | Exact current to proposed ownership | Affected callers | Facade | Verification and skills | Completion criterion |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Characterize shared ornate UI | No production move. Cover title-owned outlined text/panel style and story-owned palette/frame/ornament/gauge/heart primitives used by title, story, gameplay HUD, and pause | `obj_UI_title`, `obj_UI_story`, `obj_UI_gameplay`, `obj_UI_menu`, credits, and draw helpers | None | Focused GMTL for pure layout/state plus approved visual-tour captures `01`, `05`, `06`, `16`, and `21`-`24`; DV no; GRC no | Tests/captures define output and draw-state postconditions without production changes |
| 2 | Extract shared ornate UI | `scr_title_helpers` and `scr_story_helpers` shared draw primitives to proposed `scr_ui_ornate` | Same callers as milestone 1; calls retain names | No; preserve symbols | Focused GMTL, selected visual tour, full GMTL; DV no; GRC yes | One new registered script owns the primitives, old files contain no duplicate implementation, visuals are equivalent |
| 3 | Characterize stage catalog and field geometry | No production move. Cover stage metadata/theme, boss/final predicates, field/spawn rectangles, camera targets, and respawn/boss positions; exclude RNG-backed X choice and progression mutation | scene manager, player, boss/enemy Create/Step, audio, 3D stage, HUD | None | Focused GMTL; DV no; GRC no | Exact pure inputs/outputs for all five stages and edge coordinates are asserted |
| 4 | Extract stage rules | Pure stage catalog/geometry functions and their macros from `scr_gameplay_helpers` to proposed `scr_stage_rules` | Callers named in milestone 3 | No; preserve symbols | Focused gameplay tests then full GMTL; DV no; GRC yes | Stage rules are independently owned and no timing, spawning, or runtime mutation moved |
| 5 | Extract boss plan construction | Descriptor factories, counts, signatures, encounter identity, pure plan expansion, and phase HP/damage formulas from `scr_gameplay_helpers` to proposed `scr_boss_plans`; leave live dual mutation and attack interpretation in place | boss Create/Step, scene manager, story, HUD, player shots, boss patterns, tests, balance report | No; preserve symbols | Existing boss plan/signature/count/HP tests plus full GMTL; DV yes for phase/progression order; GRC yes | Identical signatures, counts `3,5,3+shared,7,15`, HP/damage values, and caller behavior |
| 6 | Extract rank | Rank constants and `GameRank*` functions from `scr_gameplay_helpers` to proposed `scr_rank`; leave blade motion elsewhere | scene manager, player survival/rewards, enemies, bullets, boss patterns, HUD, practice, audio/tests | No; preserve symbols | Rank focused tests and frozen/unfrozen frame checkpoints; full GMTL; DV yes; GRC yes | Rank values, counters, pressure multipliers, and mutation frames match |
| 7 | Characterize wave and enemy RNG | No production move. Trace stage director intervals, ordered spawns, X draws, enemy Create/configure double-configuration effects, and cosmetic Create-event RNG consumption | scene manager, enemy variant, bullet/power-up Create events, visual tour | None | Seeded/checkpointed focused harness and state/event trace; DV yes; GRC no | Same inputs reproduce the ordered RNG/event trace and expose first divergence |
| 8 | Extract wave director and enemy catalog | Roster, definitions, spawn bands using RNG, enemy configuration/decorators, live director, and combat clear from `scr_gameplay_helpers` to proposed `scr_wave_director` | scene manager, enemy variant, boss patterns, bullet draw, tests/visual tour | No; preserve symbols | Milestone 7 trace, wave tests, stage-balance report, full GMTL; DV yes; GRC yes | Spawn frames/types/positions, RNG state, enemy fields, and clear semantics match |
| 9 | Characterize enemy projectile timing | No production move. Trace turret/bee/mayfly specs, blade spiral motion, redirects, rank speed snapshot, parent/child Step guards, and cancellation | enemy events, bullet parent/blade events, boss runtime/patterns, player | None | Focused per-frame entity trace and existing bullet tests; DV yes; GRC no | Bullet fields, RNG draws, movement/cancel/redirect events, and culling frames are fixed |
| 10 | Extract enemy projectile rules | Blade motion, enemy shot specifications, mayfly helpers, redirect helpers, and shared enemy bullet spawns from `scr_gameplay_helpers` to proposed `scr_enemy_projectiles` | Callers from milestone 9 plus wave director and boss pattern core | No; preserve symbols | Milestone 9 trace, bullet tests, full GMTL; DV yes; GRC yes | No change in bullet creation order, motion, RNG state, or inherited stop behavior |
| 11 | Characterize player weapons | No production move. Trace volley queue/timer, focused/autofire inputs, shot specs/order, sword pose/sweep IDs, collision iteration order, and boss HP dependency | `obj_player`, `obj_player_shot`, title attack preview, boss plans, tests | None | Existing weapon tests plus frame/entity trace; DV yes; GRC no | Inputs produce identical per-frame actions, shot arrays, instance order, and damage events |
| 12 | Extract player weapons | Shot/sword factories, fire state step, and weapon macros from `scr_gameplay_helpers` to proposed `scr_player_weapons`; keep survival and rewards separate | Callers from milestone 11 and balance report | No; preserve symbols | Milestone 11 trace, weapon/boss HP tests, full GMTL; DV yes; GRC yes | Shot and sword behavior, timing, damage, and boss-plan calculations match |
| 13 | Characterize run rewards | No production move. Trace medals, bullet cancel conversion, Berserk activation/drain, point-blank rewards, pickups, drop counters, score, rank effects, and entity creation | enemy/boss/bullet/medal/power-up/player/scene events | None | Focused state/event trace through defeat, bomb, Berserk, collection, and stage reset; DV yes; GRC no | Counter, score, rank, meter, pickup/medal order, and RNG checkpoints are asserted |
| 14 | Extract run rewards | Reward, cancel, Berserk, pickup/drop functions and macros from `scr_gameplay_helpers` to proposed `scr_run_rewards` | Callers from milestone 13 and balance report | No; preserve symbols | Milestone 13 trace, reward/rank tests, full GMTL; DV yes; GRC yes | Observable economy, entity ordering, and state mutations match exactly |
| 15 | Characterize player survival and overlays | No production move. Trace local/global bomb mirroring, death, respawn, continue yes/no, practice death, game-over save/reset, and pause freeze/resume boundaries | player, scene, UI menu/gameplay, bullet parent, story/run-result paths | None | Table-driven transition and per-frame trace; DV yes for timing/save continuity; GRC no | Every exit path has explicit state and persistence checkpoints |
| 16 | Extract player survival | Player state, death/bomb/continue functions and constants from `scr_gameplay_helpers` to proposed `scr_player_survival`; pause UI remains separate | player Create/Step/Draw, bullet parent, scene manager, HUD, tests | No; preserve symbols | Milestone 15 trace, continue/bomb tests, full GMTL; DV yes; GRC yes | Local/global state and room/save actions occur on the same frames |
| 17 | Characterize runtime schema and run lifecycle | No production move. Cover setup's runtime default/reset and gameplay's ensure/transient/start/request/abort/freeze functions as one cycle | app init, scene manager, title, story, audio, HUD, all gameplay actors | None | Boot and transition matrix; save namespace isolation; full field-set comparison; DV yes for initialization/save continuity; GRC no | Default, ensured, preserved, reset, normal, and practice checkpoints are explicit |
| 18 | Extract runtime and run state | Runtime schema/reset from `scr_setup` plus ensure/run lifecycle from `scr_gameplay_helpers` to proposed `scr_run_state` | Callers from milestone 17 | Yes: retain legacy `GameRuntimeDataCreateDefault`, `GameRuntimeGameplayEnsure`, and `GameRuntimeReset` wrappers until the dependency cycle and docs are migrated | Milestone 17 tests, full GMTL; DV yes; GRC yes | One owner defines runtime fields/mutations, wrappers only forward, and boot/run traces match |
| 19 | Characterize persistence core | No production move. Cover namespaces, paths, I/O failures, backups, parse, versions, validation, migration, rewrite/no-rewrite, and automation isolation | app init, title options/remap, audio/config, tests | None | Focused sandboxed file tests; DV yes for save/load continuity; GRC no | Current/future/malformed/missing payload outcomes and exact writes are asserted |
| 20 | Extract persistence core | Config/save defaults, transport, validation, migration, load/save, and schema-version constants from `scr_setup` to proposed `scr_persistence` | app init, title/options, audio, input, tests | Yes only if public load/save/default names are replaced; otherwise preserve names and use no facade | Milestone 19 tests, full GMTL; DV yes; GRC yes | Persisted shapes, backups, migrations, filenames, and writes are unchanged |
| 21 | Characterize run results | No production move. Cover qualifying/non-qualifying insertion, aligned continues, starts/finishes, practice exclusions, ending/game-over/abort paths | gameplay run state, story ending, credits/title, tests | None | Focused sandboxed persistence and transition tests; DV yes; GRC no | Score/stat rows and exact write/no-write checkpoints are asserted |
| 22 | Extract run results | Result-table functions from `scr_setup` to proposed `scr_run_results` | callers from milestone 21 | Preserve `GameRunResultSave` as a temporary forwarding contract only if a narrower API is introduced | Milestone 21 tests and full GMTL; DV yes; GRC yes | Result ownership moves once; row alignment and write timing match |
| 23 | Extract display application | Window fit/center/delayed phase, config apply, pixel presentation functions from `scr_setup` to proposed `scr_display` | app-init Step/Draw, title options, tests | No; preserve symbols | Display math tests, full GMTL, targeted visual QA where available; DV no; GRC yes | Window/presentation calls and delayed phase state are unchanged |
| 24 | Reduce setup to boot orchestration | Keep `GameInitialize()` and boot ordering in `scr_setup` after unrelated clusters leave | `obj_app_init/Create_0.gml` | No new facade | Boot checkpoint and full GMTL; DV yes for initialization; GRC no | `scr_setup` is a cohesive boot entry and no longer contains moved implementations |
| 25 | Extract practice | Practice schema/names/request/scene application from `scr_gameplay_helpers` to proposed `scr_practice` | title, scene, pause, setup/runtime state, tests/visual tour | No; preserve symbols | Practice tests, milestone 15/17 transition evidence, full GMTL; DV yes; GRC yes | Practice setup/restart/return behavior and statistics isolation match |
| 26 | Extract pause menu | Pause state/input/step/draw/live tuning from `scr_gameplay_helpers` to proposed `scr_pause_menu` | `obj_UI_menu`, HUD, options, input, tests/visual tour | No; preserve symbols | Pause tests, milestones 1/15 evidence, selected captures, full GMTL; DV yes for freeze/resume; GRC yes | Pause owns one cluster and freeze/resume frames are unchanged |
| 27 | Extract title catalogs | Catalog and score-read functions from `scr_title_helpers` to proposed `scr_title_catalog` | title object/view, credits, tests | No; preserve symbols | Existing title metadata/gallery/music tests and full GMTL; DV no; GRC yes | Static title content and score lookup have one owner |
| 28 | Characterize options and remapping | No production move. Trace raw capture release, device maps, collision swaps, config writes/apply, and pause-option reuse | title object, pause menu, input/config/persistence, tests | None | Focused input/config tests; DV yes for input timing; GRC no | Capture and config side effects have exact checkpoints |
| 29 | Extract options and remapping | Options/config/remap functions from `scr_title_helpers` to proposed `scr_options_menu` | title and pause callers from milestone 28 | No; preserve symbols | Milestone 28 tests and full GMTL; DV yes; GRC yes | Title and pause share one options owner with unchanged persistence/input behavior |
| 30 | Extract Music Room adapter | Title-local preview selection/toggle functions from `scr_title_helpers` to proposed `scr_music_room` | title state/view and audio helpers | No; preserve symbols | Existing preview-ownership test and full GMTL; DV no; GRC yes | Preview IDs, switching, stopping, and room-music ownership match |
| 31 | Characterize title navigation and view | No production move. Cover all pages/actions plus captures for press-start, main, character, gallery, music, options, controls, practice, and scores | title object, title state/view, run request, audio/options/practice | None | Title-flow GMTL and complete title-page visual captures; DV yes for input state, GRC no | Page/action state and approved render evidence are complete |
| 32 | Extract title state | State factory, input snapshot, and navigation state machine from `scr_title_helpers` to proposed `scr_title_state` | title Create/Step, catalog/options/practice/music modules, tests | No; preserve symbols | Milestone 31 state tests and full GMTL; DV yes; GRC yes | Title actions and page/index state match; no draw functions move |
| 33 | Extract title view | Remaining title-only draw/layout functions from `scr_title_helpers` to proposed `scr_title_view` | title Draw, catalogs, weapons preview, shared UI | No; preserve symbols | Milestone 31 captures and full GMTL; DV no; GRC yes | Every title page renders equivalently and old owner has no duplicate view code |
| 34 | Characterize story data | No production move. Cover missing, malformed, empty, array-root, struct-root, packaged and sandbox story files | story state/object and tests | None | Focused Included File/sandbox tests; DV no; GRC no | Current resolution, normalization, and failure outcomes are explicit |
| 35 | Extract story data | Story path/I/O/frame normalization/loading functions from `scr_story_helpers` to proposed `scr_story_data` | story state/object and tests | No; preserve symbols | Milestone 34 tests and full GMTL; DV no; GRC yes | File resolution and normalized frames match without flow/view changes |
| 36 | Extract story state | Queue/reveal/update functions from `scr_story_helpers` to proposed `scr_story_state` | story object, run state, input, tests | `GameStoryRuntimeEnsure` may temporarily forward to `scr_run_state` | Existing reveal tests plus milestone 17 runtime evidence; full GMTL; DV yes; GRC yes | Fixed-step reveal and runtime dialogue mutations match |
| 37 | Extract story flow | Route filename and room/result transition functions from `scr_story_helpers` to proposed `scr_story_flow` | scene manager, story object, run results, tests | No; preserve symbols | Route/transition tests plus milestone 21 result evidence; full GMTL; DV yes; GRC yes | Story seams, result write, and room IDs occur in the same order |
| 38 | Characterize story view | No production move. Cover portrait/background fallback, wrapping, visible lines, story box, and opening/ending captures | story Draw and shared UI | None | Focused layout tests and visual captures; DV no; GRC no | Layout and approved rendering evidence are complete |
| 39 | Extract story view | Story-only layout/draw functions from `scr_story_helpers` to proposed `scr_story_view` | story Draw, title/credits consumers, shared UI | No; preserve symbols | Milestone 38 evidence and full GMTL; DV no; GRC yes | Story rendering matches and shared primitives remain in `scr_ui_ornate` |
| 40 | Characterize boss pattern families | No production move. Add family bullet geometry/count/order/RNG/state checkpoints and selected captures | boss sunset Step, gameplay HUD, tests/visual tour | None | Boss-pattern tests and captures; DV yes; GRC no | Every selected family has a descriptor-to-event contract |
| 41 | Extract Mira/Aisha/sisters patterns | Three related family interpreters from `scr_boss_patterns` to proposed `scr_boss_patterns_mira_aisha` | dispatcher and tests; no direct production family caller | No; preserve family function names | Milestone 40 contracts, full GMTL, dual-boss capture; DV yes; GRC yes | Dual encounter geometry/RNG/state match and dispatcher stays authoritative |
| 42 | Extract Shalmii patterns | `GameBossShalmiiPatternFire` to proposed `scr_boss_patterns_shalmii` | dispatcher and tests | No; preserve symbol | Milestone 40 contract, full GMTL, capture; DV yes; GRC yes | Shalmii geometry and event order match |
| 43 | Extract Aster patterns | `GameBossAsterPatternFire` to proposed `scr_boss_patterns_aster` | dispatcher and tests | No; preserve symbol | Milestone 40 contract, full GMTL, capture; DV yes; GRC yes | Aster geometry and event order match |
| 44 | Extract Caelia patterns | `GameBossCaeliaPatternFire` to proposed `scr_boss_patterns_caelia` | dispatcher and tests | No; preserve symbol | Milestone 40 contract, full GMTL, capture; DV yes; GRC yes | Caelia geometry and event order match |
| 45 | Extract Saltwind patterns | `GameBossSaltwindPatternFire` to proposed `scr_boss_patterns_saltwind` | dispatcher and tests | No; preserve symbol | Milestone 40 contract and full GMTL; DV yes; GRC yes | Saltwind geometry and event order match |
| 46 | Extract Kelp patterns | `GameBossKelpPatternFire` to proposed `scr_boss_patterns_kelp` | dispatcher and tests | No; preserve symbol | Milestone 40 contract and full GMTL; DV yes; GRC yes | Kelp geometry and event order match |
| 47 | Extract Bloodtide patterns | `GameBossBloodtidePatternFire` to proposed `scr_boss_patterns_bloodtide` | dispatcher and tests | No; preserve symbol | Milestone 40 contract and full GMTL; DV yes; GRC yes | Bloodtide geometry and event order match |
| 48 | Extract route-finale patterns | `GameBossFinalePatternFire` and route-specific rose/chakram cases from the dispatcher to proposed `scr_boss_patterns_finale` | dispatcher, final boss, tests | No; preserve public finale symbol; introduce only narrow internal delegation | Milestone 40 route contracts, full GMTL, final-boss capture; DV yes; GRC yes | Rose/chakram geometry, RNG draws, and route identity match |
| 49 | Extract gameplay HUD | Camera/HUD/boss-health helpers from `scr_gameplay_helpers` to proposed `scr_gameplay_hud` | gameplay UI, camera, boss Draw, story UI, tests | No; preserve symbols | HUD/layout tests, milestone 1 captures, full GMTL; DV no; GRC yes | HUD owner is draw-focused and visuals match |
| 50 | Extract balance report | `GameStageBalanceReportCreate` from `scr_gameplay_helpers` to proposed `scr_gameplay_balance` after dependencies have stable owners | GMTL and domain public APIs | No; preserve symbol | Five-stage viability test and full GMTL; DV yes for dependency equivalence; GRC yes | Integration report no longer depends on old file adjacency and values match |
| 51 | Retire facades and close ownership | Remove only wrappers proven unused, update architecture/module map/status, and leave cohesive residual owners intact | search-proven remaining callers | This is the facade-retirement milestone | Caller searches, full GMTL, governance check, diff check; DV according to retired contract; GRC if metadata changes | No duplicate implementation or stale owner remains; documentation reflects durable ownership |

## First characterization thread

Recommended model: `gpt-5.6-sol` with **high** reasoning.

Exact scope: milestone 1 only. Add characterization evidence for the shared
ornate UI primitives currently declared in `scr_title_helpers` and
`scr_story_helpers`. Do not create a production resource or move any function.
Cover these caller surfaces:

- title main/options panels and outlined text;
- opening-story frame, ornaments, portrait/text composition;
- final-boss attack title/hearts and gameplay HUD panels;
- pause main, settings, practice tuning, and quit confirmation.

The thread should add the smallest focused GMTL assertions possible for pure
palette/layout/state results, run the selected existing visual-tour captures,
record approved before evidence, verify draw-state restoration, and stop. It
does not require `$determinism-validation`; it does not invoke
`$gamemaker-resource-change`; it must not begin milestone 2.

Use a documented available or hosted runner for runtime evidence; do not repair
the known local runner as part of characterization. If no authorized runner can
produce the captures, record the visual portion as unverified and stop before
extraction rather than treating compilation or test construction as a pass.

### Milestone 1 characterization status

The focused `Shared ornate UI characterization` GMTL section defines normal and
selected palettes, title-main and title-options ordering and boundary values,
opening-story portrait and empty-text layout, final-boss HUD anchors and
one-to-fifteen heart states, all four pause-page row/selection contracts, and
draw-state postconditions for the shared primitives.

Milestone 1 is fully validated at characterization candidate
`acdf8e529ffe68e38fb87580c73ca5cee2286f6d`. Hosted GMTL run `29889767822`
reported `Test Suites: 1 passed, 1 total` and `Tests: 134 passed, 134 total`.
Visual-tour run `29889883786`, using reviewed workflow commit
`23340db00676a343c826db3ef51ef2b2e60aa543`, produced and passed review for
`01_title_main_menu`, `05_title_options`, `06_opening_story`, `16_final_boss`,
`21_pause_main`, `22_pause_settings`, `23_pause_practice_tuning`, and
`24_pause_quit_confirm` without a visual regression.

Milestone 2 moves exactly the characterized primitives into the registered
`scr_ui_ornate` resource without renaming symbols or adding a facade. Its own
frozen candidate still requires the full hosted GMTL and selected visual-tour
validation specified by the milestone.

Suspicious existing behavior is recorded rather than repaired here:
`GameUiDrawOrnamentDiamond` restores alpha but leaves the requested draw color,
and `GameUiDrawFiligreeDivider` therefore leaves the palette jewel color after
its final ornament. The characterization test preserves those current
postconditions; any normalization belongs to a separate behavior-change task.

## Migration status

| Area | Status | Next action |
| --- | --- | --- |
| Audit and routing | Complete | Use this plan and the module map for every structural thread |
| Shared ornate UI | Milestone 1 validated; milestone 2 extracted to registered `scr_ui_ornate` | Validate the frozen milestone 2 candidate with full hosted GMTL, selected captures, and high-tier delegated review |
| Stage rules | Characterization required | Milestone 3 after shared UI extraction |
| Boss plans | Existing focused coverage is likely sufficient; determinism checkpoint still required at extraction | Milestone 5 |
| Rank | Existing focused coverage is strong; frozen-frame checkpoint required | Milestone 6 |
| Waves/enemy catalog | Blocked on characterization, not on repository state | Milestone 7 |
| Enemy projectiles | Blocked on characterization, not on repository state | Milestone 9 |
| Player weapons | Blocked on timing/entity characterization | Milestone 11 |
| Rewards and survival | Blocked on ordered state/event characterization | Milestones 13 and 15 |
| Runtime/setup/persistence | Deliberately late; blocked on boot/save characterization and earlier seams | Milestones 17 onward |
| Practice/pause | Planned after shared UI and runtime seams | Milestones 25 and 26 |
| Title/story | Planned after shared UI, options, and runtime seams | Milestones 27-39 |
| Boss pattern families | Cohesive current owner; defer until family geometry/RNG characterization | Milestones 40-48 |
| Input/audio/stage 3D | Monitor; no extraction selected by this audit | Re-audit only when a bounded task demonstrates recurring mixed ownership |

The repository is ready to begin milestone 1 characterization. It is not ready
to begin RNG-sensitive extraction without the specified traces, and this audit
does not authorize any production milestone.

# Structural Module Ownership Map

This map supports the [structural decomposition plan](STRUCTURAL_DECOMPOSITION_PLAN.md).
It records current ownership and proposed future seams. A proposed resource is
not a current runtime owner unless its row explicitly records the extraction.

Status values:

- **current**: implemented ownership;
- **extracted**: the approved ownership move is implemented and awaits or has
  completed its milestone validation;
- **characterize**: contract evidence is required before moving code;
- **extract-ready**: focused coverage exists, subject to the milestone's stated
  deterministic checkpoint;
- **defer**: no extraction is selected by this audit.

All proposed GameMaker scripts require a `.gml`, matching `.yy`, and `.yyp`
registration under `$gamemaker-resource-change`. Existing project-owned script
resources use the `Selkies Moon` project root as their Asset Browser parent, so
future milestones should use that existing convention. A physical
`scripts/<resource>/` directory is separate from the Asset Browser parent. IDE
folder reorganization remains out of scope.

## `scr_gameplay_helpers` cluster map

The current resource owns 190 public function declarations and 162 macros.
Public names should remain stable during straight extraction. A compatibility
facade is needed only where the table says that a new narrow interface must
replace a circular or overly broad contract.

| Cluster | Current responsibility and owned data | Important external callers and dependencies | Side effects and behavior-sensitive contracts | Existing tests and gaps | Proposed destination and facade | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Practice | Default/normalized practice request, labels, title request, scene seam, waves-only predicate, retained return | title Create/Step and helpers; scene manager; pause; setup runtime factory; visual tour | Mutates runtime run mode/config/ship/stage and changes rooms; restart/return must not write run stats | practice normalize/init/segment/pause tests; gap: complete exit-path matrix | `scr_practice`; no facade, preserve names | characterize |
| Pause menu | Pause state/input, live tuning, state machine, and draw | `obj_UI_menu` Step/Draw; title-owned options; input helpers; `scr_ui_ornate` draw primitives | Mutates runtime stock/rank/meter/config; freeze/resume and End Step close ordering; config writes | pause/settings/tuning/quit tests and visual captures; gap: draw-state assertions | `scr_pause_menu`; no facade after `scr_ui_ornate` and options seams exist | characterize |
| Run state | Runtime compatibility ensure, ship/mode predicates, transient clear, normal request, abort, start initialization, frozen predicate | app/scene/title/story/audio/HUD and nearly every gameplay actor; setup defaults/save/reset | Co-owns `global.game_runtime`, increments/saves starts, clears nested signals/story, changes rooms | default runtime, run start, practice and exit tests; gap: boot/ensure/transition matrix | `scr_run_state`; temporary wrappers for `GameRuntimeDataCreateDefault`, `GameRuntimeGameplayEnsure`, and `GameRuntimeReset` while breaking setup cycle | characterize |
| Rank | Rank state, event counters, pressure conversion, cadence and speed scaling | scene, enemies, bullets, bosses, player survival/rewards, practice, HUD | Mutates `rank`, `rank_frame`, `rank_defeats`; frame/freeze timing changes difficulty | pressure, dynamic rank, passive rank, defeat threshold tests; gap: cross-event frame trace | `scr_rank`; no facade | extract-ready with DV |
| Stage rules and flow | Scene state, stage catalog/theme, predicates, stage notice/progression, background route, camera/field geometry and positions | scene manager, player, boss/enemy objects, audio, stage 3D, HUD | Mutates scene state and runtime stage fields; room progression and stage-clear audio | stage advance, geometry, 3D, practice seam tests; gap: catalog/theme and exact transition matrix | pure catalog/geometry to `scr_stage_rules`; mutable progression to `scr_stage_flow`; no facade | characterize |
| Wave director and enemy catalog | Spawn band/RNG, rosters, instance configuration, live director, stage enemy bullet decoration, combat clear | scene manager, enemy variant, bullet draw, boss patterns, visual tour | Consumes RNG, creates/destroys entities, writes enemy fields, relies on stage/rank and instance Create order | roster/director/timeline/balance tests; gap: seeded RNG and ordered spawn/entity trace | `scr_wave_director`; no facade | characterize |
| Player input and ship catalog | Gameplay input snapshot plus player/ship identity, sprites, display names, final opponent | player, scene, audio, title, credits, boss plans | Reads unified input and run ship; resource identity must remain exact | movement/weapon/ship/title tests; gap: input snapshot has indirect coverage | input snapshot may remain player-owned; identity to `scr_ship_catalog`; no facade | extract-ready after scope split |
| Boss plans | Descriptor factory, phase names/notices, counts, HP/damage formulas, seeds/variants/finales/signatures, encounter identity | boss Create/Step, story, scene, HUD, patterns, player shot damage, balance report | Defines progression and balance; phase order/signature is a deterministic contract | extensive counts, motifs, signatures, HP, descriptor/interpreter tests | `scr_boss_plans`; no facade | extract-ready with DV |
| Boss runtime | Damage application, dual identities/configuration/member enumeration, shared-finale mutation and defeat handoff | boss parent/sunset, player shots/sword, scene manager, rewards | Mutates two live bosses, bullets, medals, sound, phase timers, HP and visibility | dual finale and phase-transition tests; gap: member order and per-frame shared-final trace | `scr_boss_runtime`; no facade | characterize |
| Player weapons | Shot specs and visuals, route patterns, sword timing/geometry/sweep IDs/damage, fire state | player Step/Draw, player shots, title preview, boss HP/balance | Mutates player local fire state, creates ordered shot specs, damages instances; timing and collision iteration sensitive | broad shot/autofire/sword/damage tests; gap: exact frame/entity trace | `scr_player_weapons`; no facade | characterize |
| Run rewards | Medal counts/spread, bullet cancellation, Berserk meter, point-blank gain, pickup presentation/reward/drop cadence | enemy/boss/bullet/medal/power-up/player/scene events, HUD/balance | Mutates score, meter, stock, rank, counters; creates medals/pickups; cancellation resolves next bullet Step | reward/drop/medal/Berserk/bomb tests; gap: ordered cross-event trace | `scr_run_rewards`; no facade | characterize |
| Player survival | Player state, death/respawn, bomb mirror, continue prompt/accept/decline, game-over finalization, bullet hit | player, bullet parent, scene, HUD, run results | Mutates local and global state, cancels bullets, changes rooms, writes results | continue/bomb/game-over tests; gap: all exit/freeze paths in one trace | `scr_player_survival`; no facade | characterize |
| Enemy projectiles | Shared linear spawn/flash, blade motion, turret/bee/mayfly specs, redirects | enemy objects, bullet parent/blade, player, boss patterns/runtime | Consumes RNG, creates/mutates bullets, snapshots rank speed, uses inherited Step guards | projectile geometry/motion/redirect tests; gap: seeded per-frame trace | `scr_enemy_projectiles`; no facade | characterize |
| Gameplay HUD | Camera application, HUD layout/lines, boss segments/hearts/circular health draw | camera, gameplay UI, boss Draw, story UI | Mutates camera/draw state; reads broad runtime and boss state | layout/segment/heart tests and visual tour; gap: pixel/draw-state characterization | `scr_gameplay_hud`; no facade | characterize |
| Balance report | Cross-domain no-continue viability report | GMTL; indirectly every domain it samples | Test-facing production calculation couples wave, reward, weapon and boss tuning | dedicated five-stage viability test | `scr_gameplay_balance` after dependencies move; no facade | defer until late |

### Gameplay public function inventory

The following lists are exhaustive for declarations in the current file. A
function can have cross-cluster dependencies even though it appears once under
its primary responsibility.

- Practice and pause: `GamePauseStateCreate`, `GamePracticeConfigCreateDefault`,
  `GamePracticeConfigNormalize`, `GamePracticeSegmentNameGet`,
  `GamePracticeSegmentNameForStageGet`, `GamePauseInputSnapshotCreate`,
  `GamePauseInputSnapshotFromGlobal`, `GameMenuValueWrap`,
  `GamePauseMainItemsCreate`, `GamePracticeLiveEntriesCreate`,
  `GamePracticeLiveAdjust`, `GamePauseStateStep`, `GamePauseDrawRow`,
  `GamePauseDraw`, `GamePracticeRunRequestConfigure`,
  `GamePracticeReturnToTitle`, `GamePracticeSceneStateApply`,
  `GamePracticeWavesOnly`.
- Run state and rank: `GameRuntimeGameplayEnsure`, `GameRunShipIdGet`,
  `GameRunIsPractice`, `GameRunStatsShouldRecord`,
  `GameRunTransientStateClear`, `GameNormalRunRequestConfigure`,
  `GameRunAbortToTitle`, `GameRankGet`, `GameRankSet`,
  `GameRankDynamicEnabled`, `GameRankEventApply`, `GameRankStep`,
  `GameRankDefeatRewardApply`, `GameRankPressureCreate`,
  `GameRankSpawnIntervalGet`, `GameRankFireIntervalGet`,
  `GameRankBulletSpeedScaleGet`, `GameRunStartInitialize`,
  `GameGameplayIsFrozen`.
- Stage rules, flow, and waves: `GameSceneStateCreate`,
  `GameSceneBackgroundStep`, `GameSceneBackgroundBossRouteBegin`,
  `GameCurrentStageGet`, `GameStageIsFinal`, `GameStageHasCharacterBoss`,
  `GameStageInfoGet`, `GameStageBackgroundThemeCreate`,
  `GameStageLegacyPatternStageGet`, `GameStageNoticeRestart`,
  `GameStageNoticeStep`, `GameSceneStageClearBegin`,
  `GameSceneNextStageBegin`, `GameSceneStageAdvance`,
  `GameSceneFieldRectGet`, `GameScenePlayerClampPosition`,
  `GamePlayerMovementDeltaCreate`, `GameSceneCameraTargetXGet`,
  `GameScenePlayerRespawnPositionGet`, `GameSceneBossSpawnPositionGet`,
  `GameStageSpawnBandRectGet`, `GameStageRandomSpawnXGet`,
  `GameStageTurretSpawnPositionCreate`, `GameStageBeeSpawnPositionsCreate`,
  `GameStageMayflySpawnPositionCreate`, `GameStageTimelineTurretSpawn`,
  `GameStageTimelineBeeWaveSpawn`, `GameStageTimelineMayflySpawn`,
  `GameStageTimelineShouldRun`, `GameStageEnemyRosterCreate`,
  `GameStageEnemyDefinitionGet`, `GameEnemyVariantConfigure`,
  `GameStageEnemyBulletDecorate`, `GameStageEnemyBulletSpawn`,
  `GameStageTimelineVariantWaveSpawn`, `GameStageBasicEnemyWaveSpawn`,
  `GameStageEliteVariantKindGet`, `GameStageDirectorStep`,
  `GameStageBalanceReportCreate`, `GameSceneCombatClear`.
- Input and ship identity: `GameGameplayInputSnapshotCreate`,
  `GameGameplayInputSnapshotRead`, `GamePlayerPowerGet`,
  `GamePlayerShipSpriteGet`, `GamePlayerShipNameGet`,
  `GamePlayerShipDrawScaleYGet`, `GamePlayerShipDisplayNameGet`,
  `GameFinalBossOpponentShipIdGet`, `GameFinalBossDrawScaleYGet`.
- Boss plans and runtime: `GameMemoryCorePhaseCreate`,
  `GameBossPhaseDisplayNameGet`, `GameBossPhaseNoticeAlphaGet`,
  `GameBossExpandedPhaseCountForStage`, `GameBossPhaseCountForStage`,
  `GameBossPhaseHpGet`, `GameBossPhaseTargetSecondsGet`,
  `GameBossDamageScaleGet`, `GameBossDamageApply`, `GameMemoryCoreNameGet`,
  `GameMemoryCoreBasePhasePlanCreate`, `GameMemoryCoreFinalPhaseCreate`,
  `GameBossPhaseVariantCreate`, `GameBossPhasePlanExpand`,
  `GameMemoryCorePhasePlanCreate`, `GameCharacterBossPhasePlanCreate`,
  `GameFinalBossBasePhasePlanCreate`, `GameFinalBossFinalPhaseCreate`,
  `GameFinalBossPhasePlanCreate`, `GameMemoryCorePhaseSignatureCreate`,
  `GameMemoryCorePhasePlanSignatureCreate`, `GameCharacterBossInfoCreate`,
  `GameStageIsDualBoss`, `GameDualBossIdentityCreate`,
  `GameBossDualConfigure`, `GameBossDualMembersCreate`,
  `GameBossDualFinalPhaseCreate`, `GameBossDualFinaleTryBegin`,
  `GameBossDualIndividualDefeatBegin`, `GameBossEncounterInfoCreate`.
- Player weapons: `GameShotSpecCreate`, `GamePlayerShotPairAppend`,
  `GamePlayerShotPowerColorGet`, `GamePlayerShotPowerAccentColorGet`,
  `GamePlayerShotPowerScaleGet`, `GamePlayerShotVisualsApply`,
  `GamePlayerSunriseShotSpawnSpecsCreate`,
  `GamePlayerSelkieShotSpawnSpecsCreate`, `GamePlayerShotSpawnSpecsCreate`,
  `GamePlayerSwordPeriodFramesGet`, `GameCosineEase01`,
  `GamePlayerSwordPoseCreate`, `GamePlayerSwordShouldCancelBullet`,
  `GamePlayerSwordSweepIdStep`, `GamePlayerSwordDamageTryApply`,
  `GamePlayerFireStep`.
- Rewards and pickups: `GameMedalRewardCreate`,
  `GameEnemyMedalDropCountGet`, `GameBossPhaseMedalDropCountGet`,
  `GameMedalsSpawnSpread`, `GameEnemyMedalsDrop`,
  `GameBossPhaseMedalsDrop`, `GameBulletCancelMark`,
  `GameBulletsCancelAll`, `GamePlayerBerserkActivate`,
  `GamePlayerMeterRewardApply`, `GamePlayerBerserkAttackMeterStep`,
  `GamePlayerPointBlankAttackRewardApply`, `GamePlayerBerserkDrainStep`,
  `GamePowerupColorGet`, `GamePowerupSpriteGet`, `GamePowerupLabelGet`,
  `GamePowerupRewardApply`, `GameScorePickupDropPeriodGet`,
  `GameResourceDropChargeThresholdGet`, `GameResourceDropLimitGet`,
  `GameResourceDropDefeatPeriodGet`, `GamePowerupResourceDropTypeChoose`,
  `GameEnemyPowerupDropTry`.
- Player survival: `GameContinueStateCreate`, `GamePlayerStateCreate`,
  `GameContinueStateStep`, `GamePlayerRespawnStateApply`,
  `GamePlayerDeathBegin`, `GamePlayerBombStateSync`,
  `GamePlayerBombActiveGet`, `GamePlayerBombIsActive`,
  `GamePlayerIsInvulnerable`, `GamePlayerBombTryStart`,
  `GamePlayerBombStep`, `GamePlayerBombVisualCreate`,
  `GamePlayerContinueRequestBegin`, `GamePlayerContinueAccept`,
  `GamePlayerGameOverFinalize`, `GamePlayerBulletHitCheck`.
- Enemy projectiles: `GameBladeMotionStepCreate`,
  `GameEnemyBulletLinearSpawn`, `GameEnemyBulletFlashAlphaGet`,
  `GameMayflyTargetAnchorOffsetYGet`, `GameTurretShotSpecCreate`,
  `GameBeeShotSpecCreate`, `GameBeeShotSpawnSpecsCreate`,
  `GameMayflyInfinityOffsetCreate`, `GameMayflyBurstStateCreate`,
  `GameMayflyBladeShotSpecCreate`, `GameMayflyShotSpawnSpecsCreate`,
  `GameBladeBulletRedirectMark`, `GameBladeBulletsRedirectAll`.
- HUD and camera: `GameCameraViewApply`, `GameGameplayHudLayoutCreate`,
  `GameGameplayHudLinesCreate`, `GameBossBarSegmentsCreate`,
  `GameBossPhaseHeartStatesCreate`, `GameBossCircularHealthDraw`.

### Gameplay macro inventory and proposed ownership

- Stage/camera to `scr_stage_rules` or `scr_stage_flow`:
  `GAME_VIEW_WIDTH`, `GAME_VIEW_HEIGHT`, `GAME_VIEW_HALF_WIDTH`,
  `GAME_VIEW_HALF_HEIGHT`, `PLAYFIELD_HALF_WIDTH`,
  `PLAYFIELD_HALF_HEIGHT`, `PLAYFIELD_VERTICAL_PADDING`, `CAMERA_HOME_X`,
  `CAMERA_HOME_Y`, `CAMERA_DRAG_LIMIT`, `CAMERA_DRAG_MARGIN`,
  `CAMERA_SCROLL_SPEED`, `STAGE_SPAWN_ABOVE_VIEW`,
  `STAGE_SPAWN_SIDE_MARGIN`, `STAGE_BEE_WAVE_COUNT`, `STAGE_COUNT`,
  `LEGACY_STAGE_COUNT`, `SHALMII_BOSS_STAGE`, `ASTER_BOSS_STAGE`,
  `DUAL_BOSS_STAGE`, `MIRA_BOSS_STAGE`, `AISHA_BOSS_STAGE`,
  `CAELIA_BOSS_STAGE`, `MIRA_BOSS_NAME`, `MIRA_SHIP_NAME`,
  `SHALMII_BOSS_NAME`, `SHALMII_SHIP_NAME`, `AISHA_BOSS_NAME`,
  `AISHA_SHIP_NAME`, `ASTER_BOSS_NAME`, `ASTER_SHIP_NAME`,
  `CAELIA_BOSS_NAME`, `CAELIA_SHIP_NAME`, `STAGE_NOTICE_FRAMES`,
  `STAGE_CLEAR_DELAY_FRAMES`, `STAGE_LENGTH_FRAMES`.
- Player weapons/survival/rewards to their domain owners:
  `PLAYER_MOVE_SPEED`, `PLAYER_FOCUS_SPEED_MULTIPLIER`,
  `PLAYER_RESPAWN_OFFSET_Y`, `PLAYER_DEATH_ANIMATION_FRAMES`,
  `BOMB_DURATION_FRAMES`, `BOMB_INVULN_FRAMES`,
  `BOMB_VISUAL_MAX_RADIUS`, `PLAYER_POWER_MAX`, `PLAYER_LIFE_MAX`,
  `PLAYER_BOMB_MAX`, `SHOT_SPEED`, `PLAYER_SHOT_DAMAGE`,
  `SWORD_SWEEP_SHOT_EQUIVALENT`, `SWORD_SWEEP_DAMAGE`,
  `SHOT_VOLLEY_SIZE`, `SHOT_VOLLEY_INTERVAL`, `FIRE_HOLD_FRAMES`,
  `SHOT_SPRITE_FRONT`, `SHOT_SPRITE_SIDE`, `SWEEP_PERIOD_FRAMES`,
  `SWORD_START_ANGLE`, `SWORD_END_ANGLE`, `SWORD_LENGTH`,
  `BERSERK_SWORD_MULTIPLIER`, `BERSERK_SWORD_DAMAGE_MULTIPLIER`,
  `INVULN_TIME`, `BERSERK_ACTIVATION_INVULN_FRAMES`,
  `BERSERK_PASSIVE_ATTACK_INTERVAL`, `BERSERK_PASSIVE_ATTACK_GAIN`,
  `BERSERK_POINT_BLANK_RADIUS`, `BERSERK_POINT_BLANK_SHOT_GAIN`,
  `BERSERK_POINT_BLANK_SWORD_GAIN`, `ENEMY_MEDAL_BERSERK_GAIN`,
  `BULLET_CANCEL_SCORE_BONUS`, `BULLET_CANCEL_BERSERK_GAIN`,
  `METER_MAX`, `CONTINUE_OPTION_YES`, `CONTINUE_OPTION_NO`,
  `GAME_OVER_DELAY_FRAMES`.
- Enemy projectiles and movement to `scr_enemy_projectiles` or
  `scr_wave_director`: `TURRET_FIRE_INTERVAL`, `TURRET_BULLET_SPEED`,
  `BEE_MOVE_SPEED`, `BEE_FIRE_INTERVAL`, `BEE_BULLET_SPEED`,
  `BEE_BULLET_SPEED_DELTA`, `MAYFLY_PATTERN_PERIOD`,
  `MAYFLY_SECOND_BURST_DELAY`, `MAYFLY_BURST_COUNT`,
  `MAYFLY_BLADE_TURN_SPEED`, `MAYFLY_BLADE_RADIAL_SPEED`,
  `BLADE_TURN_RATE_SCALE`, `BLADE_MAX_SCREEN_SPEED`,
  `BLADE_MAX_RADIAL_SPEED`, `BLADE_REDIRECT_MAX_SCREEN_SPEED`,
  `MAYFLY_FLOAT_X_RADIUS`, `MAYFLY_FLOAT_Y_RADIUS`,
  `MAYFLY_FLOAT_RATE`, `MAYFLY_VISIBLE_Y`, `MAYFLY_DROP_SPEED`.
- Bosses to `scr_boss_plans` or `scr_boss_runtime`:
  `BOSS_PHASE_COUNT`, `FINAL_BOSS_PHASE_COUNT`,
  `FINAL_BOSS_EXPANDED_PHASE_COUNT`, `BOSS_PHASE_HP`,
  `BOSS_PHASE_HP_STAGE_STEP`, `BOSS_PHASE_MIN_HP`,
  `BOSS_DAMAGE_SCALE_MIN`, `BOSS_DESTRUCTION_FRAMES`,
  `BOSS_PHASE3_FREEZE_FRAMES`, `BOSS_PHASE3_REDIRECT_SPEED`,
  `BOSS_PHASE3_REDIRECT_ACCELERATION`, `BOSS_PHASE_NOTICE_FRAMES`,
  `BOSS_PHASE_NOTICE_FADE_IN_FRAMES`,
  `BOSS_PHASE_NOTICE_FADE_OUT_FRAMES`, `BOSS_PHASE_TRANSITION_FRAMES`,
  `BOSS_PHASE_REFILL_FRAMES`.
- Run, rank, practice, rewards, and enemy catalog to their named owners:
  `SHIP_SUNRISE`, `SHIP_SELKIE`, `POWERUP_POWER`, `POWERUP_BOMB`,
  `POWERUP_LIFE`, `POWERUP_METER`, `POWERUP_SCORE`,
  `POWERUP_METER_VALUE`, `POWERUP_SCORE_VALUE`,
  `RESOURCE_DROP_CHARGE_BASE`, `RESOURCE_DROP_DEFEAT_MULTIPLIER`,
  `RESOURCE_DROP_LIMIT_BASE`, `SCORE_PICKUP_DROP_PERIOD_BASE`,
  `RANK_MIN`, `RANK_MAX`, `RANK_DEFAULT`, `RANK_PASSIVE_INTERVAL`,
  `RANK_DEFEATS_PER_POINT`, `RANK_HYPER_GAIN`,
  `PRACTICE_SEGMENT_FULL`, `PRACTICE_SEGMENT_WAVES`,
  `PRACTICE_SEGMENT_BOSS`, `ENEMY_VARIANT_MOTH`,
  `ENEMY_VARIANT_KELP`, `ENEMY_VARIANT_WISP`, `ENEMY_VARIANT_NEEDLE`,
  `ENEMY_VARIANT_MIRROR`, `ENEMY_VARIANT_TIDEGLASS`,
  `ENEMY_VARIANT_SALTWIND`, `ENEMY_VARIANT_BRAMBLE`,
  `ENEMY_VARIANT_BLOODTIDE`, `ENEMY_FORGE_SPARK`,
  `ENEMY_ANVIL_FAMILIAR`, `ENEMY_BELLOWS_IMP`,
  `ENEMY_HAMMER_CHERUB`, `ENEMY_RIBBON_HARE`, `ENEMY_WINGED_STAFF`,
  `ENEMY_LAVENDER_KNOT`, `ENEMY_SALTWIND_PINWHEEL`,
  `ENEMY_SPADE_FAMILIAR`, `ENEMY_DEALER_MASK`,
  `ENEMY_ORDER_TALISMAN`, `ENEMY_CHAOS_SHARD`,
  `ENEMY_CLOCKWORK_PLANET`, `ENEMY_ASTROLABE_EYE`,
  `ENEMY_CONSTELLATION_LANCE`, `ENEMY_BLOODSTAR_HEART`,
  `ENEMY_VIOLET_BEE`, `ENEMY_TWILIGHT_MAYFLY`,
  `ENEMY_THORN_RELIQUARY`, `ENEMY_CHAKRAM_SERAPH`.

## `scr_setup` cluster map

| Cluster | Public interface | Owned state and side effects | Callers/tests/gaps | Proposed destination and facade | Status |
| --- | --- | --- | --- | --- | --- |
| Defaults and runtime schema | `GameStructFieldEnsure`, `GameConfigCreateDefault`, `GameSaveDataCreateDefault`, `GameRuntimeDataCreateDefault`; macros `CONFIG_VERSION`, `SAVE_VERSION`, `RUNTIME_VERSION`, `DEFAULT_LIVES`, `DEFAULT_BOMBS` | Constructs config/save/runtime shapes; depends on input and gameplay constructors | app init, gameplay ensure/start, title/audio/tests; gap: full boot/ensure checkpoint | config/save defaults to `scr_persistence`; runtime/default stock to `scr_run_state`; runtime legacy wrapper required | characterize |
| Persistence transport | `GamePersistenceIsAutomationRun`, `GamePersistenceNamespaceGet`, `GameSavePathGet`, `GameConfigPathGet`, `GamePersistenceBackupPathGet`, `GamePersistenceTextRead`, `GamePersistenceTextWrite`, `GamePersistenceBackupWrite`, `GamePersistenceJsonParse`, `GamePersistenceVersionGet` | Sandboxed file I/O, backups, debug messages, automation namespace | strong integration tests; direct failure/rewrite gaps | `scr_persistence`; preserve names | characterize |
| Validation and migration | `GameSaveValueArrayNormalize`, `GameSaveValueArrayIsCurrent`, `GameSaveTableIsCurrent`, `GameSaveDataIsCurrent`, `GameSaveTableMigrate`, `GameSaveDataMigrate`, `GameConfigDataMigrate`, `GameConfigDataIsCurrent`, `LoadGameSave`, `LoadGameConfig`, `SaveGameSave`, `SaveGameConfig` | Reads/writes persisted shapes and replaces `global.game_save`/`global.game_config` | load/migrate/future/malformed/config tests | `scr_persistence`; preserve names | characterize |
| Run results | `GameSaveShipEntriesEnsure`, `GameValueArrayInsertAt`, `GameValueArrayInsertDescendingIndex`, `GameRunResultSave` | Mutates score/stat arrays and writes save; reads gameplay run mode/runtime | story ending, game-over, credits/title, tests; gap: qualifying-score alignment and exit matrix | `scr_run_results`; optional `GameRunResultSave` wrapper if API narrows | characterize |
| Runtime reset | `GameRuntimeReset` | Replaces `global.game_runtime` | gameplay abort/game-over/credits/tests | `scr_run_state`; temporary wrapper | characterize |
| Display and boot | `GameWindowDisplayScaleFitGet`, `GameWindowCenterNow`, `GameWindowCenterStep`, `GameConfigApply`, `GamePixelPresentationScaleIsInteger`, `GamePixelPresentationLinearFilterGet`, `GamePixelPresentationApply`, `GameInitialize` | Mutates delayed window globals; window, surface, GPU, audio and game-speed side effects; initializes all globals | app init Create/Step/Draw and title options; pixel tests; gap: whole boot order | display to `scr_display`; keep `GameInitialize` as setup/bootstrap orchestrator | display extract-ready; boot characterize |

## `scr_title_helpers` cluster map

Title clusters do not require compatibility facades when their existing global
function names are preserved.

| Cluster | Public interface | State/dependencies/side effects | Evidence and gaps | Proposed destination | Status |
| --- | --- | --- | --- | --- | --- |
| Catalogs | `GameTitleCharactersCreate`, `GameTitleGalleryItemsCreate`, `GameTitleMusicItemsCreate`, `GameTitleMainItemsCreate`, `GameTitleCharacterGet`, `GameTitleScoresGet` | Static resource/audio IDs plus `global.game_save` score reads | title metadata/gallery/music tests; no mutation | `scr_title_catalog` | extract-ready |
| Title state and input | `GameTitleStateCreate`, `GameTitleInputSnapshotCreate`, `GameTitleInputSnapshotFromGlobal`, `GameTitleStateStep` | Mutates local page/index state; returns room/quit actions; reads input helpers and all submodules | extensive title-flow tests; gap: whole page/action trace | `scr_title_state` | characterize |
| Options/remap | `GameTitleConfigEntriesCreate`, `GameTitleControlEntriesCreate`, `GameTitleRemapBegin`, `GameTitleRemapCommit`, `GameTitleRemapCancel`, `GameTitleRemapCaptureUpdate`, `GameTitleConfigValueWrap`, `GameTitleConfigEntryAdjust` | Raw keyboard/gamepad polling, `global.game_input`, config mutation, save/apply, SFX | options/remap/volume tests; pause is an external caller; gap: raw capture release timing | `scr_options_menu` | characterize for timing |
| Practice page | `GameTitlePracticeEntriesCreate`, `GameTitlePracticeEntryAdjust`, `GameTitlePracticeHelpGet` | Mutates title practice struct; depends on gameplay practice/rank/stock macros | practice menu and normalization tests | page view/state can remain title-owned; shared rules move to `scr_practice` | extract-ready after practice owner |
| Music Room | `GameTitleMusicPreviewStop`, `GameTitleMusicPreviewPlaySelected`, `GameTitleMusicPreviewToggle` | Mutates local preview IDs and delegates audio preview ownership | focused preview test | `scr_music_room` or remain thin title adapter over audio | defer until title split |
| Title view | `GameTitleDrawFrame`, `GameTitleDrawSpriteFit`, `GameTitleDrawBackground`, `GameTitleDrawSilhouetteDecorators`, `GameTitlePressStartSubtitleAnimCreate`, `GameTitleDrawPageHeading`, `GameTitlePanelStyleCreate`, `GameTitleDrawLogo`, `GameTitlePressPromptTextGet`, `GameTitleDrawPrompt`, `GameTitleDrawMenuItem`, `GameTitleDrawMainMenu`, `GameTitleDrawOptionsPage`, `GameTitleDrawControlsPage`, `GameTitleDrawPracticePage`, `GameTitleDrawScoresPage`, `GameTitleDrawGalleryPage`, `GameTitleDrawMusicRoomPage`, `GameTitleDrawCharacterSelectPage`, `GameTitleDrawCharacterAttackPreview`, `GameTitleDraw` | Draw state, many sprites/fonts, gameplay weapon preview; consumes shared ornate primitives from `scr_ui_ornate` | prompt/style tests and visual tour; gap: title-only pixel/draw-state assertions | remainder to `scr_title_view` | characterize |

## `scr_story_helpers` cluster map

Story clusters do not require compatibility facades when names are preserved,
except that `GameStoryRuntimeEnsure` may temporarily forward to the future run
state owner while the current shared-runtime cycle is retired.

| Cluster | Public interface | State/dependencies/side effects | Evidence and gaps | Proposed destination | Status |
| --- | --- | --- | --- | --- | --- |
| Story data | `GameStoryFrameCreate`, `GameStoryPathJoin`, `GameStoryResolveFilePath`, `GameStoryFileReadAll`, `GameStoryPositionDefaultForIndex`, `GameStoryFrameNormalize`, `GameStoryFramesNormalize`, `GameStoryLoadFramesFromFile` | Included File and sandbox path resolution, text I/O, JSON parse | Included File and normalization-through-flow tests; gap: missing/malformed/empty roots | `scr_story_data` | characterize |
| Story state/reveal | `GameStoryStateCreate`, `GameStoryRuntimeEnsure`, `GameStoryIsActive`, `GameStoryStateClear`, `GameStoryTypewriterDelayForCharacter`, `GameStoryTextArrowFrameGet`, `GameStoryRevealReset`, `GameStoryRevealComplete`, `GameStoryRevealStep`, `GameStoryContinue`, `GameStoryBegin`, `GameStoryAdvance`, `GameStoryAdvanceInputPressed`, `GameStoryUpdate` | Local queue/reveal fields and runtime story/dialogue fields; fixed Step cadence and `current_time` arrow | strong reveal/advance tests; gap: runtime ensure direct contract and combined step trace | `scr_story_state`; runtime ensure may temporarily forward to `scr_run_state` | characterize |
| Story flow | `GameStoryQueueRequest`, `GameFinalBossStoryFileGet`, `GameCharacterBossStoryFileGet`, `GameEndingStoryFileGet`, `GameStoryDefaultFileGet`, `GameStoryRoomComplete`, `GameStoryNextRoomGet`, `GameStoryTransitionRoomGet` | Chooses route files, toggles dialogue, saves ending result, returns room IDs | route, boss story, opening/ending transition tests; gap: complete exit/save trace | `scr_story_flow` | characterize with DV |
| Text/layout and story view | `GameStoryPortraitRectGet`, `GameStoryPortraitColorGet`, `GameStoryDrawPortraitPlaceholder`, `GameStoryDrawPortrait`, `GameStoryDrawBackgroundSprite`, `GameStoryDrawBackground`, `GameStoryTextClampToWidth`, `GameStoryTextLinesCreate`, `GameStoryVisibleLinesCreate`, `GameStoryDrawBox`, `GameStoryDraw` | Draw state, portrait/background resources, two-line wrapping | wrapping/typewriter/visual-tour evidence; gap: render baseline | `scr_story_view` | characterize |
| Shared ornate UI | `GameUiDrawOutlinedText`, `GameUiDrawOutlinedTextExt`, `GameUiStoryFramePaletteCreate`, `GameUiDrawOrnamentDiamond`, `GameUiDrawPixelFiligreeCorner`, `GameUiDrawQuadraticThread`, `GameUiDrawFiligreeDivider`, `GameUiDrawVolumeGauge`, `GameUiDrawPixelHeart`, `GameUiDrawBossPhaseHearts`, `GameUiDrawOrnateFrame` | `scr_ui_ornate`; shared by title, gameplay HUD, pause, and story; preserves characterized draw-state side effects | 134-test hosted GMTL pass and eight reviewed milestone 1 captures; milestone 2 candidate validation pending | `scr_ui_ornate` | extracted |

## `scr_boss_patterns` cluster map

Boss family moves do not require compatibility facades: family functions keep
their global names and the existing dispatcher remains the public authority.

| Cluster | Public interface | State/dependencies/side effects | Evidence and gaps | Proposed destination | Status |
| --- | --- | --- | --- | --- | --- |
| Core primitives and schedule | `GameBossPhaseColorGet`, `GameBossLinearBulletSpawn`, `GameBossBladeBulletSpawn`, `GameBossLinearFanSpawn`, `GameBossPatternAngleVarianceGet`, `GameBossPhasePatternFire`, `GameBossPhaseAttackStep` | Creates bullet instances, consumes one `random_range` jitter for selected shot kinds, toggles boss clockwise state, schedules redirects | dispatcher/geometry/variance/interpreter tests; gap: exact RNG/bullet event trace | retain in `scr_boss_patterns` or rename to `scr_boss_pattern_core` only with explicit benefit | characterize |
| Character and redistributed families | `GameBossMiraPatternFire`, `GameBossSaltwindPatternFire`, `GameBossKelpPatternFire`, `GameBossShalmiiPatternFire`, `GameBossAishaPatternFire`, `GameBossSistersPatternFire`, `GameBossAsterPatternFire`, `GameBossBloodtidePatternFire`, `GameBossCaeliaPatternFire` | Family-specific bullet geometry through core primitives | representative geometry and shot-kind coverage; few direct family tests | one named family resource per bounded move; preserve function names | characterize |
| Route finales | `GameBossFinalePatternFire` plus rose/chakram generic cases currently inside the dispatcher | Route-specific bullet geometry and boss state | route plan tests and visual tour; gap: per-family event/RNG contract | `scr_boss_patterns_finale` after characterization | characterize |

## Secondary owners

| Current owner | Why it is not selected now | Future trigger |
| --- | --- | --- |
| `scr_input_helpers` | Four subareas exist, but they form one coherent input pipeline from persisted bindings to Begin Step verb state | Re-audit only if options/remap work repeatedly requires loading device polling internals, or a bounded input-owner task is approved |
| `scr_audio_helpers` | Broad caller reach is mediated by a clear semantic API; state, routing, preview, and SFX remain cohesive | Re-audit if preview ownership or room synchronization becomes independently unstable |
| `scr_stage_3d` | Large specialized renderer with only scene-manager and test callers; splitting GPU/path/config code may increase coupling | Re-audit for a bounded renderer-owner change with visual validation |
| `obj_UI_gameplay/Draw_64.gml` | It is a draw orchestrator; shared UI and HUD extraction should reduce its burden first | Re-audit after `scr_ui_ornate` and `scr_gameplay_hud` exist |
| `obj_player/Step_0.gml` and `obj_enemy_variant/Step_0.gml` | High reasoning density is caused by domain calls and ordering, not raw size; object events should remain orchestration-focused | Re-audit after weapon/survival/wave/projectile modules exist and characterization proves a further cohesive move |

// Keep the physical camera object synchronized with the latest scene state.
if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

// The data-driven stage director owns wave spawning; the legacy timeline stays idle.
timeline_running = false;

// Freeze stage logic during dialogue and continue prompts.
if (GameGameplayIsFrozen()) {
    exit;
}

GameRankStep();

// Apply berserk-wide bullet cancellation and meter drain side effects.
if (global.game_runtime.is_berserk && global.game_runtime.meter == METER_MAX) {
    GameBulletsCancelAll(true);
}

if (GamePlayerBerserkDrainStep()) {
    GameBulletsCancelAll(false);
}

GameStageNoticeStep();

if (scene_state.mode == "stage_clear") {
    if (scene_state.stage_clear_timer > 0) {
        scene_state.stage_clear_timer -= 1;
    }

    if (scene_state.stage_clear_timer <= 0) {
        if (GameRunIsPractice()) {
            GamePracticeReturnToTitle();
            exit;
        }

        if (GameStageIsFinal()) {
            room_goto(rm_ending);
            exit;
        }

        GameSceneNextStageBegin(scene_state);
        GameStageMusicSync();

        var _player_next = instance_find(obj_player, 0);
        if (_player_next != noone) {
            var _next_spawn = GameScenePlayerRespawnPositionGet(scene_state.target_x, scene_state.camera_y);
            _player_next.x = _next_spawn.x;
            _player_next.y = _next_spawn.y;
            _player_next.player_state.invuln_timer = max(_player_next.player_state.invuln_timer, INVULN_TIME div 2);
            _player_next.sprite_index = GamePlayerShipSpriteGet(GameRunShipIdGet());
        }
    }

    if (instance_exists(camera_id)) {
        camera_id.x = scene_state.target_x;
        camera_id.y = scene_state.camera_y;
    }

    exit;
}

GameStageDirectorStep(scene_state);

// Advance the scrolling section, then queue the boss intro once the full stage has passed.
var _scene_action = GameSceneStageAdvance(scene_state);
if (_scene_action == "boss_intro") {
    timeline_running = false;
    GameSceneCombatClear();

    if (GamePracticeWavesOnly()) {
        scene_state.mode = "stage_clear";
        scene_state.stage_clear_timer = STAGE_CLEAR_DELAY_FRAMES;
        global.game_runtime.stage_complete = true;
        GameStageClearSoundPlay();
    } else if (GameStageIsFinal() && !GameRunIsPractice()) {
        GameStoryQueueRequest(GameFinalBossStoryFileGet());
    }
}

if (scene_state.mode == "boss_intro" && !global.game_runtime.signals.dialogue && !scene_state.boss_spawned) {
    var _boss_spawn = GameSceneBossSpawnPositionGet(scene_state.target_x, scene_state.camera_y);
    instance_create_layer(_boss_spawn.x, _boss_spawn.y, "Instances", obj_boss_sunset);
    GameBossSpawnSoundPlay();
    scene_state.boss_spawned = true;
    scene_state.mode = "boss_fight";
}

if (scene_state.boss_defeated) {
    scene_state.boss_defeated = false;
    scene_state.mode = "stage_clear";
    scene_state.stage_clear_timer = STAGE_CLEAR_DELAY_FRAMES;
    GameRankEventApply(2);
    GameStageClearSoundPlay();
    GameSceneCombatClear();
}

if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

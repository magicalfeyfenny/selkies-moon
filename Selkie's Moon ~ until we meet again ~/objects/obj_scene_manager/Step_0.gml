// Keep the physical camera object synchronized with the latest scene state.
if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

// The native 3D route is presentation-only and keeps advancing through boss
// dialogue, phase transitions, and combat while the 2D playfield stays anchored.
GameSceneBackgroundStep(scene_state);

// The data-driven stage director owns wave spawning; the legacy timeline stays idle.
timeline_running = false;

// Freeze stage logic during dialogue and continue prompts.
if (GameGameplayIsFrozen()) {
    exit;
}

GameRankStep();

// Activation performs the one full-screen cancel; the scene only owns drain.
GamePlayerBerserkDrainStep();

GameStageNoticeStep();

// A character-boss outro holds the scene here until its queued dialogue closes.
if (scene_state.mode == "boss_outro") {
    GameSceneStageClearBegin(scene_state);
}

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
        GameSceneStageClearBegin(scene_state);
    } else if (!GameRunIsPractice()) {
        var _character_intro_file = GameCharacterBossStoryFileGet(GameCurrentStageGet(), false);

        if (_character_intro_file != "") {
            GameStoryQueueRequest(_character_intro_file);
        } else if (GameStageIsFinal()) {
            GameStoryQueueRequest(GameFinalBossStoryFileGet());
        }
    }
} else if (_scene_action == "stage_complete") {
    // Chapters without a guardian end cleanly at their last enemy gauntlet.
    // Their former abstract-boss patterns now belong to elite enemies.
    GameSceneCombatClear();
    GameSceneStageClearBegin(scene_state);
}

if (scene_state.mode == "boss_intro" && !global.game_runtime.signals.dialogue && !scene_state.boss_spawned) {
    var _boss_spawn = GameSceneBossSpawnPositionGet(scene_state.target_x, scene_state.camera_y);
    if (GameStageIsDualBoss()) {
        var _mira_boss = instance_create_layer(_boss_spawn.x - 52, _boss_spawn.y - 6,
            "Instances", obj_boss_sunset);
        var _aisha_boss = instance_create_layer(_boss_spawn.x + 52, _boss_spawn.y + 14,
            "Instances", obj_boss_sunset);
        GameBossDualConfigure(_mira_boss, "mira");
        GameBossDualConfigure(_aisha_boss, "aisha");
    } else {
        instance_create_layer(_boss_spawn.x, _boss_spawn.y, "Instances", obj_boss_sunset);
    }
    GameBossSpawnSoundPlay();
    scene_state.boss_spawned = true;
    scene_state.mode = "boss_fight";
}

if (scene_state.boss_defeated) {
    scene_state.boss_defeated = false;
    GameRankEventApply(2);
    GameSceneCombatClear();

    var _character_outro_file = GameRunIsPractice()
        ? ""
        : GameCharacterBossStoryFileGet(GameCurrentStageGet(), true);

    if (_character_outro_file != "" && GameStoryQueueRequest(_character_outro_file)) {
        scene_state.mode = "boss_outro";
    } else {
        GameSceneStageClearBegin(scene_state);
    }
}

if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

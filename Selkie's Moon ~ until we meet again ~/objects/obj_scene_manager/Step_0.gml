// Keep the physical camera object synchronized with the latest scene state.
if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

// Freeze stage logic during dialogue and continue prompts.
if (GameGameplayIsFrozen()) {
    exit;
}

// Apply berserk-wide bullet cancellation and meter drain side effects.
if (global.game_runtime.is_berserk && global.game_runtime.meter == METER_MAX) {
    GameBulletsCancelAll(true);
}

if (GamePlayerBerserkDrainStep()) {
    GameBulletsCancelAll(false);
}

// Advance the scrolling section, then queue the boss intro once the full stage has passed.
var _scene_action = GameSceneStageAdvance(scene_state);
if (_scene_action == "boss_intro") {
    GameSceneCombatClear();
    GameStoryQueueRequest("boss_intro_story.json");
}

if (scene_state.mode == "boss_intro" && !global.game_runtime.signals.dialogue && !scene_state.boss_spawned) {
    var _boss_spawn = GameSceneBossSpawnPositionGet(scene_state.target_x, scene_state.camera_y);
    instance_create_layer(_boss_spawn.x, _boss_spawn.y, "Instances", obj_boss_sunset);
    scene_state.boss_spawned = true;
    scene_state.mode = "boss_fight";
}

if (scene_state.boss_defeated) {
    room_goto(rm_ending);
    exit;
}

if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

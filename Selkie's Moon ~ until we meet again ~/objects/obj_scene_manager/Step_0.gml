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

// Advance the stage scroll and hand off to the ending room when the stage is over.
var _next_room = GameSceneStageAdvance(scene_state);
if (_next_room != -1) {
    room_goto(_next_room);
    exit;
}

if (instance_exists(camera_id)) {
    camera_id.x = scene_state.target_x;
    camera_id.y = scene_state.camera_y;
}

// Keep input polling centralized in one persistent manager instance.
if (instance_number(obj_input_manager) > 1) {
    instance_destroy();
    exit;
}

// Create the shared input state and populate it once immediately for frame-zero consumers.
global.game_input = GameInputStateCreate();
GameInputUpdate(global.game_input);

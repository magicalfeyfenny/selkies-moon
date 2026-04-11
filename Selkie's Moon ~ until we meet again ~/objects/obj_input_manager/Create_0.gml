if (instance_number(obj_input_manager) > 1) {
    instance_destroy();
    exit;
}

global.game_input = GameInputStateCreate();
GameInputUpdate(global.game_input);

// The persistent bootstrap owns the low-resolution GUI composition surface.
ui_surface = -1;
ui_surface_targeted = false;

// Keep exactly one app bootstrap instance alive across room loads.
if (instance_number(obj_app_init) > 1) {
    instance_destroy();
    exit;
}

// Boot save data, config, and runtime globals before other systems depend on them.
GameInitialize();
GameAudioStateEnsure();

// Ensure the shared input manager exists before UI or gameplay objects begin polling input.
if (!instance_exists(obj_input_manager)) {
    instance_create_layer(0, 0, "Instances", obj_input_manager);
}

// Sync persistent music state immediately so a continuing session matches the current room.
GameStageMusicSync();

test_quit_frames = 0;
test_quit_timeout_frames = 1800;

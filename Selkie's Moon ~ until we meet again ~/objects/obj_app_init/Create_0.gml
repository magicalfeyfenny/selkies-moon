if (instance_number(obj_app_init) > 1) {
    instance_destroy();
    exit;
}

GameInitialize();

if (!instance_exists(obj_input_manager)) {
    instance_create_layer(0, 0, "Instances", obj_input_manager);
}

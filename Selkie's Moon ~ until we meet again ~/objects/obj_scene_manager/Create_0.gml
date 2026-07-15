// Keep gameplay orchestration to one room-local instance.
if (instance_number(obj_scene_manager) > 1) {
    instance_destroy();
    exit;
}

depth = 10000;

// The background model is loaded lazily for the current stage and replaced as
// chapters change. Keeping it here guarantees it draws before every 2D actor.
stage3d_vertex_format = GameStage3DVertexFormatCreate();
stage3d_uniforms = GameStage3DUniformsCreate();
stage3d_stage = -1;
stage3d_buffer = -1;
stage3d_config = undefined;

// Initialize the run state and reusable stage scroll state.
GameRunStartInitialize();
scene_state = GameSceneStateCreate();
GamePracticeSceneStateApply(scene_state);

timeline_index = tml_stage;
timeline_running = false;
timeline_position = 0;
timeline_speed = 0;

// Spawn the camera, player, and gameplay UI from one central bootstrap point.
var _camera = instance_find(obj_camera, 0);
if (_camera == noone) {
    _camera = instance_create_layer(scene_state.camera_x, scene_state.camera_y, "Instances", obj_camera);
} else {
    _camera.x = scene_state.camera_x;
    _camera.y = scene_state.camera_y;
}
camera_id = _camera;

var _player = instance_find(obj_player, 0);
if (_player == noone) {
    _player = instance_create_layer(scene_state.camera_x, scene_state.camera_y, "Instances", obj_player);
}
player_id = _player;

var _spawn = GameScenePlayerRespawnPositionGet(scene_state.camera_x, scene_state.camera_y);
_player.x = _spawn.x;
_player.y = _spawn.y;
_player.sprite_index = GamePlayerShipSpriteGet(GameRunShipIdGet());
GamePlayerRespawnStateApply(_player.player_state);

if (!instance_exists(obj_UI_gameplay)) {
    instance_create_layer(0, 0, "Instances", obj_UI_gameplay);
}

if (!instance_exists(obj_UI_menu)) {
    instance_create_layer(0, 0, "Instances", obj_UI_menu);
}

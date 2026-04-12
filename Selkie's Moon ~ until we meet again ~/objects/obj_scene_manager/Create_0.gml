// Keep gameplay orchestration to one room-local instance.
if (instance_number(obj_scene_manager) > 1) {
    instance_destroy();
    exit;
}

// Initialize the run state, stage scroll state, and placeholder enemy timeline.
GameRunStartInitialize();
scene_state = GameSceneStateCreate();

timeline_index = tml_stage;
timeline_running = true;
timeline_position = 0;
timeline_speed = 1;

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
GamePlayerRespawnStateApply(_player.player_state);

if (!instance_exists(obj_UI_gameplay)) {
    instance_create_layer(0, 0, "Instances", obj_UI_gameplay);
}

// Spawn one turret and one bee so rm_game always has live targets and enemy fire sources.
if (!instance_exists(obj_enemy_turret)) {
    var _enemy_spawn = GameSceneTurretSpawnPositionGet(scene_state.camera_x, scene_state.camera_y);
    instance_create_layer(_enemy_spawn.x, _enemy_spawn.y, "Instances", obj_enemy_turret);
}

if (!instance_exists(obj_enemy_bee)) {
    var _bee_spawn = GameSceneBeeSpawnPositionGet(scene_state.camera_x, scene_state.camera_y);
    instance_create_layer(_bee_spawn.x, _bee_spawn.y, "Instances", obj_enemy_bee);
}

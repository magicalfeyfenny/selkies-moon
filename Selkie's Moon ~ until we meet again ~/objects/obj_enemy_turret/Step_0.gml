// Run the parent enemy step first so defeat, freeze, and movement stay centralized.
event_inherited();

// Remove the turret enemy once it drifts well below the camera.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone && y > _camera.y + GAME_VIEW_HALF_HEIGHT + 64) {
    instance_destroy();
    exit;
}

// Fire one bead directly at the player whenever the local timer completes.
fire_timer += 1;

if (fire_timer >= fire_interval) {
    fire_timer = 0;

    var _player = instance_find(obj_player, 0);
    if (_player != noone) {
        var _shot = GameTurretShotSpecCreate(x, y + 12, _player.x, _player.y);
        var _bullet = instance_create_layer(_shot.x, _shot.y, "Instances", _shot.object_index);
        _bullet.move_direction = _shot.direction;
        _bullet.move_speed = _shot.speed;
    }
}

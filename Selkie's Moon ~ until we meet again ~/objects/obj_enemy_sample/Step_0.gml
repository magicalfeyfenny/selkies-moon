// Resolve defeat before the enemy can fire or linger in the room.
if (health <= 0) {
    global.game_runtime.score += points;
    instance_destroy();
    exit;
}

// Suspend fire and motion while dialogue or continue overlays are active.
if (GameGameplayIsFrozen()) {
    exit;
}

// Fire one bead directly at the player whenever the local timer completes.
fire_timer += 1;

if (fire_timer >= fire_interval) {
    fire_timer = 0;

    var _player = instance_find(obj_player, 0);
    if (_player != noone) {
        var _shot = GameSampleEnemyShotSpecCreate(x, y + 12, _player.x, _player.y);
        var _bullet = instance_create_layer(_shot.x, _shot.y, "Instances", _shot.object_index);
        _bullet.move_direction = _shot.direction;
        _bullet.move_speed = _shot.speed;
    }
}

// Keep the enemy bound to the stage until it drifts well below the camera.
if (move_speed != 0) {
    x += lengthdir_x(move_speed, move_direction);
    y += lengthdir_y(move_speed, move_direction);
}

var _camera = instance_find(obj_camera, 0);
if (_camera != noone && y > _camera.y + GAME_VIEW_HALF_HEIGHT + 64) {
    instance_destroy();
}

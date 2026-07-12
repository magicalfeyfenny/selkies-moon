// Run the parent enemy step first so defeat, freeze, and movement stay centralized.
event_inherited();

if (combat_step_blocked) {
    exit;
}

// Remove the bee once it drifts far outside the active combat space.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    instance_destroy();
    exit;
}

// Steer toward the player for the next movement tick and face along that travel direction.
var _player = instance_find(obj_player, 0);
if (_player != noone) {
    move_direction = point_direction(x, y, _player.x, _player.y);
}

image_angle = move_direction;

// Fire one three-speed line of diamond shots toward the player every interval.
fire_timer += 1;

if (fire_timer >= GameRankFireIntervalGet(fire_interval, 4)) {
    fire_timer = 0;

    if (_player != noone) {
        var _shots = GameBeeShotSpawnSpecsCreate(x, y, _player.x, _player.y);

        for (var i = 0; i < array_length(_shots); i++) {
            var _shot = _shots[i];
            var _bullet = instance_create_layer(_shot.x, _shot.y, "Instances", _shot.object_index);
            _bullet.move_direction = _shot.direction;
            _bullet.move_speed = _shot.speed;
        }

        GameEnemyFireSoundPlay();
    }
}

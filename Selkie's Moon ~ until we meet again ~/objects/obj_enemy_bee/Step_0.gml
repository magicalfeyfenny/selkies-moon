// Run the parent enemy step first so defeat, freeze, and movement stay centralized.
event_inherited();

if (combat_step_blocked) {
    exit;
}

// Bees leave promptly once they pass below the visible playfield. This keeps
// completed fly-throughs from accumulating behind the player and firing from
// an unreadable offscreen stack.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (y > _camera.y + PLAYFIELD_HALF_HEIGHT + 80
        || abs(x - _camera.x) > PLAYFIELD_HALF_WIDTH + 120)) {
    instance_destroy();
    exit;
}

// Pursue only while approaching from above. Once a bee reaches or passes the
// player, it commits downward and never turns back to hover behind the ship.
// With no player, it follows the same downward cleanup path.
var _player = instance_find(obj_player, 0);
if (_player == noone) {
    flyaway_committed = true;
    move_direction = 270;
} else if (!flyaway_committed && y < _player.y - max(2, move_speed)) {
    move_direction = point_direction(x, y, _player.x, _player.y);
} else {
    flyaway_committed = true;
    move_direction = 270;
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

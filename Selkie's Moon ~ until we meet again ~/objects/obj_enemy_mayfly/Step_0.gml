// Run the parent enemy step first so defeat and pause behavior stay centralized.
event_inherited();

if (combat_step_blocked) {
    exit;
}

// Keep the mayfly anchored in the visible area while it drifts in a slow infinity pattern.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    if (anchor_offset_y < anchor_target_offset_y) {
        anchor_offset_y = min(anchor_target_offset_y, anchor_offset_y + MAYFLY_DROP_SPEED);
    } else if (anchor_offset_y > anchor_target_offset_y) {
        anchor_offset_y = max(anchor_target_offset_y, anchor_offset_y - MAYFLY_DROP_SPEED);
    }

    var _offset = GameMayflyInfinityOffsetCreate(float_phase);
    x = _camera.x + anchor_offset_x + _offset.x;
    y = _camera.y + anchor_offset_y + _offset.y;
}

float_phase = (float_phase + MAYFLY_FLOAT_RATE) mod 360;

// Emit alternating clockwise and counterclockwise spiral bursts on the requested cadence.
var _burst = GameMayflyBurstStateCreate(fire_timer, clockwise_first);
if (_burst.fire) {
    var _shots = GameMayflyShotSpawnSpecsCreate(x, y, _burst.clockwise);

    for (var i = 0; i < array_length(_shots); i++) {
        var _shot = _shots[i];
        var _bullet = instance_create_layer(_shot.x, _shot.y, "Instances", _shot.object_index);
        _bullet.spiral_origin_x = _shot.x;
        _bullet.spiral_origin_y = _shot.y;
        _bullet.spiral_angle = _shot.spiral_angle;
        _bullet.spiral_direction = _shot.spiral_direction;
        _bullet.spiral_turn_speed = _shot.spiral_turn_speed;
        _bullet.spiral_radial_speed = _shot.spiral_radial_speed;
        _bullet.image_angle = _shot.spiral_angle;
    }

    GameEnemyFireSoundPlay();
}

fire_timer += 1;
if (fire_timer >= GameRankFireIntervalGet(MAYFLY_PATTERN_PERIOD, 12)) {
    fire_timer = 0;
    clockwise_first = !clockwise_first;
}

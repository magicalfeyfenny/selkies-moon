// Freeze with combat, drift normally, and magnetize into a living player.
if (GameGameplayIsFrozen()) {
    exit;
}

pulse = (pulse + 6) mod 360;

var _player = instance_find(obj_player, 0);
if (_player != noone && !_player.player_state.hit) {
    var _distance = point_distance(x, y, _player.x, _player.y);

    if (_distance <= magnet_radius) {
        var _direction = point_direction(x, y, _player.x, _player.y);
        x += lengthdir_x(4.2, _direction);
        y += lengthdir_y(4.2, _direction);
    } else {
        y += move_speed;
    }

    if (_distance <= collect_radius) {
        GamePowerupRewardApply(powerup_type);
        GamePowerupCollectSoundPlay();
        instance_destroy();
        exit;
    }
} else {
    y += move_speed;
}

var _camera = instance_find(obj_camera, 0);
// Cull abandoned pickups well outside the active camera.
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    instance_destroy();
}

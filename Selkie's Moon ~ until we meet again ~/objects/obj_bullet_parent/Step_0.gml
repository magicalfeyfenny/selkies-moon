// Bombs cancel every active bullet before any normal bullet processing.
if (GamePlayerBombActiveGet()) {
    GameBulletCancelMark(id, global.game_runtime.is_berserk);
}

// Resolve delayed cancellation into an actual medal drop before normal motion.
if (cancelled) {
    var _medal = instance_create_layer(x, y, "Instances", obj_medal);
    _medal.score_value = medal_score_value;
    _medal.meter_value = medal_meter_value;
    instance_destroy();
    exit;
}

// Freeze bullet motion while continue and dialogue overlays are active.
if (GameGameplayIsFrozen()) {
    exit;
}

// Advance the bullet and cull it once it leaves the active combat space.
x += lengthdir_x(move_speed, move_direction);
y += lengthdir_y(move_speed, move_direction);

var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    instance_destroy();
}

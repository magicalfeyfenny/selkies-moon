// Tell overriding child Steps whether inherited combat handling ended this frame.
combat_step_blocked = false;

// A real pause freezes cancellation, conversion, and motion atomically.
if (GameGameplayIsFrozen()) {
    combat_step_blocked = true;
    exit;
}

bullet_age += 1;

// Bombs cancel every active bullet before any normal bullet processing.
if (GamePlayerBombActiveGet()) {
    GameBulletCancelMark(id, global.game_runtime.is_berserk);
}

// Resolve delayed cancellation into an actual medal drop before normal motion.
if (cancelled) {
    combat_step_blocked = true;
    var _medal = instance_create_layer(x, y, "Instances", obj_medal);
    _medal.score_value = medal_score_value;
    _medal.meter_value = medal_meter_value;
    instance_destroy();
    exit;
}

// Advance the bullet and cull it once it leaves the active combat space.
x += lengthdir_x(move_speed * rank_speed_scale, move_direction);
y += lengthdir_y(move_speed * rank_speed_scale, move_direction);
image_angle = move_direction;

var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    combat_step_blocked = true;
    instance_destroy();
    exit;
}

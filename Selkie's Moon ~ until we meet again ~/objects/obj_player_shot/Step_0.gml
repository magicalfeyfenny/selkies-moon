// Freeze shot movement while gameplay is paused by dialogue or the continue prompt.
if (GameGameplayIsFrozen()) {
    exit;
}

// Advance the shot manually so stage freezes stop it cleanly.
x += lengthdir_x(move_speed, move_direction);
y += lengthdir_y(move_speed, move_direction);

// Damage the first enemy or boss placeholder intersected by this shot.
for (var i = instance_number(obj_enemy_parent) - 1; i >= 0; i--) {
    var _enemy = instance_find(obj_enemy_parent, i);

    if (!variable_instance_exists(_enemy, "hit_radius")) {
        continue;
    }

    if (point_distance(x, y, _enemy.x, _enemy.y) <= _enemy.hit_radius) {
        _enemy.health -= damage;
        instance_destroy();
        exit;
    }
}

for (var i = instance_number(obj_boss_parent) - 1; i >= 0; i--) {
    var _boss = instance_find(obj_boss_parent, i);

    if (!variable_instance_exists(_boss, "hit_radius")) {
        continue;
    }

    if (point_distance(x, y, _boss.x, _boss.y) <= _boss.hit_radius) {
        _boss.health -= damage;
        instance_destroy();
        exit;
    }
}

// Destroy the shot once it has traveled far beyond the current camera view.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    instance_destroy();
}

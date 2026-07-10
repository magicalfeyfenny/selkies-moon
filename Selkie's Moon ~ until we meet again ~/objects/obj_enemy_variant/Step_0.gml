// Run shared defeat, freeze, and movement first.
event_inherited();

var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    instance_destroy();
    exit;
}

age += 1;
fire_timer += 1;

var _player = instance_find(obj_player, 0);
var _fired = false;

switch (variant_kind) {
    case ENEMY_VARIANT_MOTH:
        x += dsin(age * 7 + wave_phase) * 0.9;
        image_angle = 270 + (dsin(age * 9 + wave_phase) * 18);

        if (fire_timer >= fire_interval && _player != noone) {
            fire_timer = 0;
            var _base = point_direction(x, y, _player.x, _player.y);

            for (var i = -2; i <= 2; i++) {
                GameEnemyBulletLinearSpawn(x, y, _base + (i * 12), 2.3 + (stage_rank * 0.06), obj_bullet_diamond);
            }

            _fired = true;
        }
        break;

    case ENEMY_VARIANT_KELP:
        image_angle = age * 2;

        if (fire_timer >= fire_interval) {
            fire_timer = 0;
            var _count = 8 + (stage_rank >= 6 ? 2 : 0);

            for (var k = 0; k < _count; k++) {
                GameEnemyBulletLinearSpawn(x, y, (360 / _count) * k + (age mod 45), 1.7 + (stage_rank * 0.05), obj_bullet_bead);
            }

            _fired = true;
        }
        break;

    case ENEMY_VARIANT_WISP:
        if (_camera != noone) {
            x = _camera.x + anchor_offset_x + (dsin(age * 3 + wave_phase) * 34);
            y = _camera.y + anchor_offset_y + (dsin(age * 6 + wave_phase) * 12);
        }

        image_angle = age * 4;

        if (fire_timer >= fire_interval && _player != noone) {
            fire_timer = 0;
            var _aim = point_direction(x, y, _player.x, _player.y);
            GameEnemyBulletLinearSpawn(x, y, _aim - 14, 2.55 + (stage_rank * 0.05), obj_bullet_bead);
            GameEnemyBulletLinearSpawn(x, y, _aim + 14, 2.55 + (stage_rank * 0.05), obj_bullet_bead);
            _fired = true;
        }
        break;

    case ENEMY_VARIANT_NEEDLE:
        image_angle = move_direction;

        if (fire_timer >= fire_interval && _player != noone) {
            fire_timer = 0;
            var _needle_aim = point_direction(x, y, _player.x, _player.y);
            GameEnemyBulletLinearSpawn(x, y, _needle_aim, 3.2 + (stage_rank * 0.05), obj_bullet_diamond);
            _fired = true;
        }
        break;

    case ENEMY_VARIANT_MIRROR:
        x += dsin(age * 5 + wave_phase) * 1.15;
        image_angle = age * 3;

        if (fire_timer >= fire_interval) {
            fire_timer = 0;
            for (var m = 0; m < 6; m++) {
                GameEnemyBulletLinearSpawn(x, y, (m * 60) + (age * 3), 2.0 + (stage_rank * 0.04), obj_bullet_bead);
            }
            _fired = true;
        }
        break;
}

if (_fired) {
    GameEnemyFireSoundPlay();
}

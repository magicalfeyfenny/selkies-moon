// Run shared defeat, freeze, and initial linear movement first.
event_inherited();

if (combat_step_blocked) {
    exit;
}

var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    var _field = GameSceneFieldRectGet(_camera.x, _camera.y);
    if (x < _field.left - 180 || x > _field.right + 180
        || y > _field.bottom + 120 || y < _field.top - 440) {
        instance_destroy();
        exit;
    }
}

age += 1;
fire_timer += 1;

var _player = instance_find(obj_player, 0);

// Each role has a readable traversal contract. Chasers get exactly one pass:
// once the player is absent or behind them, they commit downward and leave.
switch (variant_role) {
    case "chaser":
        if (_player == noone || y >= _player.y - 8) {
            flyaway_committed = true;
        }

        if (!flyaway_committed && _player != noone) {
            move_direction = point_direction(x, y, _player.x, _player.y);
        } else {
            move_direction = 270;
        }

        move_speed = 1.05 + (stage_rank * 0.04);
        image_angle = move_direction;
        break;

    case "anchor":
        move_speed = 0;
        if (_camera != noone) {
            var _anchor_entry = min(112, age * 0.72);
            x = _camera.x + anchor_offset_x + (dsin(age * 2.5 + wave_phase) * 18);
            y = _camera.y + anchor_offset_y + _anchor_entry;
        }
        image_angle = age * 1.4;
        break;

    case "dancer":
        move_speed = 0;
        if (_camera != noone) {
            var _dance_entry = min(138, age * 0.92);
            x = _camera.x + anchor_offset_x + (dsin(age * 4.6 + wave_phase) * 54);
            y = _camera.y + anchor_offset_y + _dance_entry + (dsin(age * 2.1 + wave_phase) * 13);
        }
        image_angle = 270 + (dsin(age * 5.5 + wave_phase) * 22);
        break;

    case "lancer":
        x += dsin(age * 6.5 + wave_phase) * 0.34;
        image_angle = move_direction;
        break;
}

var _can_fire = _camera == noone;
if (_camera != noone) {
    var _fire_field = GameSceneFieldRectGet(_camera.x, _camera.y);
    _can_fire = y >= _fire_field.top - 12 && y <= _fire_field.bottom + 16;
}

if (!_can_fire || fire_timer < GameRankFireIntervalGet(fire_interval, 12)) {
    exit;
}

fire_timer = 0;
var _fired = false;

// Aimed fans inherit the removed Tideglass, Saltwind, dealer, chaos,
// Bloodtide, and thorn-arc pattern families.
switch (pattern_kind) {
    case "tideglass_fan":
    case "saltwind_gale":
    case "mira_dealer_fan":
    case "aisha_chaos_shards":
    case "bloodtide_hunt":
    case "rose_thorn_arc":
        if (_player != noone) {
            var _fan_aim = point_direction(x, y, _player.x, _player.y);
            var _fan_count = (pattern_kind == "saltwind_gale") ? 7 : 5;
            var _fan_half = (_fan_count - 1) * 0.5;
            for (var _fan_index = 0; _fan_index < _fan_count; _fan_index++) {
                var _fan_offset = (_fan_index - _fan_half) * 13;
                var _fan_bullet = GameStageEnemyBulletSpawn(
                    variant_kind, x, y, _fan_aim + _fan_offset,
                    2.35 + (stage_rank * 0.055) + (abs(_fan_offset) * 0.006),
                    obj_bullet_diamond);
            }
            _fired = true;
        }
        break;

    // Compact spirals keep the removed Memory Core motion vocabulary on
    // ordinary enemies without preserving those enemies' old identities.
    case "tideglass_spiral":
    case "aster_ribbon_loop":
    case "saltwind_spindrift":
    case "caelia_astrolabe":
    case "rose_petal_spiral":
    case "chakram_orbit":
        var _spiral_count = (pattern_kind == "chakram_orbit") ? 8 : 6;
        for (var _spiral_index = 0; _spiral_index < _spiral_count; _spiral_index++) {
            var _spiral_bullet = instance_create_layer(x, y, "Instances", obj_bullet_blade);
            _spiral_bullet.spiral_origin_x = x;
            _spiral_bullet.spiral_origin_y = y;
            _spiral_bullet.spiral_angle = (_spiral_index * (360 / _spiral_count)) + (age mod 60);
            _spiral_bullet.spiral_turn_speed = 5.5 + (stage_rank * 0.12);
            _spiral_bullet.spiral_radial_speed = 1.12 + (stage_rank * 0.035);
            _spiral_bullet.spiral_direction = ((_spiral_index + slot_index) mod 2 == 0) ? 1 : -1;
            GameStageEnemyBulletDecorate(_spiral_bullet, variant_kind);
        }
        _fired = true;
        break;

    // Downward lane attacks preserve the shockwave, kelp-wall, and
    // constellation-grid ideas with an obvious navigable gap.
    case "shalmii_shockwave":
    case "kelp_wall":
    case "caelia_constellation":
        var _wall_gap = (age div max(1, fire_interval)) mod 5;
        for (var _wall_index = 0; _wall_index < 5; _wall_index++) {
            if (_wall_index == _wall_gap) {
                continue;
            }
            GameStageEnemyBulletSpawn(
                variant_kind, x + ((_wall_index - 2) * 18), y,
                270 + ((_wall_index - 2) * 2), 2.2 + (stage_rank * 0.05),
                obj_bullet_bead);
        }
        _fired = true;
        break;

    case "shalmii_hammerfall":
        if (_player != noone) {
            var _hammer_aim = point_direction(x, y, _player.x, _player.y);
            for (var _hammer_index = -1; _hammer_index <= 1; _hammer_index++) {
                GameStageEnemyBulletSpawn(
                    variant_kind, x, y, _hammer_aim + (_hammer_index * 9),
                    3.15 + (stage_rank * 0.06), obj_bullet_diamond);
            }
            _fired = true;
        }
        break;

    case "mira_four_suits":
        for (var _suit_index = 0; _suit_index < 8; _suit_index++) {
            var _suit_object = ((_suit_index mod 2) == 0) ? obj_bullet_diamond : obj_bullet_bead;
            GameStageEnemyBulletSpawn(
                variant_kind, x, y, (_suit_index * 45) + (age mod 45),
                1.95 + (stage_rank * 0.045), _suit_object);
        }
        _fired = true;
        break;

    case "aisha_order_circle":
    case "bloodtide_pulse":
    case "rose_bloom":
        var _ring_count = 10;
        var _ring_gap = (age div max(1, fire_interval)) mod _ring_count;
        for (var _ring_index = 0; _ring_index < _ring_count; _ring_index++) {
            if (_ring_index == _ring_gap || _ring_index == ((_ring_gap + 1) mod _ring_count)) {
                continue;
            }
            GameStageEnemyBulletSpawn(
                variant_kind, x, y, (_ring_index * (360 / _ring_count)) + (age mod 36),
                1.75 + (stage_rank * 0.04), obj_bullet_bead);
        }
        _fired = true;
        break;
}

if (_fired) {
    GameEnemyFireSoundPlay();
}

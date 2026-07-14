// Boss phase descriptors live in scr_gameplay_helpers. This module is the
// runtime interpreter that turns those data-only descriptors into bullets.

/// @func GameBossPhaseColorGet(attack_theme)
/// Returns the primary bullet tint for a route-specific attack theme.
function GameBossPhaseColorGet(_attack_theme) {
    switch (_attack_theme) {
        case "tideglass":
            return make_color_rgb(96, 224, 255);

        case "poker":
            return make_color_rgb(58, 174, 112);

        case "saltwind":
            return make_color_rgb(140, 238, 255);

        case "kelp":
            return make_color_rgb(94, 218, 132);

        case "rune":
            return make_color_rgb(236, 76, 166);

        case "desire":
            return make_color_rgb(106, 208, 255);

        case "ribbon":
            return make_color_rgb(194, 142, 255);

        case "bloodtide":
            return make_color_rgb(255, 92, 118);

        case "astral":
            return make_color_rgb(142, 126, 255);

        case "rose":
            return make_color_rgb(255, 112, 166);

        case "chakram":
            return make_color_rgb(190, 120, 255);
    }

    return c_white;
}

/// @func GameBossLinearBulletSpawn(object_index, x, y, direction, speed, color)
/// Spawns and colors one linearly moving boss bullet.
function GameBossLinearBulletSpawn(_object_index, _x, _y, _direction, _speed, _color = c_white) {
    var _bullet = GameEnemyBulletLinearSpawn(_x, _y, _direction, _speed, _object_index);
    _bullet.image_blend = _color;
    return _bullet;
}

/// @func GameBossBladeBulletSpawn(x, y, angle, clockwise, turn_speed, radial_speed, color, offset)
/// Spawns one spiral blade around the supplied origin.
function GameBossBladeBulletSpawn(_x, _y, _angle, _clockwise, _turn_speed, _radial_speed,
    _color = c_white, _offset = 0) {
    var _spawn_x = _x + lengthdir_x(_offset, _angle + 90);
    var _spawn_y = _y + lengthdir_y(_offset, _angle + 90);
    var _blade = instance_create_layer(_spawn_x, _spawn_y, "Instances", obj_bullet_blade);

    _blade.spiral_origin_x = _x;
    _blade.spiral_origin_y = _y;
    _blade.spiral_angle = _angle;
    _blade.spiral_direction = _clockwise ? -1 : 1;
    _blade.spiral_turn_speed = _turn_speed;
    _blade.spiral_radial_speed = _radial_speed;
    _blade.spiral_radius = max(0, _offset);
    _blade.image_angle = _angle;
    _blade.image_blend = _color;
    return _blade;
}

/// @func GameBossLinearFanSpawn(object_index, x, y, center, spread, count, speed, color)
/// Spawns a centered linear fan and returns its bullet count.
function GameBossLinearFanSpawn(_object_index, _x, _y, _center, _spread, _count, _speed,
    _color = c_white) {
    _count = max(1, _count);
    var _step = (_count > 1) ? (_spread / (_count - 1)) : 0;
    var _start = _center - (_spread * 0.5);

    for (var i = 0; i < _count; i++) {
        GameBossLinearBulletSpawn(_object_index, _x, _y, _start + (i * _step), _speed, _color);
    }

    return _count;
}

/// @func GameBossMiraPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Deals Mira's four-suit formations and paired card fans. Red and gold
/// accents make the suit groups readable without requiring portrait-bound art.
function GameBossMiraPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;
    var _red = make_color_rgb(255, 82, 104);
    var _gold = make_color_rgb(255, 214, 104);

    switch (_phase.shot_kind) {
        case "mira_four_suits":
            var _suit_count = 4;
            var _cards_per_suit = max(2, ceil(_phase.burst_count / _suit_count));
            var _suit_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var suit = 0; suit < _suit_count; suit++) {
                var _suit_center = _suit_base + (suit * 90);
                var _suit_color = ((suit mod 2) == 0) ? _red : _gold;
                var _suit_object = ((suit mod 2) == 0)
                    ? obj_bullet_diamond
                    : obj_bullet_bead;

                GameBossLinearFanSpawn(_suit_object, _x, _y, _suit_center,
                    min(28, _phase.spread * 0.28), _cards_per_suit,
                    _phase.speed + (suit * 0.12), _suit_color);
            }

            GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                _suit_base + 45, _phase.speed * 0.72, _color);
            return true;

        case "mira_dealer_fan":
            var _deal_count = max(5, _phase.burst_count);
            var _deal_aim = point_direction(_x, _y, _target_x, _target_y);
            var _deal_step = _phase.spread / max(1, _deal_count - 1);
            var _deal_start = _deal_aim - (_phase.spread * 0.5);

            for (var card = 0; card < _deal_count; card++) {
                var _deal_angle = _deal_start + (card * _deal_step);
                var _deal_x = _x + (((card mod 2) == 0) ? -24 : 24);
                var _deal_color = ((card mod 4) < 2) ? _red : _gold;
                var _deal_object = ((card mod 3) == 0)
                    ? obj_bullet_bead
                    : obj_bullet_diamond;
                var _deal_speed = _phase.speed + ((card mod 3) * 0.3)
                    + min(0.65, _stage_pressure * 0.04);
                GameBossLinearBulletSpawn(_deal_object, _deal_x, _y,
                    _deal_angle, _deal_speed, _deal_color);
            }
            return true;
    }

    return false;
}

/// @func GameBossSaltwindPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Executes Saltwind's opposing gusts, offset spindrift, or alternating needles.
function GameBossSaltwindPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;

    switch (_phase.shot_kind) {
        case "saltwind_gale":
            var _gale_count = max(4, _phase.burst_count);
            var _gale_front = ceil(_gale_count * 0.5);
            var _gale_back = _gale_count - _gale_front;
            var _gale_center = _phase.base_angle + (_timer * _phase.angle_step);
            var _gale_speed = _phase.speed + min(0.8, _stage_pressure * 0.05);
            GameBossLinearFanSpawn(obj_bullet_diamond, _x, _y, _gale_center,
                _phase.spread * 0.5, _gale_front, _gale_speed, _color);

            if (_gale_back > 0) {
                GameBossLinearFanSpawn(obj_bullet_diamond, _x, _y, _gale_center + 180,
                    _phase.spread * 0.5, _gale_back, _gale_speed * 0.82, _color);
            }
            return true;

        case "saltwind_spindrift":
            var _drift_count = max(3, _phase.burst_count);
            var _drift_step = _phase.spread / max(1, _drift_count - 1);
            var _drift_start = _phase.base_angle + (_timer * _phase.angle_step)
                - (_phase.spread * 0.5);
            var _drift_clockwise = _boss.pattern_clockwise_first;

            for (var sd = 0; sd < _drift_count; sd++) {
                GameBossBladeBulletSpawn(_x, _y, _drift_start + (sd * _drift_step),
                    ((sd mod 2) == 0) ? _drift_clockwise : !_drift_clockwise,
                    _phase.turn_speed + (sd mod 3), _phase.radial_speed,
                    _color, 12 + ((sd mod 3) * 8));
            }

            _boss.pattern_clockwise_first = !_drift_clockwise;
            return true;

        case "saltwind_needles":
            var _needle_count = max(3, _phase.burst_count);
            var _needle_aim = point_direction(_x, _y, _target_x, _target_y);
            var _needle_step = _phase.spread / max(1, _needle_count);
            var _needle_start = _needle_aim - (_phase.spread * 0.5);

            for (var sn = 0; sn < _needle_count; sn++) {
                var _needle_angle = _needle_start + ((sn + 0.5) * _needle_step);
                var _needle_speed = _phase.speed + ((sn mod 3) * 0.28)
                    + min(0.7, _stage_pressure * 0.05);
                var _needle_object = ((sn mod 3) == 1) ? obj_bullet_bead : obj_bullet_diamond;
                GameBossLinearBulletSpawn(
                    _needle_object, _x, _y, _needle_angle, _needle_speed, _color);
            }
            return true;
    }

    return false;
}

/// @func GameBossKelpPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Executes Kelp's closing snare, rotating bramble, or descending wall.
function GameBossKelpPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;

    switch (_phase.shot_kind) {
        case "kelp_snare":
            var _snare_pairs = max(2, ceil(_phase.burst_count * 0.5));
            var _snare_width = _phase.spread * 0.32;

            for (var ks = 0; ks < _snare_pairs; ks++) {
                var _snare_offset = (ks + 1) * (_phase.spread / (_snare_pairs + 1)) * 0.3;
                var _left_x = _x - _snare_width;
                var _right_x = _x + _snare_width;
                var _left_aim = point_direction(_left_x, _y, _target_x, _target_y) + _snare_offset;
                var _right_aim = point_direction(_right_x, _y, _target_x, _target_y) - _snare_offset;
                GameBossLinearBulletSpawn(obj_bullet_bead, _left_x, _y, _left_aim,
                    _phase.speed + (ks * 0.16), _color);
                GameBossLinearBulletSpawn(obj_bullet_bead, _right_x, _y, _right_aim,
                    _phase.speed + (ks * 0.16), _color);
            }
            return true;

        case "kelp_bramble":
            var _bramble_count = max(4, _phase.burst_count);
            var _bramble_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _bramble_clockwise = _boss.pattern_clockwise_first;

            for (var kb = 0; kb < _bramble_count; kb++) {
                var _bramble_angle = _bramble_base + ((kb mod 4) * 90) + ((kb div 4) * 11);
                GameBossBladeBulletSpawn(_x, _y, _bramble_angle,
                    ((kb div 4) mod 2 == 0) ? _bramble_clockwise : !_bramble_clockwise,
                    _phase.turn_speed + (kb mod 2), _phase.radial_speed,
                    _color, 10 + ((kb div 4) * 14));

                if ((kb mod 3) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _bramble_angle + 45, _phase.speed, _color);
                }
            }

            _boss.pattern_clockwise_first = !_bramble_clockwise;
            return true;

        case "kelp_wall":
            var _wall_count = max(4, _phase.burst_count);
            var _wall_left = _x - (_phase.spread * 0.5);
            var _wall_step = _phase.spread / max(1, _wall_count - 1);
            var _wall_wobble = sin(_timer * 6) * 14;

            for (var kw = 0; kw < _wall_count; kw++) {
                var _wall_x = _wall_left + (kw * _wall_step);
                var _wall_direction = 270 + _wall_wobble + (((kw mod 2) == 0) ? -8 : 8);
                var _wall_object = ((kw mod 3) == 0) ? obj_bullet_diamond : obj_bullet_bead;
                GameBossLinearBulletSpawn(_wall_object, _wall_x, _y, _wall_direction,
                    _phase.speed + min(0.65, _stage_pressure * 0.04), _color);
            }
            return true;
    }

    return false;
}

/// @func GameBossShalmiiPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Builds Shalmii's attacks from six-sided rune wheels, hammer lanes, and
/// expanding shockwaves. Every formation reinforces her hexagonal hammer.
function GameBossShalmiiPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;
    var _rune_glow = make_color_rgb(255, 156, 220);
    var _armor_dark = make_color_rgb(116, 48, 94);

    switch (_phase.shot_kind) {
        case "shalmii_hex_runes":
            var _hex_layers = max(1, ceil(_phase.burst_count / 6));
            var _hex_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var hex_layer = 0; hex_layer < _hex_layers; hex_layer++) {
                for (var side = 0; side < 6; side++) {
                    var _hex_angle = _hex_base + (side * 60) + (hex_layer * 8);
                    GameBossLinearBulletSpawn(
                        ((side mod 2) == 0) ? obj_bullet_diamond : obj_bullet_bead,
                        _x, _y, _hex_angle, _phase.speed + (hex_layer * 0.45),
                        (hex_layer == 0) ? _color : _rune_glow);
                }
            }
            return true;

        case "shalmii_hammerfall":
            var _fall_count = max(6, _phase.burst_count);
            var _fall_aim = point_direction(_x, _y, _target_x, _target_y);
            var _fall_width = _phase.spread * 0.5;
            var _fall_step = (_fall_count > 1) ? (_fall_width / (_fall_count - 1)) : 0;

            for (var hammer = 0; hammer < _fall_count; hammer++) {
                var _fall_x = _x - (_fall_width * 0.5) + (hammer * _fall_step);
                var _fall_angle = _fall_aim + (((hammer mod 2) == 0) ? -7 : 7);
                var _fall_color = ((hammer mod 3) == 0) ? _armor_dark : _rune_glow;
                GameBossLinearBulletSpawn(obj_bullet_diamond, _fall_x, _y,
                    _fall_angle, _phase.speed + ((hammer mod 3) * 0.22), _fall_color);
            }

            GameBossBladeBulletSpawn(_x, _y, _fall_aim, true,
                _phase.turn_speed, _phase.radial_speed, _color, 22);
            return true;

        case "shalmii_shockwave":
            var _wave_count = max(6, _phase.burst_count);
            var _wave_step = 360 / _wave_count;
            var _wave_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var rune = 0; rune < _wave_count; rune++) {
                var _wave_angle = _wave_base + (rune * _wave_step);
                var _wave_speed = _phase.speed
                    + (((rune mod 3) - 1) * 0.65)
                    + min(0.6, _stage_pressure * 0.04);
                GameBossLinearBulletSpawn(
                    ((rune mod 3) == 0) ? obj_bullet_diamond : obj_bullet_bead,
                    _x, _y, _wave_angle, _wave_speed,
                    ((rune mod 2) == 0) ? _color : _rune_glow);
            }
            return true;
    }

    return false;
}

/// @func GameBossAishaPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Contrasts Aisha's precise blue order geometry with maroon chaos shards,
/// then binds both halves inside a gold talisman circle.
function GameBossAishaPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;
    var _chaos = make_color_rgb(176, 54, 88);
    var _gold = make_color_rgb(255, 210, 104);

    switch (_phase.shot_kind) {
        case "aisha_order_circle":
            var _order_count = max(6, _phase.burst_count);
            var _order_step = 360 / _order_count;
            var _order_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var order = 0; order < _order_count; order++) {
                var _order_angle = _order_base + (order * _order_step);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _order_angle, _phase.speed + ((order mod 2) * 0.35), _color);

                if ((order mod 4) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _order_angle + (_order_step * 0.5), _phase.speed * 0.68, _gold);
                }
            }
            return true;

        case "aisha_chaos_shards":
            var _chaos_count = max(5, _phase.burst_count);
            var _chaos_aim = point_direction(_x, _y, _target_x, _target_y);
            var _chaos_step = _phase.spread / max(1, _chaos_count);

            for (var shard = 0; shard < _chaos_count; shard++) {
                var _chaos_side = ((shard mod 2) == 0) ? -1 : 1;
                var _chaos_angle = _chaos_aim
                    + (_chaos_side * ceil(shard * 0.5) * _chaos_step)
                    + sin((_timer * 9) + (shard * 47)) * 6;
                var _chaos_speed = _phase.speed + ((shard mod 4) * 0.38)
                    + min(0.7, _stage_pressure * 0.04);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _chaos_angle, _chaos_speed, _chaos);
            }
            return true;

        case "aisha_talisman_seal":
            var _seal_count = max(8, _phase.burst_count);
            var _seal_step = 360 / _seal_count;
            var _seal_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _seal_clockwise = _boss.pattern_clockwise_first;

            for (var seal = 0; seal < _seal_count; seal++) {
                var _seal_angle = _seal_base + (seal * _seal_step);

                if ((seal mod 3) == 0) {
                    GameBossBladeBulletSpawn(_x, _y, _seal_angle,
                        ((seal mod 2) == 0) ? _seal_clockwise : !_seal_clockwise,
                        _phase.turn_speed, _phase.radial_speed, _gold, 24);
                } else {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _seal_angle, _phase.speed,
                        ((seal mod 2) == 0) ? _color : _chaos);
                }
            }

            _boss.pattern_clockwise_first = !_seal_clockwise;
            return true;
    }

    return false;
}

/// @func GameBossAsterPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Weaves Aster's lavender ribbons through bunny-ear arcs, winged staff fans,
/// and a two-loop knot instead of reusing the former generic star patterns.
function GameBossAsterPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;
    var _lavender_light = make_color_rgb(228, 200, 255);
    var _wing = make_color_rgb(174, 224, 255);

    switch (_phase.shot_kind) {
        case "aster_ribbon_loop":
            var _ribbon_count = max(6, _phase.burst_count);
            var _ribbon_step = 360 / _ribbon_count;
            var _ribbon_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _ribbon_clockwise = _boss.pattern_clockwise_first;

            for (var ribbon = 0; ribbon < _ribbon_count; ribbon++) {
                GameBossBladeBulletSpawn(_x, _y,
                    _ribbon_base + (ribbon * _ribbon_step),
                    ((ribbon mod 2) == 0) ? _ribbon_clockwise : !_ribbon_clockwise,
                    _phase.turn_speed + (ribbon mod 2), _phase.radial_speed,
                    ((ribbon mod 2) == 0) ? _color : _lavender_light,
                    12 + ((ribbon mod 3) * 14));
            }

            _boss.pattern_clockwise_first = !_ribbon_clockwise;
            return true;

        case "aster_bunny_hop":
            var _hop_count = max(6, _phase.burst_count);
            var _hop_aim = point_direction(_x, _y, _target_x, _target_y);
            var _hop_pairs = max(3, ceil(_hop_count * 0.5));

            for (var hop = 0; hop < _hop_pairs; hop++) {
                var _hop_offset = 12 + (hop * (_phase.spread / max(5, _hop_pairs + 2)));
                var _hop_speed = _phase.speed + (sin((hop / _hop_pairs) * 180) * 0.9);
                GameBossLinearBulletSpawn(obj_bullet_bead, _x - 18, _y,
                    _hop_aim - _hop_offset, _hop_speed, _lavender_light);
                GameBossLinearBulletSpawn(obj_bullet_bead, _x + 18, _y,
                    _hop_aim + _hop_offset, _hop_speed, _color);
            }
            return true;

        case "aster_winged_staff":
            var _staff_count = max(5, _phase.burst_count);
            var _staff_aim = point_direction(_x, _y, _target_x, _target_y);
            var _staff_step = _phase.spread / max(1, _staff_count - 1);
            var _staff_start = _staff_aim - (_phase.spread * 0.5);

            for (var feather = 0; feather < _staff_count; feather++) {
                var _staff_angle = _staff_start + (feather * _staff_step);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _staff_angle, _phase.speed + ((feather mod 3) * 0.3), _wing);

                if (feather == 0 || feather == (_staff_count - 1)) {
                    GameBossBladeBulletSpawn(_x, _y, _staff_angle, feather == 0,
                        _phase.turn_speed, _phase.radial_speed, _color, 26);
                }
            }
            return true;

        case "aster_lavender_knot":
            var _knot_count = max(8, _phase.burst_count);
            var _knot_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var knot = 0; knot < _knot_count; knot++) {
                var _knot_ratio = knot / _knot_count;
                var _knot_angle = _knot_base + (_knot_ratio * 360);
                var _knot_offset = sin(_knot_ratio * 720) * 28;
                GameBossBladeBulletSpawn(_x, _y, _knot_angle,
                    (knot mod 2) == 0, _phase.turn_speed, _phase.radial_speed,
                    ((knot mod 2) == 0) ? _color : _lavender_light,
                    abs(_knot_offset) + 10);
            }
            return true;
    }

    return false;
}

/// @func GameBossBloodtidePatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Executes Bloodtide's double pulse, tearing spokes, pursuit fan, or crossing deluge.
function GameBossBloodtidePatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;

    switch (_phase.shot_kind) {
        case "bloodtide_pulse":
            var _pulse_count = max(6, _phase.burst_count);
            var _pulse_step = 360 / _pulse_count;
            var _pulse_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var bp = 0; bp < _pulse_count; bp++) {
                var _pulse_angle = _pulse_base + (bp * _pulse_step);
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y, _pulse_angle,
                    _phase.speed * 0.72, _color);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _pulse_angle + (_pulse_step * 0.5),
                    _phase.speed + min(0.8, _stage_pressure * 0.05), _color);
            }
            return true;

        case "bloodtide_rip":
            var _rip_count = max(4, _phase.burst_count);
            var _rip_step = 360 / _rip_count;
            var _rip_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _rip_clockwise = _boss.pattern_clockwise_first;

            for (var br = 0; br < _rip_count; br++) {
                var _rip_angle = _rip_base + (br * _rip_step);
                GameBossBladeBulletSpawn(_x, _y, _rip_angle,
                    ((br mod 2) == 0) ? _rip_clockwise : !_rip_clockwise,
                    _phase.turn_speed, _phase.radial_speed, _color, 16);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _rip_angle + 180, _phase.speed + ((br mod 2) * 0.55), _color);
            }

            _boss.pattern_clockwise_first = !_rip_clockwise;
            return true;

        case "bloodtide_hunt":
            var _hunt_count = max(5, _phase.burst_count);
            var _hunt_aim = point_direction(_x, _y, _target_x, _target_y);
            var _hunt_pairs = _hunt_count div 2;
            GameBossLinearBulletSpawn(
                obj_bullet_diamond, _x, _y, _hunt_aim, _phase.speed * 1.12, _color);

            for (var bh = 1; bh <= _hunt_pairs; bh++) {
                var _hunt_offset = (_phase.spread * bh) / max(2, _hunt_pairs + 1);
                var _hunt_speed = _phase.speed + (bh * 0.32);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _hunt_aim - _hunt_offset, _hunt_speed, _color);
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                    _hunt_aim + _hunt_offset, _hunt_speed * 0.78, _color);
            }
            return true;

        case "bloodtide_deluge":
            var _deluge_count = max(6, _phase.burst_count);
            var _deluge_step = _phase.spread / max(1, _deluge_count - 1);
            var _deluge_start = _phase.base_angle + (_timer * _phase.angle_step)
                - (_phase.spread * 0.5);

            for (var bd = 0; bd < _deluge_count; bd++) {
                var _deluge_angle = _deluge_start + (bd * _deluge_step);
                var _deluge_object = ((bd + (_timer div max(1, _phase.cadence))) mod 2 == 0)
                    ? obj_bullet_bead
                    : obj_bullet_diamond;
                GameBossLinearBulletSpawn(_deluge_object, _x, _y, _deluge_angle,
                    _phase.speed + ((bd mod 4) * 0.2), _color);
            }
            return true;
    }

    return false;
}

/// @func GameBossCaeliaPatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Traces Caelia's orbiting planets, five-point constellations, astrolabe
/// rings, and enclosed star globe with a blue-purple-gold astral palette.
function GameBossCaeliaPatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;
    var _starlight = make_color_rgb(255, 226, 112);
    var _nebula = make_color_rgb(234, 126, 232);
    var _wisp = make_color_rgb(132, 224, 255);

    switch (_phase.shot_kind) {
        case "caelia_planetary_orbit":
            var _planet_count = max(6, _phase.burst_count);
            var _planet_step = 360 / _planet_count;
            var _planet_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var planet = 0; planet < _planet_count; planet++) {
                var _planet_angle = _planet_base + (planet * _planet_step);
                GameBossBladeBulletSpawn(_x, _y, _planet_angle,
                    (planet mod 2) == 0, _phase.turn_speed, _phase.radial_speed,
                    ((planet mod 3) == 0) ? _nebula : _color,
                    16 + ((planet mod 3) * 16));

                if ((planet mod 3) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _planet_angle + 180, _phase.speed, _starlight);
                }
            }
            return true;

        case "caelia_constellation":
            var _star_points = 5;
            var _rays_per_point = max(2, ceil(_phase.burst_count / _star_points));
            var _star_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _star_aim = point_direction(_x, _y, _target_x, _target_y);

            for (var point = 0; point < _star_points; point++) {
                var _point_angle = _star_base + _star_aim + (point * 144);
                GameBossLinearFanSpawn(obj_bullet_diamond, _x, _y, _point_angle,
                    min(24, _phase.spread * 0.2), _rays_per_point,
                    _phase.speed + (point * 0.16),
                    ((point mod 2) == 0) ? _starlight : _wisp);
            }
            return true;

        case "caelia_astrolabe":
            var _astrolabe_count = max(8, _phase.burst_count);
            var _astrolabe_step = 360 / _astrolabe_count;
            var _astrolabe_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var orbit = 0; orbit < _astrolabe_count; orbit++) {
                var _orbit_angle = _astrolabe_base + (orbit * _astrolabe_step);

                if ((orbit mod 2) == 0) {
                    GameBossBladeBulletSpawn(_x, _y, _orbit_angle, true,
                        _phase.turn_speed, _phase.radial_speed, _color, 18);
                } else {
                    GameBossBladeBulletSpawn(_x, _y, _orbit_angle, false,
                        _phase.turn_speed + 2, _phase.radial_speed, _nebula, 42);
                }
            }
            return true;

        case "caelia_star_cage":
            var _cage_count = max(8, _phase.burst_count);
            var _cage_step = 360 / _cage_count;
            var _cage_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var bar = 0; bar < _cage_count; bar++) {
                var _cage_angle = _cage_base + (bar * _cage_step);
                var _cage_color = ((bar mod 3) == 0) ? _starlight : _wisp;
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _cage_angle, _phase.speed + ((bar mod 2) * 0.48), _cage_color);

                if ((bar mod 4) == 0) {
                    GameBossBladeBulletSpawn(_x, _y, _cage_angle + 90,
                        (bar mod 8) == 0, _phase.turn_speed, _phase.radial_speed,
                        _nebula, 36);
                }
            }
            return true;
    }

    return false;
}

/// @func GameBossFinalePatternFire(boss, phase, timer, target_x, target_y, stage_pressure, color)
/// Executes the one-off signature attack reserved for an encounter's last phase.
function GameBossFinalePatternFire(_boss, _phase, _timer, _target_x, _target_y,
    _stage_pressure, _color) {
    var _x = _boss.x;
    var _y = _boss.y;

    switch (_phase.shot_kind) {
        case "tideglass_maelstrom":
            var _maelstrom_count = max(8, _phase.burst_count);
            var _maelstrom_step = 360 / _maelstrom_count;
            var _maelstrom_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var tm = 0; tm < _maelstrom_count; tm++) {
                var _maelstrom_angle = _maelstrom_base + (tm * _maelstrom_step);

                if ((tm mod 2) == 0) {
                    GameBossBladeBulletSpawn(_x, _y, _maelstrom_angle, (tm mod 4) == 0,
                        _phase.turn_speed, _phase.radial_speed, _color, 18);
                } else {
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                        _maelstrom_angle + (_maelstrom_step * 0.5),
                        _phase.speed + ((tm mod 3) * 0.3), _color);
                }
            }
            return true;

        case "mira_royal_flush":
            var _flush_count = max(10, _phase.burst_count);
            var _flush_aim = point_direction(_x, _y, _target_x, _target_y);
            var _flush_cards = 5;
            var _flush_step = _phase.spread / max(1, _flush_cards - 1);
            var _flush_start = _flush_aim - (_phase.spread * 0.5);

            for (var flush = 0; flush < _flush_cards; flush++) {
                var _flush_angle = _flush_start + (flush * _flush_step);
                var _flush_color = ((flush mod 2) == 0)
                    ? make_color_rgb(255, 82, 104)
                    : make_color_rgb(255, 214, 104);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _flush_angle, _phase.speed + (flush * 0.28), _flush_color);
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                    _flush_angle, _phase.speed * 0.68 + (flush * 0.18), _color);
            }

            var _suit_ring_count = max(4, _flush_count - (_flush_cards * 2));
            var _suit_ring_step = 360 / _suit_ring_count;
            var _suit_ring_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var suit_card = 0; suit_card < _suit_ring_count; suit_card++) {
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                    _suit_ring_base + (suit_card * _suit_ring_step),
                    _phase.speed * 0.78, _color);
            }
            return true;

        case "saltwind_eye":
            var _eye_count = max(8, _phase.burst_count);
            var _eye_half = ceil(_eye_count * 0.5);
            var _eye_center = _phase.base_angle + (_timer * _phase.angle_step);
            GameBossLinearFanSpawn(obj_bullet_diamond, _x, _y, _eye_center,
                _phase.spread * 0.65, _eye_half, _phase.speed, _color);
            GameBossLinearFanSpawn(obj_bullet_bead, _x, _y, _eye_center + 180,
                _phase.spread * 0.4, _eye_count - _eye_half, _phase.speed * 0.72, _color);
            GameBossBladeBulletSpawn(_x, _y, _eye_center + 90, true,
                _phase.turn_speed, _phase.radial_speed, _color, 32);
            GameBossBladeBulletSpawn(_x, _y, _eye_center - 90, false,
                _phase.turn_speed, _phase.radial_speed, _color, 32);
            return true;

        case "kelp_abyssal_bloom":
            var _bloom_count = max(8, _phase.burst_count);
            var _bloom_step = 360 / _bloom_count;
            var _bloom_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var ka = 0; ka < _bloom_count; ka++) {
                var _bloom_angle = _bloom_base + (ka * _bloom_step);
                GameBossBladeBulletSpawn(_x, _y, _bloom_angle, (ka mod 2) == 0,
                    _phase.turn_speed + (ka mod 3), _phase.radial_speed,
                    _color, 12 + ((ka mod 4) * 10));

                if ((ka mod 2) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _bloom_angle + (_bloom_step * 0.5), _phase.speed, _color);
                }
            }
            return true;

        case "shalmii_runebreaker":
            var _breaker_count = max(12, _phase.burst_count);
            var _breaker_step = 360 / _breaker_count;
            var _breaker_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _breaker_aim = point_direction(_x, _y, _target_x, _target_y);

            for (var breaker = 0; breaker < _breaker_count; breaker++) {
                var _breaker_angle = _breaker_base + (breaker * _breaker_step);
                var _breaker_color = ((breaker mod 3) == 0)
                    ? make_color_rgb(255, 156, 220)
                    : _color;
                GameBossLinearBulletSpawn(
                    ((breaker mod 2) == 0) ? obj_bullet_diamond : obj_bullet_bead,
                    _x, _y, _breaker_angle,
                    _phase.speed + (((breaker mod 3) - 1) * 0.65), _breaker_color);
            }

            for (var hammer_side = 0; hammer_side < 6; hammer_side++) {
                GameBossBladeBulletSpawn(_x, _y,
                    _breaker_aim + (hammer_side * 60), (hammer_side mod 2) == 0,
                    _phase.turn_speed, _phase.radial_speed, _color, 34);
            }
            return true;

        case "aisha_blade_of_desires":
            var _desire_count = max(12, _phase.burst_count);
            var _desire_aim = point_direction(_x, _y, _target_x, _target_y);
            var _desire_step = _phase.spread / max(1, _desire_count - 1);
            var _desire_start = _desire_aim - (_phase.spread * 0.5);

            for (var desire = 0; desire < _desire_count; desire++) {
                var _desire_ratio = desire / max(1, _desire_count - 1);
                var _desire_angle = _desire_start + (desire * _desire_step)
                    + (sin(_desire_ratio * 180) * 16);
                var _desire_color = (desire < (_desire_count * 0.5))
                    ? make_color_rgb(106, 208, 255)
                    : make_color_rgb(176, 54, 88);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                    _desire_angle, _phase.speed + ((desire mod 3) * 0.36),
                    _desire_color);

                if ((desire mod 4) == 0) {
                    GameBossBladeBulletSpawn(_x, _y, _desire_angle + 180,
                        (desire mod 8) == 0, _phase.turn_speed, _phase.radial_speed,
                        make_color_rgb(255, 210, 104), 30);
                }
            }
            return true;

        case "aster_ribbonstar_wish":
            var _wish_points = 5;
            var _wish_layers = max(2, ceil(_phase.burst_count / (_wish_points * 2)));
            var _wish_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var wish_layer = 0; wish_layer < _wish_layers; wish_layer++) {
                for (var wish_point = 0; wish_point < _wish_points; wish_point++) {
                    var _wish_angle = _wish_base + (wish_point * 144) + (wish_layer * 7);
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                        _wish_angle, _phase.speed + (wish_layer * 0.42),
                        make_color_rgb(174, 224, 255));
                    GameBossBladeBulletSpawn(_x, _y, _wish_angle + 72,
                        (wish_point mod 2) == 0, _phase.turn_speed,
                        _phase.radial_speed, _color, 18 + (wish_layer * 16));
                }
            }
            return true;

        case "bloodtide_heart":
            var _heart_pairs = max(4, _phase.burst_count div 2);
            var _heart_aim = point_direction(_x, _y, _target_x, _target_y);

            for (var bhf = 0; bhf < _heart_pairs; bhf++) {
                var _heart_offset = 12 + (bhf * (_phase.spread / max(6, _heart_pairs + 2)));
                var _heart_speed = _phase.speed + (sin((bhf / _heart_pairs) * pi) * 1.1);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x - 18, _y,
                    _heart_aim - _heart_offset, _heart_speed, _color);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x + 18, _y,
                    _heart_aim + _heart_offset, _heart_speed, _color);
            }

            GameBossBladeBulletSpawn(_x, _y, _heart_aim + 90, true,
                _phase.turn_speed, _phase.radial_speed, _color, 34);
            GameBossBladeBulletSpawn(_x, _y, _heart_aim - 90, false,
                _phase.turn_speed, _phase.radial_speed, _color, 34);
            return true;

        case "caelia_cosmic_zenith":
            var _zenith_count = max(15, _phase.burst_count);
            var _zenith_step = 360 / _zenith_count;
            var _zenith_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var zenith = 0; zenith < _zenith_count; zenith++) {
                var _zenith_angle = _zenith_base + (zenith * _zenith_step);

                switch (zenith mod 4) {
                    case 0:
                        GameBossBladeBulletSpawn(_x, _y, _zenith_angle,
                            (zenith mod 2) == 0, _phase.turn_speed,
                            _phase.radial_speed, make_color_rgb(234, 126, 232), 38);
                        break;

                    case 1:
                        GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                            _zenith_angle, _phase.speed, make_color_rgb(255, 226, 112));
                        break;

                    case 2:
                        GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                            _zenith_angle, _phase.speed * 0.72,
                            make_color_rgb(132, 224, 255));
                        break;

                    case 3:
                        GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                            _zenith_angle + 72, _phase.speed * 1.12, _color);
                        break;
                }
            }
            return true;

        case "rose_eternity":
            var _eternity_count = max(12, _phase.burst_count);
            var _eternity_step = 360 / _eternity_count;
            var _eternity_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var re = 0; re < _eternity_count; re++) {
                var _eternity_angle = _eternity_base + (re * _eternity_step);
                GameBossBladeBulletSpawn(_x, _y, _eternity_angle, (re mod 2) == 0,
                    _phase.turn_speed + (re mod 3), _phase.radial_speed,
                    _color, 18 + ((re mod 4) * 8));

                if ((re mod 2) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _eternity_angle + (_eternity_step * 0.5),
                        _phase.speed * 0.72, make_color_rgb(255, 194, 216));
                }
            }
            return true;

        case "chakram_apotheosis":
            var _apotheosis_count = max(12, _phase.burst_count);
            var _apotheosis_step = 360 / _apotheosis_count;
            var _apotheosis_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var ca = 0; ca < _apotheosis_count; ca++) {
                var _apotheosis_angle = _apotheosis_base + (ca * _apotheosis_step);
                GameBossBladeBulletSpawn(_x, _y, _apotheosis_angle,
                    (ca mod 2) == 0, _phase.turn_speed + (ca mod 2),
                    _phase.radial_speed, _color, 22 + ((ca mod 3) * 12));

                if ((ca mod 3) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                        _apotheosis_angle + 90, _phase.speed,
                        make_color_rgb(222, 198, 255));
                }
            }
            return true;
    }

    return false;
}

/// @func GameBossPhasePatternFire(boss, phase, timer, target_x, target_y, stage_pressure)
/// Executes one scheduled burst from a boss phase descriptor.
function GameBossPhasePatternFire(_boss, _phase, _timer, _target_x, _target_y, _stage_pressure) {
    var _x = _boss.x;
    var _y = _boss.y;
    var _theme_color = GameBossPhaseColorGet(_phase.attack_theme);
    var _clockwise = _boss.pattern_clockwise_first;

    if (GameBossMiraPatternFire(
        _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossSaltwindPatternFire(
        _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossKelpPatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossShalmiiPatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossAishaPatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossAsterPatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossBloodtidePatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossCaeliaPatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)
        || GameBossFinalePatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure, _theme_color)) {
        return true;
    }

    switch (_phase.shot_kind) {
        case "blade_spiral":
            var _blade_count = max(1, _phase.burst_count);
            var _blade_step = 360 / _blade_count;
            var _blade_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var b = 0; b < _blade_count; b++) {
                GameBossBladeBulletSpawn(_x, _y, _blade_base + (b * _blade_step), _clockwise,
                    _phase.turn_speed, _phase.radial_speed);
            }

            _boss.pattern_clockwise_first = !_clockwise;
            return true;

        // Redirect spirals interleave opposite rotations on an offset outer ring.
        case "redirect_spiral":
            var _redirect_count = max(2, _phase.burst_count);
            var _redirect_step = 360 / _redirect_count;
            var _redirect_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _redirect_offset = max(14, _phase.spread * 0.25);

            for (var rs = 0; rs < _redirect_count; rs++) {
                GameBossBladeBulletSpawn(
                    _x,
                    _y,
                    _redirect_base + (rs * _redirect_step),
                    (rs mod 2) == 0,
                    _phase.turn_speed + (rs mod 2),
                    _phase.radial_speed,
                    _theme_color,
                    _redirect_offset
                );
            }

            return true;

        // Blade crosses build four fixed arms with multiple offset layers.
        case "blade_cross":
            var _cross_count = max(4, _phase.burst_count);
            var _cross_layers = ceil(_cross_count / 4);
            var _cross_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _cross_spawned = 0;

            for (var cross_layer = 0; cross_layer < _cross_layers && _cross_spawned < _cross_count; cross_layer++) {
                for (var cross_arm = 0; cross_arm < 4 && _cross_spawned < _cross_count; cross_arm++) {
                    GameBossBladeBulletSpawn(
                        _x,
                        _y,
                        _cross_base + (cross_arm * 90),
                        ((cross_arm + cross_layer) mod 2) == 0,
                        _phase.turn_speed + cross_layer,
                        _phase.radial_speed + (cross_layer * 0.1),
                        _theme_color,
                        cross_layer * 14
                    );
                    _cross_spawned += 1;
                }
            }

            return true;

        case "bead_ring":
            var _ring_count = max(1, _phase.burst_count);
            var _ring_step = 360 / _ring_count;
            var _ring_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _ring_speed = _phase.speed + min(0.5, _stage_pressure * 0.04);

            for (var r = 0; r < _ring_count; r++) {
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                    _ring_base + (r * _ring_step), _ring_speed);
            }

            return true;

        case "bead_arc":
            var _bead_aim = point_direction(_x, _y, _target_x, _target_y);
            GameBossLinearFanSpawn(obj_bullet_bead, _x, _y, _bead_aim, _phase.spread,
                _phase.burst_count, _phase.speed + min(0.65, _stage_pressure * 0.05));
            return true;

        case "diamond_fan":
            var _fan_aim = point_direction(_x, _y, _target_x, _target_y);
            var _fan_count = max(1, _phase.burst_count);
            var _fan_pairs = _fan_count div 2;
            var _fan_step = _phase.spread / max(1, _fan_pairs + 1);
            var _fan_speed = _phase.speed + min(0.75, _stage_pressure * 0.05);

            if ((_fan_count mod 2) == 1) {
                GameBossLinearBulletSpawn(
                    obj_bullet_diamond, _x, _y, _fan_aim, _fan_speed * 0.88, _theme_color);
            }

            for (var fp = 1; fp <= _fan_pairs; fp++) {
                var _wing_speed = _fan_speed + (fp * 0.22);
                var _wing_offset = fp * _fan_step;
                GameBossLinearBulletSpawn(
                    obj_bullet_diamond, _x, _y, _fan_aim - _wing_offset, _wing_speed, _theme_color);
                GameBossLinearBulletSpawn(
                    obj_bullet_diamond, _x, _y, _fan_aim + _wing_offset, _wing_speed, _theme_color);
            }

            return true;

        case "diamond_sweep":
            var _sweep_center = _phase.base_angle + (_timer * _phase.angle_step);
            GameBossLinearFanSpawn(obj_bullet_diamond, _x, _y, _sweep_center, _phase.spread,
                _phase.burst_count, _phase.speed + min(0.8, _stage_pressure * 0.05));
            return true;

        case "mixed_cross":
            var _mixed_count = max(1, _phase.burst_count);
            var _mixed_step = 360 / _mixed_count;
            var _mixed_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var m = 0; m < _mixed_count; m++) {
                var _mixed_angle = _mixed_base + (m * _mixed_step);

                if ((m mod 2) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y, _mixed_angle,
                        _phase.speed + min(0.55, _stage_pressure * 0.04));
                } else {
                    GameBossBladeBulletSpawn(_x, _y, _mixed_angle, _clockwise,
                        _phase.turn_speed, _phase.radial_speed);
                }
            }

            _boss.pattern_clockwise_first = !_clockwise;
            return true;

        // Moon's final-boss route layers rose-colored petals and thorns.
        case "rose_bloom":
            var _bloom_count = max(3, _phase.burst_count);
            var _bloom_step = 360 / _bloom_count;
            var _bloom_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var rb = 0; rb < _bloom_count; rb++) {
                var _bloom_angle = _bloom_base + (rb * _bloom_step);
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y, _bloom_angle,
                    _phase.speed + min(0.45, _stage_pressure * 0.035), _theme_color);

                if ((rb mod 2) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                        _bloom_angle + (_bloom_step * 0.5), max(1.8, _phase.speed * 0.78),
                        make_color_rgb(255, 194, 216));
                }
            }

            return true;

        case "rose_thorn_arc":
            var _thorn_count = max(3, _phase.burst_count);
            var _thorn_aim = point_direction(_x, _y, _target_x, _target_y);
            var _thorn_step = (_thorn_count > 1) ? (_phase.spread / (_thorn_count - 1)) : 0;
            var _thorn_start = _thorn_aim - (_phase.spread * 0.5);

            for (var rt = 0; rt < _thorn_count; rt++) {
                var _thorn_angle = _thorn_start + (rt * _thorn_step);
                GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y, _thorn_angle,
                    _phase.speed + min(0.65, _stage_pressure * 0.05),
                    make_color_rgb(255, 84, 118));

                if ((rt mod 3) == 1) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y, _thorn_angle + 8,
                        max(1.6, _phase.speed * 0.68), _theme_color);
                }
            }

            return true;

        case "rose_whip":
            var _whip_count = max(4, _phase.burst_count);
            var _whip_center = _phase.base_angle + (_timer * _phase.angle_step);
            var _whip_step = (_whip_count > 1) ? (_phase.spread / (_whip_count - 1)) : 0;
            var _whip_start = _whip_center - (_phase.spread * 0.5);

            for (var rw = 0; rw < _whip_count; rw++) {
                GameBossBladeBulletSpawn(_x, _y, _whip_start + (rw * _whip_step), _clockwise,
                    _phase.turn_speed + (rw mod 2), _phase.radial_speed, _theme_color, rw * 8);
            }

            _boss.pattern_clockwise_first = !_clockwise;
            return true;

        case "rose_petal_spiral":
            var _petal_count = max(4, _phase.burst_count);
            var _petal_step = 360 / _petal_count;
            var _petal_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var rp = 0; rp < _petal_count; rp++) {
                var _petal_angle = _petal_base + (rp * _petal_step);
                GameBossBladeBulletSpawn(_x, _y, _petal_angle, _clockwise,
                    _phase.turn_speed, _phase.radial_speed, _theme_color);

                if ((rp mod 4) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                        _petal_angle + (_petal_step * 0.5), _phase.speed,
                        make_color_rgb(255, 194, 216));
                }
            }

            _boss.pattern_clockwise_first = !_clockwise;
            return true;

        case "rose_garden":
            var _garden_count = max(4, _phase.burst_count);
            var _garden_ring_step = 360 / _garden_count;
            var _garden_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _garden_aim = point_direction(_x, _y, _target_x, _target_y);
            var _garden_arc_step = (_garden_count > 1) ? (_phase.spread / (_garden_count - 1)) : 0;
            var _garden_arc_start = _garden_aim - (_phase.spread * 0.5);

            for (var rg = 0; rg < _garden_count; rg++) {
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                    _garden_base + (rg * _garden_ring_step), max(1.7, _phase.speed * 0.72),
                    _theme_color);

                if ((rg mod 2) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                        _garden_arc_start + (rg * _garden_arc_step),
                        _phase.speed + min(0.7, _stage_pressure * 0.05),
                        make_color_rgb(255, 84, 118));
                }
            }

            return true;

        // Selkie's final-boss route emphasizes paired rotating chakrams.
        case "chakram_orbit":
            var _orbit_count = max(4, _phase.burst_count);
            var _orbit_step = 360 / _orbit_count;
            var _orbit_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var co = 0; co < _orbit_count; co++) {
                GameBossBladeBulletSpawn(_x, _y, _orbit_base + (co * _orbit_step),
                    (co mod 2) == 0, _phase.turn_speed, _phase.radial_speed, _theme_color);
            }

            return true;

        case "chakram_saw":
            var _saw_count = max(4, _phase.burst_count);
            var _saw_step = 360 / _saw_count;
            var _saw_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var cs = 0; cs < _saw_count; cs++) {
                var _saw_angle = _saw_base + (cs * _saw_step);
                GameBossBladeBulletSpawn(_x, _y, _saw_angle, _clockwise,
                    _phase.turn_speed + ((cs mod 2) * 2), _phase.radial_speed, _theme_color);

                if ((cs mod 2) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y, _saw_angle + 90,
                        _phase.speed, make_color_rgb(222, 198, 255));
                }
            }

            _boss.pattern_clockwise_first = !_clockwise;
            return true;

        case "chakram_return":
            var _return_count = max(4, _phase.burst_count);
            var _return_step = 360 / _return_count;
            var _return_base = _phase.base_angle + (_timer * _phase.angle_step);

            for (var cr = 0; cr < _return_count; cr++) {
                GameBossBladeBulletSpawn(_x, _y, _return_base + (cr * _return_step), _clockwise,
                    _phase.turn_speed, _phase.radial_speed, _theme_color);
            }

            _boss.pattern_clockwise_first = !_clockwise;
            return true;

        case "chakram_gate":
            var _gate_count = max(6, _phase.burst_count);
            var _gate_step = 360 / _gate_count;
            var _gate_base = _phase.base_angle + (_timer * _phase.angle_step);
            var _gate_sweep_step = (_gate_count > 1) ? (_phase.spread / (_gate_count - 1)) : 0;
            var _gate_sweep_start = 270 - (_phase.spread * 0.5);

            for (var cg = 0; cg < _gate_count; cg++) {
                GameBossLinearBulletSpawn(obj_bullet_bead, _x, _y,
                    _gate_base + (cg * _gate_step), _phase.speed, _theme_color);

                if ((cg mod 3) == 0) {
                    GameBossLinearBulletSpawn(obj_bullet_diamond, _x, _y,
                        _gate_sweep_start + (cg * _gate_sweep_step),
                        _phase.speed + min(0.6, _stage_pressure * 0.04),
                        make_color_rgb(222, 198, 255));
                }
            }

            return true;

        case "chakram_lance":
            var _lance_count = max(3, _phase.burst_count);
            var _lance_aim = point_direction(_x, _y, _target_x, _target_y);
            GameBossLinearFanSpawn(obj_bullet_diamond, _x, _y, _lance_aim, _phase.spread,
                _lance_count, _phase.speed + min(0.75, _stage_pressure * 0.05),
                make_color_rgb(222, 198, 255));

            for (var cb = 0; cb < 2; cb++) {
                var _blade_angle = _lance_aim + ((cb == 0) ? -18 : 18);
                GameBossBladeBulletSpawn(_x, _y, _blade_angle, cb == 0,
                    _phase.turn_speed + 4, max(1.4, _phase.radial_speed), _theme_color);
            }

            return true;
    }

    // Unknown descriptor values intentionally fail closed instead of creating
    // a surprise fallback pattern that hides bad data.
    show_debug_message("Warning: Unknown boss shot kind " + string(_phase.shot_kind) + ".");
    return false;
}

/// @func GameBossPhaseAttackStep(boss, phase, timer, target_x, target_y, stage_pressure)
/// Runs scheduled burst and redirect behavior for one active boss phase.
function GameBossPhaseAttackStep(_boss, _phase, _timer, _target_x, _target_y, _stage_pressure) {
    var _fired = false;
    var _fire_interval = GameRankFireIntervalGet(_phase.cadence, 1);

    if ((_timer mod _fire_interval) == 0) {
        _fired = GameBossPhasePatternFire(
            _boss, _phase, _timer, _target_x, _target_y, _stage_pressure);
    }

    if (_phase.redirect_interval > 0 && _timer > 0
        && ((_timer mod _phase.redirect_interval) == 0)) {
        GameBladeBulletsRedirectAll(
            BOSS_PHASE3_FREEZE_FRAMES + (_boss.stage_rank div 3),
            BOSS_PHASE3_REDIRECT_SPEED + min(0.75, _stage_pressure * 0.08),
            BOSS_PHASE3_REDIRECT_ACCELERATION
        );
        _fired = true;
    }

    return _fired;
}

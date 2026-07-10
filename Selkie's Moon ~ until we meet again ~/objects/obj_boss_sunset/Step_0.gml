// Run the parent boss step first so phase changes and defeat timing stay centralized.
event_inherited();

// Keep the boss anchored near the top of the screen while it drifts in a figure-eight pattern.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    var _offset = GameMayflyInfinityOffsetCreate(float_phase);
    x = _camera.x + anchor_offset_x + (_offset.x * 0.9);
    y = _camera.y + anchor_offset_y + (_offset.y * 0.9);
}

float_phase = (float_phase + MAYFLY_FLOAT_RATE) mod 360;
phase_timer += 1;
var _stage_pressure = max(0, stage_rank - 1);

if (is_struct(boss_identity) && is_array(boss_identity.phase_plan)) {
    var _phase_plan_count = array_length(boss_identity.phase_plan);

    if (_phase_plan_count > 0) {
        var _phase_plan_index = floor(clamp(phase_index, 0, _phase_plan_count - 1));
        var _memory_phase = boss_identity.phase_plan[_phase_plan_index];
        var _memory_fired = false;
        var _memory_player = instance_find(obj_player, 0);
        var _target_x = (_memory_player != noone) ? _memory_player.x : x;
        var _target_y = (_memory_player != noone) ? _memory_player.y : y + 160;
        var _phase_color = c_white;

        if (_memory_phase.attack_theme == "rose") {
            _phase_color = make_color_rgb(255, 112, 166);
        } else if (_memory_phase.attack_theme == "chakram") {
            _phase_color = make_color_rgb(190, 120, 255);
        }

        if ((phase_timer mod max(1, _memory_phase.cadence)) == 0) {
            switch (_memory_phase.shot_kind) {
            case "blade_spiral":
            case "redirect_spiral":
            case "blade_cross":
                var _blade_count = max(1, _memory_phase.burst_count);
                var _blade_step = 360 / _blade_count;
                var _blade_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);
                var _clockwise = pattern_clockwise_first;

                for (var b = 0; b < _blade_count; b++) {
                    var _blade_angle = _blade_base + (b * _blade_step);
                    var _blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
                    _blade.spiral_origin_x = x;
                    _blade.spiral_origin_y = y;
                    _blade.spiral_angle = _blade_angle;
                    _blade.spiral_direction = _clockwise ? -1 : 1;
                    _blade.spiral_turn_speed = _memory_phase.turn_speed;
                    _blade.spiral_radial_speed = _memory_phase.radial_speed;
                    _blade.image_angle = _blade_angle;
                }

                pattern_clockwise_first = !pattern_clockwise_first;
                _memory_fired = true;
                break;

            case "bead_ring":
                var _ring_count = max(1, _memory_phase.burst_count);
                var _ring_step = 360 / _ring_count;
                var _ring_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

                for (var r = 0; r < _ring_count; r++) {
                    var _ring = instance_create_layer(x, y, "Instances", obj_bullet_bead);
                    _ring.move_direction = _ring_base + (r * _ring_step);
                    _ring.move_speed = _memory_phase.speed + min(0.5, _stage_pressure * 0.04);
                }

                _memory_fired = true;
                break;

            case "bead_arc":
                var _bead_count = max(1, _memory_phase.burst_count);
                var _bead_aim = point_direction(x, y, _target_x, _target_y);
                var _bead_step = (_bead_count > 1) ? (_memory_phase.spread / (_bead_count - 1)) : 0;
                var _bead_start = _bead_aim - (_memory_phase.spread * 0.5);

                for (var a = 0; a < _bead_count; a++) {
                    var _arc = instance_create_layer(x, y, "Instances", obj_bullet_bead);
                    _arc.move_direction = _bead_start + (a * _bead_step);
                    _arc.move_speed = _memory_phase.speed + min(0.65, _stage_pressure * 0.05);
                }

                _memory_fired = true;
                break;

            case "diamond_fan":
                var _fan_count = max(1, _memory_phase.burst_count);
                var _fan_aim = point_direction(x, y, _target_x, _target_y);
                var _fan_step = (_fan_count > 1) ? (_memory_phase.spread / (_fan_count - 1)) : 0;
                var _fan_start = _fan_aim - (_memory_phase.spread * 0.5);

                for (var f = 0; f < _fan_count; f++) {
                    var _fan = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
                    _fan.move_direction = _fan_start + (f * _fan_step);
                    _fan.move_speed = _memory_phase.speed + min(0.75, _stage_pressure * 0.05);
                }

                _memory_fired = true;
                break;

            case "diamond_sweep":
                var _sweep_count = max(1, _memory_phase.burst_count);
                var _sweep_center = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);
                var _sweep_step = (_sweep_count > 1) ? (_memory_phase.spread / (_sweep_count - 1)) : 0;
                var _sweep_start = _sweep_center - (_memory_phase.spread * 0.5);

                for (var d = 0; d < _sweep_count; d++) {
                    var _sweep = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
                    _sweep.move_direction = _sweep_start + (d * _sweep_step);
                    _sweep.move_speed = _memory_phase.speed + min(0.8, _stage_pressure * 0.05);
                }

                _memory_fired = true;
                break;

            case "mixed_cross":
                var _mixed_count = max(1, _memory_phase.burst_count);
                var _mixed_step = 360 / _mixed_count;
                var _mixed_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

                for (var m = 0; m < _mixed_count; m++) {
                    var _mixed_angle = _mixed_base + (m * _mixed_step);

                    if ((m mod 2) == 0) {
                        var _mixed_bead = instance_create_layer(x, y, "Instances", obj_bullet_bead);
                        _mixed_bead.move_direction = _mixed_angle;
                        _mixed_bead.move_speed = _memory_phase.speed + min(0.55, _stage_pressure * 0.04);
                    } else {
                        var _mixed_blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
                        _mixed_blade.spiral_origin_x = x;
                        _mixed_blade.spiral_origin_y = y;
                        _mixed_blade.spiral_angle = _mixed_angle;
                        _mixed_blade.spiral_direction = pattern_clockwise_first ? -1 : 1;
                        _mixed_blade.spiral_turn_speed = _memory_phase.turn_speed;
                        _mixed_blade.spiral_radial_speed = _memory_phase.radial_speed;
                        _mixed_blade.image_angle = _mixed_angle;
                    }
                }

	                pattern_clockwise_first = !pattern_clockwise_first;
	                _memory_fired = true;
	                break;

	            case "rose_bloom":
	                var _rose_bloom_count = max(3, _memory_phase.burst_count);
	                var _rose_bloom_step = 360 / _rose_bloom_count;
	                var _rose_bloom_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

	                for (var rb = 0; rb < _rose_bloom_count; rb++) {
	                    var _rose_bloom_angle = _rose_bloom_base + (rb * _rose_bloom_step);
	                    var _rose_bloom_bead = instance_create_layer(x, y, "Instances", obj_bullet_bead);
	                    _rose_bloom_bead.move_direction = _rose_bloom_angle;
	                    _rose_bloom_bead.move_speed = _memory_phase.speed + min(0.45, _stage_pressure * 0.035);
	                    _rose_bloom_bead.image_blend = _phase_color;

	                    if ((rb mod 2) == 0) {
	                        var _rose_bloom_petal = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
	                        _rose_bloom_petal.move_direction = _rose_bloom_angle + (_rose_bloom_step * 0.5);
	                        _rose_bloom_petal.move_speed = max(1.8, _memory_phase.speed * 0.78);
	                        _rose_bloom_petal.image_blend = make_color_rgb(255, 194, 216);
	                    }
	                }

	                _memory_fired = true;
	                break;

	            case "rose_thorn_arc":
	                var _rose_thorn_count = max(3, _memory_phase.burst_count);
	                var _rose_thorn_aim = point_direction(x, y, _target_x, _target_y);
	                var _rose_thorn_step = (_rose_thorn_count > 1) ? (_memory_phase.spread / (_rose_thorn_count - 1)) : 0;
	                var _rose_thorn_start = _rose_thorn_aim - (_memory_phase.spread * 0.5);

	                for (var rt = 0; rt < _rose_thorn_count; rt++) {
	                    var _rose_thorn_angle = _rose_thorn_start + (rt * _rose_thorn_step);
	                    var _rose_thorn = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
	                    _rose_thorn.move_direction = _rose_thorn_angle;
	                    _rose_thorn.move_speed = _memory_phase.speed + min(0.65, _stage_pressure * 0.05);
	                    _rose_thorn.image_blend = make_color_rgb(255, 84, 118);

	                    if ((rt mod 3) == 1) {
	                        var _rose_thorn_petal = instance_create_layer(x, y, "Instances", obj_bullet_bead);
	                        _rose_thorn_petal.move_direction = _rose_thorn_angle + 8;
	                        _rose_thorn_petal.move_speed = max(1.6, _memory_phase.speed * 0.68);
	                        _rose_thorn_petal.image_blend = _phase_color;
	                    }
	                }

	                _memory_fired = true;
	                break;

	            case "rose_whip":
	                var _rose_whip_count = max(4, _memory_phase.burst_count);
	                var _rose_whip_center = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);
	                var _rose_whip_step = (_rose_whip_count > 1) ? (_memory_phase.spread / (_rose_whip_count - 1)) : 0;
	                var _rose_whip_start = _rose_whip_center - (_memory_phase.spread * 0.5);

	                for (var rw = 0; rw < _rose_whip_count; rw++) {
	                    var _rose_whip_angle = _rose_whip_start + (rw * _rose_whip_step);
	                    var _rose_whip_offset = rw * 8;
	                    var _rose_whip_blade = instance_create_layer(
	                        x + lengthdir_x(_rose_whip_offset, _rose_whip_angle + 90),
	                        y + lengthdir_y(_rose_whip_offset, _rose_whip_angle + 90),
	                        "Instances",
	                        obj_bullet_blade
	                    );
	                    _rose_whip_blade.spiral_origin_x = x;
	                    _rose_whip_blade.spiral_origin_y = y;
	                    _rose_whip_blade.spiral_angle = _rose_whip_angle;
	                    _rose_whip_blade.spiral_direction = pattern_clockwise_first ? -1 : 1;
	                    _rose_whip_blade.spiral_turn_speed = _memory_phase.turn_speed + (rw mod 2);
	                    _rose_whip_blade.spiral_radial_speed = _memory_phase.radial_speed;
	                    _rose_whip_blade.image_angle = _rose_whip_angle;
	                    _rose_whip_blade.image_blend = _phase_color;
	                }

	                pattern_clockwise_first = !pattern_clockwise_first;
	                _memory_fired = true;
	                break;

	            case "rose_petal_spiral":
	                var _rose_petal_count = max(4, _memory_phase.burst_count);
	                var _rose_petal_step = 360 / _rose_petal_count;
	                var _rose_petal_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

	                for (var rp = 0; rp < _rose_petal_count; rp++) {
	                    var _rose_petal_angle = _rose_petal_base + (rp * _rose_petal_step);
	                    var _rose_petal_blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
	                    _rose_petal_blade.spiral_origin_x = x;
	                    _rose_petal_blade.spiral_origin_y = y;
	                    _rose_petal_blade.spiral_angle = _rose_petal_angle;
	                    _rose_petal_blade.spiral_direction = pattern_clockwise_first ? -1 : 1;
	                    _rose_petal_blade.spiral_turn_speed = _memory_phase.turn_speed;
	                    _rose_petal_blade.spiral_radial_speed = _memory_phase.radial_speed;
	                    _rose_petal_blade.image_angle = _rose_petal_angle;
	                    _rose_petal_blade.image_blend = _phase_color;

	                    if ((rp mod 4) == 0) {
	                        var _rose_petal_bead = instance_create_layer(x, y, "Instances", obj_bullet_bead);
	                        _rose_petal_bead.move_direction = _rose_petal_angle + (_rose_petal_step * 0.5);
	                        _rose_petal_bead.move_speed = _memory_phase.speed;
	                        _rose_petal_bead.image_blend = make_color_rgb(255, 194, 216);
	                    }
	                }

	                pattern_clockwise_first = !pattern_clockwise_first;
	                _memory_fired = true;
	                break;

	            case "rose_garden":
	                var _rose_garden_count = max(4, _memory_phase.burst_count);
	                var _rose_garden_ring_step = 360 / _rose_garden_count;
	                var _rose_garden_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);
	                var _rose_garden_aim = point_direction(x, y, _target_x, _target_y);
	                var _rose_garden_arc_step = (_rose_garden_count > 1) ? (_memory_phase.spread / (_rose_garden_count - 1)) : 0;
	                var _rose_garden_arc_start = _rose_garden_aim - (_memory_phase.spread * 0.5);

	                for (var rg = 0; rg < _rose_garden_count; rg++) {
	                    var _rose_garden_gate = instance_create_layer(x, y, "Instances", obj_bullet_bead);
	                    _rose_garden_gate.move_direction = _rose_garden_base + (rg * _rose_garden_ring_step);
	                    _rose_garden_gate.move_speed = max(1.7, _memory_phase.speed * 0.72);
	                    _rose_garden_gate.image_blend = _phase_color;

	                    if ((rg mod 2) == 0) {
	                        var _rose_garden_thorn = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
	                        _rose_garden_thorn.move_direction = _rose_garden_arc_start + (rg * _rose_garden_arc_step);
	                        _rose_garden_thorn.move_speed = _memory_phase.speed + min(0.7, _stage_pressure * 0.05);
	                        _rose_garden_thorn.image_blend = make_color_rgb(255, 84, 118);
	                    }
	                }

	                _memory_fired = true;
	                break;

	            case "chakram_orbit":
	                var _chakram_orbit_count = max(4, _memory_phase.burst_count);
	                var _chakram_orbit_step = 360 / _chakram_orbit_count;
	                var _chakram_orbit_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

	                for (var co = 0; co < _chakram_orbit_count; co++) {
	                    var _chakram_orbit_angle = _chakram_orbit_base + (co * _chakram_orbit_step);
	                    var _chakram_orbit_blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
	                    _chakram_orbit_blade.spiral_origin_x = x;
	                    _chakram_orbit_blade.spiral_origin_y = y;
	                    _chakram_orbit_blade.spiral_angle = _chakram_orbit_angle;
	                    _chakram_orbit_blade.spiral_direction = ((co mod 2) == 0) ? -1 : 1;
	                    _chakram_orbit_blade.spiral_turn_speed = _memory_phase.turn_speed;
	                    _chakram_orbit_blade.spiral_radial_speed = _memory_phase.radial_speed;
	                    _chakram_orbit_blade.image_angle = _chakram_orbit_angle;
	                    _chakram_orbit_blade.image_blend = _phase_color;
	                }

	                _memory_fired = true;
	                break;

	            case "chakram_saw":
	                var _chakram_saw_count = max(4, _memory_phase.burst_count);
	                var _chakram_saw_step = 360 / _chakram_saw_count;
	                var _chakram_saw_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

	                for (var cs = 0; cs < _chakram_saw_count; cs++) {
	                    var _chakram_saw_angle = _chakram_saw_base + (cs * _chakram_saw_step);
	                    var _chakram_saw_blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
	                    _chakram_saw_blade.spiral_origin_x = x;
	                    _chakram_saw_blade.spiral_origin_y = y;
	                    _chakram_saw_blade.spiral_angle = _chakram_saw_angle;
	                    _chakram_saw_blade.spiral_direction = pattern_clockwise_first ? -1 : 1;
	                    _chakram_saw_blade.spiral_turn_speed = _memory_phase.turn_speed + ((cs mod 2) * 2);
	                    _chakram_saw_blade.spiral_radial_speed = _memory_phase.radial_speed;
	                    _chakram_saw_blade.image_angle = _chakram_saw_angle;
	                    _chakram_saw_blade.image_blend = _phase_color;

	                    if ((cs mod 2) == 0) {
	                        var _chakram_saw_spark = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
	                        _chakram_saw_spark.move_direction = _chakram_saw_angle + 90;
	                        _chakram_saw_spark.move_speed = _memory_phase.speed;
	                        _chakram_saw_spark.image_blend = make_color_rgb(222, 198, 255);
	                    }
	                }

	                pattern_clockwise_first = !pattern_clockwise_first;
	                _memory_fired = true;
	                break;

	            case "chakram_return":
	                var _chakram_return_count = max(4, _memory_phase.burst_count);
	                var _chakram_return_step = 360 / _chakram_return_count;
	                var _chakram_return_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);

	                for (var cr = 0; cr < _chakram_return_count; cr++) {
	                    var _chakram_return_angle = _chakram_return_base + (cr * _chakram_return_step);
	                    var _chakram_return_blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
	                    _chakram_return_blade.spiral_origin_x = x;
	                    _chakram_return_blade.spiral_origin_y = y;
	                    _chakram_return_blade.spiral_angle = _chakram_return_angle;
	                    _chakram_return_blade.spiral_direction = pattern_clockwise_first ? -1 : 1;
	                    _chakram_return_blade.spiral_turn_speed = _memory_phase.turn_speed;
	                    _chakram_return_blade.spiral_radial_speed = _memory_phase.radial_speed;
	                    _chakram_return_blade.image_angle = _chakram_return_angle;
	                    _chakram_return_blade.image_blend = _phase_color;
	                }

	                pattern_clockwise_first = !pattern_clockwise_first;
	                _memory_fired = true;
	                break;

	            case "chakram_gate":
	                var _chakram_gate_count = max(6, _memory_phase.burst_count);
	                var _chakram_gate_step = 360 / _chakram_gate_count;
	                var _chakram_gate_base = _memory_phase.base_angle + (phase_timer * _memory_phase.angle_step);
	                var _chakram_gate_sweep_step = (_chakram_gate_count > 1) ? (_memory_phase.spread / (_chakram_gate_count - 1)) : 0;
	                var _chakram_gate_sweep_start = 270 - (_memory_phase.spread * 0.5);

	                for (var cg = 0; cg < _chakram_gate_count; cg++) {
	                    var _chakram_gate_bead = instance_create_layer(x, y, "Instances", obj_bullet_bead);
	                    _chakram_gate_bead.move_direction = _chakram_gate_base + (cg * _chakram_gate_step);
	                    _chakram_gate_bead.move_speed = _memory_phase.speed;
	                    _chakram_gate_bead.image_blend = _phase_color;

	                    if ((cg mod 3) == 0) {
	                        var _chakram_gate_spark = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
	                        _chakram_gate_spark.move_direction = _chakram_gate_sweep_start + (cg * _chakram_gate_sweep_step);
	                        _chakram_gate_spark.move_speed = _memory_phase.speed + min(0.6, _stage_pressure * 0.04);
	                        _chakram_gate_spark.image_blend = make_color_rgb(222, 198, 255);
	                    }
	                }

	                _memory_fired = true;
	                break;

	            case "chakram_lance":
	                var _chakram_lance_count = max(3, _memory_phase.burst_count);
	                var _chakram_lance_aim = point_direction(x, y, _target_x, _target_y);
	                var _chakram_lance_step = (_chakram_lance_count > 1) ? (_memory_phase.spread / (_chakram_lance_count - 1)) : 0;
	                var _chakram_lance_start = _chakram_lance_aim - (_memory_phase.spread * 0.5);

	                for (var cl = 0; cl < _chakram_lance_count; cl++) {
	                    var _chakram_lance_angle = _chakram_lance_start + (cl * _chakram_lance_step);
	                    var _chakram_lance = instance_create_layer(x, y, "Instances", obj_bullet_diamond);
	                    _chakram_lance.move_direction = _chakram_lance_angle;
	                    _chakram_lance.move_speed = _memory_phase.speed + min(0.75, _stage_pressure * 0.05);
	                    _chakram_lance.image_blend = make_color_rgb(222, 198, 255);
	                }

	                for (var cb = 0; cb < 2; cb++) {
	                    var _chakram_lance_blade_angle = _chakram_lance_aim + ((cb == 0) ? -18 : 18);
	                    var _chakram_lance_blade = instance_create_layer(x, y, "Instances", obj_bullet_blade);
	                    _chakram_lance_blade.spiral_origin_x = x;
	                    _chakram_lance_blade.spiral_origin_y = y;
	                    _chakram_lance_blade.spiral_angle = _chakram_lance_blade_angle;
	                    _chakram_lance_blade.spiral_direction = (cb == 0) ? -1 : 1;
	                    _chakram_lance_blade.spiral_turn_speed = _memory_phase.turn_speed + 4;
	                    _chakram_lance_blade.spiral_radial_speed = max(1.4, _memory_phase.radial_speed);
	                    _chakram_lance_blade.image_angle = _chakram_lance_blade_angle;
	                    _chakram_lance_blade.image_blend = _phase_color;
	                }

	                _memory_fired = true;
	                break;
	        }
	    }

    if (_memory_phase.redirect_interval > 0 && phase_timer > 0
        && ((phase_timer mod _memory_phase.redirect_interval) == 0)) {
        GameBladeBulletsRedirectAll(
            BOSS_PHASE3_FREEZE_FRAMES + (stage_rank div 3),
            BOSS_PHASE3_REDIRECT_SPEED + min(0.75, _stage_pressure * 0.08),
            BOSS_PHASE3_REDIRECT_ACCELERATION
        );
        _memory_fired = true;
    }

    if (_memory_fired) {
        GameEnemyFireSoundPlay();
    }

	    exit;
	}
}

switch (phase_index) {
    case 0:
        var _burst = GameMayflyBurstStateCreate(pattern_timer, pattern_clockwise_first);

        if (_burst.fire) {
            var _spirals = GameMayflyShotSpawnSpecsCreate(x, y, _burst.clockwise,
                BOSS_FAST_MAYFLY_TURN_SPEED + min(5, _stage_pressure),
                BOSS_FAST_MAYFLY_RADIAL_SPEED + min(0.7, _stage_pressure * 0.06));

            for (var i = 0; i < array_length(_spirals); i++) {
                var _shot = _spirals[i];
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

        pattern_timer += 1;
        if (pattern_timer >= MAYFLY_PATTERN_PERIOD) {
            pattern_timer = 0;
            pattern_clockwise_first = !pattern_clockwise_first;
        }

        if ((phase_timer mod max(22, BOSS_BEE_PATTERN_INTERVAL - _stage_pressure)) == 0) {
            var _player = instance_find(obj_player, 0);

            if (_player != noone) {
                var _bee_shots = GameBeeShotSpawnSpecsCreate(x, y, _player.x, _player.y);

                for (var j = 0; j < array_length(_bee_shots); j++) {
                    var _bee_shot = _bee_shots[j];
                    var _diamond = instance_create_layer(_bee_shot.x, _bee_shot.y, "Instances", _bee_shot.object_index);
                    _diamond.move_direction = _bee_shot.direction;
                    _diamond.move_speed = _bee_shot.speed;
                }

                GameEnemyFireSoundPlay();
            }
        }
        break;

    case 1:
        if (GameBossPhaseTwoScatterActive(phase_timer)) {
            var _scatter_shots = BOSS_PHASE2_SHOTS_PER_FRAME + (stage_rank >= 7 ? 1 : 0);

            for (var k = 0; k < _scatter_shots; k++) {
                var _scatter = GameBossScatterShotSpecCreate(x, y);
                var _bead = instance_create_layer(_scatter.x, _scatter.y, "Instances", _scatter.object_index);
                _bead.move_direction = _scatter.direction;
                _bead.move_speed = _scatter.speed + min(0.55, _stage_pressure * 0.04);
            }

            GameEnemyFireSoundPlay();
        }
        break;

    case 2:
        var _phase_three_burst = GameMayflyBurstStateCreate(pattern_timer, pattern_clockwise_first);

        if (_phase_three_burst.fire) {
            var _phase_three_shots = GameMayflyShotSpawnSpecsCreate(x, y, _phase_three_burst.clockwise);

            for (var n = 0; n < array_length(_phase_three_shots); n++) {
                var _phase_three_shot = _phase_three_shots[n];
                var _blade = instance_create_layer(_phase_three_shot.x, _phase_three_shot.y, "Instances", _phase_three_shot.object_index);
                _blade.spiral_origin_x = _phase_three_shot.x;
                _blade.spiral_origin_y = _phase_three_shot.y;
                _blade.spiral_angle = _phase_three_shot.spiral_angle;
                _blade.spiral_direction = _phase_three_shot.spiral_direction;
                _blade.spiral_turn_speed = _phase_three_shot.spiral_turn_speed;
                _blade.spiral_radial_speed = _phase_three_shot.spiral_radial_speed;
                _blade.image_angle = _phase_three_shot.spiral_angle;
            }

            GameEnemyFireSoundPlay();
        }

        pattern_timer += 1;
        if (pattern_timer >= MAYFLY_PATTERN_PERIOD) {
            pattern_timer = 0;
            pattern_clockwise_first = !pattern_clockwise_first;
        }

        if (phase_timer > 0 && ((phase_timer mod max(190, BOSS_PHASE3_REDIRECT_INTERVAL - (_stage_pressure * 10))) == 0)) {
            GameBladeBulletsRedirectAll(BOSS_PHASE3_FREEZE_FRAMES, BOSS_PHASE3_REDIRECT_SPEED, BOSS_PHASE3_REDIRECT_ACCELERATION);
        }
        break;
}

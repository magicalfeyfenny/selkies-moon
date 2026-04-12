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

switch (phase_index) {
    case 0:
        var _burst = GameMayflyBurstStateCreate(pattern_timer, pattern_clockwise_first);

        if (_burst.fire) {
            var _spirals = GameMayflyShotSpawnSpecsCreate(x, y, _burst.clockwise, BOSS_FAST_MAYFLY_TURN_SPEED, BOSS_FAST_MAYFLY_RADIAL_SPEED);

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
        }

        pattern_timer += 1;
        if (pattern_timer >= MAYFLY_PATTERN_PERIOD) {
            pattern_timer = 0;
            pattern_clockwise_first = !pattern_clockwise_first;
        }

        if ((phase_timer mod BOSS_BEE_PATTERN_INTERVAL) == 0) {
            var _player = instance_find(obj_player, 0);

            if (_player != noone) {
                var _bee_shots = GameBeeShotSpawnSpecsCreate(x, y, _player.x, _player.y);

                for (var j = 0; j < array_length(_bee_shots); j++) {
                    var _bee_shot = _bee_shots[j];
                    var _diamond = instance_create_layer(_bee_shot.x, _bee_shot.y, "Instances", _bee_shot.object_index);
                    _diamond.move_direction = _bee_shot.direction;
                    _diamond.move_speed = _bee_shot.speed;
                }
            }
        }
        break;

    case 1:
        if (GameBossPhaseTwoScatterActive(phase_timer)) {
            for (var k = 0; k < BOSS_PHASE2_SHOTS_PER_FRAME; k++) {
                var _scatter = GameBossScatterShotSpecCreate(x, y);
                var _bead = instance_create_layer(_scatter.x, _scatter.y, "Instances", _scatter.object_index);
                _bead.move_direction = _scatter.direction;
                _bead.move_speed = _scatter.speed;
            }
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
        }

        pattern_timer += 1;
        if (pattern_timer >= MAYFLY_PATTERN_PERIOD) {
            pattern_timer = 0;
            pattern_clockwise_first = !pattern_clockwise_first;
        }

        if (GameBossPhaseThreeRedirectDue(phase_timer)) {
            GameBladeBulletsRedirectAll(BOSS_PHASE3_FREEZE_FRAMES, BOSS_PHASE3_REDIRECT_SPEED, BOSS_PHASE3_REDIRECT_ACCELERATION);
        }
        break;
}

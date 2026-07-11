// Gather the shared runtime state and current input snapshot for this frame.
GameRuntimeGameplayEnsure();

var _input = GameGameplayInputSnapshotRead();
var _camera = instance_find(obj_camera, 0);
var _scene = instance_find(obj_scene_manager, 0);
var _camera_x = CAMERA_HOME_X;
var _camera_y = CAMERA_HOME_Y;
var _scroll_speed = CAMERA_SCROLL_SPEED;

if (_camera != noone) {
    _camera_x = _camera.x;
    _camera_y = _camera.y;
}

if (_scene != noone) {
    _scroll_speed = _scene.scene_state.scroll_speed;
}

// While the continue screen is active, only prompt input is processed.
if (global.game_runtime.signals.continue_request) {
    var _continue_action = GameContinueStateStep(global.game_runtime.continue_screen, _input);

    switch (_continue_action) {
        case "continue":
            var _continue_spawn = GamePlayerContinueAccept(player_state, _camera_x, _camera_y);
            x = _continue_spawn.x;
            y = _continue_spawn.y;
            break;

        case "game_over":
            GamePlayerGameOverFinalize();
            break;
    }

    exit;
}

// Suspend player activity while gameplay dialogue is active.
if (global.game_runtime.signals.dialogue) {
    exit;
}

// Resolve the death animation and respawn or continue handoff once it finishes.
if (player_state.hit) {
    player_state.death_timer -= 1;

    if (player_state.death_timer <= 0) {
        if (global.game_runtime.lives > 0) {
            var _respawn = GameScenePlayerRespawnPositionGet(_camera_x, _camera_y);
            GamePlayerRespawnStateApply(player_state);
            x = _respawn.x;
            y = _respawn.y;
        } else {
            GamePlayerContinueRequestBegin();
        }
    }

    exit;
}

// Apply stage scroll and directional movement before clamping to the field.
var _movement = GamePlayerMovementDeltaCreate(_input);
var _clamped = GameScenePlayerClampPosition(_camera_x, _camera_y, x + _movement.x, y + _movement.y - _scroll_speed);

x = _clamped.x;
y = _clamped.y;

if (_scene != noone) {
    _scene.scene_state.target_x = GameSceneCameraTargetXGet(_scene.scene_state.home_x, _scene.scene_state.target_x, x);
}

// Start one bomb animation when the bomb verb is pressed and stock is available.
if (_input.bomb_pressed) {
    GamePlayerBombTryStart(player_state);
}

// Consume volley shots and sword sweeps from the current fire state.
var _fire = GamePlayerFireStep(player_state, _input);
if (_fire.spawn_shots) {
    var _ship_id = GameRunShipIdGet();
    var _power = GamePlayerPowerGet();
    var _shots = GamePlayerShotSpawnSpecsCreate(x, y, _ship_id, _fire.focused_attack, _power);
    var _shot_total = array_length(_shots);

    GamePlayerShotSoundPlay(_ship_id, _fire.focused_attack, _power);

    for (var i = 0; i < _shot_total; i++) {
        var _shot = instance_create_layer(_shots[i].x, _shots[i].y, "Instances", obj_player_shot);
        _shot.move_direction = _shots[i].direction;
        _shot.move_speed = _shots[i].speed;
        _shot.shot_sprite = _shots[i].sprite_id;
        _shot.damage = _shots[i].damage;
        _shot.shot_scale = _shots[i].scale;
        _shot.shot_color = _shots[i].color;
        _shot.shot_accent_color = _shots[i].accent_color;
        _shot.shot_power = _shots[i].power;
        _shot.shot_focused = _shots[i].focused;
    }
}

if (_fire.sword_active) {
    if (_fire.current_pose.moving && !_fire.previous_pose.moving) {
        GamePlayerSwordSoundPlay(GameRunShipIdGet());
    }

    for (var i = instance_number(obj_bullet_parent) - 1; i >= 0; i--) {
        var _bullet = instance_find(obj_bullet_parent, i);

        if (GamePlayerSwordShouldCancelBullet(x, y, _bullet.x, _bullet.y, _fire.previous_pose, _fire.current_pose)) {
            GameBulletCancelMark(_bullet, global.game_runtime.is_berserk);
        }
    }

    for (var i = instance_number(obj_enemy_parent) - 1; i >= 0; i--) {
        var _enemy = instance_find(obj_enemy_parent, i);

        if (!variable_instance_exists(_enemy, "hit_radius")) {
            continue;
        }

        if (GamePlayerSwordShouldCancelBullet(x, y, _enemy.x, _enemy.y, _fire.previous_pose, _fire.current_pose)) {
            GamePlayerSwordDamageTryApply(_enemy, _fire.sweep_id);
        }
    }

    for (var i = instance_number(obj_boss_parent) - 1; i >= 0; i--) {
        var _boss = instance_find(obj_boss_parent, i);

        if (!variable_instance_exists(_boss, "hit_radius")) {
            continue;
        }

        if (variable_instance_exists(_boss, "destruction_active") && _boss.destruction_active) {
            continue;
        }

        if (GamePlayerSwordShouldCancelBullet(x, y, _boss.x, _boss.y, _fire.previous_pose, _fire.current_pose)) {
            GamePlayerSwordDamageTryApply(_boss, _fire.sweep_id);
        }
    }
}

// Resolve the 2x2 hitbox collision against active bullets.
if (!GamePlayerIsInvulnerable(player_state)) {
    for (var i = instance_number(obj_bullet_parent) - 1; i >= 0; i--) {
        var _bullet = instance_find(obj_bullet_parent, i);
        var _collision_radius = 0;

        if (variable_instance_exists(_bullet, "collision_radius")) {
            _collision_radius = _bullet.collision_radius;
        }

        if (!GamePlayerBulletHitCheck(x, y, _bullet.x, _bullet.y, _collision_radius)) {
            continue;
        }

        with (_bullet) {
            instance_destroy();
        }

        if (!GamePlayerIsInvulnerable(player_state)) {
            GamePlayerDeathBegin(player_state);
            break;
        }
    }
}

// Keep the bomb active for its full animation and clear bullets for the whole window.
GamePlayerBombStep(player_state);

if (player_state.invuln_timer > 0) {
    player_state.invuln_timer -= 1;
}

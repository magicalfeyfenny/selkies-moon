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
var _move_x = (_input.right_down - _input.left_down) * PLAYER_MOVE_SPEED;
var _move_y = (_input.down_down - _input.up_down) * PLAYER_MOVE_SPEED;
var _clamped = GameScenePlayerClampPosition(_camera_x, _camera_y, x + _move_x, y + _move_y - _scroll_speed);

x = _clamped.x;
y = _clamped.y;

if (_scene != noone) {
    _scene.scene_state.target_x = GameSceneCameraTargetXGet(_scene.scene_state.home_x, _scene.scene_state.target_x, x);
}

// Consume volley shots and sword sweeps from the current fire state.
var _fire = GamePlayerFireStep(player_state, _input);
if (_fire.spawn_shots) {
    var _shots = GamePlayerShotSpawnSpecsCreate(x, y);
    var _shot_total = array_length(_shots);

    for (var i = 0; i < _shot_total; i++) {
        var _shot = instance_create_layer(_shots[i].x, _shots[i].y, "Instances", obj_player_shot);
        _shot.move_direction = _shots[i].direction;
        _shot.move_speed = _shots[i].speed;
    }
}

if (_fire.sword_active) {
    for (var i = instance_number(obj_bullet_parent) - 1; i >= 0; i--) {
        var _bullet = instance_find(obj_bullet_parent, i);

        if (GamePlayerSwordShouldCancelBullet(x, y, _bullet.x, _bullet.y, _fire.previous_pose, _fire.current_pose)) {
            GameBulletCancelMark(_bullet, global.game_runtime.is_berserk);
        }
    }
}

// Resolve the 2x2 hitbox collision against active bullets.
for (var i = instance_number(obj_bullet_parent) - 1; i >= 0; i--) {
    var _bullet = instance_find(obj_bullet_parent, i);

    if (abs(_bullet.x - x) > 1 || abs(_bullet.y - y) > 1) {
        continue;
    }

    with (_bullet) {
        instance_destroy();
    }

    if (player_state.invuln_timer <= 0) {
        GamePlayerDeathBegin(player_state);
        break;
    }
}

if (player_state.invuln_timer > 0) {
    player_state.invuln_timer -= 1;
}

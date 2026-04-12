#macro GAME_VIEW_WIDTH 640
#macro GAME_VIEW_HEIGHT 360
#macro GAME_VIEW_HALF_WIDTH 320
#macro GAME_VIEW_HALF_HEIGHT 180

#macro PLAYFIELD_WIDTH 202
#macro PLAYFIELD_HALF_WIDTH 101
#macro PLAYFIELD_HALF_HEIGHT 180
#macro PLAYFIELD_VERTICAL_PADDING 10

#macro CAMERA_HOME_X 320
#macro CAMERA_HOME_Y 180
#macro CAMERA_DRAG_LIMIT 100
#macro CAMERA_DRAG_MARGIN 24
#macro CAMERA_SCROLL_SPEED 1

#macro PLAYER_MOVE_SPEED 4
#macro PLAYER_RESPAWN_OFFSET_Y 120
#macro PLAYER_DEATH_ANIMATION_FRAMES 45

#macro SHOT_SPEED 13
#macro SHOT_VOLLEY_SIZE 6
#macro SHOT_VOLLEY_INTERVAL 3
#macro FIRE_HOLD_FRAMES 60
#macro SHOT_SPRITE_FRONT spr_sunrise_bullet
#macro SHOT_SPRITE_SIDE spr_sunset_bullet
#macro SAMPLE_ENEMY_FIRE_INTERVAL 60
#macro SAMPLE_ENEMY_BULLET_SPEED 3.5

#macro SWEEP_RATE 2
#macro SWEEP_PERIOD_FRAMES 30
#macro SWORD_START_ANGLE 315
#macro SWORD_END_ANGLE 585
#macro SWORD_LENGTH 128
#macro BERSERK_SWORD_MULTIPLIER 1.5

#macro INVULN_TIME 300
#macro CANCEL_BONUS 100
#macro CANCEL_METER 1
#macro METER_MAX 1000

#macro CONTINUE_OPTION_YES 0
#macro CONTINUE_OPTION_NO 1
#macro GAME_OVER_DELAY_FRAMES 90

#macro STAGE_LENGTH_FRAMES 1800

/// @func GameContinueStateCreate()
/// Creates the runtime state used by the continue prompt.
function GameContinueStateCreate() {
    return {
        selected_index: CONTINUE_OPTION_YES,
        mode: "prompt",
        game_over_timer: 0,
    };
}

/// @func GameRuntimeGameplayEnsure()
/// Ensures gameplay-specific runtime fields exist before gameplay code runs.
function GameRuntimeGameplayEnsure() {
    if (!variable_global_exists("game_runtime")) {
        return false;
    }

    if (!struct_exists(global.game_runtime, "signals")) {
        global.game_runtime.signals = {};
    }

    if (!struct_exists(global.game_runtime.signals, "dialogue")) {
        global.game_runtime.signals.dialogue = false;
    }

    if (!struct_exists(global.game_runtime.signals, "continue_request")) {
        global.game_runtime.signals.continue_request = false;
    }

    if (!struct_exists(global.game_runtime, "continue_screen")) {
        global.game_runtime.continue_screen = GameContinueStateCreate();
    }

    if (!struct_exists(global.game_runtime, "meter")) {
        global.game_runtime.meter = 0;
    }

    if (!struct_exists(global.game_runtime, "is_berserk")) {
        global.game_runtime.is_berserk = false;
    }

    if (!struct_exists(global.game_runtime, "stage_frame")) {
        global.game_runtime.stage_frame = 0;
    }

    if (!struct_exists(global.game_runtime, "stage_complete")) {
        global.game_runtime.stage_complete = false;
    }

    if (!struct_exists(global.game_runtime, "run_started_recorded")) {
        global.game_runtime.run_started_recorded = false;
    }

    return true;
}

/// @func GameRunShipIdGet()
/// Returns the active run ship id, defaulting to ship_A when unset.
function GameRunShipIdGet() {
    var _ship_id = "ship_A";

    if (variable_global_exists("game_runtime") && struct_exists(global.game_runtime, "selected_ship_id")
        && global.game_runtime.selected_ship_id != "") {
        _ship_id = global.game_runtime.selected_ship_id;
    }

    return _ship_id;
}

/// @func GameRunStartInitialize()
/// Initializes gameplay runtime state when rm_game begins a run.
function GameRunStartInitialize() {
    if (!GameRuntimeGameplayEnsure()) {
        return false;
    }

    if (global.game_runtime.selected_ship_id == "") {
        global.game_runtime.selected_ship_id = "ship_A";
        global.game_runtime.selected_ship_index = 0;
    }

    global.game_runtime.signals.continue_request = false;
    global.game_runtime.continue_screen = GameContinueStateCreate();
    global.game_runtime.stage_frame = 0;
    global.game_runtime.stage_complete = false;
    global.game_runtime.meter = clamp(global.game_runtime.meter, 0, METER_MAX);
    global.game_runtime.is_berserk = false;

    if (!global.game_runtime.run_started_recorded) {
        var _ship_id = GameRunShipIdGet();
        GameSaveShipEntriesEnsure(_ship_id);

        var _runs_started = global.game_save.runs_started[$ _ship_id];
        _runs_started[0] += 1;
        global.game_save.runs_started[$ _ship_id] = _runs_started;
        global.game_runtime.run_started_recorded = true;

        SaveGameSave();
    }

    return true;
}

/// @func GameGameplayIsFrozen()
/// Returns whether gameplay actors should suspend motion and attacks this frame.
function GameGameplayIsFrozen() {
    if (!GameRuntimeGameplayEnsure()) {
        return false;
    }

    return global.game_runtime.signals.dialogue || global.game_runtime.signals.continue_request;
}

/// @func GameSceneStateCreate()
/// Creates the state owned by obj_scene_manager for scroll and camera control.
function GameSceneStateCreate() {
    return {
        home_x: CAMERA_HOME_X,
        camera_x: CAMERA_HOME_X,
        camera_y: CAMERA_HOME_Y,
        target_x: CAMERA_HOME_X,
        scroll_speed: CAMERA_SCROLL_SPEED,
        frame: 0,
        stage_length_frames: STAGE_LENGTH_FRAMES,
    };
}

/// @func GameSceneStageAdvance(state)
/// Advances the stage scroll and returns the next room when the stage ends.
function GameSceneStageAdvance(_state) {
    _state.frame += 1;
    _state.camera_y -= _state.scroll_speed;

    global.game_runtime.stage_frame = _state.frame;

    if (_state.frame >= _state.stage_length_frames) {
        global.game_runtime.stage_complete = true;
        return rm_ending;
    }

    return -1;
}

/// @func GameSceneFieldRectGet(camera_x, camera_y)
/// Returns the current playable field bounds around the camera.
function GameSceneFieldRectGet(_camera_x, _camera_y) {
    return {
        left: _camera_x - PLAYFIELD_HALF_WIDTH,
        right: _camera_x + PLAYFIELD_HALF_WIDTH,
        top: _camera_y - PLAYFIELD_HALF_HEIGHT,
        bottom: _camera_y + PLAYFIELD_HALF_HEIGHT,
    };
}

/// @func GameScenePlayerClampPosition(camera_x, camera_y, x, y)
/// Clamps a point to the current playable field.
function GameScenePlayerClampPosition(_camera_x, _camera_y, _x, _y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        x: clamp(_x, _field.left, _field.right),
        y: clamp(_y, _field.top + PLAYFIELD_VERTICAL_PADDING, _field.bottom - PLAYFIELD_VERTICAL_PADDING),
    };
}

/// @func GameSceneCameraTargetXGet(home_x, camera_x, player_x)
/// Returns the horizontal camera target after applying edge drag rules.
function GameSceneCameraTargetXGet(_home_x, _camera_x, _player_x) {
    var _drag_left = _camera_x - (PLAYFIELD_HALF_WIDTH - CAMERA_DRAG_MARGIN);
    var _drag_right = _camera_x + (PLAYFIELD_HALF_WIDTH - CAMERA_DRAG_MARGIN);
    var _target_x = _camera_x;

    if (_player_x < _drag_left) {
        _target_x -= (_drag_left - _player_x);
    }

    if (_player_x > _drag_right) {
        _target_x += (_player_x - _drag_right);
    }

    return clamp(_target_x, _home_x - CAMERA_DRAG_LIMIT, _home_x + CAMERA_DRAG_LIMIT);
}

/// @func GameScenePlayerRespawnPositionGet(camera_x, camera_y)
/// Returns the default respawn point near the bottom-center of the field.
function GameScenePlayerRespawnPositionGet(_camera_x, _camera_y) {
    return {
        x: _camera_x,
        y: _camera_y + PLAYER_RESPAWN_OFFSET_Y,
    };
}

/// @func GameSceneSampleEnemySpawnPositionGet(camera_x, camera_y)
/// Returns a visible top-lane spawn point for the sample enemy.
function GameSceneSampleEnemySpawnPositionGet(_camera_x, _camera_y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        x: _camera_x,
        y: _field.top + 72,
    };
}

/// @func GameGameplayInputSnapshotCreate()
/// Creates a snapshot struct for gameplay and continue-menu input.
function GameGameplayInputSnapshotCreate() {
    return {
        up_down: false,
        up_pressed: false,
        down_down: false,
        down_pressed: false,
        left_down: false,
        right_down: false,
        fire_down: false,
        fire_pressed: false,
        autofire_down: false,
        autofire_pressed: false,
        bomb_down: false,
        bomb_pressed: false,
    };
}

/// @func GameGameplayInputSnapshotRead()
/// Reads the current gameplay input verbs into one snapshot struct.
function GameGameplayInputSnapshotRead() {
    var _input = GameGameplayInputSnapshotCreate();

    _input.up_down = GameInputVerbDown("up");
    _input.up_pressed = GameInputVerbPressed("up");
    _input.down_down = GameInputVerbDown("down");
    _input.down_pressed = GameInputVerbPressed("down");
    _input.left_down = GameInputVerbDown("left");
    _input.right_down = GameInputVerbDown("right");
    _input.fire_down = GameInputVerbDown("fire");
    _input.fire_pressed = GameInputVerbPressed("fire");
    _input.autofire_down = GameInputVerbDown("autofire");
    _input.autofire_pressed = GameInputVerbPressed("autofire");
    _input.bomb_down = GameInputVerbDown("bomb");
    _input.bomb_pressed = GameInputVerbPressed("bomb");

    return _input;
}

/// @func GamePlayerStateCreate()
/// Creates the local state container used by obj_player.
function GamePlayerStateCreate() {
    return {
        hit: false,
        death_timer: 0,
        invuln_timer: INVULN_TIME,
        fire_hold_frames: 0,
        volley_queue: 0,
        volley_timer: 0,
        sweep_frame: 0,
        sword_pose: undefined,
    };
}

/// @func GameShotSpecCreate(x, y, direction, speed, sprite_id)
/// Creates one normalized shot spawn specification.
function GameShotSpecCreate(_x, _y, _direction, _speed, _sprite_id) {
    return {
        x: _x,
        y: _y,
        direction: _direction,
        speed: _speed,
        sprite_id: _sprite_id,
    };
}

/// @func GamePlayerShotPairWrite(shots, index, center_x, center_y, direction, sprite_id)
/// Writes one mirrored pair of shots into a shot specification array.
function GamePlayerShotPairWrite(_shots, _index, _center_x, _center_y, _direction, _sprite_id) {
    var _perpendicular = _direction + 90;
    var _offset_x = lengthdir_x(2.5, _perpendicular);
    var _offset_y = lengthdir_y(2.5, _perpendicular);

    _shots[_index] = GameShotSpecCreate(_center_x - _offset_x, _center_y - _offset_y, _direction, SHOT_SPEED, _sprite_id);
    _shots[_index + 1] = GameShotSpecCreate(_center_x + _offset_x, _center_y + _offset_y, _direction, SHOT_SPEED, _sprite_id);
}

/// @func GamePlayerShotSpawnSpecsCreate(x, y)
/// Returns the twelve shot specifications produced by one queued volley tick.
function GamePlayerShotSpawnSpecsCreate(_x, _y) {
    var _shots = array_create(12);
    var _index = 0;

    GamePlayerShotPairWrite(_shots, _index, _x - 26, _y - 12, 100, SHOT_SPRITE_SIDE);
    _index += 2;
    GamePlayerShotPairWrite(_shots, _index, _x + 26, _y - 12, 80, SHOT_SPRITE_SIDE);
    _index += 2;
    GamePlayerShotPairWrite(_shots, _index, _x - 24, _y - 30, 90, SHOT_SPRITE_FRONT);
    _index += 2;
    GamePlayerShotPairWrite(_shots, _index, _x - 8, _y - 36, 90, SHOT_SPRITE_FRONT);
    _index += 2;
    GamePlayerShotPairWrite(_shots, _index, _x + 8, _y - 36, 90, SHOT_SPRITE_FRONT);
    _index += 2;
    GamePlayerShotPairWrite(_shots, _index, _x + 24, _y - 30, 90, SHOT_SPRITE_FRONT);

    return _shots;
}

/// @func GamePlayerSwordPeriodFramesGet(is_berserk)
/// Returns the full sword sweep cycle length in frames.
function GamePlayerSwordPeriodFramesGet(_is_berserk) {
    if (_is_berserk) {
        return max(1, floor(SWEEP_PERIOD_FRAMES * 0.5));
    }

    return SWEEP_PERIOD_FRAMES;
}

/// @func GameCosineEase01(value)
/// Returns a cosine-biased ease value between 0 and 1.
function GameCosineEase01(_value) {
    return (1 - dcos(_value * 180)) * 0.5;
}

/// @func GamePlayerSwordPoseCreate(frame, is_berserk)
/// Returns the sword angle, length, and movement state for one sweep frame.
function GamePlayerSwordPoseCreate(_frame, _is_berserk) {
    var _period = GamePlayerSwordPeriodFramesGet(_is_berserk);
    var _phase = (_frame mod _period) / _period;
    var _angle = SWORD_START_ANGLE;
    var _moving = false;

    if (_phase < 0.25) {
        _angle = SWORD_START_ANGLE;
    } else if (_phase < 0.5) {
        _moving = true;
        _angle = lerp(SWORD_START_ANGLE, SWORD_END_ANGLE, GameCosineEase01((_phase - 0.25) / 0.25));
    } else if (_phase < 0.75) {
        _angle = SWORD_END_ANGLE;
    } else {
        _moving = true;
        _angle = lerp(SWORD_END_ANGLE, SWORD_START_ANGLE, GameCosineEase01((_phase - 0.75) / 0.25));
    }

    return {
        angle: _angle,
        length: SWORD_LENGTH * (_is_berserk ? BERSERK_SWORD_MULTIPLIER : 1),
        moving: _moving,
    };
}

/// @func GameAngleNormalizeAround(angle, reference)
/// Normalizes an angle around a nearby reference angle for range comparisons.
function GameAngleNormalizeAround(_angle, _reference) {
    while (_angle - _reference > 180) {
        _angle -= 360;
    }

    while (_angle - _reference < -180) {
        _angle += 360;
    }

    return _angle;
}

/// @func GamePlayerSwordShouldCancelBullet(player_x, player_y, bullet_x, bullet_y, previous_pose, current_pose)
/// Returns whether a bullet lies inside the swept sword arc segment this frame.
function GamePlayerSwordShouldCancelBullet(_player_x, _player_y, _bullet_x, _bullet_y, _previous_pose, _current_pose) {
    if (_previous_pose == undefined || _current_pose == undefined) {
        return false;
    }

    if (!_previous_pose.moving && !_current_pose.moving) {
        return false;
    }

    var _distance = point_distance(_player_x, _player_y, _bullet_x, _bullet_y);
    var _max_length = max(_previous_pose.length, _current_pose.length);

    if (_distance > _max_length) {
        return false;
    }

    var _bullet_angle = point_direction(_player_x, _player_y, _bullet_x, _bullet_y);
    var _range_min = min(_previous_pose.angle, _current_pose.angle);
    var _range_max = max(_previous_pose.angle, _current_pose.angle);

    while (_bullet_angle < _range_min) {
        _bullet_angle += 360;
    }

    while (_bullet_angle > _range_max) {
        _bullet_angle -= 360;
    }

    return _bullet_angle >= _range_min && _bullet_angle <= _range_max;
}

/// @func GameMedalRewardCreate(is_berserk)
/// Returns the score and meter reward carried by a cancelled bullet medal.
function GameMedalRewardCreate(_is_berserk) {
    return {
        score_value: CANCEL_BONUS * (_is_berserk ? 10 : 1),
        meter_value: _is_berserk ? 0 : CANCEL_METER,
    };
}

/// @func GameBulletCancelMark(bullet_id, is_berserk)
/// Marks a bullet for cancellation and records the medal reward it should drop.
function GameBulletCancelMark(_bullet_id, _is_berserk) {
    if (!instance_exists(_bullet_id)) {
        return false;
    }

    with (_bullet_id) {
        if (cancelled) {
            exit;
        }

        var _reward = GameMedalRewardCreate(_is_berserk);
        cancelled = true;
        medal_score_value = _reward.score_value;
        medal_meter_value = _reward.meter_value;
    }

    return true;
}

/// @func GameBulletsCancelAll(is_berserk)
/// Marks every active enemy bullet for cancellation.
function GameBulletsCancelAll(_is_berserk) {
    with (obj_bullet_parent) {
        GameBulletCancelMark(id, _is_berserk);
    }
}

/// @func GamePlayerMeterRewardApply(meter_amount)
/// Adds to the cancel meter and returns whether berserk just started.
function GamePlayerMeterRewardApply(_meter_amount) {
    GameRuntimeGameplayEnsure();

    if (global.game_runtime.is_berserk) {
        return false;
    }

    global.game_runtime.meter = clamp(global.game_runtime.meter + _meter_amount, 0, METER_MAX);

    if (global.game_runtime.meter >= METER_MAX) {
        global.game_runtime.is_berserk = true;
        return true;
    }

    return false;
}

/// @func GamePlayerBerserkDrainStep()
/// Drains the berserk meter and returns whether berserk just ended.
function GamePlayerBerserkDrainStep() {
    GameRuntimeGameplayEnsure();

    if (!global.game_runtime.is_berserk) {
        return false;
    }

    global.game_runtime.meter = max(0, global.game_runtime.meter - 1);

    if (global.game_runtime.meter <= 0) {
        global.game_runtime.is_berserk = false;
        return true;
    }

    return false;
}

/// @func GameContinueStateStep(state, input)
/// Advances the continue prompt and returns continue/game_over actions.
function GameContinueStateStep(_state, _input) {
    var _action = "none";

    if (_state.mode == "prompt") {
        if (_input.up_pressed || _input.down_pressed) {
            _state.selected_index = 1 - _state.selected_index;
        }

        if (_input.fire_pressed) {
            if (_state.selected_index == CONTINUE_OPTION_YES) {
                _action = "continue";
            } else {
                _state.mode = "game_over";
                _state.game_over_timer = GAME_OVER_DELAY_FRAMES;
            }
        }

        return _action;
    }

    if (_state.game_over_timer > 0) {
        _state.game_over_timer -= 1;
    }

    if (_state.game_over_timer <= 0) {
        _action = "game_over";
    }

    return _action;
}

/// @func GamePlayerRespawnStateApply(state)
/// Resets a player state to its live and invulnerable spawn condition.
function GamePlayerRespawnStateApply(_state) {
    _state.hit = false;
    _state.death_timer = 0;
    _state.invuln_timer = INVULN_TIME;
    _state.fire_hold_frames = 0;
    _state.volley_queue = 0;
    _state.volley_timer = 0;
    _state.sweep_frame = 0;
    _state.sword_pose = GamePlayerSwordPoseCreate(0, false);
}

/// @func GamePlayerDeathBegin(state)
/// Starts the player death state and subtracts one life.
function GamePlayerDeathBegin(_state) {
    if (_state.hit || _state.invuln_timer > 0) {
        return false;
    }

    _state.hit = true;
    _state.death_timer = PLAYER_DEATH_ANIMATION_FRAMES;
    global.game_runtime.lives = max(0, global.game_runtime.lives - 1);

    return true;
}

/// @func GamePlayerContinueRequestBegin()
/// Raises the runtime continue-request signal and resets the prompt state.
function GamePlayerContinueRequestBegin() {
    GameRuntimeGameplayEnsure();

    global.game_runtime.signals.continue_request = true;
    global.game_runtime.continue_screen = GameContinueStateCreate();
}

/// @func GamePlayerContinueAccept(state, camera_x, camera_y)
/// Applies the Continue=Yes result and returns the respawn coordinates.
function GamePlayerContinueAccept(_state, _camera_x, _camera_y) {
    GameRuntimeGameplayEnsure();

    global.game_runtime.continues_used += 1;
    global.game_runtime.lives = DEFAULT_LIVES;
    global.game_runtime.bombs = DEFAULT_BOMBS;
    global.game_runtime.meter = 0;
    global.game_runtime.is_berserk = false;
    global.game_runtime.signals.continue_request = false;
    global.game_runtime.continue_screen = GameContinueStateCreate();

    GamePlayerRespawnStateApply(_state);
    return GameScenePlayerRespawnPositionGet(_camera_x, _camera_y);
}

/// @func GamePlayerGameOverBegin()
/// Moves the continue prompt into its game-over countdown mode.
function GamePlayerGameOverBegin() {
    GameRuntimeGameplayEnsure();

    global.game_runtime.continue_screen.mode = "game_over";
    global.game_runtime.continue_screen.game_over_timer = GAME_OVER_DELAY_FRAMES;
}

/// @func GamePlayerGameOverFinalize()
/// Saves the run result, resets runtime state, and returns to the title room.
function GamePlayerGameOverFinalize() {
    GameRunResultSave();
    GameRuntimeReset();
    room_goto(rm_title);
}

/// @func GamePlayerFireStep(state, input)
/// Advances the player fire state and returns volley and sword actions for this frame.
function GamePlayerFireStep(_state, _input) {
    var _result = {
        spawn_shots: false,
        shot_specs: [],
        previous_pose: undefined,
        current_pose: undefined,
        sword_active: false,
    };
    var _use_sword = false;

    if (global.game_runtime.is_berserk) {
        _state.fire_hold_frames = FIRE_HOLD_FRAMES + 1;
    } else if (_input.fire_down) {
        _state.fire_hold_frames += 1;
    } else {
        _state.fire_hold_frames = 0;
    }

    _use_sword = global.game_runtime.is_berserk || (_input.fire_down && _state.fire_hold_frames > FIRE_HOLD_FRAMES);

    if (_use_sword) {
        var _period = GamePlayerSwordPeriodFramesGet(global.game_runtime.is_berserk);

        _state.volley_queue = 0;
        _state.volley_timer = 0;
        _result.previous_pose = GamePlayerSwordPoseCreate(_state.sweep_frame, global.game_runtime.is_berserk);
        _state.sweep_frame = (_state.sweep_frame + 1) mod _period;
        _result.current_pose = GamePlayerSwordPoseCreate(_state.sweep_frame, global.game_runtime.is_berserk);
        _state.sword_pose = _result.current_pose;
        _result.sword_active = true;

        return _result;
    }

    _state.sweep_frame = 0;
    _state.sword_pose = GamePlayerSwordPoseCreate(0, false);

    if (_input.fire_pressed || _input.autofire_down || _input.autofire_pressed) {
        _state.volley_queue = SHOT_VOLLEY_SIZE;
    }

    if (_state.volley_queue > 0) {
        _state.volley_timer += 1;

        if (_state.volley_timer >= SHOT_VOLLEY_INTERVAL) {
            _state.volley_timer = 0;
            _state.volley_queue -= 1;
            _result.spawn_shots = true;
        }
    } else {
        _state.volley_timer = 0;
    }

    return _result;
}

/// @func GameCameraViewApply(x, y)
/// Applies a camera object's position to the active room view.
function GameCameraViewApply(_x, _y) {
    if (!view_enabled) {
        return false;
    }

    var _camera = view_camera[0];
    if (_camera == -1) {
        return false;
    }

    camera_set_view_pos(_camera, round(_x - GAME_VIEW_HALF_WIDTH), round(_y - GAME_VIEW_HALF_HEIGHT));
    return true;
}

/// @func GameGameplayHudLayoutCreate()
/// Returns the GUI-space playfield gutters and HUD anchor positions.
function GameGameplayHudLayoutCreate() {
    var _playfield_left = GAME_VIEW_HALF_WIDTH - PLAYFIELD_HALF_WIDTH;
    var _playfield_right = GAME_VIEW_HALF_WIDTH + PLAYFIELD_HALF_WIDTH;

    return {
        playfield_left: _playfield_left,
        playfield_right: _playfield_right,
        left_panel_left: 0,
        left_panel_right: _playfield_left,
        right_panel_left: _playfield_right,
        right_panel_right: GAME_VIEW_WIDTH,
        panel_padding: 16,
        line_height: 20,
        meter_left: _playfield_right + 16,
        meter_top: 74,
        meter_width: GAME_VIEW_WIDTH - _playfield_right - 32,
        meter_height: 14,
        sidebar_color: make_color_rgb(44, 14, 74),
        sidebar_alpha: 0.62,
    };
}

/// @func GameGameplayHudLinesCreate()
/// Returns the current HUD label strings for lives, bombs, score, and meter.
function GameGameplayHudLinesCreate() {
    GameRuntimeGameplayEnsure();

    var _meter_label = "Meter: " + string(global.game_runtime.meter) + "/" + string(METER_MAX);
    if (global.game_runtime.is_berserk) {
        _meter_label = "Meter: BERSERK " + string(global.game_runtime.meter) + "/" + string(METER_MAX);
    }

    return [
        "Lives: " + string(global.game_runtime.lives),
        "Bombs: " + string(global.game_runtime.bombs),
        "Score: " + string(global.game_runtime.score),
        _meter_label,
    ];
}

/// @func GamePlayerBulletHitCheck(player_x, player_y, bullet_x, bullet_y, bullet_collision_radius)
/// Returns whether a bullet collision circle overlaps the player's 2x2 center hitbox.
function GamePlayerBulletHitCheck(_player_x, _player_y, _bullet_x, _bullet_y, _bullet_collision_radius) {
    return point_distance(_player_x, _player_y, _bullet_x, _bullet_y) <= (_bullet_collision_radius + 1);
}

/// @func GameSampleEnemyShotSpecCreate(enemy_x, enemy_y, player_x, player_y)
/// Returns the direct-fire bead shot spawned by the sample enemy.
function GameSampleEnemyShotSpecCreate(_enemy_x, _enemy_y, _player_x, _player_y) {
    return {
        x: _enemy_x,
        y: _enemy_y,
        direction: point_direction(_enemy_x, _enemy_y, _player_x, _player_y),
        speed: SAMPLE_ENEMY_BULLET_SPEED,
        object_index: obj_bullet_bead,
    };
}

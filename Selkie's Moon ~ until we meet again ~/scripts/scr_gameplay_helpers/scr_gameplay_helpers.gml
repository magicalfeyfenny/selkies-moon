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
#macro STAGE_SPAWN_ABOVE_VIEW 100
#macro STAGE_SPAWN_SIDE_MARGIN 16
#macro STAGE_BEE_WAVE_COUNT 3

#macro PLAYER_MOVE_SPEED 4
#macro PLAYER_RESPAWN_OFFSET_Y 120
#macro PLAYER_DEATH_ANIMATION_FRAMES 45
#macro BOMB_DURATION_FRAMES 60
#macro BOMB_VISUAL_MAX_RADIUS 220

#macro SHOT_SPEED 13
#macro PLAYER_SHOT_DAMAGE 1
#macro SWORD_SWEEP_SHOT_EQUIVALENT 20
#macro SWORD_SWEEP_DAMAGE (PLAYER_SHOT_DAMAGE * SWORD_SWEEP_SHOT_EQUIVALENT)
#macro SHOT_VOLLEY_SIZE 6
#macro SHOT_VOLLEY_INTERVAL 3
#macro FIRE_HOLD_FRAMES 60
#macro SHOT_SPRITE_FRONT spr_sunrise_bullet
#macro SHOT_SPRITE_SIDE spr_sunset_bullet
#macro TURRET_FIRE_INTERVAL 60
#macro TURRET_BULLET_SPEED 3.5
#macro BEE_MOVE_SPEED 1
#macro BEE_FIRE_INTERVAL 6
#macro BEE_BULLET_SPEED 4
#macro BEE_BULLET_SPEED_DELTA 0.5

#macro MAYFLY_PATTERN_PERIOD 20
#macro MAYFLY_SECOND_BURST_DELAY 3
#macro MAYFLY_BURST_COUNT 12
#macro MAYFLY_BLADE_TURN_SPEED 12
#macro MAYFLY_BLADE_RADIAL_SPEED 1.5
#macro MAYFLY_FLOAT_X_RADIUS 42
#macro MAYFLY_FLOAT_Y_RADIUS 14
#macro MAYFLY_FLOAT_RATE 3
#macro MAYFLY_VISIBLE_Y 100
#macro MAYFLY_DROP_SPEED 3

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

#macro STAGE_LENGTH_FRAMES 3600
#macro BOSS_PHASE_COUNT 3
#macro BOSS_PHASE_HP 300
#macro BOSS_DESTRUCTION_FRAMES 90
#macro BOSS_FAST_MAYFLY_TURN_SPEED 16
#macro BOSS_FAST_MAYFLY_RADIAL_SPEED 2.25
#macro BOSS_BEE_PATTERN_INTERVAL 30
#macro BOSS_PHASE2_SCATTER_PERIOD 30
#macro BOSS_PHASE2_BREAK_FRAMES 10
#macro BOSS_PHASE2_SHOTS_PER_FRAME 2
#macro BOSS_PHASE2_BEAD_SPEED 4.25
#macro BOSS_PHASE3_REDIRECT_INTERVAL 300
#macro BOSS_PHASE3_FREEZE_FRAMES 5
#macro BOSS_PHASE3_REDIRECT_SPEED 1.5
#macro BOSS_PHASE3_REDIRECT_ACCELERATION 0.05

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

    if (!struct_exists(global.game_runtime, "bomb_active")) {
        global.game_runtime.bomb_active = false;
    }

    if (!struct_exists(global.game_runtime, "bomb_timer")) {
        global.game_runtime.bomb_timer = 0;
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
    global.game_runtime.bomb_active = false;
    global.game_runtime.bomb_timer = 0;

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
        mode: "scroll",
        boss_spawned: false,
        boss_defeated: false,
    };
}

/// @func GameSceneStageAdvance(state)
/// Advances the stage scroll and returns a scene action when the scroll section ends.
function GameSceneStageAdvance(_state) {
    if (_state.mode != "scroll") {
        return "none";
    }

    _state.frame += 1;
    _state.camera_y -= _state.scroll_speed;

    global.game_runtime.stage_frame = _state.frame;

    if (_state.frame >= _state.stage_length_frames) {
        _state.mode = "boss_intro";
        _state.scroll_speed = 0;
        return "boss_intro";
    }

    return "none";
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

/// @func GameSceneTurretSpawnPositionGet(camera_x, camera_y)
/// Returns a visible top-lane spawn point for the starter turret enemy.
function GameSceneTurretSpawnPositionGet(_camera_x, _camera_y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        x: _camera_x,
        y: _field.top + 72,
    };
}

/// @func GameSceneBeeSpawnPositionGet(camera_x, camera_y)
/// Returns a visible upper-lane spawn point for the starter bee enemy.
function GameSceneBeeSpawnPositionGet(_camera_x, _camera_y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        x: _field.left + 40,
        y: _field.top + 96,
    };
}

/// @func GameSceneMayflySpawnPositionGet(camera_x, camera_y)
/// Returns a visible upper-lane anchor point for the mayfly enemy.
function GameSceneMayflySpawnPositionGet(_camera_x, _camera_y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        x: _camera_x,
        y: _field.top + MAYFLY_VISIBLE_Y,
    };
}

/// @func GameSceneBossSpawnPositionGet(camera_x, camera_y)
/// Returns a visible anchor point for the boss encounter.
function GameSceneBossSpawnPositionGet(_camera_x, _camera_y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        x: _camera_x,
        y: _field.top + 84,
    };
}

/// @func GameStageSpawnBandRectGet(camera_x, camera_y)
/// Returns the horizontal spawn band used for timeline enemies above the visible field.
function GameStageSpawnBandRectGet(_camera_x, _camera_y) {
    var _field = GameSceneFieldRectGet(_camera_x, _camera_y);

    return {
        left: _field.left + STAGE_SPAWN_SIDE_MARGIN,
        right: _field.right - STAGE_SPAWN_SIDE_MARGIN,
        y: _field.top - STAGE_SPAWN_ABOVE_VIEW,
    };
}

/// @func GameStageRandomSpawnXGet(left, right)
/// Returns one random horizontal position within the stage spawn band.
function GameStageRandomSpawnXGet(_left, _right) {
    return irandom_range(round(_left), round(_right));
}

/// @func GameStageTurretSpawnPositionCreate(camera_x, camera_y)
/// Returns one turret spawn point above the visible play area.
function GameStageTurretSpawnPositionCreate(_camera_x, _camera_y) {
    var _band = GameStageSpawnBandRectGet(_camera_x, _camera_y);

    return {
        x: GameStageRandomSpawnXGet(_band.left, _band.right),
        y: _band.y,
    };
}

/// @func GameStageBeeSpawnPositionsCreate(camera_x, camera_y)
/// Returns three horizontally scattered bee spawn points above the visible play area.
function GameStageBeeSpawnPositionsCreate(_camera_x, _camera_y) {
    var _band = GameStageSpawnBandRectGet(_camera_x, _camera_y);
    var _positions = array_create(STAGE_BEE_WAVE_COUNT);
    var _span = _band.right - _band.left;
    var _slice_width = _span / max(1, STAGE_BEE_WAVE_COUNT);

    for (var i = 0; i < STAGE_BEE_WAVE_COUNT; i++) {
        var _slice_left = _band.left + (_slice_width * i);
        var _slice_right = _slice_left + _slice_width;

        _positions[i] = {
            x: GameStageRandomSpawnXGet(_slice_left, _slice_right),
            y: _band.y,
        };
    }

    return _positions;
}

/// @func GameStageMayflySpawnPositionCreate(camera_x, camera_y)
/// Returns one random mayfly spawn point above the visible play area.
function GameStageMayflySpawnPositionCreate(_camera_x, _camera_y) {
    return GameStageTurretSpawnPositionCreate(_camera_x, _camera_y);
}

/// @func GameStageTimelineTurretSpawn(camera_x, camera_y)
/// Spawns one turret from the active stage timeline.
function GameStageTimelineTurretSpawn(_camera_x, _camera_y) {
    var _spawn = GameStageTurretSpawnPositionCreate(_camera_x, _camera_y);
    return instance_create_layer(_spawn.x, _spawn.y, "Instances", obj_enemy_turret);
}

/// @func GameStageTimelineBeeWaveSpawn(camera_x, camera_y)
/// Spawns one three-bee wave from the active stage timeline.
function GameStageTimelineBeeWaveSpawn(_camera_x, _camera_y) {
    var _positions = GameStageBeeSpawnPositionsCreate(_camera_x, _camera_y);
    var _count = array_length(_positions);

    for (var i = 0; i < _count; i++) {
        instance_create_layer(_positions[i].x, _positions[i].y, "Instances", obj_enemy_bee);
    }

    return _count;
}

/// @func GameStageTimelineMayflySpawn(camera_x, camera_y)
/// Spawns one mayfly from the active stage timeline.
function GameStageTimelineMayflySpawn(_camera_x, _camera_y) {
    var _spawn = GameStageMayflySpawnPositionCreate(_camera_x, _camera_y);
    return instance_create_layer(_spawn.x, _spawn.y, "Instances", obj_enemy_mayfly);
}

/// @func GameStageTimelineShouldRun(state)
/// Returns whether the stage timeline should currently advance.
function GameStageTimelineShouldRun(_state) {
    return !GameGameplayIsFrozen() && _state.mode == "scroll";
}

/// @func GameSceneCombatClear()
/// Removes active non-player combat actors before the boss encounter begins.
function GameSceneCombatClear() {
    with (obj_enemy_parent) {
        instance_destroy();
    }

    with (obj_bullet_parent) {
        instance_destroy();
    }

    with (obj_medal) {
        instance_destroy();
    }

    with (obj_player_shot) {
        instance_destroy();
    }
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
        bomb_timer: 0,
        fire_hold_frames: 0,
        volley_queue: 0,
        volley_timer: 0,
        sweep_frame: 0,
        sword_pose: undefined,
        sword_sweep_id: 0,
    };
}

/// @func GameMayflyTargetAnchorOffsetYGet()
/// Returns the camera-relative anchor offset that keeps mayflies near y=100 in view.
function GameMayflyTargetAnchorOffsetYGet() {
    return -PLAYFIELD_HALF_HEIGHT + MAYFLY_VISIBLE_Y;
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
    _state.bomb_timer = 0;
    _state.fire_hold_frames = 0;
    _state.volley_queue = 0;
    _state.volley_timer = 0;
    _state.sweep_frame = 0;
    _state.sword_pose = GamePlayerSwordPoseCreate(0, false);
    _state.sword_sweep_id = 0;

    GamePlayerBombStateSync(_state);
}

/// @func GamePlayerDeathBegin(state)
/// Starts the player death state and subtracts one life.
function GamePlayerDeathBegin(_state) {
    if (_state.hit || GamePlayerIsInvulnerable(_state)) {
        return false;
    }

    GamePlayerHitSoundPlay();
    _state.hit = true;
    _state.death_timer = PLAYER_DEATH_ANIMATION_FRAMES;
    global.game_runtime.lives = max(0, global.game_runtime.lives - 1);

    return true;
}

/// @func GamePlayerBombStateSync(state)
/// Mirrors the local bomb timer onto the shared runtime state.
function GamePlayerBombStateSync(_state) {
    if (!GameRuntimeGameplayEnsure()) {
        return false;
    }

    global.game_runtime.bomb_timer = max(0, _state.bomb_timer);
    global.game_runtime.bomb_active = (_state.bomb_timer > 0);
    return global.game_runtime.bomb_active;
}

/// @func GamePlayerBombActiveGet()
/// Returns whether a player bomb is currently active.
function GamePlayerBombActiveGet() {
    if (!GameRuntimeGameplayEnsure()) {
        return false;
    }

    return global.game_runtime.bomb_active;
}

/// @func GamePlayerBombIsActive(state)
/// Returns whether the local player state is inside an active bomb animation.
function GamePlayerBombIsActive(_state) {
    return _state.bomb_timer > 0;
}

/// @func GamePlayerIsInvulnerable(state)
/// Returns whether the player should ignore bullet hits this frame.
function GamePlayerIsInvulnerable(_state) {
    return _state.invuln_timer > 0 || GamePlayerBombIsActive(_state);
}

/// @func GamePlayerBombTryStart(state)
/// Starts a player bomb when stock is available and no bomb is already active.
function GamePlayerBombTryStart(_state) {
    GameRuntimeGameplayEnsure();

    if (_state.hit || GamePlayerBombIsActive(_state) || global.game_runtime.bombs <= 0) {
        return false;
    }

    global.game_runtime.bombs -= 1;
    _state.bomb_timer = BOMB_DURATION_FRAMES;
    GamePlayerBombStateSync(_state);
    GameBulletsCancelAll(global.game_runtime.is_berserk);
    return true;
}

/// @func GamePlayerBombStep(state)
/// Advances the bomb timer and keeps cancelling bullets while it remains active.
function GamePlayerBombStep(_state) {
    if (!GamePlayerBombIsActive(_state)) {
        GamePlayerBombStateSync(_state);
        return false;
    }

    GameBulletsCancelAll(global.game_runtime.is_berserk);
    _state.bomb_timer = max(0, _state.bomb_timer - 1);
    GamePlayerBombStateSync(_state);
    return GamePlayerBombIsActive(_state);
}

/// @func GamePlayerBombVisualCreate(timer)
/// Returns simple expanding ring parameters for the active bomb animation.
function GamePlayerBombVisualCreate(_timer) {
    var _progress = 1 - (max(0, _timer) / max(1, BOMB_DURATION_FRAMES));
    var _outer_radius = lerp(28, BOMB_VISUAL_MAX_RADIUS, _progress);
    var _inner_radius = max(12, _outer_radius - 40);

    return {
        outer_radius: _outer_radius,
        inner_radius: _inner_radius,
        fill_alpha: lerp(0.32, 0.08, _progress),
        ring_alpha: lerp(0.9, 0.25, _progress),
    };
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

/// @func GamePlayerSwordSweepIdStep(state, previous_pose, current_pose)
/// Advances the sword sweep id when a new cross-screen sword swing begins.
function GamePlayerSwordSweepIdStep(_state, _previous_pose, _current_pose) {
    var _was_moving = (_previous_pose != undefined) && _previous_pose.moving;
    var _is_moving = (_current_pose != undefined) && _current_pose.moving;

    if (_is_moving && !_was_moving) {
        _state.sword_sweep_id += 1;
    }

    return _state.sword_sweep_id;
}

/// @func GamePlayerSwordDamageTryApply(target_id, sweep_id)
/// Applies one sweep's worth of sword damage to a target only once for that sweep.
function GamePlayerSwordDamageTryApply(_target_id, _sweep_id) {
    if (!instance_exists(_target_id) || !variable_instance_exists(_target_id, "hp")) {
        return false;
    }

    if (variable_instance_exists(_target_id, "last_sword_sweep_id")
        && variable_instance_get(_target_id, "last_sword_sweep_id") == _sweep_id) {
        return false;
    }

    variable_instance_set(_target_id, "last_sword_sweep_id", _sweep_id);
    variable_instance_set(_target_id, "hp", variable_instance_get(_target_id, "hp") - SWORD_SWEEP_DAMAGE);
    return true;
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
        sweep_id: 0,
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
        _result.sweep_id = GamePlayerSwordSweepIdStep(_state, _result.previous_pose, _result.current_pose);
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
        boss_bar_left: _playfield_right + 16,
        boss_bar_top: 132,
        boss_bar_width: GAME_VIEW_WIDTH - _playfield_right - 32,
        boss_bar_height: 12,
        boss_bar_gap: 8,
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

/// @func GameTurretShotSpecCreate(enemy_x, enemy_y, player_x, player_y)
/// Returns the direct-fire bead shot spawned by the turret enemy.
function GameTurretShotSpecCreate(_enemy_x, _enemy_y, _player_x, _player_y) {
    return {
        x: _enemy_x,
        y: _enemy_y,
        direction: point_direction(_enemy_x, _enemy_y, _player_x, _player_y),
        speed: TURRET_BULLET_SPEED,
        object_index: obj_bullet_bead,
    };
}

/// @func GameBeeShotSpecCreate(enemy_x, enemy_y, player_x, player_y, speed)
/// Returns one direct-fire diamond shot specification for the bee enemy.
function GameBeeShotSpecCreate(_enemy_x, _enemy_y, _player_x, _player_y, _speed) {
    return {
        x: _enemy_x,
        y: _enemy_y,
        direction: point_direction(_enemy_x, _enemy_y, _player_x, _player_y),
        speed: _speed,
        object_index: obj_bullet_diamond,
    };
}

/// @func GameBeeShotSpawnSpecsCreate(enemy_x, enemy_y, player_x, player_y)
/// Returns the three aligned diamond shots fired by the bee enemy.
function GameBeeShotSpawnSpecsCreate(_enemy_x, _enemy_y, _player_x, _player_y) {
    return [
        GameBeeShotSpecCreate(_enemy_x, _enemy_y, _player_x, _player_y, 3.5),
        GameBeeShotSpecCreate(_enemy_x, _enemy_y, _player_x, _player_y, 4.0),
        GameBeeShotSpecCreate(_enemy_x, _enemy_y, _player_x, _player_y, 4.5),
    ];
}

/// @func GameMayflyInfinityOffsetCreate(phase)
/// Returns the current infinity-path offset for the mayfly enemy.
function GameMayflyInfinityOffsetCreate(_phase) {
    return {
        x: dsin(_phase) * MAYFLY_FLOAT_X_RADIUS,
        y: dsin(_phase * 2) * MAYFLY_FLOAT_Y_RADIUS,
    };
}

/// @func GameMayflyBurstStateCreate(timer, clockwise_first)
/// Returns whether the mayfly should fire this frame and which spiral direction leads.
function GameMayflyBurstStateCreate(_timer, _clockwise_first) {
    if (_timer == 0) {
        return {
            fire: true,
            clockwise: _clockwise_first,
        };
    }

    if (_timer == MAYFLY_SECOND_BURST_DELAY) {
        return {
            fire: true,
            clockwise: !_clockwise_first,
        };
    }

    return {
        fire: false,
        clockwise: _clockwise_first,
    };
}

/// @func GameMayflyBladeShotSpecCreate(enemy_x, enemy_y, angle, clockwise, turn_speed, radial_speed)
/// Returns one spiral blade shot specification for the mayfly enemy.
function GameMayflyBladeShotSpecCreate(_enemy_x, _enemy_y, _angle, _clockwise, _turn_speed = MAYFLY_BLADE_TURN_SPEED, _radial_speed = MAYFLY_BLADE_RADIAL_SPEED) {
    return {
        x: _enemy_x,
        y: _enemy_y,
        object_index: obj_bullet_blade,
        spiral_angle: _angle,
        spiral_direction: _clockwise ? -1 : 1,
        spiral_turn_speed: _turn_speed,
        spiral_radial_speed: _radial_speed,
    };
}

/// @func GameMayflyShotSpawnSpecsCreate(enemy_x, enemy_y, clockwise, turn_speed, radial_speed)
/// Returns one twelve-shot mayfly spiral burst.
function GameMayflyShotSpawnSpecsCreate(_enemy_x, _enemy_y, _clockwise, _turn_speed = MAYFLY_BLADE_TURN_SPEED, _radial_speed = MAYFLY_BLADE_RADIAL_SPEED) {
    var _shots = array_create(MAYFLY_BURST_COUNT);
    var _angle_step = 360 / MAYFLY_BURST_COUNT;

    for (var i = 0; i < MAYFLY_BURST_COUNT; i++) {
        _shots[i] = GameMayflyBladeShotSpecCreate(_enemy_x, _enemy_y, i * _angle_step, _clockwise, _turn_speed, _radial_speed);
    }

    return _shots;
}

/// @func GameBladeBulletRedirectMark(bullet_id, freeze_frames, redirect_speed, redirect_acceleration)
/// Queues a blade bullet to freeze, then relaunch in a random direction with acceleration.
function GameBladeBulletRedirectMark(_bullet_id, _freeze_frames, _redirect_speed, _redirect_acceleration) {
    if (!instance_exists(_bullet_id)) {
        return false;
    }

    with (_bullet_id) {
        if (redirected || redirect_pending || freeze_timer > 0) {
            exit;
        }

        freeze_timer = _freeze_frames;
        redirect_pending = true;
        redirect_speed = _redirect_speed;
        redirect_acceleration = _redirect_acceleration;
        redirect_direction = irandom(359);
        move_speed = 0;
    }

    return true;
}

/// @func GameBladeBulletsRedirectAll(freeze_frames, redirect_speed, redirect_acceleration)
/// Queues every active blade bullet to freeze and relaunch.
function GameBladeBulletsRedirectAll(_freeze_frames, _redirect_speed, _redirect_acceleration) {
    with (obj_bullet_blade) {
        GameBladeBulletRedirectMark(id, _freeze_frames, _redirect_speed, _redirect_acceleration);
    }
}

/// @func GameBossBarSegmentsCreate(phase_index, hp, phase_max_hp, phase_count)
/// Returns the current fill ratio for each segmented boss health bar slice.
function GameBossBarSegmentsCreate(_phase_index, _hp, _phase_max_hp, _phase_count = BOSS_PHASE_COUNT) {
    var _segments = array_create(_phase_count, 0);

    for (var i = 0; i < _phase_count; i++) {
        if (i < _phase_index) {
            _segments[i] = 0;
        } else if (i == _phase_index) {
            _segments[i] = clamp(_hp / max(1, _phase_max_hp), 0, 1);
        } else {
            _segments[i] = 1;
        }
    }

    return _segments;
}

/// @func GameBossPhaseTwoScatterActive(frame)
/// Returns whether the phase-two scatter attack is currently in its firing window.
function GameBossPhaseTwoScatterActive(_frame) {
    return (_frame mod BOSS_PHASE2_SCATTER_PERIOD) < (BOSS_PHASE2_SCATTER_PERIOD - BOSS_PHASE2_BREAK_FRAMES);
}

/// @func GameBossPhaseThreeRedirectDue(frame)
/// Returns whether the phase-three freeze-and-redirect event should trigger.
function GameBossPhaseThreeRedirectDue(_frame) {
    return _frame > 0 && ((_frame mod BOSS_PHASE3_REDIRECT_INTERVAL) == 0);
}

/// @func GameBossScatterShotSpecCreate(enemy_x, enemy_y)
/// Returns one random-direction bead shot specification for the boss scatter phase.
function GameBossScatterShotSpecCreate(_enemy_x, _enemy_y) {
    return {
        x: _enemy_x,
        y: _enemy_y,
        direction: irandom(359),
        speed: BOSS_PHASE2_BEAD_SPEED,
        object_index: obj_bullet_bead,
    };
}

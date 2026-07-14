// Core gameplay constants and pure/system helpers. Object events should stay
// thin and delegate reusable rules here; boss pattern execution has its own
// scr_boss_patterns module.

// View, playfield, camera, and stage flow.
#macro GAME_VIEW_WIDTH 640
#macro GAME_VIEW_HEIGHT 360
#macro GAME_VIEW_HALF_WIDTH 320
#macro GAME_VIEW_HALF_HEIGHT 180

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
#macro STAGE_COUNT 10
#macro MIRA_BOSS_STAGE 2
#macro MIRA_BOSS_NAME "Mira"
#macro MIRA_SHIP_NAME "Wildheart"
#macro SHALMII_BOSS_STAGE 5
#macro SHALMII_BOSS_NAME "Shalmii"
#macro SHALMII_SHIP_NAME "Lockstep"
#macro AISHA_BOSS_STAGE 6
#macro AISHA_BOSS_NAME "Aisha"
#macro AISHA_SHIP_NAME "Wishbound"
#macro ASTER_BOSS_STAGE 7
#macro ASTER_BOSS_NAME "Aster"
#macro ASTER_SHIP_NAME "Ribbonstar"
#macro CAELIA_BOSS_STAGE 9
#macro CAELIA_BOSS_NAME "Caelia"
#macro CAELIA_SHIP_NAME "Zenith"
#macro STAGE_NOTICE_FRAMES 150
#macro STAGE_CLEAR_DELAY_FRAMES 120

// Player movement, resources, weapons, and damage.
#macro PLAYER_MOVE_SPEED 4
#macro PLAYER_FOCUS_SPEED_MULTIPLIER 0.62
#macro PLAYER_RESPAWN_OFFSET_Y 120
#macro PLAYER_DEATH_ANIMATION_FRAMES 45
#macro BOMB_DURATION_FRAMES 60
#macro BOMB_VISUAL_MAX_RADIUS 220
#macro PLAYER_POWER_MAX 5
#macro PLAYER_LIFE_MAX 6
#macro PLAYER_BOMB_MAX 6

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

// Standard enemy behavior.
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

// Sword geometry and timing.
#macro SWEEP_PERIOD_FRAMES 48
#macro SWORD_START_ANGLE 315
#macro SWORD_END_ANGLE 585
#macro SWORD_LENGTH 128
#macro BERSERK_SWORD_MULTIPLIER 1.5

#macro INVULN_TIME 300
#macro CANCEL_BONUS 100
#macro CANCEL_METER 1
#macro METER_MAX 1000

// Continue and boss encounter flow.
#macro CONTINUE_OPTION_YES 0
#macro CONTINUE_OPTION_NO 1
#macro GAME_OVER_DELAY_FRAMES 90

#macro STAGE_LENGTH_FRAMES 2400
#macro BOSS_PHASE_COUNT 3
#macro FINAL_BOSS_PHASE_COUNT 16
#macro FINAL_BOSS_EXPANDED_PHASE_COUNT 15
#macro BOSS_PHASE_HP 300
#macro BOSS_PHASE_HP_STAGE_STEP 30
#macro BOSS_PHASE_MIN_HP 240
#macro BOSS_DAMAGE_SCALE_MIN 0.2
#macro BOSS_DESTRUCTION_FRAMES 90
#macro BOSS_PHASE3_FREEZE_FRAMES 5
#macro BOSS_PHASE3_REDIRECT_SPEED 1.5
#macro BOSS_PHASE3_REDIRECT_ACCELERATION 0.05
#macro BOSS_PHASE_NOTICE_FRAMES 120
#macro BOSS_PHASE_NOTICE_FADE_IN_FRAMES 12
#macro BOSS_PHASE_NOTICE_FADE_OUT_FRAMES 30

// Ship identities, pickups, and point-blank resource economy.
#macro SHIP_SUNRISE "ship_A"
#macro SHIP_SELKIE "ship_selkie"
#macro POWERUP_POWER "power"
#macro POWERUP_BOMB "bomb"
#macro POWERUP_LIFE "life"
#macro POWERUP_METER "meter"
#macro POWERUP_SCORE "score"
#macro POWERUP_METER_VALUE 240
#macro POWERUP_SCORE_VALUE 5000
#macro POINT_BLANK_RESOURCE_RADIUS 96
#macro RESOURCE_DROP_CHARGE_BASE 4
#macro RESOURCE_DROP_LIMIT_BASE 3
#macro SCORE_PICKUP_DROP_PERIOD_BASE 9
#macro RANK_MIN 0
#macro RANK_MAX 100
#macro RANK_DEFAULT 50
#macro RANK_PASSIVE_INTERVAL 600
#macro PRACTICE_SEGMENT_FULL "full"
#macro PRACTICE_SEGMENT_WAVES "waves"
#macro PRACTICE_SEGMENT_BOSS "boss"
#macro ENEMY_VARIANT_MOTH "moth"
#macro ENEMY_VARIANT_KELP "kelp"
#macro ENEMY_VARIANT_WISP "wisp"
#macro ENEMY_VARIANT_NEEDLE "needle"
#macro ENEMY_VARIANT_MIRROR "mirror"

/// @func GameContinueStateCreate()
/// Creates the runtime state used by the continue prompt.
function GameContinueStateCreate() {
    return {
        selected_index: CONTINUE_OPTION_YES,
        mode: "prompt",
        game_over_timer: 0,
    };
}

/// @func GamePauseStateCreate()
/// Creates the dedicated in-run pause menu state.
function GamePauseStateCreate() {
    return {
        active: false,
        page: "main",
        main_index: 0,
        options_index: 0,
        practice_index: 0,
        quit_index: 0,
        close_requested: false,
    };
}

/// @func GamePracticeConfigCreateDefault()
/// Creates the editable setup used by title practice select and live tuning.
function GamePracticeConfigCreateDefault() {
    return {
        ship_id: SHIP_SUNRISE,
        ship_index: 0,
        stage: 1,
        segment: PRACTICE_SEGMENT_FULL,
        power: 3,
        rank: RANK_DEFAULT,
        dynamic_rank: false,
        lives: DEFAULT_LIVES,
        bombs: DEFAULT_BOMBS,
        meter: 0,
    };
}

/// @func GamePracticeConfigNormalize(config)
/// Returns a complete practice setup with every exposed value kept in range.
function GamePracticeConfigNormalize(_config) {
    var _result = GamePracticeConfigCreateDefault();

    if (!is_struct(_config)) {
        return _result;
    }

    if (struct_exists(_config, "ship_id") && _config.ship_id == SHIP_SELKIE) {
        _result.ship_id = SHIP_SELKIE;
        _result.ship_index = 1;
    }

    if (struct_exists(_config, "ship_index") && round(_config.ship_index) == 1) {
        _result.ship_id = SHIP_SELKIE;
        _result.ship_index = 1;
    }

    if (struct_exists(_config, "stage") && is_real(_config.stage)) {
        _result.stage = clamp(round(_config.stage), 1, STAGE_COUNT);
    }

    if (struct_exists(_config, "segment") && (_config.segment == PRACTICE_SEGMENT_WAVES
        || _config.segment == PRACTICE_SEGMENT_BOSS)) {
        _result.segment = _config.segment;
    }

    if (struct_exists(_config, "power") && is_real(_config.power)) {
        _result.power = clamp(round(_config.power), 0, PLAYER_POWER_MAX);
    }

    if (struct_exists(_config, "rank") && is_real(_config.rank)) {
        _result.rank = clamp(round(_config.rank), RANK_MIN, RANK_MAX);
    }

    if (struct_exists(_config, "dynamic_rank") && is_bool(_config.dynamic_rank)) {
        _result.dynamic_rank = _config.dynamic_rank;
    }

    if (struct_exists(_config, "lives") && is_real(_config.lives)) {
        _result.lives = clamp(round(_config.lives), 1, PLAYER_LIFE_MAX);
    }

    if (struct_exists(_config, "bombs") && is_real(_config.bombs)) {
        _result.bombs = clamp(round(_config.bombs), 0, PLAYER_BOMB_MAX);
    }

    if (struct_exists(_config, "meter") && is_real(_config.meter)) {
        _result.meter = clamp(round(_config.meter / 100) * 100, 0, METER_MAX);
    }

    return _result;
}

/// @func GamePracticeSegmentNameGet(segment)
/// Returns the player-facing label for one selectable stage section.
function GamePracticeSegmentNameGet(_segment) {
    switch (_segment) {
        case PRACTICE_SEGMENT_WAVES: return "Waves Only";
        case PRACTICE_SEGMENT_BOSS: return "Boss";
    }

    return "Full Stage";
}

/// @func GamePauseInputSnapshotCreate(up, down, left, right, fire, bomb, pause)
/// Creates the menu-oriented input consumed by the pause state machine.
function GamePauseInputSnapshotCreate(_up = false, _down = false, _left = false, _right = false,
    _fire = false, _bomb = false, _pause = false) {
    return {
        up: _up,
        down: _down,
        left: _left,
        right: _right,
        fire: _fire,
        bomb: _bomb,
        pause: _pause,
    };
}

/// @func GamePauseInputSnapshotFromGlobal()
/// Reads keyboard/controller menu edges from the unified verb state.
function GamePauseInputSnapshotFromGlobal() {
    return GamePauseInputSnapshotCreate(
        GameInputVerbPressed("up"),
        GameInputVerbPressed("down"),
        GameInputVerbPressed("left"),
        GameInputVerbPressed("right"),
        GameInputVerbPressed("fire"),
        GameInputVerbPressed("bomb"),
        GameInputVerbPressed("pause")
    );
}

/// @func GameMenuValueWrap(value, delta, minimum, maximum)
/// Wraps one integer setting across both ends of its allowed range.
function GameMenuValueWrap(_value, _delta, _minimum, _maximum) {
    _value += _delta;
    if (_value < _minimum) return _maximum;
    if (_value > _maximum) return _minimum;
    return _value;
}

/// @func GamePauseMainItemsCreate(practice)
/// Returns pause rows, including live tuning only for practice sessions.
function GamePauseMainItemsCreate(_practice) {
    if (_practice) {
        return ["Resume", "Settings", "Practice Tuning", "Quit to Main Menu"];
    }

    return ["Resume", "Settings", "Quit to Main Menu"];
}

/// @func GamePracticeLiveEntriesCreate()
/// Returns current values exposed by the live practice tuning page.
function GamePracticeLiveEntriesCreate() {
    GameRuntimeGameplayEnsure();
    return [
        { label: "Shot Power", value: string(GamePlayerPowerGet()) + "/" + string(PLAYER_POWER_MAX) },
        { label: "Rank", value: string(GameRankGet()) + "%" },
        { label: "Dynamic Rank", value: GameRankDynamicEnabled() ? "On" : "Off" },
        { label: "Lives", value: string(global.game_runtime.lives) },
        { label: "Bombs", value: string(global.game_runtime.bombs) },
        { label: "Cancel Meter", value: string(global.game_runtime.meter) },
    ];
}

/// @func GamePracticeLiveAdjust(index, delta)
/// Changes one practice value and applies it immediately to the active run.
function GamePracticeLiveAdjust(_index, _delta) {
    GameRuntimeGameplayEnsure();
    var _practice = GamePracticeConfigNormalize(global.game_runtime.practice_config);
    var _step = (_delta < 0) ? -1 : 1;

    switch (_index) {
        case 0:
            global.game_runtime.power = GameMenuValueWrap(GamePlayerPowerGet(), _step, 0, PLAYER_POWER_MAX);
            _practice.power = global.game_runtime.power;
            break;
        case 1:
            var _rank_step_base = clamp(round(GameRankGet() / 5) * 5, RANK_MIN, RANK_MAX);
            global.game_runtime.rank = GameMenuValueWrap(_rank_step_base, _step * 5, RANK_MIN, RANK_MAX);
            _practice.rank = global.game_runtime.rank;
            break;
        case 2:
            global.game_runtime.rank_locked = !global.game_runtime.rank_locked;
            _practice.dynamic_rank = !global.game_runtime.rank_locked;
            break;
        case 3:
            global.game_runtime.lives = GameMenuValueWrap(global.game_runtime.lives, _step, 1, PLAYER_LIFE_MAX);
            _practice.lives = global.game_runtime.lives;
            break;
        case 4:
            global.game_runtime.bombs = GameMenuValueWrap(global.game_runtime.bombs, _step, 0, PLAYER_BOMB_MAX);
            _practice.bombs = global.game_runtime.bombs;
            break;
        case 5:
            var _meter_step_base = clamp(round(global.game_runtime.meter / 100) * 100, 0, METER_MAX);
            global.game_runtime.meter = GameMenuValueWrap(_meter_step_base, _step * 100, 0, METER_MAX);
            global.game_runtime.is_berserk = global.game_runtime.meter >= METER_MAX;
            _practice.meter = global.game_runtime.meter;
            break;
    }

    _practice = GamePracticeConfigNormalize(_practice);
    global.game_runtime.practice_config = _practice;
    return _practice;
}

/// @func GamePauseStateStep(state, input, practice)
/// Advances pause navigation and returns an action for the room controller.
function GamePauseStateStep(_state, _input, _practice) {
    var _result = { action: "none" };

    if (!_state.active) {
        if (_input.pause) {
            _state.active = true;
            _state.page = "main";
            _state.main_index = 0;
            _result.action = "open";
        }
        return _result;
    }

    if (_input.pause) {
        _result.action = "close";
        return _result;
    }

    switch (_state.page) {
        case "main":
            var _main_items = GamePauseMainItemsCreate(_practice);
            _state.main_index = GameMenuIndexStep(
                _state.main_index, _input.up, _input.down, array_length(_main_items));

            if (_input.bomb) {
                _result.action = "close";
            } else if (_input.fire) {
                var _label = _main_items[_state.main_index];
                if (_label == "Resume") {
                    _result.action = "close";
                } else if (_label == "Settings") {
                    _state.page = "options";
                    _state.options_index = 0;
                } else if (_label == "Practice Tuning") {
                    _state.page = "practice";
                    _state.practice_index = 0;
                } else {
                    _state.page = "quit_confirm";
                    _state.quit_index = 0;
                }
            }
            break;

        case "options":
            var _options = GameTitleConfigEntriesCreate();
            var _options_count = array_length(_options);
            _state.options_index = GameMenuIndexStep(
                _state.options_index, _input.up, _input.down, _options_count + 1);

            if (_input.bomb) {
                _state.page = "main";
            } else if (_state.options_index < _options_count && (_input.left || _input.right || _input.fire)) {
                var _delta = _input.left ? -1 : 1;
                GameTitleConfigEntryAdjust(_options[_state.options_index].id, _delta);
            } else if (_state.options_index == _options_count && _input.fire) {
                _state.page = "main";
            }
            break;

        case "practice":
            var _practice_entries = GamePracticeLiveEntriesCreate();
            var _practice_count = array_length(_practice_entries);
            var _practice_total = _practice_count + 2;
            _state.practice_index = GameMenuIndexStep(
                _state.practice_index, _input.up, _input.down, _practice_total);

            if (_input.bomb) {
                _state.page = "main";
            } else if (_state.practice_index < _practice_count && (_input.left || _input.right || _input.fire)) {
                GamePracticeLiveAdjust(_state.practice_index, _input.left ? -1 : 1);
            } else if (_state.practice_index == _practice_count && _input.fire) {
                _result.action = "restart_practice";
            } else if (_state.practice_index == _practice_count + 1 && _input.fire) {
                _state.page = "main";
            }
            break;

        case "quit_confirm":
            if (_input.left || _input.right || _input.up || _input.down) {
                _state.quit_index = 1 - _state.quit_index;
            }

            if (_input.bomb) {
                _state.page = "main";
            } else if (_input.fire) {
                if (_state.quit_index == 1) {
                    _result.action = "quit_title";
                } else {
                    _state.page = "main";
                }
            }
            break;
    }

    return _result;
}

/// @func GamePauseDrawRow(x, y, width, label, value, selected)
/// Draws one textbox-styled pause row.
function GamePauseDrawRow(_x, _y, _width, _label, _value, _selected) {
    var _style = GameTitlePanelStyleCreate(_selected);
    GameUiDrawOrnateFrame(_x, _y, _width, 26, _style.fill_color, _style.fill_alpha,
        _style.border_color, _selected);

    draw_set_font(fn_menu);
    draw_set_valign(fa_middle);
    draw_set_halign(fa_left);
    GameUiDrawOutlinedText(_label, _x + 10, _y + 14, _style.text_color);

    if (_value != "") {
        draw_set_halign(fa_right);
        GameUiDrawOutlinedText(_value, _x + _width - 10, _y + 14, _style.text_color);
    }
}

/// @func GamePauseDraw(state)
/// Draws pause, settings, practice-tuning, and quit-confirm pages over gameplay.
function GamePauseDraw(_state) {
    if (!_state.active) {
        return false;
    }

    var _palette = GameUiStoryFramePaletteCreate(false);
    draw_set_alpha(0.72);
    draw_set_color(c_black);
    draw_rectangle(0, 0, GAME_VIEW_WIDTH, GAME_VIEW_HEIGHT, false);
    draw_set_alpha(1);
    GameUiDrawOrnateFrame(126, 28, 388, 304, _palette.fill_color, 0.94,
        _palette.border_color, false);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_title);

    switch (_state.page) {
        case "main":
            GameUiDrawOutlinedText("Paused", GAME_VIEW_HALF_WIDTH, 62, _palette.title_color);
            var _items = GamePauseMainItemsCreate(GameRunIsPractice());
            var _start_y = GameRunIsPractice() ? 96 : 108;
            for (var i = 0; i < array_length(_items); i++) {
                GamePauseDrawRow(184, _start_y + (i * 42), 272, _items[i], "", i == _state.main_index);
            }
            break;

        case "options":
            GameUiDrawOutlinedText("Settings", GAME_VIEW_HALF_WIDTH, 62, _palette.title_color);
            var _options = GameTitleConfigEntriesCreate();
            for (var o = 0; o < array_length(_options); o++) {
                GamePauseDrawRow(170, 112 + (o * 46), 300, _options[o].label, _options[o].value,
                    o == _state.options_index);
            }
            GamePauseDrawRow(170, 112 + (array_length(_options) * 46), 300, "Back", "",
                _state.options_index == array_length(_options));
            break;

        case "practice":
            GameUiDrawOutlinedText("Practice Tuning", GAME_VIEW_HALF_WIDTH, 54, _palette.title_color);
            var _practice_entries = GamePracticeLiveEntriesCreate();
            var _practice_start_y = 68;
            var _practice_row_gap = 28;
            for (var p = 0; p < array_length(_practice_entries); p++) {
                GamePauseDrawRow(158, _practice_start_y + (p * _practice_row_gap), 324, _practice_entries[p].label,
                    _practice_entries[p].value, p == _state.practice_index);
            }
            var _restart_index = array_length(_practice_entries);
            GamePauseDrawRow(158, _practice_start_y + (_restart_index * _practice_row_gap), 324, "Restart Segment", "",
                _state.practice_index == _restart_index);
            GamePauseDrawRow(158, _practice_start_y + ((_restart_index + 1) * _practice_row_gap), 324, "Back", "",
                _state.practice_index == _restart_index + 1);
            break;

        case "quit_confirm":
            GameUiDrawOutlinedText("Return to Main Menu?", GAME_VIEW_HALF_WIDTH, 92, _palette.title_color);
            draw_set_font(fn_dialogue_speech);
            GameUiDrawOutlinedText("The current attempt will not be recorded as a clear.",
                GAME_VIEW_HALF_WIDTH, 132, _palette.muted_text_color);
            GamePauseDrawRow(206, 176, 100, "No", "", _state.quit_index == 0);
            GamePauseDrawRow(334, 176, 100, "Yes", "", _state.quit_index == 1);
            break;
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Arrows / D-pad move   Z / A confirm",
        GAME_VIEW_HALF_WIDTH, 306, _palette.muted_text_color);
    GameUiDrawOutlinedText("X / B back   Esc / Start resume",
        GAME_VIEW_HALF_WIDTH, 322, _palette.muted_text_color);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
    draw_set_color(c_white);
    return true;
}

/// @func GameRuntimeGameplayEnsure()
/// Ensures gameplay-specific runtime fields exist before gameplay code runs.
function GameRuntimeGameplayEnsure() {
    if (!variable_global_exists("game_runtime")) {
        return false;
    }

    // The default factory is the single source of truth for runtime fields.
    // Preserve live values while filling anything introduced by a newer build.
    var _resource_threshold_missing = !struct_exists(global.game_runtime, "resource_drop_threshold");
    var _defaults = GameRuntimeDataCreateDefault();
    var _field_names = variable_struct_get_names(_defaults);

    for (var i = 0; i < array_length(_field_names); i++) {
        var _field_name = _field_names[i];
        GameStructFieldEnsure(global.game_runtime, _field_name, _defaults[$ _field_name]);
    }

    // Nested structs can evolve independently, so normalize their fields too.
    if (!is_struct(global.game_runtime.signals)) {
        global.game_runtime.signals = _defaults.signals;
    }
    if (!is_struct(global.game_runtime.story)) {
        global.game_runtime.story = _defaults.story;
    }

    var _signal_names = variable_struct_get_names(_defaults.signals);
    for (var s = 0; s < array_length(_signal_names); s++) {
        var _signal_name = _signal_names[s];
        GameStructFieldEnsure(global.game_runtime.signals, _signal_name, _defaults.signals[$ _signal_name]);
    }

    var _story_names = variable_struct_get_names(_defaults.story);
    for (var t = 0; t < array_length(_story_names); t++) {
        var _story_name = _story_names[t];
        GameStructFieldEnsure(global.game_runtime.story, _story_name, _defaults.story[$ _story_name]);
    }

    if (_resource_threshold_missing) {
        global.game_runtime.resource_drop_threshold = GameResourceDropChargeThresholdGet(
            clamp(global.game_runtime.current_stage, 1, STAGE_COUNT));
    }

    return true;
}

/// @func GameRunShipIdGet()
/// Returns the active run ship id, defaulting to ship_A when unset.
function GameRunShipIdGet() {
    var _ship_id = SHIP_SUNRISE;

    if (variable_global_exists("game_runtime") && struct_exists(global.game_runtime, "selected_ship_id")
        && global.game_runtime.selected_ship_id != "") {
        _ship_id = global.game_runtime.selected_ship_id;
    }

    return _ship_id;
}

/// @func GameRunIsPractice()
/// Returns whether the active room was launched from Practice Select.
function GameRunIsPractice() {
    return variable_global_exists("game_runtime")
        && struct_exists(global.game_runtime, "run_mode")
        && global.game_runtime.run_mode == "practice";
}

/// @func GameRunStatsShouldRecord()
/// Keeps practice sessions out of persistent run and score statistics.
function GameRunStatsShouldRecord() {
    return !GameRunIsPractice();
}

/// @func GameRunTransientStateClear()
/// Clears overlays and queued story state when a run changes rooms or modes.
function GameRunTransientStateClear() {
    if (!GameRuntimeGameplayEnsure()) {
        return false;
    }

    global.game_runtime.signals.dialogue = false;
    global.game_runtime.signals.continue_request = false;
    global.game_runtime.signals.paused = false;
    global.game_runtime.continue_screen = GameContinueStateCreate();
    global.game_runtime.pause_menu = GamePauseStateCreate();

    if (!struct_exists(global.game_runtime, "story")) {
        global.game_runtime.story = {};
    }
    global.game_runtime.story.requested_file = "";
    global.game_runtime.story.current_file = "";
    return true;
}

/// @func GameNormalRunRequestConfigure(ship_id, ship_index)
/// Clears practice-only state before the normal story route begins.
function GameNormalRunRequestConfigure(_ship_id, _ship_index) {
    GameRunTransientStateClear();
    global.game_runtime.run_mode = "normal";
    global.game_runtime.selected_ship_id = (_ship_id == SHIP_SELKIE) ? SHIP_SELKIE : SHIP_SUNRISE;
    global.game_runtime.selected_ship_index = clamp(round(_ship_index), 0, 1);
    global.game_runtime.run_started_recorded = false;
    return true;
}

/// @func GamePracticeRunRequestConfigure(config)
/// Stores one sanitized, session-only practice request before entering rm_game.
function GamePracticeRunRequestConfigure(_config) {
    GameRunTransientStateClear();
    var _practice = GamePracticeConfigNormalize(_config);

    global.game_runtime.run_mode = "practice";
    global.game_runtime.practice_config = _practice;
    global.game_runtime.selected_ship_id = _practice.ship_id;
    global.game_runtime.selected_ship_index = _practice.ship_index;
    global.game_runtime.run_started_recorded = false;
    return _practice;
}

/// @func GameRunAbortToTitle()
/// Leaves an unfinished run without writing a result row or finished-run count.
function GameRunAbortToTitle() {
    GameRuntimeReset();
    room_goto(rm_title);
    return true;
}

/// @func GamePracticeReturnToTitle()
/// Returns a completed practice attempt to its retained setup page.
function GamePracticeReturnToTitle() {
    GameRunTransientStateClear();
    room_goto(rm_title);
    return true;
}

/// @func GameRankGet()
/// Returns the current bounded dynamic-difficulty rank as a percentage.
function GameRankGet() {
    GameRuntimeGameplayEnsure();
    return clamp(round(global.game_runtime.rank), RANK_MIN, RANK_MAX);
}

/// @func GameRankSet(rank)
/// Sets rank directly for initialization and practice tuning.
function GameRankSet(_rank) {
    GameRuntimeGameplayEnsure();
    global.game_runtime.rank = clamp(round(_rank), RANK_MIN, RANK_MAX);
    return global.game_runtime.rank;
}

/// @func GameRankDynamicEnabled()
/// Returns whether performance events are allowed to change rank.
function GameRankDynamicEnabled() {
    GameRuntimeGameplayEnsure();
    return !global.game_runtime.rank_locked;
}

/// @func GameRankEventApply(delta)
/// Applies one bounded performance event when dynamic rank is enabled.
function GameRankEventApply(_delta) {
    if (!GameRankDynamicEnabled()) {
        return GameRankGet();
    }

    return GameRankSet(GameRankGet() + _delta);
}

/// @func GameRankStep()
/// Raises dynamic rank slowly during uninterrupted active combat time.
function GameRankStep() {
    GameRuntimeGameplayEnsure();

    if (!GameRankDynamicEnabled() || GameGameplayIsFrozen()) {
        return GameRankGet();
    }

    global.game_runtime.rank_frame += 1;
    if (global.game_runtime.rank_frame >= RANK_PASSIVE_INTERVAL) {
        global.game_runtime.rank_frame = 0;
        GameRankEventApply(1);
    }

    return GameRankGet();
}

/// @func GameRankPressureCreate(rank)
/// Converts rank into stable spawn, fire-cadence, and bullet-speed multipliers.
function GameRankPressureCreate(_rank = undefined) {
    if (_rank == undefined) {
        _rank = GameRankGet();
    }

    var _centered = (clamp(_rank, RANK_MIN, RANK_MAX) - RANK_DEFAULT) / max(1, RANK_DEFAULT);
    return {
        spawn_interval_scale: 1 - (0.20 * _centered),
        fire_interval_scale: 1 - (0.25 * _centered),
        bullet_speed_scale: 1 + (0.15 * _centered),
    };
}

/// @func GameRankSpawnIntervalGet(base_interval, minimum)
/// Applies rank pressure to a stage-director interval.
function GameRankSpawnIntervalGet(_base_interval, _minimum = 1, _rank = undefined) {
    return max(_minimum, round(_base_interval * GameRankPressureCreate(_rank).spawn_interval_scale));
}

/// @func GameRankFireIntervalGet(base_interval, minimum)
/// Applies rank pressure to an enemy or boss cadence.
function GameRankFireIntervalGet(_base_interval, _minimum = 1, _rank = undefined) {
    return max(_minimum, round(_base_interval * GameRankPressureCreate(_rank).fire_interval_scale));
}

/// @func GameRankBulletSpeedScaleGet()
/// Returns the current enemy-bullet speed multiplier.
function GameRankBulletSpeedScaleGet(_rank = undefined) {
    return GameRankPressureCreate(_rank).bullet_speed_scale;
}

/// @func GameRunStartInitialize()
/// Initializes gameplay runtime state when rm_game begins a run.
function GameRunStartInitialize() {
    if (!GameRuntimeGameplayEnsure()) {
        return false;
    }

    GameRunTransientStateClear();
    global.game_runtime.stage_count = STAGE_COUNT;
    global.game_runtime.stage_notice_timer = STAGE_NOTICE_FRAMES;
    global.game_runtime.stage_frame = 0;
    global.game_runtime.stage_complete = false;
    global.game_runtime.bomb_active = false;
    global.game_runtime.bomb_timer = 0;
    global.game_runtime.powerup_drop_counter = 0;
    global.game_runtime.resource_drop_charge = 0;
    global.game_runtime.resource_drops_this_stage = 0;
    global.game_runtime.resource_drop_counter = 0;
    global.game_runtime.score = 0;
    global.game_runtime.continues_used = 0;
    global.game_runtime.rank_frame = 0;
    global.game_runtime.rank_defeats = 0;

    if (GameRunIsPractice()) {
        var _practice = GamePracticeConfigNormalize(global.game_runtime.practice_config);
        global.game_runtime.practice_config = _practice;
        global.game_runtime.selected_ship_id = _practice.ship_id;
        global.game_runtime.selected_ship_index = _practice.ship_index;
        global.game_runtime.current_stage = _practice.stage;
        global.game_runtime.power = _practice.power;
        global.game_runtime.lives = _practice.lives;
        global.game_runtime.bombs = _practice.bombs;
        global.game_runtime.meter = _practice.meter;
        global.game_runtime.is_berserk = _practice.meter >= METER_MAX;
        global.game_runtime.rank = _practice.rank;
        global.game_runtime.rank_locked = !_practice.dynamic_rank;
        global.game_runtime.resource_drop_threshold = GameResourceDropChargeThresholdGet(_practice.stage);
        global.game_runtime.run_started_recorded = false;
        return true;
    }

    if (global.game_runtime.selected_ship_id == "") {
        global.game_runtime.selected_ship_id = SHIP_SUNRISE;
        global.game_runtime.selected_ship_index = 0;
    }

    global.game_runtime.current_stage = 1;
    global.game_runtime.power = 0;
    global.game_runtime.lives = DEFAULT_LIVES;
    global.game_runtime.bombs = DEFAULT_BOMBS;
    global.game_runtime.meter = 0;
    global.game_runtime.is_berserk = false;
    global.game_runtime.rank = RANK_DEFAULT;
    global.game_runtime.rank_locked = false;
    global.game_runtime.resource_drop_threshold = GameResourceDropChargeThresholdGet(1);

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

    return global.game_runtime.signals.dialogue
        || global.game_runtime.signals.continue_request
        || global.game_runtime.signals.paused;
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
        stage_clear_timer: 0,
    };
}

/// @func GamePracticeSceneStateApply(state)
/// Starts a practice request at the selected full-stage, waves, or boss seam.
function GamePracticeSceneStateApply(_state) {
    if (!GameRunIsPractice()) {
        return false;
    }

    var _practice = GamePracticeConfigNormalize(global.game_runtime.practice_config);
    global.game_runtime.practice_config = _practice;
    global.game_runtime.current_stage = _practice.stage;
    global.game_runtime.stage_frame = 0;
    global.game_runtime.stage_complete = false;

    _state.frame = 0;
    _state.camera_y = CAMERA_HOME_Y;
    _state.target_x = CAMERA_HOME_X;
    _state.scroll_speed = CAMERA_SCROLL_SPEED;
    _state.mode = "scroll";
    _state.boss_spawned = false;
    _state.boss_defeated = false;
    _state.stage_clear_timer = 0;

    if (_practice.segment == PRACTICE_SEGMENT_BOSS) {
        _state.frame = STAGE_LENGTH_FRAMES;
        _state.camera_y = CAMERA_HOME_Y - STAGE_LENGTH_FRAMES;
        _state.scroll_speed = 0;
        _state.mode = "boss_intro";
        global.game_runtime.stage_frame = STAGE_LENGTH_FRAMES;
        global.game_runtime.stage_notice_timer = 0;
    } else {
        global.game_runtime.stage_notice_timer = STAGE_NOTICE_FRAMES;
    }

    return true;
}

/// @func GamePracticeWavesOnly()
/// Returns whether the current request should stop at the boss boundary.
function GamePracticeWavesOnly() {
    return GameRunIsPractice()
        && global.game_runtime.practice_config.segment == PRACTICE_SEGMENT_WAVES;
}

/// @func GameCurrentStageGet()
/// Returns the clamped one-based stage index for the active run.
function GameCurrentStageGet() {
    GameRuntimeGameplayEnsure();
    return clamp(global.game_runtime.current_stage, 1, STAGE_COUNT);
}

/// @func GameStageIsFinal()
/// Returns whether the active stage is the final stage of the run.
function GameStageIsFinal() {
    return GameCurrentStageGet() >= STAGE_COUNT;
}

/// @func GameStageInfoGet(stage)
/// Returns display metadata for one of the ten stage chapters.
function GameStageInfoGet(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);

    var _stages = [
        { name: "Moonlit Garden", subtitle: "the first tide answers", accent: make_color_rgb(118, 226, 255) },
        { name: "Petal Shoal", subtitle: "flowers blooming under glass", accent: make_color_rgb(255, 146, 212) },
        { name: "Glass Reef", subtitle: "where reflected stars bite back", accent: make_color_rgb(126, 255, 196) },
        { name: "Sunken Chapel", subtitle: "bells ring below the wake", accent: make_color_rgb(198, 166, 255) },
        { name: "Aurora Breakwater", subtitle: "a bright wall across the dark", accent: make_color_rgb(255, 214, 112) },
        { name: "Grief-Tide Observatory", subtitle: "orbiting what was lost", accent: make_color_rgb(112, 196, 255) },
        { name: "Needle Rain Coast", subtitle: "every wish returns sharpened", accent: make_color_rgb(255, 116, 116) },
        { name: "Luminous Abyss", subtitle: "light surviving without sky", accent: make_color_rgb(92, 255, 232) },
        { name: "Where Wishes Drift", subtitle: "the sea keeps every promise", accent: make_color_rgb(238, 172, 255) },
        { name: "Until We Meet Again", subtitle: "the chase reaches moonrise", accent: make_color_rgb(255, 236, 138) },
    ];

    return _stages[_stage - 1];
}

/// @func GameStageNoticeRestart()
/// Restarts the stage-title banner timer.
function GameStageNoticeRestart() {
    GameRuntimeGameplayEnsure();
    global.game_runtime.stage_notice_timer = STAGE_NOTICE_FRAMES;
}

/// @func GameStageNoticeStep()
/// Advances the stage-title banner timer.
function GameStageNoticeStep() {
    GameRuntimeGameplayEnsure();

    if (global.game_runtime.stage_notice_timer > 0) {
        global.game_runtime.stage_notice_timer -= 1;
    }
}

/// @func GameSceneStageClearBegin(state)
/// Moves the scene into its timed stage-clear seam and marks the stage complete.
function GameSceneStageClearBegin(_state) {
    _state.mode = "stage_clear";
    _state.stage_clear_timer = STAGE_CLEAR_DELAY_FRAMES;
    global.game_runtime.stage_complete = true;
    GameStageClearSoundPlay();
}

/// @func GameSceneNextStageBegin(state)
/// Advances runtime and scene state into the next scrolling stage.
function GameSceneNextStageBegin(_state) {
    GameRuntimeGameplayEnsure();

    global.game_runtime.current_stage = clamp(global.game_runtime.current_stage + 1, 1, STAGE_COUNT);
    global.game_runtime.stage_frame = 0;
    global.game_runtime.stage_complete = false;
    global.game_runtime.resource_drop_charge = 0;
    global.game_runtime.resource_drop_threshold = GameResourceDropChargeThresholdGet(global.game_runtime.current_stage);
    global.game_runtime.resource_drops_this_stage = 0;
    GameStageNoticeRestart();

    _state.frame = 0;
    _state.stage_length_frames = STAGE_LENGTH_FRAMES;
    _state.mode = "scroll";
    _state.scroll_speed = CAMERA_SCROLL_SPEED;
    _state.boss_spawned = false;
    _state.boss_defeated = false;
    _state.stage_clear_timer = 0;

    return global.game_runtime.current_stage;
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

/// @func GamePlayerMovementDeltaCreate(input)
/// Returns one frame of player movement with diagonal input normalized.
function GamePlayerMovementDeltaCreate(_input) {
    var _axis_x = _input.right_down - _input.left_down;
    var _axis_y = _input.down_down - _input.up_down;
    var _speed = PLAYER_MOVE_SPEED * (_input.autofire_down ? PLAYER_FOCUS_SPEED_MULTIPLIER : 1);

    if (_axis_x != 0 && _axis_y != 0) {
        var _diagonal_scale = 1 / sqrt(2);
        _axis_x *= _diagonal_scale;
        _axis_y *= _diagonal_scale;
    }

    return {
        x: _axis_x * _speed,
        y: _axis_y * _speed,
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

/// @func GameEnemyBulletLinearSpawn(x, y, direction, speed, object_index)
/// Spawns one enemy bullet with linear motion.
function GameEnemyBulletLinearSpawn(_x, _y, _direction, _speed, _object_index = obj_bullet_bead) {
    var _bullet = instance_create_layer(_x, _y, "Instances", _object_index);
    _bullet.move_direction = _direction;
    _bullet.move_speed = _speed;
    return _bullet;
}

/// @func GameEnemyVariantConfigure(enemy, kind, stage, slot, slot_count)
/// Applies variant stats and an initial stage-scaled movement profile.
function GameEnemyVariantConfigure(_enemy, _kind, _stage, _slot = 0, _slot_count = 1) {
    if (!instance_exists(_enemy)) {
        return noone;
    }

    _stage = clamp(_stage, 1, STAGE_COUNT);
    _enemy.variant_kind = _kind;
    _enemy.stage_rank = _stage;
    _enemy.slot_index = _slot;
    _enemy.slot_count = max(1, _slot_count);
    _enemy.age = 0;
    _enemy.fire_timer = irandom(20);
    _enemy.fire_interval = max(34, 82 - (_stage * 3));
    _enemy.wave_phase = irandom(359);
    _enemy.anchor_offset_x = 0;
    _enemy.anchor_offset_y = 0;
    _enemy.hit_radius = 18;
    _enemy.points = 900 + (_stage * 60);
    _enemy.hp = 14 + (_stage * 2);
    _enemy.move_direction = 270;
    _enemy.move_speed = 0.95 + (_stage * 0.04);

    switch (_kind) {
        case ENEMY_VARIANT_KELP:
            _enemy.hp = 32 + (_stage * 3);
            _enemy.points = 1500 + (_stage * 90);
            _enemy.hit_radius = 20;
            _enemy.move_speed = 0.42;
            _enemy.fire_interval = max(54, 112 - (_stage * 4));
            break;

        case ENEMY_VARIANT_WISP:
            _enemy.hp = 22 + (_stage * 2);
            _enemy.points = 1300 + (_stage * 75);
            _enemy.hit_radius = 16;
            _enemy.move_speed = 0;
            _enemy.fire_interval = max(42, 84 - (_stage * 3));
            break;

        case ENEMY_VARIANT_NEEDLE:
            _enemy.hp = 12 + _stage;
            _enemy.points = 800 + (_stage * 65);
            _enemy.hit_radius = 14;
            _enemy.move_speed = 2.05 + (_stage * 0.06);
            _enemy.fire_interval = max(58, 98 - (_stage * 3));
            break;

        case ENEMY_VARIANT_MIRROR:
            _enemy.hp = 34 + (_stage * 3);
            _enemy.points = 1800 + (_stage * 120);
            _enemy.hit_radius = 22;
            _enemy.move_speed = 0.5;
            _enemy.fire_interval = max(48, 92 - (_stage * 3));
            break;
    }

    var _camera = instance_find(obj_camera, 0);
    if (_camera != noone) {
        _enemy.anchor_offset_x = _enemy.x - _camera.x;
        _enemy.anchor_offset_y = _enemy.y - _camera.y;
    }

    return _enemy;
}

/// @func GameStageTimelineVariantWaveSpawn(camera_x, camera_y, kind, count)
/// Spawns a row of stage-variant enemies inside the current spawn band.
function GameStageTimelineVariantWaveSpawn(_camera_x, _camera_y, _kind, _count = 1) {
    var _band = GameStageSpawnBandRectGet(_camera_x, _camera_y);
    var _spawned = 0;
    var _stage = GameCurrentStageGet();
    _count = max(1, _count);

    for (var i = 0; i < _count; i++) {
        var _ratio = (i + 1) / (_count + 1);
        var _x = lerp(_band.left, _band.right, _ratio) + irandom_range(-8, 8);
        var _y = _band.y - (i * 8);
        var _enemy = instance_create_layer(_x, _y, "Instances", obj_enemy_variant);
        GameEnemyVariantConfigure(_enemy, _kind, _stage, i, _count);
        _spawned += 1;
    }

    return _spawned;
}

/// @func GameStageDirectorStep(state)
/// Runs the per-stage wave director for the active scrolling section.
function GameStageDirectorStep(_state) {
    if (!GameStageTimelineShouldRun(_state)) {
        return 0;
    }

    var _stage = GameCurrentStageGet();
    var _frame = _state.frame;
    var _spawned = 0;

    if (_frame < 45) {
        return 0;
    }

    var _rank = GameRankGet();
    var _turret_interval = GameRankSpawnIntervalGet(max(58, 132 - (_stage * 6)), 44, _rank);
    var _bee_interval = GameRankSpawnIntervalGet(max(72, 156 - (_stage * 5)), 54, _rank);
    var _variant_interval = GameRankSpawnIntervalGet(max(88, 188 - (_stage * 6)), 66, _rank);
    var _mayfly_interval = GameRankSpawnIntervalGet(max(210, 460 - (_stage * 18)), 160, _rank);

    if ((_frame mod _turret_interval) == 0) {
        GameStageTimelineTurretSpawn(_state.target_x, _state.camera_y);
        _spawned += 1;
    }

    if (((_frame + 30) mod _bee_interval) == 0) {
        _spawned += GameStageTimelineBeeWaveSpawn(_state.target_x, _state.camera_y);
    }

    if (_stage >= 2 && (((_frame + (_stage * 17)) mod _variant_interval) == 0)) {
        var _kind = ENEMY_VARIANT_MOTH;

        switch (((_stage + (_frame div _variant_interval)) mod 5)) {
            case 1:
                _kind = ENEMY_VARIANT_KELP;
                break;

            case 2:
                _kind = ENEMY_VARIANT_WISP;
                break;

            case 3:
                _kind = ENEMY_VARIANT_NEEDLE;
                break;

            case 4:
                _kind = ENEMY_VARIANT_MIRROR;
                break;
        }

        _spawned += GameStageTimelineVariantWaveSpawn(_state.target_x, _state.camera_y, _kind, 1 + min(2, _stage div 4));
    }

    if (_stage >= 3 && (((_frame + 90) mod _mayfly_interval) == 0)) {
        GameStageTimelineMayflySpawn(_state.target_x, _state.camera_y);
        _spawned += 1;
    }

    return _spawned;
}

/// @func GameStageBalanceReportCreate(stage)
/// Estimates whether one stage stays inside no-continue clearability bounds.
function GameStageBalanceReportCreate(_stage, _rank = RANK_DEFAULT) {
    _stage = clamp(_stage, 1, STAGE_COUNT);

    var _turret_interval = GameRankSpawnIntervalGet(max(58, 132 - (_stage * 6)), 44, _rank);
    var _bee_interval = GameRankSpawnIntervalGet(max(72, 156 - (_stage * 5)), 54, _rank);
    var _variant_interval = GameRankSpawnIntervalGet(max(88, 188 - (_stage * 6)), 66, _rank);
    var _mayfly_interval = GameRankSpawnIntervalGet(max(210, 460 - (_stage * 18)), 160, _rank);
    var _turret_count = 0;
    var _bee_count = 0;
    var _variant_count = 0;
    var _mayfly_count = 0;
    var _variant_wave_size = 1 + min(2, _stage div 4);

    for (var frame = 45; frame < STAGE_LENGTH_FRAMES; frame++) {
        if ((frame mod _turret_interval) == 0) {
            _turret_count += 1;
        }

        if (((frame + 30) mod _bee_interval) == 0) {
            _bee_count += STAGE_BEE_WAVE_COUNT;
        }

        if (_stage >= 2 && (((frame + (_stage * 17)) mod _variant_interval) == 0)) {
            _variant_count += _variant_wave_size;
        }

        if (_stage >= 3 && (((frame + 90) mod _mayfly_interval) == 0)) {
            _mayfly_count += 1;
        }
    }

    var _total_enemy_count = _turret_count + _bee_count + _variant_count + _mayfly_count;
    var _score_drop_period = GameScorePickupDropPeriodGet(_stage);
    var _resource_drop_threshold = GameResourceDropChargeThresholdGet(_stage);
    var _resource_drop_limit = GameResourceDropLimitGet(_stage);
    var _estimated_score_pickups = _total_enemy_count div _score_drop_period;
    var _estimated_resource_pickups = min(_resource_drop_limit, _total_enemy_count div _resource_drop_threshold);
    var _estimated_powerups = _estimated_score_pickups + _estimated_resource_pickups;
    var _max_spawn_pressure = ceil(300 / _turret_interval)
        + (ceil(300 / _bee_interval) * STAGE_BEE_WAVE_COUNT)
        + ((_stage >= 2) ? (ceil(300 / _variant_interval) * _variant_wave_size) : 0)
        + ((_stage >= 3) ? (ceil(300 / _mayfly_interval) * 4) : 0);

    var _sunrise_focus = GamePlayerShotSpawnSpecsCreate(0, 0, SHIP_SUNRISE, true, PLAYER_POWER_MAX);
    var _selkie_focus = GamePlayerShotSpawnSpecsCreate(0, 0, SHIP_SELKIE, true, PLAYER_POWER_MAX);
    var _sunrise_damage = 0;
    var _selkie_damage = 0;

    for (var i = 0; i < array_length(_sunrise_focus); i++) {
        _sunrise_damage += _sunrise_focus[i].damage;
    }

    for (var j = 0; j < array_length(_selkie_focus); j++) {
        _selkie_damage += _selkie_focus[j].damage;
    }

    var _boss_phase_count = GameBossPhaseCountForStage(_stage);
    var _boss_phase_hp = GameBossPhaseHpGet(_stage, _boss_phase_count);
    var _boss_damage_scale = GameBossDamageScaleGet(_boss_phase_count);
    var _reliable_focus_damage = max(1, min(_sunrise_damage, _selkie_damage) * 0.62 * _boss_damage_scale);
    var _maximum_focus_damage = max(1, max(_sunrise_damage, _selkie_damage) * _boss_damage_scale);
    var _boss_total_hp = _boss_phase_hp * _boss_phase_count;
    var _focus_boss_clear_frames = ceil(_boss_total_hp / _reliable_focus_damage) * SHOT_VOLLEY_INTERVAL;
    var _fastest_phase_clear_frames = ceil(_boss_phase_hp / _maximum_focus_damage) * SHOT_VOLLEY_INTERVAL;
    var _no_continue_viable = _estimated_score_pickups > 4
        && _max_spawn_pressure < 42
        && _focus_boss_clear_frames < (60 * 70);

    return {
        stage: _stage,
        enemy_count: _total_enemy_count,
        estimated_powerups: _estimated_powerups,
        estimated_score_pickups: _estimated_score_pickups,
        estimated_resource_pickups: _estimated_resource_pickups,
        resource_drop_limit: _resource_drop_limit,
        max_spawn_pressure: _max_spawn_pressure,
        focus_boss_clear_frames: _focus_boss_clear_frames,
        fastest_phase_clear_frames: _fastest_phase_clear_frames,
        no_continue_viable: _no_continue_viable,
    };
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

    with (obj_powerup) {
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

/// @func GamePlayerPowerGet()
/// Returns the active run's shot power level.
function GamePlayerPowerGet() {
    GameRuntimeGameplayEnsure();
    return clamp(global.game_runtime.power, 0, PLAYER_POWER_MAX);
}

/// @func GamePlayerShipSpriteGet(ship_id)
/// Returns the ship sprite for a playable ship id.
function GamePlayerShipSpriteGet(_ship_id) {
    switch (_ship_id) {
        case SHIP_SELKIE:
            return spr_sunset;
    }

    return spr_sunrise;
}

/// @func GamePlayerShipNameGet(ship_id)
/// Returns the visible craft name for a playable ship id.
function GamePlayerShipNameGet(_ship_id) {
    if (_ship_id == SHIP_SELKIE) {
        return "Sunrise";
    }

    return "Sunset";
}

/// @func GamePlayerShipDrawScaleYGet(ship_id)
/// Returns the vertical draw scale needed by playable ships.
function GamePlayerShipDrawScaleYGet(_ship_id) {
    if (_ship_id == SHIP_SELKIE) {
        return -1;
    }

    return 1;
}

/// @func GamePlayerShipDisplayNameGet(ship_id)
/// Returns the display name for a playable ship id.
function GamePlayerShipDisplayNameGet(_ship_id = undefined) {
    if (_ship_id == undefined) {
        _ship_id = GameRunShipIdGet();
    }

    switch (_ship_id) {
        case SHIP_SELKIE:
            return "Selkie";
    }

    return "Moon";
}

/// @func GameFinalBossOpponentShipIdGet(player_ship_id)
/// Returns the character ship that opposes the current route in the finale.
function GameFinalBossOpponentShipIdGet(_player_ship_id = undefined) {
    if (_player_ship_id == undefined) {
        _player_ship_id = GameRunShipIdGet();
    }

    if (_player_ship_id == SHIP_SELKIE) {
        return SHIP_SUNRISE;
    }

    return SHIP_SELKIE;
}

/// @func GameFinalBossDrawScaleYGet(player_ship_id)
/// Returns the draw scale that makes the final opponent face the player.
function GameFinalBossDrawScaleYGet(_player_ship_id = undefined) {
    var _opponent_ship_id = GameFinalBossOpponentShipIdGet(_player_ship_id);

    if (_opponent_ship_id == SHIP_SUNRISE) {
        return -1;
    }

    return 1;
}

/// @func GameMemoryCorePhaseCreate(id, shot_kind, cadence, burst_count, base_angle, angle_step, speed, turn_speed, radial_speed, spread, redirect_interval, attack_theme)
/// Creates one boss phase behavior descriptor.
function GameMemoryCorePhaseCreate(_id, _shot_kind, _cadence, _burst_count, _base_angle, _angle_step, _speed, _turn_speed, _radial_speed, _spread, _redirect_interval = 0, _attack_theme = "memory") {
    return {
        id: _id,
        shot_kind: _shot_kind,
        cadence: _cadence,
        burst_count: _burst_count,
        base_angle: _base_angle,
        angle_step: _angle_step,
        speed: _speed,
        turn_speed: _turn_speed,
        radial_speed: _radial_speed,
        spread: _spread,
        redirect_interval: _redirect_interval,
        attack_theme: _attack_theme,
    };
}

/// @func GameBossPhaseDisplayNameGet(phase)
/// Formats a descriptor id as the player-facing attack name shown by the HUD.
function GameBossPhaseDisplayNameGet(_phase) {
    if (!is_struct(_phase) || !variable_struct_exists(_phase, "id")) {
        return "Boss Attack";
    }

    var _id = string_lower(string(_phase.id));
    var _variant_label = "";
    var _variant_pos = string_pos("_v", _id);

    if (_variant_pos > 0) {
        _variant_label = string_copy(
            _id,
            _variant_pos + 2,
            string_length(_id) - (_variant_pos + 1)
        );
        _id = string_copy(_id, 1, _variant_pos - 1);
    }

    var _finale_pos = string_pos("_finale", _id);
    if (_finale_pos > 0) {
        _id = string_copy(_id, 1, _finale_pos - 1);
    }

    var _display_name = "";
    var _capitalize_next = true;

    for (var i = 1; i <= string_length(_id); i++) {
        var _character = string_char_at(_id, i);

        if (_character == "_") {
            _display_name += " ";
            _capitalize_next = true;
        } else if (_capitalize_next) {
            _display_name += string_upper(_character);
            _capitalize_next = false;
        } else {
            _display_name += _character;
        }
    }

    if (_variant_label != "") {
        _display_name += " - Variant " + _variant_label;
    }

    return (_display_name == "") ? "Boss Attack" : _display_name;
}

/// @func GameBossPhaseNoticeAlphaGet(phase_timer)
/// Returns the two-second phase-title opacity with short entrance and exit fades.
function GameBossPhaseNoticeAlphaGet(_phase_timer) {
    if (_phase_timer < 0 || _phase_timer >= BOSS_PHASE_NOTICE_FRAMES) {
        return 0;
    }

    var _fade_in = clamp(_phase_timer / BOSS_PHASE_NOTICE_FADE_IN_FRAMES, 0, 1);
    var _remaining = BOSS_PHASE_NOTICE_FRAMES - _phase_timer;
    var _fade_out = clamp(_remaining / BOSS_PHASE_NOTICE_FADE_OUT_FRAMES, 0, 1);
    return min(_fade_in, _fade_out);
}

/// @func GameBossExpandedPhaseCountForStage(stage)
/// Returns the seed-and-variant phase count before the unique finale is appended.
function GameBossExpandedPhaseCountForStage(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);

    if (_stage >= STAGE_COUNT) {
        return FINAL_BOSS_EXPANDED_PHASE_COUNT;
    }

    if (_stage <= 2) {
        return 4;
    }

    if (_stage <= 6) {
        return 6;
    }

    return 8;
}

/// @func GameBossPhaseCountForStage(stage)
/// Returns the full life-segment count, including the boss-exclusive finale.
function GameBossPhaseCountForStage(_stage) {
    return GameBossExpandedPhaseCountForStage(_stage) + 1;
}

/// @func GameBossPhaseHpGet(stage, phase_count)
/// Keeps total boss endurance near the original curve while allowing more phases.
function GameBossPhaseHpGet(_stage, _phase_count = undefined) {
    _stage = clamp(_stage, 1, STAGE_COUNT);

    if (_phase_count == undefined) {
        _phase_count = GameBossPhaseCountForStage(_stage);
    }

    var _original_total_hp = (BOSS_PHASE_HP + ((_stage - 1) * BOSS_PHASE_HP_STAGE_STEP)) * BOSS_PHASE_COUNT;
    return max(BOSS_PHASE_MIN_HP, ceil(_original_total_hp / max(1, _phase_count)));
}

/// @func GameBossDamageScaleGet(phase_count)
/// Normalizes incoming damage so expanded encounters have time to express each phase.
function GameBossDamageScaleGet(_phase_count) {
    _phase_count = max(1, _phase_count);
    return clamp(BOSS_PHASE_COUNT / _phase_count, BOSS_DAMAGE_SCALE_MIN, 1);
}

/// @func GameBossDamageApply(boss, damage)
/// Applies phase-count-normalized damage to an active boss and returns the amount dealt.
function GameBossDamageApply(_boss, _damage) {
    if (!instance_exists(_boss) || !variable_instance_exists(_boss, "hp")) {
        return 0;
    }

    if (variable_instance_exists(_boss, "destruction_active") && _boss.destruction_active) {
        return 0;
    }

    var _phase_count = variable_instance_exists(_boss, "phase_count") ? _boss.phase_count : BOSS_PHASE_COUNT;
    var _applied_damage = max(0, _damage) * GameBossDamageScaleGet(_phase_count);
    _boss.hp -= _applied_damage;
    return _applied_damage;
}

/// @func GameMemoryCoreNameGet(stage)
/// Returns the display name for a non-final Memory Core.
function GameMemoryCoreNameGet(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT - 1)) {
        case 1: return "Tideglass Core";
        case 2: return "Lantern Core";
        case 3: return "Saltwind Core";
        case 4: return "Kelp Core";
        case 5: return "Moonwake Core";
        case 6: return "Glassreef Core";
        case 7: return "Starfall Core";
        case 8: return "Bloodtide Core";
        case 9: return "Crescent Gate Core";
    }

    return "Memory Core";
}

/// @func GameMemoryCoreBasePhasePlanCreate(stage)
/// Returns the boss-specific seed phases for any non-final encounter. The
/// legacy function name is retained because stage and practice data call it.
function GameMemoryCoreBasePhasePlanCreate(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT - 1)) {
        case 1:
            return [
                GameMemoryCorePhaseCreate("tideglass_spiral", "blade_spiral", 24, 10, 0, 19, 0, 12, 1.55, 0),
                GameMemoryCorePhaseCreate("tideglass_fan", "diamond_fan", 36, 5, 0, 0, 3.4, 0, 0, 44),
            ];

        case 2:
            return [
                GameMemoryCorePhaseCreate("mira_four_suits", "mira_four_suits", 30, 12, 12, -9, 2.8, 0, 0, 72, 0, "poker"),
                GameMemoryCorePhaseCreate("mira_dealer_fan", "mira_dealer_fan", 38, 9, 0, 11, 3.5, 0, 0, 76, 0, "poker"),
            ];

        case 3:
            return [
                GameMemoryCorePhaseCreate("saltwind_gale", "saltwind_gale", 22, 8, 250, 23, 3.6, 0, 0, 74, 0, "saltwind"),
                GameMemoryCorePhaseCreate("saltwind_spindrift", "saltwind_spindrift", 34, 14, 9, -17, 0, 15, 1.35, 82, 0, "saltwind"),
                GameMemoryCorePhaseCreate("saltwind_needles", "saltwind_needles", 28, 9, 0, 11, 4.0, 0, 0, 68, 0, "saltwind"),
            ];

        case 4:
            return [
                GameMemoryCorePhaseCreate("kelp_snare", "kelp_snare", 38, 10, 0, 0, 3.0, 0, 0, 104, 0, "kelp"),
                GameMemoryCorePhaseCreate("kelp_bramble", "kelp_bramble", 28, 12, 0, 29, 2.9, 9, 1.85, 72, 0, "kelp"),
                GameMemoryCorePhaseCreate("kelp_wall", "kelp_wall", 32, 10, 90, 15, 3.2, 10, 1.6, 88, 0, "kelp"),
            ];

        case 5:
            return [
                GameMemoryCorePhaseCreate("shalmii_hex_runes", "shalmii_hex_runes", 26, 12, 0, 17, 3.2, 0, 0, 0, 0, "rune"),
                GameMemoryCorePhaseCreate("shalmii_hammerfall", "shalmii_hammerfall", 34, 12, 270, 9, 3.5, 12, 1.7, 96, 0, "rune"),
                GameMemoryCorePhaseCreate("shalmii_shockwave", "shalmii_shockwave", 24, 15, 30, -13, 3.0, 0, 0, 0, 0, "rune"),
            ];

        case 6:
            return [
                GameMemoryCorePhaseCreate("aisha_order_circle", "aisha_order_circle", 28, 12, 0, 19, 3.2, 0, 0, 0, 0, "desire"),
                GameMemoryCorePhaseCreate("aisha_chaos_shards", "aisha_chaos_shards", 22, 11, 235, -17, 4.0, 0, 0, 84, 0, "desire"),
                GameMemoryCorePhaseCreate("aisha_talisman_seal", "aisha_talisman_seal", 32, 18, 6, 13, 2.8, 14, 1.65, 92, 0, "desire"),
            ];

        case 7:
            return [
                GameMemoryCorePhaseCreate("aster_ribbon_loop", "aster_ribbon_loop", 20, 12, 0, 23, 2.8, 13, 1.55, 88, 0, "ribbon"),
                GameMemoryCorePhaseCreate("aster_bunny_hop", "aster_bunny_hop", 28, 12, 0, -17, 3.5, 0, 0, 104, 0, "ribbon"),
                GameMemoryCorePhaseCreate("aster_winged_staff", "aster_winged_staff", 24, 10, 240, 15, 4.2, 12, 1.7, 82, 0, "ribbon"),
                GameMemoryCorePhaseCreate("aster_lavender_knot", "aster_lavender_knot", 32, 16, 10, -11, 3.0, 17, 1.75, 72, 105, "ribbon"),
            ];

        case 8:
            return [
                GameMemoryCorePhaseCreate("bloodtide_pulse", "bloodtide_pulse", 20, 16, 0, 17, 3.6, 0, 0, 0, 0, "bloodtide"),
                GameMemoryCorePhaseCreate("bloodtide_rip", "bloodtide_rip", 26, 10, 45, -21, 3.8, 14, 1.75, 76, 0, "bloodtide"),
                GameMemoryCorePhaseCreate("bloodtide_hunt", "bloodtide_hunt", 18, 9, 0, 0, 4.5, 0, 0, 104, 0, "bloodtide"),
                GameMemoryCorePhaseCreate("bloodtide_deluge", "bloodtide_deluge", 30, 14, 270, 13, 3.5, 10, 1.55, 96, 0, "bloodtide"),
            ];

        case 9:
            return [
                GameMemoryCorePhaseCreate("caelia_planetary_orbit", "caelia_planetary_orbit", 22, 12, 22, 29, 3.3, 16, 1.65, 84, 0, "astral"),
                GameMemoryCorePhaseCreate("caelia_constellation", "caelia_constellation", 20, 15, 0, 11, 4.0, 0, 0, 120, 0, "astral"),
                GameMemoryCorePhaseCreate("caelia_astrolabe", "caelia_astrolabe", 26, 18, 0, 25, 3.1, 18, 1.85, 76, 0, "astral"),
                GameMemoryCorePhaseCreate("caelia_star_cage", "caelia_star_cage", 28, 16, 45, -17, 3.7, 15, 1.75, 108, 75, "astral"),
            ];
    }

    return [
        GameMemoryCorePhaseCreate("memory_default_spiral", "blade_spiral", 30, 12, 0, 0, 0, 12, 1.5, 0),
        GameMemoryCorePhaseCreate("memory_default_fan", "diamond_fan", 36, 5, 0, 0, 3.5, 0, 0, 48),
        GameMemoryCorePhaseCreate("memory_default_ring", "bead_ring", 48, 12, 0, 0, 3.0, 0, 0, 0),
    ];
}

/// @func GameMemoryCoreFinalPhaseCreate(stage)
/// Returns the one-off attack appended after every non-final seed and variant set.
function GameMemoryCoreFinalPhaseCreate(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT - 1)) {
        case 1:
            return GameMemoryCorePhaseCreate("tideglass_maelstrom_finale", "tideglass_maelstrom", 18, 18, 0, 23, 3.4, 15, 1.65, 96, 0, "tideglass");

        case 2:
            return GameMemoryCorePhaseCreate("mira_royal_flush_finale", "mira_royal_flush", 18, 16, 45, -19, 3.8, 0, 0, 104, 0, "poker");

        case 3:
            return GameMemoryCorePhaseCreate("saltwind_eye_finale", "saltwind_eye", 16, 18, 270, 31, 4.1, 17, 1.75, 112, 0, "saltwind");

        case 4:
            return GameMemoryCorePhaseCreate("kelp_abyssal_bloom_finale", "kelp_abyssal_bloom", 20, 16, 0, 27, 3.5, 13, 1.9, 120, 0, "kelp");

        case 5:
            return GameMemoryCorePhaseCreate("shalmii_runebreaker_finale", "shalmii_runebreaker", 16, 20, 0, -29, 4.0, 18, 1.95, 132, 0, "rune");

        case 6:
            return GameMemoryCorePhaseCreate("aisha_blade_of_desires_finale", "aisha_blade_of_desires", 14, 21, 6, 37, 4.3, 14, 1.8, 116, 0, "desire");

        case 7:
            return GameMemoryCorePhaseCreate("aster_ribbonstar_wish_finale", "aster_ribbonstar_wish", 14, 22, 0, -33, 4.5, 20, 2.0, 128, 75, "ribbon");

        case 8:
            return GameMemoryCorePhaseCreate("bloodtide_heart_finale", "bloodtide_heart", 14, 24, 45, 29, 4.4, 18, 2.05, 136, 0, "bloodtide");

        case 9:
            return GameMemoryCorePhaseCreate("caelia_cosmic_zenith_finale", "caelia_cosmic_zenith", 12, 24, 0, 33, 4.6, 21, 2.1, 144, 60, "astral");
    }

    return GameMemoryCorePhaseCreate("memory_finale", "tideglass_maelstrom", 20, 16, 0, 19, 3.5, 14, 1.7, 96);
}

/// @func GameBossPhaseVariantCreate(phase, variant_index)
/// Returns a denser but readable iteration of a boss-specific seed phase.
function GameBossPhaseVariantCreate(_phase, _variant_index) {
    var _variant = max(1, _variant_index);
    var _speed = _phase.speed + min(0.7, _variant * 0.12);
    var _turn_speed = _phase.turn_speed + min(4, _variant);
    var _radial_speed = _phase.radial_speed + min(0.45, _variant * 0.08);
    var _spread = _phase.spread + (_variant * 8);
    var _redirect_interval = (_phase.redirect_interval > 0)
        ? max(60, _phase.redirect_interval - (_variant * 10))
        : 0;

    return GameMemoryCorePhaseCreate(
        _phase.id + "_v" + string(_variant),
        _phase.shot_kind,
        max(14, _phase.cadence - min(10, _variant * 2)),
        min(_phase.burst_count + _variant, _phase.burst_count + 4),
        _phase.base_angle + (_variant * 17),
        _phase.angle_step + (((_variant mod 2) == 0) ? _variant : -_variant),
        _speed,
        _turn_speed,
        _radial_speed,
        _spread,
        _redirect_interval,
        _phase.attack_theme
    );
}

/// @func GameBossPhasePlanExpand(seed_plan, target_count)
/// Repeats seed phases as tuned variants until the desired phase count is reached.
function GameBossPhasePlanExpand(_seed_plan, _target_count) {
    var _phase_plan = [];
    var _seed_count = array_length(_seed_plan);
    var _base_count = min(_target_count, _seed_count);

    if (_seed_count <= 0) {
        return _phase_plan;
    }

    for (var i = 0; i < _base_count; i++) {
        array_push(_phase_plan, _seed_plan[i]);
    }

    var _variant_index = 1;
    while (array_length(_phase_plan) < _target_count) {
        for (var p = 0; p < _seed_count && array_length(_phase_plan) < _target_count; p++) {
            array_push(_phase_plan, GameBossPhaseVariantCreate(_seed_plan[p], _variant_index));
        }

        _variant_index += 1;
    }

    return _phase_plan;
}

/// @func GameMemoryCorePhasePlanCreate(stage)
/// Returns the expanding unique phase descriptors for a non-final Memory Core.
function GameMemoryCorePhasePlanCreate(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT - 1);
    var _expanded_count = GameBossExpandedPhaseCountForStage(_stage);
    var _seed_plan = GameMemoryCoreBasePhasePlanCreate(_stage);
    var _phase_plan = GameBossPhasePlanExpand(_seed_plan, _expanded_count);
    array_push(_phase_plan, GameMemoryCoreFinalPhaseCreate(_stage));
    return _phase_plan;
}

/// @func GameFinalBossBasePhasePlanCreate(opponent_ship_id)
/// Returns the route-specific seed phases for the final opponent.
function GameFinalBossBasePhasePlanCreate(_opponent_ship_id) {
    if (_opponent_ship_id == SHIP_SUNRISE) {
        return [
            GameMemoryCorePhaseCreate("moon_rose_bloom", "rose_bloom", 30, 14, 0, 13, 3.0, 10, 1.4, 0, 0, "rose"),
            GameMemoryCorePhaseCreate("moon_thorn_arc", "rose_thorn_arc", 24, 9, 0, 0, 4.0, 0, 0, 112, 0, "rose"),
            GameMemoryCorePhaseCreate("moon_rose_whip", "rose_whip", 18, 8, 220, 21, 3.3, 12, 1.6, 96, 0, "rose"),
            GameMemoryCorePhaseCreate("moon_petal_spiral", "rose_petal_spiral", 26, 16, 15, -17, 3.2, 15, 1.55, 0, 120, "rose"),
            GameMemoryCorePhaseCreate("moon_garden_gate", "rose_garden", 34, 12, 45, 19, 3.5, 13, 1.5, 88, 0, "rose"),
        ];
    }

    return [
        GameMemoryCorePhaseCreate("selkie_chakram_orbit", "chakram_orbit", 28, 12, 0, 23, 0, 17, 1.7, 0, 0, "chakram"),
        GameMemoryCorePhaseCreate("selkie_chakram_saw", "chakram_saw", 20, 10, 45, -25, 3.7, 18, 1.65, 0, 0, "chakram"),
        GameMemoryCorePhaseCreate("selkie_chakram_return", "chakram_return", 24, 14, 12, 27, 0, 16, 1.85, 0, 110, "chakram"),
        GameMemoryCorePhaseCreate("selkie_chakram_gate", "chakram_gate", 32, 18, 0, 11, 3.1, 0, 0, 80, 0, "chakram"),
        GameMemoryCorePhaseCreate("selkie_chakram_lance", "chakram_lance", 22, 7, 0, 0, 4.6, 0, 0, 42, 0, "chakram"),
    ];
}

/// @func GameFinalBossFinalPhaseCreate(opponent_ship_id)
/// Returns the route opponent's one-off sixteenth and final attack.
function GameFinalBossFinalPhaseCreate(_opponent_ship_id) {
    if (_opponent_ship_id == SHIP_SUNRISE) {
        return GameMemoryCorePhaseCreate(
            "moon_rose_eternity_finale", "rose_eternity", 12, 26, 0, 31,
            4.4, 22, 2.15, 156, 60, "rose"
        );
    }

    return GameMemoryCorePhaseCreate(
        "selkie_chakram_apotheosis_finale", "chakram_apotheosis", 12, 24, 45, -33,
        4.7, 23, 2.2, 148, 60, "chakram"
    );
}

/// @func GameFinalBossPhasePlanCreate(opponent_ship_id)
/// Returns three complete five-pattern sets followed by a route-exclusive finale.
function GameFinalBossPhasePlanCreate(_opponent_ship_id) {
    var _phase_plan = GameBossPhasePlanExpand(
        GameFinalBossBasePhasePlanCreate(_opponent_ship_id),
        FINAL_BOSS_EXPANDED_PHASE_COUNT
    );
    array_push(_phase_plan, GameFinalBossFinalPhaseCreate(_opponent_ship_id));
    return _phase_plan;
}

/// @func GameMemoryCorePhaseSignatureCreate(phase)
/// Returns a compact signature for one Memory Core phase descriptor.
function GameMemoryCorePhaseSignatureCreate(_phase) {
    return _phase.id + ":"
        + _phase.shot_kind + ":"
        + string(_phase.cadence) + ":"
        + string(_phase.burst_count) + ":"
        + string(_phase.base_angle) + ":"
        + string(_phase.angle_step) + ":"
        + string(_phase.speed) + ":"
        + string(_phase.turn_speed) + ":"
        + string(_phase.radial_speed) + ":"
        + string(_phase.spread) + ":"
        + string(_phase.redirect_interval) + ":"
        + _phase.attack_theme;
}

/// @func GameMemoryCorePhasePlanSignatureCreate(phase_plan)
/// Returns a compact signature for a boss phase plan.
function GameMemoryCorePhasePlanSignatureCreate(_phase_plan) {
    var _signature = "";

    for (var i = 0; i < array_length(_phase_plan); i++) {
        if (_signature != "") {
            _signature += "|";
        }

        _signature += GameMemoryCorePhaseSignatureCreate(_phase_plan[i]);
    }

    return _signature;
}

/// @func GameCharacterBossInfoCreate(stage)
/// Returns character presentation metadata for a replaced Memory Core.
/// The encounter's original phase plan remains owned by its stage.
function GameCharacterBossInfoCreate(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT)) {
        case MIRA_BOSS_STAGE:
            return {
                story_id: "mira",
                display_name: MIRA_BOSS_NAME,
                ship_name: MIRA_SHIP_NAME,
                sprite_id: spr_mira_ship,
            };

        case SHALMII_BOSS_STAGE:
            return {
                story_id: "shalmii",
                display_name: SHALMII_BOSS_NAME,
                ship_name: SHALMII_SHIP_NAME,
                sprite_id: spr_shalmii_ship,
            };

        case AISHA_BOSS_STAGE:
            return {
                story_id: "aisha",
                display_name: AISHA_BOSS_NAME,
                ship_name: AISHA_SHIP_NAME,
                sprite_id: spr_aisha_ship,
            };

        case ASTER_BOSS_STAGE:
            return {
                story_id: "aster",
                display_name: ASTER_BOSS_NAME,
                ship_name: ASTER_SHIP_NAME,
                sprite_id: spr_aster_ship,
            };

        case CAELIA_BOSS_STAGE:
            return {
                story_id: "caelia",
                display_name: CAELIA_BOSS_NAME,
                ship_name: CAELIA_SHIP_NAME,
                sprite_id: spr_caelia_ship,
            };
    }

    return undefined;
}

/// @func GameBossEncounterInfoCreate(stage, player_ship_id)
/// Returns the visual identity for a stage boss encounter.
function GameBossEncounterInfoCreate(_stage = undefined, _player_ship_id = undefined) {
    if (_stage == undefined) {
        _stage = GameCurrentStageGet();
    }

    if (_player_ship_id == undefined) {
        _player_ship_id = GameRunShipIdGet();
    }

    _stage = clamp(_stage, 1, STAGE_COUNT);
    var _is_final = _stage >= STAGE_COUNT;
    if (!_is_final) {
        var _phase_plan = GameMemoryCorePhasePlanCreate(_stage);
        var _character_boss = GameCharacterBossInfoCreate(_stage);
        var _is_character = is_struct(_character_boss);

        return {
            is_final: false,
            is_character: _is_character,
            opponent_ship_id: "",
            display_name: _is_character ? _character_boss.display_name : GameMemoryCoreNameGet(_stage),
            ship_name: _is_character ? _character_boss.ship_name : "",
            sprite_id: _is_character ? _character_boss.sprite_id : spr_mayfly,
            draw_y_scale: 1,
            phase_plan: _phase_plan,
            phase_signature: GameMemoryCorePhasePlanSignatureCreate(_phase_plan),
        };
    }

    var _opponent_ship_id = GameFinalBossOpponentShipIdGet(_player_ship_id);
    var _final_phase_plan = GameFinalBossPhasePlanCreate(_opponent_ship_id);

    return {
        is_final: true,
        is_character: true,
        opponent_ship_id: _opponent_ship_id,
        display_name: GamePlayerShipDisplayNameGet(_opponent_ship_id),
        ship_name: GamePlayerShipNameGet(_opponent_ship_id),
        sprite_id: GamePlayerShipSpriteGet(_opponent_ship_id),
        draw_y_scale: GameFinalBossDrawScaleYGet(_player_ship_id),
        phase_plan: _final_phase_plan,
        phase_signature: GameMemoryCorePhasePlanSignatureCreate(_final_phase_plan),
    };
}

/// @func GameMayflyTargetAnchorOffsetYGet()
/// Returns the camera-relative anchor offset that keeps mayflies near y=100 in view.
function GameMayflyTargetAnchorOffsetYGet() {
    return -PLAYFIELD_HALF_HEIGHT + MAYFLY_VISIBLE_Y;
}

/// @func GameShotSpecCreate(x, y, direction, speed, sprite_id, damage, scale, color, accent_color, power, focused)
/// Creates one normalized shot spawn specification.
function GameShotSpecCreate(_x, _y, _direction, _speed, _sprite_id, _damage = PLAYER_SHOT_DAMAGE, _scale = 1, _color = c_white, _accent_color = c_aqua, _power = 0, _focused = false) {
    return {
        x: _x,
        y: _y,
        direction: _direction,
        speed: _speed,
        sprite_id: _sprite_id,
        damage: _damage,
        scale: _scale,
        color: _color,
        accent_color: _accent_color,
        power: _power,
        focused: _focused,
    };
}

/// @func GamePlayerShotPairAppend(shots, center_x, center_y, direction, sprite_id, damage, speed, scale, color)
/// Appends one mirrored pair of shots into a shot specification array.
function GamePlayerShotPairAppend(_shots, _center_x, _center_y, _direction, _sprite_id, _damage = PLAYER_SHOT_DAMAGE, _speed = SHOT_SPEED, _scale = 1, _color = c_white) {
    var _perpendicular = _direction + 90;
    var _offset_x = lengthdir_x(2.5, _perpendicular);
    var _offset_y = lengthdir_y(2.5, _perpendicular);

    array_push(_shots, GameShotSpecCreate(_center_x - _offset_x, _center_y - _offset_y, _direction, _speed, _sprite_id, _damage, _scale, _color));
    array_push(_shots, GameShotSpecCreate(_center_x + _offset_x, _center_y + _offset_y, _direction, _speed, _sprite_id, _damage, _scale, _color));
    return _shots;
}

/// @func GamePlayerShotPowerColorGet(ship_id, power, focused)
/// Returns the main tint used by player shots at a power level.
function GamePlayerShotPowerColorGet(_ship_id, _power, _focused = false) {
    var _tier = clamp(floor(_power), 0, PLAYER_POWER_MAX);

    if (_ship_id == SHIP_SELKIE) {
        switch (_tier) {
            case 0: return make_color_rgb(158, 92, 255);
            case 1: return make_color_rgb(184, 92, 255);
            case 2: return make_color_rgb(210, 96, 255);
            case 3: return make_color_rgb(232, 104, 246);
            case 4: return make_color_rgb(250, 112, 226);
            case 5: return _focused ? make_color_rgb(255, 194, 236) : make_color_rgb(255, 118, 208);
        }
    }

    switch (_tier) {
        case 0: return make_color_rgb(94, 188, 255);
        case 1: return make_color_rgb(104, 216, 255);
        case 2: return make_color_rgb(135, 225, 228);
        case 3: return make_color_rgb(255, 208, 112);
        case 4: return make_color_rgb(255, 156, 72);
        case 5: return _focused ? make_color_rgb(255, 220, 128) : make_color_rgb(255, 118, 48);
    }

    return c_white;
}

/// @func GamePlayerShotPowerAccentColorGet(ship_id, power, focused)
/// Returns the secondary glow color used by high-powered shots.
function GamePlayerShotPowerAccentColorGet(_ship_id, _power, _focused = false) {
    var _tier = clamp(floor(_power), 0, PLAYER_POWER_MAX);

    if (_ship_id == SHIP_SELKIE) {
        if (_tier >= 4) {
            return make_color_rgb(255, 184, 232);
        }

        return _focused ? make_color_rgb(232, 196, 255) : make_color_rgb(198, 116, 255);
    }

    if (_tier >= 4) {
        return make_color_rgb(255, 202, 108);
    }

    return _focused ? make_color_rgb(255, 232, 154) : make_color_rgb(106, 226, 255);
}

/// @func GamePlayerShotPowerScaleGet(power, focused)
/// Returns the visual scale multiplier for a shot power level.
function GamePlayerShotPowerScaleGet(_power, _focused = false) {
    return 0.9 + (clamp(_power, 0, PLAYER_POWER_MAX) * 0.075) + (_focused ? 0.06 : 0);
}

/// @func GamePlayerShotVisualsApply(shots, ship_id, power, focused)
/// Applies shared power-tier visual metadata to a generated shot array.
function GamePlayerShotVisualsApply(_shots, _ship_id, _power, _focused) {
    var _color = GamePlayerShotPowerColorGet(_ship_id, _power, _focused);
    var _accent = GamePlayerShotPowerAccentColorGet(_ship_id, _power, _focused);
    var _scale = GamePlayerShotPowerScaleGet(_power, _focused);

    for (var i = 0; i < array_length(_shots); i++) {
        _shots[i].scale *= _scale;
        _shots[i].color = _color;
        _shots[i].accent_color = _accent;
        _shots[i].power = clamp(_power, 0, PLAYER_POWER_MAX);
        _shots[i].focused = _focused;
    }

    return _shots;
}

/// @func GamePlayerSunriseShotSpawnSpecsCreate(x, y, focused, power)
/// Returns the Sunrise shot pattern for one queued volley tick.
function GamePlayerSunriseShotSpawnSpecsCreate(_x, _y, _focused, _power) {
    var _shots = [];
    var _damage = PLAYER_SHOT_DAMAGE + (_power div 3);
    var _speed = SHOT_SPEED + (_focused ? 1 : 0);

    if (_focused) {
        GamePlayerShotPairAppend(_shots, _x - 14, _y - 28, 92, SHOT_SPRITE_FRONT, _damage + 1, _speed, 1.05);
        GamePlayerShotPairAppend(_shots, _x + 14, _y - 28, 88, SHOT_SPRITE_FRONT, _damage + 1, _speed, 1.05);
        GamePlayerShotPairAppend(_shots, _x - 5, _y - 38, 90, SHOT_SPRITE_FRONT, _damage + 1, _speed, 1.1);
        GamePlayerShotPairAppend(_shots, _x + 5, _y - 38, 90, SHOT_SPRITE_FRONT, _damage + 1, _speed, 1.1);

        if (_power >= 2) {
            GamePlayerShotPairAppend(_shots, _x, _y - 20, 90, SHOT_SPRITE_SIDE, _damage + 1, _speed - 1, 0.95);
        }

        if (_power >= 4) {
            GamePlayerShotPairAppend(_shots, _x, _y - 16, 86, SHOT_SPRITE_SIDE, _damage, _speed - 1, 0.9);
            GamePlayerShotPairAppend(_shots, _x, _y - 16, 94, SHOT_SPRITE_SIDE, _damage, _speed - 1, 0.9);
        }

        return GamePlayerShotVisualsApply(_shots, SHIP_SUNRISE, _power, _focused);
    }

    GamePlayerShotPairAppend(_shots, _x - 26, _y - 12, 100, SHOT_SPRITE_SIDE, _damage, _speed);
    GamePlayerShotPairAppend(_shots, _x + 26, _y - 12, 80, SHOT_SPRITE_SIDE, _damage, _speed);
    GamePlayerShotPairAppend(_shots, _x - 24, _y - 30, 90, SHOT_SPRITE_FRONT, _damage, _speed);
    GamePlayerShotPairAppend(_shots, _x - 8, _y - 36, 90, SHOT_SPRITE_FRONT, _damage, _speed);
    GamePlayerShotPairAppend(_shots, _x + 8, _y - 36, 90, SHOT_SPRITE_FRONT, _damage, _speed);
    GamePlayerShotPairAppend(_shots, _x + 24, _y - 30, 90, SHOT_SPRITE_FRONT, _damage, _speed);

    if (_power >= 3) {
        GamePlayerShotPairAppend(_shots, _x - 34, _y - 6, 112, SHOT_SPRITE_SIDE, _damage, _speed - 1, 0.9);
        GamePlayerShotPairAppend(_shots, _x + 34, _y - 6, 68, SHOT_SPRITE_SIDE, _damage, _speed - 1, 0.9);
    }

    return GamePlayerShotVisualsApply(_shots, SHIP_SUNRISE, _power, _focused);
}

/// @func GamePlayerSelkieShotSpawnSpecsCreate(x, y, focused, power)
/// Returns the Selkie shot pattern for one queued volley tick.
function GamePlayerSelkieShotSpawnSpecsCreate(_x, _y, _focused, _power) {
    var _shots = [];
    var _damage = PLAYER_SHOT_DAMAGE + 1 + (_power div 2);
    var _speed = SHOT_SPEED - 1;

    if (_focused) {
        GamePlayerShotPairAppend(_shots, _x - 10, _y - 26, 90, SHOT_SPRITE_SIDE, _damage + 1, _speed + 2, 1.15, make_color_rgb(255, 216, 252));
        GamePlayerShotPairAppend(_shots, _x + 10, _y - 26, 90, SHOT_SPRITE_SIDE, _damage + 1, _speed + 2, 1.15, make_color_rgb(255, 216, 252));
        GamePlayerShotPairAppend(_shots, _x, _y - 38, 90, SHOT_SPRITE_FRONT, _damage + 2, _speed + 1, 1.25, make_color_rgb(182, 244, 255));

        if (_power >= 2) {
            GamePlayerShotPairAppend(_shots, _x - 20, _y - 12, 94, SHOT_SPRITE_FRONT, _damage, _speed, 0.9, make_color_rgb(182, 244, 255));
            GamePlayerShotPairAppend(_shots, _x + 20, _y - 12, 86, SHOT_SPRITE_FRONT, _damage, _speed, 0.9, make_color_rgb(182, 244, 255));
        }

        if (_power >= 5) {
            GamePlayerShotPairAppend(_shots, _x, _y - 8, 90, SHOT_SPRITE_SIDE, _damage + 2, _speed + 1, 1.25, make_color_rgb(255, 246, 180));
        }

        return GamePlayerShotVisualsApply(_shots, SHIP_SELKIE, _power, _focused);
    }

    GamePlayerShotPairAppend(_shots, _x - 24, _y - 12, 112, SHOT_SPRITE_SIDE, _damage, _speed, 1.0, make_color_rgb(255, 206, 244));
    GamePlayerShotPairAppend(_shots, _x + 24, _y - 12, 68, SHOT_SPRITE_SIDE, _damage, _speed, 1.0, make_color_rgb(255, 206, 244));
    GamePlayerShotPairAppend(_shots, _x - 18, _y - 26, 100, SHOT_SPRITE_FRONT, _damage, _speed + 1, 1.0, make_color_rgb(184, 244, 255));
    GamePlayerShotPairAppend(_shots, _x + 18, _y - 26, 80, SHOT_SPRITE_FRONT, _damage, _speed + 1, 1.0, make_color_rgb(184, 244, 255));
    GamePlayerShotPairAppend(_shots, _x, _y - 34, 90, SHOT_SPRITE_FRONT, _damage + 1, _speed + 1, 1.1, make_color_rgb(255, 246, 180));

    if (_power >= 3) {
        GamePlayerShotPairAppend(_shots, _x - 32, _y - 4, 124, SHOT_SPRITE_SIDE, _damage, _speed - 1, 0.85, make_color_rgb(255, 206, 244));
        GamePlayerShotPairAppend(_shots, _x + 32, _y - 4, 56, SHOT_SPRITE_SIDE, _damage, _speed - 1, 0.85, make_color_rgb(255, 206, 244));
    }

    return GamePlayerShotVisualsApply(_shots, SHIP_SELKIE, _power, _focused);
}

/// @func GamePlayerShotSpawnSpecsCreate(x, y, ship_id, focused, power)
/// Returns the shot specifications produced by one queued volley tick.
function GamePlayerShotSpawnSpecsCreate(_x, _y, _ship_id = undefined, _focused = false, _power = undefined) {
    if (_ship_id == undefined) {
        _ship_id = GameRunShipIdGet();
    }

    if (_power == undefined) {
        _power = GamePlayerPowerGet();
    }

    switch (_ship_id) {
        case SHIP_SELKIE:
            return GamePlayerSelkieShotSpawnSpecsCreate(_x, _y, _focused, _power);
    }

    return GamePlayerSunriseShotSpawnSpecsCreate(_x, _y, _focused, _power);
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

/// @func GamePlayerSwordPoseCreate(frame, is_berserk, ship_id)
/// Returns the sword angle, length, and movement state for one sweep frame.
function GamePlayerSwordPoseCreate(_frame, _is_berserk, _ship_id = undefined) {
    if (_ship_id == undefined) {
        _ship_id = SHIP_SUNRISE;
    }

    var _period = GamePlayerSwordPeriodFramesGet(_is_berserk);
    var _phase = (_frame mod _period) / _period;
    var _start_angle = SWORD_START_ANGLE;
    var _end_angle = SWORD_END_ANGLE;
    var _length = SWORD_LENGTH;
    var _angle = _start_angle;
    var _moving = false;

    if (_ship_id == SHIP_SELKIE) {
        _start_angle = 250;
        _end_angle = 650;
        _length = 108;
    }

    if (_phase < 0.25) {
        _angle = _start_angle;
    } else if (_phase < 0.5) {
        _moving = true;
        _angle = lerp(_start_angle, _end_angle, GameCosineEase01((_phase - 0.25) / 0.25));
    } else if (_phase < 0.75) {
        _angle = _end_angle;
    } else {
        _moving = true;
        _angle = lerp(_end_angle, _start_angle, GameCosineEase01((_phase - 0.75) / 0.25));
    }

    return {
        angle: _angle,
        length: _length * (_is_berserk ? BERSERK_SWORD_MULTIPLIER : 1),
        moving: _moving,
    };
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
    _state.sword_pose = GamePlayerSwordPoseCreate(0, false, GameRunShipIdGet());
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
    GameRankEventApply(-12);

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
    GameRankEventApply(-4);
    _state.bomb_timer = BOMB_DURATION_FRAMES;
    GamePlayerBombStateSync(_state);
    GameBulletsCancelAll(global.game_runtime.is_berserk);
    GamePlayerBombSoundPlay();
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
    GameRankEventApply(-25);
    global.game_runtime.lives = DEFAULT_LIVES;
    global.game_runtime.bombs = DEFAULT_BOMBS;
    global.game_runtime.meter = 0;
    global.game_runtime.is_berserk = false;
    global.game_runtime.signals.continue_request = false;
    global.game_runtime.continue_screen = GameContinueStateCreate();

    GamePlayerRespawnStateApply(_state);
    return GameScenePlayerRespawnPositionGet(_camera_x, _camera_y);
}

/// @func GamePlayerGameOverFinalize()
/// Saves the run result, resets runtime state, and returns to the title room.
function GamePlayerGameOverFinalize() {
    if (GameRunIsPractice()) {
        GamePracticeReturnToTitle();
        return;
    }

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

    if (variable_instance_exists(_target_id, "phase_count")
        && variable_instance_exists(_target_id, "phase_max_hp")) {
        GameBossDamageApply(_target_id, SWORD_SWEEP_DAMAGE);
    } else {
        variable_instance_set(_target_id, "hp", variable_instance_get(_target_id, "hp") - SWORD_SWEEP_DAMAGE);
    }

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
        focused_attack: false,
    };
    var _use_sword = false;
    var _ship_id = GameRunShipIdGet();

    _result.focused_attack = _input.autofire_down;

    if (global.game_runtime.is_berserk) {
        _state.fire_hold_frames = FIRE_HOLD_FRAMES + 1;
    } else if (_input.fire_down && !_input.autofire_down) {
        _state.fire_hold_frames += 1;
    } else {
        _state.fire_hold_frames = 0;
    }

    _use_sword = global.game_runtime.is_berserk
        || (_input.fire_down && !_input.autofire_down && _state.fire_hold_frames > FIRE_HOLD_FRAMES);

    if (_use_sword) {
        var _period = GamePlayerSwordPeriodFramesGet(global.game_runtime.is_berserk);

        _state.volley_queue = 0;
        _state.volley_timer = 0;
        _result.previous_pose = GamePlayerSwordPoseCreate(_state.sweep_frame, global.game_runtime.is_berserk, _ship_id);
        _state.sweep_frame = (_state.sweep_frame + 1) mod _period;
        _result.current_pose = GamePlayerSwordPoseCreate(_state.sweep_frame, global.game_runtime.is_berserk, _ship_id);
        _result.sweep_id = GamePlayerSwordSweepIdStep(_state, _result.previous_pose, _result.current_pose);
        _state.sword_pose = _result.current_pose;
        _result.sword_active = true;

        return _result;
    }

    _state.sweep_frame = 0;
    _state.sword_pose = GamePlayerSwordPoseCreate(0, false, _ship_id);

    if ((_input.fire_down || _input.fire_pressed || _input.autofire_down || _input.autofire_pressed)
        && _state.volley_queue <= 0) {
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
        line_height: 17,
        meter_left: _playfield_right + 16,
        meter_top: 86,
        meter_width: GAME_VIEW_WIDTH - _playfield_right - 32,
        meter_height: 12,
        boss_bar_left: _playfield_right + 16,
        boss_bar_top: 152,
        boss_bar_width: GAME_VIEW_WIDTH - _playfield_right - 32,
        boss_bar_height: 8,
        boss_bar_gap: 5,
        sidebar_color: make_color_rgb(22, 12, 44),
        sidebar_alpha: 0.86,
    };
}

/// @func GameGameplayHudLinesCreate()
/// Returns the current HUD label strings for run state, ship, stock, score, rank, and meter.
function GameGameplayHudLinesCreate() {
    GameRuntimeGameplayEnsure();

    var _stage_label = "Stage: " + string(GameCurrentStageGet()) + "/" + string(STAGE_COUNT);
    if (GameRunIsPractice()) {
        var _practice = GamePracticeConfigNormalize(global.game_runtime.practice_config);
        _stage_label = "Practice S" + string(GameCurrentStageGet()) + ": "
            + GamePracticeSegmentNameGet(_practice.segment);
    }

    var _rank_label = "Rank: " + string(GameRankGet()) + " "
        + (GameRankDynamicEnabled() ? "Dynamic" : "Fixed");
    var _meter_label = "Meter: " + string(global.game_runtime.meter) + "/" + string(METER_MAX);
    if (global.game_runtime.is_berserk) {
        _meter_label = "Meter: BERSERK " + string(global.game_runtime.meter) + "/" + string(METER_MAX);
    }

    return [
        _stage_label,
        "Ship: " + GamePlayerShipDisplayNameGet(),
        "Lives: " + string(global.game_runtime.lives),
        "Bombs: " + string(global.game_runtime.bombs),
        "Power: " + string(GamePlayerPowerGet()) + "/" + string(PLAYER_POWER_MAX),
        "Score: " + string(global.game_runtime.score),
        _rank_label,
        _meter_label,
    ];
}

/// @func GamePowerupColorGet(type)
/// Returns the display color for a power-up type.
function GamePowerupColorGet(_type) {
    switch (_type) {
        case POWERUP_POWER:
            return make_color_rgb(255, 210, 88);

        case POWERUP_BOMB:
            return make_color_rgb(174, 116, 255);

        case POWERUP_LIFE:
            return make_color_rgb(255, 122, 172);

        case POWERUP_METER:
            return make_color_rgb(108, 232, 255);
    }

    return make_color_rgb(180, 255, 156);
}

/// @func GamePowerupLabelGet(type)
/// Returns the single-letter label for a power-up type.
function GamePowerupLabelGet(_type) {
    switch (_type) {
        case POWERUP_POWER:
            return "P";

        case POWERUP_BOMB:
            return "B";

        case POWERUP_LIFE:
            return "L";

        case POWERUP_METER:
            return "M";
    }

    return "$";
}

/// @func GamePowerupRewardApply(type)
/// Applies a collected power-up's reward to the current run.
function GamePowerupRewardApply(_type) {
    GameRuntimeGameplayEnsure();

    switch (_type) {
        case POWERUP_POWER:
            var _power_before = global.game_runtime.power;
            global.game_runtime.power = min(PLAYER_POWER_MAX, global.game_runtime.power + 1);
            if (global.game_runtime.power > _power_before) {
                GameRankEventApply(1);
            }
            return true;

        case POWERUP_BOMB:
            global.game_runtime.bombs = min(PLAYER_BOMB_MAX, global.game_runtime.bombs + 1);
            return true;

        case POWERUP_LIFE:
            global.game_runtime.lives = min(PLAYER_LIFE_MAX, global.game_runtime.lives + 1);
            return true;

        case POWERUP_METER:
            if (GamePlayerMeterRewardApply(POWERUP_METER_VALUE)) {
                GameBulletsCancelAll(true);
            }
            return true;
    }

    global.game_runtime.score += POWERUP_SCORE_VALUE;
    return true;
}

/// @func GameScorePickupDropPeriodGet(stage)
/// Returns the enemy-defeat cadence for bonus-score pickups.
function GameScorePickupDropPeriodGet(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);
    return max(6, SCORE_PICKUP_DROP_PERIOD_BASE - ((_stage - 1) div 3));
}

/// @func GameResourceDropChargeThresholdGet(stage)
/// Returns how many point-blank defeats are required to earn one resource pickup.
function GameResourceDropChargeThresholdGet(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);
    return max(2, RESOURCE_DROP_CHARGE_BASE - ((_stage - 1) div 4));
}

/// @func GameResourceDropLimitGet(stage)
/// Caps conditional resource pickups so mastery does not erase stock pressure.
function GameResourceDropLimitGet(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);
    return RESOURCE_DROP_LIMIT_BASE + ((_stage - 1) div 4);
}

/// @func GameEnemyPointBlankResourceCheck(enemy_x, enemy_y, player_x, player_y)
/// Returns whether an enemy was defeated close enough to charge resource recovery.
function GameEnemyPointBlankResourceCheck(_enemy_x, _enemy_y, _player_x, _player_y) {
    return point_distance(_enemy_x, _enemy_y, _player_x, _player_y) <= POINT_BLANK_RESOURCE_RADIUS;
}

/// @func GamePowerupResourceDropTypeChoose(counter)
/// Chooses a useful resource reward without mixing ordinary score pickups into the cycle.
function GamePowerupResourceDropTypeChoose(_counter) {
    if (global.game_runtime.lives < DEFAULT_LIVES) {
        return POWERUP_LIFE;
    }

    if (global.game_runtime.bombs < DEFAULT_BOMBS) {
        return POWERUP_BOMB;
    }

    if (global.game_runtime.power < PLAYER_POWER_MAX) {
        return POWERUP_POWER;
    }

    if (((_counter mod 4) == 0) && global.game_runtime.lives < PLAYER_LIFE_MAX) {
        return POWERUP_LIFE;
    }

    if (((_counter mod 3) == 0) && global.game_runtime.bombs < PLAYER_BOMB_MAX) {
        return POWERUP_BOMB;
    }

    return POWERUP_METER;
}

/// @func GameEnemyPowerupDropTry(x, y, points)
/// Drops sparse score bonuses, while point-blank defeats charge bounded resource recovery.
function GameEnemyPowerupDropTry(_x, _y, _points) {
    GameRuntimeGameplayEnsure();

    global.game_runtime.powerup_drop_counter += 1;

    var _counter = global.game_runtime.powerup_drop_counter;
    var _stage = GameCurrentStageGet();
    var _resource_threshold = GameResourceDropChargeThresholdGet(_stage);
    var _resource_limit = GameResourceDropLimitGet(_stage);
    global.game_runtime.resource_drop_threshold = _resource_threshold;
    var _drop_type = POWERUP_SCORE;
    var _pickup_class = "score";
    var _should_drop = false;
    var _player = instance_find(obj_player, 0);
    var _point_blank = _player != noone && !_player.player_state.hit
        && GameEnemyPointBlankResourceCheck(_x, _y, _player.x, _player.y);

    if (_point_blank && global.game_runtime.resource_drops_this_stage < _resource_limit) {
        global.game_runtime.resource_drop_charge += 1;

        if (global.game_runtime.resource_drop_charge >= _resource_threshold) {
            global.game_runtime.resource_drop_charge = 0;
            global.game_runtime.resource_drops_this_stage += 1;
            global.game_runtime.resource_drop_counter += 1;
            _drop_type = GamePowerupResourceDropTypeChoose(global.game_runtime.resource_drop_counter);
            _pickup_class = "resource";
            _should_drop = true;
        }
    } else if (global.game_runtime.resource_drops_this_stage >= _resource_limit) {
        global.game_runtime.resource_drop_charge = 0;
    }

    if (!_should_drop && ((_counter mod GameScorePickupDropPeriodGet(_stage)) == 0)) {
        _should_drop = true;
    }

    if (!_should_drop) {
        return noone;
    }

    var _powerup = instance_create_layer(_x, _y, "Instances", obj_powerup);
    _powerup.powerup_type = _drop_type;
    _powerup.pickup_class = _pickup_class;
    _powerup.value = _points;
    return _powerup;
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

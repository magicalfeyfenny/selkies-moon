// Core gameplay constants and pure/system helpers. Object events should stay
// thin and delegate reusable rules here; boss pattern execution has its own
// scr_boss_patterns module.

// View, playfield, camera, and stage flow.
#macro GAME_VIEW_WIDTH 640
#macro GAME_VIEW_HEIGHT 360
#macro GAME_VIEW_HALF_WIDTH 320
#macro GAME_VIEW_HALF_HEIGHT 180

#macro PLAYFIELD_HALF_WIDTH 120
#macro PLAYFIELD_HALF_HEIGHT 180
#macro PLAYFIELD_VERTICAL_PADDING 10

#macro CAMERA_HOME_X 320
#macro CAMERA_HOME_Y 180
#macro CAMERA_DRAG_LIMIT 100
#macro CAMERA_DRAG_MARGIN 24
#macro CAMERA_SCROLL_SPEED 1
#macro STAGE_SPAWN_ABOVE_VIEW 100
#macro STAGE_SPAWN_SIDE_MARGIN 16
#macro STAGE_COUNT 5
#macro LEGACY_STAGE_COUNT 10
#macro SHALMII_BOSS_STAGE 1
#macro ASTER_BOSS_STAGE 2
#macro DUAL_BOSS_STAGE 3
#macro MIRA_BOSS_STAGE DUAL_BOSS_STAGE
#macro AISHA_BOSS_STAGE DUAL_BOSS_STAGE
#macro CAELIA_BOSS_STAGE 4
#macro MIRA_BOSS_NAME "Mira"
#macro MIRA_SHIP_NAME "Wildheart"
#macro SHALMII_BOSS_NAME "Shalmii"
#macro SHALMII_SHIP_NAME "Lockstep"
#macro AISHA_BOSS_NAME "Aisha"
#macro AISHA_SHIP_NAME "Wishbound"
#macro ASTER_BOSS_NAME "Aster"
#macro ASTER_SHIP_NAME "Ribbonstar"
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
#macro BOMB_INVULN_FRAMES 120
#macro BOMB_VISUAL_MAX_RADIUS 220
#macro PLAYER_POWER_MAX 5
#macro PLAYER_LIFE_MAX 6
#macro PLAYER_BOMB_MAX 6

#macro SHOT_SPEED 13
#macro PLAYER_SHOT_DAMAGE 1
#macro SWORD_SWEEP_SHOT_EQUIVALENT 240
#macro SWORD_SWEEP_DAMAGE (PLAYER_SHOT_DAMAGE * SWORD_SWEEP_SHOT_EQUIVALENT)
#macro SHOT_VOLLEY_SIZE 6
#macro SHOT_VOLLEY_INTERVAL 3
#macro FIRE_HOLD_FRAMES 60
#macro SHOT_SPRITE_FRONT spr_sunrise_bullet
#macro SHOT_SPRITE_SIDE spr_sunset_bullet
#macro BEAD_BULLET_SPEED 3.5
#macro DIAMOND_BULLET_SPEED 4

// Standard enemy behavior.
#macro BLADE_TURN_SPEED 12
#macro BLADE_RADIAL_SPEED 1.5
#macro BLADE_TURN_RATE_SCALE 0.10
#macro BLADE_MAX_SCREEN_SPEED 3.0
#macro BLADE_MAX_RADIAL_SPEED 2.55
#macro BLADE_REDIRECT_MAX_SCREEN_SPEED 2.75
#macro SUNSET_FLOAT_X_RADIUS 42
#macro SUNSET_FLOAT_Y_RADIUS 14
#macro SUNSET_FLOAT_RATE 3

// Sword geometry and timing.
#macro SWEEP_PERIOD_FRAMES 48
#macro SWORD_START_ANGLE 315
#macro SWORD_END_ANGLE 585
#macro SWORD_LENGTH 128
#macro BERSERK_SWORD_MULTIPLIER 1.5
#macro BERSERK_SWORD_DAMAGE_MULTIPLIER 2

#macro INVULN_TIME 300
#macro BERSERK_ACTIVATION_INVULN_FRAMES 3
#macro BERSERK_PASSIVE_ATTACK_INTERVAL 30
#macro BERSERK_PASSIVE_ATTACK_GAIN 1
#macro BERSERK_POINT_BLANK_RADIUS 108
#macro BERSERK_POINT_BLANK_SHOT_GAIN 1
#macro BERSERK_POINT_BLANK_SWORD_GAIN 24
#macro ENEMY_MEDAL_BERSERK_GAIN 8
#macro BULLET_CANCEL_SCORE_BONUS 100
#macro BULLET_CANCEL_BERSERK_GAIN 1
#macro METER_MAX 1000

// Continue and boss encounter flow.
#macro CONTINUE_OPTION_YES 0
#macro CONTINUE_OPTION_NO 1
#macro GAME_OVER_DELAY_FRAMES 90

#macro STAGE_LENGTH_FRAMES 2400
#macro BOSS_PHASE_COUNT 3
#macro FINAL_BOSS_PHASE_COUNT 15
#macro FINAL_BOSS_EXPANDED_PHASE_COUNT 14
#macro BOSS_PHASE_HP 300
#macro BOSS_PHASE_HP_STAGE_STEP 30
#macro BOSS_PHASE_MIN_HP 240
#macro BOSS_DAMAGE_SCALE_MIN 0.2
#macro BOSS_DESTRUCTION_FRAMES 90
#macro BOSS_PHASE3_FREEZE_FRAMES 24
#macro BOSS_PHASE3_REDIRECT_SPEED 1.5
#macro BOSS_PHASE3_REDIRECT_ACCELERATION 0.05
#macro BOSS_PHASE_NOTICE_FRAMES 120
#macro BOSS_PHASE_NOTICE_FADE_IN_FRAMES 12
#macro BOSS_PHASE_NOTICE_FADE_OUT_FRAMES 30
#macro BOSS_PHASE_TRANSITION_FRAMES 72
#macro BOSS_PHASE_REFILL_FRAMES 48

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
#macro RESOURCE_DROP_CHARGE_BASE 4
#macro RESOURCE_DROP_DEFEAT_MULTIPLIER 6
#macro RESOURCE_DROP_LIMIT_BASE 3
#macro SCORE_PICKUP_DROP_PERIOD_BASE 9
#macro RANK_MIN 0
#macro RANK_MAX 50
#macro RANK_DEFAULT 50
#macro RANK_PASSIVE_INTERVAL 600
#macro RANK_DEFEATS_PER_POINT 12
#macro RANK_HYPER_GAIN 15
#macro PRACTICE_SEGMENT_FULL "full"
#macro PRACTICE_SEGMENT_WAVES "waves"
#macro PRACTICE_SEGMENT_BOSS "boss"
#macro ENEMY_VARIANT_MOTH "moth"
#macro ENEMY_VARIANT_KELP "kelp"
#macro ENEMY_VARIANT_WISP "wisp"
#macro ENEMY_VARIANT_NEEDLE "needle"
#macro ENEMY_VARIANT_MIRROR "mirror"
#macro ENEMY_VARIANT_TIDEGLASS "tideglass"
#macro ENEMY_VARIANT_SALTWIND "saltwind"
#macro ENEMY_VARIANT_BRAMBLE "bramble"
#macro ENEMY_VARIANT_BLOODTIDE "bloodtide"
#macro ENEMY_FORGE_SPARK "forge_spark"
#macro ENEMY_ANVIL_FAMILIAR "anvil_familiar"
#macro ENEMY_BELLOWS_IMP "bellows_imp"
#macro ENEMY_HAMMER_CHERUB "hammer_cherub"
#macro ENEMY_RIBBON_HARE "ribbon_hare"
#macro ENEMY_WINGED_STAFF "winged_staff"
#macro ENEMY_LAVENDER_KNOT "lavender_knot"
#macro ENEMY_SALTWIND_PINWHEEL "saltwind_pinwheel"
#macro ENEMY_SPADE_FAMILIAR "spade_familiar"
#macro ENEMY_DEALER_MASK "dealer_mask"
#macro ENEMY_ORDER_TALISMAN "order_talisman"
#macro ENEMY_CHAOS_SHARD "chaos_shard"
#macro ENEMY_CLOCKWORK_PLANET "clockwork_planet"
#macro ENEMY_ASTROLABE_EYE "astrolabe_eye"
#macro ENEMY_CONSTELLATION_LANCE "constellation_lance"
#macro ENEMY_BLOODSTAR_HEART "bloodstar_heart"
#macro ENEMY_VIOLET_BEE "violet_bee"
#macro ENEMY_TWILIGHT_MAYFLY "twilight_mayfly"
#macro ENEMY_THORN_RELIQUARY "thorn_reliquary"
#macro ENEMY_CHAKRAM_SERAPH "chakram_seraph"

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
        rank: RANK_MIN,
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

/// @func GamePracticeSegmentNameForStageGet(segment, stage)
/// Names the boss seam honestly on chapters that end in a pattern gauntlet.
function GamePracticeSegmentNameForStageGet(_segment, _stage) {
    if (_segment == PRACTICE_SEGMENT_BOSS && !GameStageHasCharacterBoss(_stage)) {
        return "Finale Wave";
    }

    return GamePracticeSegmentNameGet(_segment);
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
        { label: "Berserk Meter", value: string(global.game_runtime.meter) },
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
            var _options = GameTitleConfigEntriesCreate(false);
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

/// @func GamePauseDrawRow(x, y, width, label, value, selected, meter_ratio)
/// Draws one textbox-styled pause row.
function GamePauseDrawRow(_x, _y, _width, _label, _value, _selected, _meter_ratio = -1) {
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

    if (_meter_ratio >= 0) {
        GameUiDrawVolumeGauge(_x + 140, _x + _width - 58,
            _y + 14, _meter_ratio, _selected);
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
            var _options = GameTitleConfigEntriesCreate(false);
            var _options_start_y = 78;
            var _options_gap = 34;
            for (var o = 0; o < array_length(_options); o++) {
                var _option_ratio = struct_exists(_options[o], "meter_ratio")
                    ? _options[o].meter_ratio : -1;
                GamePauseDrawRow(170, _options_start_y + (o * _options_gap), 300,
                    _options[o].label, _options[o].value,
                    o == _state.options_index, _option_ratio);
            }
            GamePauseDrawRow(170, _options_start_y + (array_length(_options) * _options_gap), 300, "Back", "",
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
    var _help_line = "Move to select   " + GameInputActiveBindingLabel("fire") + " confirms";
    switch (_state.page) {
        case "options":
        case "practice":
            _help_line = "Move to select / adjust   "
                + GameInputActiveBindingLabel("fire") + " toggles";
            break;

        case "quit_confirm":
            _help_line = "Move left / right to choose   "
                + GameInputActiveBindingLabel("fire") + " confirms";
            break;
    }
    GameUiDrawOutlinedText(_help_line, GAME_VIEW_HALF_WIDTH, 306,
        _palette.muted_text_color);
    GameUiDrawOutlinedText(GameInputActiveBindingLabel("bomb") + " returns   "
        + GameInputActiveBindingLabel("pause") + " resumes",
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
        global.game_runtime.resource_drop_threshold = GameResourceDropDefeatPeriodGet(
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

/// @func GameRankDefeatRewardApply()
/// Converts ordinary shootdowns into deliberately slow one-point rank gains.
function GameRankDefeatRewardApply() {
    GameRuntimeGameplayEnsure();

    if (!GameRankDynamicEnabled()) {
        return GameRankGet();
    }

    global.game_runtime.rank_defeats += 1;
    if (global.game_runtime.rank_defeats >= RANK_DEFEATS_PER_POINT) {
        global.game_runtime.rank_defeats -= RANK_DEFEATS_PER_POINT;
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

/// @func GameBladeMotionStepCreate(radius, radial_speed, turn_speed, rank_speed_scale)
/// Converts authored spiral values into one bounded screen-space motion step.
/// Authored turn values are expressive pattern weights, not literal degrees per
/// frame: applying them literally makes outer blades cross dozens of pixels in
/// one step. The chord calculation below keeps every spiral below the same fair
/// velocity ceiling while preserving its rotation direction and overall shape.
function GameBladeMotionStepCreate(_radius, _radial_speed, _turn_speed, _rank_speed_scale = 1) {
    var _old_radius = max(0, _radius);
    var _radial_step = clamp(abs(_radial_speed) * max(0, _rank_speed_scale),
        0, min(BLADE_MAX_RADIAL_SPEED, BLADE_MAX_SCREEN_SPEED));
    var _new_radius = _old_radius + _radial_step;
    var _desired_turn = abs(_turn_speed) * BLADE_TURN_RATE_SCALE;
    var _turn_step = _desired_turn;

    if (_old_radius > 0 && _new_radius > 0) {
        var _cos_limit = ((_old_radius * _old_radius) + (_new_radius * _new_radius)
            - (BLADE_MAX_SCREEN_SPEED * BLADE_MAX_SCREEN_SPEED))
            / (2 * _old_radius * _new_radius);

        if (_cos_limit >= 1) {
            _turn_step = 0;
        } else if (_cos_limit > -1) {
            _turn_step = min(_desired_turn, arccos(_cos_limit) * (180 / pi));
        }
    }

    var _turn_radians = _turn_step * (pi / 180);
    var _screen_step = sqrt(max(0,
        (_old_radius * _old_radius) + (_new_radius * _new_radius)
        - (2 * _old_radius * _new_radius * cos(_turn_radians))));

    return {
        radial_step: _radial_step,
        turn_step: _turn_step,
        screen_step: _screen_step,
    };
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
        global.game_runtime.resource_drop_threshold = GameResourceDropDefeatPeriodGet(_practice.stage);
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
    global.game_runtime.rank = RANK_MIN;
    global.game_runtime.rank_locked = false;
    global.game_runtime.resource_drop_threshold = GameResourceDropDefeatPeriodGet(1);

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
        background_frame: 0,
        background_route: "travel",
        background_route_blend: 0,
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
    _state.background_frame = 0;
    _state.background_route = "travel";
    _state.background_route_blend = 0;
    _state.camera_y = CAMERA_HOME_Y;
    _state.target_x = CAMERA_HOME_X;
    _state.scroll_speed = CAMERA_SCROLL_SPEED;
    _state.mode = "scroll";
    _state.boss_spawned = false;
    _state.boss_defeated = false;
    _state.stage_clear_timer = 0;

    if (_practice.segment == PRACTICE_SEGMENT_BOSS) {
        if (GameStageHasCharacterBoss(_practice.stage)) {
            _state.frame = STAGE_LENGTH_FRAMES;
            _state.camera_y = CAMERA_HOME_Y - STAGE_LENGTH_FRAMES;
            _state.scroll_speed = 0;
            _state.mode = "boss_intro";
            GameSceneBackgroundBossRouteBegin(_state);
            global.game_runtime.stage_frame = STAGE_LENGTH_FRAMES;
            global.game_runtime.stage_notice_timer = 0;
        } else {
            // Removed abstract bosses leave their signature patterns behind as
            // the last ten seconds of a normal enemy gauntlet.
            _state.frame = STAGE_LENGTH_FRAMES - 600;
            _state.camera_y = CAMERA_HOME_Y - _state.frame;
            global.game_runtime.stage_frame = _state.frame;
            global.game_runtime.stage_notice_timer = 0;
        }
    } else {
        global.game_runtime.stage_notice_timer = STAGE_NOTICE_FRAMES;
    }

    return true;
}

/// @func GameSceneBackgroundStep(state)
/// Advances presentation-only 3D travel independently of the anchored 2D field.
function GameSceneBackgroundStep(_state) {
    _state.background_frame += 1;

    if (_state.background_route == "boss") {
        _state.background_route_blend = min(1, _state.background_route_blend + (1 / 150));
    } else {
        _state.background_route_blend = max(0, _state.background_route_blend - (1 / 90));
    }

    return _state.background_frame;
}

/// @func GameSceneBackgroundBossRouteBegin(state)
/// Changes the infinite 3D route at a boss seam without stopping its forward motion.
function GameSceneBackgroundBossRouteBegin(_state) {
    _state.background_route = "boss";
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

/// @func GameStageHasCharacterBoss(stage)
/// Only the five guardian girls and the selected route's lover are bosses.
function GameStageHasCharacterBoss(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);
    return _stage >= STAGE_COUNT || is_struct(GameCharacterBossInfoCreate(_stage));
}

/// @func GameStageInfoGet(stage)
/// Returns display metadata for one of the five stage chapters.
function GameStageInfoGet(_stage) {
    _stage = clamp(_stage, 1, STAGE_COUNT);

    var _stages = [
        { name: "Shalmii's Blacksmith Citadel", subtitle: "hammers ring above rivers of molten steel", accent: make_color_rgb(255, 214, 112) },
        { name: "Aster's Moonrabbit Forest", subtitle: "bunny trails wind beneath an enchanted canopy", accent: make_color_rgb(255, 146, 212) },
        { name: "Mira & Aisha's Grand Illusion", subtitle: "casino trickery meets sorcery beneath Vegas lights", accent: make_color_rgb(112, 196, 255) },
        { name: "Caelia's Deep-Space Orrery", subtitle: "galaxies turn around the violet gate", accent: make_color_rgb(238, 172, 255) },
        { name: "The Infinite Violet Field", subtitle: "flowers and vines reach beyond the horizon", accent: make_color_rgb(255, 236, 138) },
    ];

    return _stages[_stage - 1];
}

/// @func GameStageBackgroundThemeCreate(stage)
/// Returns the palette and architectural motif for the infinite perspective set.
function GameStageBackgroundThemeCreate(_stage) {
    var _themes = [
        { motif: "runes", sky_top: make_color_rgb(20, 12, 30), sky_bottom: make_color_rgb(94, 58, 46), floor: make_color_rgb(46, 30, 44), accent: make_color_rgb(255, 214, 112) },
        { motif: "moonrabbit_forest", sky_top: make_color_rgb(8, 24, 24), sky_bottom: make_color_rgb(42, 88, 62), floor: make_color_rgb(25, 48, 38), accent: make_color_rgb(255, 146, 212) },
        { motif: "vegas_sorcery", sky_top: make_color_rgb(12, 8, 34), sky_bottom: make_color_rgb(88, 24, 96), floor: make_color_rgb(28, 24, 62), accent: make_color_rgb(112, 196, 255) },
        { motif: "deep_space", sky_top: make_color_rgb(4, 4, 18), sky_bottom: make_color_rgb(38, 16, 78), floor: make_color_rgb(18, 12, 42), accent: make_color_rgb(238, 172, 255) },
        { motif: "violets", sky_top: make_color_rgb(10, 4, 24), sky_bottom: make_color_rgb(62, 24, 84), floor: make_color_rgb(28, 16, 52), accent: make_color_rgb(194, 126, 255) },
    ];

    return _themes[clamp(_stage, 1, STAGE_COUNT) - 1];
}

/// @func GameStageLegacyPatternStageGet(stage, frame)
/// Maps each consolidated stage section onto the old wave/pattern material.
function GameStageLegacyPatternStageGet(_stage, _frame = 0) {
    _stage = clamp(_stage, 1, STAGE_COUNT);
    var _progress = clamp(_frame / max(1, STAGE_LENGTH_FRAMES), 0, 0.9999);

    switch (_stage) {
        case 1: return 1 + floor(_progress * 2);       // old 1-2
        case 2: return 3 + floor(_progress * 2);       // old 3-4
        case 3: return 5 + floor(_progress * 3);       // old 5-7
        case 4: return 8 + floor(_progress * 2);       // old 8-9
        case 5: return 10;                             // old 10
    }

    return 1;
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
    global.game_runtime.resource_drop_threshold = GameResourceDropDefeatPeriodGet(global.game_runtime.current_stage);
    global.game_runtime.resource_drops_this_stage = 0;
    GameStageNoticeRestart();

    _state.frame = 0;
    _state.background_frame = 0;
    _state.background_route = "travel";
    _state.background_route_blend = 0;
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
        _state.scroll_speed = 0;
        if (GameStageHasCharacterBoss(GameCurrentStageGet())) {
            _state.mode = "boss_intro";
            GameSceneBackgroundBossRouteBegin(_state);
            return "boss_intro";
        }

        _state.mode = "stage_complete";
        return "stage_complete";
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
    var _speed = PLAYER_MOVE_SPEED * (_input.focus_down ? PLAYER_FOCUS_SPEED_MULTIPLIER : 1);

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

/// @func GameStageDirectorShouldRun(state)
/// Returns whether the code-driven stage director should currently advance.
function GameStageDirectorShouldRun(_state) {
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

/// @func GameEnemyBulletFlashAlphaGet(age, phase)
/// Returns a restrained readability pulse for every enemy projectile.
function GameEnemyBulletFlashAlphaGet(_age, _phase = 0) {
    return 0.045 + (0.055 * (0.5 + (0.5 * dsin((_age * 7.2) + _phase))));
}

/// @func GameStageEnemyRosterCreate(stage)
/// Returns four basic enemies authored specifically for one consolidated stage.
/// Pattern ids name the Memory Core/boss family being miniaturized; none of the
/// old basic-enemy identities are used as presentation authority.
function GameStageEnemyRosterCreate(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT)) {
        case 1:
            return [
                { id: ENEMY_FORGE_SPARK, name: "Forge Spark", role: "chaser", pattern: "tideglass_fan", shape: "spark", sprite: spr_enemy_forge_spark, accent: make_color_rgb(255, 174, 72), core: make_color_rgb(255, 238, 166) },
                { id: ENEMY_ANVIL_FAMILIAR, name: "Anvil Familiar", role: "anchor", pattern: "tideglass_spiral", shape: "anvil", sprite: spr_enemy_anvil_familiar, accent: make_color_rgb(92, 112, 142), core: make_color_rgb(255, 156, 72) },
                { id: ENEMY_BELLOWS_IMP, name: "Bellows Imp", role: "dancer", pattern: "shalmii_shockwave", shape: "bellows", sprite: spr_enemy_bellows_imp, accent: make_color_rgb(154, 72, 66), core: make_color_rgb(255, 214, 112) },
                { id: ENEMY_HAMMER_CHERUB, name: "Hammer Cherub", role: "lancer", pattern: "shalmii_hammerfall", shape: "hammer", sprite: spr_enemy_hammer_cherub, accent: make_color_rgb(198, 166, 255), core: make_color_rgb(255, 214, 112) },
            ];

        case 2:
            return [
                { id: ENEMY_RIBBON_HARE, name: "Ribbon Hare", role: "chaser", pattern: "saltwind_gale", shape: "hare", sprite: spr_enemy_ribbon_hare, accent: make_color_rgb(255, 164, 218), core: make_color_rgb(224, 206, 255) },
                { id: ENEMY_WINGED_STAFF, name: "Winged Staff", role: "anchor", pattern: "kelp_wall", shape: "staff", sprite: spr_enemy_winged_staff, accent: make_color_rgb(184, 154, 255), core: make_color_rgb(118, 236, 255) },
                { id: ENEMY_LAVENDER_KNOT, name: "Lavender Knot", role: "dancer", pattern: "aster_ribbon_loop", shape: "knot", sprite: spr_enemy_lavender_knot, accent: make_color_rgb(214, 166, 255), core: make_color_rgb(255, 244, 220) },
                { id: ENEMY_SALTWIND_PINWHEEL, name: "Saltwind Pinwheel", role: "lancer", pattern: "saltwind_spindrift", shape: "pinwheel", sprite: spr_enemy_saltwind_pinwheel, accent: make_color_rgb(126, 255, 196), core: make_color_rgb(255, 174, 234) },
            ];

        case 3:
            return [
                { id: ENEMY_SPADE_FAMILIAR, name: "Monte Familiar", role: "chaser", pattern: "mira_three_card_monte", shape: "spade", sprite: spr_enemy_spade_familiar, accent: make_color_rgb(255, 146, 212), core: make_color_rgb(24, 12, 42) },
                { id: ENEMY_DEALER_MASK, name: "Loaded Dealer Mask", role: "anchor", pattern: "mira_loaded_dice", shape: "mask", sprite: spr_enemy_dealer_mask, accent: make_color_rgb(255, 214, 112), core: make_color_rgb(255, 244, 220) },
                { id: ENEMY_ORDER_TALISMAN, name: "Arcane Talisman", role: "dancer", pattern: "aisha_arcane_circle", shape: "talisman", sprite: spr_enemy_order_talisman, accent: make_color_rgb(112, 196, 255), core: make_color_rgb(255, 214, 112) },
                { id: ENEMY_CHAOS_SHARD, name: "Mirrored Hex", role: "lancer", pattern: "aisha_mirrored_hex", shape: "shard", sprite: spr_enemy_chaos_shard, accent: make_color_rgb(118, 236, 255), core: make_color_rgb(255, 96, 196) },
            ];

        case 4:
            return [
                { id: ENEMY_CLOCKWORK_PLANET, name: "Clockwork Planet", role: "chaser", pattern: "bloodtide_pulse", shape: "planet", sprite: spr_enemy_clockwork_planet, accent: make_color_rgb(238, 172, 255), core: make_color_rgb(255, 92, 126) },
                { id: ENEMY_ASTROLABE_EYE, name: "Astrolabe Eye", role: "anchor", pattern: "caelia_astrolabe", shape: "astrolabe", sprite: spr_enemy_astrolabe_eye, accent: make_color_rgb(255, 214, 112), core: make_color_rgb(118, 236, 255) },
                { id: ENEMY_CONSTELLATION_LANCE, name: "Constellation Lance", role: "dancer", pattern: "caelia_constellation", shape: "constellation", sprite: spr_enemy_constellation_lance, accent: make_color_rgb(188, 176, 255), core: make_color_rgb(255, 244, 220) },
                { id: ENEMY_BLOODSTAR_HEART, name: "Bloodstar Heart", role: "lancer", pattern: "bloodtide_hunt", shape: "heart", sprite: spr_enemy_bloodstar_heart, accent: make_color_rgb(255, 72, 116), core: make_color_rgb(255, 210, 112) },
            ];

        case 5:
            return [
                { id: ENEMY_VIOLET_BEE, name: "Violet Bee", role: "chaser", pattern: "rose_thorn_arc", shape: "bee", sprite: spr_violet_bee, accent: make_color_rgb(255, 214, 112), core: make_color_rgb(194, 126, 255) },
                { id: ENEMY_TWILIGHT_MAYFLY, name: "Twilight Mayfly", role: "dancer", pattern: "rose_petal_spiral", shape: "mayfly", sprite: spr_twilight_mayfly, accent: make_color_rgb(118, 236, 255), core: make_color_rgb(255, 132, 92) },
                { id: ENEMY_THORN_RELIQUARY, name: "Thorn Reliquary", role: "anchor", pattern: "rose_bloom", shape: "reliquary", sprite: spr_enemy_thorn_reliquary, accent: make_color_rgb(255, 96, 196), core: make_color_rgb(88, 210, 150) },
                { id: ENEMY_CHAKRAM_SERAPH, name: "Chakram Seraph", role: "lancer", pattern: "chakram_orbit", shape: "chakram", sprite: spr_enemy_chakram_seraph, accent: make_color_rgb(255, 174, 234), core: make_color_rgb(118, 236, 255) },
            ];
    }

    return [];
}

/// @func GameStageEnemyDefinitionGet(stage, enemy_id)
/// Resolves one stage-authored enemy definition by id.
function GameStageEnemyDefinitionGet(_stage, _enemy_id) {
    var _roster = GameStageEnemyRosterCreate(_stage);
    for (var i = 0; i < array_length(_roster); i++) {
        if (_roster[i].id == _enemy_id) {
            return _roster[i];
        }
    }

    return (array_length(_roster) > 0) ? _roster[0] : undefined;
}

/// @func GameEnemyVariantConfigure(enemy, kind, stage, slot, slot_count)
/// Applies variant stats and an initial stage-scaled movement profile.
function GameEnemyVariantConfigure(_enemy, _kind, _stage, _slot = 0, _slot_count = 1) {
    if (!instance_exists(_enemy)) {
        return noone;
    }

    _stage = clamp(_stage, 1, STAGE_COUNT);
    var _definition = GameStageEnemyDefinitionGet(_stage, _kind);
    if (!is_struct(_definition)) {
        return noone;
    }

    _enemy.variant_kind = _definition.id;
    _enemy.enemy_name = _definition.name;
    _enemy.variant_role = _definition.role;
    _enemy.pattern_kind = _definition.pattern;
    _enemy.draw_shape = _definition.shape;
    _enemy.variant_sprite = _definition.sprite;
    _enemy.accent_color = _definition.accent;
    _enemy.core_color = _definition.core;
    _enemy.stage_rank = _stage;
    _enemy.slot_index = _slot;
    _enemy.slot_count = max(1, _slot_count);
    _enemy.age = 0;
    _enemy.fire_timer = irandom(20);
    _enemy.fire_interval = max(34, 82 - (_stage * 3));
    _enemy.wave_phase = irandom(359);
    _enemy.anchor_offset_x = 0;
    _enemy.anchor_offset_y = 0;
    _enemy.flyaway_committed = false;
    _enemy.hit_radius = 18;
    _enemy.points = 900 + (_stage * 90);
    _enemy.hp = 14 + (_stage * 2);
    _enemy.move_direction = 270;
    _enemy.move_speed = 1.05 + (_stage * 0.04);

    switch (_definition.role) {
        case "anchor":
            _enemy.hp = 30 + (_stage * 3);
            _enemy.points = 1600 + (_stage * 110);
            _enemy.hit_radius = 20;
            _enemy.move_speed = 0.36;
            _enemy.fire_interval = max(48, 98 - (_stage * 4));
            break;

        case "dancer":
            _enemy.hp = 22 + (_stage * 3);
            _enemy.points = 1350 + (_stage * 100);
            _enemy.hit_radius = 17;
            _enemy.move_speed = 0;
            _enemy.fire_interval = max(40, 82 - (_stage * 3));
            break;

        case "lancer":
            _enemy.hp = 12 + _stage;
            _enemy.points = 1050 + (_stage * 85);
            _enemy.hit_radius = 14;
            _enemy.move_speed = 2.0 + (_stage * 0.07);
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

/// @func GameStageEnemyBulletDecorate(bullet, enemy_id)
/// Assigns the final-stage insects their own readable projectile silhouettes.
function GameStageEnemyBulletDecorate(_bullet, _enemy_id) {
    if (!instance_exists(_bullet)) {
        return noone;
    }

    switch (_enemy_id) {
        case ENEMY_VIOLET_BEE:
            _bullet.sprite_index = spr_violet_bee_bullet;
            _bullet.image_xscale = 1;
            _bullet.image_yscale = 1;
            break;

        case ENEMY_TWILIGHT_MAYFLY:
            _bullet.sprite_index = spr_twilight_mayfly_bullet;
            _bullet.image_xscale = 1;
            _bullet.image_yscale = 1;
            break;
    }

    return _bullet;
}

/// @func GameStageEnemyBulletSpawn(enemy_id, x, y, direction, speed, object_index)
/// Spawns a linear bullet and applies its stage-family presentation.
function GameStageEnemyBulletSpawn(_enemy_id, _x, _y, _direction, _speed, _object_index = obj_bullet_bead) {
    return GameStageEnemyBulletDecorate(
        GameEnemyBulletLinearSpawn(_x, _y, _direction, _speed, _object_index),
        _enemy_id);
}

/// @func GameStageDirectorVariantWaveSpawn(camera_x, camera_y, kind, count)
/// Spawns a row of stage-variant enemies inside the current spawn band.
function GameStageDirectorVariantWaveSpawn(_camera_x, _camera_y, _kind, _count = 1) {
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

/// @func GameStageBasicEnemyWaveSpawn(camera_x, camera_y, stage, roster_index, count)
/// Spawns one wave from the active stage's four bespoke basic-enemy families.
function GameStageBasicEnemyWaveSpawn(_camera_x, _camera_y, _stage, _roster_index, _count = 1) {
    var _roster = GameStageEnemyRosterCreate(_stage);
    if (array_length(_roster) <= 0) {
        return 0;
    }

    _roster_index = clamp(round(_roster_index), 0, array_length(_roster) - 1);
    return GameStageDirectorVariantWaveSpawn(
        _camera_x, _camera_y, _roster[_roster_index].id, max(1, _count));
}

/// @func GameStageEliteVariantKindGet(stage, cycle)
/// Rehomes the four removed abstract-boss pattern families on elite enemies.
function GameStageEliteVariantKindGet(_stage, _cycle = 0) {
    switch (clamp(_stage, 1, LEGACY_STAGE_COUNT)) {
        case 1: return ENEMY_VARIANT_TIDEGLASS;
        case 3: return ENEMY_VARIANT_SALTWIND;
        case 4: return ENEMY_VARIANT_BRAMBLE;
        case 8: return ENEMY_VARIANT_BLOODTIDE;
    }

    var _elites = [ENEMY_VARIANT_TIDEGLASS, ENEMY_VARIANT_SALTWIND,
        ENEMY_VARIANT_BRAMBLE, ENEMY_VARIANT_BLOODTIDE];
    return _elites[abs(_stage + _cycle) mod array_length(_elites)];
}

/// @func GameStageDirectorStep(state)
/// Runs the per-stage wave director for the active scrolling section.
function GameStageDirectorStep(_state) {
    if (!GameStageDirectorShouldRun(_state)) {
        return 0;
    }

    var _stage = GameCurrentStageGet();
    var _frame = _state.frame;
    var _pattern_stage = GameStageLegacyPatternStageGet(_stage, _frame);
    var _spawned = 0;

    if (_frame < 45) {
        return 0;
    }

    var _rank = GameRankGet();
    var _chaser_interval = GameRankSpawnIntervalGet(max(64, 142 - (_pattern_stage * 5)), 48, _rank);
    var _anchor_interval = GameRankSpawnIntervalGet(max(126, 252 - (_pattern_stage * 8)), 92, _rank);
    var _dancer_interval = GameRankSpawnIntervalGet(max(96, 206 - (_pattern_stage * 7)), 72, _rank);
    var _lancer_interval = GameRankSpawnIntervalGet(max(148, 302 - (_pattern_stage * 9)), 108, _rank);

    if ((_frame mod _chaser_interval) == 0) {
        _spawned += GameStageBasicEnemyWaveSpawn(
            _state.target_x, _state.camera_y, _stage, 0, 2 + (_pattern_stage >= 6));
    }

    if (((_frame + 41) mod _anchor_interval) == 0) {
        _spawned += GameStageBasicEnemyWaveSpawn(_state.target_x, _state.camera_y, _stage, 1, 1);
    }

    if (((_frame + 83 + (_pattern_stage * 7)) mod _dancer_interval) == 0) {
        _spawned += GameStageBasicEnemyWaveSpawn(
            _state.target_x, _state.camera_y, _stage, 2, 1 + (_pattern_stage >= 8));
    }

    if (((_frame + 127 + (_pattern_stage * 11)) mod _lancer_interval) == 0) {
        _spawned += GameStageBasicEnemyWaveSpawn(
            _state.target_x, _state.camera_y, _stage, 3, 1 + (_pattern_stage >= 10));
    }

    return _spawned;
}

/// @func GameStageBalanceReportCreate(stage)
/// Estimates whether one stage stays inside no-continue clearability bounds.
function GameStageBalanceReportCreate(_stage, _rank = RANK_DEFAULT) {
    _stage = clamp(_stage, 1, STAGE_COUNT);
    // Use the newest legacy section in the consolidated chapter for a
    // deliberately conservative pressure/viability estimate.
    var _pattern_stage = GameStageLegacyPatternStageGet(_stage, STAGE_LENGTH_FRAMES - 1);

    var _chaser_interval = GameRankSpawnIntervalGet(max(64, 142 - (_pattern_stage * 5)), 48, _rank);
    var _anchor_interval = GameRankSpawnIntervalGet(max(126, 252 - (_pattern_stage * 8)), 92, _rank);
    var _dancer_interval = GameRankSpawnIntervalGet(max(96, 206 - (_pattern_stage * 7)), 72, _rank);
    var _lancer_interval = GameRankSpawnIntervalGet(max(148, 302 - (_pattern_stage * 9)), 108, _rank);
    var _chaser_count = 0;
    var _anchor_count = 0;
    var _dancer_count = 0;
    var _lancer_count = 0;
    var _chaser_wave_size = 2 + (_pattern_stage >= 6);
    var _dancer_wave_size = 1 + (_pattern_stage >= 8);
    var _lancer_wave_size = 1 + (_pattern_stage >= 10);

    for (var frame = 45; frame < STAGE_LENGTH_FRAMES; frame++) {
        if ((frame mod _chaser_interval) == 0) {
            _chaser_count += _chaser_wave_size;
        }

        if (((frame + 41) mod _anchor_interval) == 0) {
            _anchor_count += 1;
        }

        if (((frame + 83 + (_pattern_stage * 7)) mod _dancer_interval) == 0) {
            _dancer_count += _dancer_wave_size;
        }

        if (((frame + 127 + (_pattern_stage * 11)) mod _lancer_interval) == 0) {
            _lancer_count += _lancer_wave_size;
        }
    }

    var _total_enemy_count = _chaser_count + _anchor_count + _dancer_count + _lancer_count;
    var _score_drop_period = GameScorePickupDropPeriodGet(_stage);
    var _resource_drop_threshold = GameResourceDropDefeatPeriodGet(_stage);
    var _resource_drop_limit = GameResourceDropLimitGet(_stage);
    var _estimated_score_pickups = _total_enemy_count div _score_drop_period;
    var _estimated_resource_pickups = min(_resource_drop_limit, _total_enemy_count div _resource_drop_threshold);
    var _estimated_powerups = _estimated_score_pickups + _estimated_resource_pickups;
    var _max_spawn_pressure = (ceil(300 / _chaser_interval) * _chaser_wave_size)
        + ceil(300 / _anchor_interval)
        + (ceil(300 / _dancer_interval) * _dancer_wave_size)
        + (ceil(300 / _lancer_interval) * _lancer_wave_size);

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
    var _reliable_focus_damage = max(1, min(_sunrise_damage, _selkie_damage) * _boss_damage_scale);
    var _maximum_focus_damage = max(1, max(_sunrise_damage, _selkie_damage) * _boss_damage_scale);
    var _boss_total_hp = _boss_phase_hp * _boss_phase_count;
    var _focus_boss_clear_frames = ceil(_boss_total_hp / _reliable_focus_damage) * SHOT_VOLLEY_INTERVAL;
    var _fastest_phase_clear_frames = ceil(_boss_phase_hp / _maximum_focus_damage) * SHOT_VOLLEY_INTERVAL;
    var _expected_boss_frames = _boss_phase_count
        * ((GameBossPhaseTargetSecondsGet(_stage) * 60) + BOSS_PHASE_TRANSITION_FRAMES);
    var _no_continue_viable = _estimated_score_pickups > 4
        && _max_spawn_pressure < 42
        && _focus_boss_clear_frames <= (_expected_boss_frames * 1.08);

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
        focus_down: false,
        focus_pressed: false,
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
    _input.focus_down = GameInputVerbDown("focus");
    _input.focus_pressed = GameInputVerbPressed("focus");
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
        attack_meter_timer: 0,
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
    // Attack banners name the spell itself; the boss identity already owns a
    // dedicated gutter label and should not be repeated in limited playfield space.
    var _boss_prefixes = [
        "shalmii_", "aster_", "mira_", "aisha_", "sisters_", "caelia_",
        "moon_", "selkie_", "sunset_", "sunrise_", "boss_"
    ];
    var _prefix_removed = true;

    while (_prefix_removed) {
        _prefix_removed = false;
        for (var prefix = 0; prefix < array_length(_boss_prefixes); prefix++) {
            var _prefix = _boss_prefixes[prefix];
            if (string_pos(_prefix, _id) == 1) {
                _id = string_delete(_id, 1, string_length(_prefix));
                _prefix_removed = true;
                break;
            }
        }
    }

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

    switch (_stage) {
        case 1: return 2;
        case 2: return 4;
        case DUAL_BOSS_STAGE: return 2;
        case 4: return 6;
    }

    return 2;
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

    var _sunrise_focus = GamePlayerShotSpawnSpecsCreate(0, 0, SHIP_SUNRISE, true, PLAYER_POWER_MAX);
    var _selkie_focus = GamePlayerShotSpawnSpecsCreate(0, 0, SHIP_SELKIE, true, PLAYER_POWER_MAX);
    var _sunrise_damage = 0;
    var _selkie_damage = 0;

    for (var sunrise = 0; sunrise < array_length(_sunrise_focus); sunrise++) {
        _sunrise_damage += _sunrise_focus[sunrise].damage;
    }

    for (var selkie = 0; selkie < array_length(_selkie_focus); selkie++) {
        _selkie_damage += _selkie_focus[selkie].damage;
    }

    var _focus_damage_per_volley = max(1, min(_sunrise_damage, _selkie_damage));
    var _focus_volleys_per_second = 60 / SHOT_VOLLEY_INTERVAL;
    var _target_seconds = GameBossPhaseTargetSecondsGet(_stage);
    var _damage_scale = GameBossDamageScaleGet(_phase_count);
    return max(BOSS_PHASE_MIN_HP,
        ceil(_focus_damage_per_volley * _focus_volleys_per_second
            * _target_seconds * _damage_scale));
}

/// @func GameBossPhaseTargetSecondsGet(stage)
/// Returns the intended full-power focused-fire lifetime of one attack pattern.
function GameBossPhaseTargetSecondsGet(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT)) {
        case 1: return 4;
        case 2: return 5;
        case 3: return 6;
        case 4: return 7;
    }

    return 8;
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

    if (variable_instance_exists(_boss, "phase_transition_timer")
        && _boss.phase_transition_timer > 0) {
        return 0;
    }

    var _phase_count = variable_instance_exists(_boss, "phase_count") ? _boss.phase_count : BOSS_PHASE_COUNT;
    var _applied_damage = max(0, _damage) * GameBossDamageScaleGet(_phase_count);

    // Mira and Aisha's shared finale has one life pool presented by two bodies.
    // Hitting either sister updates both copies so their coordinated attack can
    // only end once, after both individual plans have already been cleared.
    if (variable_instance_exists(_boss, "dual_finale_active")
        && _boss.dual_finale_active) {
        var _dual_members = GameBossDualMembersCreate();
        for (var _dual = 0; _dual < array_length(_dual_members); _dual++) {
            var _member = _dual_members[_dual];
            if (variable_instance_exists(_member, "dual_finale_active")
                && _member.dual_finale_active) {
                _member.hp -= _applied_damage;
            }
        }
        return _applied_damage;
    }

    _boss.hp -= _applied_damage;
    return _applied_damage;
}

/// @func GameMemoryCoreNameGet(stage)
/// Returns the display name for a non-final Memory Core.
function GameMemoryCoreNameGet(_stage) {
    switch (clamp(_stage, 1, LEGACY_STAGE_COUNT - 1)) {
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
    switch (clamp(_stage, 1, LEGACY_STAGE_COUNT - 1)) {
        case 1:
            return [
                GameMemoryCorePhaseCreate("tideglass_spiral", "blade_spiral", 24, 10, 0, 19, 0, 12, 1.55, 0),
                GameMemoryCorePhaseCreate("tideglass_fan", "diamond_fan", 36, 5, 0, 0, 3.4, 0, 0, 44),
            ];

        case 2:
            return [
                GameMemoryCorePhaseCreate("mira_three_card_monte", "mira_three_card_monte", 30, 12, 12, -9, 3.0, 0, 0, 82, 0, "casino"),
                GameMemoryCorePhaseCreate("mira_loaded_dice", "mira_loaded_dice", 36, 14, 0, 17, 3.4, 0, 0, 92, 0, "casino"),
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
                GameMemoryCorePhaseCreate("aisha_arcane_circle", "aisha_arcane_circle", 28, 14, 0, 19, 3.0, 13, 1.55, 0, 0, "sorcery"),
                GameMemoryCorePhaseCreate("aisha_mirrored_hex", "aisha_mirrored_hex", 24, 12, 30, -17, 3.8, 12, 1.45, 96, 0, "sorcery"),
                GameMemoryCorePhaseCreate("aisha_grand_grimoire", "aisha_grand_grimoire", 32, 18, 6, 13, 3.1, 16, 1.7, 104, 90, "sorcery"),
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
    switch (clamp(_stage, 1, LEGACY_STAGE_COUNT - 1)) {
        case 1:
            return GameMemoryCorePhaseCreate("tideglass_maelstrom_finale", "tideglass_maelstrom", 18, 18, 0, 23, 3.4, 15, 1.65, 96, 0, "tideglass");

        case 2:
            return GameMemoryCorePhaseCreate("mira_house_always_wins_finale", "mira_house_always_wins", 18, 18, 45, -19, 3.9, 0, 0, 112, 0, "casino");

        case 3:
            return GameMemoryCorePhaseCreate("saltwind_eye_finale", "saltwind_eye", 16, 18, 270, 31, 4.1, 17, 1.75, 112, 0, "saltwind");

        case 4:
            return GameMemoryCorePhaseCreate("kelp_abyssal_bloom_finale", "kelp_abyssal_bloom", 20, 16, 0, 27, 3.5, 13, 1.9, 120, 0, "kelp");

        case 5:
            return GameMemoryCorePhaseCreate("shalmii_runebreaker_finale", "shalmii_runebreaker", 16, 20, 0, -29, 4.0, 18, 1.95, 132, 0, "rune");

        case 6:
            return GameMemoryCorePhaseCreate("aisha_grand_sorcery_finale", "aisha_grand_sorcery", 15, 22, 6, 37, 4.1, 18, 1.85, 124, 75, "sorcery");

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
    _stage = clamp(_stage, 1, LEGACY_STAGE_COUNT - 1);
    var _expanded_count = (_stage <= 2) ? 4 : ((_stage <= 6) ? 6 : 8);
    var _seed_plan = GameMemoryCoreBasePhasePlanCreate(_stage);
    var _phase_plan = GameBossPhasePlanExpand(_seed_plan, _expanded_count);
    array_push(_phase_plan, GameMemoryCoreFinalPhaseCreate(_stage));
    return _phase_plan;
}

/// @func GameCharacterBossPhasePlanCreate(encounter_stage, pattern_stage)
/// Fits a character's original motif plan to the new five-stage difficulty arc.
function GameCharacterBossPhasePlanCreate(_encounter_stage, _pattern_stage) {
    var _expanded_count = GameBossExpandedPhaseCountForStage(_encounter_stage);
    var _seed_plan = GameMemoryCoreBasePhasePlanCreate(_pattern_stage);
    var _phase_plan = GameBossPhasePlanExpand(_seed_plan, _expanded_count);
    array_push(_phase_plan, GameMemoryCoreFinalPhaseCreate(_pattern_stage));
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
        case SHALMII_BOSS_STAGE:
            return {
                story_id: "shalmii",
                display_name: SHALMII_BOSS_NAME,
                ship_name: SHALMII_SHIP_NAME,
                sprite_id: spr_shalmii_ship,
                pattern_stage: 5,
                is_dual: false,
            };

        case ASTER_BOSS_STAGE:
            return {
                story_id: "aster",
                display_name: ASTER_BOSS_NAME,
                ship_name: ASTER_SHIP_NAME,
                sprite_id: spr_aster_ship,
                pattern_stage: 7,
                is_dual: false,
            };

        case DUAL_BOSS_STAGE:
            return {
                story_id: "mira_aisha",
                display_name: "Mira & Aisha",
                ship_name: "Wildheart / Wishbound",
                sprite_id: spr_mira_ship,
                pattern_stage: 2,
                is_dual: true,
            };

        case CAELIA_BOSS_STAGE:
            return {
                story_id: "caelia",
                display_name: CAELIA_BOSS_NAME,
                ship_name: CAELIA_SHIP_NAME,
                sprite_id: spr_caelia_ship,
                pattern_stage: 9,
                is_dual: false,
            };
    }

    return undefined;
}

/// @func GameStageIsDualBoss(stage)
/// Returns whether this stage fields Mira and Aisha together.
function GameStageIsDualBoss(_stage = undefined) {
    if (_stage == undefined) {
        _stage = GameCurrentStageGet();
    }

    return clamp(_stage, 1, STAGE_COUNT) == DUAL_BOSS_STAGE;
}

/// @func GameDualBossIdentityCreate(role)
/// Builds one half of the Mira/Aisha duet from each girl's original motifs.
function GameDualBossIdentityCreate(_role) {
    var _is_aisha = (_role == "aisha");
    var _pattern_stage = _is_aisha ? 6 : 2;
    var _phase_plan = GameCharacterBossPhasePlanCreate(DUAL_BOSS_STAGE, _pattern_stage);

    return {
        is_final: false,
        is_character: true,
        is_dual: true,
        dual_role: _is_aisha ? "aisha" : "mira",
        opponent_ship_id: "",
        display_name: _is_aisha ? AISHA_BOSS_NAME : MIRA_BOSS_NAME,
        ship_name: _is_aisha ? AISHA_SHIP_NAME : MIRA_SHIP_NAME,
        sprite_id: _is_aisha ? spr_aisha_ship : spr_mira_ship,
        draw_y_scale: 1,
        phase_plan: _phase_plan,
        phase_signature: GameMemoryCorePhasePlanSignatureCreate(_phase_plan),
    };
}

/// @func GameBossDualConfigure(boss, role)
/// Places and tunes one independently damageable half of the dual encounter.
function GameBossDualConfigure(_boss, _role) {
    if (!instance_exists(_boss)) {
        return noone;
    }

    var _identity = GameDualBossIdentityCreate(_role);
    var _is_aisha = (_identity.dual_role == "aisha");
    _boss.boss_identity = _identity;
    _boss.boss_display_name = _identity.display_name;
    _boss.boss_ship_name = _identity.ship_name;
    _boss.boss_draw_y_scale = _identity.draw_y_scale;
    _boss.sprite_index = _identity.sprite_id;
    _boss.phase_count = max(1, array_length(_identity.phase_plan));
    _boss.phase_max_hp = max(BOSS_PHASE_MIN_HP,
        ceil(GameBossPhaseHpGet(DUAL_BOSS_STAGE, _boss.phase_count) * 0.64));
    _boss.hp = _boss.phase_max_hp;
    _boss.anchor_offset_x = _is_aisha ? 52 : -52;
    _boss.anchor_offset_y = _is_aisha ? -82 : -102;
    _boss.float_phase = _is_aisha ? 180 : 0;
    _boss.dual_boss = true;
    _boss.dual_role = _identity.dual_role;
    _boss.dual_individual_defeated = false;
    _boss.dual_finale_active = false;
    _boss.points = 22000;
    return _boss;
}

/// @func GameBossDualMembersCreate()
/// Returns the live Mira/Aisha boss objects in encounter order.
function GameBossDualMembersCreate() {
    var _members = [];
    var _count = instance_number(obj_boss_parent);
    for (var _index = 0; _index < _count; _index++) {
        var _member = instance_find(obj_boss_parent, _index);
        if (_member != noone
            && variable_instance_exists(_member, "dual_boss")
            && _member.dual_boss) {
            array_push(_members, _member);
        }
    }
    return _members;
}

/// @func GameBossDualFinalPhaseCreate()
/// Defines the one attack the sisters perform only after both personal plans fall.
function GameBossDualFinalPhaseCreate() {
    return GameMemoryCorePhaseCreate(
        "sisters_grand_illusion_finale",
        "sisters_grand_illusion",
        18, 22, 0, 23, 4.0, 18, 1.75, 126, 72, "sisters"
    );
}

/// @func GameBossDualFinaleTryBegin()
/// Reforms both defeated sisters around a synchronized final shared life pool.
function GameBossDualFinaleTryBegin() {
    var _members = GameBossDualMembersCreate();
    if (array_length(_members) < 2) {
        return false;
    }

    var _all_defeated = true;
    for (var _check = 0; _check < array_length(_members); _check++) {
        var _candidate = _members[_check];
        if (!variable_instance_exists(_candidate, "dual_individual_defeated")
            || !_candidate.dual_individual_defeated) {
            _all_defeated = false;
        }
        if (variable_instance_exists(_candidate, "dual_finale_active")
            && _candidate.dual_finale_active) {
            return true;
        }
    }

    if (!_all_defeated) {
        return false;
    }

    var _final_phase = GameBossDualFinalPhaseCreate();
    var _shared_hp = ceil(GameBossPhaseHpGet(DUAL_BOSS_STAGE, 1) * 1.35);
    for (var _index = 0; _index < array_length(_members); _index++) {
        var _member = _members[_index];
        _member.dual_finale_active = true;
        _member.dual_individual_defeated = true;
        _member.boss_identity.phase_plan = [_final_phase];
        _member.boss_identity.phase_signature = GameMemoryCorePhaseSignatureCreate(_final_phase);
        _member.boss_display_name = "Mira & Aisha";
        _member.boss_ship_name = "Wildheart + Wishbound";
        _member.phase_count = 1;
        _member.phase_index = 0;
        _member.phase_max_hp = _shared_hp;
        _member.hp = 0;
        _member.phase_timer = 0;
        _member.phase_transition_timer = BOSS_PHASE_TRANSITION_FRAMES;
        _member.phase_transition_total = BOSS_PHASE_TRANSITION_FRAMES;
        _member.destruction_active = false;
        _member.destruction_timer = 0;
        _member.last_medal_drop_phase = -1;
        _member.hit_radius = 28;
        _member.image_alpha = 1;
        _member.pattern_clockwise_first = (_member.dual_role == "mira");
    }

    GameBulletsCancelAll(false);
    GameBossPhaseSoundPlay();
    return true;
}

/// @func GameBossDualIndividualDefeatBegin(boss)
/// Holds one sister safely off-line until the other personal plan is defeated.
function GameBossDualIndividualDefeatBegin(_boss) {
    if (!instance_exists(_boss)
        || !variable_instance_exists(_boss, "dual_boss")
        || !_boss.dual_boss
        || _boss.dual_finale_active) {
        return false;
    }

    GameBossPhaseMedalsDrop(_boss);
    _boss.dual_individual_defeated = true;
    _boss.hp = 0;
    _boss.hit_radius = 0;
    _boss.phase_transition_timer = 0;
    _boss.phase_timer = 0;
    _boss.image_alpha = 0.34;
    GameBulletsCancelAll(false);
    GameBossPhaseSoundPlay();
    return GameBossDualFinaleTryBegin();
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
        var _character_boss = GameCharacterBossInfoCreate(_stage);
        if (!is_struct(_character_boss)) {
            return undefined;
        }

        var _phase_plan = GameCharacterBossPhasePlanCreate(_stage, _character_boss.pattern_stage);

        return {
            is_final: false,
            is_character: true,
            is_dual: _character_boss.is_dual,
            opponent_ship_id: "",
            display_name: _character_boss.display_name,
            ship_name: _character_boss.ship_name,
            sprite_id: _character_boss.sprite_id,
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
    // Keep both routes' focused DPS close enough that the duration-based boss
    // phase targets hold for either character.
    var _damage = PLAYER_SHOT_DAMAGE + 1 + (_power div 2);
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
        score_value: BULLET_CANCEL_SCORE_BONUS * (_is_berserk ? 10 : 1),
        meter_value: _is_berserk ? 0 : BULLET_CANCEL_BERSERK_GAIN,
    };
}

/// @func GameEnemyMedalDropCountGet(role, points, seed)
/// Gives small familiars one or two medals and substantial enemies five to ten.
function GameEnemyMedalDropCountGet(_role, _points, _seed = 0) {
    var _offset = abs(round(_seed)) mod 6;

    if (_role == "anchor") {
        return 8 + (_offset mod 3);
    }

    if (_role == "dancer" || _points >= 1500) {
        return 5 + _offset;
    }

    return 1 + (_offset mod 2);
}

/// @func GameBossPhaseMedalDropCountGet(stage, phase_index)
/// Gives every defeated boss phase a deterministic five-to-ten-medal shower.
function GameBossPhaseMedalDropCountGet(_stage, _phase_index) {
    return 5 + (abs(round((_stage * 7) + (_phase_index * 3))) mod 6);
}

/// @func GameMedalsSpawnSpread(x, y, count, score_value, meter_value, seed)
/// Spawns a readable radial medal shower with a short non-homing launch.
function GameMedalsSpawnSpread(_x, _y, _count, _score_value = BULLET_CANCEL_SCORE_BONUS,
    _meter_value = ENEMY_MEDAL_BERSERK_GAIN, _seed = 0) {
    _count = max(0, round(_count));

    for (var _index = 0; _index < _count; _index++) {
        var _direction = 90 + ((_index * 360) / max(1, _count)) + ((_seed * 17) mod 23);
        var _radius = 2 + ((_index + abs(round(_seed))) mod 4);
        var _medal = instance_create_layer(
            _x + lengthdir_x(_radius, _direction),
            _y + lengthdir_y(_radius, _direction),
            "Instances", obj_medal);
        _medal.score_value = _score_value;
        _medal.meter_value = _meter_value;
        _medal.launch_direction = _direction;
        _medal.launch_speed = 2.4 + ((_index + abs(round(_seed))) mod 5) * 0.35;
        _medal.launch_timer = 12 + ((_index * 3 + abs(round(_seed))) mod 9);
    }

    return _count;
}

/// @func GameEnemyMedalsDrop(enemy)
/// Resolves one ordinary enemy's size class and emits its medal reward.
function GameEnemyMedalsDrop(_enemy) {
    if (!instance_exists(_enemy)) {
        return 0;
    }

    var _role = variable_instance_exists(_enemy, "variant_role")
        ? _enemy.variant_role : "chaser";
    var _points = variable_instance_exists(_enemy, "points") ? _enemy.points : 0;
    var _seed = variable_instance_exists(_enemy, "slot_index")
        ? _enemy.slot_index + (GameCurrentStageGet() * 5) : GameCurrentStageGet();
    var _count = GameEnemyMedalDropCountGet(_role, _points, _seed);
    return GameMedalsSpawnSpread(_enemy.x, _enemy.y, _count,
        BULLET_CANCEL_SCORE_BONUS, ENEMY_MEDAL_BERSERK_GAIN, _seed);
}

/// @func GameBossPhaseMedalsDrop(boss)
/// Emits exactly one medal shower for one defeated phase, including the shared finale.
function GameBossPhaseMedalsDrop(_boss) {
    if (!instance_exists(_boss)) {
        return 0;
    }

    var _phase_index = variable_instance_exists(_boss, "phase_index") ? _boss.phase_index : 0;
    if (variable_instance_exists(_boss, "last_medal_drop_phase")
        && _boss.last_medal_drop_phase == _phase_index) {
        return 0;
    }

    if (variable_instance_exists(_boss, "dual_finale_active") && _boss.dual_finale_active) {
        var _members = GameBossDualMembersCreate();
        for (var _check = 0; _check < array_length(_members); _check++) {
            var _candidate = _members[_check];
            if (variable_instance_exists(_candidate, "last_medal_drop_phase")
                && _candidate.last_medal_drop_phase == _phase_index) {
                return 0;
            }
        }

        for (var _mark = 0; _mark < array_length(_members); _mark++) {
            _members[_mark].last_medal_drop_phase = _phase_index;
        }
    } else {
        _boss.last_medal_drop_phase = _phase_index;
    }

    var _stage = variable_instance_exists(_boss, "stage_rank")
        ? _boss.stage_rank : GameCurrentStageGet();
    var _count = GameBossPhaseMedalDropCountGet(_stage, _phase_index);
    return GameMedalsSpawnSpread(_boss.x, _boss.y, _count,
        BULLET_CANCEL_SCORE_BONUS, ENEMY_MEDAL_BERSERK_GAIN,
        (_stage * 11) + _phase_index);
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

/// @func GamePlayerBerserkActivate()
/// Starts Berserk, cancels the screen, and grants only a three-frame safety flash.
function GamePlayerBerserkActivate() {
    GameRuntimeGameplayEnsure();

    if (global.game_runtime.is_berserk) {
        return false;
    }

    global.game_runtime.meter = METER_MAX;
    global.game_runtime.is_berserk = true;
    GameRankEventApply(RANK_HYPER_GAIN);
    GameBulletsCancelAll(true);

    var _player = instance_find(obj_player, 0);
    if (_player != noone && variable_instance_exists(_player, "player_state")) {
        _player.player_state.invuln_timer = max(
            _player.player_state.invuln_timer,
            BERSERK_ACTIVATION_INVULN_FRAMES);
    }

    return true;
}

/// @func GamePlayerMeterRewardApply(meter_amount)
/// Adds to the unified Berserk meter and returns whether Berserk just started.
function GamePlayerMeterRewardApply(_meter_amount) {
    GameRuntimeGameplayEnsure();

    if (global.game_runtime.is_berserk) {
        return false;
    }

    global.game_runtime.meter = clamp(global.game_runtime.meter + _meter_amount, 0, METER_MAX);

    if (global.game_runtime.meter >= METER_MAX) {
        return GamePlayerBerserkActivate();
    }

    return false;
}

/// @func GamePlayerBerserkAttackMeterStep(state, attacking)
/// Adds a deliberately tiny Berserk trickle during sustained ordinary attacks.
function GamePlayerBerserkAttackMeterStep(_state, _attacking) {
    if (!_attacking || global.game_runtime.is_berserk) {
        return 0;
    }

    _state.attack_meter_timer += 1;
    if (_state.attack_meter_timer < BERSERK_PASSIVE_ATTACK_INTERVAL) {
        return 0;
    }

    _state.attack_meter_timer -= BERSERK_PASSIVE_ATTACK_INTERVAL;
    GamePlayerMeterRewardApply(BERSERK_PASSIVE_ATTACK_GAIN);
    return BERSERK_PASSIVE_ATTACK_GAIN;
}

/// @func GamePlayerPointBlankAttackRewardApply(target_x, target_y, amount)
/// Rewards a damaging hit inside Selkie's normal chakram reach.
function GamePlayerPointBlankAttackRewardApply(_target_x, _target_y, _amount) {
    if (global.game_runtime.is_berserk || _amount <= 0) {
        return false;
    }

    var _player = instance_find(obj_player, 0);
    if (_player == noone || _player.player_state.hit) {
        return false;
    }

    if (point_distance(_player.x, _player.y, _target_x, _target_y)
        > BERSERK_POINT_BLANK_RADIUS) {
        return false;
    }

    GamePlayerMeterRewardApply(_amount);
    return true;
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
    _state.attack_meter_timer = 0;

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
    _state.invuln_timer = max(_state.invuln_timer, BOMB_INVULN_FRAMES);
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

    var _damage = SWORD_SWEEP_DAMAGE
        * (global.game_runtime.is_berserk ? BERSERK_SWORD_DAMAGE_MULTIPLIER : 1);
    var _damage_applied = false;

    if (variable_instance_exists(_target_id, "phase_count")
        && variable_instance_exists(_target_id, "phase_max_hp")) {
        _damage_applied = GameBossDamageApply(_target_id, _damage) > 0;
    } else {
        variable_instance_set(_target_id, "hp", variable_instance_get(_target_id, "hp") - _damage);
        _damage_applied = true;
    }

    if (_damage_applied) {
        GamePlayerPointBlankAttackRewardApply(
            variable_instance_get(_target_id, "x"),
            variable_instance_get(_target_id, "y"),
            BERSERK_POINT_BLANK_SWORD_GAIN);
    }

    return _damage_applied;
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

    _result.focused_attack = _input.focus_down;

    if (global.game_runtime.is_berserk) {
        _state.fire_hold_frames = FIRE_HOLD_FRAMES + 1;
    } else if (_input.fire_down && !_input.autofire_down) {
        _state.fire_hold_frames += 1;
    } else {
        _state.fire_hold_frames = 0;
    }

    _use_sword = global.game_runtime.is_berserk
        || (_input.fire_down && !_input.autofire_down && _state.fire_hold_frames >= FIRE_HOLD_FRAMES);

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
        panel_padding: 12,
        line_height: 16,
        meter_left: _playfield_right + 12,
        meter_top: 86,
        meter_width: GAME_VIEW_WIDTH - _playfield_right - 24,
        meter_height: 12,
        boss_bar_left: _playfield_right + 12,
        boss_bar_top: 152,
        boss_bar_width: GAME_VIEW_WIDTH - _playfield_right - 24,
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
            + GamePracticeSegmentNameForStageGet(_practice.segment, _practice.stage);
    }

    var _rank_label = "Rank: " + string(GameRankGet()) + " "
        + (GameRankDynamicEnabled() ? "Dynamic" : "Fixed");
    var _meter_label = "Berserk: " + string(global.game_runtime.meter) + "/" + string(METER_MAX);
    if (global.game_runtime.is_berserk) {
        _meter_label = "Berserk: ACTIVE " + string(global.game_runtime.meter) + "/" + string(METER_MAX);
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
        "FPS: " + string(fps),
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

/// @func GamePowerupSpriteGet(type)
/// Returns the route-neutral pixel-art icon for a collectible type.
function GamePowerupSpriteGet(_type) {
    switch (_type) {
        case POWERUP_POWER:
            return spr_powerup_power;

        case POWERUP_BOMB:
            return spr_powerup_bomb;

        case POWERUP_LIFE:
            return spr_powerup_life;

        case POWERUP_METER:
            return spr_powerup_meter;
    }

    return spr_powerup_score;
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
/// Returns the stage-scaled base used by the ordinary-defeat resource cadence.
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

/// @func GameResourceDropDefeatPeriodGet(stage)
/// Returns the ordinary-defeat cadence for one bounded stock/power pickup.
function GameResourceDropDefeatPeriodGet(_stage) {
    return GameResourceDropChargeThresholdGet(_stage) * RESOURCE_DROP_DEFEAT_MULTIPLIER;
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
/// Drops sparse score bonuses and bounded resources without a second PB meter.
function GameEnemyPowerupDropTry(_x, _y, _points) {
    GameRuntimeGameplayEnsure();

    global.game_runtime.powerup_drop_counter += 1;

    var _counter = global.game_runtime.powerup_drop_counter;
    var _stage = GameCurrentStageGet();
    var _resource_threshold = GameResourceDropDefeatPeriodGet(_stage);
    var _resource_limit = GameResourceDropLimitGet(_stage);
    global.game_runtime.resource_drop_threshold = _resource_threshold;
    var _drop_type = POWERUP_SCORE;
    var _pickup_class = "score";
    var _should_drop = false;
    global.game_runtime.resource_drop_charge = _counter mod _resource_threshold;

    if ((_counter mod _resource_threshold) == 0
        && global.game_runtime.resource_drops_this_stage < _resource_limit) {
        global.game_runtime.resource_drop_charge = 0;
        global.game_runtime.resource_drops_this_stage += 1;
        global.game_runtime.resource_drop_counter += 1;
        _drop_type = GamePowerupResourceDropTypeChoose(global.game_runtime.resource_drop_counter);
        _pickup_class = "resource";
        _should_drop = true;
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

/// @func GameSunsetInfinityOffsetCreate(phase)
/// Returns the current infinity-path offset for the Sunset boss.
function GameSunsetInfinityOffsetCreate(_phase) {
    return {
        x: dsin(_phase) * SUNSET_FLOAT_X_RADIUS,
        y: dsin(_phase * 2) * SUNSET_FLOAT_Y_RADIUS,
    };
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

        freeze_timer = max(BOSS_PHASE3_FREEZE_FRAMES, _freeze_frames);
        redirect_pending = true;
        redirect_speed = min(_redirect_speed,
            BLADE_REDIRECT_MAX_SCREEN_SPEED / max(0.01, rank_speed_scale));
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

/// @func GameBossPhaseHeartStatesCreate(phase_index, phase_count)
/// Returns 0 for spent hearts, 2 for the active heart, and 1 for future hearts.
function GameBossPhaseHeartStatesCreate(_phase_index, _phase_count) {
    _phase_count = max(1, floor(_phase_count));
    _phase_index = floor(clamp(_phase_index, 0, _phase_count - 1));
    var _states = array_create(_phase_count, 1);

    for (var i = 0; i < _phase_count; i++) {
        _states[i] = (i < _phase_index) ? 0 : ((i == _phase_index) ? 2 : 1);
    }

    return _states;
}

/// @func GameBossCircularHealthDraw(boss)
/// Draws a crisp segmented health ring around the boss itself.
function GameBossCircularHealthDraw(_boss) {
    if (!instance_exists(_boss)
        || !variable_instance_exists(_boss, "hp")
        || !variable_instance_exists(_boss, "phase_max_hp")) {
        return false;
    }

    var _ratio = clamp(_boss.hp / max(1, _boss.phase_max_hp), 0, 1);
    var _transitioning = variable_instance_exists(_boss, "phase_transition_timer")
        && _boss.phase_transition_timer > 0;
    var _radius = max(34, _boss.hit_radius + 10);
    var _segments = 48;
    var _filled_segments = floor((_ratio * _segments) + 0.001);
    var _center_x = round(_boss.x);
    var _center_y = round(_boss.y);

    for (var segment = 0; segment < _segments; segment++) {
        var _angle_a = -90 + ((segment / _segments) * 360);
        var _angle_b = -90 + (((segment + 0.72) / _segments) * 360);
        var _x1 = round(_center_x + lengthdir_x(_radius, _angle_a));
        var _y1 = round(_center_y + lengthdir_y(_radius, _angle_a));
        var _x2 = round(_center_x + lengthdir_x(_radius, _angle_b));
        var _y2 = round(_center_y + lengthdir_y(_radius, _angle_b));
        var _filled = segment < _filled_segments;

        draw_set_alpha(_filled ? 0.96 : 0.38);
        if (_filled) {
            draw_set_color(_transitioning
                ? make_color_rgb(255, 220, 132)
                : merge_color(make_color_rgb(255, 102, 174),
                    make_color_rgb(112, 226, 236), segment / _segments));
        } else {
            draw_set_color(make_color_rgb(38, 20, 56));
        }
        draw_line_width(_x1, _y1, _x2, _y2, 2);
    }

    if (_transitioning) {
        draw_set_alpha(0.42 + (0.18 * abs(dsin(_boss.phase_transition_timer * 14))));
        draw_set_color(make_color_rgb(255, 242, 198));
        draw_circle(_center_x, _center_y, _radius + 3, true);
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
    return true;
}

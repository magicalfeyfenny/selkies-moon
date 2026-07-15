// Boot, persistence, migration, display configuration, and runtime defaults.
// Increment these schema versions only when persisted or runtime data changes shape.
#macro CONFIG_VERSION 5
#macro SAVE_VERSION 2
#macro RUNTIME_VERSION 7

#macro DEFAULT_LIVES 3
#macro DEFAULT_BOMBS 3

/// @func GameStructFieldEnsure(target, field_name, default_value)
/// Adds a missing struct field and returns the stored value.
function GameStructFieldEnsure(_target, _field_name, _default_value) {
    if (!struct_exists(_target, _field_name)) {
        _target[$ _field_name] = _default_value;
    }

    return _target[$ _field_name];
}

/// @func GameConfigCreateDefault()
/// Creates the default configuration struct for a fresh boot.
function GameConfigCreateDefault() {
    return {
        version: CONFIG_VERSION,
        view_width: 640,
        view_height: 360,
        target_fps: 60,
        display_scale: 2,
        fullscreen: false,
        input_device: "keyboard",
        input_bindings: GameInputBindingsCreateDefault(),
        master_volume: 100,
        music_volume: 100,
        sfx_volume: 100,
    };
}

/// @func GameSaveDataCreateDefault()
/// Creates the default persistent save data structure.
function GameSaveDataCreateDefault() {
    return {
        version: SAVE_VERSION,
        high_score: {
            ship_A: [0,0,0,0,0,0,0,0,0,0],
            ship_selkie: [0,0,0,0,0,0,0,0,0,0]
        },
        runs_started: {
            ship_A: [0,0,0,0,0,0,0,0,0,0],
            ship_selkie: [0,0,0,0,0,0,0,0,0,0]
        },
        runs_finished: {
            ship_A: [0,0,0,0,0,0,0,0,0,0],
            ship_selkie: [0,0,0,0,0,0,0,0,0,0]
        },
        continues_used: {
            ship_A: [0,0,0,0,0,0,0,0,0,0],
            ship_selkie: [0,0,0,0,0,0,0,0,0,0]
        },
    };
}

/// @func GameRuntimeDataCreateDefault()
/// Creates the runtime-only state used for the current run.
function GameRuntimeDataCreateDefault() {
    return {
        version: RUNTIME_VERSION,
        is_initialized: true,
        signals: {
            dialogue: false,
            continue_request: false,
            paused: false,
        },
        continue_screen: GameContinueStateCreate(),
        pause_menu: GamePauseStateCreate(),
        story: {
            requested_file: "",
            current_file: "",
        },
        selected_ship_id: "",
        selected_ship_index: -1,
        run_mode: "normal",
        practice_config: GamePracticeConfigCreateDefault(),
        score: 0,
        continues_used: 0,
        meter: 0,
        is_berserk: false,
        bomb_active: false,
        bomb_timer: 0,
        current_stage: 1,
        stage_count: STAGE_COUNT,
        stage_notice_timer: 0,
        stage_frame: 0,
        stage_complete: false,
        power: 0,
        powerup_drop_counter: 0,
        resource_drop_charge: 0,
        resource_drop_threshold: RESOURCE_DROP_CHARGE_BASE,
        resource_drops_this_stage: 0,
        resource_drop_counter: 0,
        rank: RANK_DEFAULT,
        rank_locked: false,
        rank_frame: 0,
        rank_defeats: 0,
        run_started_recorded: false,
        lives: DEFAULT_LIVES,
        bombs: DEFAULT_BOMBS,
    };
}

/// @func GamePersistenceIsAutomationRun()
/// Returns whether persistence should use the isolated QA/test namespace.
function GamePersistenceIsAutomationRun() {
    return GameShouldRunTests() || GameShouldRunVisualTour();
}

/// @func GamePersistenceNamespaceGet()
/// Returns the filename prefix for the active persistence namespace.
function GamePersistenceNamespaceGet() {
    if (GamePersistenceIsAutomationRun()) {
        return "automation-";
    }

    return "";
}

/// @func GameSavePathGet()
/// Returns the relative path used for the save file.
function GameSavePathGet() {
    return GamePersistenceNamespaceGet() + "game.sav";
}

/// @func GameConfigPathGet()
/// Returns the relative path used for the config file.
function GameConfigPathGet() {
    return GamePersistenceNamespaceGet() + "config.sav";
}

/// @func GamePersistenceBackupPathGet(path)
/// Returns the stable backup path used before recovery or migration rewrites.
function GamePersistenceBackupPathGet(_path) {
    return _path + ".backup";
}

/// @func GamePersistenceTextRead(path)
/// Reads an entire text file and reports whether it could be opened safely.
function GamePersistenceTextRead(_path) {
    var _result = {
        ok: false,
        contents: ""
    };

    try {
        var _file = file_text_open_read(_path);
        if (_file < 0) {
            return _result;
        }

        var _contents = "";
        var _is_first_line = true;

        while (!file_text_eof(_file)) {
            if (!_is_first_line) {
                _contents += "\n";
            }

            _contents += file_text_read_string(_file);
            file_text_readln(_file);
            _is_first_line = false;
        }

        file_text_close(_file);
        _result.ok = true;
        _result.contents = _contents;
    } catch (_exception) {
        show_debug_message("Warning: Could not read persistence file " + _path + ".");
    }

    return _result;
}

/// @func GamePersistenceTextWrite(path, contents)
/// Writes a complete persistence payload and reports whether it succeeded.
function GamePersistenceTextWrite(_path, _contents) {
    try {
        var _file = file_text_open_write(_path);
        if (_file < 0) {
            return false;
        }

        file_text_write_string(_file, _contents);
        file_text_close(_file);
        return true;
    } catch (_exception) {
        show_debug_message("Warning: Could not write persistence file " + _path + ".");
        return false;
    }
}

/// @func GamePersistenceBackupWrite(path, contents)
/// Preserves the original payload before a migration or recovery rewrite.
function GamePersistenceBackupWrite(_path, _contents) {
    var _backup_path = GamePersistenceBackupPathGet(_path);
    var _did_write = GamePersistenceTextWrite(_backup_path, _contents);

    if (_did_write) {
        show_debug_message("Persistence backup written to " + _backup_path + ".");
    }

    return _did_write;
}

/// @func GamePersistenceJsonParse(contents)
/// Parses a persistence payload without allowing malformed JSON to stop boot.
function GamePersistenceJsonParse(_contents) {
    var _result = {
        ok: false,
        value: undefined
    };

    try {
        _result.value = json_parse(_contents);
        _result.ok = is_struct(_result.value);
    } catch (_exception) {
        _result.ok = false;
    }

    return _result;
}

/// @func GamePersistenceVersionGet(data)
/// Returns a numeric schema version, treating unversioned legacy structs as zero.
function GamePersistenceVersionGet(_data) {
    if (is_struct(_data) && struct_exists(_data, "version") && is_real(_data.version)) {
        return floor(_data.version);
    }

    return 0;
}

/// @func GameSaveValueArrayNormalize(value)
/// Converts legacy scalars and partial arrays into a ten-entry stat array.
function GameSaveValueArrayNormalize(_value) {
    var _result = array_create(10, 0);

    if (is_array(_value)) {
        var _copy_count = min(array_length(_value), array_length(_result));

        for (var i = 0; i < _copy_count; i++) {
            if (is_real(_value[i])) {
                _result[i] = _value[i];
            }
        }
    } else if (is_real(_value)) {
        _result[0] = _value;
    }

    return _result;
}

/// @func GameSaveValueArrayIsCurrent(value)
/// Returns whether a stored statistic already matches the current ten-value schema.
function GameSaveValueArrayIsCurrent(_value) {
    if (!is_array(_value) || array_length(_value) != 10) {
        return false;
    }

    for (var i = 0; i < array_length(_value); i++) {
        if (!is_real(_value[i])) {
            return false;
        }
    }

    return true;
}

/// @func GameSaveTableIsCurrent(source, field_name)
/// Validates one current per-ship save table without relying on JSON key order.
function GameSaveTableIsCurrent(_source, _field_name) {
    if (!struct_exists(_source, _field_name) || !is_struct(_source[$ _field_name])) {
        return false;
    }

    var _table = _source[$ _field_name];
    if (!struct_exists(_table, "ship_A") || !struct_exists(_table, "ship_selkie")) {
        return false;
    }

    var _ship_names = variable_struct_get_names(_table);
    for (var i = 0; i < array_length(_ship_names); i++) {
        if (!GameSaveValueArrayIsCurrent(_table[$ _ship_names[i]])) {
            return false;
        }
    }

    return true;
}

/// @func GameSaveDataIsCurrent(source)
/// Detects actual schema drift while ignoring harmless struct/key serialization order.
function GameSaveDataIsCurrent(_source) {
    if (!is_struct(_source) || GamePersistenceVersionGet(_source) != SAVE_VERSION) {
        return false;
    }

    return GameSaveTableIsCurrent(_source, "high_score")
        && GameSaveTableIsCurrent(_source, "runs_started")
        && GameSaveTableIsCurrent(_source, "runs_finished")
        && GameSaveTableIsCurrent(_source, "continues_used");
}

/// @func GameSaveTableMigrate(source, field_name, destination)
/// Copies a legacy scalar or any per-ship arrays into a current save table.
function GameSaveTableMigrate(_source, _field_name, _destination) {
    if (!struct_exists(_source, _field_name)) {
        return _destination;
    }

    var _source_value = _source[$ _field_name];

    if (is_struct(_source_value)) {
        var _ship_names = variable_struct_get_names(_source_value);

        for (var i = 0; i < array_length(_ship_names); i++) {
            var _ship_id = _ship_names[i];
            _destination[$ _ship_id] = GameSaveValueArrayNormalize(_source_value[$ _ship_id]);
        }
    } else {
        // Version 1 stored one scalar per statistic, all belonging to Moon/ship_A.
        _destination.ship_A = GameSaveValueArrayNormalize(_source_value);
    }

    return _destination;
}

/// @func GameSaveDataMigrate(source)
/// Builds the current save schema while preserving every recognized stat table.
function GameSaveDataMigrate(_source) {
    var _result = GameSaveDataCreateDefault();

    _result.high_score = GameSaveTableMigrate(_source, "high_score", _result.high_score);
    _result.runs_started = GameSaveTableMigrate(_source, "runs_started", _result.runs_started);
    _result.runs_finished = GameSaveTableMigrate(_source, "runs_finished", _result.runs_finished);
    _result.continues_used = GameSaveTableMigrate(_source, "continues_used", _result.continues_used);
    _result.version = SAVE_VERSION;

    return _result;
}

/// @func GameConfigDataMigrate(source)
/// Carries compatible settings forward while filling newly introduced fields.
function GameConfigDataMigrate(_source) {
    var _result = GameConfigCreateDefault();

    if (struct_exists(_source, "view_width") && is_real(_source.view_width)) {
        _result.view_width = max(1, floor(_source.view_width));
    }

    if (struct_exists(_source, "view_height") && is_real(_source.view_height)) {
        _result.view_height = max(1, floor(_source.view_height));
    }

    if (struct_exists(_source, "target_fps") && is_real(_source.target_fps)) {
        _result.target_fps = max(1, floor(_source.target_fps));
    }

    if (struct_exists(_source, "display_scale") && is_real(_source.display_scale)) {
        _result.display_scale = clamp(round(_source.display_scale), 1, 6);
    }

    if (struct_exists(_source, "fullscreen") && is_bool(_source.fullscreen)) {
        _result.fullscreen = _source.fullscreen;
    }

    if (struct_exists(_source, "input_device") && is_string(_source.input_device)) {
        _result.input_device = _source.input_device;
    }

    if (struct_exists(_source, "input_bindings")) {
        _result.input_bindings = GameInputBindingsNormalize(_source.input_bindings);
    }

    if (struct_exists(_source, "master_volume") && is_real(_source.master_volume)) {
        _result.master_volume = clamp(round(_source.master_volume), 0, 100);
    }

    if (struct_exists(_source, "music_volume") && is_real(_source.music_volume)) {
        _result.music_volume = clamp(round(_source.music_volume), 0, 100);
    }

    if (struct_exists(_source, "sfx_volume") && is_real(_source.sfx_volume)) {
        _result.sfx_volume = clamp(round(_source.sfx_volume), 0, 100);
    }

    _result.version = CONFIG_VERSION;
    return _result;
}

/// @func GameConfigDataIsCurrent(source)
/// Validates current config fields without comparing serialized key order.
function GameConfigDataIsCurrent(_source) {
    if (!is_struct(_source) || GamePersistenceVersionGet(_source) != CONFIG_VERSION) {
        return false;
    }

    return struct_exists(_source, "view_width") && is_real(_source.view_width)
        && _source.view_width >= 1 && floor(_source.view_width) == _source.view_width
        && struct_exists(_source, "view_height") && is_real(_source.view_height)
        && _source.view_height >= 1 && floor(_source.view_height) == _source.view_height
        && struct_exists(_source, "target_fps") && is_real(_source.target_fps)
        && _source.target_fps >= 1 && floor(_source.target_fps) == _source.target_fps
        && struct_exists(_source, "display_scale") && is_real(_source.display_scale)
        && _source.display_scale >= 1 && _source.display_scale <= 6
        && round(_source.display_scale) == _source.display_scale
        && struct_exists(_source, "fullscreen") && is_bool(_source.fullscreen)
        && struct_exists(_source, "input_device") && is_string(_source.input_device)
        && struct_exists(_source, "input_bindings")
        && GameInputBindingsIsValid(_source.input_bindings)
        && struct_exists(_source, "master_volume") && is_real(_source.master_volume)
        && _source.master_volume >= 0 && _source.master_volume <= 100
        && round(_source.master_volume) == _source.master_volume
        && struct_exists(_source, "music_volume") && is_real(_source.music_volume)
        && _source.music_volume >= 0 && _source.music_volume <= 100
        && round(_source.music_volume) == _source.music_volume
        && struct_exists(_source, "sfx_volume") && is_real(_source.sfx_volume)
        && _source.sfx_volume >= 0 && _source.sfx_volume <= 100
        && round(_source.sfx_volume) == _source.sfx_volume;
}

/// @func LoadGameSave()
/// Loads and normalizes current or older save data without discarding progress.
function LoadGameSave() {
    var _path = GameSavePathGet();

    if (!file_exists(_path)) {
        return false;
    }

    var _read = GamePersistenceTextRead(_path);
    if (!_read.ok) {
        return false;
    }

    var _parsed = GamePersistenceJsonParse(_read.contents);
    if (!_parsed.ok) {
        GamePersistenceBackupWrite(_path, _read.contents);
        show_debug_message("Warning: Invalid save data recovered; starting from defaults.");
        return false;
    }

    var _version = GamePersistenceVersionGet(_parsed.value);
    if (_version > SAVE_VERSION) {
        GamePersistenceBackupWrite(_path, _read.contents);
        show_debug_message("Warning: Save data is from a newer unsupported version " + string(_version) + ".");
        return false;
    }

    var _needs_rewrite = !GameSaveDataIsCurrent(_parsed.value);
    var _migrated = GameSaveDataMigrate(_parsed.value);

    if (_needs_rewrite) {
        GamePersistenceBackupWrite(_path, _read.contents);
        GamePersistenceTextWrite(_path, json_stringify(_migrated));

        if (_version < SAVE_VERSION) {
            show_debug_message("Migrated save data from version " + string(_version)
                + " to version " + string(SAVE_VERSION) + ".");
        }
    }

    global.game_save = _migrated;
    return true;
}

/// @func LoadGameConfig()
/// Loads and normalizes current or older configuration data.
function LoadGameConfig() {
    var _path = GameConfigPathGet();

    if (!file_exists(_path)) {
        return false;
    }

    var _read = GamePersistenceTextRead(_path);
    if (!_read.ok) {
        return false;
    }

    var _parsed = GamePersistenceJsonParse(_read.contents);
    if (!_parsed.ok) {
        GamePersistenceBackupWrite(_path, _read.contents);
        show_debug_message("Warning: Invalid config data recovered; using defaults.");
        return false;
    }

    var _version = GamePersistenceVersionGet(_parsed.value);
    if (_version > CONFIG_VERSION) {
        GamePersistenceBackupWrite(_path, _read.contents);
        show_debug_message("Warning: Config data is from a newer unsupported version " + string(_version) + ".");
        return false;
    }

    var _needs_rewrite = !GameConfigDataIsCurrent(_parsed.value);
    var _migrated = GameConfigDataMigrate(_parsed.value);

    if (_needs_rewrite) {
        GamePersistenceBackupWrite(_path, _read.contents);
        GamePersistenceTextWrite(_path, json_stringify(_migrated));
    }

    global.game_config = _migrated;
    return true;
}

/// @func SaveGameSave()
/// Writes the current save struct back to disk.
function SaveGameSave() {
    return GamePersistenceTextWrite(GameSavePathGet(), json_stringify(global.game_save));
}

/// @func SaveGameConfig()
/// Writes the current config struct back to disk.
function SaveGameConfig() {
    return GamePersistenceTextWrite(GameConfigPathGet(), json_stringify(global.game_config));
}

/// @func GameSaveShipEntriesEnsure(ship_id)
/// Ensures a ship has all expected save arrays before results are written.
function GameSaveShipEntriesEnsure(_ship_id) {
    if (!is_struct(global.game_save)) {
        global.game_save = GameSaveDataCreateDefault();
    }

    global.game_save.version = SAVE_VERSION;

    // All four statistics share the same per-ship, ten-entry table schema.
    var _table_names = ["high_score", "runs_started", "runs_finished", "continues_used"];

    for (var i = 0; i < array_length(_table_names); i++) {
        var _table_name = _table_names[i];

        if (!struct_exists(global.game_save, _table_name) || !is_struct(global.game_save[$ _table_name])) {
            global.game_save[$ _table_name] = {};
        }

        var _table = global.game_save[$ _table_name];
        var _stored_values = struct_exists(_table, _ship_id) ? _table[$ _ship_id] : [];
        _table[$ _ship_id] = GameSaveValueArrayNormalize(_stored_values);
    }
}

/// @func GameValueArrayInsertAt(values, index, value)
/// Returns a fixed-length array with a new value inserted at the requested index.
function GameValueArrayInsertAt(_values, _index, _value) {
    var _count = array_length(_values);
    var _result = array_create(_count, 0);
    var _source_index = 0;

    if (_count <= 0) {
        return _result;
    }

    if (_index < 0 || _index >= _count) {
        for (var i = 0; i < _count; i++) {
            _result[i] = _values[i];
        }

        return _result;
    }

    for (var i = 0; i < _count; i++) {
        if (i == _index) {
            _result[i] = _value;
            continue;
        }

        _result[i] = _values[_source_index];
        _source_index += 1;
    }

    return _result;
}

/// @func GameValueArrayInsertDescendingIndex(values, value)
/// Returns an insertion index, or -1 when a value does not qualify for the chart.
function GameValueArrayInsertDescendingIndex(_values, _value) {
    var _count = array_length(_values);

    if (_count <= 0) {
        return -1;
    }

    for (var i = 0; i < _count; i++) {
        if (_value >= _values[i]) {
            return i;
        }
    }

    return -1;
}

/// @func GameRunResultSave()
/// Stores the current run's ending results into the persistent save data.
function GameRunResultSave() {
    if (!GameRunStatsShouldRecord()) {
        return false;
    }

    var _ship_id = global.game_runtime.selected_ship_id;

    if (_ship_id == "") {
        _ship_id = "ship_A";
    }

    GameSaveShipEntriesEnsure(_ship_id);

    var _high_scores = global.game_save.high_score[$ _ship_id];
    var _continues_used = global.game_save.continues_used[$ _ship_id];
    var _runs_finished = global.game_save.runs_finished[$ _ship_id];
    var _score_index = GameValueArrayInsertDescendingIndex(_high_scores, global.game_runtime.score);

    if (_score_index >= 0) {
        global.game_save.high_score[$ _ship_id] = GameValueArrayInsertAt(_high_scores, _score_index, global.game_runtime.score);
        global.game_save.continues_used[$ _ship_id] = GameValueArrayInsertAt(_continues_used, _score_index, global.game_runtime.continues_used);
    }

    _runs_finished[0] += 1;
    global.game_save.runs_finished[$ _ship_id] = _runs_finished;

    SaveGameSave();
    return true;
}

/// @func GameRuntimeReset()
/// Resets the runtime state back to its default values.
function GameRuntimeReset() {
    global.game_runtime = GameRuntimeDataCreateDefault();
}

/// @func GameWindowDisplayScaleFitGet(requested_scale)
/// Returns the largest requested integer scale that fits the active display.
function GameWindowDisplayScaleFitGet(_requested_scale) {
    var _view_width = max(1, global.game_config.view_width);
    var _view_height = max(1, global.game_config.view_height);
    var _display_width = max(_view_width, display_get_width());
    // Leave enough vertical room for normal desktop window chrome.
    var _display_height = max(_view_height, display_get_height() - 48);
    var _width_scale = max(1, floor(_display_width / _view_width));
    var _height_scale = max(1, floor(_display_height / _view_height));
    var _fit_scale = min(_width_scale, _height_scale);

    return clamp(round(_requested_scale), 1, _fit_scale);
}

/// @func GameWindowCenterNow()
/// Centers the current window against the active display dimensions.
function GameWindowCenterNow() {
    if (global.game_config.fullscreen) {
        return false;
    }

    var _window_width = window_get_width();
    var _window_height = window_get_height();
    var _display_width = display_get_width();
    var _display_height = display_get_height();
    var _window_x = max(0, floor((_display_width - _window_width) * 0.5));
    var _window_y = max(0, floor((_display_height - _window_height) * 0.5));

    window_set_position(_window_x, _window_y);
    return true;
}

/// @func GameWindowCenterStep()
/// Applies a delayed window resize and centering sequence after display mode changes.
function GameWindowCenterStep() {
    if (!variable_global_exists("game_window_apply_phase")) {
        global.game_window_apply_phase = "idle";
        global.game_window_apply_timer = 0;
    }

    if (global.game_config.fullscreen) {
        global.game_window_apply_phase = "idle";
        global.game_window_apply_timer = 0;
        return false;
    }

    if (global.game_window_apply_phase == "idle") {
        return false;
    }

    if (global.game_window_apply_timer > 0) {
        global.game_window_apply_timer -= 1;
        return false;
    }

    if (global.game_window_apply_phase == "resize") {
        var _applied_scale = GameWindowDisplayScaleFitGet(global.game_config.display_scale);
        global.game_window_applied_scale = _applied_scale;
        window_set_size(global.game_config.view_width * _applied_scale,
            global.game_config.view_height * _applied_scale);
        global.game_window_apply_phase = "center";
        global.game_window_apply_timer = 10;
        return true;
    }

    if (global.game_window_apply_phase == "center") {
        global.game_window_apply_phase = "idle";
        return GameWindowCenterNow();
    }

    return false;
}

/// @func GameConfigApply()
/// Applies the current config values to the active game window.
function GameConfigApply() {
    window_set_fullscreen(global.game_config.fullscreen);
    GameAudioVolumesApply();
    GamePixelPresentationApply();

    if (!global.game_config.fullscreen) {
        // macOS applies fullscreen transitions asynchronously, so resize after it settles.
        global.game_window_apply_phase = "resize";
        global.game_window_apply_timer = 10;
    } else {
        global.game_window_applied_scale = global.game_config.display_scale;
        global.game_window_apply_phase = "idle";
        global.game_window_apply_timer = 0;
    }

    game_set_speed(global.game_config.target_fps, gamespeed_fps);
}

/// @func GamePixelPresentationScaleIsInteger(output_width, output_height, view_width, view_height)
/// Returns whether both output axes are exact integer multiples of the low-res canvas.
function GamePixelPresentationScaleIsInteger(_output_width, _output_height,
    _view_width = 640, _view_height = 360) {
    var _scale_x = max(1, _output_width) / max(1, _view_width);
    var _scale_y = max(1, _output_height) / max(1, _view_height);
    var _epsilon = 0.0001;

    return abs(_scale_x - round(_scale_x)) <= _epsilon
        && abs(_scale_y - round(_scale_y)) <= _epsilon;
}

/// @func GamePixelPresentationLinearFilterGet(fullscreen, output_width, output_height)
/// Uses nearest-neighbour at integer scales and antialiases fractional fullscreen output.
function GamePixelPresentationLinearFilterGet(_fullscreen = undefined,
    _output_width = undefined, _output_height = undefined) {
    if (_fullscreen == undefined) {
        _fullscreen = variable_global_exists("game_config")
            && global.game_config.fullscreen;
    }
    if (_output_width == undefined) {
        _output_width = window_get_width();
    }
    if (_output_height == undefined) {
        _output_height = window_get_height();
    }

    return _fullscreen && !GamePixelPresentationScaleIsInteger(
        _output_width, _output_height, 640, 360);
}

/// @func GamePixelPresentationApply()
/// Pins every sprite, primitive, and GUI element to the authored 640x360 pixel grid.
function GamePixelPresentationApply() {
    gpu_set_texfilter(false);
    display_set_gui_size(640, 360);

    if (surface_exists(application_surface)) {
        if (surface_get_width(application_surface) != 640
            || surface_get_height(application_surface) != 360) {
            surface_resize(application_surface, 640, 360);
        }
    }

    return true;
}

/// @func GameInitialize()
/// Boots config, save, and runtime state and creates missing data files.
function GameInitialize() {
    global.game_config = GameConfigCreateDefault();
    global.game_save = GameSaveDataCreateDefault();
    global.game_runtime = GameRuntimeDataCreateDefault();
    
    var _save = LoadGameSave();
    if (_save == false) {
        // Missing or unrecoverable data starts clean after the original is backed up.
        SaveGameSave();
    }
    var _config = LoadGameConfig();
    if (_config == false) {
        SaveGameConfig();
    }
    
    GameConfigApply();
}

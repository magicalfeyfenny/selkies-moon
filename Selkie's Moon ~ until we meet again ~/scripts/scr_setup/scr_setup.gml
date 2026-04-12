//increment config and save versions when needed
#macro CONFIG_VERSION 3
#macro SAVE_VERSION 2
#macro RUNTIME_VERSION 4

#macro DEFAULT_LIVES 3
#macro DEFAULT_BOMBS 3

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
    };
}

/// @func GameSaveDataCreateDefault()
/// Creates the default persistent save data structure.
function GameSaveDataCreateDefault() {
    return {
        version: SAVE_VERSION,
        high_score: {
            ship_A: [0,0,0,0,0,0,0,0,0,0]
        },
        runs_started: {
            ship_A: [0,0,0,0,0,0,0,0,0,0]
        },
        runs_finished: {
            ship_A: [0,0,0,0,0,0,0,0,0,0]
        },
        continues_used: {
            ship_A: [0,0,0,0,0,0,0,0,0,0]
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
        },
        story: {
            requested_file: "",
            current_file: "",
        },
        selected_ship_id: "",
        selected_ship_index: -1,
        score: 0,
        continues_used: 0,
        lives: DEFAULT_LIVES,
        bombs: DEFAULT_BOMBS,
    };
}

/// @func GameSavePathGet()
/// Returns the relative path used for the save file.
function GameSavePathGet() {
    return "game.sav";
}

/// @func GameConfigPathGet()
/// Returns the relative path used for the config file.
function GameConfigPathGet() {
    return "config.sav";
}

/// @func LoadGameSave()
/// Loads save data when the on-disk version matches the current format.
function LoadGameSave() {
    var _did_load = false;
    var _path = GameSavePathGet();

    if (file_exists(_path)) {
        var _file = file_text_open_read(_path);
        var _json_string = file_text_read_string(_file);
        file_text_close(_file);

        var _json = json_parse(_json_string);
        if (_json.version == SAVE_VERSION) {
            global.game_save = _json;
            _did_load = true;
        } else {
            show_debug_message("Warning: Old save data detected. Expected version " + string(SAVE_VERSION)
                + ", got version " + string(_json.version));
        }
    }

    return _did_load;
}

/// @func LoadGameConfig()
/// Loads config data when the on-disk version matches the current format.
function LoadGameConfig() {
    var _did_load = false;
    var _path = GameConfigPathGet();

    if (file_exists(_path)) {
        var _file = file_text_open_read(_path);
        var _json_string = file_text_read_string(_file);
        file_text_close(_file);

        var _json = json_parse(_json_string);
        if (_json.version == CONFIG_VERSION) {
            global.game_config = _json;
            _did_load = true;
        } else {
            show_debug_message("Warning: Old config data detected. Expected version " + string(CONFIG_VERSION)
                + ", got version " + string(_json.version));
        }
    }

    return _did_load;
}

/// @func SaveGameSave()
/// Writes the current save struct back to disk.
function SaveGameSave() {
    var _file = file_text_open_write(GameSavePathGet());
    file_text_write_string(_file, json_stringify(global.game_save));
    file_text_close(_file);
}

/// @func SaveGameConfig()
/// Writes the current config struct back to disk.
function SaveGameConfig() {
    var _file = file_text_open_write(GameConfigPathGet());
    file_text_write_string(_file, json_stringify(global.game_config));
    file_text_close(_file);
}

/// @func GameSaveShipEntriesEnsure(ship_id)
/// Ensures a ship has all expected save arrays before results are written.
function GameSaveShipEntriesEnsure(_ship_id) {
    if (!struct_exists(global.game_save.high_score, _ship_id)) {
        global.game_save.high_score[$ _ship_id] = array_create(10, 0);
    }

    if (!struct_exists(global.game_save.runs_started, _ship_id)) {
        global.game_save.runs_started[$ _ship_id] = array_create(10, 0);
    }

    if (!struct_exists(global.game_save.runs_finished, _ship_id)) {
        global.game_save.runs_finished[$ _ship_id] = array_create(10, 0);
    }

    if (!struct_exists(global.game_save.continues_used, _ship_id)) {
        global.game_save.continues_used[$ _ship_id] = array_create(10, 0);
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

    _index = clamp(_index, 0, _count - 1);

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
/// Returns the index where a descending score chart should insert a value.
function GameValueArrayInsertDescendingIndex(_values, _value) {
    var _count = array_length(_values);

    if (_count <= 0) {
        return 0;
    }

    for (var i = 0; i < _count; i++) {
        if (_value >= _values[i]) {
            return i;
        }
    }

    return _count - 1;
}

/// @func GameValueArrayInsertDescending(values, value)
/// Returns a fixed-length array with a value inserted into descending order.
function GameValueArrayInsertDescending(_values, _value) {
    return GameValueArrayInsertAt(_values, GameValueArrayInsertDescendingIndex(_values, _value), _value);
}

/// @func GameRunResultSave()
/// Stores the current run's ending results into the persistent save data.
function GameRunResultSave() {
    var _ship_id = global.game_runtime.selected_ship_id;

    if (_ship_id == "") {
        _ship_id = "ship_A";
    }

    GameSaveShipEntriesEnsure(_ship_id);

    var _high_scores = global.game_save.high_score[$ _ship_id];
    var _continues_used = global.game_save.continues_used[$ _ship_id];
    var _runs_finished = global.game_save.runs_finished[$ _ship_id];
    var _score_index = GameValueArrayInsertDescendingIndex(_high_scores, global.game_runtime.score);

    global.game_save.high_score[$ _ship_id] = GameValueArrayInsertAt(_high_scores, _score_index, global.game_runtime.score);
    global.game_save.continues_used[$ _ship_id] = GameValueArrayInsertAt(_continues_used, _score_index, global.game_runtime.continues_used);

    _runs_finished[0] += 1;
    global.game_save.runs_finished[$ _ship_id] = _runs_finished;

    SaveGameSave();
}

/// @func GameRuntimeReset()
/// Resets the runtime state back to its default values.
function GameRuntimeReset() {
    global.game_runtime = GameRuntimeDataCreateDefault();
}

/// @func GameConfigApply()
/// Applies the current config values to the active game window.
function GameConfigApply() {
    window_set_fullscreen(global.game_config.fullscreen);
    if (!global.game_config.fullscreen) {
        window_set_size(global.game_config.view_width * global.game_config.display_scale,
            global.game_config.view_height * global.game_config.display_scale);
    }
    game_set_speed(global.game_config.target_fps, gamespeed_fps);
}

/// @func GameInitialize()
/// Boots config, save, and runtime state and creates missing data files.
function GameInitialize() {
    global.game_config = GameConfigCreateDefault();
    global.game_save = GameSaveDataCreateDefault();
    global.game_runtime = GameRuntimeDataCreateDefault();
    
    var _save = LoadGameSave();
    if (_save == false) {
        //if we didn't load the save file, then we need to create or overwrite it
        var _save_file = file_text_open_write(GameSavePathGet());
        file_text_write_string(_save_file, json_stringify(global.game_save));
        file_text_close(_save_file);
    }
    var _config = LoadGameConfig();
    if (_config == false) {
        //if we didn't load the config file, then we need to create or overwrite it
        var _config_file = file_text_open_write(GameConfigPathGet());
        file_text_write_string(_config_file, json_stringify(global.game_config));
        file_text_close(_config_file);
    }
    
    GameConfigApply();
}

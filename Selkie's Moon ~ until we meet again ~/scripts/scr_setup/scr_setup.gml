//increment config and save versions when needed
#macro CONFIG_VERSION 3
#macro SAVE_VERSION 2
#macro RUNTIME_VERSION 2

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
        score: 0,
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

/// @func SaveGameConfig()
/// Writes the current config struct back to disk.
function SaveGameConfig() {
    var _file = file_text_open_write(GameConfigPathGet());
    file_text_write_string(_file, json_stringify(global.game_config));
    file_text_close(_file);
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

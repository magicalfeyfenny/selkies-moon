//increment config and save versions when needed
#macro CONFIG_VERSION 2
#macro SAVE_VERSION 1
#macro LIVES_VERSION 

function GameConfigCreateDefault() {
    return {
        version: CONFIG_VERSION,
        view_width: 640,
        view_height: 360,
        target_fps: 60,
        display_scale: 2,
        fullscreen: false,
    };
}

function GameSaveDataCreateDefault() {
    return {
        version: SAVE_VERSION,
        high_score: 0,
        runs_started: 0,
        runs_finished: 0,
        continues_used: 0,
        options: {
            display_scale: 2,
            fullscreen: false
        }
    };
}

function GameRuntimeDataCreateDefault() {
    return {
        is_initialized: true,
        state: "boot",
        score: 0,
        lives: DEFAULT_LIVES,
        bombs: DEFAULT_BOMBS
    };
}

function GameSavePathGet() {
    return "game.sav";
}

function GameConfigPathGet() {
    return "config.sav";
}

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

function GameConfigApply() {
    room_w
}

function GameInitialize() {
    global.game_config = GameConfigCreateDefault();
    global.game_save = GameSaveDataCreateDefault();
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

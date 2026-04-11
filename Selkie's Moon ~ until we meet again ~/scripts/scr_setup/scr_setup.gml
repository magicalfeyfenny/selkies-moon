function GameProjectDirectoryGet() {
    var _project_path = string_replace_all(GM_project_filename, "\\", "/");
    var _separator_index = string_last_pos("/", _project_path);

    if (_separator_index <= 0) {
        return "";
    }

    return string_copy(_project_path, 1, _separator_index);
}

function GameTestsMarkerPathGet() {
    return GameProjectDirectoryGet() + ".run-gmtl-tests.txt";
}

function GameCommandLineHasFlag(_flag) {
    var _parameter_total = parameter_count();

    for (var i = 1; i <= _parameter_total; i++) {
        if (parameter_string(i) == _flag) {
            return true;
        }
    }

    return false;
}

function GameShouldQuitAfterTests() {
    if (GameCommandLineHasFlag("--run-test")) {
        return true;
    }

    return GameCommandLineHasFlag("-runTest");
}

function GameShouldRunTests() {
    if (GameShouldQuitAfterTests()) {
        return true;
    }

    return file_exists(GameTestsMarkerPathGet());
}

function GameConfigCreateDefault() {
    return {
        room_width: 640,
        room_height: 360,
        view_width: 640,
        view_height: 360,
        target_fps: 60,
        display_scale: 2,
        fullscreen: false,
        scroll_speed: 2,
        player_move_speed: 4
    };
}

function GameSaveDataCreateDefault() {
    return {
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

function GameInitialize() {
    global.game_config = GameConfigCreateDefault();
    global.game_save = GameSaveDataCreateDefault();
    global.game_runtime = {
        is_initialized: true,
        state: "boot",
        score: 0,
        lives: 3,
        bombs: 2
    };

    game_set_speed(global.game_config.target_fps, gamespeed_fps);
}

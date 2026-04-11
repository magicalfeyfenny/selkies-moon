function GameDirectoryPathNormalize(_path) {
    _path = string_replace_all(_path, "\\", "/");

    if (_path == "") {
        return "";
    }

    if (string_char_at(_path, string_length(_path)) != "/") {
        _path += "/";
    }

    return _path;
}

function GameProjectDirectoryGet() {
    var _project_path = string_replace_all(GM_project_filename, "\\", "/");
    var _separator_index = string_last_pos("/", _project_path);

    if (_separator_index <= 0) {
        return "";
    }

    return string_copy(_project_path, 1, _separator_index);
}

function GameWorkingDirectoryGet() {
    return GameDirectoryPathNormalize(working_directory);
}

function GameTestsMarkerPathGet() {
    return GameWorkingDirectoryGet() + ".run-gmtl-tests.txt";
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
    var _has_marker = file_exists(GameTestsMarkerPathGet());
    var _has_test_flag = GameCommandLineHasFlag("--run-test") || GameCommandLineHasFlag("-runTest");

    return _has_marker && _has_test_flag;
}

function GameShouldRunTests() {
    return file_exists(GameTestsMarkerPathGet());
}

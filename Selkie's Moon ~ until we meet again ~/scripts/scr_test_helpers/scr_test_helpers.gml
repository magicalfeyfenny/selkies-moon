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

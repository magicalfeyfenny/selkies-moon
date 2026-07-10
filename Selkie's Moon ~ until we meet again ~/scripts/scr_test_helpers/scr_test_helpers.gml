/// @func GameDirectoryPathNormalize(path)
/// Normalizes a directory path to forward slashes with a trailing slash.
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

/// @func GameProjectDirectoryGet()
/// Returns the project directory derived from the loaded project filename.
function GameProjectDirectoryGet() {
    var _project_path = string_replace_all(GM_project_filename, "\\", "/");
    var _separator_index = string_last_pos("/", _project_path);

    if (_separator_index <= 0) {
        return "";
    }

    return string_copy(_project_path, 1, _separator_index);
}

/// @func GameWorkingDirectoryGet()
/// Returns the normalized runtime working directory.
function GameWorkingDirectoryGet() {
    return GameDirectoryPathNormalize(working_directory);
}

/// @func GameTestsMarkerPathGet()
/// Returns the marker file path used by the external GMTL runner.
function GameTestsMarkerPathGet() {
    return GameWorkingDirectoryGet() + ".run-gmtl-tests.txt";
}

/// @func GameCommandLineHasFlag(flag)
/// Checks whether the current run was launched with a specific CLI flag.
function GameCommandLineHasFlag(_flag) {
    var _parameter_total = parameter_count();

    for (var i = 1; i <= _parameter_total; i++) {
        if (parameter_string(i) == _flag) {
            return true;
        }
    }

    return false;
}

/// @func GameShouldQuitAfterTests()
/// Returns whether the game should close itself after finishing tests.
function GameShouldQuitAfterTests() {
    var _has_marker = file_exists(GameTestsMarkerPathGet());
    var _has_test_flag = GameCommandLineHasFlag("--run-test") || GameCommandLineHasFlag("-runTest");

    return _has_test_flag || _has_marker;
}

/// @func GameShouldRunTests()
/// Returns whether this launch should boot into GMTL test mode.
function GameShouldRunTests() {
    return GameShouldQuitAfterTests();
}

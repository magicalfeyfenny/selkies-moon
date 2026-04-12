/// @func GameStoryFrameCreate(name, text, portraits, positions)
/// Creates a normalized dialogue frame for the story UI.
function GameStoryFrameCreate(_name = "", _text = "", _portraits = [], _positions = []) {
    return {
        name: string(_name),
        text: string(_text),
        portraits: _portraits,
        positions: _positions,
    };
}

/// @func GameStoryStateCreate()
/// Creates the local state container used by obj_UI_story.
function GameStoryStateCreate() {
    return {
        frames: [],
        frame_index: -1,
        current_frame: GameStoryFrameCreate(),
        active_file: "",
    };
}

/// @func GameStoryRuntimeEnsure()
/// Ensures the runtime story request struct exists before story code uses it.
function GameStoryRuntimeEnsure() {
    if (!variable_global_exists("game_runtime")) {
        return false;
    }

    if (!struct_exists(global.game_runtime, "story")) {
        global.game_runtime.story = {
            requested_file: "",
            current_file: "",
        };
    }

    return true;
}

/// @func GameStoryPathJoin(directory, filename)
/// Joins a directory and filename with normalized forward slashes.
function GameStoryPathJoin(_directory, _filename) {
    _directory = string_replace_all(_directory, "\\", "/");

    if (_directory != "" && string_char_at(_directory, string_length(_directory)) != "/") {
        _directory += "/";
    }

    return _directory + _filename;
}

/// @func GameStoryResolveFilePath(filename)
/// Resolves a story filename against likely runtime locations.
function GameStoryResolveFilePath(_filename) {
    if (file_exists(_filename)) {
        return _filename;
    }

    var _working_path = GameStoryPathJoin(working_directory, _filename);
    if (file_exists(_working_path)) {
        return _working_path;
    }

    var _datafiles_path = GameStoryPathJoin(working_directory, "datafiles/" + _filename);
    if (file_exists(_datafiles_path)) {
        return _datafiles_path;
    }

    var _relative_datafiles_path = "datafiles/" + _filename;
    if (file_exists(_relative_datafiles_path)) {
        return _relative_datafiles_path;
    }

    return "";
}

/// @func GameStoryFileReadAll(path)
/// Reads the entire contents of a text file into one string.
function GameStoryFileReadAll(_path) {
    if (_path == "" || !file_exists(_path)) {
        return "";
    }

    var _file = file_text_open_read(_path);
    var _contents = "";

    while (!file_text_eof(_file)) {
        _contents += file_text_read_string(_file);

        if (!file_text_eof(_file)) {
            file_text_readln(_file);

            if (!file_text_eof(_file)) {
                _contents += "\n";
            }
        }
    }

    file_text_close(_file);
    return _contents;
}

/// @func GameStoryPositionDefaultForIndex(index)
/// Returns a fallback portrait slot for the requested portrait index.
function GameStoryPositionDefaultForIndex(_index) {
    switch (_index) {
        case 1:
            return "right";

        case 2:
            return "center";
    }

    return "left";
}

/// @func GameStoryFrameNormalize(frame_data)
/// Normalizes parsed JSON data into one dialogue frame struct.
function GameStoryFrameNormalize(_frame_data) {
    var _name = "";
    var _text = "";
    var _portraits = [];
    var _positions = [];

    if (!is_struct(_frame_data)) {
        return GameStoryFrameCreate();
    }

    if (struct_exists(_frame_data, "name")) {
        _name = _frame_data.name;
    }

    if (struct_exists(_frame_data, "text")) {
        _text = _frame_data.text;
    }

    if (struct_exists(_frame_data, "portraits")) {
        if (is_array(_frame_data.portraits)) {
            _portraits = _frame_data.portraits;
        } else if (_frame_data.portraits != undefined) {
            _portraits = [string(_frame_data.portraits)];
        }
    }

    if (struct_exists(_frame_data, "positions")) {
        if (is_array(_frame_data.positions)) {
            _positions = _frame_data.positions;
        } else if (_frame_data.positions != undefined) {
            _positions = [string(_frame_data.positions)];
        }
    }

    return GameStoryFrameCreate(_name, _text, _portraits, _positions);
}

/// @func GameStoryFramesNormalize(json_data)
/// Extracts and normalizes an array of story frames from parsed JSON.
function GameStoryFramesNormalize(_json_data) {
    var _source_frames = [];

    if (is_array(_json_data)) {
        _source_frames = _json_data;
    } else if (is_struct(_json_data) && struct_exists(_json_data, "frames") && is_array(_json_data.frames)) {
        _source_frames = _json_data.frames;
    }

    var _frame_count = array_length(_source_frames);
    var _frames = array_create(_frame_count);

    for (var i = 0; i < _frame_count; i++) {
        _frames[i] = GameStoryFrameNormalize(_source_frames[i]);
    }

    return _frames;
}

/// @func GameStoryLoadFramesFromFile(filename)
/// Loads and parses a story frame queue from a JSON file.
function GameStoryLoadFramesFromFile(_filename) {
    var _path = GameStoryResolveFilePath(_filename);
    if (_path == "") {
        return [];
    }

    var _contents = GameStoryFileReadAll(_path);
    if (_contents == "") {
        return [];
    }

    var _json_data = json_parse(_contents);
    return GameStoryFramesNormalize(_json_data);
}

/// @func GameStoryIsActive(state)
/// Returns whether the story UI currently has a live frame queue.
function GameStoryIsActive(_state) {
    return _state.frame_index >= 0 && array_length(_state.frames) > 0;
}

/// @func GameStoryStateClear(state)
/// Clears the active story queue and current frame.
function GameStoryStateClear(_state) {
    _state.frames = [];
    _state.frame_index = -1;
    _state.current_frame = GameStoryFrameCreate();
    _state.active_file = "";
}

/// @func GameStoryQueueRequest(filename)
/// Queues a story file to be started by obj_UI_story.
function GameStoryQueueRequest(_filename) {
    if (!GameStoryRuntimeEnsure() || _filename == "") {
        return false;
    }

    global.game_runtime.story.requested_file = _filename;
    global.game_runtime.signals.dialogue = true;
    return true;
}

/// @func GameStoryDefaultFileGet(room_id)
/// Returns the default story file for a room that auto-starts dialogue.
function GameStoryDefaultFileGet(_room_id) {
    switch (_room_id) {
        case rm_ending:
            return "ending_story.json";

        case rm_opening:
            return "opening_story.json";
    }

    return "";
}

/// @func GameStoryRoomComplete(room_id)
/// Applies room-specific completion side effects before a story transition.
function GameStoryRoomComplete(_room_id) {
    switch (_room_id) {
        case rm_ending:
            GameRunResultSave();
            GameRuntimeReset();
            break;
    }
}

/// @func GameStoryNextRoomGet(room_id)
/// Returns the room that should load after a room's story segment completes.
function GameStoryNextRoomGet(_room_id) {
    switch (_room_id) {
        case rm_ending:
            return rm_title;

        case rm_opening:
            return rm_game;
    }

    return -1;
}

/// @func GameStoryTransitionRoomGet(room_id, was_dialogue_active, is_dialogue_active)
/// Returns a pending room transition when a room's story segment has just finished.
function GameStoryTransitionRoomGet(_room_id, _was_dialogue_active, _is_dialogue_active) {
    if (!_was_dialogue_active || _is_dialogue_active) {
        return -1;
    }

    GameStoryRoomComplete(_room_id);
    return GameStoryNextRoomGet(_room_id);
}

/// @func GameStoryBegin(state, filename)
/// Starts a story queue from the requested file and shows the first frame.
function GameStoryBegin(_state, _filename) {
    if (!GameStoryRuntimeEnsure()) {
        return false;
    }

    var _frames = GameStoryLoadFramesFromFile(_filename);
    if (array_length(_frames) <= 0) {
        GameStoryStateClear(_state);
        global.game_runtime.story.requested_file = "";
        global.game_runtime.story.current_file = "";
        global.game_runtime.signals.dialogue = false;
        return false;
    }

    _state.frames = _frames;
    _state.frame_index = 0;
    _state.current_frame = _frames[0];
    _state.active_file = _filename;

    global.game_runtime.story.requested_file = "";
    global.game_runtime.story.current_file = _filename;
    global.game_runtime.signals.dialogue = true;
    return true;
}

/// @func GameStoryAdvance(state)
/// Advances to the next frame or closes the story when the queue ends.
function GameStoryAdvance(_state) {
    if (!GameStoryRuntimeEnsure() || !GameStoryIsActive(_state)) {
        return false;
    }

    _state.frame_index += 1;

    if (_state.frame_index >= array_length(_state.frames)) {
        GameStoryStateClear(_state);
        global.game_runtime.story.current_file = "";
        global.game_runtime.signals.dialogue = false;
        return false;
    }

    _state.current_frame = _state.frames[_state.frame_index];
    return true;
}

/// @func GameStoryAdvanceInputPressed()
/// Returns whether the current frame should advance this step.
function GameStoryAdvanceInputPressed() {
    return GameInputVerbPressed("fire") || GameInputVerbPressed("autofire") || GameInputVerbPressed("bomb");
}

/// @func GameStoryUpdate(state)
/// Starts queued stories and advances the active frame queue from input.
function GameStoryUpdate(_state) {
    if (!GameStoryRuntimeEnsure()) {
        return;
    }

    if (!global.game_runtime.signals.dialogue) {
        GameStoryStateClear(_state);
        global.game_runtime.story.current_file = "";
        return;
    }

    if (!GameStoryIsActive(_state)) {
        if (global.game_runtime.story.requested_file != "") {
            GameStoryBegin(_state, global.game_runtime.story.requested_file);
        }

        return;
    }

    if (GameStoryAdvanceInputPressed()) {
        GameStoryAdvance(_state);
    }
}

/// @func GameStoryPortraitRectGet(position)
/// Returns the destination rectangle for a 360x360 portrait slot.
function GameStoryPortraitRectGet(_position) {
    var _gui_width = display_get_gui_width();
    var _gui_height = display_get_gui_height();
    var _portrait_width = 360;
    var _portrait_height = 360;
    var _x = 0;
    var _y = max(0, (_gui_height - _portrait_height) * 0.5);

    switch (string_lower(string(_position))) {
        case "right":
            _x = _gui_width - _portrait_width;
            break;

        case "center":
            _x = (_gui_width - _portrait_width) * 0.5;
            break;

        default:
            _x = 0;
            break;
    }

    return {
        x: _x,
        y: _y,
        width: _portrait_width,
        height: _portrait_height,
    };
}

/// @func GameStoryPortraitColorGet(portrait_id)
/// Generates a stable fallback color for a portrait placeholder.
function GameStoryPortraitColorGet(_portrait_id) {
    var _hash = 0;
    var _length = string_length(_portrait_id);

    for (var i = 1; i <= _length; i++) {
        _hash += ord(string_char_at(_portrait_id, i)) * i;
    }

    return make_color_hsv(_hash mod 256, 170, 225);
}

/// @func GameStoryDrawPortraitPlaceholder(portrait_id, position)
/// Draws a colored portrait card when no matching sprite exists yet.
function GameStoryDrawPortraitPlaceholder(_portrait_id, _position) {
    var _rect = GameStoryPortraitRectGet(_position);
    var _fill_color = GameStoryPortraitColorGet(_portrait_id);

    draw_set_alpha(0.92);
    draw_set_color(_fill_color);
    draw_rectangle(_rect.x, _rect.y, _rect.x + _rect.width, _rect.y + _rect.height, false);

    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_rectangle(_rect.x, _rect.y, _rect.x + _rect.width, _rect.y + _rect.height, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_dialogue_name);
    draw_set_color(c_white);
    draw_text(_rect.x + (_rect.width * 0.5), _rect.y + (_rect.height * 0.5), string_upper(string(_portrait_id)));
}

/// @func GameStoryDrawPortrait(portrait_id, position)
/// Draws a portrait sprite when present or a placeholder panel otherwise.
function GameStoryDrawPortrait(_portrait_id, _position) {
    var _asset_index = asset_get_index(_portrait_id);
    var _rect = GameStoryPortraitRectGet(_position);

    if (_asset_index != -1 && sprite_exists(_asset_index)) {
        draw_set_alpha(1.0);
        draw_set_color(c_white);
        draw_sprite_stretched(_asset_index, 0, _rect.x, _rect.y, _rect.width, _rect.height);
        return;
    }

    GameStoryDrawPortraitPlaceholder(_portrait_id, _position);
}

/// @func GameStoryDrawBackground(frame)
/// Draws the current frame portraits behind the dialogue box.
function GameStoryDrawBackground(_frame) {
    var _portrait_count = array_length(_frame.portraits);

    if (_portrait_count <= 0) {
        draw_set_alpha(0.35);
        draw_set_color(make_color_rgb(12, 18, 34));
        draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
        return;
    }

    for (var i = 0; i < _portrait_count; i++) {
        var _position = GameStoryPositionDefaultForIndex(i);

        if (i < array_length(_frame.positions)) {
            _position = _frame.positions[i];
        }

        GameStoryDrawPortrait(string(_frame.portraits[i]), _position);
    }
}

/// @func GameStoryDrawBox(frame)
/// Draws the semi-transparent dialogue box and current text content.
function GameStoryDrawBox(_frame) {
    var _gui_width = display_get_gui_width();
    var _gui_height = display_get_gui_height();
    var _box_x = 16;
    var _box_y = _gui_height - 120;
    var _box_width = _gui_width - 32;
    var _box_height = 104;

    draw_set_alpha(0.72);
    draw_set_color(c_black);
    draw_rectangle(_box_x, _box_y, _box_x + _box_width, _box_y + _box_height, false);

    draw_set_alpha(1.0);
    draw_set_color(make_color_rgb(224, 236, 255));
    draw_rectangle(_box_x, _box_y, _box_x + _box_width, _box_y + _box_height, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fn_dialogue_name);
    draw_set_color(make_color_rgb(255, 230, 180));
    draw_text(_box_x + 16, _box_y + 10, _frame.name);

    draw_set_font(fn_dialogue_speech);
    draw_set_color(c_white);
    draw_text_ext(_box_x + 16, _box_y + 36, _frame.text, 18, _box_width - 32);

    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_set_font(fn_menu);
    draw_set_color(make_color_rgb(180, 204, 232));
    draw_text(_box_x + _box_width - 14, _box_y + _box_height - 10, "Z / C / X continue");
}

/// @func GameStoryDraw(state)
/// Draws the active story frame when dialogue is currently enabled.
function GameStoryDraw(_state) {
    if (!GameStoryRuntimeEnsure() || !global.game_runtime.signals.dialogue || !GameStoryIsActive(_state)) {
        return;
    }

    GameStoryDrawBackground(_state.current_frame);
    GameStoryDrawBox(_state.current_frame);
}

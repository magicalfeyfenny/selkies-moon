/// @func GameStoryFrameCreate(name, text, portraits, positions, backgrounds)
/// Creates a normalized dialogue frame for the story UI.
function GameStoryFrameCreate(_name = "", _text = "", _portraits = [], _positions = [], _backgrounds = []) {
    return {
        name: string(_name),
        text: string(_text),
        portraits: _portraits,
        positions: _positions,
        backgrounds: _backgrounds,
    };
}

// Story JSON loading, dialogue state transitions, and shared ornate UI drawing.

/// @func GameStoryStateCreate()
/// Creates the local state container used by obj_UI_story.
function GameStoryStateCreate() {
    return {
        frames: [],
        frame_index: -1,
        current_frame: GameStoryFrameCreate(),
        active_file: "",
        reveal_characters: 0,
        reveal_wait: 0,
        reveal_complete: true,
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
    // Prefer packaged data over a same-named stale sandbox copy. GameMaker's
    // working_directory is the writable app-support sandbox on macOS; shipped
    // Included Files live beside the runner in program_directory.
    var _program_path = GameStoryPathJoin(program_directory, _filename);
    if (file_exists(_program_path)) {
        return _program_path;
    }

    var _program_datafiles_path = GameStoryPathJoin(program_directory, "datafiles/" + _filename);
    if (file_exists(_program_datafiles_path)) {
        return _program_datafiles_path;
    }

    // Test fixtures and user-authored loose files resolve through writable
    // locations only after packaged content has been exhausted.
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

    if (file_exists(_filename)) {
        return _filename;
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
    var _backgrounds = [];

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

    if (struct_exists(_frame_data, "backgrounds")) {
        if (is_array(_frame_data.backgrounds)) {
            _backgrounds = _frame_data.backgrounds;
        } else if (_frame_data.backgrounds != undefined) {
            _backgrounds = [string(_frame_data.backgrounds)];
        }
    }

    return GameStoryFrameCreate(_name, _text, _portraits, _positions, _backgrounds);
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
    _state.reveal_characters = 0;
    _state.reveal_wait = 0;
    _state.reveal_complete = true;
}

/// @func GameStoryTypewriterDelayForCharacter(character)
/// Returns the number of extra steps to hold after revealing a character.
function GameStoryTypewriterDelayForCharacter(_character) {
    switch (_character) {
        case ".":
        case "!":
        case "?":
            return 9;

        case ",":
        case ";":
        case ":":
            return 4;

        case "-":
        case "—":
            return 3;

        case " ":
            return 0;
    }

    // One hold step produces an even 30-character-per-second cadence at the
    // game's native 60 fps without tying the reveal to rendered frame rate.
    return 1;
}

/// @func GameStoryTextArrowFrameGet(elapsed_ms, frame_count)
/// Returns the source-authored 3 fps loop frame for the continue arrow.
function GameStoryTextArrowFrameGet(_elapsed_ms = current_time,
    _frame_count = 8) {
    _frame_count = max(1, floor(_frame_count));
    return floor(max(0, _elapsed_ms) * 3 / 1000) mod _frame_count;
}

/// @func GameStoryRevealReset(state)
/// Starts the current dialogue frame at its first character.
function GameStoryRevealReset(_state) {
    _state.reveal_characters = 0;
    _state.reveal_wait = 0;
    _state.reveal_complete = string_length(_state.current_frame.text) <= 0;
    return _state.reveal_complete;
}

/// @func GameStoryRevealComplete(state)
/// Reveals the entire current frame immediately.
function GameStoryRevealComplete(_state) {
    _state.reveal_characters = string_length(_state.current_frame.text);
    _state.reveal_wait = 0;
    _state.reveal_complete = true;
    return _state.reveal_characters;
}

/// @func GameStoryRevealStep(state)
/// Advances the punctuation-aware typewriter by one fixed gameplay step.
function GameStoryRevealStep(_state) {
    if (_state.reveal_complete || !GameStoryIsActive(_state)) {
        return false;
    }

    if (_state.reveal_wait > 0) {
        _state.reveal_wait -= 1;
        return false;
    }

    var _text_length = string_length(_state.current_frame.text);
    _state.reveal_characters = min(_text_length,
        _state.reveal_characters + 1);

    if (_state.reveal_characters >= _text_length) {
        _state.reveal_complete = true;
        _state.reveal_wait = 0;
    } else {
        var _character = string_char_at(_state.current_frame.text,
            _state.reveal_characters);
        _state.reveal_wait = GameStoryTypewriterDelayForCharacter(_character);
    }

    return true;
}

/// @func GameStoryContinue(state)
/// First reveals an unfinished frame; a later press advances the queue.
function GameStoryContinue(_state) {
    if (!_state.reveal_complete) {
        GameStoryRevealComplete(_state);
        return true;
    }

    return GameStoryAdvance(_state);
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

/// @func GameFinalBossStoryFileGet()
/// Returns the stage 5 confrontation file for the selected route.
function GameFinalBossStoryFileGet() {
    if (GameRunShipIdGet() == SHIP_SELKIE) {
        return "boss_intro_story_selkie_route_v2.json";
    }

    return "boss_intro_story_v2.json";
}

/// @func GameCharacterBossStoryFileGet(stage, after_defeat, ship_id)
/// Returns a character boss's route-specific story seam, or an empty string.
function GameCharacterBossStoryFileGet(_stage, _after_defeat = false, _ship_id = undefined) {
    var _character_boss = GameCharacterBossInfoCreate(_stage);
    if (!is_struct(_character_boss)) {
        return "";
    }

    if (_ship_id == undefined) {
        _ship_id = GameRunShipIdGet();
    }

    var _route = (_ship_id == SHIP_SELKIE) ? "selkie_route" : "moon_route";
    var _seam = _after_defeat ? "defeat" : "intro";
    return _character_boss.story_id + "_" + _seam + "_story_" + _route + "_v2.json";
}

/// @func GameEndingStoryFileGet()
/// Returns the ending file for the selected route.
function GameEndingStoryFileGet() {
    if (GameRunShipIdGet() == SHIP_SELKIE) {
        return "ending_story_selkie_route_v2.json";
    }

    return "ending_story_v2.json";
}

/// @func GameStoryDefaultFileGet(room_id)
/// Returns the default story file for a room that auto-starts dialogue.
function GameStoryDefaultFileGet(_room_id) {
    switch (_room_id) {
        case rm_ending:
            return GameEndingStoryFileGet();

        case rm_opening:
            return "opening_story_v2.json";
    }

    return "";
}

/// @func GameStoryRoomComplete(room_id)
/// Applies room-specific completion side effects before a story transition.
function GameStoryRoomComplete(_room_id) {
    switch (_room_id) {
        case rm_ending:
            GameRunResultSave();
            break;
    }
}

/// @func GameStoryNextRoomGet(room_id)
/// Returns the room that should load after a room's story segment completes.
function GameStoryNextRoomGet(_room_id) {
    switch (_room_id) {
        case rm_ending:
            return rm_credits;

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
    global.game_runtime.signals.dialogue = false;
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
    GameStoryRevealReset(_state);

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
    GameStoryRevealReset(_state);
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

    GameStoryRevealStep(_state);

    if (GameStoryAdvanceInputPressed()) {
        GameStoryContinue(_state);
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
    GameUiDrawOutlinedText(string_upper(string(_portrait_id)), _rect.x + (_rect.width * 0.5), _rect.y + (_rect.height * 0.5), c_white);
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

/// @func GameStoryDrawBackgroundSprite(background_id)
/// Draws a full-screen dialogue background sprite when it exists.
function GameStoryDrawBackgroundSprite(_background_id) {
    var _asset_index = asset_get_index(_background_id);

    if (_asset_index == -1 || !sprite_exists(_asset_index)) {
        return false;
    }

    draw_set_alpha(1.0);
    draw_set_color(c_white);

    if (_background_id == "spr_dialogue_bg_flower") {
        var _scale = min(0.54, min(360 / sprite_get_width(_asset_index), 196 / sprite_get_height(_asset_index)));
        var _draw_width = sprite_get_width(_asset_index) * _scale;
        var _draw_height = sprite_get_height(_asset_index) * _scale;
        draw_sprite_stretched(_asset_index, 0,
            (display_get_gui_width() - _draw_width) * 0.5,
            28,
            _draw_width,
            _draw_height);
        return true;
    }

    draw_sprite_stretched(_asset_index, 0, 0, 0, display_get_gui_width(), display_get_gui_height());
    return true;
}

/// @func GameStoryDrawBackground(frame)
/// Draws the current frame portraits behind the dialogue box.
function GameStoryDrawBackground(_frame) {
    var _background_count = array_length(_frame.backgrounds);
    var _portrait_count = array_length(_frame.portraits);
    var _drew_background = false;

    for (var j = 0; j < _background_count; j++) {
        if (GameStoryDrawBackgroundSprite(string(_frame.backgrounds[j]))) {
            _drew_background = true;
        }
    }

    if (!_drew_background && _portrait_count <= 0) {
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

/// @func GameStoryTextClampToWidth(text, max_width)
/// Clamps one line of dialogue text to the requested width using an ellipsis.
function GameStoryTextClampToWidth(_text, _max_width) {
    var _ellipsis = "...";

    if (string_width(_text) <= _max_width) {
        return _text;
    }

    while (string_length(_text) > 0 && string_width(_text + _ellipsis) > _max_width) {
        _text = string_delete(_text, string_length(_text), 1);
    }

    while (string_length(_text) > 0 && string_char_at(_text, string_length(_text)) == " ") {
        _text = string_delete(_text, string_length(_text), 1);
    }

    return _text + _ellipsis;
}

/// @func GameStoryTextLinesCreate(text, max_width, max_lines)
/// Wraps story dialogue into a capped number of display lines.
function GameStoryTextLinesCreate(_text, _max_width, _max_lines = 2) {
    var _normalized = string_replace_all(string(_text), "\r", "");
    _normalized = string_replace_all(_normalized, "\n", " ");

    while (string_pos("  ", _normalized) > 0) {
        _normalized = string_replace_all(_normalized, "  ", " ");
    }

    var _words = [];
    var _word_count = 0;
    var _word = "";
    var _length = string_length(_normalized);

    for (var i = 1; i <= _length; i++) {
        var _character = string_char_at(_normalized, i);

        if (_character == " ") {
            if (_word != "") {
                _words[_word_count] = _word;
                _word_count += 1;
                _word = "";
            }
        } else {
            _word += _character;
        }
    }

    if (_word != "") {
        _words[_word_count] = _word;
        _word_count += 1;
    }

    if (_word_count <= 0) {
        return [""];
    }

    var _lines = [];
    var _line_count = 0;
    var _current = "";

    for (var j = 0; j < _word_count; j++) {
        var _candidate = _current;

        if (_candidate == "") {
            _candidate = _words[j];
        } else {
            _candidate += " " + _words[j];
        }

        if (_current == "" || string_width(_candidate) <= _max_width) {
            _current = _candidate;
            continue;
        }

        _lines[_line_count] = GameStoryTextClampToWidth(_current, _max_width);
        _line_count += 1;
        _current = _words[j];

        if (_line_count >= (_max_lines - 1)) {
            for (var k = j + 1; k < _word_count; k++) {
                _current += " " + _words[k];
            }

            _lines[_line_count] = GameStoryTextClampToWidth(_current, _max_width);
            return _lines;
        }
    }

    _lines[_line_count] = GameStoryTextClampToWidth(_current, _max_width);
    return _lines;
}

/// @func GameStoryVisibleLinesCreate(text, max_width, max_lines, visible_characters)
/// Reveals characters against the final wrapped layout so words never jump
/// between lines while the typewriter is running.
function GameStoryVisibleLinesCreate(_text, _max_width, _max_lines,
    _visible_characters) {
    var _full_lines = GameStoryTextLinesCreate(_text, _max_width, _max_lines);
    var _visible_lines = array_create(array_length(_full_lines), "");
    var _remaining = max(0, floor(_visible_characters));

    for (var i = 0; i < array_length(_full_lines); i++) {
        var _line = _full_lines[i];
        var _line_length = string_length(_line);
        var _line_visible = min(_line_length, _remaining);

        if (_line_visible > 0) {
            _visible_lines[i] = string_copy(_line, 1, _line_visible);
        }

        _remaining = max(0, _remaining - _line_length);
        if (_remaining > 0 && i < array_length(_full_lines) - 1) {
            // Wrapped lines replace one source-space character.
            _remaining -= 1;
        }
    }

    return _visible_lines;
}

/// @func GameUiStoryFramePaletteCreate(selected)
/// Returns the shared moon-purple, pearl, and rose palette derived from the story textbox.
function GameUiStoryFramePaletteCreate(_selected = false) {
    var _palette = {
        fill_color: make_color_rgb(28, 12, 48),
        shadow_color: make_color_rgb(8, 5, 20),
        border_color: make_color_rgb(242, 232, 255),
        inner_border_color: make_color_rgb(255, 184, 224),
        ornament_color: make_color_rgb(255, 116, 198),
        vine_color: make_color_rgb(104, 214, 204),
        jewel_color: make_color_rgb(132, 102, 224),
        title_color: make_color_rgb(255, 232, 184),
        text_color: c_white,
        muted_text_color: make_color_rgb(180, 204, 232),
    };

    if (_selected) {
        _palette.fill_color = make_color_rgb(70, 24, 98);
        _palette.inner_border_color = make_color_rgb(255, 220, 150);
        _palette.ornament_color = make_color_rgb(255, 230, 164);
        _palette.vine_color = make_color_rgb(138, 242, 218);
        _palette.jewel_color = make_color_rgb(255, 142, 208);
        _palette.title_color = make_color_rgb(255, 246, 188);
    }

    return _palette;
}

/// @func GameUiDrawOrnamentDiamond(x, y, radius, color, alpha)
/// Draws the small rose-diamond ornament used at story-frame joins.
function GameUiDrawOrnamentDiamond(_x, _y, _radius, _color, _alpha = 1.0) {
    draw_set_alpha(_alpha);
    draw_set_color(_color);
    draw_triangle(_x, _y - _radius, _x + _radius, _y, _x, _y + _radius, false);
    draw_triangle(_x, _y - _radius, _x - _radius, _y, _x, _y + _radius, false);
    draw_set_alpha(1.0);
}

/// @func GameUiDrawPixelFiligreeCorner(x, y, x_sign, y_sign, palette, alpha)
/// Draws one compact vine curl derived from the layered story textbox.
function GameUiDrawPixelFiligreeCorner(_x, _y, _sx, _sy, _palette, _alpha = 1.0) {
    GameUiDrawQuadraticThread(_x, _y,
        _x + (_sx * 8), _y - (_sy * 2),
        _x + (_sx * 16), _y + (_sy * 4),
        _palette.vine_color, _alpha, 10);
    GameUiDrawQuadraticThread(_x, _y,
        _x - (_sx * 2), _y + (_sy * 8),
        _x + (_sx * 4), _y + (_sy * 16),
        _palette.vine_color, _alpha, 10);

    // Rose threads curl back toward their stems instead of terminating in
    // clipped geometric corners.
    GameUiDrawQuadraticThread(_x + (_sx * 7), _y + (_sy * 2),
        _x + (_sx * 15), _y - (_sy * 4),
        _x + (_sx * 12), _y + (_sy * 7),
        _palette.ornament_color, 0.88 * _alpha, 8);
    GameUiDrawQuadraticThread(_x + (_sx * 2), _y + (_sy * 7),
        _x - (_sx * 4), _y + (_sy * 15),
        _x + (_sx * 7), _y + (_sy * 12),
        _palette.inner_border_color, 0.76 * _alpha, 8);
    GameUiDrawOrnamentDiamond(_x + (_sx * 5), _y + (_sy * 5), 2,
        _palette.jewel_color, _alpha);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawQuadraticThread(x0, y0, cx, cy, x1, y1, color, alpha, segments)
/// Draws a one-pixel, integer-snapped thread suitable for 640x360 filigree.
function GameUiDrawQuadraticThread(_x0, _y0, _cx, _cy, _x1, _y1,
    _color, _alpha = 1.0, _segments = 12) {
    var _previous_x = round(_x0);
    var _previous_y = round(_y0);
    _segments = max(2, round(_segments));

    draw_set_alpha(_alpha);
    draw_set_color(_color);
    for (var i = 1; i <= _segments; i++) {
        var _t = i / _segments;
        var _inverse = 1 - _t;
        var _next_x = round((_inverse * _inverse * _x0)
            + (2 * _inverse * _t * _cx) + (_t * _t * _x1));
        var _next_y = round((_inverse * _inverse * _y0)
            + (2 * _inverse * _t * _cy) + (_t * _t * _y1));

        if (_next_x != _previous_x || _next_y != _previous_y) {
            draw_line(_previous_x, _previous_y, _next_x, _next_y);
        }
        _previous_x = _next_x;
        _previous_y = _next_y;
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawFiligreeDivider(left, right, y, palette, alpha, arc, thread_color)
/// Draws an open pearl-and-vine flourish with a rose jewel at its centre.
function GameUiDrawFiligreeDivider(_left, _right, _y, _palette,
    _alpha = 1.0, _arc = -3, _thread_color = -1) {
    var _center = round((_left + _right) * 0.5);
    var _gap = 7;
    var _thread = (_thread_color == -1) ? _palette.border_color : _thread_color;
    var _left_inner = _center - _gap;
    var _right_inner = _center + _gap;
    var _left_span = max(1, _left_inner - _left);
    var _right_span = max(1, _right - _right_inner);
    var _left_wave = round(_left + (_left_span * 0.52));
    var _right_wave = round(_right - (_right_span * 0.52));

    GameUiDrawQuadraticThread(_left, _y,
        _left + (_left_span * 0.24), _y + (_arc * 1.35),
        _left_wave, _y - (_arc * 0.42),
        _thread, _alpha, max(3, _left_span div 15));
    GameUiDrawQuadraticThread(_left_wave, _y - (_arc * 0.42),
        _left + (_left_span * 0.78), _y - (_arc * 1.18),
        _left_inner, _y,
        _thread, _alpha, max(3, _left_span div 15));
    GameUiDrawQuadraticThread(_right_inner, _y,
        _right - (_right_span * 0.78), _y - (_arc * 1.18),
        _right_wave, _y - (_arc * 0.42),
        _thread, _alpha, max(3, _right_span div 15));
    GameUiDrawQuadraticThread(_right_wave, _y - (_arc * 0.42),
        _right - (_right_span * 0.24), _y + (_arc * 1.35),
        _right, _y,
        _thread, _alpha, max(3, _right_span div 15));

    // A second broken thread gives the same airy cyan/pink layering as the
    // original dialogue box without enclosing the panel in a hard rectangle.
    GameUiDrawQuadraticThread(_left + 8, _y - sign(_arc) * 3,
        _left + (_left_span * 0.55), _y - (_arc * 0.55),
        _left_inner - 4, _y - sign(_arc),
        _palette.vine_color, 0.74 * _alpha, max(5, _left_span div 9));
    GameUiDrawQuadraticThread(_right_inner + 4, _y - sign(_arc),
        _right - (_right_span * 0.55), _y - (_arc * 0.55),
        _right - 8, _y - sign(_arc) * 3,
        _palette.vine_color, 0.74 * _alpha, max(5, _right_span div 9));

    GameUiDrawQuadraticThread(_center - 18, _y + sign(_arc) * 2,
        _center - 10, _y + (_arc * 2.2),
        _center - 3, _y + sign(_arc) * 5,
        _palette.ornament_color, 0.82 * _alpha, 7);
    GameUiDrawQuadraticThread(_center + 3, _y + sign(_arc) * 5,
        _center + 10, _y + (_arc * 2.2),
        _center + 18, _y + sign(_arc) * 2,
        _palette.inner_border_color, 0.82 * _alpha, 7);
    GameUiDrawOrnamentDiamond(_center, _y, 3, _palette.jewel_color, _alpha);

    if ((_right - _left) >= 140) {
        GameUiDrawOrnamentDiamond(round(lerp(_left, _center, 0.56)),
            _y + round(_arc * 0.45), 1, _palette.ornament_color, 0.72 * _alpha);
        GameUiDrawOrnamentDiamond(round(lerp(_center, _right, 0.44)),
            _y + round(_arc * 0.45), 1, _palette.ornament_color, 0.72 * _alpha);
    }
}

/// @func GameUiDrawVolumeGauge(left, right, y, ratio, selected)
/// Draws a compact rose-vine slider that sits inside a menu row rather than
/// competing with the row's lower filigree divider.
function GameUiDrawVolumeGauge(_left, _right, _y, _ratio, _selected = false) {
    var _palette = GameUiStoryFramePaletteCreate(_selected);
    var _left_x = round(min(_left, _right));
    var _right_x = round(max(_left, _right));
    var _center_y = round(_y);
    var _value = clamp(_ratio, 0, 1);
    var _thumb_x = round(lerp(_left_x, _right_x, _value));
    var _filled_color = _selected
        ? _palette.title_color : _palette.vine_color;
    var _petal_color = _selected
        ? _palette.ornament_color : _palette.inner_border_color;

    // A dim pair of loose threads defines the whole range. Their opposing
    // curves echo the dialogue-box vines without becoming another hard bar.
    GameUiDrawQuadraticThread(_left_x, _center_y,
        round((_left_x + _right_x) * 0.5), _center_y - 2,
        _right_x, _center_y,
        _palette.jewel_color, 0.42, max(8, (_right_x - _left_x) div 9));
    GameUiDrawQuadraticThread(_left_x, _center_y + 1,
        round((_left_x + _right_x) * 0.5), _center_y + 3,
        _right_x, _center_y + 1,
        _palette.inner_border_color, 0.28,
        max(8, (_right_x - _left_x) div 9));

    // The live portion blooms into brighter interlaced threads.
    if (_thumb_x > _left_x) {
        var _fill_center = round((_left_x + _thumb_x) * 0.5);
        GameUiDrawQuadraticThread(_left_x, _center_y,
            _fill_center, _center_y - 2,
            _thumb_x, _center_y,
            _filled_color, 0.96, max(3, (_thumb_x - _left_x) div 7));
        GameUiDrawQuadraticThread(_left_x, _center_y + 1,
            _fill_center, _center_y + 3,
            _thumb_x, _center_y + 1,
            _petal_color, 0.76, max(3, (_thumb_x - _left_x) div 7));
    }

    // Five restrained petal marks make the adjustment scale legible while
    // remaining decorative at the native 640x360 resolution.
    for (var i = 0; i <= 4; i++) {
        var _tick_x = round(lerp(_left_x, _right_x, i / 4));
        var _tick_active = (i / 4) <= _value;
        draw_set_alpha(_tick_active ? 0.88 : 0.38);
        draw_set_color(_tick_active ? _petal_color : _palette.jewel_color);
        draw_point(_tick_x, _center_y - 2);
        draw_point(_tick_x, _center_y + 3);
    }

    // Curl the stems inward at each end, then use a luminous rose jewel as
    // the thumb so 0% and 100% still have an intentional silhouette.
    GameUiDrawQuadraticThread(_left_x - 4, _center_y + 2,
        _left_x - 1, _center_y - 4,
        _left_x + 3, _center_y,
        _palette.vine_color, 0.72, 5);
    GameUiDrawQuadraticThread(_right_x + 4, _center_y + 2,
        _right_x + 1, _center_y - 4,
        _right_x - 3, _center_y,
        _palette.ornament_color, 0.68, 5);
    GameUiDrawOrnamentDiamond(_thumb_x, _center_y, 3,
        _selected ? _palette.ornament_color : _palette.jewel_color, 1);
    draw_set_color(_palette.border_color);
    draw_point(_thumb_x, _center_y - 1);

    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawPixelHeart(x, y, state, alpha)
/// Draws one 9x8 phase heart: spent, future, or active.
function GameUiDrawPixelHeart(_x, _y, _state, _alpha = 1.0) {
    var _palette = GameUiStoryFramePaletteCreate(_state == 2);
    var _fill = (_state == 0) ? _palette.shadow_color
        : ((_state == 2) ? _palette.title_color : _palette.ornament_color);
    var _outline = (_state == 0) ? _palette.jewel_color : _palette.border_color;
    _x = round(_x);
    _y = round(_y);

    draw_set_alpha((_state == 0 ? 0.42 : 0.94) * _alpha);
    draw_set_color(_outline);
    draw_rectangle(_x + 1, _y, _x + 3, _y + 1, false);
    draw_rectangle(_x + 5, _y, _x + 7, _y + 1, false);
    draw_rectangle(_x, _y + 2, _x + 8, _y + 4, false);
    draw_rectangle(_x + 1, _y + 5, _x + 7, _y + 5, false);
    draw_rectangle(_x + 2, _y + 6, _x + 6, _y + 6, false);
    draw_rectangle(_x + 4, _y + 7, _x + 4, _y + 7, false);

    draw_set_color(_fill);
    draw_rectangle(_x + 2, _y + 1, _x + 2, _y + 2, false);
    draw_rectangle(_x + 6, _y + 1, _x + 6, _y + 2, false);
    draw_rectangle(_x + 1, _y + 3, _x + 7, _y + 4, false);
    draw_rectangle(_x + 2, _y + 5, _x + 6, _y + 5, false);
    draw_rectangle(_x + 3, _y + 6, _x + 5, _y + 6, false);

    if (_state == 2) {
        draw_set_color(c_white);
        draw_point(_x + 2, _y + 2);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawBossPhaseHearts(x, y, phase_index, phase_count, alpha)
/// Wraps phase hearts into compact rows suitable for the redesigned gutter.
function GameUiDrawBossPhaseHearts(_x, _y, _phase_index, _phase_count, _alpha = 1.0) {
    var _states = GameBossPhaseHeartStatesCreate(_phase_index, _phase_count);
    var _per_row = 10;

    for (var i = 0; i < array_length(_states); i++) {
        var _heart_x = _x + ((i mod _per_row) * 12);
        var _heart_y = _y + ((i div _per_row) * 11);
        GameUiDrawPixelHeart(_heart_x, _heart_y, _states[i], _alpha);
    }
}

/// @func GameUiDrawOrnateFrame(x, y, width, height, fill_color, fill_alpha, accent_color, selected, frame_alpha)
/// Draws a scalable open filigree panel derived from spr_textbox's wispy threads.
function GameUiDrawOrnateFrame(_x, _y, _w, _h, _fill_color = -1, _fill_alpha = 0.76, _accent_color = -1, _selected = false, _frame_alpha = 1.0) {
    var _palette = GameUiStoryFramePaletteCreate(_selected);
    var _fill = (_fill_color == -1) ? _palette.fill_color : _fill_color;
    var _outer = (_accent_color == -1) ? _palette.border_color : _accent_color;
    var _left = round(_x);
    var _top = round(_y);
    var _right = round(_x + _w);
    var _bottom = round(_y + _h);
    _frame_alpha = clamp(_frame_alpha, 0, 1);

    // Soft offset shadow and translucent ink-dark fill preserve contrast over
    // art. Compact rows are inset and feathered so their silhouettes do not
    // become a stack of hard purple bricks.
    if (_h < 34) {
        draw_set_alpha(min(0.38, _fill_alpha * 0.54) * _frame_alpha);
        draw_set_color(_palette.shadow_color);
        draw_rectangle(_left + 7, _top + 5, _right - 1, _bottom + 3, false);

        draw_set_alpha(_fill_alpha * _frame_alpha);
        draw_set_color(_fill);
        draw_rectangle(_left + 6, _top + 3, _right - 6, _bottom - 3, false);
        draw_set_alpha(_fill_alpha * 0.42 * _frame_alpha);
        draw_rectangle(_left + 2, _top + 6, _left + 5, _bottom - 6, false);
        draw_rectangle(_right - 5, _top + 6, _right - 2, _bottom - 6, false);
    } else {
        draw_set_alpha(min(0.5, _fill_alpha * 0.7) * _frame_alpha);
        draw_set_color(_palette.shadow_color);
        draw_rectangle(_left + 3, _top + 3, _right + 3, _bottom + 3, false);

        draw_set_alpha(_fill_alpha * _frame_alpha);
        draw_set_color(_fill);
        draw_rectangle(_left, _top, _right, _bottom, false);
    }

    // Open, broken flourishes replace the former doubled rectangles. Small
    // rows deliberately omit side rails so stacked menu entries feel like
    // floating ribbons rather than a spreadsheet.
    if (_w >= 32 && _h < 34) {
        if (_selected) {
            GameUiDrawFiligreeDivider(_left + 12, _right - 12, _top + 2,
                _palette, 0.62 * _frame_alpha, -3, _outer);
        }
        GameUiDrawFiligreeDivider(_left + 4, _right - 4, _bottom - 1,
            _palette, _frame_alpha, 4,
            _selected ? _palette.title_color : _palette.inner_border_color);
    } else if (_w >= 32 && _h >= 34) {
        GameUiDrawFiligreeDivider(_left + 5, _right - 5, _top + 1,
            _palette, _frame_alpha, -3, _outer);
        GameUiDrawFiligreeDivider(_left + 5, _right - 5, _bottom - 1,
            _palette, 0.88 * _frame_alpha, 3, _palette.inner_border_color);
    }

    if (_w >= 42 && _h >= 34) {
        GameUiDrawPixelFiligreeCorner(_left + 3, _top + 3, 1, 1,
            _palette, _frame_alpha);
        GameUiDrawPixelFiligreeCorner(_right - 3, _top + 3, -1, 1,
            _palette, _frame_alpha);
        GameUiDrawPixelFiligreeCorner(_left + 3, _bottom - 3, 1, -1,
            _palette, 0.88 * _frame_alpha);
        GameUiDrawPixelFiligreeCorner(_right - 3, _bottom - 3, -1, -1,
            _palette, 0.88 * _frame_alpha);
    }

    if (_h >= 54) {
        var _center_y = round((_top + _bottom) * 0.5);
        var _side_gap = min(9, max(5, _h div 10));
        var _side_segments = max(5, (_h div 2) div 7);

        GameUiDrawQuadraticThread(_left + 1, _top + 10,
            _left - 2, _center_y - 16,
            _left + 2, _center_y - _side_gap,
            _palette.vine_color, 0.74 * _frame_alpha, _side_segments);
        GameUiDrawQuadraticThread(_left + 2, _center_y + _side_gap,
            _left - 2, _center_y + 16,
            _left + 1, _bottom - 10,
            _palette.ornament_color, 0.70 * _frame_alpha, _side_segments);
        GameUiDrawQuadraticThread(_right - 1, _top + 10,
            _right + 2, _center_y - 16,
            _right - 2, _center_y - _side_gap,
            _palette.inner_border_color, 0.72 * _frame_alpha, _side_segments);
        GameUiDrawQuadraticThread(_right - 2, _center_y + _side_gap,
            _right + 2, _center_y + 16,
            _right - 1, _bottom - 10,
            _palette.vine_color, 0.74 * _frame_alpha, _side_segments);
        GameUiDrawOrnamentDiamond(_left + 1, _center_y, 2,
            _palette.jewel_color, _frame_alpha);
        GameUiDrawOrnamentDiamond(_right - 1, _center_y, 2,
            _palette.jewel_color, _frame_alpha);
    }

    draw_set_alpha(1.0);
    draw_set_color(c_white);
}

/// @func GameStoryDrawBox(frame, visible_characters, reveal_complete)
/// Draws the dialogue textbox sprite and current text content.
function GameStoryDrawBox(_frame, _visible_characters = -1,
    _reveal_complete = true) {
    var _gui_width = display_get_gui_width();
    var _gui_height = display_get_gui_height();
    var _box_top = _gui_height - 130;
    var _text_width = 520;
    var _lines = [];
    var _palette = GameUiStoryFramePaletteCreate(false);

    // The old sprite enclosed the entire dialogue area in a heavy octagonal
    // hull. Keep its rose-and-vine language, but let an open filigree frame
    // breathe around the words instead.
    GameUiDrawOrnateFrame(38, _box_top + 4, _gui_width - 76, 116,
        _palette.fill_color, 0.78, _palette.border_color, false);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_font(fn_dialogue_name);
    GameUiDrawOutlinedText(_frame.name, _gui_width * 0.5, _box_top + 10, _palette.title_color);

    draw_set_font(fn_dialogue_speech);
    if (_visible_characters < 0) {
        _visible_characters = string_length(_frame.text);
    }
    _lines = GameStoryVisibleLinesCreate(_frame.text, _text_width, 2,
        _visible_characters);

    for (var i = 0; i < array_length(_lines); i++) {
        GameUiDrawOutlinedText(_lines[i], _gui_width * 0.5, _box_top + 42 + (i * 22), _palette.text_color);
    }

    // Once the typewriter completes, thpj3's jeweled chevron replaces the
    // former textual input prompt. Its 64x64 source targets 1280x720, so the
    // 640x360 presentation uses an exact 50% nearest-neighbour scale.
    if (_reveal_complete) {
        var _arrow_asset = asset_get_index("spr_text_arrow");
        if (_arrow_asset != -1 && sprite_exists(_arrow_asset)) {
            var _arrow_frame = GameStoryTextArrowFrameGet(current_time,
                sprite_get_number(_arrow_asset));
            draw_set_alpha(1);
            draw_set_color(c_white);
            draw_sprite_ext(_arrow_asset, _arrow_frame,
                _gui_width - 86, _gui_height - 49,
                0.5, 0.5, 0, c_white, 1);
        }
    }
}

/// @func GameStoryDraw(state)
/// Draws the active story frame when dialogue is currently enabled.
function GameStoryDraw(_state) {
    if (!GameStoryRuntimeEnsure() || !global.game_runtime.signals.dialogue || !GameStoryIsActive(_state)) {
        return;
    }

    GameStoryDrawBackground(_state.current_frame);
    GameStoryDrawBox(_state.current_frame, _state.reveal_characters,
        _state.reveal_complete);
}

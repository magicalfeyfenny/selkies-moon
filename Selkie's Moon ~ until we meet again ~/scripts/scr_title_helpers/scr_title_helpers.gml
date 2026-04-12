/// @func GameTitleCharactersCreate()
/// Creates the selectable character roster shown on the title screen.
function GameTitleCharactersCreate() {
    return [
        {
            id: "ship_A",
            name: "Sunrise",
            subtitle: "Selkie's seafaring frame",
            accent_color: make_color_rgb(64, 232, 255),
            logo_color: make_color_rgb(255, 96, 196),
            preview_sprite: "spr_sunrise",
            pilot_name: "Selkie",
            support_name: "Moon",
            description_lines: [
                "A balanced ship built for readable, steady pressure.",
                "Sunrise holds a clean firing lane for first-route play.",
                "Selkie flies it with Moon guiding the tide ahead."
            ]
        }
    ];
}

/// @func GameTitleMainItemsCreate()
/// Creates the main menu entries for the title screen.
function GameTitleMainItemsCreate() {
    return [
        { id: "start_game", label: "Start Game" },
        { id: "options", label: "Options" },
        { id: "scores", label: "Scores" },
        { id: "quit", label: "Quit" }
    ];
}

/// @func GameTitleStateCreate()
/// Creates the persistent UI state for the title menu flow.
function GameTitleStateCreate() {
    return {
        phase: "press_start",
        page: "main",
        flash_timer: 0,
        main_index: 0,
        options_index: 0,
        score_character_index: 0,
        select_character_index: 0,
        characters: GameTitleCharactersCreate(),
        main_items: GameTitleMainItemsCreate()
    };
}

/// @func GameTitleInputSnapshotCreate(up, down, left, right, fire, bomb)
/// Creates a simple input snapshot for stepping the title state.
function GameTitleInputSnapshotCreate(_up = false, _down = false, _left = false, _right = false, _fire = false, _bomb = false) {
    return {
        up: _up,
        down: _down,
        left: _left,
        right: _right,
        fire: _fire,
        bomb: _bomb
    };
}

/// @func GameTitleInputSnapshotFromGlobal()
/// Builds a title-menu input snapshot from the global input state.
function GameTitleInputSnapshotFromGlobal() {
    return GameTitleInputSnapshotCreate(
        GameInputVerbPressed("up"),
        GameInputVerbPressed("down"),
        GameInputVerbPressed("left"),
        GameInputVerbPressed("right"),
        GameInputVerbPressed("fire"),
        GameInputVerbPressed("bomb")
    );
}

/// @func GameTitleWrapIndex(index, delta, count)
/// Wraps a menu index forward or backward within a fixed item count.
function GameTitleWrapIndex(_index, _delta, _count) {
    if (_count <= 0) {
        return 0;
    }

    _index += _delta;

    if (_index < 0) {
        _index = _count - 1;
    } else if (_index >= _count) {
        _index = 0;
    }

    return _index;
}

/// @func GameTitleConfigEntriesCreate()
/// Creates the list of editable settings shown on the options page.
function GameTitleConfigEntriesCreate() {
    return [
        { id: "fullscreen", label: "Fullscreen", value: string(global.game_config.fullscreen) },
        { id: "display_scale", label: "Display Scale", value: string(global.game_config.display_scale) }
    ];
}

/// @func GameTitleCharacterGet(state, index)
/// Returns the character entry at the requested roster index.
function GameTitleCharacterGet(_state, _index) {
    return _state.characters[_index];
}

/// @func GameTitleScoresGet(character_id)
/// Returns the stored score table for the requested character.
function GameTitleScoresGet(_character_id) {
    if (!struct_exists(global.game_save.high_score, _character_id)) {
        return [0,0,0,0,0,0,0,0,0,0];
    }

    return global.game_save.high_score[$ _character_id];
}

/// @func GameTitleConfigValueWrap(value, delta, min, max)
/// Wraps an option value between its minimum and maximum bounds.
function GameTitleConfigValueWrap(_value, _delta, _min, _max) {
    _value += _delta;

    if (_value < _min) {
        _value = _max;
    } else if (_value > _max) {
        _value = _min;
    }

    return _value;
}

/// @func GameTitleConfigEntryAdjust(entry_id, delta)
/// Applies a left or right adjustment to one options-menu entry.
function GameTitleConfigEntryAdjust(_entry_id, _delta) {
    var _did_change = false;

    switch (_entry_id) {
        case "fullscreen":
            global.game_config.fullscreen = !global.game_config.fullscreen;
            _did_change = true;
            break;

        case "display_scale":
            var _next_scale = GameTitleConfigValueWrap(global.game_config.display_scale, _delta, 1, 6);
            if (_next_scale != global.game_config.display_scale) {
                global.game_config.display_scale = _next_scale;
                _did_change = true;
            }
            break;
    }

    if (_did_change) {
        SaveGameConfig();
        GameConfigApply();
    }

    return _did_change;
}

/// @func GameTitleStateStep(state, input)
/// Advances the title state machine by one input snapshot.
function GameTitleStateStep(_state, _input) {
    var _result = {
        action: "none",
        room_name: "",
        character_id: "",
        character_index: -1
    };

    _state.flash_timer += 1;

    if (_state.phase == "press_start") {
        if (_input.fire) {
            _state.phase = "menu";
            _state.page = "main";
            _state.main_index = 0;
        }

        return _result;
    }

    switch (_state.page) {
        case "main":
            if (_input.up) {
                _state.main_index = GameTitleWrapIndex(_state.main_index, -1, array_length(_state.main_items));
            }

            if (_input.down) {
                _state.main_index = GameTitleWrapIndex(_state.main_index, 1, array_length(_state.main_items));
            }

            if (_input.fire) {
                var _item = _state.main_items[_state.main_index];

                switch (_item.id) {
                    case "start_game":
                        _state.page = "character_select";
                        break;

                    case "options":
                        _state.page = "options";
                        _state.options_index = 0;
                        break;

                    case "scores":
                        _state.page = "scores";
                        break;

                    case "quit":
                        _result.action = "quit";
                        break;
                }
            }
            break;

        case "scores":
            if (_input.left) {
                _state.score_character_index = GameTitleWrapIndex(_state.score_character_index, -1, array_length(_state.characters));
            }

            if (_input.right) {
                _state.score_character_index = GameTitleWrapIndex(_state.score_character_index, 1, array_length(_state.characters));
            }

            if (_input.bomb) {
                _state.page = "main";
            }
            break;

        case "options":
            var _entries = GameTitleConfigEntriesCreate();
            var _entry_count = array_length(_entries);

            if (_input.up) {
                _state.options_index = GameTitleWrapIndex(_state.options_index, -1, _entry_count);
            }

            if (_input.down) {
                _state.options_index = GameTitleWrapIndex(_state.options_index, 1, _entry_count);
            }

            if (_entry_count > 0) {
                if (_input.left) {
                    GameTitleConfigEntryAdjust(_entries[_state.options_index].id, -1);
                }

                if (_input.right) {
                    GameTitleConfigEntryAdjust(_entries[_state.options_index].id, 1);
                }
            }

            if (_input.bomb) {
                _state.page = "main";
            }
            break;

        case "character_select":
            if (_input.left) {
                _state.select_character_index = GameTitleWrapIndex(_state.select_character_index, -1, array_length(_state.characters));
            }

            if (_input.right) {
                _state.select_character_index = GameTitleWrapIndex(_state.select_character_index, 1, array_length(_state.characters));
            }

            if (_input.bomb) {
                _state.page = "main";
            } else if (_input.fire) {
                var _character = GameTitleCharacterGet(_state, _state.select_character_index);

                _result.action = "goto_room";
                _result.room_name = "rm_opening";
                _result.character_id = _character.id;
                _result.character_index = _state.select_character_index;
            }
            break;
    }

    return _result;
}

/// @func GameTitleDrawFrame(x, y, width, height, border_color, fill_color)
/// Draws a framed UI panel for title menu widgets.
function GameTitleDrawFrame(_x, _y, _w, _h, _border_color, _fill_color) {
    draw_set_alpha(1.0);
    draw_set_color(_fill_color);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_border_color);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
}

/// @func GameTitleDrawSpriteFit(sprite_name, center_x, center_y, max_width, max_height, scale_cap)
/// Draws a sprite centered inside a bounding box while preserving aspect ratio.
function GameTitleDrawSpriteFit(_sprite_name, _center_x, _center_y, _max_width, _max_height, _scale_cap = 1) {
    var _asset_index = asset_get_index(_sprite_name);

    if (_asset_index == -1 || !sprite_exists(_asset_index)) {
        return false;
    }

    var _scale = min(_max_width / sprite_get_width(_asset_index), _max_height / sprite_get_height(_asset_index));
    _scale = min(_scale, _scale_cap);

    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_sprite_ext(_asset_index, 0, _center_x, _center_y, _scale, _scale, 0, c_white, 1.0);
    return true;
}

/// @func GameTitleDrawBackground()
/// Draws the title screen background layers.
function GameTitleDrawBackground() {
    draw_clear_alpha(make_color_rgb(8, 12, 28), 1.0);

    draw_set_alpha(1.0);
    draw_set_color(make_color_rgb(12, 28, 64));
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);

    draw_set_color(make_color_rgb(28, 12, 54));
    draw_rectangle(0, 220, display_get_gui_width(), display_get_gui_height(), false);

    draw_set_color(make_color_rgb(0, 160, 192));
    draw_rectangle(32, 24, 608, 28, false);
}

/// @func GameTitleDrawLogo(state)
/// Draws the game title card and subtitle banner.
function GameTitleDrawLogo(_state) {
    if (asset_get_index("spr_logo") != -1 && sprite_exists(asset_get_index("spr_logo"))) {
        if (_state.phase == "press_start") {
            GameTitleDrawSpriteFit("spr_logo", 320, 90, 156, 156, 1);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_set_font(fn_subtitle);
            draw_text(320, 176, "~ until we meet again ~");
        } else {
            GameTitleDrawSpriteFit("spr_logo", 82, 56, 84, 84, 1);
        }

        return;
    }

    var _character = GameTitleCharacterGet(_state, 0);

    GameTitleDrawFrame(120, 56, 400, 88, c_white, _character.logo_color);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_set_font(fn_title);
    draw_text(320, 90, "Selkie's Moon");
    draw_set_font(fn_subtitle);
    draw_text(320, 116, "~ until we meet again ~");
}

/// @func GameTitleDrawPrompt(state)
/// Draws the press-start prompt and input hint text.
function GameTitleDrawPrompt(_state) {
    if (((_state.flash_timer div 20) mod 2) == 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_set_font(fn_menu);
        draw_text(320, 260, "Press [FIRE] to start");
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(140, 210, 255));
    draw_set_font(fn_menu);
    draw_text(320, 310, "Arrow Keys move  Z fire  X back/bomb");
}

/// @func GameTitleDrawMenuItem(x, y, label, selected)
/// Draws one selectable main-menu item with highlight styling.
function GameTitleDrawMenuItem(_x, _y, _label, _selected) {
    var _fill_color = make_color_rgb(20, 24, 40);
    var _border_color = make_color_rgb(96, 124, 180);
    var _text_color = c_white;

    if (_selected) {
        _fill_color = make_color_rgb(36, 74, 124);
        _border_color = make_color_rgb(144, 236, 255);
        _text_color = make_color_rgb(255, 255, 160);
    }

    GameTitleDrawFrame(_x, _y, 220, 28, _border_color, _fill_color);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_color(_text_color);
    draw_set_font(fn_menu);
    draw_text(_x + 12, _y + 15, _label);
}

/// @func GameTitleDrawMainMenu(state)
/// Draws the main title menu page.
function GameTitleDrawMainMenu(_state) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    draw_text(320, 44, "Main Menu");

    var _item_count = array_length(_state.main_items);
    for (var i = 0; i < _item_count; i++) {
        GameTitleDrawMenuItem(210, 112 + (i * 36), _state.main_items[i].label, i == _state.main_index);
    }
}

/// @func GameTitleDrawOptionsPage(state)
/// Draws the options page and highlights the active setting row.
function GameTitleDrawOptionsPage(_state) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    draw_text(320, 44, "Options");

    var _entries = GameTitleConfigEntriesCreate();
    var _entry_count = array_length(_entries);

    for (var i = 0; i < _entry_count; i++) {
        var _entry = _entries[i];
        var _fill_color = make_color_rgb(20, 24, 40);
        var _border_color = make_color_rgb(96, 124, 180);
        var _text_color = c_white;
        var _value_color = c_white;

        if (i == _state.options_index) {
            _fill_color = make_color_rgb(36, 74, 124);
            _border_color = make_color_rgb(144, 236, 255);
            _text_color = make_color_rgb(255, 255, 160);
            _value_color = make_color_rgb(255, 255, 160);
        }

        GameTitleDrawFrame(136, 96 + (i * 36), 368, 28, _border_color, _fill_color);
        draw_set_halign(fa_left);
        draw_set_color(_text_color);
        draw_set_font(fn_menu);
        draw_text(148, 111 + (i * 36), _entry.label);
        draw_set_halign(fa_right);
        draw_set_color(_value_color);
        draw_text(492, 111 + (i * 36), _entry.value);
    }

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(160, 188, 220));
    draw_set_font(fn_menu);
    draw_text(320, 322, "Up/Down select  Left/Right change  X back");
}

/// @func GameTitleDrawScoresPage(state)
/// Draws the score table for the selected character.
function GameTitleDrawScoresPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.score_character_index);
    var _scores = GameTitleScoresGet(_character.id);
    var _score_count = array_length(_scores);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    draw_text(320, 36, "Scores");
    draw_set_color(_character.accent_color);
    draw_text(320, 60, _character.name);

    for (var i = 0; i < _score_count; i++) {
        GameTitleDrawFrame(180, 92 + (i * 22), 280, 18, make_color_rgb(88, 108, 156), make_color_rgb(20, 24, 40));

        draw_set_halign(fa_left);
        draw_set_color(c_white);
        draw_set_font(fn_menu);
        draw_text(194, 102 + (i * 22), string(i + 1) + ".");

        draw_set_halign(fa_right);
        draw_text(446, 102 + (i * 22), string(_scores[i]));
    }

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(160, 188, 220));
    draw_set_font(fn_menu);
    draw_text(320, 322, "Press [LEFT]/[RIGHT] to change ship, [BOMB] to go back");
}

/// @func GameTitleDrawCharacterSelectPage(state)
/// Draws the character select page for the active ship.
function GameTitleDrawCharacterSelectPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.select_character_index);
    var _line_count = array_length(_character.description_lines);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    draw_text(320, 36, "Character Select");
    draw_set_color(_character.accent_color);
    draw_text(320, 62, _character.name);
    draw_set_color(make_color_rgb(180, 204, 224));
    draw_text(320, 84, _character.subtitle);

    GameTitleDrawFrame(96, 112, 124, 140, c_white, make_color_rgb(24, 34, 66));
    if (!GameTitleDrawSpriteFit(_character.preview_sprite, 158, 176, 92, 92, 2)) {
        draw_set_color(_character.accent_color);
        draw_rectangle(118, 138, 198, 226, false);
    }
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    draw_text(158, 242, _character.name);

    GameTitleDrawFrame(252, 112, 292, 140, c_white, make_color_rgb(18, 22, 34));
    draw_set_halign(fa_left);
    draw_set_color(make_color_rgb(180, 204, 224));
    draw_set_font(fn_menu);
    draw_text(266, 130, "Pilot: " + _character.pilot_name);
    draw_text(266, 152, "Support: " + _character.support_name);

    draw_set_color(c_white);
    draw_set_font(fn_menu);
    for (var i = 0; i < _line_count; i++) {
        draw_text(266, 186 + (i * 18), _character.description_lines[i]);
    }

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(160, 188, 220));
    draw_set_font(fn_menu);
    draw_text(320, 322, "Press [FIRE] to begin, [LEFT]/[RIGHT] to switch, [BOMB] to go back");
}

/// @func GameTitleDraw(state)
/// Draws the current title screen page for the active state.
function GameTitleDraw(_state) {
    GameTitleDrawBackground();
    GameTitleDrawLogo(_state);

    if (_state.phase == "press_start") {
        GameTitleDrawPrompt(_state);
        return;
    }

    switch (_state.page) {
        case "main":
            GameTitleDrawMainMenu(_state);
            break;

        case "options":
            GameTitleDrawOptionsPage(_state);
            break;

        case "scores":
            GameTitleDrawScoresPage(_state);
            break;

        case "character_select":
            GameTitleDrawCharacterSelectPage(_state);
            break;
    }
}

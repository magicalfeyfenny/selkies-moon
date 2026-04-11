function GameTitleCharactersCreate() {
    return [
        {
            id: "ship_A",
            name: "Ship A",
            subtitle: "Moonlit starter frame",
            accent_color: make_color_rgb(64, 232, 255),
            logo_color: make_color_rgb(255, 96, 196),
            description_lines: [
                "A balanced first ship for the opening route.",
                "Focused fire stays readable and predictable.",
                "Bomb stock is generous while the roster is tiny."
            ]
        }
    ];
}

function GameTitleMainItemsCreate() {
    return [
        { id: "start_game", label: "Start Game" },
        { id: "options", label: "Options" },
        { id: "scores", label: "Scores" },
        { id: "quit", label: "Quit" }
    ];
}

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

function GameTitleConfigEntriesCreate() {
    return [
        { id: "fullscreen", label: "Fullscreen", value: string(global.game_config.fullscreen) },
        { id: "display_scale", label: "Display Scale", value: string(global.game_config.display_scale) }
    ];
}

function GameTitleCharacterGet(_state, _index) {
    return _state.characters[_index];
}

function GameTitleScoresGet(_character_id) {
    if (!struct_exists(global.game_save.high_score, _character_id)) {
        return [0,0,0,0,0,0,0,0,0,0];
    }

    return global.game_save.high_score[$ _character_id];
}

function GameTitleConfigValueWrap(_value, _delta, _min, _max) {
    _value += _delta;

    if (_value < _min) {
        _value = _max;
    } else if (_value > _max) {
        _value = _min;
    }

    return _value;
}

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

function GameTitleDrawFrame(_x, _y, _w, _h, _border_color, _fill_color) {
    draw_set_alpha(1.0);
    draw_set_color(_fill_color);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_border_color);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
}

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

function GameTitleDrawLogo(_state) {
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
    draw_set_color(_character.accent_color);
    draw_rectangle(118, 138, 198, 226, false);
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    draw_text(158, 242, "Portrait");

    GameTitleDrawFrame(252, 112, 292, 140, c_white, make_color_rgb(18, 22, 34));
    draw_set_color(_character.accent_color);
    draw_rectangle(314, 170, 330, 194, false);
    draw_triangle(322, 146, 306, 190, 338, 190, false);
    draw_set_color(make_color_rgb(255, 224, 96));
    draw_circle(370, 178, 4, false);
    draw_circle(392, 178, 4, false);
    draw_circle(414, 178, 4, false);

    draw_set_halign(fa_left);
    draw_set_color(c_white);
    draw_set_font(fn_menu);
    for (var i = 0; i < _line_count; i++) {
        draw_text(266, 214 + (i * 18), _character.description_lines[i]);
    }

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(160, 188, 220));
    draw_set_font(fn_menu);
    draw_text(320, 322, "Press [FIRE] to begin, [LEFT]/[RIGHT] to switch, [BOMB] to go back");
}

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

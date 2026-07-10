/// @func GameTitleCharactersCreate()
/// Creates the selectable character roster shown on the title screen.
function GameTitleCharactersCreate() {
    return [
        {
            id: SHIP_SUNRISE,
            name: "Sunset",
            subtitle: "Moon carries twilight back toward the sea",
            accent_color: make_color_rgb(64, 232, 255),
            logo_color: make_color_rgb(255, 96, 196),
            preview_sprite: "spr_sunrise",
            pilot_name: "Moon",
            support_name: "",
            description_lines: [
                "A balanced craft built for",
                "Moon's long pursuit through",
                "the violet tide. Wide volleys",
                "turn blue heat into orange",
                "as her resolve rises"
            ]
        },
        {
            id: SHIP_SELKIE,
            name: "Sunrise",
            subtitle: "Selkie returns in the first light",
            accent_color: make_color_rgb(255, 174, 234),
            logo_color: make_color_rgb(255, 198, 112),
            preview_sprite: "spr_sunset",
            pilot_name: "Selkie",
            support_name: "Moon",
            description_lines: [
                "A heavier ship with crescent",
                "spread shots and narrow focus",
                "lances. Her focused sweep is",
                "wide, close, and made for",
                "breaking dense bullet curtains"
            ]
        }
    ];
}

/// @func GameTitleGalleryItemsCreate()
/// Creates the CG gallery entries shown on the title screen.
function GameTitleGalleryItemsCreate() {
    return [
        { name: "Core of the Moon", sprite: "spr_dialogue_bg_core", caption: "The place where the promise began." },
        { name: "Flowering Memory", sprite: "spr_dialogue_bg_flower", caption: "A bloom that refuses to fade." },
        { name: "Moon", sprite: "spr_moon_portrait", caption: "Pilot of Sunset." },
        { name: "Selkie", sprite: "spr_selkie_portrait", caption: "Pilot of Sunrise." },
        { name: "Sunset", sprite: "spr_sunrise", caption: "Moon's balanced shot type." },
        { name: "Sunrise", sprite: "spr_sunset", caption: "Selkie's crescent shot type." },
    ];
}

/// @func GameTitleMusicItemsCreate()
/// Creates the music-room track list.
function GameTitleMusicItemsCreate() {
    return [
        { name: "Moonlit Launch", subtitle: "title / opening", sound_id: snd_music_title },
        { name: "Tideglass", subtitle: "stage 1", sound_id: snd_music_stage_01 },
        { name: "Lanterns Underwater", subtitle: "stage 2", sound_id: snd_music_stage_02 },
        { name: "Saltwind Corridor", subtitle: "stage 3", sound_id: snd_music_stage_03 },
        { name: "Kelp Chase", subtitle: "stage 4", sound_id: snd_music_stage_04 },
        { name: "Moonwake", subtitle: "stage 5", sound_id: snd_music_stage_05 },
        { name: "Glassreef", subtitle: "stage 6", sound_id: snd_music_stage_06 },
        { name: "Starfall Break", subtitle: "stage 7", sound_id: snd_music_stage_07 },
        { name: "Bloodtide", subtitle: "stage 8", sound_id: snd_music_stage_08 },
        { name: "Crescent Gate", subtitle: "stage 9", sound_id: snd_music_stage_09 },
        { name: "Selkie Eclipse", subtitle: "stage 10", sound_id: snd_music_stage_10 },
        { name: "Soft Bloom", subtitle: "ending", sound_id: snd_music_ending },
        { name: "Moonlit Return", subtitle: "credits", sound_id: snd_music_credits },
    ];
}

/// @func GameTitleMainItemsCreate()
/// Creates the main menu entries for the title screen.
function GameTitleMainItemsCreate() {
    return [
        { id: "start_game", label: "Start Game" },
        { id: "scores", label: "Scores" },
        { id: "cg_gallery", label: "CG Gallery" },
        { id: "music_room", label: "Music Room" },
        { id: "options", label: "Options" },
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
        gallery_index: 0,
        music_index: 0,
        music_preview_id: -1,
        characters: GameTitleCharactersCreate(),
        gallery_items: GameTitleGalleryItemsCreate(),
        music_items: GameTitleMusicItemsCreate(),
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

/// @func GameTitleMusicPreviewStop(state)
/// Stops the currently playing music-room preview.
function GameTitleMusicPreviewStop(_state) {
    if (_state.music_preview_id != -1) {
        audio_stop_sound(_state.music_preview_id);
        _state.music_preview_id = -1;
    }

    GameStageMusicSync();
}

/// @func GameTitleMusicPreviewToggle(state)
/// Toggles the selected music-room preview track.
function GameTitleMusicPreviewToggle(_state) {
    if (_state.music_preview_id != -1) {
        GameTitleMusicPreviewStop(_state);
        return false;
    }

    if (GameShouldQuitAfterTests()) {
        return false;
    }

    GameAudioStateEnsure();
    if (global.game_audio.current_music_id != -1) {
        audio_stop_sound(global.game_audio.current_music_id);
        global.game_audio.current_music_id = -1;
        global.game_audio.stage_music_playing = false;
    }

    var _track = _state.music_items[_state.music_index];
    _state.music_preview_id = audio_play_sound(_track.sound_id, 0, true);
    return true;
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

                    case "cg_gallery":
                        _state.page = "cg_gallery";
                        _state.gallery_index = 0;
                        break;

                    case "music_room":
                        _state.page = "music_room";
                        _state.music_index = 0;
                        break;

                    case "quit":
                        GameTitleMusicPreviewStop(_state);
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

        case "cg_gallery":
            if (_input.left) {
                _state.gallery_index = GameTitleWrapIndex(_state.gallery_index, -1, array_length(_state.gallery_items));
            }

            if (_input.right) {
                _state.gallery_index = GameTitleWrapIndex(_state.gallery_index, 1, array_length(_state.gallery_items));
            }

            if (_input.bomb) {
                _state.page = "main";
            }
            break;

        case "music_room":
            if (_input.up) {
                _state.music_index = GameTitleWrapIndex(_state.music_index, -1, array_length(_state.music_items));
            }

            if (_input.down) {
                _state.music_index = GameTitleWrapIndex(_state.music_index, 1, array_length(_state.music_items));
            }

            if (_input.fire) {
                GameTitleMusicPreviewToggle(_state);
            }

            if (_input.bomb) {
                GameTitleMusicPreviewStop(_state);
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

                GameTitleMusicPreviewStop(_state);
                _result.action = "goto_room";
                _result.room_name = "rm_opening";
                _result.character_id = _character.id;
                _result.character_index = _state.select_character_index;
            }
            break;
    }

    return _result;
}

/// @func GameTitleDrawFrame(x, y, width, height, border_color, fill_color, fill_alpha)
/// Draws a framed UI panel for title menu widgets.
function GameTitleDrawFrame(_x, _y, _w, _h, _border_color, _fill_color, _fill_alpha = 1.0) {
    draw_set_alpha(_fill_alpha);
    draw_set_color(_fill_color);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1.0);
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

/// @func GameTitleDrawBackground(state)
/// Draws the title screen background layers.
function GameTitleDrawBackground(_state) {
    var _core_asset = asset_get_index("spr_dialogue_bg_core");

    draw_clear_alpha(make_color_rgb(8, 12, 28), 1.0);

    if (_core_asset != -1 && sprite_exists(_core_asset)) {
        draw_set_alpha(1.0);
        draw_set_color(c_white);
        draw_sprite_stretched(_core_asset, 0, 0, 0, display_get_gui_width(), display_get_gui_height());

        draw_set_alpha(0.5);
        draw_set_color(c_black);
        draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
        draw_set_alpha(1.0);
        return;
    }

    draw_set_alpha(1.0);
    draw_set_color(make_color_rgb(12, 28, 64));
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);

    draw_set_color(make_color_rgb(28, 12, 54));
    draw_rectangle(0, 220, display_get_gui_width(), display_get_gui_height(), false);

    draw_set_color(make_color_rgb(0, 160, 192));
    draw_rectangle(32, 24, 608, 28, false);
}

/// @func GameTitlePressStartSubtitleAnimCreate(timer)
/// Returns the animated press-start subtitle position and fade state.
function GameTitlePressStartSubtitleAnimCreate(_timer) {
    var _duration = max(1, game_get_speed(gamespeed_fps));
    var _frame = clamp(_timer, 0, _duration);

    return {
        x: 300 - _frame,
        y: 160,
        alpha: _frame / _duration
    };
}

/// @func GameUiDrawOutlinedText(text, x, y, text_color, outline_color, alpha)
/// Draws one line of UI text with a four-direction one-pixel outline.
function GameUiDrawOutlinedText(_text, _x, _y, _text_color = c_white, _outline_color = c_black, _alpha = 1.0) {
    draw_set_alpha(_alpha);
    draw_set_color(_outline_color);
    draw_text(_x - 1, _y, _text);
    draw_text(_x + 1, _y, _text);
    draw_text(_x, _y - 1, _text);
    draw_text(_x, _y + 1, _text);

    draw_set_color(_text_color);
    draw_text(_x, _y, _text);
    draw_set_alpha(1.0);
}

/// @func GameTitlePanelStyleCreate(selected)
/// Returns the shared purple panel styling used across title-menu pages.
function GameTitlePanelStyleCreate(_selected = false) {
    var _style = {
        fill_color: make_color_rgb(58, 18, 92),
        border_color: make_color_rgb(96, 124, 180),
        text_color: c_white,
        fill_alpha: 0.75,
    };

    if (_selected) {
        _style.fill_color = make_color_rgb(78, 28, 116);
        _style.border_color = make_color_rgb(144, 236, 255);
        _style.text_color = make_color_rgb(255, 255, 160);
    }

    return _style;
}

/// @func GameTitleDrawLogo(state)
/// Draws the game title card and subtitle banner.
function GameTitleDrawLogo(_state) {
    var _logo_asset = asset_get_index("spr_logo");

    if (_logo_asset != -1 && sprite_exists(_logo_asset)) {
        if (_state.phase == "press_start") {
            var _subtitle_anim = GameTitlePressStartSubtitleAnimCreate(_state.flash_timer);

            draw_set_alpha(1.0);
            draw_set_color(c_white);
            draw_sprite(_logo_asset, 0, 200, 160);

            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_font(fn_subtitle);
            GameUiDrawOutlinedText("~ until we meet again ~", _subtitle_anim.x, _subtitle_anim.y, c_white, c_black, _subtitle_anim.alpha);
        } else {
            GameTitleDrawSpriteFit("spr_logo", 82, 56, 84, 84, 1);
        }

        return;
    }

    var _character = GameTitleCharacterGet(_state, 0);

    GameTitleDrawFrame(120, 56, 400, 88, c_white, _character.logo_color);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_title);
    GameUiDrawOutlinedText("Selkie's Moon", 320, 90, c_white);
    draw_set_font(fn_subtitle);
    GameUiDrawOutlinedText("~ until we meet again ~", 320, 116, c_white);
}

/// @func GameTitleDrawPrompt(state)
/// Draws the press-start prompt and input hint text.
function GameTitleDrawPrompt(_state) {
    if (((_state.flash_timer div 20) mod 2) == 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_font(fn_menu);
        GameUiDrawOutlinedText("Press [FIRE] to start", 470, 190, c_white);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Arrow Keys move  Z fire  X back/bomb", 470, 232, make_color_rgb(140, 210, 255));
}

/// @func GameTitleDrawMenuItem(x, y, label, selected)
/// Draws one selectable main-menu item with highlight styling.
function GameTitleDrawMenuItem(_x, _y, _label, _selected) {
    var _style = GameTitlePanelStyleCreate(_selected);

    GameTitleDrawFrame(_x, _y, 220, 28, _style.border_color, _style.fill_color, _style.fill_alpha);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText(_label, _x + 12, _y + 15, _style.text_color);
}

/// @func GameTitleDrawMainMenu(state)
/// Draws the main title menu page.
function GameTitleDrawMainMenu(_state) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Main Menu", 320, 44, c_white);

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
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Options", 320, 44, c_white);

    var _entries = GameTitleConfigEntriesCreate();
    var _entry_count = array_length(_entries);

    for (var i = 0; i < _entry_count; i++) {
        var _entry = _entries[i];
        var _style = GameTitlePanelStyleCreate(i == _state.options_index);

        GameTitleDrawFrame(136, 96 + (i * 36), 368, 28, _style.border_color, _style.fill_color, _style.fill_alpha);
        draw_set_halign(fa_left);
        draw_set_font(fn_menu);
        GameUiDrawOutlinedText(_entry.label, 148, 111 + (i * 36), _style.text_color);
        draw_set_halign(fa_right);
        GameUiDrawOutlinedText(_entry.value, 492, 111 + (i * 36), _style.text_color);
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Up/Down select  Left/Right change  X back", 320, 322, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawScoresPage(state)
/// Draws the score table for the selected character.
function GameTitleDrawScoresPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.score_character_index);
    var _scores = GameTitleScoresGet(_character.id);
    var _score_count = array_length(_scores);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Scores", 320, 36, c_white);
    GameUiDrawOutlinedText(_character.name, 320, 60, _character.accent_color);

    for (var i = 0; i < _score_count; i++) {
        var _style = GameTitlePanelStyleCreate(false);

        GameTitleDrawFrame(180, 92 + (i * 22), 280, 18, _style.border_color, _style.fill_color, _style.fill_alpha);

        draw_set_halign(fa_left);
        draw_set_font(fn_menu);
        GameUiDrawOutlinedText(string(i + 1) + ".", 194, 102 + (i * 22), c_white);

        draw_set_halign(fa_right);
        GameUiDrawOutlinedText(string(_scores[i]), 446, 102 + (i * 22), c_white);
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Press [LEFT]/[RIGHT] to change ship, [BOMB] to go back", 320, 322, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawGalleryPage(state)
/// Draws the CG gallery page for existing story and ship art.
function GameTitleDrawGalleryPage(_state) {
    var _item = _state.gallery_items[_state.gallery_index];
    var _style = GameTitlePanelStyleCreate(false);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("CG Gallery", 320, 36, c_white);
    GameUiDrawOutlinedText(string(_state.gallery_index + 1) + "/" + string(array_length(_state.gallery_items)), 320, 58, make_color_rgb(160, 188, 220));

    GameTitleDrawFrame(94, 78, 452, 202, _style.border_color, _style.fill_color, 0.48);
    GameTitleDrawSpriteFit(_item.sprite, 320, 174, 410, 172, 3);

    GameUiDrawOutlinedText(_item.name, 320, 296, c_white);
    GameUiDrawOutlinedText(_item.caption, 320, 316, make_color_rgb(180, 204, 224));
    GameUiDrawOutlinedText("[LEFT]/[RIGHT] browse  [BOMB] back", 320, 342, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawMusicRoomPage(state)
/// Draws the music room page and playback state.
function GameTitleDrawMusicRoomPage(_state) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Music Room", 320, 42, c_white);

    var _track_count = array_length(_state.music_items);
    for (var i = 0; i < _track_count; i++) {
        var _track = _state.music_items[i];
        var _style = GameTitlePanelStyleCreate(i == _state.music_index);

        GameTitleDrawFrame(136, 104 + (i * 44), 368, 34, _style.border_color, _style.fill_color, _style.fill_alpha);
        draw_set_halign(fa_left);
        GameUiDrawOutlinedText(_track.name, 150, 116 + (i * 44), _style.text_color);
        GameUiDrawOutlinedText(_track.subtitle, 150, 130 + (i * 44), make_color_rgb(180, 204, 224));
    }

    draw_set_halign(fa_center);
    var _status = (_state.music_preview_id != -1) ? "Playing" : "Stopped";
    GameUiDrawOutlinedText(_status, 320, 236, (_state.music_preview_id != -1) ? c_yellow : make_color_rgb(180, 204, 224));
    GameUiDrawOutlinedText("[FIRE] play/stop  [BOMB] back", 320, 322, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawCharacterSelectPage(state)
/// Draws the character select page for the active ship.
function GameTitleDrawCharacterSelectPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.select_character_index);
    var _line_count = array_length(_character.description_lines);
    var _description_start_y = 186;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Character Select", 320, 36, c_white);
    GameUiDrawOutlinedText(_character.name, 320, 62, _character.accent_color);
    GameUiDrawOutlinedText(_character.subtitle, 320, 84, make_color_rgb(180, 204, 224));

    var _panel_style = GameTitlePanelStyleCreate(false);

    GameTitleDrawFrame(96, 112, 124, 140, _panel_style.border_color, _panel_style.fill_color, _panel_style.fill_alpha);
    if (!GameTitleDrawSpriteFit(_character.preview_sprite, 158, 176, 92, 92, 2)) {
        draw_set_color(_character.accent_color);
        draw_rectangle(118, 138, 198, 226, false);
    }
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText(_character.name, 158, 242, c_white);

    GameTitleDrawFrame(252, 112, 292, 140, _panel_style.border_color, _panel_style.fill_color, _panel_style.fill_alpha);
    draw_set_halign(fa_left);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Pilot: " + _character.pilot_name, 266, 130, make_color_rgb(180, 204, 224));

    if (_character.support_name != "") {
        GameUiDrawOutlinedText("Support: " + _character.support_name, 266, 152, make_color_rgb(180, 204, 224));
    } else {
        _description_start_y = 162;
    }

    draw_set_font(fn_menu);
    for (var i = 0; i < _line_count; i++) {
        GameUiDrawOutlinedText(_character.description_lines[i], 266, _description_start_y + (i * 18), c_white);
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Press [FIRE] to begin, [LEFT]/[RIGHT] to switch, [BOMB] to go back", 320, 322, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDraw(state)
/// Draws the current title screen page for the active state.
function GameTitleDraw(_state) {
    GameTitleDrawBackground(_state);
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

        case "cg_gallery":
            GameTitleDrawGalleryPage(_state);
            break;

        case "music_room":
            GameTitleDrawMusicRoomPage(_state);
            break;

        case "character_select":
            GameTitleDrawCharacterSelectPage(_state);
            break;
    }
}

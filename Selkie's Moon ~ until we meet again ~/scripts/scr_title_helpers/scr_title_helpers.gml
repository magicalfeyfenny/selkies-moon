// Title-page state, menu actions, character metadata, and title rendering.

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
        { id: "practice", label: "Practice" },
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
        music_preview_index: -1,
        practice_index: 0,
        practice_config: GamePracticeConfigCreateDefault(),
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
        GameInputVerbPressed("fire") || GameInputVerbPressed("pause"),
        GameInputVerbPressed("bomb")
    );
}

/// @func GameTitleConfigEntriesCreate()
/// Creates the list of editable settings shown on the options page.
function GameTitleConfigEntriesCreate() {
    return [
        { id: "fullscreen", label: "Fullscreen", value: global.game_config.fullscreen ? "On" : "Off" },
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

/// @func GameTitlePracticeEntriesCreate(state)
/// Creates the complete set of editable rows shown on Practice Select.
function GameTitlePracticeEntriesCreate(_state) {
    _state.practice_config = GamePracticeConfigNormalize(_state.practice_config);
    var _practice = _state.practice_config;
    var _ship = GameTitleCharacterGet(_state, _practice.ship_index);

    return [
        { id: "ship", label: "Ship", value: _ship.name },
        { id: "stage", label: "Stage", value: string(_practice.stage) + " / " + string(STAGE_COUNT) },
        { id: "segment", label: "Segment", value: GamePracticeSegmentNameGet(_practice.segment) },
        { id: "power", label: "Power", value: string(_practice.power) + " / " + string(PLAYER_POWER_MAX) },
        { id: "rank", label: "Rank", value: string(_practice.rank) + "%" },
        { id: "dynamic_rank", label: "Dynamic Rank", value: _practice.dynamic_rank ? "On" : "Off" },
        { id: "lives", label: "Lives", value: string(_practice.lives) },
        { id: "bombs", label: "Bombs", value: string(_practice.bombs) },
        { id: "meter", label: "Meter", value: string(_practice.meter) + " / " + string(METER_MAX) },
        { id: "start", label: "Start", value: "" },
        { id: "back", label: "Back", value: "" },
    ];
}

/// @func GameTitlePracticeEntryAdjust(state, entry_id, delta)
/// Applies one wrapped left/right change to a Practice Select value.
function GameTitlePracticeEntryAdjust(_state, _entry_id, _delta) {
    if (_delta == 0) {
        return false;
    }

    var _practice = GamePracticeConfigNormalize(_state.practice_config);
    var _direction = sign(_delta);

    switch (_entry_id) {
        case "ship":
            _practice.ship_index = GameTitleConfigValueWrap(_practice.ship_index, _direction, 0,
                array_length(_state.characters) - 1);
            _practice.ship_id = GameTitleCharacterGet(_state, _practice.ship_index).id;
            break;

        case "stage":
            _practice.stage = GameTitleConfigValueWrap(_practice.stage, _direction, 1, STAGE_COUNT);
            break;

        case "segment":
            var _segments = [PRACTICE_SEGMENT_FULL, PRACTICE_SEGMENT_WAVES, PRACTICE_SEGMENT_BOSS];
            var _segment_index = 0;

            for (var i = 0; i < array_length(_segments); i++) {
                if (_segments[i] == _practice.segment) {
                    _segment_index = i;
                    break;
                }
            }

            _segment_index = GameMenuIndexWrap(_segment_index, _direction, array_length(_segments));
            _practice.segment = _segments[_segment_index];
            break;

        case "power":
            _practice.power = GameTitleConfigValueWrap(_practice.power, _direction, 0, PLAYER_POWER_MAX);
            break;

        case "rank":
            _practice.rank = GameTitleConfigValueWrap(_practice.rank, _direction * 5, RANK_MIN, RANK_MAX);
            break;

        case "dynamic_rank":
            _practice.dynamic_rank = !_practice.dynamic_rank;
            break;

        case "lives":
            _practice.lives = GameTitleConfigValueWrap(_practice.lives, _direction, 1, PLAYER_LIFE_MAX);
            break;

        case "bombs":
            _practice.bombs = GameTitleConfigValueWrap(_practice.bombs, _direction, 0, PLAYER_BOMB_MAX);
            break;

        case "meter":
            _practice.meter = GameTitleConfigValueWrap(_practice.meter, _direction * 100, 0, METER_MAX);
            break;

        default:
            return false;
    }

    _state.practice_config = GamePracticeConfigNormalize(_practice);
    return true;
}

/// @func GameTitlePracticeHelpGet(entry_id)
/// Returns one concise explanation for the selected Practice Select row.
function GameTitlePracticeHelpGet(_entry_id) {
    switch (_entry_id) {
        case "segment": return "Full stage, enemy waves, or the boss alone";
        case "rank": return "Starting bullet pressure and enemy tempo";
        case "dynamic_rank": return "Let survival and mistakes adjust rank during play";
        case "meter": return "Start with up to a full berserk meter";
        case "start": return "Launch this setup directly into gameplay";
        case "back": return "Return to the main menu";
    }

    return "Left / Right or D-pad adjusts this value";
}

/// @func GameTitleMusicPreviewStop(state)
/// Stops the currently playing music-room preview.
function GameTitleMusicPreviewStop(_state) {
    GameMusicRoomPreviewStop(true);
    _state.music_preview_id = -1;
    _state.music_preview_index = -1;
}

/// @func GameTitleMusicPreviewPlaySelected(state)
/// Starts or cleanly switches to the currently selected music-room row.
function GameTitleMusicPreviewPlaySelected(_state) {
    var _track = _state.music_items[_state.music_index];
    var _preview_id = GameMusicRoomPreviewStart(_track.sound_id);

    _state.music_preview_id = _preview_id;
    _state.music_preview_index = (_preview_id != -1) ? _state.music_index : -1;
    return _preview_id != -1;
}

/// @func GameTitleMusicPreviewToggle(state)
/// Toggles the selected music-room preview track.
function GameTitleMusicPreviewToggle(_state) {
    if (GameMusicRoomPreviewIsActive() && _state.music_preview_index == _state.music_index) {
        GameTitleMusicPreviewStop(_state);
        return false;
    }

    return GameTitleMusicPreviewPlaySelected(_state);
}

/// @func GameTitleStateStep(state, input)
/// Advances the title state machine by one input snapshot.
function GameTitleStateStep(_state, _input) {
    var _result = {
        action: "none",
        room_name: "",
        character_id: "",
        character_index: -1,
        practice_config: GamePracticeConfigCreateDefault(),
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
            _state.main_index = GameMenuIndexStep(
                _state.main_index, _input.up, _input.down, array_length(_state.main_items));

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

                    case "practice":
                        _state.page = "practice";
                        _state.practice_index = 0;
                        _state.practice_config = GamePracticeConfigNormalize(_state.practice_config);
                        break;

                    case "quit":
                        GameTitleMusicPreviewStop(_state);
                        _result.action = "quit";
                        break;
                }
            }
            break;

        case "scores":
            _state.score_character_index = GameMenuIndexStep(
                _state.score_character_index, _input.left, _input.right, array_length(_state.characters));

            if (_input.bomb) {
                _state.page = "main";
            }
            break;

        case "cg_gallery":
            _state.gallery_index = GameMenuIndexStep(
                _state.gallery_index, _input.left, _input.right, array_length(_state.gallery_items));

            if (_input.bomb) {
                _state.page = "main";
            }
            break;

        case "music_room":
            var _music_was_playing = GameMusicRoomPreviewIsActive();
            var _music_previous_index = _state.music_index;

            _state.music_index = GameMenuIndexStep(
                _state.music_index, _input.up, _input.down, array_length(_state.music_items));

            // Browsing while a preview is active immediately follows the cursor,
            // so the highlighted row and audible track can never disagree.
            if (_music_was_playing && _state.music_index != _music_previous_index) {
                GameTitleMusicPreviewPlaySelected(_state);
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

            _state.options_index = GameMenuIndexStep(
                _state.options_index, _input.up, _input.down, _entry_count);

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

        case "practice":
            var _practice_entries = GameTitlePracticeEntriesCreate(_state);
            var _practice_count = array_length(_practice_entries);

            _state.practice_index = GameMenuIndexStep(
                _state.practice_index, _input.up, _input.down, _practice_count);

            var _practice_entry = _practice_entries[_state.practice_index];
            if (_input.left) {
                GameTitlePracticeEntryAdjust(_state, _practice_entry.id, -1);
            }

            if (_input.right) {
                GameTitlePracticeEntryAdjust(_state, _practice_entry.id, 1);
            }

            if (_input.bomb) {
                _state.page = "main";
            } else if (_input.fire) {
                switch (_practice_entry.id) {
                    case "start":
                        GameTitleMusicPreviewStop(_state);
                        _state.practice_config = GamePracticeConfigNormalize(_state.practice_config);
                        _result.action = "goto_practice";
                        _result.room_name = "rm_game";
                        _result.practice_config = _state.practice_config;
                        break;

                    case "back":
                        _state.page = "main";
                        break;

                    case "dynamic_rank":
                        GameTitlePracticeEntryAdjust(_state, _practice_entry.id, 1);
                        break;
                }
            }
            break;

        case "character_select":
            _state.select_character_index = GameMenuIndexStep(
                _state.select_character_index, _input.left, _input.right, array_length(_state.characters));

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
    GameUiDrawOrnateFrame(_x, _y, _w, _h, _fill_color, _fill_alpha, _border_color, false);
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
    var _draw_width = sprite_get_width(_asset_index) * _scale;
    var _draw_height = sprite_get_height(_asset_index) * _scale;

    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_sprite_stretched(_asset_index, 0, _center_x - (_draw_width * 0.5), _center_y - (_draw_height * 0.5), _draw_width, _draw_height);
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
        x: 258 - (_frame * 0.3),
        y: 236,
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

/// @func GameUiDrawOutlinedTextExt(text, x, y, sep, width, text_color, outline_color, alpha)
/// Draws wrapped UI text with the same outline style as single-line text.
function GameUiDrawOutlinedTextExt(_text, _x, _y, _sep, _width, _text_color = c_white, _outline_color = c_black, _alpha = 1.0) {
    draw_set_alpha(_alpha);
    draw_set_color(_outline_color);
    draw_text_ext(_x - 1, _y, _text, _sep, _width);
    draw_text_ext(_x + 1, _y, _text, _sep, _width);
    draw_text_ext(_x, _y - 1, _text, _sep, _width);
    draw_text_ext(_x, _y + 1, _text, _sep, _width);

    draw_set_color(_text_color);
    draw_text_ext(_x, _y, _text, _sep, _width);
    draw_set_alpha(1.0);
}

/// @func GameTitleDrawPageHeading(text, y, color)
/// Draws title-page headings in the same ornate face as cutscene nameplates.
function GameTitleDrawPageHeading(_text, _y = 42, _color = c_white) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_title);
    GameUiDrawOutlinedText(_text, 320, _y, _color);
}

/// @func GameTitlePanelStyleCreate(selected)
/// Returns the shared purple panel styling used across title-menu pages.
function GameTitlePanelStyleCreate(_selected = false) {
    var _story_palette = GameUiStoryFramePaletteCreate(_selected);
    var _style = {
        fill_color: make_color_rgb(58, 18, 92),
        border_color: _story_palette.border_color,
        text_color: c_white,
        fill_alpha: 0.75,
    };

    if (_selected) {
        _style.fill_color = make_color_rgb(78, 28, 116);
        _style.border_color = _story_palette.inner_border_color;
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

            GameTitleDrawSpriteFit("spr_logo", 220, 134, 300, 210, 1);

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
    var _prompt_alpha = (((_state.flash_timer div 20) mod 2) == 0) ? 1.0 : 0.42;
    var _palette = GameUiStoryFramePaletteCreate(false);

    GameUiDrawOrnateFrame(242, 162, 382, 82, _palette.fill_color, 0.58, _palette.border_color, false);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Press Z / A / Start", 433, 188, c_white, c_black, _prompt_alpha);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Arrows/D-pad move  Z/A shot  C/X focus  X/B bomb", 433, 222, make_color_rgb(140, 210, 255));
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
    GameTitleDrawPageHeading("Main Menu", 44);

    var _item_count = array_length(_state.main_items);
    for (var i = 0; i < _item_count; i++) {
        GameTitleDrawMenuItem(210, 78 + (i * 34), _state.main_items[i].label, i == _state.main_index);
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Arrows / D-pad select   Z / A / Start confirm", 320, 330, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawOptionsPage(state)
/// Draws the options page and highlights the active setting row.
function GameTitleDrawOptionsPage(_state) {
    GameTitleDrawPageHeading("Options", 44);

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
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Arrows / D-pad adjust   X / B back", 320, 322, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawPracticePage(state)
/// Draws the scrolling Practice Select setup and its live variable values.
function GameTitleDrawPracticePage(_state) {
    var _entries = GameTitlePracticeEntriesCreate(_state);
    var _entry_count = array_length(_entries);
    var _visible_count = min(7, _entry_count);
    var _first_entry = clamp(_state.practice_index - 3, 0, max(0, _entry_count - _visible_count));

    GameTitleDrawPageHeading("Practice Select", 34);
    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(string(_state.practice_index + 1) + " / " + string(_entry_count),
        320, 54, make_color_rgb(160, 188, 220));

    for (var i = 0; i < _visible_count; i++) {
        var _entry_index = _first_entry + i;
        var _entry = _entries[_entry_index];
        var _style = GameTitlePanelStyleCreate(_entry_index == _state.practice_index);
        var _row_top = 68 + (i * 30);

        GameTitleDrawFrame(128, _row_top, 384, 26, _style.border_color, _style.fill_color, _style.fill_alpha);
        draw_set_font(fn_menu);

        if (_entry.id == "start" || _entry.id == "back") {
            draw_set_halign(fa_center);
            GameUiDrawOutlinedText(_entry.label, 320, _row_top + 14, _style.text_color);
        } else {
            draw_set_halign(fa_left);
            GameUiDrawOutlinedText(_entry.label, 142, _row_top + 14, _style.text_color);
            draw_set_halign(fa_right);
            GameUiDrawOutlinedText(_entry.value, 498, _row_top + 14, _style.text_color);
        }
    }

    var _selected_entry = _entries[_state.practice_index];
    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(GameTitlePracticeHelpGet(_selected_entry.id), 320, 294, make_color_rgb(190, 214, 234));
    GameUiDrawOutlinedText("D-pad adjust   Z / A choose   X / B back", 320, 326, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawScoresPage(state)
/// Draws the score table for the selected character.
function GameTitleDrawScoresPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.score_character_index);
    var _scores = GameTitleScoresGet(_character.id);
    var _score_count = array_length(_scores);

    GameTitleDrawPageHeading("Scores", 36);
    draw_set_font(fn_dialogue_name);
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
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Left/Right or D-pad change ship   X / B back", 320, 326, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawGalleryPage(state)
/// Draws the CG gallery page for existing story and ship art.
function GameTitleDrawGalleryPage(_state) {
    var _item = _state.gallery_items[_state.gallery_index];
    var _style = GameTitlePanelStyleCreate(false);

    GameTitleDrawPageHeading("CG Gallery", 36);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText(string(_state.gallery_index + 1) + "/" + string(array_length(_state.gallery_items)), 320, 58, make_color_rgb(160, 188, 220));

    GameTitleDrawFrame(128, 76, 384, 182, _style.border_color, _style.fill_color, 0.52);
    GameTitleDrawSpriteFit(_item.sprite, 320, 164, 340, 138, 1.0);

    GameUiDrawOutlinedText(_item.name, 320, 282, c_white);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(_item.caption, 320, 304, make_color_rgb(180, 204, 224));
    GameUiDrawOutlinedText("Left/Right or D-pad browse   X / B back", 320, 332, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawMusicRoomPage(state)
/// Draws the music room page and playback state.
function GameTitleDrawMusicRoomPage(_state) {
    GameTitleDrawPageHeading("Music Room", 42);

    var _track_count = array_length(_state.music_items);
    var _visible_count = min(5, _track_count);
    var _first_track = clamp(_state.music_index - 2, 0, max(0, _track_count - _visible_count));

    for (var i = 0; i < _visible_count; i++) {
        var _track_index = _first_track + i;
        var _track = _state.music_items[_track_index];
        var _style = GameTitlePanelStyleCreate(_track_index == _state.music_index);
        var _is_playing = GameMusicRoomPreviewIsActive() && _state.music_preview_index == _track_index;

        var _row_top = 70 + (i * 42);
        GameTitleDrawFrame(128, _row_top, 384, 38, _style.border_color, _style.fill_color, _style.fill_alpha);
        draw_set_halign(fa_left);
        draw_set_font(fn_menu);
        GameUiDrawOutlinedText(_track.name, 142, _row_top + 12, _style.text_color);
        draw_set_font(fn_dialogue_speech);
        GameUiDrawOutlinedText(_track.subtitle, 142, _row_top + 29, make_color_rgb(180, 204, 224));

        if (_is_playing) {
            draw_set_halign(fa_right);
            GameUiDrawOutlinedText("PLAY", 498, _row_top + 12, make_color_rgb(255, 230, 164));
        }
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    var _preview_active = GameMusicRoomPreviewIsActive() && _state.music_preview_index >= 0;
    var _status = "Stopped";

    if (_preview_active) {
        _status = "Playing: " + _state.music_items[_state.music_preview_index].name;
    }

    GameUiDrawOutlinedText(_status, 320, 296, _preview_active ? c_yellow : make_color_rgb(180, 204, 224));
    GameUiDrawOutlinedText(_preview_active ? "D-pad switch   Z / A stop   X / B back" : "D-pad select   Z / A play   X / B back",
        320, 326, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawCharacterSelectPage(state)
/// Draws the character select page for the active ship.
function GameTitleDrawCharacterSelectPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.select_character_index);
    var _line_count = array_length(_character.description_lines);
    var _description_start_y = 178;

    GameTitleDrawPageHeading("Character Select", 36);
    draw_set_font(fn_dialogue_name);
    GameUiDrawOutlinedText(_character.name, 320, 62, _character.accent_color);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(_character.subtitle, 320, 84, make_color_rgb(180, 204, 224));

    var _panel_style = GameTitlePanelStyleCreate(false);

    GameTitleDrawFrame(96, 112, 124, 140, _panel_style.border_color, _panel_style.fill_color, _panel_style.fill_alpha);
    if (!GameTitleDrawSpriteFit(_character.preview_sprite, 158, 176, 92, 92, 2)) {
        draw_set_color(_character.accent_color);
        draw_rectangle(118, 138, 198, 226, false);
    }
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText(_character.name, 158, 242, c_white);

    GameTitleDrawFrame(252, 108, 292, 154, _panel_style.border_color, _panel_style.fill_color, _panel_style.fill_alpha);
    draw_set_halign(fa_left);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Pilot: " + _character.pilot_name, 266, 126, make_color_rgb(180, 204, 224));

    if (_character.support_name != "") {
        GameUiDrawOutlinedText("Support: " + _character.support_name, 266, 148, make_color_rgb(180, 204, 224));
    } else {
        _description_start_y = 162;
    }

    draw_set_font(fn_dialogue_speech);
    for (var i = 0; i < _line_count; i++) {
        GameUiDrawOutlinedText(_character.description_lines[i], 266, _description_start_y + (i * 15), c_white);
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Z / A begin   D-pad switch   X / B back", 320, 326, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDraw(state)
/// Draws the current title screen page for the active state.
function GameTitleDraw(_state) {
    GameTitleDrawBackground(_state);

    if (_state.phase != "press_start") {
        var _palette = GameUiStoryFramePaletteCreate(false);
        GameUiDrawOrnateFrame(18, 18, 604, 326, _palette.fill_color, 0.30, _palette.border_color, false);
    }

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

        case "practice":
            GameTitleDrawPracticePage(_state);
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

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
            speed_label: "Balanced / 4 px",
            normal_label: "Rose fan volleys",
            focus_label: "Tight sunset lance",
            sword_label: "Hold Fire: thorn whip",
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
            speed_label: "Balanced / 4 px",
            normal_label: "Wide crescent spread",
            focus_label: "Narrow sunrise lance",
            sword_label: "Hold Fire: chakram",
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
        { name: "A Promise Across the Horizon", subtitle: "title / Two Voices Beyond the Horizon", sound_id: snd_music_title },
        { name: "The Forge at Dusk", subtitle: "stage 1 / Shalmii / Anvil Oath", sound_id: snd_music_stage_shalmii },
        { name: "Iron Vow beneath the Ember Moon", subtitle: "boss / Shalmii / Anvil Oath", sound_id: snd_music_boss_shalmii },
        { name: "Ribbon over Saltwind", subtitle: "stage 2 / Aster / Saltwind Ribbon", sound_id: snd_music_stage_aster },
        { name: "Tidebound Lace in Revolt", subtitle: "boss / Aster / Saltwind Ribbon", sound_id: snd_music_boss_aster },
        { name: "A Covenant in Four Suits", subtitle: "stage 3 / Mira & Aisha medley", sound_id: snd_music_stage_mira_aisha },
        { name: "Wish and Suit, Entwined", subtitle: "dual boss / Mira & Aisha medley", sound_id: snd_music_boss_mira_aisha },
        { name: "Orrery of the Bloodstar", subtitle: "stage 4 / Caelia / Bloodstar Orrery", sound_id: snd_music_stage_caelia },
        { name: "Red Orbit of the Unforgiving Star", subtitle: "boss / Caelia / Bloodstar Orrery", sound_id: snd_music_boss_caelia },
        { name: "Violets beneath Moon's Sunset", subtitle: "stage 5 / Moon route / two voices", sound_id: snd_music_stage_moon },
        { name: "Rose-Eternity at the Edge of Morning", subtitle: "final boss / Moon / two voices", sound_id: snd_music_boss_moon },
        { name: "Violets upon Selkie's Sunrise", subtitle: "stage 5 / Selkie route / two voices", sound_id: snd_music_stage_selkie },
        { name: "Chakram Apotheosis before Daybreak", subtitle: "final boss / Selkie / two voices", sound_id: snd_music_boss_selkie },
        { name: "Where Morning Finds the Moon", subtitle: "ending / two voices", sound_id: snd_music_ending },
        { name: "Until We Meet Again", subtitle: "credits / two voices", sound_id: snd_music_credits },
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
        controls_index: 0,
        remap_listening: false,
        remap_wait_release: false,
        remap_device: "keyboard",
        remap_verb: "",
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

/// @func GameTitleConfigEntriesCreate(include_controls)
/// Creates the list of editable settings shown on the options page.
function GameTitleConfigEntriesCreate(_include_controls = true) {
    var _entries = [
        { id: "fullscreen", label: "Fullscreen", value: global.game_config.fullscreen ? "On" : "Off" },
        { id: "display_scale", label: "Display Scale", value: string(global.game_config.display_scale) },
        { id: "master_volume", label: "Master Volume", value: string(global.game_config.master_volume) + "%", meter_ratio: global.game_config.master_volume / 100 },
        { id: "music_volume", label: "Music Volume", value: string(global.game_config.music_volume) + "%", meter_ratio: global.game_config.music_volume / 100 },
        { id: "sfx_volume", label: "SFX Volume", value: string(global.game_config.sfx_volume) + "%", meter_ratio: global.game_config.sfx_volume / 100 },
    ];

    if (_include_controls) {
        array_push(_entries,
            { id: "controls_keyboard", label: "Keyboard Controls", value: "Configure", submenu: true },
            { id: "controls_gamepad", label: "Gamepad Controls", value: "Configure", submenu: true });
    }

    return _entries;
}

/// @func GameTitleControlEntriesCreate(device)
/// Builds the device-specific action rows plus reset and return commands.
function GameTitleControlEntriesCreate(_device) {
    var _labels = ["Move Up", "Move Down", "Move Left", "Move Right",
        "Fire / Charge", "Autofire", "Focus", "Bomb", "Pause"];
    var _verbs = GameInputVerbNamesCreate();
    var _entries = [];

    for (var i = 0; i < array_length(_verbs); i++) {
        array_push(_entries, {
            id: _verbs[i],
            label: _labels[i],
            value: GameInputBindingLabel(_device, _verbs[i]),
        });
    }

    array_push(_entries,
        { id: "reset", label: "Restore Defaults", value: "" },
        { id: "back", label: "Back", value: "" });
    return _entries;
}

/// @func GameTitleRemapBegin(state, device, verb)
function GameTitleRemapBegin(_state, _device, _verb) {
    _state.remap_device = _device;
    _state.remap_verb = _verb;
    _state.remap_listening = true;
    _state.remap_wait_release = true;
    return true;
}

/// @func GameTitleRemapCommit(state, code)
/// Applies one captured binding and persists the independent device map.
function GameTitleRemapCommit(_state, _code) {
    if (!_state.remap_listening
        || !GameInputBindingAssign(_state.remap_device, _state.remap_verb, _code)) {
        return false;
    }

    _state.remap_listening = false;
    _state.remap_wait_release = false;
    _state.remap_verb = "";
    SaveGameConfig();
    GameSoundPlay(snd_powerup_collect);
    return true;
}

/// @func GameTitleRemapCancel(state)
function GameTitleRemapCancel(_state) {
    if (!_state.remap_listening) return false;
    _state.remap_listening = false;
    _state.remap_wait_release = false;
    _state.remap_verb = "";
    return true;
}

/// @func GameTitleRemapCaptureUpdate(state)
/// Captures the next raw key/button after the menu-confirm input is released.
function GameTitleRemapCaptureUpdate(_state) {
    if (!_state.remap_listening) return false;

    if (_state.remap_device == "keyboard") {
        if (_state.remap_wait_release) {
            if (keyboard_check(vk_anykey) != true) _state.remap_wait_release = false;
            return false;
        }

        if (keyboard_check_pressed(vk_backspace) == true) {
            return GameTitleRemapCancel(_state);
        }
        if (keyboard_check_pressed(vk_anykey) == true
            && GameInputKeyboardCodeSupported(keyboard_lastkey)) {
            return GameTitleRemapCommit(_state, keyboard_lastkey);
        }
        return false;
    }

    if (!variable_global_exists("game_input")) return false;
    var _slot = GameInputGamepadSlotRefresh(global.game_input);
    if (_slot < 0) return false;

    var _codes = GameInputGamepadCodesCreate();
    var _any_down = false;
    for (var i = 0; i < array_length(_codes); i++) {
        if (gamepad_button_check(_slot, _codes[i]) == true) {
            _any_down = true;
            break;
        }
    }

    if (_state.remap_wait_release) {
        if (!_any_down) _state.remap_wait_release = false;
        return false;
    }

    if (gamepad_button_check_pressed(_slot, gp_select) == true) {
        return GameTitleRemapCancel(_state);
    }
    for (var i = 0; i < array_length(_codes); i++) {
        var _code = _codes[i];
        if (_code != gp_select && gamepad_button_check_pressed(_slot, _code) == true) {
            return GameTitleRemapCommit(_state, _code);
        }
    }
    return false;
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

        case "master_volume":
        case "music_volume":
        case "sfx_volume":
            var _volume = global.game_config[$ _entry_id];
            var _next_volume = clamp(_volume + (_delta * 5), 0, 100);
            if (_next_volume != _volume) {
                global.game_config[$ _entry_id] = _next_volume;
                _did_change = true;
            }
            break;
    }

    if (_did_change) {
        SaveGameConfig();
        GameConfigApply();

        if (_entry_id == "master_volume" || _entry_id == "sfx_volume") {
            GameSoundPlay(snd_powerup_collect);
        }
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
        { id: "segment", label: "Segment", value: GamePracticeSegmentNameForStageGet(_practice.segment, _practice.stage) },
        { id: "power", label: "Power", value: string(_practice.power) + " / " + string(PLAYER_POWER_MAX) },
        { id: "rank", label: "Rank", value: string(_practice.rank) + "%" },
        { id: "dynamic_rank", label: "Dynamic Rank", value: _practice.dynamic_rank ? "On" : "Off" },
        { id: "lives", label: "Lives", value: string(_practice.lives) },
        { id: "bombs", label: "Bombs", value: string(_practice.bombs) },
        { id: "meter", label: "Berserk Meter", value: string(_practice.meter) + " / " + string(METER_MAX) },
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
        case "segment": return "Full stage, waves, or its boss/finale pattern gauntlet";
        case "rank": return "Starting bullet pressure and enemy tempo";
        case "dynamic_rank": return "Let survival and mistakes adjust rank during play";
        case "meter": return "Start with up to a full berserk meter";
        case "start": return "Launch this setup directly into gameplay";
        case "back": return "Return to the main menu";
    }

    return "Left / Right, A / D, or D-pad adjusts this value";
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

    // Raw capture owns input until it receives a new key or button. This keeps
    // ordinary menu navigation from moving beneath the listening prompt.
    if (_state.remap_listening) {
        return _result;
    }

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

            if (_entry_count > 0 && !struct_exists(_entries[_state.options_index], "submenu")) {
                if (_input.left) {
                    GameTitleConfigEntryAdjust(_entries[_state.options_index].id, -1);
                }

                if (_input.right) {
                    GameTitleConfigEntryAdjust(_entries[_state.options_index].id, 1);
                }
            }

            if (_input.fire && struct_exists(_entries[_state.options_index], "submenu")) {
                _state.remap_device = (_entries[_state.options_index].id == "controls_gamepad")
                    ? "gamepad" : "keyboard";
                _state.controls_index = 0;
                _state.page = "controls_" + _state.remap_device;
            } else if (_input.bomb) {
                _state.page = "main";
            }
            break;

        case "controls_keyboard":
        case "controls_gamepad":
            var _device = (_state.page == "controls_gamepad") ? "gamepad" : "keyboard";
            var _control_entries = GameTitleControlEntriesCreate(_device);
            var _control_count = array_length(_control_entries);
            _state.controls_index = GameMenuIndexStep(_state.controls_index,
                _input.up, _input.down, _control_count);

            if (_input.bomb) {
                _state.page = "options";
            } else if (_input.fire) {
                var _control = _control_entries[_state.controls_index];
                if (_control.id == "reset") {
                    GameInputBindingsResetDevice(_device);
                    SaveGameConfig();
                    GameSoundPlay(snd_powerup_collect);
                } else if (_control.id == "back") {
                    _state.page = "options";
                } else {
                    GameTitleRemapBegin(_state, _device, _control.id);
                }
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
function GameTitleDrawFrame(_x, _y, _w, _h, _border_color, _fill_color,
    _fill_alpha = 1.0, _selected = false) {
    GameUiDrawOrnateFrame(_x, _y, _w, _h, _fill_color, _fill_alpha,
        _border_color, _selected);
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
        GameTitleDrawSilhouetteDecorators(_state);
        return;
    }

    draw_set_alpha(1.0);
    draw_set_color(make_color_rgb(12, 28, 64));
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);

    draw_set_color(make_color_rgb(28, 12, 54));
    draw_rectangle(0, 220, display_get_gui_width(), display_get_gui_height(), false);

    draw_set_color(make_color_rgb(0, 160, 192));
    draw_rectangle(32, 24, 608, 28, false);
    GameTitleDrawSilhouetteDecorators(_state);
}

/// @func GameTitleDrawSilhouetteDecorators(state)
/// Washes all seven heroines across menu backgrounds as subtle cameos.
function GameTitleDrawSilhouetteDecorators(_state) {
    var _silhouettes = [
        "spr_silhouette_moon", "spr_silhouette_selkie", "spr_silhouette_mira",
        "spr_silhouette_shalmii", "spr_silhouette_aisha", "spr_silhouette_aster",
        "spr_silhouette_caelia"
    ];
    var _count = array_length(_silhouettes);
    // These are decorators, but they still need to read as the seven heroines
    // rather than disappearing into the dark title painting.
    var _pulse = 0.30 + (0.04 * dsin(_state.flash_timer * 1.5));

    for (var i = 0; i < _count; i++) {
        var _asset = asset_get_index(_silhouettes[i]);
        if (_asset == -1 || !sprite_exists(_asset)) {
            continue;
        }

        var _scale = min(0.19, 96 / max(1, sprite_get_height(_asset)));
        var _x = 38 + (i * 94);
        var _y = 302 + (dsin((_state.flash_timer * 1.2) + (i * 33)) * 3);
        draw_sprite_ext(_asset, 0, _x, _y, _scale, _scale, 0,
            (i mod 2 == 0) ? make_color_rgb(176, 112, 224) : make_color_rgb(92, 190, 220),
            _pulse);
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
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
        fill_alpha: 0.56,
    };

    if (_selected) {
        _style.fill_color = make_color_rgb(78, 28, 116);
        _style.border_color = _story_palette.inner_border_color;
        _style.text_color = make_color_rgb(255, 255, 160);
        _style.fill_alpha = 0.72;
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
function GameTitlePressPromptTextGet(_gamepad_connected = undefined) {
    if (_gamepad_connected == undefined) {
        _gamepad_connected = variable_global_exists("game_input")
            && global.game_input.gamepad_connected;
    }

    return "Press " + GameInputBindingLabel(
        _gamepad_connected ? "gamepad" : "keyboard",
        _gamepad_connected ? "pause" : "fire");
}

/// @func GameTitleDrawPrompt(state)
/// Draws one device-aware press prompt without a controls legend.
function GameTitleDrawPrompt(_state) {
    var _prompt_alpha = (((_state.flash_timer div 20) mod 2) == 0) ? 1.0 : 0.42;
    var _palette = GameUiStoryFramePaletteCreate(false);

    // The title art should breathe. Input details belong in character select
    // and pause help, not in an instruction panel beside the logo.
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText(GameTitlePressPromptTextGet(), 470, 108,
        c_white, c_black, _prompt_alpha);
    GameUiDrawFiligreeDivider(392, 548, 132, _palette, 0.82, -4,
        _palette.border_color);
}

/// @func GameTitleDrawMenuItem(x, y, label, selected)
/// Draws one selectable main-menu item with highlight styling.
function GameTitleDrawMenuItem(_x, _y, _label, _selected) {
    var _style = GameTitlePanelStyleCreate(_selected);

    GameTitleDrawFrame(_x, _y, 220, 28, _style.border_color,
        _style.fill_color, _style.fill_alpha, _selected);
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
    GameUiDrawOutlinedText("Move to select   " + GameInputActiveBindingLabel("fire") + " confirms",
        320, 330, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawOptionsPage(state)
/// Draws the options page and highlights the active setting row.
function GameTitleDrawOptionsPage(_state) {
    GameTitleDrawPageHeading("Options", 44);

    var _entries = GameTitleConfigEntriesCreate();
    var _entry_count = array_length(_entries);
    var _visible_count = min(7, _entry_count);
    var _first_entry = clamp(_state.options_index - 3, 0,
        max(0, _entry_count - _visible_count));
    var _palette = GameUiStoryFramePaletteCreate(false);

    for (var i = 0; i < _visible_count; i++) {
        var _entry_index = _first_entry + i;
        var _entry = _entries[_entry_index];
        var _selected = _entry_index == _state.options_index;
        var _style = GameTitlePanelStyleCreate(_selected);
        var _row_top = 66 + (i * 34);

        GameTitleDrawFrame(136, _row_top, 368, 28,
            _style.border_color, _style.fill_color, _style.fill_alpha,
            _selected);
        draw_set_halign(fa_left);
        draw_set_font(fn_menu);
        GameUiDrawOutlinedText(_entry.label, 148, _row_top + 15, _style.text_color);
        draw_set_halign(fa_right);
        GameUiDrawOutlinedText(_entry.value, 492, _row_top + 15, _style.text_color);

        if (struct_exists(_entry, "meter_ratio")) {
            GameUiDrawVolumeGauge(292, 440, _row_top + 14,
                _entry.meter_ratio, _selected);
        }
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Left / Right adjust   Confirm opens controls   Bomb returns",
        320, 322, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawControlsPage(state, device)
/// Draws a scrolling, device-specific binding editor.
function GameTitleDrawControlsPage(_state, _device) {
    var _entries = GameTitleControlEntriesCreate(_device);
    var _entry_count = array_length(_entries);
    var _visible_count = min(7, _entry_count);
    var _first_entry = clamp(_state.controls_index - 3, 0,
        max(0, _entry_count - _visible_count));
    var _heading = (_device == "gamepad") ? "Gamepad Controls" : "Keyboard Controls";
    var _gamepad_ready = _device != "gamepad"
        || (variable_global_exists("game_input") && global.game_input.gamepad_connected);

    GameTitleDrawPageHeading(_heading, 34);
    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(string(_state.controls_index + 1) + " / " + string(_entry_count),
        320, 54, make_color_rgb(160, 188, 220));

    for (var i = 0; i < _visible_count; i++) {
        var _entry_index = _first_entry + i;
        var _entry = _entries[_entry_index];
        var _selected = _entry_index == _state.controls_index;
        var _style = GameTitlePanelStyleCreate(_selected);
        var _row_top = 66 + (i * 32);
        var _value = _entry.value;

        if (_selected && _state.remap_listening) {
            _value = (_device == "gamepad")
                ? (_gamepad_ready ? "Press a button..." : "Connect controller...")
                : "Press a key...";
        }

        GameTitleDrawFrame(124, _row_top, 392, 26, _style.border_color,
            _style.fill_color, _style.fill_alpha, _selected);
        draw_set_font(fn_menu);
        if (_entry.id == "reset" || _entry.id == "back") {
            draw_set_halign(fa_center);
            GameUiDrawOutlinedText(_entry.label, 320, _row_top + 14, _style.text_color);
        } else {
            draw_set_halign(fa_left);
            GameUiDrawOutlinedText(_entry.label, 138, _row_top + 14, _style.text_color);
            draw_set_halign(fa_right);
            GameUiDrawOutlinedText(_value, 502, _row_top + 14,
                (_selected && _state.remap_listening)
                    ? make_color_rgb(255, 228, 138) : _style.text_color);
        }
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    var _help = "Confirm rebinds   Bomb returns";
    if (_state.remap_listening) {
        _help = (_device == "gamepad")
            ? (_gamepad_ready
                ? "Release controls, then press a button   Select cancels"
                : "Connect a controller to continue listening")
            : "Release keys, then press a key   Backspace cancels";
    } else if (_device == "gamepad") {
        _help = "Left stick remains analog   Confirm rebinds   Bomb returns";
    }
    GameUiDrawOutlinedText(_help, 320, 322, make_color_rgb(170, 204, 228));
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

        GameTitleDrawFrame(128, _row_top, 384, 26, _style.border_color,
            _style.fill_color, _style.fill_alpha,
            _entry_index == _state.practice_index);
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
    GameUiDrawOutlinedText("Move to adjust   " + GameInputActiveBindingLabel("fire")
        + " chooses   " + GameInputActiveBindingLabel("bomb") + " returns",
        320, 326, make_color_rgb(160, 188, 220));
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
    GameUiDrawOutlinedText("Move left / right to change ship   "
        + GameInputActiveBindingLabel("bomb") + " returns",
        320, 326, make_color_rgb(160, 188, 220));
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
    GameUiDrawOutlinedText("Move left / right to browse   "
        + GameInputActiveBindingLabel("bomb") + " returns",
        320, 332, make_color_rgb(160, 188, 220));
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
        GameTitleDrawFrame(128, _row_top, 384, 38, _style.border_color,
            _style.fill_color, _style.fill_alpha,
            _track_index == _state.music_index);
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
    GameUiDrawOutlinedText((_preview_active ? "Move to switch   " : "Move to select   ")
        + GameInputActiveBindingLabel("fire") + (_preview_active ? " stops   " : " plays   ")
        + GameInputActiveBindingLabel("bomb") + " returns",
        320, 326, make_color_rgb(160, 188, 220));
}

/// @func GameTitleDrawCharacterSelectPage(state)
/// Draws the character select page for the active ship.
function GameTitleDrawCharacterSelectPage(_state) {
    var _character = GameTitleCharacterGet(_state, _state.select_character_index);
    var _line_count = array_length(_character.description_lines);

    GameTitleDrawPageHeading("Choose the Chaser", 32);
    draw_set_font(fn_dialogue_name);
    GameUiDrawOutlinedText(_character.name, 320, 56, _character.accent_color);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(_character.subtitle, 320, 76, make_color_rgb(180, 204, 224));

    var _panel_style = GameTitlePanelStyleCreate(false);

    GameTitleDrawFrame(42, 94, 218, 202, _panel_style.border_color, _panel_style.fill_color, 0.82);
    GameTitleDrawCharacterAttackPreview(_character, _state.flash_timer, 151, 225);

    GameTitleDrawFrame(276, 94, 322, 202, _panel_style.border_color, _panel_style.fill_color, 0.82);
    draw_set_halign(fa_left);
    draw_set_font(fn_menu);
    GameUiDrawOutlinedText("Pilot", 290, 109, _character.accent_color);
    GameUiDrawOutlinedText(_character.pilot_name, 382, 109, c_white);
    GameUiDrawOutlinedText("Speed", 290, 128, _character.accent_color);
    GameUiDrawOutlinedText(_character.speed_label, 382, 128, c_white);
    GameUiDrawOutlinedText("Normal", 290, 147, _character.accent_color);
    GameUiDrawOutlinedText(_character.normal_label, 382, 147, c_white);
    GameUiDrawOutlinedText("Focus", 290, 166, _character.accent_color);
    GameUiDrawOutlinedText(_character.focus_label, 382, 166, c_white);
    GameUiDrawOutlinedText("Sword", 290, 185, _character.accent_color);
    GameUiDrawOutlinedText(_character.sword_label, 382, 185, c_white);

    draw_set_font(fn_dialogue_speech);
    for (var i = 0; i < min(5, _line_count); i++) {
        GameUiDrawOutlinedText(_character.description_lines[i], 290, 212 + (i * 14),
            (i < 2) ? c_white : make_color_rgb(190, 210, 230));
    }

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(GameInputActiveBindingLabel("fire")
        + " begins   Move left / right to switch   "
        + GameInputActiveBindingLabel("bomb") + " returns",
        320, 326, make_color_rgb(180, 214, 236));
}

/// @func GameTitleDrawCharacterAttackPreview(character, timer, x, y)
/// Animates normal fire, focused fire, charge, and sword use in the select card.
function GameTitleDrawCharacterAttackPreview(_character, _timer, _x, _y) {
    var _cycle = _timer mod 240;
    var _ship_asset = asset_get_index(_character.preview_sprite);
    var _shot_asset = asset_get_index((_character.id == SHIP_SELKIE)
        ? "spr_sunset_bullet" : "spr_sunrise_bullet");
    var _label = "NORMAL VOLLEY";

    draw_set_halign(fa_center);
    draw_set_font(fn_dialogue_speech);

    if (_cycle < 90) {
        for (var shot = -2; shot <= 2; shot++) {
            var _shot_y = _y - 30 - ((_cycle * 3 + ((shot + 2) * 23)) mod 116);
            var _shot_x = _x + (shot * ((_character.id == SHIP_SELKIE) ? 13 : 9));
            if (_shot_asset != -1) {
                draw_sprite_ext(_shot_asset, 0, _shot_x, _shot_y, 0.75, 0.75,
                    90 + (shot * 4), _character.accent_color, 0.9);
            }
        }
    } else if (_cycle < 160) {
        _label = "FOCUS LANCE";
        var _focus_time = _cycle - 90;
        for (var lance = -1; lance <= 1; lance++) {
            var _lance_y = _y - 30 - ((_focus_time * 5 + ((lance + 1) * 37)) mod 116);
            if (_shot_asset != -1) {
                draw_sprite_ext(_shot_asset, 0, _x + (lance * 5), _lance_y,
                    0.65, 1.0, 90, c_white, 0.96);
            }
        }
    } else {
        var _sword_time = _cycle - 160;
        var _charge = clamp(_sword_time / 38, 0, 1);
        _label = (_charge < 1) ? "HOLD FIRE: CHARGING" : "SWORD SWEEP";

        draw_set_alpha(0.35 + (_charge * 0.5));
        draw_set_color(merge_color(make_color_rgb(118, 236, 255), make_color_rgb(255, 214, 112), _charge));
        draw_circle(_x, _y, 22 + (_charge * 11), true);

        if (_charge >= 1) {
            var _sweep_angle = 230 + (GameCosineEase01(clamp((_sword_time - 38) / 42, 0, 1)) * 280);
            if (_character.id == SHIP_SELKIE) {
                var _disc_x = _x + lengthdir_x(58, _sweep_angle);
                var _disc_y = _y + lengthdir_y(58, _sweep_angle);
                draw_set_color(make_color_rgb(255, 174, 234));
                draw_circle(_disc_x, _disc_y, 11, true);
                draw_circle(_disc_x, _disc_y, 5, true);
            } else {
                var _thorn_x = _x + lengthdir_x(66, _sweep_angle);
                var _thorn_y = _y + lengthdir_y(66, _sweep_angle);
                draw_set_color(make_color_rgb(88, 210, 150));
                draw_line_width(_x, _y, _thorn_x, _thorn_y, 3);
                draw_set_color(make_color_rgb(255, 118, 204));
                draw_circle(_thorn_x, _thorn_y, 6, false);
            }
        }
    }

    draw_set_alpha(1);
    if (_ship_asset != -1 && sprite_exists(_ship_asset)) {
        var _scale = min(1.6, 72 / max(1, sprite_get_height(_ship_asset)));
        draw_sprite_ext(_ship_asset, 0, _x, _y, _scale,
            _scale * GamePlayerShipDrawScaleYGet(_character.id), 0, c_white, 1);
    }

    GameUiDrawOutlinedText(_label, _x, 278, _character.accent_color);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameTitleDraw(state)
/// Draws the current title screen page for the active state.
function GameTitleDraw(_state) {
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
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

        case "controls_keyboard":
            GameTitleDrawControlsPage(_state, "keyboard");
            break;

        case "controls_gamepad":
            GameTitleDrawControlsPage(_state, "gamepad");
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

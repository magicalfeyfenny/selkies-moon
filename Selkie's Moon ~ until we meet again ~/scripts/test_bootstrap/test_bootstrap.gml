// GMTL regression suite. Tests are grouped by owning subsystem and exercise
// pure helpers plus representative object events without writing player saves.
suite(function() {
    section("Game setup", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();

            GameTestPersistenceFilesDelete();
        });

        afterEach(function() {
            GameTestPersistenceFilesDelete();
        });

        test("Default config keeps the playfield at 640x360", function() {
            var _config = GameConfigCreateDefault();

            expect(_config.version).toBe(CONFIG_VERSION);
            expect(_config.view_width).toBe(640);
            expect(_config.view_height).toBe(360);
            expect(_config.target_fps).toBe(60);
            expect(_config.input_device).toBe("keyboard");
            expect(GameInputBindingsIsValid(_config.input_bindings)).toBeTruthy();
            expect(_config.input_bindings.keyboard.fire[0]).toBe(ord("Z"));
            expect(_config.input_bindings.gamepad.pause).toBe(gp_start);
            expect(_config.master_volume).toBe(100);
            expect(_config.music_volume).toBe(100);
            expect(_config.sfx_volume).toBe(100);
        });

        test("Pixel presentation antialiases only fractional fullscreen scales", function() {
            expect(GamePixelPresentationScaleIsInteger(1280, 720)).toBeTruthy();
            expect(GamePixelPresentationScaleIsInteger(1920, 1080)).toBeTruthy();
            expect(GamePixelPresentationScaleIsInteger(1366, 768)).toBeFalsy();
            expect(GamePixelPresentationScaleIsInteger(2560, 1600)).toBeFalsy();

            expect(GamePixelPresentationLinearFilterGet(false, 1366, 768)).toBeFalsy();
            expect(GamePixelPresentationLinearFilterGet(true, 1280, 720)).toBeFalsy();
            expect(GamePixelPresentationLinearFilterGet(true, 1920, 1080)).toBeFalsy();
            expect(GamePixelPresentationLinearFilterGet(true, 1366, 768)).toBeTruthy();
            expect(GamePixelPresentationLinearFilterGet(true, 2560, 1600)).toBeTruthy();
        });

        test("Crystal UI maps GUI panels onto matching backdrop pixels", function() {
            var _region = GameUiCrystalSourceRegionCreate(
                10, 20, 110, 70, 1280, 720, 640, 360);

            expect(_region.source_x).toBe(20);
            expect(_region.source_y).toBe(40);
            expect(_region.source_width).toBe(200);
            expect(_region.source_height).toBe(100);
            expect(_region.target_x).toBe(10);
            expect(_region.target_y).toBe(20);
            expect(_region.target_width).toBe(100);
            expect(_region.target_height).toBe(50);
        });

        test("Default save data starts clean", function() {
            var _save = GameSaveDataCreateDefault();

            expect(_save.version).toBe(SAVE_VERSION);
            expect(array_length(_save.high_score.ship_A)).toBe(10);
            expect(array_length(_save.high_score.ship_selkie)).toBe(10);
            expect(_save.high_score.ship_A[0]).toBe(0);
            expect(_save.high_score.ship_selkie[0]).toBe(0);
            expect(_save.runs_started.ship_A[0]).toBe(0);
            expect(_save.runs_started.ship_selkie[0]).toBe(0);
            expect(_save.runs_finished.ship_A[0]).toBe(0);
            expect(_save.runs_finished.ship_selkie[0]).toBe(0);
            expect(_save.continues_used.ship_A[0]).toBe(0);
            expect(_save.continues_used.ship_selkie[0]).toBe(0);
        });

        test("Struct defaults fill missing fields without overwriting live values", function() {
            var _state = { retained: 7 };

            expect(GameStructFieldEnsure(_state, "added", 3)).toBe(3);
            expect(GameStructFieldEnsure(_state, "retained", 99)).toBe(7);
            expect(_state.added).toBe(3);
            expect(_state.retained).toBe(7);
        });

        test("LoadGameSave loads a matching save file", function() {
            var _save = GameSaveDataCreateDefault();
            _save.high_score.ship_A[0] = 777;
            _save.runs_started.ship_A[0] = 4;
            _save.continues_used.ship_A[0] = 1;

            var _file = file_text_open_write(GameSavePathGet());
            file_text_write_string(_file, json_stringify(_save));
            file_text_close(_file);

            global.game_save = GameSaveDataCreateDefault();

            expect(LoadGameSave()).toBeTruthy();
            expect(global.game_save.high_score.ship_A[0]).toBe(777);
            expect(global.game_save.runs_started.ship_A[0]).toBe(4);
            expect(global.game_save.continues_used.ship_A[0]).toBe(1);
            expect(file_exists(GamePersistenceBackupPathGet(GameSavePathGet()))).toBeFalsy();
        });

        test("LoadGameSave rejects and backs up a future save version", function() {
            var _save = GameSaveDataCreateDefault();
            _save.version = SAVE_VERSION + 1;
            _save.high_score.ship_A[0] = 999;

            var _file = file_text_open_write(GameSavePathGet());
            file_text_write_string(_file, json_stringify(_save));
            file_text_close(_file);

            global.game_save = GameSaveDataCreateDefault();

            expect(LoadGameSave()).toBeFalsy();
            expect(global.game_save.high_score.ship_A[0]).toBe(0);
            expect(global.game_save.version).toBe(SAVE_VERSION);
            expect(file_exists(GamePersistenceBackupPathGet(GameSavePathGet()))).toBeTruthy();
        });

        test("LoadGameSave migrates legacy scalar progress into the current ship tables", function() {
            var _legacy = {
                version: max(0, SAVE_VERSION - 1),
                high_score: 43210,
                runs_started: 7,
                runs_finished: 3,
                continues_used: 2,
            };
            var _file = file_text_open_write(GameSavePathGet());
            file_text_write_string(_file, json_stringify(_legacy));
            file_text_close(_file);

            expect(LoadGameSave()).toBeTruthy();
            expect(global.game_save.version).toBe(SAVE_VERSION);
            expect(global.game_save.high_score.ship_A[0]).toBe(43210);
            expect(global.game_save.runs_started.ship_A[0]).toBe(7);
            expect(global.game_save.runs_finished.ship_A[0]).toBe(3);
            expect(global.game_save.continues_used.ship_A[0]).toBe(2);
            expect(array_length(global.game_save.high_score.ship_selkie)).toBe(10);
            expect(file_exists(GamePersistenceBackupPathGet(GameSavePathGet()))).toBeTruthy();
        });

        test("Malformed persistence is backed up and recovered without stopping boot", function() {
            var _file = file_text_open_write(GameSavePathGet());
            file_text_write_string(_file, "{not valid json");
            file_text_close(_file);

            expect(LoadGameSave()).toBeFalsy();
            expect(file_exists(GamePersistenceBackupPathGet(GameSavePathGet()))).toBeTruthy();
            expect(global.game_save.version).toBe(SAVE_VERSION);
        });

        test("Automated tests use isolated persistence filenames", function() {
            expect(GamePersistenceIsAutomationRun()).toBeTruthy();
            expect(GameSavePathGet()).toBe("automation-game.sav");
            expect(GameConfigPathGet()).toBe("automation-config.sav");
        });

        test("LoadGameConfig loads a matching config file", function() {
            var _config = GameConfigCreateDefault();
            _config.display_scale = 5;
            _config.fullscreen = true;
            _config.target_fps = 30;

            var _file = file_text_open_write(GameConfigPathGet());
            file_text_write_string(_file, json_stringify(_config));
            file_text_close(_file);

            global.game_config = GameConfigCreateDefault();

            expect(LoadGameConfig()).toBeTruthy();
            expect(global.game_config.display_scale).toBe(5);
            expect(global.game_config.fullscreen).toBeTruthy();
            expect(global.game_config.target_fps).toBe(30);
            expect(file_exists(GamePersistenceBackupPathGet(GameConfigPathGet()))).toBeFalsy();
        });

        test("Config migration preserves and clamps the three audio gains", function() {
            var _legacy = {
                version: CONFIG_VERSION - 1,
                view_width: 640,
                view_height: 360,
                target_fps: 60,
                display_scale: 3,
                fullscreen: false,
                input_device: "keyboard",
                master_volume: 78,
                music_volume: 180,
                sfx_volume: -12,
            };

            var _migrated = GameConfigDataMigrate(_legacy);

            expect(_migrated.version).toBe(CONFIG_VERSION);
            expect(_migrated.master_volume).toBe(78);
            expect(_migrated.music_volume).toBe(100);
            expect(_migrated.sfx_volume).toBe(0);
            expect(GameInputBindingsIsValid(_migrated.input_bindings)).toBeTruthy();
            expect(GameConfigDataIsCurrent(_migrated)).toBeTruthy();
        });

        test("Audio mixer applies independent music and SFX asset gains", function() {
            global.game_config.master_volume = 80;
            global.game_config.music_volume = 35;
            global.game_config.sfx_volume = 65;

            expect(GameAudioVolumesApply()).toBeTruthy();
            expect(round(audio_sound_get_gain(snd_music_title) * 100)).toBe(35);
            expect(round(audio_sound_get_gain(snd_player_shot_moon) * 100)).toBe(14);
            expect(round(audio_sound_get_gain(snd_bomb) * 100)).toBe(51);

            global.game_config = GameConfigCreateDefault();
            GameAudioVolumesApply();
        });

        test("Enemy bullet visibility flash stays subtle", function() {
            var _minimum = GameEnemyBulletFlashAlphaGet(75, 90);
            var _maximum = GameEnemyBulletFlashAlphaGet(0, 90);

            expect(_minimum >= 0.04).toBeTruthy();
            expect(_maximum <= 0.11).toBeTruthy();
            expect(_maximum > _minimum).toBeTruthy();
        });

        test("LoadGameConfig rejects and backs up a future config version", function() {
            var _config = GameConfigCreateDefault();
            _config.version = CONFIG_VERSION + 1;
            _config.display_scale = 6;

            var _file = file_text_open_write(GameConfigPathGet());
            file_text_write_string(_file, json_stringify(_config));
            file_text_close(_file);

            global.game_config = GameConfigCreateDefault();

            expect(LoadGameConfig()).toBeFalsy();
            expect(global.game_config.version).toBe(CONFIG_VERSION);
            expect(global.game_config.display_scale).toBe(2);
            expect(file_exists(GamePersistenceBackupPathGet(GameConfigPathGet()))).toBeTruthy();
        });

        test("GameInitialize writes default save and config files when missing", function() {
            GameInitialize();

            expect(file_exists(GameSavePathGet())).toBeTruthy();
            expect(file_exists(GameConfigPathGet())).toBeTruthy();
            expect(global.game_runtime.is_initialized).toBeTruthy();
            expect(global.game_runtime.lives).toBe(DEFAULT_LIVES);
            expect(global.game_runtime.bombs).toBe(DEFAULT_BOMBS);
            expect(global.game_config.version).toBe(CONFIG_VERSION);
            expect(global.game_save.version).toBe(SAVE_VERSION);
        });

        test("A non-qualifying score leaves the leaderboard and continues rows unchanged", function() {
            global.game_runtime = GameRuntimeDataCreateDefault();
            global.game_runtime.selected_ship_id = SHIP_SUNRISE;
            global.game_runtime.score = 5;
            global.game_runtime.continues_used = 9;
            global.game_save.high_score.ship_A = [100, 90, 80, 70, 60, 50, 40, 30, 20, 10];
            global.game_save.continues_used.ship_A = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

            GameRunResultSave();

            expect(global.game_save.high_score.ship_A[9]).toBe(10);
            expect(global.game_save.continues_used.ship_A[9]).toBe(9);
            expect(global.game_save.runs_finished.ship_A[0]).toBe(1);
        });
    });

    section("Title menu", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            GameTestPersistenceFilesDelete();
        });

        afterEach(function() {
            GameTestPersistenceFilesDelete();
        });

        test("Title state starts on the press start screen", function() {
            var _state = GameTitleStateCreate();

            expect(_state.phase).toBe("press_start");
            expect(_state.page).toBe("main");
            expect(array_length(_state.main_items)).toBe(7);
            expect(array_length(_state.characters)).toBe(2);
            expect(array_length(_state.gallery_items)).toBeGreaterThan(1);
            expect(array_length(_state.music_items)).toBe(15);
            expect(_state.music_items[0].name).toBe("A Promise Across the Horizon");
            expect(_state.music_items[6].name).toBe("Wish and Suit, Entwined");
            expect(_state.music_items[14].name).toBe("Until We Meet Again");
            expect(_state.options_index).toBe(0);
        });

        test("Fire moves the title screen into the main menu", function() {
            var _state = GameTitleStateCreate();

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(_state.phase).toBe("menu");
            expect(_state.page).toBe("main");
            expect(_state.main_index).toBe(0);
        });

        test("Main menu wraps upward to Quit", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(true, false, false, false, false, false));

            expect(_state.main_index).toBe(6);
            expect(_state.main_items[_state.main_index].id).toBe("quit");
        });

        test("Start Game opens the character select submenu", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(_state.page).toBe("character_select");
        });

        test("Practice Select edits its setup and launches gameplay directly", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.main_index = 5;

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_state.page).toBe("practice");
            expect(array_length(GameTitlePracticeEntriesCreate(_state))).toBe(11);

            _state.practice_index = 1;
            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));
            expect(_state.practice_config.stage).toBe(2);

            _state.practice_index = 2;
            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));
            expect(_state.practice_config.segment).toBe(PRACTICE_SEGMENT_WAVES);

            _state.practice_index = 4;
            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));
            expect(_state.practice_config.rank).toBe(RANK_MIN + 5);

            _state.practice_index = 5;
            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_state.practice_config.dynamic_rank).toBeTruthy();

            _state.practice_index = 9;
            var _result = GameTitleStateStep(_state,
                GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_result.action).toBe("goto_practice");
            expect(_result.room_name).toBe("rm_game");
            expect(_result.practice_config.stage).toBe(2);
            expect(_result.practice_config.segment).toBe(PRACTICE_SEGMENT_WAVES);
            expect(_result.practice_config.rank).toBe(RANK_MIN + 5);
            expect(_result.practice_config.dynamic_rank).toBeTruthy();
        });

        test("Scores submenu returns to main on bomb", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "scores";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, false, true));

            expect(_state.page).toBe("main");
        });

        test("Main menu opens CG gallery and music room pages", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.main_index = 2;

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_state.page).toBe("cg_gallery");

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, false, true));
            expect(_state.page).toBe("main");

            _state.main_index = 3;
            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_state.page).toBe("music_room");

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, false, true));
            expect(_state.page).toBe("main");
        });

        test("Music Room preview ownership follows the selected row without restoring title BGM", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "music_room";
            global.game_audio = {
                stage_music_playing: true,
                current_music_id: snd_music_title,
                music_owner: "room",
                music_preview_instance_id: -1,
                music_preview_sound_id: -1,
                enemy_fire_cycle: 0,
            };

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(GameMusicRoomPreviewIsActive()).toBeTruthy();
            expect(_state.music_preview_index).toBe(0);
            expect(global.game_audio.music_preview_sound_id).toBe(_state.music_items[0].sound_id);
            expect(global.game_audio.music_owner).toBe("music_room");

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, true, false, false, false, false));

            expect(_state.music_index).toBe(1);
            expect(_state.music_preview_index).toBe(1);
            expect(global.game_audio.music_preview_sound_id).toBe(_state.music_items[1].sound_id);

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(GameMusicRoomPreviewIsActive()).toBeFalsy();
            expect(_state.music_preview_index).toBe(-1);
            expect(global.game_audio.music_owner).toBe("room");
        });

        test("CG gallery browses art entries without leaving its page", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "cg_gallery";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));

            expect(_state.page).toBe("cg_gallery");
            expect(_state.gallery_index).toBe(1);

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, true, false, false, false));
            expect(_state.gallery_index).toBe(0);
        });

        test("Options menu exposes display, audio, and separate control maps", function() {
            var _entries = GameTitleConfigEntriesCreate();

            expect(array_length(_entries)).toBe(7);
            expect(_entries[0].id).toBe("fullscreen");
            expect(_entries[0].value).toBe("Off");
            expect(_entries[1].id).toBe("display_scale");
            expect(_entries[2].id).toBe("master_volume");
            expect(_entries[2].meter_ratio).toBe(1);
            expect(_entries[3].id).toBe("music_volume");
            expect(_entries[4].id).toBe("sfx_volume");
            expect(_entries[5].id).toBe("controls_keyboard");
            expect(_entries[6].id).toBe("controls_gamepad");
            expect(array_length(GameTitleConfigEntriesCreate(false))).toBe(5);
        });

        test("Keyboard and gamepad remaps persist separately and swap collisions", function() {
            var _state = GameTitleStateCreate();

            GameTitleRemapBegin(_state, "keyboard", "bomb");
            expect(GameTitleRemapCommit(_state, ord("Z"))).toBeTruthy();
            expect(global.game_config.input_bindings.keyboard.bomb[0]).toBe(ord("Z"));
            expect(global.game_config.input_bindings.keyboard.fire[0]).toBe(ord("X"));
            expect(global.game_config.input_bindings.gamepad.bomb).toBe(gp_face2);

            GameTitleRemapBegin(_state, "gamepad", "fire");
            expect(GameTitleRemapCommit(_state, gp_face2)).toBeTruthy();
            expect(global.game_config.input_bindings.gamepad.fire).toBe(gp_face2);
            expect(global.game_config.input_bindings.gamepad.bomb).toBe(gp_face1);
            expect(global.game_config.input_bindings.keyboard.bomb[0]).toBe(ord("Z"));
            expect(file_exists(GameConfigPathGet())).toBeTruthy();
        });

        test("Control submenus enter listening mode and can restore one device", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "options";
            _state.options_index = 5;

            GameTitleStateStep(_state,
                GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_state.page).toBe("controls_keyboard");

            _state.controls_index = 4;
            GameTitleStateStep(_state,
                GameTitleInputSnapshotCreate(false, false, false, false, true, false));
            expect(_state.remap_listening).toBeTruthy();
            expect(_state.remap_device).toBe("keyboard");
            expect(_state.remap_verb).toBe("fire");

            expect(GameTitleRemapCancel(_state)).toBeTruthy();
            GameInputBindingAssign("keyboard", "fire", ord("Q"));
            expect(global.game_config.input_bindings.keyboard.fire[0]).toBe(ord("Q"));
            expect(GameInputBindingsResetDevice("keyboard")).toBeTruthy();
            expect(global.game_config.input_bindings.keyboard.fire[0]).toBe(ord("Z"));
        });

        test("Volume meters move in five-point steps, clamp, and persist", function() {
            expect(GameTitleConfigEntryAdjust("master_volume", -1)).toBeTruthy();
            expect(global.game_config.master_volume).toBe(95);
            expect(GameTitleConfigEntryAdjust("music_volume", -1)).toBeTruthy();
            expect(global.game_config.music_volume).toBe(95);
            global.game_config.sfx_volume = 0;
            expect(GameTitleConfigEntryAdjust("sfx_volume", -1)).toBeFalsy();
            expect(global.game_config.sfx_volume).toBe(0);
            expect(file_exists(GameConfigPathGet())).toBeTruthy();
        });

        test("Options menu changes the active setting with up and down", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "options";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, true, false, false, false, false));

            expect(_state.options_index).toBe(1);

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(true, false, false, false, false, false));

            expect(_state.options_index).toBe(0);
        });

        test("Options menu toggles fullscreen and saves the config", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "options";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));

            expect(global.game_config.fullscreen).toBeTruthy();
            expect(file_exists(GameConfigPathGet())).toBeTruthy();

            var _file = file_text_open_read(GameConfigPathGet());
            var _json_string = file_text_read_string(_file);
            file_text_close(_file);

            var _config = json_parse(_json_string);
            expect(_config.fullscreen).toBeTruthy();
        });

        test("Options menu wraps display scale between 1 and 6", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "options";
            _state.options_index = 1;

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));

            expect(global.game_config.display_scale).toBe(3);

            global.game_config.display_scale = 6;
            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, true, false, false));

            expect(global.game_config.display_scale).toBe(1);

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, true, false, false, false));

            expect(global.game_config.display_scale).toBe(6);
        });

        test("Character select returns rm_opening with ship A", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "character_select";

            var _result = GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(_result.action).toBe("goto_room");
            expect(_result.room_name).toBe("rm_opening");
            expect(_result.character_id).toBe("ship_A");
            expect(_result.character_index).toBe(0);
        });

        test("Character select can choose Selkie's Sunrise ship", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "character_select";
            _state.select_character_index = 1;

            var _result = GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(_result.action).toBe("goto_room");
            expect(_result.character_id).toBe(SHIP_SELKIE);
            expect(_result.character_index).toBe(1);
        });

        test("Title art metadata uses Moon's Sunset and Selkie's Sunrise names", function() {
            var _characters = GameTitleCharactersCreate();

            expect(_characters[0].name).toBe("Sunset");
            expect(_characters[0].preview_sprite).toBe("spr_sunrise");
            expect(_characters[1].name).toBe("Sunrise");
            expect(_characters[1].preview_sprite).toBe("spr_sunset");
        });

        test("Sunset character metadata matches Moon's story role", function() {
            var _characters = GameTitleCharactersCreate();

            expect(_characters[0].pilot_name).toBe("Moon");
            expect(_characters[0].support_name).toBe("");
            expect(_characters[0].subtitle).toBe("Moon carries twilight back toward the sea");
            expect(array_length(_characters[0].description_lines)).toBe(5);
            expect(_characters[0].description_lines[0]).toBe("A balanced craft built for");
            expect(_characters[0].description_lines[1]).toBe("Moon's long pursuit through");
            expect(_characters[0].description_lines[2]).toBe("the violet tide. Wide volleys");
            expect(_characters[0].description_lines[3]).toBe("turn blue heat into orange");
            expect(_characters[0].description_lines[4]).toBe("as her resolve rises");
        });

        test("Press-start subtitle fades in over one second while sliding left", function() {
            var _start = GameTitlePressStartSubtitleAnimCreate(0);
            var _halfway = GameTitlePressStartSubtitleAnimCreate(30);
            var _finish = GameTitlePressStartSubtitleAnimCreate(60);
            var _clamped = GameTitlePressStartSubtitleAnimCreate(90);

            expect(_start.x).toBe(258);
            expect(_start.y).toBe(236);
            expect(_start.alpha).toBe(0);

            expect(_halfway.x).toBe(249);
            expect(_halfway.alpha).toBe(0.5);

            expect(_finish.x).toBe(240);
            expect(_finish.alpha).toBe(1);

            expect(_clamped.x).toBe(240);
            expect(_clamped.alpha).toBe(1);
        });

        test("Press-start prompt reflects controller detection without a controls legend", function() {
            expect(GameTitlePressPromptTextGet(false)).toBe("Press Z");
            expect(GameTitlePressPromptTextGet(true)).toBe("Press Start");

            GameInputBindingAssign("keyboard", "fire", ord("Q"));
            GameInputBindingAssign("gamepad", "pause", gp_face4);
            expect(GameTitlePressPromptTextGet(false)).toBe("Press Q");
            expect(GameTitlePressPromptTextGet(true)).toBe("Press Y / Triangle");
        });

        test("Title submenu panels use airy normal and brighter selected styling", function() {
            var _normal = GameTitlePanelStyleCreate(false);
            var _selected = GameTitlePanelStyleCreate(true);

            expect(_normal.fill_alpha).toBe(0.56);
            expect(_normal.fill_color).toBe(make_color_rgb(58, 18, 92));
            expect(_selected.fill_alpha).toBe(0.72);
            expect(_selected.fill_color).toBe(make_color_rgb(78, 28, 116));
        });

    });

    section("Gameplay", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            GameTestPersistenceFilesDelete();
        });

        afterEach(function() {
            GameTestPersistenceFilesDelete();
        });

        test("Default runtime includes continue and berserk state", function() {
            var _runtime = GameRuntimeDataCreateDefault();

            expect(_runtime.signals.continue_request).toBeFalsy();
            expect(_runtime.continue_screen.mode).toBe("prompt");
            expect(_runtime.meter).toBe(0);
            expect(_runtime.is_berserk).toBeFalsy();
            expect(_runtime.bomb_active).toBeFalsy();
            expect(_runtime.bomb_timer).toBe(0);
            expect(_runtime.current_stage).toBe(1);
            expect(_runtime.stage_count).toBe(STAGE_COUNT);
            expect(_runtime.power).toBe(0);
            expect(_runtime.stage_frame).toBe(0);
            expect(_runtime.resource_drop_charge).toBe(0);
            expect(_runtime.resource_drop_threshold).toBe(
                RESOURCE_DROP_CHARGE_BASE * RESOURCE_DROP_DEFEAT_MULTIPLIER);
            expect(_runtime.resource_drops_this_stage).toBe(0);
        });

        test("Run start initialization records a run and defaults the ship", function() {
            GameRunStartInitialize();

            expect(global.game_runtime.selected_ship_id).toBe("ship_A");
            expect(global.game_runtime.selected_ship_index).toBe(0);
            expect(global.game_runtime.rank).toBe(RANK_MIN);
            expect(global.game_runtime.run_started_recorded).toBeTruthy();
            expect(global.game_save.runs_started.ship_A[0]).toBe(1);
            expect(file_exists(GameSavePathGet())).toBeTruthy();
        });

        test("Stage scroll reaches boss intro after the configured stage length", function() {
            var _state = GameSceneStateCreate();

            _state.frame = STAGE_LENGTH_FRAMES - 1;

            expect(GameSceneStageAdvance(_state)).toBe("boss_intro");
            expect(_state.mode).toBe("boss_intro");
            expect(_state.scroll_speed).toBe(0);
            expect(_state.background_route).toBe("boss");
            expect(_state.stage_length_frames).toBe(STAGE_LENGTH_FRAMES);
            expect(global.game_runtime.stage_frame).toBe(STAGE_LENGTH_FRAMES);

            var _background_before = _state.background_frame;
            GameSceneBackgroundStep(_state);
            expect(_state.background_frame).toBe(_background_before + 1);
            expect(_state.background_route_blend).toBeGreaterThan(0);
        });

        test("Every 3D stage has valid travel and boss loops plus billboard scenery", function() {
            for (var stage = 1; stage <= STAGE_COUNT; stage++) {
                var _config = GameStage3DConfigGet(stage);
                expect(GameStage3DPathLoopIsValid(_config, false)).toBeTruthy();
                expect(GameStage3DPathLoopIsValid(_config, true)).toBeTruthy();
                expect(array_length(_config.billboards)).toBeGreaterThan(15);

                var _travel = GameStage3DPathSample(_config, 18, false);
                var _boss = GameStage3DPathSample(_config, 18, true);
                var _blend = GameStage3DPathBlendSample(_config, 18, 0.5);
                expect(_blend.y).toBe(18);
                expect(_blend.x >= min(_travel.x, _boss.x)
                    && _blend.x <= max(_travel.x, _boss.x)).toBeTruthy();
            }
        });

        test("Stage clear advances to the next stage and restarts scroll state", function() {
            var _state = GameSceneStateCreate();
            _state.frame = 900;
            _state.mode = "stage_clear";
            _state.scroll_speed = 0;
            _state.boss_spawned = true;
            global.game_runtime.current_stage = 4;
            global.game_runtime.stage_complete = true;

            expect(GameSceneNextStageBegin(_state)).toBe(5);
            expect(_state.frame).toBe(0);
            expect(_state.mode).toBe("scroll");
            expect(_state.scroll_speed).toBe(CAMERA_SCROLL_SPEED);
            expect(_state.boss_spawned).toBeFalsy();
            expect(global.game_runtime.stage_complete).toBeFalsy();
            expect(global.game_runtime.stage_notice_timer).toBe(STAGE_NOTICE_FRAMES);
        });

        test("Stage balance report keeps every stage within no-continue viability bounds", function() {
            for (var stage = 1; stage <= STAGE_COUNT; stage++) {
                var _report = GameStageBalanceReportCreate(stage);

                expect(_report.no_continue_viable).toBeTruthy();
                expect(_report.estimated_score_pickups).toBeGreaterThan(4);
                expect(_report.estimated_resource_pickups <= _report.resource_drop_limit).toBeTruthy();
                expect(_report.max_spawn_pressure).toBeLessThan(42);
                var _phase_count = GameBossPhaseCountForStage(stage);
                var _expected_with_transitions = _phase_count
                    * ((GameBossPhaseTargetSecondsGet(stage) * 60) + BOSS_PHASE_TRANSITION_FRAMES);
                expect(_report.focus_boss_clear_frames <= _expected_with_transitions).toBeTruthy();

                if (stage > 1) {
                    expect(_report.fastest_phase_clear_frames).toBeGreaterThan(3 * 60);
                    expect(_report.fastest_phase_clear_frames).toBeLessThan(9 * 60);
                }
            }

            var _final_report = GameStageBalanceReportCreate(STAGE_COUNT);
            expect(_final_report.fastest_phase_clear_frames).toBeGreaterThan(7 * 60);
        });

        test("Stage timeline helpers spawn above the field and stop once scrolling ends", function() {
            var _state = GameSceneStateCreate();
            var _turret = GameStageTurretSpawnPositionCreate(CAMERA_HOME_X, CAMERA_HOME_Y);
            var _bees = GameStageBeeSpawnPositionsCreate(CAMERA_HOME_X, CAMERA_HOME_Y);
            var _mayfly = GameStageMayflySpawnPositionCreate(CAMERA_HOME_X, CAMERA_HOME_Y);
            var _band = GameStageSpawnBandRectGet(CAMERA_HOME_X, CAMERA_HOME_Y);

            expect(GameStageTimelineShouldRun(_state)).toBeTruthy();
            expect(_turret.y).toBe(_band.y);
            expect(_mayfly.y).toBe(_band.y);
            expect(_turret.x >= _band.left).toBeTruthy();
            expect(_turret.x <= _band.right).toBeTruthy();
            expect(array_length(_bees)).toBe(STAGE_BEE_WAVE_COUNT);

            for (var i = 0; i < array_length(_bees); i++) {
                expect(_bees[i].x >= _band.left).toBeTruthy();
                expect(_bees[i].x <= _band.right).toBeTruthy();
                expect(_bees[i].y).toBe(_band.y);
            }

            _state.mode = "boss_intro";
            expect(GameStageTimelineShouldRun(_state)).toBeFalsy();

            _state.mode = "scroll";
            global.game_runtime.signals.dialogue = true;
            expect(GameStageTimelineShouldRun(_state)).toBeFalsy();
            global.game_runtime.signals.dialogue = false;
        });

        test("Each consolidated stage owns four unique themed basic enemies", function() {
            var _all_ids = [];

            for (var _stage = 1; _stage <= STAGE_COUNT; _stage++) {
                var _roster = GameStageEnemyRosterCreate(_stage);
                expect(array_length(_roster)).toBe(4);

                for (var _enemy_index = 0; _enemy_index < array_length(_roster); _enemy_index++) {
                    var _definition = _roster[_enemy_index];
                    for (var _seen_index = 0; _seen_index < array_length(_all_ids); _seen_index++) {
                        expect(_definition.id == _all_ids[_seen_index]).toBeFalsy();
                    }
                    array_push(_all_ids, _definition.id);

                    if (_stage < STAGE_COUNT) {
                        expect(_definition.id == ENEMY_VIOLET_BEE).toBeFalsy();
                        expect(_definition.id == ENEMY_TWILIGHT_MAYFLY).toBeFalsy();
                    }
                }
            }

            expect(array_length(_all_ids)).toBe(20);
            var _forge_roster = GameStageEnemyRosterCreate(1);
            expect(_forge_roster[0].id).toBe(ENEMY_FORGE_SPARK);
            expect(_forge_roster[1].id).toBe(ENEMY_ANVIL_FAMILIAR);
            expect(_forge_roster[2].id).toBe(ENEMY_BELLOWS_IMP);
            expect(_forge_roster[3].id).toBe(ENEMY_HAMMER_CHERUB);

            var _final_roster = GameStageEnemyRosterCreate(STAGE_COUNT);
            expect(_final_roster[0].id).toBe(ENEMY_VIOLET_BEE);
            expect(_final_roster[1].id).toBe(ENEMY_TWILIGHT_MAYFLY);
        });

        test("The live director spawns only stage-authored variant enemies", function() {
            var _state = GameSceneStateCreate();
            global.game_runtime.current_stage = 3;

            for (var _frame = 45; _frame <= 420; _frame++) {
                _state.frame = _frame;
                GameStageDirectorStep(_state);
            }

            expect(instance_number(obj_enemy_variant)).toBeGreaterThan(0);
            expect(instance_number(obj_enemy_turret)).toBe(0);
            expect(instance_number(obj_enemy_bee)).toBe(0);
            expect(instance_number(obj_enemy_mayfly)).toBe(0);

            with (obj_enemy_parent) { instance_destroy(); }
        });

        test("Violet bees commit downward without a player and own their projectile art", function() {
            global.game_runtime.current_stage = STAGE_COUNT;
            var _bee = instance_create_layer(160, 80, "Instances", obj_enemy_variant);
            GameEnemyVariantConfigure(_bee, ENEMY_VIOLET_BEE, STAGE_COUNT, 0, 1);

            simulateEvent(ev_step, ev_step_normal, _bee);
            expect(variable_instance_get(_bee, "variant_role")).toBe("chaser");
            expect(variable_instance_get(_bee, "flyaway_committed")).toBeTruthy();
            expect(variable_instance_get(_bee, "move_direction")).toBe(270);

            var _bullet = instance_create_layer(160, 80, "Instances", obj_bullet_diamond);
            GameStageEnemyBulletDecorate(_bullet, ENEMY_VIOLET_BEE);
            expect(variable_instance_get(_bullet, "sprite_index")).toBe(spr_violet_bee_bullet);

            with (_bullet) { instance_destroy(); }
            with (_bee) { instance_destroy(); }
        });

        test("Field clamping and camera drag stay inside the intended gameplay bounds", function() {
            var _clamped = GameScenePlayerClampPosition(CAMERA_HOME_X, CAMERA_HOME_Y, 999, 999);
            var _clamped_top = GameScenePlayerClampPosition(CAMERA_HOME_X, CAMERA_HOME_Y, -999, -999);
            var _drag_target = GameSceneCameraTargetXGet(CAMERA_HOME_X, CAMERA_HOME_X, 999);
            var _layout = GameGameplayHudLayoutCreate();

            expect(_clamped.x).toBe(CAMERA_HOME_X + PLAYFIELD_HALF_WIDTH);
            expect(_clamped.y).toBe(CAMERA_HOME_Y + PLAYFIELD_HALF_HEIGHT - PLAYFIELD_VERTICAL_PADDING);
            expect(_clamped_top.y).toBe(CAMERA_HOME_Y - PLAYFIELD_HALF_HEIGHT + PLAYFIELD_VERTICAL_PADDING);
            expect(_drag_target).toBe(CAMERA_HOME_X + CAMERA_DRAG_LIMIT);
            expect(_layout.left_panel_right).toBe(_layout.playfield_left);
            expect(_layout.right_panel_left).toBe(_layout.playfield_right);
            expect(_layout.meter_left).toBeGreaterThan(_layout.playfield_right);
        });

        test("Player movement keeps diagonal and focus speeds controlled", function() {
            var _straight_input = GameGameplayInputSnapshotCreate();
            var _diagonal_input = GameGameplayInputSnapshotCreate();
            var _focus_input = GameGameplayInputSnapshotCreate();

            _straight_input.right_down = true;
            _diagonal_input.right_down = true;
            _diagonal_input.down_down = true;
            _focus_input.right_down = true;
            _focus_input.down_down = true;
            _focus_input.focus_down = true;

            var _straight = GamePlayerMovementDeltaCreate(_straight_input);
            var _diagonal = GamePlayerMovementDeltaCreate(_diagonal_input);
            var _focused_diagonal = GamePlayerMovementDeltaCreate(_focus_input);

            expect(_straight.x).toBe(PLAYER_MOVE_SPEED);
            expect(_straight.y).toBe(0);
            expect(point_distance(0, 0, _diagonal.x, _diagonal.y)).toBeLessThan(PLAYER_MOVE_SPEED + 0.01);
            expect(point_distance(0, 0, _diagonal.x, _diagonal.y)).toBeGreaterThan(PLAYER_MOVE_SPEED - 0.01);
            expect(point_distance(0, 0, _focused_diagonal.x, _focused_diagonal.y)).toBeLessThan((PLAYER_MOVE_SPEED * PLAYER_FOCUS_SPEED_MULTIPLIER) + 0.01);
            expect(point_distance(0, 0, _focused_diagonal.x, _focused_diagonal.y)).toBeGreaterThan((PLAYER_MOVE_SPEED * PLAYER_FOCUS_SPEED_MULTIPLIER) - 0.01);
        });

        test("One volley tick creates twelve player shots with the intended direction and sprite split", function() {
            var _shots = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SUNRISE, false, 0);
            var _count_80 = 0;
            var _count_90 = 0;
            var _count_100 = 0;
            var _count_front_sprite = 0;
            var _count_side_sprite = 0;

            for (var i = 0; i < array_length(_shots); i++) {
                switch (_shots[i].direction) {
                    case 80:
                        _count_80 += 1;
                        break;

                    case 90:
                        _count_90 += 1;
                        break;

                    case 100:
                        _count_100 += 1;
                        break;
                }

                if (_shots[i].sprite_id == spr_sunrise_bullet) {
                    _count_front_sprite += 1;
                }

                if (_shots[i].sprite_id == spr_sunset_bullet) {
                    _count_side_sprite += 1;
                }
            }

            expect(array_length(_shots)).toBe(12);
            expect(_count_80).toBe(2);
            expect(_count_90).toBe(8);
            expect(_count_100).toBe(2);
            expect(_shots[0].speed).toBe(SHOT_SPEED);
            expect(_shots[0].sprite_id).toBe(spr_sunset_bullet);
            expect(_shots[4].sprite_id).toBe(spr_sunrise_bullet);
            expect(_count_front_sprite).toBe(8);
            expect(_count_side_sprite).toBe(4);
        });

        test("Selkie normal spread is wider while focused fire becomes a tighter lance", function() {
            var _normal = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SELKIE, false, 0);
            var _focused = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SELKIE, true, PLAYER_POWER_MAX);
            var _normal_min = 999;
            var _normal_max = -999;
            var _focused_min = 999;
            var _focused_max = -999;
            var _focused_damage = 0;

            for (var i = 0; i < array_length(_normal); i++) {
                _normal_min = min(_normal_min, _normal[i].direction);
                _normal_max = max(_normal_max, _normal[i].direction);
            }

            for (var j = 0; j < array_length(_focused); j++) {
                _focused_min = min(_focused_min, _focused[j].direction);
                _focused_max = max(_focused_max, _focused[j].direction);
                _focused_damage = max(_focused_damage, _focused[j].damage);
            }

            expect(array_length(_normal)).toBe(10);
            expect(array_length(_focused)).toBe(12);
            expect(_normal_min).toBeLessThan(70);
            expect(_normal_max).toBeGreaterThan(110);
            expect(_focused_min).toBeGreaterThan(84);
            expect(_focused_max).toBeLessThan(96);
            expect(_focused_damage).toBeGreaterThan(PLAYER_SHOT_DAMAGE + 2);
        });

        test("Playable Selkie uses the boss ship art flipped forward", function() {
            expect(GamePlayerShipSpriteGet(SHIP_SELKIE)).toBe(spr_sunset);
            expect(GamePlayerShipNameGet(SHIP_SELKIE)).toBe("Sunrise");
            expect(GamePlayerShipNameGet(SHIP_SUNRISE)).toBe("Sunset");
            expect(GamePlayerShipDrawScaleYGet(SHIP_SELKIE)).toBe(-1);
            expect(GamePlayerShipDrawScaleYGet(SHIP_SUNRISE)).toBe(1);
        });

        test("Shot power tiers give Moon and Selkie distinct color ramps", function() {
            var _moon_low = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SUNRISE, false, 0);
            var _moon_mid = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SUNRISE, false, 3);
            var _moon_high = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SUNRISE, false, PLAYER_POWER_MAX);
            var _selkie_low = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SELKIE, false, 0);
            var _selkie_mid = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SELKIE, false, 3);
            var _selkie_high = GamePlayerShotSpawnSpecsCreate(100, 100, SHIP_SELKIE, false, PLAYER_POWER_MAX);

            expect(_moon_low[0].color).toBe(make_color_rgb(94, 188, 255));
            expect(_moon_mid[0].color).toBe(make_color_rgb(255, 208, 112));
            expect(_moon_high[0].color).toBe(make_color_rgb(255, 118, 48));
            expect(_selkie_low[0].color).toBe(make_color_rgb(158, 92, 255));
            expect(_selkie_mid[0].color).toBe(make_color_rgb(232, 104, 246));
            expect(_selkie_high[0].color).toBe(make_color_rgb(255, 118, 208));
            expect(_moon_high[0].scale).toBeGreaterThan(_moon_low[0].scale);
            expect(_selkie_high[0].scale).toBeGreaterThan(_selkie_low[0].scale);
        });

        test("Autofire follows the independent focus switch", function() {
            var _normal_state = GamePlayerStateCreate();
            var _focused_state = GamePlayerStateCreate();
            var _normal_input = GameGameplayInputSnapshotCreate();
            var _focused_input = GameGameplayInputSnapshotCreate();
            _normal_input.autofire_down = true;
            _focused_input.autofire_down = true;
            _focused_input.focus_down = true;
            _normal_state.volley_timer = SHOT_VOLLEY_INTERVAL - 1;
            _focused_state.volley_timer = SHOT_VOLLEY_INTERVAL - 1;

            var _normal_result = GamePlayerFireStep(_normal_state, _normal_input);
            var _focused_result = GamePlayerFireStep(_focused_state, _focused_input);

            expect(_normal_result.spawn_shots).toBeTruthy();
            expect(_normal_result.focused_attack).toBeFalsy();
            expect(_focused_result.spawn_shots).toBeTruthy();
            expect(_focused_result.focused_attack).toBeTruthy();
            expect(_focused_state.volley_queue).toBe(SHOT_VOLLEY_SIZE - 1);
        });

        test("Held fire sustains volleys until the sword wind-up takes over", function() {
            var _state = GamePlayerStateCreate();
            var _input = GameGameplayInputSnapshotCreate();
            var _shot_count = 0;
            var _last_shot_frame = -1;
            var _max_shot_gap = 0;
            var _sword_frame = -1;

            for (var frame = 0; frame < FIRE_HOLD_FRAMES + 8; frame++) {
                _input.fire_down = true;
                _input.fire_pressed = (frame == 0);

                var _result = GamePlayerFireStep(_state, _input);

                if (_result.spawn_shots) {
                    if (_last_shot_frame >= 0) {
                        _max_shot_gap = max(_max_shot_gap, frame - _last_shot_frame);
                    }

                    _last_shot_frame = frame;
                    _shot_count += 1;
                }

                if (_result.sword_active && _sword_frame < 0) {
                    _sword_frame = frame;
                }
            }

            expect(_shot_count).toBeGreaterThan(10);
            expect(_max_shot_gap).toBeLessThan(SHOT_VOLLEY_INTERVAL + 1);
            expect(_sword_frame).toBe(FIRE_HOLD_FRAMES - 1);
        });

        test("Focused autofire does not accidentally charge the sword", function() {
            var _state = GamePlayerStateCreate();
            var _input = GameGameplayInputSnapshotCreate();
            var _shot_count = 0;
            var _sword_count = 0;

            for (var frame = 0; frame < FIRE_HOLD_FRAMES + 20; frame++) {
                _input.fire_down = true;
                _input.fire_pressed = (frame == 0);
                _input.autofire_down = true;
                _input.focus_down = true;

                var _result = GamePlayerFireStep(_state, _input);

                if (_result.spawn_shots) {
                    _shot_count += 1;
                    expect(_result.focused_attack).toBeTruthy();
                }

                if (_result.sword_active) {
                    _sword_count += 1;
                }
            }

            expect(_shot_count).toBeGreaterThan(10);
            expect(_sword_count).toBe(0);
            expect(_state.fire_hold_frames).toBe(0);
        });

        test("Power-up rewards apply stock, power, score, and meter effects", function() {
            global.game_runtime.bombs = DEFAULT_BOMBS;
            global.game_runtime.lives = DEFAULT_LIVES;
            global.game_runtime.score = 1234;
            var _resource_score = global.game_runtime.score;

            expect(GamePowerupRewardApply(POWERUP_POWER)).toBeTruthy();
            expect(global.game_runtime.power).toBe(1);

            expect(GamePowerupRewardApply(POWERUP_BOMB)).toBeTruthy();
            expect(global.game_runtime.bombs).toBe(DEFAULT_BOMBS + 1);

            expect(GamePowerupRewardApply(POWERUP_LIFE)).toBeTruthy();
            expect(global.game_runtime.lives).toBe(DEFAULT_LIVES + 1);

            expect(GamePowerupRewardApply(POWERUP_METER)).toBeTruthy();
            expect(global.game_runtime.meter).toBe(POWERUP_METER_VALUE);
            expect(global.game_runtime.score).toBe(_resource_score);

            var _score_before = global.game_runtime.score;
            expect(GamePowerupRewardApply(POWERUP_SCORE)).toBeTruthy();
            expect(global.game_runtime.score).toBe(_score_before + POWERUP_SCORE_VALUE);
        });

        test("Every power-up type has a dedicated pixel-art icon", function() {
            expect(GamePowerupSpriteGet(POWERUP_POWER)).toBe(spr_powerup_power);
            expect(GamePowerupSpriteGet(POWERUP_BOMB)).toBe(spr_powerup_bomb);
            expect(GamePowerupSpriteGet(POWERUP_LIFE)).toBe(spr_powerup_life);
            expect(GamePowerupSpriteGet(POWERUP_METER)).toBe(spr_powerup_meter);
            expect(GamePowerupSpriteGet(POWERUP_SCORE)).toBe(spr_powerup_score);
        });

        test("Defeat cadence drops bounded resources while ordinary cadence drops score", function() {
            with (obj_powerup) {
                instance_destroy();
            }

            var _resource = noone;
            var _threshold = GameResourceDropDefeatPeriodGet(1);

            for (var i = 0; i < _threshold; i++) {
                _resource = GameEnemyPowerupDropTry(400, 300, 1200);
            }

            expect(instance_exists(_resource)).toBeTruthy();
            expect(variable_instance_get(_resource, "pickup_class")).toBe("resource");
            expect(variable_instance_get(_resource, "powerup_type") == POWERUP_SCORE).toBeFalsy();
            expect(global.game_runtime.resource_drops_this_stage).toBe(1);
            expect(global.game_runtime.resource_drop_charge).toBe(0);

            with (obj_powerup) {
                instance_destroy();
            }

            global.game_runtime.powerup_drop_counter = GameScorePickupDropPeriodGet(1) - 1;
            var _score_pickup = GameEnemyPowerupDropTry(400, 300, 500);

            expect(instance_exists(_score_pickup)).toBeTruthy();
            expect(variable_instance_get(_score_pickup, "pickup_class")).toBe("score");
            expect(variable_instance_get(_score_pickup, "powerup_type")).toBe(POWERUP_SCORE);

            with (obj_powerup) {
                instance_destroy();
            }
        });

        test("Small and large enemies drop spread Berserk medals in their authored ranges", function() {
            with (obj_medal) { instance_destroy(); }

            expect(GameEnemyMedalDropCountGet("chaser", 900, 0)).toBe(1);
            expect(GameEnemyMedalDropCountGet("lancer", 1100, 1)).toBe(2);
            expect(GameEnemyMedalDropCountGet("dancer", 1400, 0)).toBe(5);
            expect(GameEnemyMedalDropCountGet("anchor", 1700, 2)).toBe(10);
            expect(GameBossPhaseMedalDropCountGet(1, 0)).toBeGreaterThan(4);
            expect(GameBossPhaseMedalDropCountGet(5, 14)).toBeLessThan(11);

            expect(GameMedalsSpawnSpread(100, 100, 7)).toBe(7);
            expect(instance_number(obj_medal)).toBe(7);
            var _medal = instance_find(obj_medal, 0);
            expect(variable_instance_get(_medal, "launch_timer")).toBeGreaterThan(0);
            expect(variable_instance_get(_medal, "meter_value")).toBe(ENEMY_MEDAL_BERSERK_GAIN);

            with (obj_medal) { instance_destroy(); }
        });

        test("Holding fire long enough switches the player from volleys into sword swings", function() {
            var _state = GamePlayerStateCreate();
            var _input = GameGameplayInputSnapshotCreate();

            _state.fire_hold_frames = FIRE_HOLD_FRAMES;
            _input.fire_down = true;

            var _result = GamePlayerFireStep(_state, _input);

            expect(_result.sword_active).toBeTruthy();
            expect(_result.spawn_shots).toBeFalsy();
            expect(_result.current_pose.moving || _result.current_pose.angle == SWORD_START_ANGLE
                || _result.current_pose.angle == SWORD_END_ANGLE).toBeTruthy();
            expect(GamePlayerSwordPoseCreate(SWEEP_PERIOD_FRAMES * 0.5, false).angle mod 360).toBe(225);
            expect(GamePlayerSwordPeriodFramesGet(false)).toBeGreaterThan(30);
            expect(GamePlayerSwordPeriodFramesGet(true)).toBeLessThan(GamePlayerSwordPeriodFramesGet(false));
        });

        test("One sword sweep deals boosted damage only once per target", function() {
            var _state = GamePlayerStateCreate();
            var _enemy = instance_create_layer(0, 0, "Instances", obj_enemy_turret);
            var _first_sweep = 0;
            var _same_sweep = 0;
            var _second_sweep = 0;

            with (_enemy) {
                event_perform(ev_create, 0);
                hp = 50;
            }

            _first_sweep = GamePlayerSwordSweepIdStep(_state,
                { moving: false, angle: SWORD_START_ANGLE, length: SWORD_LENGTH },
                { moving: true, angle: SWORD_START_ANGLE + 10, length: SWORD_LENGTH });
            _same_sweep = GamePlayerSwordSweepIdStep(_state,
                { moving: true, angle: SWORD_START_ANGLE + 10, length: SWORD_LENGTH },
                { moving: true, angle: SWORD_START_ANGLE + 20, length: SWORD_LENGTH });

            expect(_first_sweep).toBe(1);
            expect(_same_sweep).toBe(1);
            expect(SWORD_SWEEP_DAMAGE).toBeGreaterThan(PLAYER_SHOT_DAMAGE * 100);
            expect(GamePlayerSwordDamageTryApply(_enemy, _first_sweep)).toBeTruthy();
            expect(variable_instance_get(_enemy, "hp")).toBe(50 - SWORD_SWEEP_DAMAGE);
            expect(GamePlayerSwordDamageTryApply(_enemy, _first_sweep)).toBeFalsy();
            expect(variable_instance_get(_enemy, "hp")).toBe(50 - SWORD_SWEEP_DAMAGE);

            _second_sweep = GamePlayerSwordSweepIdStep(_state,
                { moving: false, angle: SWORD_END_ANGLE, length: SWORD_LENGTH },
                { moving: true, angle: SWORD_END_ANGLE - 10, length: SWORD_LENGTH });

            expect(_second_sweep).toBe(2);
            expect(GamePlayerSwordDamageTryApply(_enemy, _second_sweep)).toBeTruthy();
            expect(variable_instance_get(_enemy, "hp")).toBe(50 - (SWORD_SWEEP_DAMAGE * 2));

            with (_enemy) {
                instance_destroy();
            }
        });

        test("Expanded boss phases normalize damage without overstaying their attack cadence", function() {
            var _boss = instance_create_layer(0, 0, "Instances", obj_boss_parent);
            var _phase_count = GameBossPhaseCountForStage(STAGE_COUNT);
            var _phase_hp = GameBossPhaseHpGet(STAGE_COUNT, _phase_count);
            var _scale = GameBossDamageScaleGet(_phase_count);
            var _fastest_clear_frames = ceil(_phase_hp / (60 * _scale)) * SHOT_VOLLEY_INTERVAL;

            with (_boss) {
                phase_count = FINAL_BOSS_PHASE_COUNT;
                phase_max_hp = _phase_hp;
                hp = _phase_hp;
            }

            expect(_phase_hp).toBeGreaterThan(200);
            expect(_scale).toBe(BOSS_DAMAGE_SCALE_MIN);
            expect(_fastest_clear_frames).toBeGreaterThan(6 * 60);
            expect(_fastest_clear_frames).toBeLessThan(10 * 60);
            expect(GameBossDamageApply(_boss, 60)).toBe(60 * BOSS_DAMAGE_SCALE_MIN);
            expect(variable_instance_get(_boss, "hp")).toBe(_phase_hp - (60 * BOSS_DAMAGE_SCALE_MIN));

            with (_boss) {
                instance_destroy();
            }
        });

        test("Five consolidated stages end with the ordered character encounters", function() {
            var _shalmii = GameBossEncounterInfoCreate(1, SHIP_SUNRISE);
            var _aster = GameBossEncounterInfoCreate(2, SHIP_SUNRISE);
            var _duet = GameBossEncounterInfoCreate(3, SHIP_SUNRISE);
            var _mira = GameDualBossIdentityCreate("mira");
            var _aisha = GameDualBossIdentityCreate("aisha");
            var _caelia = GameBossEncounterInfoCreate(4, SHIP_SUNRISE);
            var _moon_route = GameBossEncounterInfoCreate(STAGE_COUNT, SHIP_SUNRISE);
            var _selkie_route = GameBossEncounterInfoCreate(STAGE_COUNT, SHIP_SELKIE);

            expect(STAGE_COUNT).toBe(5);
            expect(_shalmii.display_name).toBe(SHALMII_BOSS_NAME);
            expect(_shalmii.sprite_id).toBe(spr_shalmii_ship);
            expect(array_length(_shalmii.phase_plan)).toBe(3);
            expect(_aster.display_name).toBe(ASTER_BOSS_NAME);
            expect(_aster.sprite_id).toBe(spr_aster_ship);
            expect(array_length(_aster.phase_plan)).toBe(5);
            expect(_duet.display_name).toBe("Mira & Aisha");
            expect(_duet.is_dual).toBeTruthy();
            expect(_mira.display_name).toBe(MIRA_BOSS_NAME);
            expect(_mira.sprite_id).toBe(spr_mira_ship);
            expect(_aisha.display_name).toBe(AISHA_BOSS_NAME);
            expect(_aisha.sprite_id).toBe(spr_aisha_ship);
            expect(array_length(_mira.phase_plan)).toBe(3);
            expect(array_length(_aisha.phase_plan)).toBe(3);
            expect(_caelia.display_name).toBe(CAELIA_BOSS_NAME);
            expect(_caelia.sprite_id).toBe(spr_caelia_ship);
            expect(array_length(_caelia.phase_plan)).toBe(7);
            expect(_moon_route.is_final).toBeTruthy();
            expect(_moon_route.is_character).toBeTruthy();
            expect(_moon_route.opponent_ship_id).toBe(SHIP_SELKIE);
            expect(_moon_route.display_name).toBe("Selkie");
            expect(_moon_route.ship_name).toBe("Sunrise");
            expect(_moon_route.sprite_id).toBe(spr_sunset);
            expect(_moon_route.draw_y_scale).toBe(1);
            expect(_selkie_route.is_final).toBeTruthy();
            expect(_selkie_route.is_character).toBeTruthy();
            expect(_selkie_route.opponent_ship_id).toBe(SHIP_SUNRISE);
            expect(_selkie_route.display_name).toBe("Moon");
            expect(_selkie_route.ship_name).toBe("Sunset");
            expect(_selkie_route.sprite_id).toBe(spr_sunrise);
            expect(_selkie_route.draw_y_scale).toBe(-1);
        });

        test("Mira and Aisha unlock one shared finale only after both personal defeats", function() {
            with (obj_boss_parent) {
                instance_destroy();
            }

            var _mira = instance_create_layer(250, 80, "Instances", obj_boss_parent);
            var _aisha = instance_create_layer(390, 80, "Instances", obj_boss_parent);
            GameBossDualConfigure(_mira, "mira");
            GameBossDualConfigure(_aisha, "aisha");

            expect(GameBossDualIndividualDefeatBegin(_mira)).toBeFalsy();
            expect(_mira.dual_individual_defeated).toBeTruthy();
            expect(_mira.dual_finale_active).toBeFalsy();
            expect(_aisha.dual_individual_defeated).toBeFalsy();

            expect(GameBossDualIndividualDefeatBegin(_aisha)).toBeTruthy();
            expect(_mira.dual_finale_active).toBeTruthy();
            expect(_aisha.dual_finale_active).toBeTruthy();
            expect(_mira.phase_count).toBe(1);
            expect(_aisha.phase_count).toBe(1);
            expect(_mira.boss_identity.phase_plan[0].shot_kind).toBe("sisters_grand_illusion");
            expect(_aisha.boss_identity.phase_plan[0].attack_theme).toBe("sisters");

            _mira.phase_transition_timer = 0;
            _aisha.phase_transition_timer = 0;
            _mira.hp = _mira.phase_max_hp;
            _aisha.hp = _aisha.phase_max_hp;
            var _shared_hp = _mira.hp;
            expect(GameBossDamageApply(_mira, 40)).toBe(40);
            expect(_mira.hp).toBe(_shared_hp - 40);
            expect(_aisha.hp).toBe(_shared_hp - 40);

            with (_mira) {
                instance_destroy();
            }
            with (_aisha) {
                instance_destroy();
            }
        });

        test("Consolidated boss plans preserve each character's original motif source", function() {
            var _expected = [
                { stage: 1, source: 5, count: 3, first: "shalmii_hex_runes" },
                { stage: 2, source: 7, count: 5, first: "aster_ribbon_loop" },
                { stage: 4, source: 9, count: 7, first: "caelia_planetary_orbit" },
            ];

            for (var i = 0; i < array_length(_expected); i++) {
                var _entry = _expected[i];
                var _boss = GameBossEncounterInfoCreate(_entry.stage, SHIP_SUNRISE);
                expect(array_length(_boss.phase_plan)).toBe(_entry.count);
                expect(_boss.phase_plan[0].id).toBe(_entry.first);
                expect(string_pos("_finale", _boss.phase_plan[_entry.count - 1].id)).toBeGreaterThan(0);
            }

            expect(GameStageLegacyPatternStageGet(1, 0)).toBe(1);
            expect(GameStageLegacyPatternStageGet(1, STAGE_LENGTH_FRAMES - 1)).toBe(2);
            expect(GameStageLegacyPatternStageGet(2, 0)).toBe(3);
            expect(GameStageLegacyPatternStageGet(2, STAGE_LENGTH_FRAMES - 1)).toBe(4);
            expect(GameStageLegacyPatternStageGet(3, 0)).toBe(5);
            expect(GameStageLegacyPatternStageGet(3, STAGE_LENGTH_FRAMES - 1)).toBe(7);
            expect(GameStageLegacyPatternStageGet(4, 0)).toBe(8);
            expect(GameStageLegacyPatternStageGet(4, STAGE_LENGTH_FRAMES - 1)).toBe(9);
            expect(GameStageLegacyPatternStageGet(5, 0)).toBe(10);
        });

        test("Character bosses use motif-specific seed families and finales", function() {
            var _motifs = [
                { stage: 2, theme: "casino", first: "mira_three_card_monte", finale: "mira_house_always_wins" },
                { stage: 5, theme: "rune", first: "shalmii_hex_runes", finale: "shalmii_runebreaker" },
                { stage: 6, theme: "sorcery", first: "aisha_arcane_circle", finale: "aisha_grand_sorcery" },
                { stage: 7, theme: "ribbon", first: "aster_ribbon_loop", finale: "aster_ribbonstar_wish" },
                { stage: 9, theme: "astral", first: "caelia_planetary_orbit", finale: "caelia_cosmic_zenith" },
            ];

            for (var motif_index = 0; motif_index < array_length(_motifs); motif_index++) {
                var _motif = _motifs[motif_index];
                var _seeds = GameMemoryCoreBasePhasePlanCreate(_motif.stage);
                var _finale = GameMemoryCoreFinalPhaseCreate(_motif.stage);

                expect(_seeds[0].id).toBe(_motif.first);
                expect(_finale.shot_kind).toBe(_motif.finale);
                expect(_finale.attack_theme).toBe(_motif.theme);

                for (var seed_index = 0; seed_index < array_length(_seeds); seed_index++) {
                    expect(_seeds[seed_index].attack_theme).toBe(_motif.theme);
                }
            }
        });

        test("Final bosses cap at fifteen phases with route-exclusive finales", function() {
            var _selkie_final = GameBossEncounterInfoCreate(STAGE_COUNT, SHIP_SUNRISE);
            var _moon_final = GameBossEncounterInfoCreate(STAGE_COUNT, SHIP_SELKIE);
            var _selkie_seeds = GameFinalBossBasePhasePlanCreate(SHIP_SELKIE);
            var _moon_seeds = GameFinalBossBasePhasePlanCreate(SHIP_SUNRISE);
            var _selkie_phase_ids = [];
            var _moon_phase_ids = [];

            expect(array_length(_selkie_final.phase_plan)).toBe(15);
            expect(array_length(_moon_final.phase_plan)).toBe(15);
            expect(_selkie_final.phase_signature == _moon_final.phase_signature).toBeFalsy();

            for (var seed = 0; seed < 5; seed++) {
                expect(_selkie_final.phase_plan[seed].id).toBe(_selkie_seeds[seed].id);
                expect(_selkie_final.phase_plan[seed + 5].id).toBe(_selkie_seeds[seed].id + "_v1");
                expect(_moon_final.phase_plan[seed].id).toBe(_moon_seeds[seed].id);
                expect(_moon_final.phase_plan[seed + 5].id).toBe(_moon_seeds[seed].id + "_v1");

                if (seed < 4) {
                    expect(_selkie_final.phase_plan[seed + 10].id).toBe(_selkie_seeds[seed].id + "_v2");
                    expect(_moon_final.phase_plan[seed + 10].id).toBe(_moon_seeds[seed].id + "_v2");
                }
            }

            expect(_selkie_final.phase_plan[14].id).toBe("selkie_chakram_apotheosis_finale");
            expect(_moon_final.phase_plan[14].id).toBe("moon_rose_eternity_finale");

            for (var i = 0; i < 15; i++) {
                expect(_selkie_final.phase_plan[i].attack_theme).toBe("chakram");
                expect(_moon_final.phase_plan[i].attack_theme).toBe("rose");

                for (var s = 0; s < array_length(_selkie_phase_ids); s++) {
                    expect(_selkie_final.phase_plan[i].id == _selkie_phase_ids[s]).toBeFalsy();
                }

                for (var m = 0; m < array_length(_moon_phase_ids); m++) {
                    expect(_moon_final.phase_plan[i].id == _moon_phase_ids[m]).toBeFalsy();
                }

                array_push(_selkie_phase_ids, _selkie_final.phase_plan[i].id);
                array_push(_moon_phase_ids, _moon_final.phase_plan[i].id);
            }
        });

        test("Boss phase titles format descriptor ids and remain visible for two seconds", function() {
            var _seed = GameMemoryCorePhaseCreate(
                "tideglass_spiral", "blade_spiral", 24, 10, 0, 19, 0, 12, 1.55, 0);
            var _variant = GameBossPhaseVariantCreate(_seed, 1);
            var _finale = GameMemoryCoreFinalPhaseCreate(9);

            expect(GameBossPhaseDisplayNameGet(_seed)).toBe("Tideglass Spiral");
            expect(GameBossPhaseDisplayNameGet(_variant)).toBe("Tideglass Spiral - Variant 1");
            expect(GameBossPhaseDisplayNameGet(_finale)).toBe("Cosmic Zenith");
            expect(GameBossPhaseDisplayNameGet({})).toBe("Boss Attack");
            expect(GameBossPhaseNoticeAlphaGet(0)).toBe(0);
            expect(GameBossPhaseNoticeAlphaGet(BOSS_PHASE_NOTICE_FADE_IN_FRAMES)).toBe(1);
            expect(GameBossPhaseNoticeAlphaGet(BOSS_PHASE_NOTICE_FRAMES - BOSS_PHASE_NOTICE_FADE_OUT_FRAMES)).toBe(1);
            expect(GameBossPhaseNoticeAlphaGet(BOSS_PHASE_NOTICE_FRAMES - 15)).toBe(0.5);
            expect(GameBossPhaseNoticeAlphaGet(BOSS_PHASE_NOTICE_FRAMES)).toBe(0);
        });

        test("Every configured boss shot kind has a live runtime interpreter", function() {
            global.game_runtime.current_stage = 1;
            var _boss = instance_create_layer(100, 100, "Instances", obj_boss_sunset);
            var _plans = [];
            var _seen_kinds = [];

            for (var stage = 1; stage < LEGACY_STAGE_COUNT; stage++) {
                array_push(_plans, GameMemoryCorePhasePlanCreate(stage));
            }

            array_push(_plans, GameFinalBossPhasePlanCreate(SHIP_SUNRISE));
            array_push(_plans, GameFinalBossPhasePlanCreate(SHIP_SELKIE));

            for (var plan_index = 0; plan_index < array_length(_plans); plan_index++) {
                var _plan = _plans[plan_index];

                for (var phase_index = 0; phase_index < array_length(_plan); phase_index++) {
                    var _phase = _plan[phase_index];
                    var _already_seen = false;

                    for (var seen = 0; seen < array_length(_seen_kinds); seen++) {
                        if (_seen_kinds[seen] == _phase.shot_kind) {
                            _already_seen = true;
                            break;
                        }
                    }

                    if (_already_seen) {
                        continue;
                    }

                    array_push(_seen_kinds, _phase.shot_kind);
                    expect(GameBossPhasePatternFire(_boss, _phase, _phase.cadence, 100, 260, 0)).toBeTruthy();
                    expect(instance_number(obj_bullet_parent)).toBeGreaterThan(0);

                    with (obj_bullet_parent) {
                        instance_destroy();
                    }
                }
            }

            expect(array_length(_seen_kinds)).toBe(49);

            with (_boss) {
                instance_destroy();
            }
        });

        test("Radial blade families and aimed fans produce distinct geometries", function() {
            global.game_runtime.current_stage = 1;
            var _boss = instance_create_layer(100, 100, "Instances", obj_boss_sunset);
            var _spiral = GameMemoryCorePhaseCreate(
                "test_spiral", "blade_spiral", 30, 8, 0, 11, 0, 10, 1.5, 0);
            var _redirect = GameMemoryCorePhaseCreate(
                "test_redirect", "redirect_spiral", 30, 8, 0, 11, 0, 10, 1.5, 80, 120);
            var _cross = GameMemoryCorePhaseCreate(
                "test_cross", "blade_cross", 30, 8, 0, 11, 0, 10, 1.5, 0);

            expect(GameBossPhasePatternFire(_boss, _spiral, 0, 100, 260, 0)).toBeTruthy();
            expect(instance_number(obj_bullet_blade)).toBe(8);

            var _spiral_clockwise = 0;
            var _spiral_offset = 0;

            for (var spiral_index = 0; spiral_index < instance_number(obj_bullet_blade); spiral_index++) {
                var _spiral_bullet = instance_find(obj_bullet_blade, spiral_index);

                if (variable_instance_get(_spiral_bullet, "spiral_direction") < 0) {
                    _spiral_clockwise += 1;
                }

                if (variable_instance_get(_spiral_bullet, "spiral_radius") > 0) {
                    _spiral_offset += 1;
                }
            }

            expect(_spiral_clockwise).toBe(8);
            expect(_spiral_offset).toBe(0);

            with (obj_bullet_blade) {
                instance_destroy();
            }

            _boss.pattern_clockwise_first = true;
            expect(GameBossPhasePatternFire(_boss, _redirect, 0, 100, 260, 0)).toBeTruthy();
            expect(instance_number(obj_bullet_blade)).toBe(8);

            var _redirect_clockwise = 0;
            var _redirect_offset = 0;

            for (var redirect_index = 0; redirect_index < instance_number(obj_bullet_blade); redirect_index++) {
                var _redirect_bullet = instance_find(obj_bullet_blade, redirect_index);

                if (variable_instance_get(_redirect_bullet, "spiral_direction") < 0) {
                    _redirect_clockwise += 1;
                }

                if (variable_instance_get(_redirect_bullet, "spiral_radius") > 0) {
                    _redirect_offset += 1;
                }
            }

            expect(_redirect_clockwise).toBe(4);
            expect(_redirect_offset).toBe(8);

            with (obj_bullet_blade) {
                instance_destroy();
            }

            _boss.pattern_clockwise_first = true;
            expect(GameBossPhasePatternFire(_boss, _cross, 0, 100, 260, 0)).toBeTruthy();
            expect(instance_number(obj_bullet_blade)).toBe(8);

            var _cross_inner = 0;
            var _cross_outer = 0;

            for (var cross_index = 0; cross_index < instance_number(obj_bullet_blade); cross_index++) {
                var _cross_bullet = instance_find(obj_bullet_blade, cross_index);

                if (variable_instance_get(_cross_bullet, "spiral_radius") == 0) {
                    _cross_inner += 1;
                } else {
                    _cross_outer += 1;
                }
            }

            expect(_cross_inner).toBe(4);
            expect(_cross_outer).toBe(4);

            with (obj_bullet_blade) {
                instance_destroy();
            }

            var _bead_arc = GameMemoryCorePhaseCreate(
                "test_bead_arc", "bead_arc", 30, 5, 0, 0, 3, 0, 0, 60);
            var _diamond_fan = GameMemoryCorePhaseCreate(
                "test_diamond_fan", "diamond_fan", 30, 5, 0, 0, 3, 0, 0, 60);
            expect(GameBossPhasePatternFire(_boss, _bead_arc, 0, 100, 260, 0)).toBeTruthy();
            expect(instance_number(obj_bullet_bead)).toBe(5);

            for (var bead_index = 0; bead_index < instance_number(obj_bullet_bead); bead_index++) {
                var _bead = instance_find(obj_bullet_bead, bead_index);
                expect(variable_instance_get(_bead, "move_speed")).toBe(3);
            }

            with (obj_bullet_bead) {
                instance_destroy();
            }

            expect(GameBossPhasePatternFire(_boss, _diamond_fan, 0, 100, 260, 0)).toBeTruthy();
            expect(instance_number(obj_bullet_diamond)).toBe(5);

            var _first_diamond_speed = undefined;
            var _diamond_speed_varies = false;

            for (var diamond_index = 0; diamond_index < instance_number(obj_bullet_diamond); diamond_index++) {
                var _diamond = instance_find(obj_bullet_diamond, diamond_index);
                var _diamond_speed = variable_instance_get(_diamond, "move_speed");

                if (_first_diamond_speed == undefined) {
                    _first_diamond_speed = _diamond_speed;
                } else if (_diamond_speed != _first_diamond_speed) {
                    _diamond_speed_varies = true;
                }
            }

            expect(_diamond_speed_varies).toBeTruthy();

            with (obj_bullet_diamond) {
                instance_destroy();
            }

            with (_boss) {
                instance_destroy();
            }
        });

        test("Only gap-safe pattern families receive restrained burst variance", function() {
            expect(GameBossPatternAngleVarianceGet("blade_spiral")).toBe(5);
            expect(GameBossPatternAngleVarianceGet("diamond_fan")).toBe(3);
            expect(GameBossPatternAngleVarianceGet("aisha_chaos_shards")).toBe(5);
            expect(GameBossPatternAngleVarianceGet("blade_cross")).toBe(0);
            expect(GameBossPatternAngleVarianceGet("caelia_star_cage")).toBe(0);
            expect(GameBossPatternAngleVarianceGet("kelp_wall")).toBe(0);
        });

        test("Redistributed Memory Core families give basic enemies different bullet mixes", function() {
            var _player = instance_create_layer(100, 260, "Instances", obj_player);

            with (_player) {
                event_perform(ev_create, 0);
                x = 100;
                y = 260;
            }

            var _anvil = instance_create_layer(100, 100, "Instances", obj_enemy_variant);
            GameEnemyVariantConfigure(_anvil, ENEMY_ANVIL_FAMILIAR, 1, 0, 1);
            with (_anvil) { fire_timer = 999; }
            simulateEvent(ev_step, ev_step_normal, _anvil);

            expect(instance_number(obj_bullet_blade)).toBeGreaterThan(0);
            expect(instance_number(obj_bullet_bead)).toBe(0);
            expect(instance_number(obj_bullet_diamond)).toBe(0);

            with (obj_bullet_parent) {
                instance_destroy();
            }

            with (_anvil) {
                instance_destroy();
            }

            var _dealer = instance_create_layer(100, 100, "Instances", obj_enemy_variant);
            GameEnemyVariantConfigure(_dealer, ENEMY_DEALER_MASK, 3, 0, 1);
            with (_dealer) { fire_timer = 999; }
            simulateEvent(ev_step, ev_step_normal, _dealer);

            expect(instance_number(obj_bullet_blade)).toBe(0);
            expect(instance_number(obj_bullet_bead)).toBe(0);
            expect(instance_number(obj_bullet_diamond)).toBeGreaterThan(0);

            with (obj_bullet_parent) {
                instance_destroy();
            }

            with (_dealer) {
                instance_destroy();
            }

            var _order = instance_create_layer(100, 100, "Instances", obj_enemy_variant);
            GameEnemyVariantConfigure(_order, ENEMY_ORDER_TALISMAN, 3, 0, 1);
            with (_order) { fire_timer = 999; }
            simulateEvent(ev_step, ev_step_normal, _order);

            expect(instance_number(obj_bullet_blade)).toBe(0);
            expect(instance_number(obj_bullet_bead)).toBeGreaterThan(0);
            expect(instance_number(obj_bullet_diamond)).toBe(0);

            with (obj_bullet_parent) { instance_destroy(); }
            with (_order) { instance_destroy(); }

            with (_player) {
                instance_destroy();
            }
        });

        test("Music routing selects character stages, guardian cues, and route-specific finales", function() {
            global.game_runtime.current_stage = 1;
            global.game_runtime.selected_ship_id = SHIP_SUNRISE;

            expect(GameMusicForRoomGet(rm_title)).toBe(snd_music_title);
            expect(GameMusicForRoomGet(rm_opening)).toBe(snd_music_title);
            expect(GameGameplayMusicTrackGet(1, "scroll", false, SHIP_SUNRISE)).toBe(snd_music_stage_shalmii);
            expect(GameGameplayMusicTrackGet(1, "boss_intro", false, SHIP_SUNRISE)).toBe(snd_music_boss_shalmii);
            expect(GameGameplayMusicTrackGet(1, "boss_fight", true, SHIP_SUNRISE)).toBe(snd_music_boss_shalmii);
            expect(GameGameplayMusicTrackGet(1, "stage_clear", true, SHIP_SUNRISE)).toBe(snd_music_boss_shalmii);
            expect(GameGameplayMusicTrackGet(1, "stage_clear", false, SHIP_SUNRISE)).toBe(snd_music_stage_shalmii);
            expect(GameMusicForRoomGet(rm_ending)).toBe(snd_music_ending);
            expect(GameMusicForRoomGet(rm_credits)).toBe(snd_music_credits);

            global.game_runtime.current_stage = STAGE_COUNT;

            expect(GameStageMusicTrackGet(STAGE_COUNT, SHIP_SUNRISE)).toBe(snd_music_stage_moon);
            expect(GameBossMusicTrackGet(STAGE_COUNT, SHIP_SUNRISE)).toBe(snd_music_boss_selkie);
            expect(GameStageMusicTrackGet(STAGE_COUNT, SHIP_SELKIE)).toBe(snd_music_stage_selkie);
            expect(GameBossMusicTrackGet(STAGE_COUNT, SHIP_SELKIE)).toBe(snd_music_boss_moon);

            var _music_assets = GameAudioMusicAssetsCreate();
            var _sfx_assets = GameAudioSfxAssetsCreate();
            expect(array_length(_music_assets)).toBe(26);
            expect(array_length(_sfx_assets)).toBe(15);
            expect(_music_assets[0]).toBe(snd_music_title);
            expect(_music_assets[1]).toBe(snd_music_stage_shalmii);
            expect(_sfx_assets[0]).toBe(snd_bomb);
        });

        test("Turret bead shots aim at the player and use the centered 8 px hit circle", function() {
            var _shot = GameTurretShotSpecCreate(100, 120, 100, 220);

            expect(_shot.object_index).toBe(obj_bullet_bead);
            expect(_shot.direction).toBe(270);
            expect(_shot.speed).toBe(TURRET_BULLET_SPEED);
            expect(GamePlayerBulletHitCheck(100, 100, 105, 100, 4)).toBeTruthy();
            expect(GamePlayerBulletHitCheck(100, 100, 106, 100, 4)).toBeFalsy();
        });

        test("Bee enemies make one pass toward a player below and fire three aligned diamond shots", function() {
            var _player = instance_create_layer(0, 0, "Instances", obj_player);
            var _bee = instance_create_layer(0, 0, "Instances", obj_enemy_bee);
            var _slow_count = 0;
            var _mid_count = 0;
            var _fast_count = 0;

            with (_player) {
                event_perform(ev_create, 0);
                x = 140;
                y = 100;
            }

            with (_bee) {
                event_perform(ev_create, 0);
                x = 100;
                y = 80;
                move_direction = 0;
                move_speed = BEE_MOVE_SPEED;
                fire_interval = BEE_FIRE_INTERVAL;
                fire_timer = BEE_FIRE_INTERVAL - 1;
            }

            simulateEvent(ev_step, ev_step_normal, _bee);

            expect(variable_instance_get(_bee, "sprite_index")).toBe(spr_bee);
            expect(variable_instance_get(_bee, "x")).toBe(101);
            expect(variable_instance_get(_bee, "y")).toBe(80);
            var _aim_direction = point_direction(101, 80, 140, 100);
            expect(variable_instance_get(_bee, "move_direction")).toBe(_aim_direction);
            expect(variable_instance_get(_bee, "image_angle")).toBe(_aim_direction);
            expect(variable_instance_get(_bee, "flyaway_committed")).toBeFalsy();
            expect(instance_number(obj_bullet_diamond)).toBe(3);

            for (var i = 0; i < instance_number(obj_bullet_diamond); i++) {
                var _bullet = instance_find(obj_bullet_diamond, i);
                var _speed = variable_instance_get(_bullet, "move_speed");
                var _direction = variable_instance_get(_bullet, "move_direction");

                expect(_direction).toBe(_aim_direction);

                if (_speed == BEE_BULLET_SPEED - BEE_BULLET_SPEED_DELTA) {
                    _slow_count += 1;
                }

                if (_speed == BEE_BULLET_SPEED) {
                    _mid_count += 1;
                }

                if (_speed == BEE_BULLET_SPEED + BEE_BULLET_SPEED_DELTA) {
                    _fast_count += 1;
                }
            }

            expect(_slow_count).toBe(1);
            expect(_mid_count).toBe(1);
            expect(_fast_count).toBe(1);

            with (obj_bullet_diamond) {
                instance_destroy();
            }

            with (_bee) {
                instance_destroy();
            }

            with (_player) {
                instance_destroy();
            }
        });

        test("Bees commit downward after passing the player and also leave when no player exists", function() {
            var _player = instance_create_layer(140, 100, "Instances", obj_player);
            var _bee = instance_create_layer(100, 100, "Instances", obj_enemy_bee);

            with (_player) {
                event_perform(ev_create, 0);
                x = 140;
                y = 100;
            }

            with (_bee) {
                event_perform(ev_create, 0);
                x = 100;
                y = 100;
                move_direction = 0;
                fire_timer = 0;
            }

            simulateEvent(ev_step, ev_step_normal, _bee);
            expect(variable_instance_get(_bee, "flyaway_committed")).toBeTruthy();
            expect(variable_instance_get(_bee, "move_direction")).toBe(270);

            with (_player) {
                y = 300;
            }
            simulateEvent(ev_step, ev_step_normal, _bee);
            expect(variable_instance_get(_bee, "flyaway_committed")).toBeTruthy();
            expect(variable_instance_get(_bee, "move_direction")).toBe(270);

            with (_player) { instance_destroy(); }

            var _orphan_bee = instance_create_layer(200, 120, "Instances", obj_enemy_bee);
            with (_orphan_bee) {
                event_perform(ev_create, 0);
                move_direction = 45;
                fire_timer = 0;
            }
            simulateEvent(ev_step, ev_step_normal, _orphan_bee);
            expect(variable_instance_get(_orphan_bee, "flyaway_committed")).toBeTruthy();
            expect(variable_instance_get(_orphan_bee, "move_direction")).toBe(270);

            with (_bee) { instance_destroy(); }
            with (_orphan_bee) { instance_destroy(); }
        });

        test("Enemy bullet artwork rotates to its movement direction", function() {
            var _bullet = instance_create_layer(40, 60, "Instances", obj_bullet_bead);
            with (_bullet) {
                move_direction = 37;
                move_speed = 3;
                image_angle = 0;
            }

            simulateEvent(ev_step, ev_step_normal, _bullet);
            expect(variable_instance_get(_bullet, "image_angle")).toBe(37);

            with (_bullet) { instance_destroy(); }
        });

        test("Mayfly bursts alternate spiral direction while dropping into the y=100 camera lane", function() {
            var _camera = instance_create_layer(CAMERA_HOME_X, CAMERA_HOME_Y, "Instances", obj_camera);
            var _visible_lane_y = CAMERA_HOME_Y - PLAYFIELD_HALF_HEIGHT + MAYFLY_VISIBLE_Y;
            var _mayfly = instance_create_layer(CAMERA_HOME_X, _visible_lane_y, "Instances", obj_enemy_mayfly);
            var _clockwise_count = 0;
            var _counter_count = 0;
            var _offset = GameMayflyInfinityOffsetCreate(90);
            var _primary = GameMayflyBurstStateCreate(0, true);
            var _secondary = GameMayflyBurstStateCreate(MAYFLY_SECOND_BURST_DELAY, true);
            var _ring = GameMayflyShotSpawnSpecsCreate(0, 0, true);
            var _stage_spawn = GameStageMayflySpawnPositionCreate(CAMERA_HOME_X, CAMERA_HOME_Y);
            var _dropping_mayfly = instance_create_layer(_stage_spawn.x, _stage_spawn.y, "Instances", obj_enemy_mayfly);

            with (_mayfly) {
                event_perform(ev_create, 0);
                float_phase = 0;
                fire_timer = 0;
                clockwise_first = true;
            }

            with (_dropping_mayfly) {
                event_perform(ev_create, 0);
                float_phase = 0;
                fire_timer = 1;
            }

            simulateEvent(ev_step, ev_step_normal, _mayfly);

            expect(_primary.fire).toBeTruthy();
            expect(_primary.clockwise).toBeTruthy();
            expect(_secondary.fire).toBeTruthy();
            expect(_secondary.clockwise).toBeFalsy();
            expect(variable_instance_get(_mayfly, "x")).toBe(CAMERA_HOME_X);
            expect(variable_instance_get(_mayfly, "y")).toBe(CAMERA_HOME_Y - PLAYFIELD_HALF_HEIGHT + MAYFLY_VISIBLE_Y);
            expect(variable_instance_get(_mayfly, "float_phase")).toBe(MAYFLY_FLOAT_RATE);
            expect(instance_number(obj_bullet_blade)).toBe(12);
            expect(_offset.x).toBe(MAYFLY_FLOAT_X_RADIUS);
            expect(round(_offset.y)).toBe(0);
            expect(_ring[0].spiral_angle).toBe(0);
            expect(_ring[3].spiral_angle).toBe(90);
            expect(_ring[11].spiral_angle).toBe(330);
            expect(GameMayflyTargetAnchorOffsetYGet()).toBe(-PLAYFIELD_HALF_HEIGHT + MAYFLY_VISIBLE_Y);

            for (var i = 0; i < instance_number(obj_bullet_blade); i++) {
                var _bullet = instance_find(obj_bullet_blade, i);

                if (variable_instance_get(_bullet, "spiral_direction") < 0) {
                    _clockwise_count += 1;
                } else {
                    _counter_count += 1;
                }
            }

            expect(_clockwise_count).toBe(12);
            expect(_counter_count).toBe(0);

            for (var step = 0; step < MAYFLY_SECOND_BURST_DELAY; step++) {
                simulateEvent(ev_step, ev_step_normal, _mayfly);
            }

            _clockwise_count = 0;
            _counter_count = 0;

            for (var i = 0; i < instance_number(obj_bullet_blade); i++) {
                var _bullet = instance_find(obj_bullet_blade, i);

                if (variable_instance_get(_bullet, "spiral_direction") < 0) {
                    _clockwise_count += 1;
                } else {
                    _counter_count += 1;
                }
            }

            expect(instance_number(obj_bullet_blade)).toBe(24);
            expect(_clockwise_count).toBe(12);
            expect(_counter_count).toBe(12);

            with (obj_bullet_blade) {
                instance_destroy();
            }

            with (_mayfly) {
                instance_destroy();
            }

            for (var drop_step = 0; drop_step < 80; drop_step++) {
                simulateEvent(ev_step, ev_step_normal, _dropping_mayfly);
            }

            expect(variable_instance_get(_dropping_mayfly, "anchor_offset_y")).toBe(GameMayflyTargetAnchorOffsetYGet());

            with (obj_bullet_blade) {
                instance_destroy();
            }

            with (_dropping_mayfly) {
                instance_destroy();
            }

            with (_camera) {
                instance_destroy();
            }
        });

        test("Blade bullets spiral outward from their spawn point in either rotation direction", function() {
            var _counter = instance_create_layer(0, 0, "Instances", obj_bullet_blade);
            var _clockwise = instance_create_layer(0, 0, "Instances", obj_bullet_blade);

            with (_counter) {
                event_perform(ev_create, 0);
                spiral_origin_x = 0;
                spiral_origin_y = 0;
                spiral_radius = 0;
                spiral_angle = 0;
                spiral_turn_speed = 90;
                spiral_radial_speed = 2;
                spiral_direction = 1;
            }

            with (_clockwise) {
                event_perform(ev_create, 0);
                spiral_origin_x = 0;
                spiral_origin_y = 0;
                spiral_radius = 0;
                spiral_angle = 0;
                spiral_turn_speed = 90;
                spiral_radial_speed = 2;
                spiral_direction = -1;
            }

            simulateEvent(ev_step, ev_step_normal, _counter);
            simulateEvent(ev_step, ev_step_normal, _clockwise);

            expect(variable_instance_get(_counter, "x")).toBeGreaterThan(1);
            expect(variable_instance_get(_counter, "y")).toBeLessThan(0);
            expect(variable_instance_get(_clockwise, "x")).toBeGreaterThan(1);
            expect(variable_instance_get(_clockwise, "y")).toBeGreaterThan(0);
            expect(point_distance(0, 0,
                variable_instance_get(_counter, "x"),
                variable_instance_get(_counter, "y"))).toBeLessThan(BLADE_MAX_SCREEN_SPEED + 0.01);
            expect(point_distance(0, 0,
                variable_instance_get(_clockwise, "x"),
                variable_instance_get(_clockwise, "y"))).toBeLessThan(BLADE_MAX_SCREEN_SPEED + 0.01);

            with (_counter) {
                instance_destroy();
            }

            with (_clockwise) {
                instance_destroy();
            }
        });

        test("Blade motion stays within a fair screen-space ceiling at outer radii", function() {
            var _near = GameBladeMotionStepCreate(0, 1.5, 12, 1);
            var _outer = GameBladeMotionStepCreate(180, 2.2, 23, 1);
            var _rank_zero = GameBladeMotionStepCreate(180, 2.2, 23,
                GameRankBulletSpeedScaleGet(RANK_MIN));

            expect(_near.screen_step).toBeLessThan(BLADE_MAX_SCREEN_SPEED + 0.001);
            expect(_outer.screen_step).toBeLessThan(BLADE_MAX_SCREEN_SPEED + 0.001);
            expect(_outer.turn_step).toBeLessThan(23 * BLADE_TURN_RATE_SCALE);
            expect(_outer.turn_step).toBeGreaterThan(0);
            expect(_rank_zero.radial_step).toBeLessThan(_outer.radial_step);
        });

        test("Redirected blades telegraph and cap their eventual travel speed", function() {
            var _blade = instance_create_layer(0, 0, "Instances", obj_bullet_blade);
            expect(GameBladeBulletRedirectMark(_blade, 1, 99, 1)).toBeTruthy();
            expect(variable_instance_get(_blade, "freeze_timer")).toBe(BOSS_PHASE3_FREEZE_FRAMES);
            var _redirect_screen_speed = variable_instance_get(_blade, "redirect_speed")
                * variable_instance_get(_blade, "rank_speed_scale");
            expect(_redirect_screen_speed).toBeLessThan(BLADE_REDIRECT_MAX_SCREEN_SPEED + 0.001);

            with (_blade) {
                instance_destroy();
            }
        });

        test("Boss helpers expose segmented life bars", function() {
            var _segments = GameBossBarSegmentsCreate(1, BOSS_PHASE_HP * 0.5, BOSS_PHASE_HP);

            expect(_segments[0]).toBe(0);
            expect(_segments[1]).toBe(0.5);
            expect(_segments[2]).toBe(1);
        });

        test("Boss phase hearts distinguish spent, active, and future patterns", function() {
            var _hearts = GameBossPhaseHeartStatesCreate(2, 5);

            expect(_hearts[0]).toBe(0);
            expect(_hearts[1]).toBe(0);
            expect(_hearts[2]).toBe(2);
            expect(_hearts[3]).toBe(1);
            expect(_hearts[4]).toBe(1);
        });

        test("Boss phase transitions refill health while damage is invulnerable", function() {
            with (obj_medal) { instance_destroy(); }
            var _boss = instance_create_layer(0, 0, "Instances", obj_boss_parent);
            with (_boss) {
                phase_count = 3;
                phase_index = 0;
                phase_max_hp = 600;
                hp = 0;
            }

            simulateEvent(ev_step, ev_step_normal, _boss);
            expect(variable_instance_get(_boss, "phase_index")).toBe(1);
            expect(variable_instance_get(_boss, "phase_transition_timer")).toBe(BOSS_PHASE_TRANSITION_FRAMES);
            expect(instance_number(obj_medal)).toBeGreaterThan(4);
            expect(instance_number(obj_medal)).toBeLessThan(11);
            expect(GameBossDamageApply(_boss, 100)).toBe(0);

            simulateEvent(ev_step, ev_step_normal, _boss);
            expect(variable_instance_get(_boss, "hp")).toBeGreaterThan(0);
            expect(variable_instance_get(_boss, "hp")).toBeLessThan(600);

            with (_boss) {
                instance_destroy();
            }
            with (obj_medal) { instance_destroy(); }
        });

        test("Boss intro combat clear removes enemies and bullets but keeps bosses and score unchanged", function() {
            var _enemy = instance_create_layer(0, 0, "Instances", obj_enemy_turret);
            var _bullet = instance_create_layer(0, 0, "Instances", obj_bullet_bead);
            var _boss = instance_create_layer(0, 0, "Instances", obj_boss_sunset);

            with (_enemy) {
                event_perform(ev_create, 0);
                points = 500;
            }

            with (_bullet) {
                event_perform(ev_create, 0);
            }

            with (_boss) {
                event_perform(ev_create, 0);
            }

            global.game_runtime.score = 0;
            GameSceneCombatClear();

            expect(instance_exists(_enemy)).toBeFalsy();
            expect(instance_exists(_bullet)).toBeFalsy();
            expect(instance_exists(_boss)).toBeTruthy();
            expect(global.game_runtime.score).toBe(0);

            with (_boss) {
                instance_destroy();
            }
        });

        test("Inherited child bullets keep parent defaults and child turrets keep parent step behavior", function() {
            with (obj_medal) { instance_destroy(); }
            var _bead = instance_create_layer(0, 0, "Instances", obj_bullet_bead);
            var _enemy = instance_create_layer(0, 0, "Instances", obj_enemy_turret);

            with (_bead) {
                event_perform(ev_create, 0);
            }

            with (_enemy) {
                event_perform(ev_create, 0);
            }

            expect(variable_instance_get(_bead, "cancelled")).toBeFalsy();
            expect(variable_instance_get(_bead, "medal_score_value")).toBe(BULLET_CANCEL_SCORE_BONUS);
            expect(variable_instance_get(_bead, "move_speed")).toBe(TURRET_BULLET_SPEED);
            expect(variable_instance_get(_bead, "collision_radius")).toBe(4);

            global.game_runtime.score = 0;

            with (_enemy) {
                x = 10;
                y = 12;
                move_direction = 0;
                move_speed = 3;
                hp = 5;
                points = 750;
                fire_interval = 999;
                fire_timer = 0;
            }

            simulateEvent(ev_step, ev_step_normal, _enemy);

            expect(variable_instance_get(_enemy, "x")).toBe(13);
            expect(variable_instance_get(_enemy, "y")).toBe(12);
            expect(variable_instance_get(_enemy, "fire_timer")).toBe(1);

            with (_enemy) {
                hp = 0;
            }

            simulateEvent(ev_step, ev_step_normal, _enemy);

            expect(global.game_runtime.score).toBe(750);
            expect(instance_exists(_enemy)).toBeFalsy();
            expect(instance_number(obj_medal)).toBe(2);

            with (_bead) {
                instance_destroy();
            }

            if (instance_exists(_enemy)) {
                with (_enemy) {
                    instance_destroy();
                }
            }
            with (obj_medal) { instance_destroy(); }
        });

        test("Inherited combat children stop after parent freeze and destruction guards", function() {
            var _enemy = instance_create_layer(20, 20, "Instances", obj_enemy_variant);
            var _blade = instance_create_layer(40, 40, "Instances", obj_bullet_blade);
            var _boss = instance_create_layer(60, 60, "Instances", obj_boss_sunset);

            with (_enemy) {
                move_direction = 0;
                move_speed = 3;
                age = 0;
            }
            with (_blade) {
                spiral_angle = 45;
            }
            with (_boss) {
                phase_timer = 0;
                float_phase = 0;
            }

            global.game_runtime.signals.dialogue = true;
            simulateEvent(ev_step, ev_step_normal, _enemy);
            simulateEvent(ev_step, ev_step_normal, _blade);
            simulateEvent(ev_step, ev_step_normal, _boss);

            expect(variable_instance_get(_enemy, "x")).toBe(20);
            expect(variable_instance_get(_enemy, "age")).toBe(0);
            expect(variable_instance_get(_enemy, "combat_step_blocked")).toBeTruthy();
            expect(variable_instance_get(_blade, "spiral_angle")).toBe(45);
            expect(variable_instance_get(_blade, "combat_step_blocked")).toBeTruthy();
            expect(variable_instance_get(_boss, "phase_timer")).toBe(0);
            expect(variable_instance_get(_boss, "float_phase")).toBe(0);
            expect(variable_instance_get(_boss, "combat_step_blocked")).toBeTruthy();

            global.game_runtime.signals.dialogue = false;
            with (_enemy) { instance_destroy(); }
            with (_blade) { instance_destroy(); }
            with (_boss) { instance_destroy(); }
        });

        test("A cancelled close-range bullet becomes a medal without hitting the player", function() {
            with (obj_player) { instance_destroy(); }
            with (obj_bullet_parent) { instance_destroy(); }
            with (obj_medal) { instance_destroy(); }

            var _player = instance_create_layer(CAMERA_HOME_X, CAMERA_HOME_Y, "Instances", obj_player);
            var _bullet = instance_create_layer(CAMERA_HOME_X, CAMERA_HOME_Y - CAMERA_SCROLL_SPEED, "Instances", obj_bullet_bead);

            with (_player) {
                player_state.invuln_timer = 0;
            }
            with (_bullet) {
                cancelled = true;
            }

            // The room input manager may retain runner-simulated undefined key
            // values; this collision regression only needs a neutral snapshot.
            global.game_input = GameInputStateCreate();
            simulateEvent(ev_step, ev_step_normal, _player);

            expect(variable_instance_get(_player, "player_state").hit).toBeFalsy();
            expect(instance_exists(_bullet)).toBeTruthy();

            simulateEvent(ev_step, ev_step_normal, _bullet);

            expect(instance_exists(_bullet)).toBeFalsy();
            expect(instance_number(obj_medal)).toBe(1);

            with (_player) { instance_destroy(); }
            with (obj_medal) { instance_destroy(); }
        });

        test("Berserk meter activation cancels the screen and grants only three safe frames", function() {
            with (obj_player) { instance_destroy(); }
            with (obj_bullet_parent) { instance_destroy(); }

            var _player = instance_create_layer(100, 100, "Instances", obj_player);
            var _bullet = instance_create_layer(110, 80, "Instances", obj_bullet_bead);
            _player.player_state.invuln_timer = 0;
            GameRankSet(5);
            global.game_runtime.meter = 999;

            expect(GamePlayerMeterRewardApply(1)).toBeTruthy();
            expect(global.game_runtime.is_berserk).toBeTruthy();
            expect(global.game_runtime.meter).toBe(METER_MAX);
            expect(GameRankGet()).toBe(5 + RANK_HYPER_GAIN);
            expect(GamePlayerSwordPoseCreate(0, true).length).toBe(SWORD_LENGTH * BERSERK_SWORD_MULTIPLIER);
            expect(variable_instance_get(_player, "player_state").invuln_timer).toBe(BERSERK_ACTIVATION_INVULN_FRAMES);
            expect(variable_instance_get(_bullet, "cancelled")).toBeTruthy();

            with (_player) { instance_destroy(); }
            with (_bullet) { instance_destroy(); }
        });

        test("Sustained fire trickles Berserk while point-blank hits build it quickly", function() {
            with (obj_player) { instance_destroy(); }
            var _player = instance_create_layer(100, 100, "Instances", obj_player);
            _player.player_state.invuln_timer = 0;
            global.game_runtime.meter = 0;
            global.game_runtime.is_berserk = false;
            _player.player_state.attack_meter_timer = BERSERK_PASSIVE_ATTACK_INTERVAL - 1;

            expect(GamePlayerBerserkAttackMeterStep(_player.player_state, true)).toBe(BERSERK_PASSIVE_ATTACK_GAIN);
            expect(global.game_runtime.meter).toBe(BERSERK_PASSIVE_ATTACK_GAIN);
            expect(GamePlayerPointBlankAttackRewardApply(100 + BERSERK_POINT_BLANK_RADIUS, 100,
                BERSERK_POINT_BLANK_SWORD_GAIN)).toBeTruthy();
            expect(global.game_runtime.meter).toBe(BERSERK_PASSIVE_ATTACK_GAIN
                + BERSERK_POINT_BLANK_SWORD_GAIN);
            expect(GamePlayerPointBlankAttackRewardApply(100 + BERSERK_POINT_BLANK_RADIUS + 1, 100,
                BERSERK_POINT_BLANK_SWORD_GAIN)).toBeFalsy();

            with (_player) { instance_destroy(); }
        });

        test("Continue accept resets the run state and respawns the player", function() {
            var _state = GamePlayerStateCreate();

            global.game_runtime.signals.continue_request = true;
            global.game_runtime.lives = 0;
            global.game_runtime.bombs = 0;
            global.game_runtime.continues_used = 0;
            global.game_runtime.meter = 321;
            global.game_runtime.is_berserk = true;

            var _respawn = GamePlayerContinueAccept(_state, CAMERA_HOME_X, CAMERA_HOME_Y);

            expect(global.game_runtime.signals.continue_request).toBeFalsy();
            expect(global.game_runtime.continues_used).toBe(1);
            expect(global.game_runtime.lives).toBe(DEFAULT_LIVES);
            expect(global.game_runtime.bombs).toBe(DEFAULT_BOMBS);
            expect(global.game_runtime.meter).toBe(0);
            expect(global.game_runtime.is_berserk).toBeFalsy();
            expect(_state.invuln_timer).toBe(INVULN_TIME);
            expect(_respawn.x).toBe(CAMERA_HOME_X);
            expect(_respawn.y).toBe(CAMERA_HOME_Y + PLAYER_RESPAWN_OFFSET_Y);
        });

        test("Bombs consume stock, stay active for their animation, and cancel bullets while they run", function() {
            var _state = GamePlayerStateCreate();
            var _bullet = noone;

            global.game_runtime.bombs = 1;
            _state.invuln_timer = 0;

            expect(GamePlayerBombTryStart(_state)).toBeTruthy();
            expect(global.game_runtime.bombs).toBe(0);
            expect(GamePlayerBombActiveGet()).toBeTruthy();
            expect(GamePlayerIsInvulnerable(_state)).toBeTruthy();
            expect(_state.invuln_timer).toBe(BOMB_INVULN_FRAMES);
            expect(GamePlayerBombTryStart(_state)).toBeFalsy();

            _bullet = instance_create_layer(0, 0, "Instances", obj_bullet_bead);
            with (_bullet) {
                event_perform(ev_create, 0);
            }

            simulateEvent(ev_step, ev_step_normal, _bullet);

            expect(instance_exists(_bullet)).toBeFalsy();
            expect(instance_number(obj_medal)).toBe(1);

            for (var i = 0; i < BOMB_DURATION_FRAMES; i++) {
                GamePlayerBombStep(_state);
            }

            expect(GamePlayerBombActiveGet()).toBeFalsy();
            expect(GamePlayerIsInvulnerable(_state)).toBeTruthy();
            _state.invuln_timer = 0;
            expect(GamePlayerIsInvulnerable(_state)).toBeFalsy();
            expect(GamePlayerBombTryStart(_state)).toBeFalsy();

            with (obj_medal) {
                instance_destroy();
            }
        });

        test("Continue decline enters game over and finishes after its delay", function() {
            var _state = GameContinueStateCreate();
            var _input = GameGameplayInputSnapshotCreate();
            var _action = "none";

            _state.selected_index = CONTINUE_OPTION_NO;
            _input.fire_pressed = true;

            expect(GameContinueStateStep(_state, _input)).toBe("none");
            expect(_state.mode).toBe("game_over");
            expect(_state.game_over_timer).toBe(GAME_OVER_DELAY_FRAMES);

            _input.fire_pressed = false;

            for (var i = 0; i < GAME_OVER_DELAY_FRAMES; i++) {
                _action = GameContinueStateStep(_state, _input);
            }

            expect(_action).toBe("game_over");
        });

        test("Imported art and audio assets are registered with the expected sizes", function() {
            var _aisha_portrait = asset_get_index("spr_aisha_portrait");
            var _aisha_ship = asset_get_index("spr_aisha_ship");
            var _aster_portrait = asset_get_index("spr_aster_portrait");
            var _aster_ship = asset_get_index("spr_aster_ship");
            var _caelia_portrait = asset_get_index("spr_caelia_portrait");
            var _caelia_ship = asset_get_index("spr_caelia_ship");
            var _mira_portrait = asset_get_index("spr_mira_portrait");
            var _mira_ship = asset_get_index("spr_mira_ship");
            var _shalmii_portrait = asset_get_index("spr_shalmii_portrait");
            var _shalmii_ship = asset_get_index("spr_shalmii_ship");
            var _bee = asset_get_index("spr_bee");
            var _bullet_bead = asset_get_index("spr_bullet_bead");
            var _bullet_bead_mask = asset_get_index("spr_bullet_bead_mask");
            var _bullet_blade = asset_get_index("spr_bullet_blade");
            var _bullet_diamond = asset_get_index("spr_bullet_diamond");
            var _dialogue_bg_core = asset_get_index("spr_dialogue_bg_core");
            var _dialogue_bg_flower = asset_get_index("spr_dialogue_bg_flower");
            var _logo = asset_get_index("spr_logo");
            var _mayfly = asset_get_index("spr_mayfly");
            var _violet_bee = asset_get_index("spr_violet_bee");
            var _violet_bee_bullet = asset_get_index("spr_violet_bee_bullet");
            var _twilight_mayfly = asset_get_index("spr_twilight_mayfly");
            var _twilight_mayfly_bullet = asset_get_index("spr_twilight_mayfly_bullet");
            var _silhouette_moon = asset_get_index("spr_silhouette_moon");
            var _silhouette_selkie = asset_get_index("spr_silhouette_selkie");
            var _silhouette_mira = asset_get_index("spr_silhouette_mira");
            var _silhouette_shalmii = asset_get_index("spr_silhouette_shalmii");
            var _silhouette_aisha = asset_get_index("spr_silhouette_aisha");
            var _silhouette_aster = asset_get_index("spr_silhouette_aster");
            var _silhouette_caelia = asset_get_index("spr_silhouette_caelia");
            var _medal = asset_get_index("spr_medal");
            var _enemy_destroy = asset_get_index("snd_enemy_destroy");
            var _ow = asset_get_index("snd_ow");
            var _stage_music = asset_get_index("snd_stage_music");
            var _typewriter = asset_get_index("snd_typewriter");
            var _music_title = asset_get_index("snd_music_title");
            var _music_stage_01 = asset_get_index("snd_music_stage_01");
            var _music_stage_02 = asset_get_index("snd_music_stage_02");
            var _music_stage_03 = asset_get_index("snd_music_stage_03");
            var _music_stage_04 = asset_get_index("snd_music_stage_04");
            var _music_stage_05 = asset_get_index("snd_music_stage_05");
            var _music_stage_06 = asset_get_index("snd_music_stage_06");
            var _music_stage_07 = asset_get_index("snd_music_stage_07");
            var _music_stage_08 = asset_get_index("snd_music_stage_08");
            var _music_stage_09 = asset_get_index("snd_music_stage_09");
            var _music_stage_10 = asset_get_index("snd_music_stage_10");
            var _music_ending = asset_get_index("snd_music_ending");
            var _music_credits = asset_get_index("snd_music_credits");
            var _character_music_names = [
                "snd_music_stage_shalmii", "snd_music_boss_shalmii",
                "snd_music_stage_aster", "snd_music_boss_aster",
                "snd_music_stage_mira_aisha", "snd_music_boss_mira_aisha",
                "snd_music_stage_caelia", "snd_music_boss_caelia",
                "snd_music_stage_moon", "snd_music_boss_moon",
                "snd_music_stage_selkie", "snd_music_boss_selkie",
            ];
            var _player_shot_moon = asset_get_index("snd_player_shot_moon");
            var _player_shot_selkie = asset_get_index("snd_player_shot_selkie");
            var _player_focus = asset_get_index("snd_player_focus");
            var _sword_moon = asset_get_index("snd_sword_moon");
            var _sword_selkie = asset_get_index("snd_sword_selkie");
            var _powerup_collect = asset_get_index("snd_powerup_collect");
            var _bomb = asset_get_index("snd_bomb");
            var _stage_clear = asset_get_index("snd_stage_clear");
            var _boss_spawn = asset_get_index("snd_boss_spawn");
            var _boss_phase = asset_get_index("snd_boss_phase");
            var _enemy_fire_arc = asset_get_index("snd_enemy_fire_arc");
            var _enemy_fire_needle = asset_get_index("snd_enemy_fire_needle");
            var _sunrise = asset_get_index("spr_sunrise");
            var _sunrise_bullet = asset_get_index("spr_sunrise_bullet");
            var _sunset = asset_get_index("spr_sunset");
            var _sunset_bullet = asset_get_index("spr_sunset_bullet");
            var _text_arrow = asset_get_index("spr_text_arrow");
            var _textbox = asset_get_index("spr_textbox");
            var _turret = asset_get_index("spr_turret");
            var _violet_tiles = asset_get_index("spr_violet_tiles");
            var _stage3d_textures = [
                asset_get_index("tex_stage3d_01"),
                asset_get_index("tex_stage3d_02"),
                asset_get_index("tex_stage3d_03"),
                asset_get_index("tex_stage3d_04"),
                asset_get_index("tex_stage3d_05")
            ];

            expect(_aisha_portrait != -1 && sprite_exists(_aisha_portrait)).toBeTruthy();
            expect(_aisha_ship != -1 && sprite_exists(_aisha_ship)).toBeTruthy();
            expect(_aster_portrait != -1 && sprite_exists(_aster_portrait)).toBeTruthy();
            expect(_aster_ship != -1 && sprite_exists(_aster_ship)).toBeTruthy();
            expect(_caelia_portrait != -1 && sprite_exists(_caelia_portrait)).toBeTruthy();
            expect(_caelia_ship != -1 && sprite_exists(_caelia_ship)).toBeTruthy();
            expect(_mira_portrait != -1 && sprite_exists(_mira_portrait)).toBeTruthy();
            expect(_mira_ship != -1 && sprite_exists(_mira_ship)).toBeTruthy();
            expect(_shalmii_portrait != -1 && sprite_exists(_shalmii_portrait)).toBeTruthy();
            expect(_shalmii_ship != -1 && sprite_exists(_shalmii_ship)).toBeTruthy();
            expect(_bee != -1 && sprite_exists(_bee)).toBeTruthy();
            expect(_bullet_bead != -1 && sprite_exists(_bullet_bead)).toBeTruthy();
            expect(_bullet_bead_mask != -1 && sprite_exists(_bullet_bead_mask)).toBeTruthy();
            expect(_bullet_blade != -1 && sprite_exists(_bullet_blade)).toBeTruthy();
            expect(_bullet_diamond != -1 && sprite_exists(_bullet_diamond)).toBeTruthy();
            expect(_dialogue_bg_core != -1 && sprite_exists(_dialogue_bg_core)).toBeTruthy();
            expect(_dialogue_bg_flower != -1 && sprite_exists(_dialogue_bg_flower)).toBeTruthy();
            expect(_logo != -1 && sprite_exists(_logo)).toBeTruthy();
            expect(_mayfly != -1 && sprite_exists(_mayfly)).toBeTruthy();
            expect(_violet_bee != -1 && sprite_exists(_violet_bee)).toBeTruthy();
            expect(_violet_bee_bullet != -1 && sprite_exists(_violet_bee_bullet)).toBeTruthy();
            expect(_twilight_mayfly != -1 && sprite_exists(_twilight_mayfly)).toBeTruthy();
            expect(_twilight_mayfly_bullet != -1 && sprite_exists(_twilight_mayfly_bullet)).toBeTruthy();
            expect(_silhouette_moon != -1 && sprite_exists(_silhouette_moon)).toBeTruthy();
            expect(_silhouette_selkie != -1 && sprite_exists(_silhouette_selkie)).toBeTruthy();
            expect(_silhouette_mira != -1 && sprite_exists(_silhouette_mira)).toBeTruthy();
            expect(_silhouette_shalmii != -1 && sprite_exists(_silhouette_shalmii)).toBeTruthy();
            expect(_silhouette_aisha != -1 && sprite_exists(_silhouette_aisha)).toBeTruthy();
            expect(_silhouette_aster != -1 && sprite_exists(_silhouette_aster)).toBeTruthy();
            expect(_silhouette_caelia != -1 && sprite_exists(_silhouette_caelia)).toBeTruthy();
            expect(_medal != -1 && sprite_exists(_medal)).toBeTruthy();
            expect(_enemy_destroy != -1).toBeTruthy();
            expect(_ow != -1).toBeTruthy();
            expect(_stage_music != -1).toBeTruthy();
            expect(_typewriter != -1).toBeTruthy();
            expect(_music_title != -1).toBeTruthy();
            expect(_music_stage_01 != -1).toBeTruthy();
            expect(_music_stage_02 != -1).toBeTruthy();
            expect(_music_stage_03 != -1).toBeTruthy();
            expect(_music_stage_04 != -1).toBeTruthy();
            expect(_music_stage_05 != -1).toBeTruthy();
            expect(_music_stage_06 != -1).toBeTruthy();
            expect(_music_stage_07 != -1).toBeTruthy();
            expect(_music_stage_08 != -1).toBeTruthy();
            expect(_music_stage_09 != -1).toBeTruthy();
            expect(_music_stage_10 != -1).toBeTruthy();
            expect(_music_ending != -1).toBeTruthy();
            expect(_music_credits != -1).toBeTruthy();
            for (var music = 0; music < array_length(_character_music_names); music++) {
                expect(asset_get_index(_character_music_names[music]) != -1).toBeTruthy();
            }
            expect(_player_shot_moon != -1).toBeTruthy();
            expect(_player_shot_selkie != -1).toBeTruthy();
            expect(_player_focus != -1).toBeTruthy();
            expect(_sword_moon != -1).toBeTruthy();
            expect(_sword_selkie != -1).toBeTruthy();
            expect(_powerup_collect != -1).toBeTruthy();
            expect(_bomb != -1).toBeTruthy();
            expect(_stage_clear != -1).toBeTruthy();
            expect(_boss_spawn != -1).toBeTruthy();
            expect(_boss_phase != -1).toBeTruthy();
            expect(_enemy_fire_arc != -1).toBeTruthy();
            expect(_enemy_fire_needle != -1).toBeTruthy();
            expect(_sunrise != -1 && sprite_exists(_sunrise)).toBeTruthy();
            expect(_sunrise_bullet != -1 && sprite_exists(_sunrise_bullet)).toBeTruthy();
            expect(_sunset != -1 && sprite_exists(_sunset)).toBeTruthy();
            expect(_sunset_bullet != -1 && sprite_exists(_sunset_bullet)).toBeTruthy();
            expect(_text_arrow != -1 && sprite_exists(_text_arrow)).toBeTruthy();
            expect(_textbox != -1 && sprite_exists(_textbox)).toBeTruthy();
            expect(_turret != -1 && sprite_exists(_turret)).toBeTruthy();
            expect(_violet_tiles != -1 && sprite_exists(_violet_tiles)).toBeTruthy();
            for (var texture_index = 0; texture_index < array_length(_stage3d_textures); texture_index++) {
                expect(_stage3d_textures[texture_index] != -1 && sprite_exists(_stage3d_textures[texture_index])).toBeTruthy();
                expect(sprite_get_width(_stage3d_textures[texture_index])).toBe(1024);
                expect(sprite_get_height(_stage3d_textures[texture_index])).toBe(1024);
            }
            expect(object_exists(obj_boss_sunset)).toBeTruthy();
            expect(object_exists(obj_bullet_bead)).toBeTruthy();
            expect(object_exists(obj_bullet_blade)).toBeTruthy();
            expect(object_exists(obj_bullet_diamond)).toBeTruthy();
            expect(object_exists(obj_enemy_bee)).toBeTruthy();
            expect(object_exists(obj_enemy_mayfly)).toBeTruthy();
            expect(object_exists(obj_enemy_turret)).toBeTruthy();
            expect(object_exists(obj_enemy_variant)).toBeTruthy();
            expect(object_exists(obj_powerup)).toBeTruthy();
            expect(object_exists(obj_UI_credits)).toBeTruthy();
            expect(asset_get_index("rm_credits") != -1).toBeTruthy();
            expect(sprite_get_width(_aisha_portrait)).toBe(360);
            expect(sprite_get_height(_aisha_portrait)).toBe(360);
            expect(sprite_get_width(_aisha_ship)).toBe(64);
            expect(sprite_get_height(_aisha_ship)).toBe(64);
            expect(sprite_get_width(_aster_portrait)).toBe(360);
            expect(sprite_get_height(_aster_portrait)).toBe(360);
            expect(sprite_get_width(_aster_ship)).toBe(64);
            expect(sprite_get_height(_aster_ship)).toBe(64);
            expect(sprite_get_width(_caelia_portrait)).toBe(360);
            expect(sprite_get_height(_caelia_portrait)).toBe(360);
            expect(sprite_get_width(_caelia_ship)).toBe(64);
            expect(sprite_get_height(_caelia_ship)).toBe(64);
            expect(sprite_get_width(_mira_portrait)).toBe(360);
            expect(sprite_get_height(_mira_portrait)).toBe(360);
            expect(sprite_get_width(_mira_ship)).toBe(64);
            expect(sprite_get_height(_mira_ship)).toBe(64);
            expect(sprite_get_width(_shalmii_portrait)).toBe(360);
            expect(sprite_get_height(_shalmii_portrait)).toBe(360);
            expect(sprite_get_width(_shalmii_ship)).toBe(64);
            expect(sprite_get_height(_shalmii_ship)).toBe(64);
            expect(sprite_get_width(_bee)).toBe(64);
            expect(sprite_get_width(_bullet_bead)).toBe(16);
            expect(sprite_get_width(_bullet_bead_mask)).toBe(16);
            expect(sprite_get_width(_bullet_blade)).toBe(16);
            expect(sprite_get_width(_bullet_diamond)).toBe(16);
            expect(sprite_get_width(_dialogue_bg_core)).toBe(640);
            expect(sprite_get_height(_dialogue_bg_flower)).toBe(360);
            expect(sprite_get_width(_mayfly)).toBe(64);
            expect(sprite_get_width(_medal)).toBe(32);
            expect(sprite_get_width(_sunrise)).toBe(64);
            expect(sprite_get_width(_sunrise_bullet)).toBe(16);
            expect(sprite_get_width(_sunset)).toBe(64);
            expect(sprite_get_height(_sunset_bullet)).toBe(16);
            expect(sprite_get_width(_text_arrow)).toBe(64);
            expect(sprite_get_height(_text_arrow)).toBe(64);
            expect(sprite_get_number(_text_arrow)).toBe(8);
            expect(sprite_get_width(_textbox)).toBe(640);
            expect(sprite_get_height(_textbox)).toBe(130);
            expect(sprite_get_width(_turret)).toBe(32);
            expect(sprite_get_width(_violet_tiles)).toBe(128);
            expect(sprite_get_height(_violet_tiles)).toBe(128);
        });

        test("Five modular 3D stage scenes expose looping camera, lighting, fog, and runtime buffers", function() {
            var _effects = ["embers", "forest_fireflies", "vegas_magic_dust", "deep_space", "violet_pollen"];

            for (var stage = 1; stage <= 5; stage++) {
                var _config = GameStage3DConfigGet(stage);
                var _start = GameStage3DPathSample(_config, 0);
                var _end = GameStage3DPathSample(_config, 64);

                expect(_config.effect).toBe(_effects[stage - 1]);
                expect(_config.fog_start < _config.fog_end).toBeTruthy();
                expect(_config.speed > 0 && _config.speed < 0.03).toBeTruthy();
                expect(_start.x).toBe(_end.x);
                expect(_start.z).toBe(_end.z);
                expect(file_exists(_config.buffer_name)).toBeTruthy();
                expect(asset_get_index("tex_stage3d_0" + string(stage)) != -1).toBeTruthy();
            }
        });
    });

    section("Controller, pause, practice, and rank", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();
            global.game_input = GameInputStateCreate();

            GameTestPersistenceFilesDelete();
        });

        afterEach(function() {
            GameTestPersistenceFilesDelete();
        });

        test("Synthetic gamepad snapshots expose edges and release neutral movement", function() {
            var _state = GameInputStateCreate();
            _state.gamepad_connected = true;
            var _keyboard = {
                up: false,
                down: false,
                left: false,
                right: false,
                fire: false,
                autofire: false,
                focus: false,
                bomb: false,
                pause: false,
                move_x: 0,
                move_y: 0,
                activity: false,
            };
            var _gamepad = {
                up: false,
                down: false,
                left: false,
                right: true,
                fire: true,
                autofire: false,
                focus: false,
                bomb: false,
                pause: true,
                move_x: 0.75,
                move_y: -0.25,
                activity: true,
            };

            GameInputSnapshotApply(_state, _keyboard, _gamepad);

            expect(_state.device).toBe("gamepad");
            expect(_state.move_x).toBe(0.75);
            expect(_state.move_y).toBe(-0.25);
            expect(_state.verbs.right.down).toBeTruthy();
            expect(_state.verbs.right.pressed).toBeTruthy();
            expect(_state.verbs.fire.pressed).toBeTruthy();
            expect(_state.verbs.pause.pressed).toBeTruthy();

            GameInputSnapshotApply(_state, _keyboard, _gamepad);
            expect(_state.verbs.right.down).toBeTruthy();
            expect(_state.verbs.right.pressed).toBeFalsy();

            _gamepad.right = false;
            _gamepad.fire = false;
            _gamepad.pause = false;
            _gamepad.move_x = 0;
            _gamepad.move_y = 0;
            _gamepad.activity = false;
            GameInputSnapshotApply(_state, _keyboard, _gamepad);

            expect(_state.device).toBe("gamepad");
            expect(_state.move_x).toBe(0);
            expect(_state.move_y).toBe(0);
            expect(_state.verbs.right.down).toBeFalsy();
            expect(_state.verbs.right.released).toBeTruthy();
            expect(_state.verbs.fire.released).toBeTruthy();
            expect(_state.verbs.pause.released).toBeTruthy();
        });

        test("Text-key impulses preserve sub-frame taps without repeating stale characters", function() {
            var _state = GameInputStateCreate();

            expect(GameInputTextImpulseConsume(_state, "s")).toBe("S");
            expect(GameInputTextImpulseConsume(_state, "s")).toBe("");
            expect(GameInputTextImpulseConsume(_state, "q")).toBe("Q");
            expect(GameInputTextImpulseConsume(_state, "d")).toBe("D");
            expect(GameInputTextImpulseConsume(_state, "")).toBe("");
        });

        test("Keyboard polling consumes the configured binding instead of its old default", function() {
            GameInputBindingAssign("keyboard", "fire", ord("Q"));
            simulateKeyHold(ord("Q"));

            var _snapshot = GameInputKeyboardSnapshotCreate();
            expect(_snapshot.fire).toBeTruthy();
            expect(_snapshot.bomb).toBeFalsy();

            simulateKeyRelease(ord("Q"));
        });

        test("Keyboard and controller verbs combine while the active device owns movement", function() {
            var _state = GameInputStateCreate();
            var _keyboard = {
                up: false,
                down: false,
                left: true,
                right: false,
                fire: false,
                autofire: false,
                focus: false,
                bomb: true,
                pause: false,
                move_x: -1,
                move_y: 0,
                activity: true,
            };
            var _gamepad = {
                up: false,
                down: true,
                left: false,
                right: false,
                fire: true,
                autofire: true,
                focus: true,
                bomb: false,
                pause: false,
                move_x: 0,
                move_y: 0.5,
                activity: true,
            };

            GameInputSnapshotApply(_state, _keyboard, _gamepad);
            global.game_input = _state;

            expect(_state.device).toBe("gamepad");
            expect(_state.move_x).toBe(0);
            expect(_state.move_y).toBe(0.5);
            expect(GameInputVerbDown("left")).toBeTruthy();
            expect(GameInputVerbDown("down")).toBeTruthy();
            expect(GameInputVerbPressed("fire")).toBeTruthy();
            expect(GameInputVerbDown("autofire")).toBeTruthy();
            expect(GameInputVerbDown("focus")).toBeTruthy();
            expect(GameInputVerbDown("bomb")).toBeTruthy();
            expect(GameInputVerbDown("not_a_real_verb")).toBeFalsy();
            expect(GameInputVerbPressed("not_a_real_verb")).toBeFalsy();
            _gamepad.down = false;
            _gamepad.fire = false;
            _gamepad.autofire = false;
            _gamepad.focus = false;
            _gamepad.move_y = 0;
            _gamepad.activity = false;
            GameInputSnapshotApply(_state, _keyboard, _gamepad);

            expect(_state.device).toBe("keyboard");
            expect(_state.move_x).toBe(-1);
            expect(_state.move_y).toBe(0);
        });

        test("Pause opens from its dedicated verb and exposes mode-specific rows", function() {
            var _state = GamePauseStateCreate();
            var _open = GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, false, false, true), false);

            expect(_open.action).toBe("open");
            expect(_state.active).toBeTruthy();
            expect(_state.page).toBe("main");
            expect(array_length(GamePauseMainItemsCreate(false))).toBe(3);
            expect(array_length(GamePauseMainItemsCreate(true))).toBe(4);
            expect(GamePauseMainItemsCreate(true)[2]).toBe("Practice Tuning");

            var _close = GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, false, false, true), false);
            expect(_close.action).toBe("close");
        });

        test("Pause settings adjust configuration and return to the main pause page", function() {
            var _state = GamePauseStateCreate();
            _state.active = true;
            _state.main_index = 1;

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, true, false, false), false);
            expect(_state.page).toBe("options");
            expect(_state.options_index).toBe(0);

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, true, false, false, false, false, false), false);
            expect(_state.options_index).toBe(1);

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, true, false, false, false), false);
            expect(global.game_config.display_scale).toBe(3);
            expect(file_exists(GameConfigPathGet())).toBeTruthy();

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, false, true, false), false);
            expect(_state.page).toBe("main");
        });

        test("Pause quit confirmation requires choosing Yes before returning to title", function() {
            var _state = GamePauseStateCreate();
            _state.active = true;
            _state.main_index = 2;

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, true, false, false), false);
            expect(_state.page).toBe("quit_confirm");
            expect(_state.quit_index).toBe(0);

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, true, false, false, false), false);
            expect(_state.quit_index).toBe(1);

            var _result = GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, true, false, false), false);
            expect(_result.action).toBe("quit_title");
        });

        test("Practice pause tuning changes live variables and can restart the attempt", function() {
            global.game_runtime.run_mode = "practice";
            var _state = GamePauseStateCreate();
            _state.active = true;
            _state.main_index = 2;

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, true, false, false), true);
            expect(_state.page).toBe("practice");
            expect(_state.practice_index).toBe(0);

            GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, true, false, false, false), true);
            expect(global.game_runtime.practice_config.power).toBe(1);
            expect(global.game_runtime.power).toBe(1);

            _state.practice_index = array_length(GamePracticeLiveEntriesCreate());
            var _result = GamePauseStateStep(_state,
                GamePauseInputSnapshotCreate(false, false, false, false, true, false, false), true);
            expect(_result.action).toBe("restart_practice");
        });

        test("Practice tuning preserves unrelated live values and displays the active state", function() {
            global.game_runtime.run_mode = "practice";
            global.game_runtime.power = 1;
            global.game_runtime.rank = 35;
            global.game_runtime.rank_locked = true;
            global.game_runtime.lives = 1;
            global.game_runtime.bombs = 0;
            global.game_runtime.meter = 700;
            global.game_runtime.is_berserk = false;

            GamePracticeLiveAdjust(0, 1);

            expect(global.game_runtime.power).toBe(2);
            expect(global.game_runtime.rank).toBe(35);
            expect(global.game_runtime.rank_locked).toBeTruthy();
            expect(global.game_runtime.lives).toBe(1);
            expect(global.game_runtime.bombs).toBe(0);
            expect(global.game_runtime.meter).toBe(700);
            expect(global.game_runtime.is_berserk).toBeFalsy();

            var _entries = GamePracticeLiveEntriesCreate();
            expect(_entries[0].value).toBe("2/" + string(PLAYER_POWER_MAX));
            expect(_entries[1].value).toBe("35%");
            expect(_entries[2].value).toBe("Off");
            expect(_entries[3].value).toBe("1");
            expect(_entries[4].value).toBe("0");
            expect(_entries[5].value).toBe("700");
        });

        test("Practice configuration normalizes every editable run variable", function() {
            var _config = GamePracticeConfigNormalize({
                ship_index: 1,
                stage: STAGE_COUNT + 8,
                segment: PRACTICE_SEGMENT_BOSS,
                power: -4,
                rank: RANK_MAX + 50,
                dynamic_rank: true,
                lives: 0,
                bombs: PLAYER_BOMB_MAX + 3,
                meter: 955,
            });

            expect(_config.ship_id).toBe(SHIP_SELKIE);
            expect(_config.ship_index).toBe(1);
            expect(_config.stage).toBe(STAGE_COUNT);
            expect(_config.segment).toBe(PRACTICE_SEGMENT_BOSS);
            expect(_config.power).toBe(0);
            expect(_config.rank).toBe(RANK_MAX);
            expect(_config.dynamic_rank).toBeTruthy();
            expect(_config.lives).toBe(1);
            expect(_config.bombs).toBe(PLAYER_BOMB_MAX);
            expect(_config.meter).toBe(METER_MAX);
        });

        test("Practice initialization applies setup without recording starts or results", function() {
            var _request = GamePracticeRunRequestConfigure({
                ship_id: SHIP_SELKIE,
                ship_index: 1,
                stage: 3,
                segment: PRACTICE_SEGMENT_BOSS,
                power: PLAYER_POWER_MAX,
                rank: 40,
                dynamic_rank: false,
                lives: 2,
                bombs: 1,
                meter: METER_MAX,
            });

            expect(_request.stage).toBe(3);
            expect(GameRunStartInitialize()).toBeTruthy();
            expect(GameRunIsPractice()).toBeTruthy();
            expect(GameRunStatsShouldRecord()).toBeFalsy();
            expect(global.game_runtime.selected_ship_id).toBe(SHIP_SELKIE);
            expect(global.game_runtime.current_stage).toBe(3);
            expect(global.game_runtime.power).toBe(PLAYER_POWER_MAX);
            expect(global.game_runtime.rank).toBe(40);
            expect(global.game_runtime.rank_locked).toBeTruthy();
            expect(global.game_runtime.lives).toBe(2);
            expect(global.game_runtime.bombs).toBe(1);
            expect(global.game_runtime.meter).toBe(METER_MAX);
            expect(global.game_runtime.is_berserk).toBeTruthy();
            expect(global.game_runtime.run_started_recorded).toBeFalsy();
            expect(global.game_save.runs_started.ship_selkie[0]).toBe(0);
            expect(file_exists(GameSavePathGet())).toBeFalsy();

            global.game_runtime.score = 999999;
            expect(GameRunResultSave()).toBeFalsy();
            expect(global.game_save.high_score.ship_selkie[0]).toBe(0);
            expect(global.game_save.runs_finished.ship_selkie[0]).toBe(0);
            expect(file_exists(GameSavePathGet())).toBeFalsy();
        });

        test("Practice segment selection reaches boss and waves-only seams", function() {
            GamePracticeRunRequestConfigure({
                stage: 4,
                segment: PRACTICE_SEGMENT_BOSS,
            });
            GameRunStartInitialize();
            var _boss_state = GameSceneStateCreate();

            expect(GamePracticeSceneStateApply(_boss_state)).toBeTruthy();
            expect(_boss_state.mode).toBe("boss_intro");
            expect(_boss_state.frame).toBe(STAGE_LENGTH_FRAMES);
            expect(_boss_state.scroll_speed).toBe(0);
            expect(_boss_state.background_route).toBe("boss");
            expect(global.game_runtime.current_stage).toBe(4);
            expect(global.game_runtime.stage_frame).toBe(STAGE_LENGTH_FRAMES);
            expect(global.game_runtime.stage_notice_timer).toBe(0);

            GamePracticeRunRequestConfigure({
                stage: 4,
                segment: PRACTICE_SEGMENT_WAVES,
            });
            GameRunStartInitialize();
            var _waves_state = GameSceneStateCreate();
            GamePracticeSceneStateApply(_waves_state);

            expect(_waves_state.mode).toBe("scroll");
            expect(_waves_state.frame).toBe(0);
            expect(global.game_runtime.current_stage).toBe(4);
            expect(GamePracticeWavesOnly()).toBeTruthy();
        });

        test("Rank pressure starts forgiving and reaches the established tuning at fifty", function() {
            var _low = GameRankPressureCreate(RANK_MIN);
            var _neutral = GameRankPressureCreate(RANK_DEFAULT);
            var _high = GameRankPressureCreate(RANK_MAX);

            expect(_neutral.spawn_interval_scale).toBe(1);
            expect(_neutral.fire_interval_scale).toBe(1);
            expect(_neutral.bullet_speed_scale).toBe(1);
            expect(_low.spawn_interval_scale).toBeGreaterThan(_neutral.spawn_interval_scale);
            expect(_low.fire_interval_scale).toBeGreaterThan(_neutral.fire_interval_scale);
            expect(_low.bullet_speed_scale).toBeLessThan(_neutral.bullet_speed_scale);
            expect(_high.spawn_interval_scale).toBe(_neutral.spawn_interval_scale);
            expect(_high.fire_interval_scale).toBe(_neutral.fire_interval_scale);
            expect(_high.bullet_speed_scale).toBe(_neutral.bullet_speed_scale);
            expect(GameRankSpawnIntervalGet(100, 1, RANK_MIN)).toBe(120);
            expect(GameRankSpawnIntervalGet(100, 1, RANK_DEFAULT)).toBe(100);
            expect(GameRankSpawnIntervalGet(100, 1, RANK_MAX)).toBe(100);
            expect(GameRankFireIntervalGet(100, 1, RANK_MIN)).toBe(125);
            expect(GameRankFireIntervalGet(100, 1, RANK_DEFAULT)).toBe(100);
            expect(GameRankFireIntervalGet(100, 1, RANK_MAX)).toBe(100);
            expect(GameRankFireIntervalGet(4, 5, RANK_MAX)).toBe(5);
        });

        test("Dynamic rank events clamp to bounds and respect the practice lock", function() {
            GameRankSet(95);
            expect(GameRankDynamicEnabled()).toBeTruthy();
            expect(GameRankEventApply(20)).toBe(RANK_MAX);
            expect(GameRankEventApply(-200)).toBe(RANK_MIN);

            GameRankSet(RANK_DEFAULT);
            global.game_runtime.rank_locked = true;
            expect(GameRankDynamicEnabled()).toBeFalsy();
            expect(GameRankEventApply(20)).toBe(RANK_DEFAULT);
            expect(GameRankGet()).toBe(RANK_DEFAULT);
        });

        test("Passive rank rises only after uninterrupted active gameplay", function() {
            GameRankSet(RANK_MIN);
            global.game_runtime.rank_frame = RANK_PASSIVE_INTERVAL - 1;

            expect(GameRankStep()).toBe(RANK_MIN + 1);
            expect(global.game_runtime.rank_frame).toBe(0);

            global.game_runtime.rank_frame = RANK_PASSIVE_INTERVAL - 1;
            global.game_runtime.signals.paused = true;
            expect(GameRankStep()).toBe(RANK_MIN + 1);
            expect(global.game_runtime.rank_frame).toBe(RANK_PASSIVE_INTERVAL - 1);

            global.game_runtime.signals.paused = false;
            global.game_runtime.rank_locked = true;
            expect(GameRankStep()).toBe(RANK_MIN + 1);
            expect(global.game_runtime.rank_frame).toBe(RANK_PASSIVE_INTERVAL - 1);
        });

        test("Ordinary shootdowns add one gradual rank point per defeat threshold", function() {
            GameRankSet(RANK_MIN);

            for (var i = 0; i < RANK_DEFEATS_PER_POINT - 1; i++) {
                expect(GameRankDefeatRewardApply()).toBe(RANK_MIN);
            }

            expect(GameRankDefeatRewardApply()).toBe(RANK_MIN + 1);
            expect(global.game_runtime.rank_defeats).toBe(0);

            global.game_runtime.rank_locked = true;
            expect(GameRankDefeatRewardApply()).toBe(RANK_MIN + 1);
            expect(global.game_runtime.rank_defeats).toBe(0);
        });
    });

    section("Story UI", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            GameTestPersistenceFilesDelete();

            if (file_exists("test_story.json")) {
                file_delete("test_story.json");
            }
        });

        afterEach(function() {
            GameTestPersistenceFilesDelete();

            if (file_exists("test_story.json")) {
                file_delete("test_story.json");
            }
        });

        test("Story queue requests enable the dialogue signal", function() {
            expect(GameStoryQueueRequest("test_story.json")).toBeTruthy();
            expect(global.game_runtime.signals.dialogue).toBeTruthy();
            expect(global.game_runtime.story.requested_file).toBe("test_story.json");
        });

        test("Story update loads the first frame from a queued JSON file", function() {
            var _file = file_text_open_write("test_story.json");
            file_text_write_string(_file, "[{\"name\":\"Narrator\",\"text\":\"The sea remembers.\",\"portraits\":[\"narrator_wave\"],\"positions\":[\"left\"]},{\"name\":\"Selkie\",\"text\":\"Then let's answer it.\",\"portraits\":[\"selkie_focus\"],\"positions\":[\"right\"]}]");
            file_text_close(_file);

            var _state = GameStoryStateCreate();
            GameStoryQueueRequest("test_story.json");
            GameStoryUpdate(_state);

            expect(GameStoryIsActive(_state)).toBeTruthy();
            expect(_state.current_frame.name).toBe("Narrator");
            expect(_state.current_frame.text).toBe("The sea remembers.");
            expect(_state.current_frame.portraits[0]).toBe("narrator_wave");
            expect(global.game_runtime.story.current_file).toBe("test_story.json");
        });

        test("Story advance moves through frames and clears dialogue at the end", function() {
            var _file = file_text_open_write("test_story.json");
            file_text_write_string(_file, "[{\"name\":\"A\",\"text\":\"One\",\"portraits\":[],\"positions\":[]},{\"name\":\"B\",\"text\":\"Two\",\"portraits\":[],\"positions\":[]}]");
            file_text_close(_file);

            var _state = GameStoryStateCreate();
            expect(GameStoryBegin(_state, "test_story.json")).toBeTruthy();
            expect(_state.current_frame.name).toBe("A");

            expect(GameStoryAdvance(_state)).toBeTruthy();
            expect(_state.current_frame.name).toBe("B");

            expect(GameStoryAdvance(_state)).toBeFalsy();
            expect(GameStoryIsActive(_state)).toBeFalsy();
            expect(global.game_runtime.signals.dialogue).toBeFalsy();
            expect(global.game_runtime.story.current_file).toBe("");
        });

        test("Story text types in, pauses at punctuation, and reveals before advancing", function() {
            var _file = file_text_open_write("test_story.json");
            file_text_write_string(_file, "[{\"name\":\"A\",\"text\":\"Wait, Moon.\",\"portraits\":[],\"positions\":[]},{\"name\":\"B\",\"text\":\"I am here.\",\"portraits\":[],\"positions\":[]}]");
            file_text_close(_file);

            var _state = GameStoryStateCreate();
            expect(GameStoryBegin(_state, "test_story.json")).toBeTruthy();
            expect(_state.reveal_characters).toBe(0);
            expect(_state.reveal_complete).toBeFalsy();

            expect(GameStoryRevealStep(_state)).toBeTruthy();
            expect(_state.reveal_characters).toBe(1);
            expect(GameStoryRevealStep(_state)).toBeFalsy();
            expect(_state.reveal_characters).toBe(1);
            expect(GameStoryTypewriterDelayForCharacter(",")).toBeGreaterThan(
                GameStoryTypewriterDelayForCharacter("W"));

            expect(GameStoryContinue(_state)).toBeTruthy();
            expect(_state.reveal_complete).toBeTruthy();
            expect(_state.reveal_characters).toBe(string_length("Wait, Moon."));
            expect(_state.frame_index).toBe(0);

            expect(GameStoryContinue(_state)).toBeTruthy();
            expect(_state.frame_index).toBe(1);
            expect(_state.reveal_characters).toBe(0);
            expect(_state.reveal_complete).toBeFalsy();
        });

        test("Story continue arrow follows the imported eight-frame 3 fps loop", function() {
            expect(GameStoryTextArrowFrameGet(0, 8)).toBe(0);
            expect(GameStoryTextArrowFrameGet(333, 8)).toBe(0);
            expect(GameStoryTextArrowFrameGet(334, 8)).toBe(1);
            expect(GameStoryTextArrowFrameGet(2666, 8)).toBe(7);
            expect(GameStoryTextArrowFrameGet(2667, 8)).toBe(0);
        });

        test("Typewriter text keeps the final two-line wrapping stable", function() {
            draw_set_font(fn_dialogue_speech);
            var _text = "Moonlight gathers over the water while Selkie keeps the bow pointed straight into the tide.";
            var _full = GameStoryTextLinesCreate(_text, 240, 2);
            var _partial = GameStoryVisibleLinesCreate(_text, 240, 2, 20);

            expect(array_length(_partial)).toBe(array_length(_full));
            expect(string_length(_partial[0])).toBe(20);
            expect(_partial[1]).toBe("");
        });

        test("Opening story included file loads from the project datafiles", function() {
            var _frames = GameStoryLoadFramesFromFile("opening_story_v2.json");

            expect(array_length(_frames)).toBe(10);
            expect(_frames[0].name).toBe("");
            expect(array_length(_frames[0].portraits)).toBe(0);
            expect(array_length(_frames[0].backgrounds)).toBe(1);
            expect(_frames[0].backgrounds[0]).toBe("spr_story_bg_core_chapel");
            expect(_frames[1].name).toBe("Moon");
            expect(_frames[2].name).toBe("Selkie");
            expect(_frames[5].text).toBe("I named my ship Sunset because it carries every ending I could not accept.");
            expect(_frames[6].text).toBe("Then Sunrise will be the answer. I will bring you back from the dark.");
        });

        test("Final boss stories stay in rm_game and match the selected route", function() {
            var _moon_route = GameStoryLoadFramesFromFile("boss_intro_story_v2.json");
            var _selkie_route = GameStoryLoadFramesFromFile("boss_intro_story_selkie_route_v2.json");

            expect(array_length(_moon_route)).toBe(10);
            expect(array_length(_selkie_route)).toBe(10);
            expect(_moon_route[0].name).toBe("Moon");
            expect(_moon_route[2].name).toBe("Selkie");
            expect(array_length(_moon_route[0].backgrounds)).toBe(1);
            expect(_moon_route[0].backgrounds[0]).toBe("spr_story_bg_violet_horizon");
            expect(array_length(_moon_route[2].portraits)).toBe(2);
            expect(_selkie_route[0].name).toBe("Selkie");
            expect(_selkie_route[2].name).toBe("Moon");
            expect(array_length(_selkie_route[0].backgrounds)).toBe(1);
            expect(_selkie_route[0].backgrounds[0]).toBe("spr_story_bg_violet_horizon");
            expect(array_length(_selkie_route[2].portraits)).toBe(2);

            global.game_runtime.selected_ship_id = SHIP_SUNRISE;
            expect(GameFinalBossStoryFileGet()).toBe("boss_intro_story_v2.json");

            global.game_runtime.selected_ship_id = SHIP_SELKIE;
            expect(GameFinalBossStoryFileGet()).toBe("boss_intro_story_selkie_route_v2.json");
        });

        test("Character bosses have route-specific dialogue around motif-specific fights", function() {
            var _bosses = [
                { stage: 1, story_id: "shalmii", name: SHALMII_BOSS_NAME, portrait: "spr_shalmii_portrait", second_moon: "Moon", second_selkie: "Selkie" },
                { stage: 2, story_id: "aster", name: ASTER_BOSS_NAME, portrait: "spr_aster_portrait", second_moon: "Moon", second_selkie: "Selkie" },
                { stage: 3, story_id: "mira_aisha", name: MIRA_BOSS_NAME, portrait: "spr_mira_portrait", second_moon: "Aisha", second_selkie: "Aisha" },
                { stage: 4, story_id: "caelia", name: CAELIA_BOSS_NAME, portrait: "spr_caelia_portrait", second_moon: "Moon", second_selkie: "Selkie" },
            ];

            for (var i = 0; i < array_length(_bosses); i++) {
                var _boss = _bosses[i];
                var _moon_intro_file = GameCharacterBossStoryFileGet(_boss.stage, false, SHIP_SUNRISE);
                var _moon_defeat_file = GameCharacterBossStoryFileGet(_boss.stage, true, SHIP_SUNRISE);
                var _selkie_intro_file = GameCharacterBossStoryFileGet(_boss.stage, false, SHIP_SELKIE);
                var _selkie_defeat_file = GameCharacterBossStoryFileGet(_boss.stage, true, SHIP_SELKIE);
                var _moon_intro = GameStoryLoadFramesFromFile(_moon_intro_file);
                var _moon_defeat = GameStoryLoadFramesFromFile(_moon_defeat_file);
                var _selkie_intro = GameStoryLoadFramesFromFile(_selkie_intro_file);
                var _selkie_defeat = GameStoryLoadFramesFromFile(_selkie_defeat_file);

                expect(_moon_intro_file).toBe(_boss.story_id + "_intro_story_moon_route_v2.json");
                expect(_moon_defeat_file).toBe(_boss.story_id + "_defeat_story_moon_route_v2.json");
                expect(_selkie_intro_file).toBe(_boss.story_id + "_intro_story_selkie_route_v2.json");
                expect(_selkie_defeat_file).toBe(_boss.story_id + "_defeat_story_selkie_route_v2.json");
                expect(array_length(_moon_intro)).toBe(6);
                expect(array_length(_moon_defeat)).toBe(6);
                expect(array_length(_selkie_intro)).toBe(6);
                expect(array_length(_selkie_defeat)).toBe(6);
                expect(_moon_intro[0].name).toBe(_boss.name);
                expect(_moon_intro[0].portraits[0]).toBe(_boss.portrait);
                expect(_moon_intro[1].name).toBe(_boss.second_moon);
                expect(_moon_defeat[5].name).toBe("Moon");
                expect(_selkie_intro[1].name).toBe(_boss.second_selkie);
                expect(_selkie_defeat[5].name).toBe("Selkie");
            }

            expect(GameCharacterBossStoryFileGet(STAGE_COUNT, false, SHIP_SUNRISE)).toBe("");
        });

        test("Story textbox wrapping never exceeds two lines", function() {
            draw_set_font(fn_dialogue_speech);

            var _lines = GameStoryTextLinesCreate("Moonlight gathers over the water while Selkie keeps the bow pointed straight into the tide.", 240, 2);

            expect(array_length(_lines)).toBe(2);
        });

        test("Ending story uses the authored morning reunion behind its portraits", function() {
            var _frames = GameStoryLoadFramesFromFile("ending_story_v2.json");
            var _selkie_route = GameStoryLoadFramesFromFile("ending_story_selkie_route_v2.json");

            expect(array_length(_frames)).toBe(7);
            expect(array_length(_selkie_route)).toBe(7);
            expect(array_length(_frames[0].backgrounds)).toBe(1);
            expect(_frames[0].backgrounds[0]).toBe("spr_story_bg_morning_reunion");
            expect(_frames[0].name).toBe("");
            expect(array_length(_frames[0].portraits)).toBe(0);
            expect(array_length(_frames[4].portraits)).toBe(2);
            expect(_selkie_route[1].name).toBe("Selkie");
            expect(_selkie_route[2].name).toBe("Moon");

            global.game_runtime.selected_ship_id = SHIP_SUNRISE;
            expect(GameEndingStoryFileGet()).toBe("ending_story_v2.json");

            global.game_runtime.selected_ship_id = SHIP_SELKIE;
            expect(GameEndingStoryFileGet()).toBe("ending_story_selkie_route_v2.json");
        });

        test("Opening story completion transitions into rm_game", function() {
            expect(GameStoryTransitionRoomGet(rm_opening, true, false)).toBe(rm_game);
            expect(GameStoryTransitionRoomGet(rm_opening, true, true)).toBe(-1);
            expect(GameStoryTransitionRoomGet(rm_game, true, false)).toBe(-1);
        });

        test("Ending story completion saves the run and transitions into credits before runtime reset", function() {
            global.game_save.high_score.ship_A = [90000, 70000, 50000, 30000, 10000, 8000, 6000, 4000, 2000, 1000];
            global.game_save.continues_used.ship_A = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            global.game_runtime.selected_ship_id = "ship_A";
            global.game_runtime.selected_ship_index = 0;
            global.game_runtime.score = 42000;
            global.game_runtime.continues_used = 2;
            global.game_runtime.signals.dialogue = true;

            var _next_room = GameStoryTransitionRoomGet(rm_ending, true, false);

            expect(_next_room).toBe(rm_credits);
            expect(global.game_save.high_score.ship_A[0]).toBe(90000);
            expect(global.game_save.high_score.ship_A[1]).toBe(70000);
            expect(global.game_save.high_score.ship_A[2]).toBe(50000);
            expect(global.game_save.high_score.ship_A[3]).toBe(42000);
            expect(global.game_save.high_score.ship_A[4]).toBe(30000);
            expect(global.game_save.continues_used.ship_A[2]).toBe(2);
            expect(global.game_save.continues_used.ship_A[3]).toBe(2);
            expect(global.game_save.continues_used.ship_A[4]).toBe(3);
            expect(global.game_save.runs_finished.ship_A[0]).toBe(1);
            expect(file_exists(GameSavePathGet())).toBeTruthy();
            expect(global.game_runtime.score).toBe(42000);
            expect(global.game_runtime.continues_used).toBe(2);
            expect(global.game_runtime.selected_ship_id).toBe("ship_A");
            expect(global.game_runtime.signals.dialogue).toBeFalsy();

            var _file = file_text_open_read(GameSavePathGet());
            var _json_string = file_text_read_string(_file);
            file_text_close(_file);

            var _save = json_parse(_json_string);
            expect(_save.high_score.ship_A[3]).toBe(42000);
            expect(_save.continues_used.ship_A[3]).toBe(2);
            expect(_save.runs_finished.ship_A[0]).toBe(1);
        });
    });
});

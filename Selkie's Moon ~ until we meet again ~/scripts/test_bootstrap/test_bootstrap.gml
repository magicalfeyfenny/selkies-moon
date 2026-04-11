suite(function() {
    section("Game setup", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();

            if (file_exists(GameSavePathGet())) {
                file_delete(GameSavePathGet());
            }

            if (file_exists(GameConfigPathGet())) {
                file_delete(GameConfigPathGet());
            }
        });

        afterEach(function() {
            if (file_exists(GameSavePathGet())) {
                file_delete(GameSavePathGet());
            }

            if (file_exists(GameConfigPathGet())) {
                file_delete(GameConfigPathGet());
            }
        });

        test("Default config keeps the playfield at 640x360", function() {
            var _config = GameConfigCreateDefault();

            expect(_config.version).toBe(CONFIG_VERSION);
            expect(_config.view_width).toBe(640);
            expect(_config.view_height).toBe(360);
            expect(_config.target_fps).toBe(60);
            expect(_config.input_device).toBe("keyboard");
        });

        test("Default save data starts clean", function() {
            var _save = GameSaveDataCreateDefault();

            expect(_save.version).toBe(SAVE_VERSION);
            expect(array_length(_save.high_score.ship_A)).toBe(10);
            expect(_save.high_score.ship_A[0]).toBe(0);
            expect(_save.runs_started.ship_A[0]).toBe(0);
            expect(_save.runs_finished.ship_A[0]).toBe(0);
            expect(_save.continues_used.ship_A[0]).toBe(0);
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
        });

        test("LoadGameSave rejects an old save version", function() {
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
        });

        test("LoadGameConfig rejects an old config version", function() {
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
    });

    section("Title menu", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            if (file_exists(GameConfigPathGet())) {
                file_delete(GameConfigPathGet());
            }
        });

        afterEach(function() {
            if (file_exists(GameConfigPathGet())) {
                file_delete(GameConfigPathGet());
            }
        });

        test("Title state starts on the press start screen", function() {
            var _state = GameTitleStateCreate();

            expect(_state.phase).toBe("press_start");
            expect(_state.page).toBe("main");
            expect(array_length(_state.main_items)).toBe(4);
            expect(array_length(_state.characters)).toBe(1);
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

            expect(_state.main_index).toBe(3);
            expect(_state.main_items[_state.main_index].id).toBe("quit");
        });

        test("Start Game opens the character select submenu", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, true, false));

            expect(_state.page).toBe("character_select");
        });

        test("Scores submenu returns to main on bomb", function() {
            var _state = GameTitleStateCreate();
            _state.phase = "menu";
            _state.page = "scores";

            GameTitleStateStep(_state, GameTitleInputSnapshotCreate(false, false, false, false, false, true));

            expect(_state.page).toBe("main");
        });

        test("Options menu only exposes fullscreen and display scale", function() {
            var _entries = GameTitleConfigEntriesCreate();

            expect(array_length(_entries)).toBe(2);
            expect(_entries[0].id).toBe("fullscreen");
            expect(_entries[1].id).toBe("display_scale");
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
    });

    section("Story UI", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            if (file_exists("test_story.json")) {
                file_delete("test_story.json");
            }
        });

        afterEach(function() {
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

        test("Opening story included file loads from the project datafiles", function() {
            var _frames = GameStoryLoadFramesFromFile("opening_story.json");

            expect(array_length(_frames)).toBe(3);
            expect(_frames[0].name).toBe("Selkie");
            expect(array_length(_frames[0].portraits)).toBe(2);
        });

        test("Opening story completion transitions into rm_game", function() {
            expect(GameStoryTransitionRoomGet(rm_opening, true, false)).toBe(rm_game);
            expect(GameStoryTransitionRoomGet(rm_opening, true, true)).toBe(-1);
            expect(GameStoryTransitionRoomGet(rm_game, true, false)).toBe(-1);
        });
    });
});

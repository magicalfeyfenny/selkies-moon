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
            expect(_config.room_width).toBe(640);
            expect(_config.room_height).toBe(360);
            expect(_config.target_fps).toBe(60);
        });

        test("Default save data starts clean", function() {
            var _save = GameSaveDataCreateDefault();

            expect(_save.version).toBe(SAVE_VERSION);
            expect(_save.high_score).toBe(0);
            expect(_save.runs_started).toBe(0);
            expect(_save.options.display_scale).toBe(2);
            expect(_save.options.fullscreen).toBeFalsy();
        });

        test("LoadGameSave loads a matching save file", function() {
            var _save = GameSaveDataCreateDefault();
            _save.high_score = 777;
            _save.runs_started = 4;
            _save.options.fullscreen = true;

            var _file = file_text_open_write(GameSavePathGet());
            file_text_write_string(_file, json_stringify(_save));
            file_text_close(_file);

            global.game_save = GameSaveDataCreateDefault();

            expect(LoadGameSave()).toBeTruthy();
            expect(global.game_save.high_score).toBe(777);
            expect(global.game_save.runs_started).toBe(4);
            expect(global.game_save.options.fullscreen).toBeTruthy();
        });

        test("LoadGameSave rejects an old save version", function() {
            var _save = GameSaveDataCreateDefault();
            _save.version = SAVE_VERSION + 1;
            _save.high_score = 999;

            var _file = file_text_open_write(GameSavePathGet());
            file_text_write_string(_file, json_stringify(_save));
            file_text_close(_file);

            global.game_save = GameSaveDataCreateDefault();

            expect(LoadGameSave()).toBeFalsy();
            expect(global.game_save.high_score).toBe(0);
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
            expect(global.game_config.version).toBe(CONFIG_VERSION);
            expect(global.game_save.version).toBe(SAVE_VERSION);
        });
    });
});

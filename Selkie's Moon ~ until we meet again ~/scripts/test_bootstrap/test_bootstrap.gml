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

        test("Title art metadata uses the Sunrise ship preview", function() {
            var _characters = GameTitleCharactersCreate();

            expect(_characters[0].name).toBe("Sunrise");
            expect(_characters[0].preview_sprite).toBe("spr_sunrise");
        });
    });

    section("Gameplay", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            if (file_exists(GameSavePathGet())) {
                file_delete(GameSavePathGet());
            }
        });

        afterEach(function() {
            if (file_exists(GameSavePathGet())) {
                file_delete(GameSavePathGet());
            }
        });

        test("Default runtime includes continue and berserk state", function() {
            var _runtime = GameRuntimeDataCreateDefault();

            expect(_runtime.signals.continue_request).toBeFalsy();
            expect(_runtime.continue_screen.mode).toBe("prompt");
            expect(_runtime.meter).toBe(0);
            expect(_runtime.is_berserk).toBeFalsy();
            expect(_runtime.stage_frame).toBe(0);
        });

        test("Run start initialization records a run and defaults the ship", function() {
            GameRunStartInitialize();

            expect(global.game_runtime.selected_ship_id).toBe("ship_A");
            expect(global.game_runtime.selected_ship_index).toBe(0);
            expect(global.game_runtime.run_started_recorded).toBeTruthy();
            expect(global.game_save.runs_started.ship_A[0]).toBe(1);
            expect(file_exists(GameSavePathGet())).toBeTruthy();
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

        test("One volley tick creates twelve player shots with the intended direction and sprite split", function() {
            var _shots = GamePlayerShotSpawnSpecsCreate(100, 100);
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
        });

        test("Sample enemy bead shots aim at the player and use the centered 8 px hit circle", function() {
            var _shot = GameSampleEnemyShotSpecCreate(100, 120, 100, 220);
            var _spawn = GameSceneSampleEnemySpawnPositionGet(CAMERA_HOME_X, CAMERA_HOME_Y);

            expect(_shot.object_index).toBe(obj_bullet_bead);
            expect(_shot.direction).toBe(270);
            expect(_shot.speed).toBe(SAMPLE_ENEMY_BULLET_SPEED);
            expect(GamePlayerBulletHitCheck(100, 100, 105, 100, 4)).toBeTruthy();
            expect(GamePlayerBulletHitCheck(100, 100, 106, 100, 4)).toBeFalsy();
            expect(_spawn.x).toBe(CAMERA_HOME_X);
            expect(_spawn.y).toBe(CAMERA_HOME_Y - PLAYFIELD_HALF_HEIGHT + 72);
        });

        test("Cancel meter rewards trigger berserk at one thousand", function() {
            global.game_runtime.meter = 999;

            expect(GamePlayerMeterRewardApply(1)).toBeTruthy();
            expect(global.game_runtime.is_berserk).toBeTruthy();
            expect(global.game_runtime.meter).toBe(METER_MAX);
            expect(GamePlayerSwordPoseCreate(0, true).length).toBe(SWORD_LENGTH * BERSERK_SWORD_MULTIPLIER);
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

        test("Imported art sprites are registered with the expected sizes", function() {
            var _bullet_bead = asset_get_index("spr_bullet_bead");
            var _bullet_bead_mask = asset_get_index("spr_bullet_bead_mask");
            var _logo = asset_get_index("spr_logo");
            var _sunrise = asset_get_index("spr_sunrise");
            var _sunrise_bullet = asset_get_index("spr_sunrise_bullet");
            var _sunset_bullet = asset_get_index("spr_sunset_bullet");
            var _textbox = asset_get_index("spr_textbox");
            var _violet_tiles = asset_get_index("spr_violet_tiles");

            expect(_bullet_bead != -1 && sprite_exists(_bullet_bead)).toBeTruthy();
            expect(_bullet_bead_mask != -1 && sprite_exists(_bullet_bead_mask)).toBeTruthy();
            expect(_logo != -1 && sprite_exists(_logo)).toBeTruthy();
            expect(_sunrise != -1 && sprite_exists(_sunrise)).toBeTruthy();
            expect(_sunrise_bullet != -1 && sprite_exists(_sunrise_bullet)).toBeTruthy();
            expect(_sunset_bullet != -1 && sprite_exists(_sunset_bullet)).toBeTruthy();
            expect(_textbox != -1 && sprite_exists(_textbox)).toBeTruthy();
            expect(_violet_tiles != -1 && sprite_exists(_violet_tiles)).toBeTruthy();
            expect(object_exists(obj_bullet_bead)).toBeTruthy();
            expect(object_exists(obj_enemy_sample)).toBeTruthy();
            expect(sprite_get_width(_bullet_bead)).toBe(12);
            expect(sprite_get_width(_bullet_bead_mask)).toBe(12);
            expect(sprite_get_width(_sunrise)).toBe(64);
            expect(sprite_get_width(_sunrise_bullet)).toBe(8);
            expect(sprite_get_height(_sunset_bullet)).toBe(8);
            expect(sprite_get_width(_textbox)).toBe(640);
            expect(sprite_get_height(_textbox)).toBe(130);
            expect(sprite_get_width(_violet_tiles)).toBe(128);
            expect(sprite_get_height(_violet_tiles)).toBe(128);
        });
    });

    section("Story UI", function() {
        beforeEach(function() {
            global.game_config = GameConfigCreateDefault();
            global.game_save = GameSaveDataCreateDefault();
            global.game_runtime = GameRuntimeDataCreateDefault();

            if (file_exists(GameSavePathGet())) {
                file_delete(GameSavePathGet());
            }

            if (file_exists("test_story.json")) {
                file_delete("test_story.json");
            }
        });

        afterEach(function() {
            if (file_exists(GameSavePathGet())) {
                file_delete(GameSavePathGet());
            }

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
            expect(_frames[1].name).toBe("Moon");
            expect(_frames[0].portraits[0]).toBe("spr_selkie_portrait");
        });

        test("Story textbox wrapping never exceeds two lines", function() {
            draw_set_font(fn_dialogue_speech);

            var _lines = GameStoryTextLinesCreate("Moonlight gathers over the water while Selkie keeps the bow pointed straight into the tide.", 240, 2);

            expect(array_length(_lines)).toBe(2);
        });

        test("Opening story completion transitions into rm_game", function() {
            expect(GameStoryTransitionRoomGet(rm_opening, true, false)).toBe(rm_game);
            expect(GameStoryTransitionRoomGet(rm_opening, true, true)).toBe(-1);
            expect(GameStoryTransitionRoomGet(rm_game, true, false)).toBe(-1);
        });

        test("Ending story completion stores aligned score and continue entries, saves, resets runtime, and returns to title", function() {
            global.game_save.high_score.ship_A = [90000, 70000, 50000, 30000, 10000, 8000, 6000, 4000, 2000, 1000];
            global.game_save.continues_used.ship_A = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            global.game_runtime.selected_ship_id = "ship_A";
            global.game_runtime.selected_ship_index = 0;
            global.game_runtime.score = 42000;
            global.game_runtime.continues_used = 2;
            global.game_runtime.signals.dialogue = true;

            var _next_room = GameStoryTransitionRoomGet(rm_ending, true, false);

            expect(_next_room).toBe(rm_title);
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
            expect(global.game_runtime.score).toBe(0);
            expect(global.game_runtime.continues_used).toBe(0);
            expect(global.game_runtime.selected_ship_id).toBe("");
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

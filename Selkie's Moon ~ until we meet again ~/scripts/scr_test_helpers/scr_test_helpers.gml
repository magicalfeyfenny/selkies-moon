// Automation-only launch detection, persistence isolation, and visual QA tour.

/// @func GameDirectoryPathNormalize(path)
/// Normalizes a directory path to forward slashes with a trailing slash.
function GameDirectoryPathNormalize(_path) {
    _path = string_replace_all(_path, "\\", "/");

    if (_path == "") {
        return "";
    }

    if (string_char_at(_path, string_length(_path)) != "/") {
        _path += "/";
    }

    return _path;
}

/// @func GameWorkingDirectoryGet()
/// Returns the normalized runtime working directory.
function GameWorkingDirectoryGet() {
    return GameDirectoryPathNormalize(working_directory);
}

/// @func GameTestsMarkerPathGet()
/// Returns the marker file path used by the external GMTL runner.
function GameTestsMarkerPathGet() {
    return GameWorkingDirectoryGet() + ".run-gmtl-tests.txt";
}

/// @func GameCommandLineHasFlag(flag)
/// Checks whether the current run was launched with a specific CLI flag.
function GameCommandLineHasFlag(_flag) {
    var _parameter_total = parameter_count();

    for (var i = 1; i <= _parameter_total; i++) {
        if (parameter_string(i) == _flag) {
            return true;
        }
    }

    return false;
}

/// @func GameShouldQuitAfterTests()
/// Returns whether the game should close itself after finishing tests.
function GameShouldQuitAfterTests() {
    var _has_marker = file_exists(GameTestsMarkerPathGet());
    var _has_test_flag = GameCommandLineHasFlag("--run-test") || GameCommandLineHasFlag("-runTest");

    return _has_test_flag || _has_marker;
}

/// @func GameShouldRunTests()
/// Returns whether this launch should boot into GMTL test mode.
function GameShouldRunTests() {
    return GameShouldQuitAfterTests();
}

/// @func GameTestPersistenceFilesDelete()
/// Removes only automation-namespaced persistence and recovery artifacts.
function GameTestPersistenceFilesDelete() {
    var _paths = [
        GameSavePathGet(),
        GameConfigPathGet(),
        GamePersistenceBackupPathGet(GameSavePathGet()),
        GamePersistenceBackupPathGet(GameConfigPathGet()),
    ];

    for (var i = 0; i < array_length(_paths); i++) {
        if (file_exists(_paths[i])) {
            file_delete(_paths[i]);
        }
    }
}

/// @func GameVisualTourMarkerPathGet()
/// Returns the marker file path used by local visual QA capture runs.
function GameVisualTourMarkerPathGet() {
    return GameWorkingDirectoryGet() + ".visual-tour.txt";
}

/// @func GameShouldRunVisualTour()
/// Returns whether the local visual QA tour should drive the runner.
function GameShouldRunVisualTour() {
    return file_exists(GameVisualTourMarkerPathGet()) || GameCommandLineHasFlag("--visual-tour");
}

/// @func GameVisualTourOutputDirectoryGet()
/// Returns the runner-sandbox screenshot directory reported by working_directory.
function GameVisualTourOutputDirectoryGet() {
    return "visual-tour/";
}

/// @func GameVisualTourStateEnsure()
/// Creates the local-only visual QA state machine.
function GameVisualTourStateEnsure() {
    if (!variable_global_exists("visual_tour")) {
        var _output_dir = GameVisualTourOutputDirectoryGet();
        directory_create(_output_dir);

        global.visual_tour = {
            step: 0,
            wait: 18,
            prepared: false,
            output_dir: _output_dir,
            pending_capture_name: "",
            pending_capture_path: "",
            capture_count: 0,
            expected_capture_count: 27,
            completion_wait_logged: false,
        };

        show_debug_message("VISUAL_TOUR_OUTPUT_SANDBOX " + _output_dir);
        show_debug_message("VISUAL_TOUR_OUTPUT_NOTE Relative paths are stored in the runner's GameMaker save sandbox.");
    }

    return global.visual_tour;
}

/// @func GameVisualTourAdvance()
/// Advances the visual QA state machine to the next capture setup.
function GameVisualTourAdvance() {
    global.visual_tour.step += 1;
    global.visual_tour.prepared = false;
    global.visual_tour.wait = 10;
}

/// @func GameVisualTourCaptureQueue(name)
/// Queues one capture for Draw GUI End, after all world and GUI layers render.
function GameVisualTourCaptureQueue(_name) {
    if (global.visual_tour.pending_capture_name != "") {
        return false;
    }

    global.visual_tour.pending_capture_name = _name;
    global.visual_tour.pending_capture_path = global.visual_tour.output_dir + _name + ".png";
    show_debug_message("VISUAL_TOUR_CAPTURE_QUEUED " + global.visual_tour.pending_capture_path);
    return true;
}

/// @func GameVisualTourCapturePendingDrawGuiEnd()
/// Writes the queued frame from Draw GUI End, then and only then advances the tour.
function GameVisualTourCapturePendingDrawGuiEnd() {
    if (!GameShouldRunVisualTour() || !variable_global_exists("visual_tour")) {
        return false;
    }

    var _tour = global.visual_tour;
    if (_tour.pending_capture_name == "") {
        return false;
    }

    var _capture_name = _tour.pending_capture_name;
    var _capture_path = _tour.pending_capture_path;

    screen_save(_capture_path);
    _tour.capture_count += 1;
    _tour.pending_capture_name = "";
    _tour.pending_capture_path = "";

    show_debug_message("VISUAL_TOUR_CAPTURE_SANDBOX " + _capture_path);
    show_debug_message("VISUAL_TOUR_CAPTURE_COMPLETE " + string(_tour.capture_count)
        + "/" + string(_tour.expected_capture_count) + " " + _capture_name);

    GameVisualTourAdvance();
    return true;
}

/// @func GameVisualTourTitlePrepare(page, main_index)
/// Places the title UI on a specific menu page for visual capture.
function GameVisualTourTitlePrepare(_page, _main_index) {
    if (room != rm_title) {
        room_goto(rm_title);
        return false;
    }

    var _title = instance_find(obj_UI_title, 0);
    if (_title == noone) {
        return false;
    }

    _title.title_state.phase = (_page == "press_start") ? "press_start" : "menu";
    _title.title_state.page = (_page == "press_start") ? "main" : _page;
    _title.title_state.main_index = _main_index;
    _title.title_state.select_character_index = clamp(_main_index, 0, 1);
    _title.title_state.gallery_index = 1;
    _title.title_state.music_index = 9;

    if (_page == "practice") {
        _title.title_state.practice_config = GamePracticeConfigNormalize({
            ship_id: SHIP_SELKIE,
            ship_index: 1,
            stage: 8,
            segment: PRACTICE_SEGMENT_BOSS,
            power: PLAYER_POWER_MAX,
            rank: 80,
            dynamic_rank: false,
            lives: 5,
            bombs: 4,
            meter: 700,
        });
        _title.title_state.practice_index = 4;
    }

    return true;
}

/// @func GameVisualTourPausePrepare(page)
/// Starts a deterministic practice room and exposes one dedicated pause page.
function GameVisualTourPausePrepare(_page) {
    if (room != rm_game || !GameRunIsPractice()) {
        var _practice = GamePracticeConfigCreateDefault();
        _practice.ship_id = SHIP_SELKIE;
        _practice.ship_index = 1;
        _practice.stage = 8;
        _practice.segment = PRACTICE_SEGMENT_BOSS;
        _practice.power = PLAYER_POWER_MAX;
        _practice.rank = 80;
        _practice.dynamic_rank = false;
        _practice.lives = 5;
        _practice.bombs = 4;
        _practice.meter = 700;
        GamePracticeRunRequestConfigure(_practice);
        room_goto(rm_game);
        return false;
    }

    var _pause = instance_find(obj_UI_menu, 0);
    if (_pause == noone) {
        return false;
    }

    global.game_runtime.signals.dialogue = false;
    global.game_runtime.signals.continue_request = false;
    global.game_runtime.signals.paused = true;
    _pause.pause_state.active = true;
    _pause.pause_state.close_requested = false;
    _pause.pause_state.page = _page;
    _pause.pause_state.main_index = 2;
    _pause.pause_state.options_index = 1;
    _pause.pause_state.practice_index = 1;
    _pause.pause_state.quit_index = 1;
    return true;
}

/// @func GameVisualTourStoryPrepare(room_id)
/// Moves to a story room and waits until its default story is active.
function GameVisualTourStoryPrepare(_room_id) {
    if (room != _room_id) {
        room_goto(_room_id);
        return false;
    }

    var _story = instance_find(obj_UI_story, 0);
    return _story != noone && global.game_runtime.signals.dialogue;
}

/// @func GameVisualTourCreditsPrepare()
/// Holds the credits at a representative, fully readable scroll position.
function GameVisualTourCreditsPrepare() {
    if (room != rm_credits) {
        room_goto(rm_credits);
        return false;
    }

    var _credits = instance_find(obj_UI_credits, 0);
    if (_credits == noone) {
        return false;
    }

    if (!global.visual_tour.prepared) {
        _credits.credits_scroll_y = 112;
    }

    return true;
}

/// @func GameVisualTourGameplayPrepare(stage, mode)
/// Places gameplay into a representative stage, combat, boss, or clear state.
function GameVisualTourGameplayPrepare(_stage, _mode) {
    if (room != rm_game) {
        global.game_runtime.selected_ship_id = SHIP_SUNRISE;
        global.game_runtime.selected_ship_index = 0;
        room_goto(rm_game);
        return false;
    }

    var _scene = instance_find(obj_scene_manager, 0);
    var _player = instance_find(obj_player, 0);
    if (_scene == noone || _player == noone) {
        return false;
    }

    // Once the scene has settled, leave its instances intact through the draw
    // that captures it. Rebuilding a boss on the capture frame can leave a
    // partially composed GUI surface in the macOS runner.
    if (variable_global_exists("visual_tour") && global.visual_tour.prepared) {
        return true;
    }

    GameSceneCombatClear();
    with (obj_boss_parent) {
        instance_destroy();
    }

    global.game_runtime.current_stage = clamp(_stage, 1, STAGE_COUNT);
    global.game_runtime.stage_frame = 360;
    global.game_runtime.stage_notice_timer = (_mode == "notice") ? STAGE_NOTICE_FRAMES : 0;
    global.game_runtime.signals.dialogue = false;
    global.game_runtime.score = 128400 + (_stage * 7600);
    global.game_runtime.power = min(PLAYER_POWER_MAX, 2 + (_stage div 3));
    global.game_runtime.meter = (_stage * 70) mod METER_MAX;

    _scene.scene_state.frame = 360;
    _scene.scene_state.mode = "scroll";
    _scene.scene_state.target_x = CAMERA_HOME_X;
    _scene.scene_state.camera_x = CAMERA_HOME_X;
    _scene.scene_state.camera_y = CAMERA_HOME_Y;
    _scene.scene_state.scroll_speed = (_mode == "notice") ? CAMERA_SCROLL_SPEED : 0;
    _scene.scene_state.boss_spawned = false;
    _scene.scene_state.boss_defeated = false;
    _scene.scene_state.stage_clear_timer = 0;

    _player.x = CAMERA_HOME_X;
    _player.y = CAMERA_HOME_Y + 118;
    _player.sprite_index = GamePlayerShipSpriteGet(GameRunShipIdGet());

    if (_mode == "combat") {
        var _left = CAMERA_HOME_X - 70;
        var _right = CAMERA_HOME_X + 70;
        var _enemy_a = instance_create_layer(_left, CAMERA_HOME_Y - 88, "Instances", obj_enemy_variant);
        GameEnemyVariantConfigure(_enemy_a, ENEMY_VARIANT_KELP, _stage, 0, 3);
        var _enemy_b = instance_create_layer(CAMERA_HOME_X, CAMERA_HOME_Y - 122, "Instances", obj_enemy_variant);
        GameEnemyVariantConfigure(_enemy_b, ENEMY_VARIANT_WISP, _stage, 1, 3);
        var _enemy_c = instance_create_layer(_right, CAMERA_HOME_Y - 92, "Instances", obj_enemy_variant);
        GameEnemyVariantConfigure(_enemy_c, ENEMY_VARIANT_NEEDLE, _stage, 2, 3);

        for (var i = 0; i < 12; i++) {
            GameEnemyBulletLinearSpawn(CAMERA_HOME_X - 110 + (i * 20), CAMERA_HOME_Y - 18 + ((i mod 3) * 18), 260 + (i * 7), 1.8);
        }

        var _shots = GamePlayerShotSpawnSpecsCreate(_player.x, _player.y, GameRunShipIdGet(), true, global.game_runtime.power);
        for (var j = 0; j < array_length(_shots); j++) {
            var _shot = instance_create_layer(_shots[j].x, _shots[j].y - 36, "Instances", obj_player_shot);
            _shot.move_direction = _shots[j].direction;
            _shot.move_speed = 0;
            _shot.shot_sprite = _shots[j].sprite_id;
            _shot.damage = _shots[j].damage;
            _shot.shot_scale = _shots[j].scale;
            _shot.shot_color = _shots[j].color;
            _shot.shot_accent_color = _shots[j].accent_color;
            _shot.shot_power = _shots[j].power;
            _shot.shot_focused = _shots[j].focused;
        }
    } else if (_mode == "boss") {
        global.game_runtime.current_stage = _stage;
        _scene.scene_state.mode = "boss_fight";
        _scene.scene_state.boss_spawned = true;
        var _boss = instance_create_layer(CAMERA_HOME_X, CAMERA_HOME_Y - 92, "Instances", obj_boss_sunset);
        _boss.attack_timer = 90;
    } else if (_mode == "clear") {
        _scene.scene_state.mode = "stage_clear";
        _scene.scene_state.stage_clear_timer = STAGE_CLEAR_DELAY_FRAMES;
        global.game_runtime.stage_complete = true;
    }

    return true;
}

/// @func GameVisualTourPrepareAndCapture(name, ready)
/// Captures a prepared view after enough frames have rendered.
function GameVisualTourPrepareAndCapture(_name, _ready) {
    if (!global.visual_tour.prepared) {
        if (!_ready) {
            global.visual_tour.wait = 16;
            return true;
        }

        global.visual_tour.prepared = true;
        global.visual_tour.wait = 8;
        return true;
    }

    if (global.visual_tour.pending_capture_name == "") {
        GameVisualTourCaptureQueue(_name);
    }

    return true;
}

/// @func GameVisualTourStep()
/// Runs a local-only automated screenshot tour when explicitly requested.
function GameVisualTourStep() {
    if (!GameShouldRunVisualTour()) {
        return false;
    }

    var _tour = GameVisualTourStateEnsure();
    if (_tour.wait > 0) {
        _tour.wait -= 1;
        return true;
    }

    switch (_tour.step) {
        case 0:
            return GameVisualTourPrepareAndCapture("00_title_press_start",
                GameVisualTourTitlePrepare("press_start", 0));
        case 1:
            return GameVisualTourPrepareAndCapture("01_title_main_menu",
                GameVisualTourTitlePrepare("main", 0));
        case 2:
            return GameVisualTourPrepareAndCapture("02_title_character_select",
                GameVisualTourTitlePrepare("character_select", 1));
        case 3:
            return GameVisualTourPrepareAndCapture("03_title_gallery",
                GameVisualTourTitlePrepare("cg_gallery", 2));
        case 4:
            return GameVisualTourPrepareAndCapture("04_title_music_room",
                GameVisualTourTitlePrepare("music_room", 3));
        case 5:
            return GameVisualTourPrepareAndCapture("05_opening_story",
                GameVisualTourStoryPrepare(rm_opening));
    }

    if (_tour.step >= 6 && _tour.step < 16) {
        var _stage = _tour.step - 5;
        var _stage_label = (_stage < 10) ? "0" + string(_stage) : string(_stage);
        return GameVisualTourPrepareAndCapture("stage_" + _stage_label + "_notice",
            GameVisualTourGameplayPrepare(_stage, "notice"));
    }

    switch (_tour.step) {
        case 16:
            return GameVisualTourPrepareAndCapture("16_stage_04_combat",
                GameVisualTourGameplayPrepare(4, "combat"));
        case 17:
            return GameVisualTourPrepareAndCapture("17_stage_08_combat",
                GameVisualTourGameplayPrepare(8, "combat"));
        case 18:
            return GameVisualTourPrepareAndCapture("18_final_boss",
                GameVisualTourGameplayPrepare(STAGE_COUNT, "boss"));
        case 19:
            return GameVisualTourPrepareAndCapture("19_stage_clear",
                GameVisualTourGameplayPrepare(9, "clear"));
        case 20:
            return GameVisualTourPrepareAndCapture("20_ending_story",
                GameVisualTourStoryPrepare(rm_ending));
        case 21:
            return GameVisualTourPrepareAndCapture("21_credits", GameVisualTourCreditsPrepare());
        case 22:
            return GameVisualTourPrepareAndCapture("22_title_practice",
                GameVisualTourTitlePrepare("practice", 5));
        case 23:
            return GameVisualTourPrepareAndCapture("23_pause_main",
                GameVisualTourPausePrepare("main"));
        case 24:
            return GameVisualTourPrepareAndCapture("24_pause_settings",
                GameVisualTourPausePrepare("options"));
        case 25:
            return GameVisualTourPrepareAndCapture("25_pause_practice_tuning",
                GameVisualTourPausePrepare("practice"));
        case 26:
            return GameVisualTourPrepareAndCapture("26_pause_quit_confirm",
                GameVisualTourPausePrepare("quit_confirm"));
    }

    if (_tour.pending_capture_name != "" || _tour.capture_count < _tour.expected_capture_count) {
        if (!_tour.completion_wait_logged) {
            show_debug_message("VISUAL_TOUR_WAITING_FOR_CAPTURES " + string(_tour.capture_count)
                + "/" + string(_tour.expected_capture_count));
            _tour.completion_wait_logged = true;
        }
        return true;
    }

    show_debug_message("VISUAL_TOUR_DONE_SANDBOX " + _tour.output_dir);
    file_delete(GameVisualTourMarkerPathGet());
    game_end();
    return true;
}

// Snapshot menu input and advance the title state machine.
var _input = GameTitleInputSnapshotFromGlobal();
var _result = GameTitleStateStep(title_state, _input);
GameTitleRemapCaptureUpdate(title_state);

// Dispatch any room or application actions requested by the title flow.
switch (_result.action) {
    case "goto_room":
        // Clear any retained practice state before booting the normal story route.
        GameNormalRunRequestConfigure(_result.character_id, _result.character_index);
        room_goto(rm_opening);
        break;

    case "goto_practice":
        // Practice skips story setup and launches the selected stage segment directly.
        GamePracticeRunRequestConfigure(_result.practice_config);
        room_goto(rm_game);
        break;

    case "quit":
        // Allow the title menu to exit the application directly.
        game_end();
        break;
}

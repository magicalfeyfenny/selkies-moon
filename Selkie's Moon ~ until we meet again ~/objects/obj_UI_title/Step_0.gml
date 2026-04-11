// Snapshot menu input and advance the title state machine.
var _input = GameTitleInputSnapshotFromGlobal();
var _result = GameTitleStateStep(title_state, _input);

// Dispatch any room or application actions requested by the title flow.
switch (_result.action) {
    case "goto_room":
        // Persist the selected ship so the opening scene can boot the correct run state.
        global.game_runtime.selected_ship_id = _result.character_id;
        global.game_runtime.selected_ship_index = _result.character_index;
        room_goto(rm_opening);
        break;

    case "quit":
        // Allow the title menu to exit the application directly.
        game_end();
        break;
}

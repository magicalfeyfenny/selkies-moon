var _input = GameTitleInputSnapshotFromGlobal();
var _result = GameTitleStateStep(title_state, _input);

switch (_result.action) {
    case "goto_room":
        global.game_runtime.selected_ship_id = _result.character_id;
        global.game_runtime.selected_ship_index = _result.character_index;
        room_goto(rm_opening);
        break;

    case "quit":
        game_end();
        break;
}

// Advance pause navigation after normal gameplay Steps have read the freeze signal.
GameRuntimeGameplayEnsure();

// Dialogue and Continue already own confirm/cancel, so they cannot open pause.
if (!pause_state.active && (global.game_runtime.signals.dialogue
    || global.game_runtime.signals.continue_request)) {
    exit;
}

var _input = GamePauseInputSnapshotFromGlobal();
var _result = GamePauseStateStep(pause_state, _input, GameRunIsPractice());

switch (_result.action) {
    case "open":
        global.game_runtime.signals.paused = true;
        break;

    case "close":
        // End Step releases the freeze after every gameplay Step has stayed still.
        pause_state.close_requested = true;
        break;

    case "restart_practice":
        global.game_runtime.signals.paused = false;
        pause_state.active = false;
        pause_state.close_requested = false;
        room_restart();
        break;

    case "quit_title":
        GameRunAbortToTitle();
        break;
}

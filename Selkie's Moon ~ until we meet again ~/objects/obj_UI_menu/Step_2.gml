// Defer resume until normal gameplay Steps have observed the paused signal.
if (pause_state.close_requested) {
    pause_state.close_requested = false;
    pause_state.active = false;
    pause_state.page = "main";
    global.game_runtime.signals.paused = false;
}

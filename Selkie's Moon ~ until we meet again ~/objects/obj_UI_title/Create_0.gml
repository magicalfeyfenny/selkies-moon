// Create a fresh title UI state when the room enters the menu flow.
title_state = GameTitleStateCreate();

// Completed or failed practice attempts return directly to their retained setup.
if (GameRunIsPractice()) {
    title_state.phase = "menu";
    title_state.page = "practice";
    title_state.practice_config = GamePracticeConfigNormalize(global.game_runtime.practice_config);

    for (var i = 0; i < array_length(title_state.main_items); i++) {
        if (title_state.main_items[i].id == "practice") {
            title_state.main_index = i;
            break;
        }
    }
}

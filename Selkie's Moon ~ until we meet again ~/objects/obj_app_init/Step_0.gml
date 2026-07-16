// Finish the delayed resize/center sequence after display-mode changes settle.
GameWindowCenterStep();

// Retina/fullscreen transitions may recreate the application surface. Reassert
// the fixed low-resolution pixel grid and nearest-neighbour sampling every step.
GamePixelPresentationApply();

// Keep the run music loop aligned with the current room flow across the persistent bootstrap object.
GameStageMusicSync();

// Allow local visual QA runs to drive and capture representative game states.
if (GameVisualTourStep()) {
    exit;
}

// Skip the auto-quit path during normal IDE runs.
if (!GameShouldQuitAfterTests()) {
    exit;
}

test_quit_frames++;

// Close the runner once GMTL has fully finished when launched by the test harness.
// TODO: so this is mostly just to patch it so i can test it, we want a better way to do this
if (TEST_HARNESS_AUTO_QUIT) {
    if (gmtl_has_finished || test_quit_frames >= test_quit_timeout_frames) { 
        if (test_quit_frames >= test_quit_timeout_frames) {
            show_debug_message("GMTL test run timeout reached; closing runner.");
        }

        game_end();
    }
}

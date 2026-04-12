// Keep the run music loop aligned with the current room flow across the persistent bootstrap object.
GameStageMusicSync();

// Skip the auto-quit path during normal IDE runs.
if (!GameShouldQuitAfterTests()) {
    exit;
}

// Close the runner once GMTL has fully finished when launched by the test harness.
if (gmtl_has_finished) {
    game_end();
}

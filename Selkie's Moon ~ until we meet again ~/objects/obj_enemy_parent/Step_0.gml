// Destroy defeated enemies and award their score before any motion update.
if (hp <= 0) {
    GameEnemyDestroySoundPlay();
    global.game_runtime.score += points;
    instance_destroy();
    exit;
}

// Freeze enemy motion while gameplay is paused.
if (GameGameplayIsFrozen()) {
    exit;
}

if (move_speed != 0) {
    x += lengthdir_x(move_speed, move_direction);
    y += lengthdir_y(move_speed, move_direction);
}

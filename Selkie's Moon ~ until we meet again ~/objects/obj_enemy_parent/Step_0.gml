// Tell overriding child Steps whether inherited combat handling ended this frame.
combat_step_blocked = false;

// Freeze before resolving a pending defeat so the pause frame is atomic.
if (GameGameplayIsFrozen()) {
    combat_step_blocked = true;
    exit;
}

// Destroy defeated enemies and award their score before any motion update.
if (hp <= 0) {
    combat_step_blocked = true;
    GameEnemyDestroySoundPlay();
    global.game_runtime.score += points;
    GameRankDefeatRewardApply();
    GameEnemyPowerupDropTry(x, y, points);
    instance_destroy();
    exit;
}

if (move_speed != 0) {
    x += lengthdir_x(move_speed, move_direction);
    y += lengthdir_y(move_speed, move_direction);
}

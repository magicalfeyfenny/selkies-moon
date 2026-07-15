// Freeze medal movement while gameplay is paused by dialogue or continue prompts.
if (GameGameplayIsFrozen()) {
    exit;
}

var _player = instance_find(obj_player, 0);
if (_player == noone || _player.player_state.hit) {
    exit;
}

// Defeat drops fan out briefly so five-to-ten-medal rewards read as a shower,
// not one visually indistinguishable stack.
if (launch_timer > 0) {
    x += lengthdir_x(launch_speed, launch_direction);
    y += lengthdir_y(launch_speed, launch_direction);
    launch_speed = max(0, launch_speed - 0.12);
    launch_timer -= 1;
    exit;
}

// Pull the medal directly toward the player until it is collected.
var _direction = point_direction(x, y, _player.x, _player.y);
x += lengthdir_x(homing_speed, _direction);
y += lengthdir_y(homing_speed, _direction);

if (point_distance(x, y, _player.x, _player.y) <= 12) {
    global.game_runtime.score += score_value;

    GamePlayerMeterRewardApply(meter_value);

    instance_destroy();
}

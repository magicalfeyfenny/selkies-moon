// Freeze medal movement while gameplay is paused by dialogue or continue prompts.
if (GameGameplayIsFrozen()) {
    exit;
}

var _player = instance_find(obj_player, 0);
if (_player == noone || _player.player_state.hit) {
    exit;
}

// Pull the medal directly toward the player until it is collected.
var _direction = point_direction(x, y, _player.x, _player.y);
x += lengthdir_x(7, _direction);
y += lengthdir_y(7, _direction);

if (point_distance(x, y, _player.x, _player.y) <= 12) {
    global.game_runtime.score += score_value;

    if (GamePlayerMeterRewardApply(meter_value)) {
        GameBulletsCancelAll(true);
    }

    instance_destroy();
}

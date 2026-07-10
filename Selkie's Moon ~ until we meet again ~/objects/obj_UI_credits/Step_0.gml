credits_timer += 1;
credits_scroll_y -= 0.42;

var _skip = GameInputVerbPressed("fire") || GameInputVerbPressed("autofire") || GameInputVerbPressed("bomb");
var _finished = credits_scroll_y + (array_length(credits_lines) * credits_line_height) < -24;
var _timeout = credits_timer > (60 * 55);

if (_skip || _finished || _timeout) {
    GameRuntimeReset();
    room_goto(rm_title);
}

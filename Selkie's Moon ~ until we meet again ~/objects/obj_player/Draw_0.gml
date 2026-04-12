// Draw the current sword sweep ahead of the player ship when active.
if (player_state.sword_pose != undefined && (global.game_runtime.is_berserk || player_state.fire_hold_frames > FIRE_HOLD_FRAMES)) {
    var _sword_angle = player_state.sword_pose.angle mod 360;
    var _sword_length = player_state.sword_pose.length;

    draw_set_alpha(0.75);
    draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
    draw_line_width(x, y, x + lengthdir_x(_sword_length, _sword_angle), y + lengthdir_y(_sword_length, _sword_angle), 3);
}

// Draw either the death burst or the live player ship body.
if (player_state.hit) {
    draw_set_alpha(0.9);
    draw_set_color(c_red);
    draw_circle(x, y, 18, false);
    draw_circle(x, y, 8, false);
    draw_set_alpha(1);
    exit;
}

var _blink_alpha = 1;
if (player_state.invuln_timer > 0 && ((player_state.invuln_timer div 6) mod 2) == 0) {
    _blink_alpha = 0.35;
}

draw_set_alpha(_blink_alpha);
draw_set_color(c_white);
draw_triangle(x, y - 18, x - 12, y + 14, x + 12, y + 14, false);
draw_set_color(c_aqua);
draw_rectangle(x - 10, y - 8, x + 10, y + 12, false);
draw_set_color(c_red);
draw_rectangle(x - 1, y - 1, x + 1, y + 1, false);
draw_set_alpha(1);

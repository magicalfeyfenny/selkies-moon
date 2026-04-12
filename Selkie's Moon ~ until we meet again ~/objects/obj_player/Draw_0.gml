// Draw the current sword sweep ahead of the player ship when active.
if (player_state.sword_pose != undefined && (global.game_runtime.is_berserk || player_state.fire_hold_frames > FIRE_HOLD_FRAMES)) {
    var _sword_angle = player_state.sword_pose.angle mod 360;
    var _sword_length = player_state.sword_pose.length;

    draw_set_alpha(0.75);
    draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
    draw_line_width(x, y, x + lengthdir_x(_sword_length, _sword_angle), y + lengthdir_y(_sword_length, _sword_angle), 3);
}

// Draw a simple expanding bomb ring while the bomb animation is active.
if (GamePlayerBombIsActive(player_state)) {
    var _bomb_visual = GamePlayerBombVisualCreate(player_state.bomb_timer);

    draw_set_alpha(_bomb_visual.fill_alpha);
    draw_set_color(make_color_rgb(116, 48, 170));
    draw_circle(x, y, _bomb_visual.outer_radius, false);

    draw_set_alpha(_bomb_visual.ring_alpha);
    draw_set_color(make_color_rgb(160, 244, 255));
    draw_circle(x, y, _bomb_visual.outer_radius, true);
    draw_set_color(make_color_rgb(255, 202, 246));
    draw_circle(x, y, _bomb_visual.inner_radius, true);
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
if (player_state.invuln_timer > 0 && !GamePlayerBombIsActive(player_state) && ((player_state.invuln_timer div 6) mod 2) == 0) {
    _blink_alpha = 0.35;
}

if (sprite_index != -1 && sprite_exists(sprite_index)) {
    draw_sprite_ext(sprite_index, 0, x, y, 1, 1, 0, c_white, _blink_alpha);
} else {
    draw_set_alpha(_blink_alpha);
    draw_set_color(c_white);
    draw_triangle(x, y - 18, x - 12, y + 14, x + 12, y + 14, false);
    draw_set_color(c_aqua);
    draw_rectangle(x - 10, y - 8, x + 10, y + 12, false);
}

draw_set_alpha(1);
draw_set_color(c_red);
draw_rectangle(x - 1, y - 1, x + 1, y + 1, false);

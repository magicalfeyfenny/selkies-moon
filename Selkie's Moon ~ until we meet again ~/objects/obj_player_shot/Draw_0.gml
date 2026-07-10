// Render the configured bullet sprite rotated along its travel direction.
var _power = clamp(shot_power, 0, PLAYER_POWER_MAX);
var _trail_length = 7 + (_power * 2) + (shot_focused ? 4 : 0);
var _glow_radius = 3 + (_power * 1.6);
var _trail_x = x - lengthdir_x(_trail_length, move_direction);
var _trail_y = y - lengthdir_y(_trail_length, move_direction);

draw_set_alpha(0.18 + (_power * 0.035));
draw_set_color(shot_accent_color);
draw_line_width(x, y, _trail_x, _trail_y, max(1, 1 + (_power div 2)));

if (_power >= 2) {
    draw_set_alpha(0.16 + (_power * 0.03));
    draw_circle(x, y, _glow_radius, false);
}

if (_power >= 4) {
    draw_set_alpha(0.65);
    draw_circle(x, y, _glow_radius + 2 + (shot_focused ? 2 : 0), true);
}

draw_set_alpha(1);

if (shot_sprite != -1) {
    draw_sprite_ext(shot_sprite, 0, x, y, shot_scale, shot_scale, move_direction, shot_color, 1);
    exit;
}

// Fall back to a simple luminous bolt if the sprite resource is unavailable.
draw_set_color(c_aqua);
draw_line_width(x, y, x - lengthdir_x(10, move_direction), y - lengthdir_y(10, move_direction), 2);

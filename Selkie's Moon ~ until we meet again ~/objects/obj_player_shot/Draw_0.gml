// Render the configured bullet sprite rotated along its travel direction.
if (shot_sprite != -1) {
    draw_sprite_ext(shot_sprite, 0, x, y, 1, 1, move_direction, c_white, 1);
    exit;
}

// Fall back to a simple luminous bolt if the sprite resource is unavailable.
draw_set_color(c_aqua);
draw_line_width(x, y, x - lengthdir_x(10, move_direction), y - lengthdir_y(10, move_direction), 2);

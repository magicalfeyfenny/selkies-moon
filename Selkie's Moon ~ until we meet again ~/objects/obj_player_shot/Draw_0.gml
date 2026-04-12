// Render a simple luminous bolt for the current player shot.
draw_set_color(c_aqua);
draw_line_width(x, y, x - lengthdir_x(10, move_direction), y - lengthdir_y(10, move_direction), 2);

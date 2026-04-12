// Draw the assigned sprite when present, otherwise fall back to a simple placeholder circle.
if (sprite_index != -1 && sprite_exists(sprite_index)) {
    draw_self();
    exit;
}

draw_set_color(c_fuchsia);
draw_circle(x, y, draw_radius, false);

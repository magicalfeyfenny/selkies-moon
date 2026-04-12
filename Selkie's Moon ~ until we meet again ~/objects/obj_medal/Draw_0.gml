// Draw the medal sprite when present, otherwise fall back to the placeholder marker.
if (sprite_index != -1 && sprite_exists(sprite_index)) {
    draw_self();
    exit;
}

draw_set_color(c_yellow);
draw_triangle(x, y - 6, x - 6, y + 6, x + 6, y + 6, false);
draw_rectangle(x - 2, y - 8, x + 2, y - 2, false);

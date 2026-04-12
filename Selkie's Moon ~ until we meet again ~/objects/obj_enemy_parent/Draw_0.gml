// Draw the assigned enemy sprite when one exists, otherwise fall back to the placeholder hitbox box.
if (sprite_index != -1 && sprite_exists(sprite_index)) {
    draw_self();
    exit;
}

draw_set_color(c_orange);
draw_rectangle(x - hit_radius, y - hit_radius, x + hit_radius, y + hit_radius, false);

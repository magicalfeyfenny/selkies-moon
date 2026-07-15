// Draw End guarantees the collision core remains visible above enemy bullets
// even though the ship silhouette itself deliberately sits beneath them.
if (!player_state.hit) {
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(10, 6, 22));
    draw_circle(x, y, 3, false);
    draw_set_color(make_color_rgb(255, 248, 226));
    draw_rectangle(x - 1, y - 1, x + 1, y + 1, false);
    draw_set_color(c_white);
}

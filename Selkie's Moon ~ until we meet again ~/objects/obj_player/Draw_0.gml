// The ship stays in normal Draw at depth -100, so depth -200 enemy bullets
// cross over it. The hitbox is emitted later from Draw End.
if (!player_state.hit) {
    var _blink_alpha = 1;
    if (player_state.invuln_timer > 0 && !GamePlayerBombIsActive(player_state)
        && ((player_state.invuln_timer div 6) mod 2) == 0) {
        _blink_alpha = 0.35;
    }

    if (sprite_index != -1 && sprite_exists(sprite_index)) {
        var _ship_y_scale = GamePlayerShipDrawScaleYGet(GameRunShipIdGet());
        draw_sprite_ext(sprite_index, 0, x, y, 1, _ship_y_scale, 0, c_white, _blink_alpha);
    } else {
        draw_set_alpha(_blink_alpha);
        draw_set_color(c_white);
        draw_triangle(x, y - 18, x - 12, y + 14, x + 12, y + 14, false);
        draw_set_color(c_aqua);
        draw_rectangle(x - 10, y - 8, x + 10, y + 12, false);
    }
}

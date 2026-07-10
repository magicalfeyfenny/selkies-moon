// Draw compact neon silhouettes that sit beside the existing insect/flower enemies.
var _accent = make_color_rgb(255, 180, 228);
var _core = make_color_rgb(96, 228, 255);

switch (variant_kind) {
    case ENEMY_VARIANT_KELP:
        _accent = make_color_rgb(118, 255, 184);
        _core = make_color_rgb(38, 118, 92);
        break;

    case ENEMY_VARIANT_WISP:
        _accent = make_color_rgb(196, 166, 255);
        _core = make_color_rgb(116, 232, 255);
        break;

    case ENEMY_VARIANT_NEEDLE:
        _accent = make_color_rgb(255, 122, 118);
        _core = make_color_rgb(255, 236, 138);
        break;

    case ENEMY_VARIANT_MIRROR:
        _accent = make_color_rgb(255, 236, 138);
        _core = make_color_rgb(255, 146, 212);
        break;
}

draw_set_alpha(0.9);
draw_set_color(_accent);

if (variant_kind == ENEMY_VARIANT_NEEDLE) {
    draw_triangle(x, y - 20, x - 10, y + 14, x + 10, y + 14, false);
    draw_set_color(_core);
    draw_line_width(x, y - 16, x, y + 12, 3);
} else if (variant_kind == ENEMY_VARIANT_KELP) {
    draw_circle(x, y, 16, false);
    draw_set_color(_core);
    draw_line_width(x - 12, y + 10, x - 4, y - 14, 3);
    draw_line_width(x, y + 12, x + 4, y - 16, 3);
    draw_line_width(x + 12, y + 10, x + 4, y - 14, 3);
} else if (variant_kind == ENEMY_VARIANT_MIRROR) {
    draw_circle(x, y, 18, true);
    draw_line_width(x - 16, y, x + 16, y, 2);
    draw_line_width(x, y - 16, x, y + 16, 2);
    draw_set_color(_core);
    draw_circle(x, y, 8, false);
} else {
    draw_circle(x, y, 14, false);
    draw_set_color(_core);
    draw_circle(x, y, 7, false);
    draw_line_width(x - 18, y, x - 6, y, 2);
    draw_line_width(x + 6, y, x + 18, y, 2);
}

draw_set_alpha(1);

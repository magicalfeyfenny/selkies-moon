// Every stage familiar now has layered, ship-quality neo-Gothic artwork.
if (variant_sprite != -1 && sprite_exists(variant_sprite)) {
    draw_sprite_ext(variant_sprite, 0, x, y, 1, 1, image_angle - 270, c_white, 1);
    exit;
}

var _pulse = 0.82 + (dsin(age * 6 + wave_phase) * 0.1);
draw_set_alpha(0.24);
draw_set_color(accent_color);
draw_circle(x, y, 23 + (_pulse * 2), false);
draw_set_alpha(0.94);
draw_set_color(accent_color);

switch (draw_shape) {
    case "spark":
        for (var _spark = 0; _spark < 8; _spark++) {
            draw_line_width(x + lengthdir_x(7, _spark * 45), y + lengthdir_y(7, _spark * 45),
                x + lengthdir_x(21, _spark * 45), y + lengthdir_y(21, _spark * 45), 3);
        }
        break;

    case "anvil":
        draw_triangle(x - 19, y - 11, x + 19, y - 11, x + 9, y + 1, false);
        draw_rectangle(x - 9, y - 1, x + 9, y + 12, false);
        draw_rectangle(x - 15, y + 12, x + 15, y + 17, false);
        break;

    case "bellows":
        draw_triangle(x - 18, y - 12, x + 8, y - 17, x + 8, y + 17, false);
        draw_triangle(x - 18, y + 12, x + 8, y - 17, x + 8, y + 17, false);
        draw_line_width(x + 8, y, x + 21, y, 5);
        break;

    case "hammer":
        draw_rectangle(x - 18, y - 17, x + 12, y - 6, false);
        draw_triangle(x + 12, y - 17, x + 21, y - 11, x + 12, y - 6, false);
        draw_line_width(x - 2, y - 6, x + 6, y + 20, 5);
        break;

    case "hare":
        draw_ellipse(x - 13, y - 9, x + 13, y + 17, false);
        draw_ellipse(x - 12, y - 23, x - 2, y - 4, false);
        draw_ellipse(x + 2, y - 23, x + 12, y - 4, false);
        break;

    case "staff":
        draw_line_width(x, y - 20, x, y + 20, 5);
        draw_circle(x, y - 13, 7, true);
        draw_triangle(x - 2, y - 4, x - 21, y - 15, x - 14, y + 3, false);
        draw_triangle(x + 2, y - 4, x + 21, y - 15, x + 14, y + 3, false);
        break;

    case "knot":
        draw_ellipse(x - 20, y - 10, x + 2, y + 10, true);
        draw_ellipse(x - 2, y - 10, x + 20, y + 10, true);
        draw_circle(x, y, 5, false);
        break;

    case "pinwheel":
        for (var _pin = 0; _pin < 4; _pin++) {
            var _pin_angle = (_pin * 90) + image_angle;
            draw_triangle(x, y,
                x + lengthdir_x(20, _pin_angle), y + lengthdir_y(20, _pin_angle),
                x + lengthdir_x(10, _pin_angle + 50), y + lengthdir_y(10, _pin_angle + 50), false);
        }
        break;

    case "spade":
        draw_circle(x - 8, y - 4, 10, false);
        draw_circle(x + 8, y - 4, 10, false);
        draw_triangle(x, y - 21, x - 16, y + 1, x + 16, y + 1, false);
        draw_triangle(x, y + 1, x - 9, y + 20, x + 9, y + 20, false);
        break;

    case "mask":
        draw_ellipse(x - 19, y - 16, x + 19, y + 17, true);
        draw_set_color(core_color);
        draw_ellipse(x - 13, y - 7, x - 3, y + 1, false);
        draw_ellipse(x + 3, y - 7, x + 13, y + 1, false);
        draw_line_width(x - 8, y + 9, x + 8, y + 9, 2);
        break;

    case "talisman":
        draw_rectangle(x - 13, y - 20, x + 13, y + 20, false);
        draw_set_color(core_color);
        draw_line_width(x, y - 15, x, y + 14, 2);
        draw_line_width(x - 8, y - 7, x + 8, y - 7, 2);
        draw_circle(x, y + 5, 6, true);
        break;

    case "shard":
        draw_triangle(x, y - 22, x - 17, y + 13, x + 5, y + 6, false);
        draw_triangle(x + 5, y + 6, x + 17, y - 4, x + 11, y + 20, false);
        break;

    case "planet":
        draw_circle(x, y, 13, false);
        draw_ellipse(x - 23, y - 7, x + 23, y + 7, true);
        draw_set_color(core_color);
        draw_circle(x + 8, y - 6, 3, false);
        break;

    case "astrolabe":
        draw_circle(x, y, 19, true);
        draw_ellipse(x - 8, y - 21, x + 8, y + 21, true);
        draw_ellipse(x - 21, y - 8, x + 21, y + 8, true);
        break;

    case "constellation":
        var _last_star_x = x;
        var _last_star_y = y;
        for (var _star = 0; _star < 5; _star++) {
            var _star_x = x + lengthdir_x(8 + ((_star mod 2) * 10), (_star * 73) + 18);
            var _star_y = y + lengthdir_y(8 + ((_star mod 2) * 10), (_star * 73) + 18);
            draw_circle(_star_x, _star_y, 3, false);
            if (_star > 0) {
                draw_line_width(_last_star_x, _last_star_y, _star_x, _star_y, 2);
            }
            _last_star_x = _star_x;
            _last_star_y = _star_y;
        }
        break;

    case "heart":
        draw_circle(x - 8, y - 8, 10, false);
        draw_circle(x + 8, y - 8, 10, false);
        draw_triangle(x - 17, y - 5, x + 17, y - 5, x, y + 21, false);
        break;

    case "reliquary":
        draw_ellipse(x - 16, y - 19, x + 16, y + 19, true);
        draw_set_color(core_color);
        draw_circle(x, y, 8, false);
        for (var _thorn = 0; _thorn < 6; _thorn++) {
            draw_line_width(x + lengthdir_x(13, _thorn * 60), y + lengthdir_y(13, _thorn * 60),
                x + lengthdir_x(22, _thorn * 60), y + lengthdir_y(22, _thorn * 60), 2);
        }
        break;

    case "chakram":
        draw_circle(x, y, 20, true);
        draw_circle(x, y, 12, true);
        for (var _blade = 0; _blade < 4; _blade++) {
            draw_triangle(
                x + lengthdir_x(16, (_blade * 90) - 12), y + lengthdir_y(16, (_blade * 90) - 12),
                x + lengthdir_x(25, _blade * 90), y + lengthdir_y(25, _blade * 90),
                x + lengthdir_x(16, (_blade * 90) + 12), y + lengthdir_y(16, (_blade * 90) + 12), false);
        }
        break;
}

draw_set_color(core_color);
draw_circle(x, y, 5 + (_pulse * 2), false);
draw_set_alpha(1);
draw_set_color(c_white);

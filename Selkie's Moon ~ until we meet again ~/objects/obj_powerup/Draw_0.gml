// Distinguish guaranteed score drops from earned resource drops by silhouette.
var _color = GamePowerupColorGet(powerup_type);
var _radius = 9 + (dsin(pulse) * 1.5);
var _is_resource = pickup_class == "resource";

draw_set_alpha(_is_resource ? 0.38 : 0.24);
draw_set_color(_color);

if (_is_resource) {
    draw_circle(x, y, _radius + 7, false);
    draw_set_alpha(0.82);
    draw_circle(x, y, _radius + 4, true);
    draw_line(x - _radius - 7, y, x - _radius - 3, y);
    draw_line(x + _radius + 3, y, x + _radius + 7, y);
} else {
    draw_triangle(x, y - _radius - 5, x - _radius - 5, y, x, y + _radius + 5, false);
    draw_triangle(x, y - _radius - 5, x + _radius + 5, y, x, y + _radius + 5, false);
}

draw_set_alpha(_is_resource ? 0.92 : 0.78);
draw_circle(x, y, _radius, false);

draw_set_alpha(1);
draw_set_color(c_white);
draw_circle(x, y, _radius, true);

draw_set_font(fn_menu);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
GameUiDrawOutlinedText(GamePowerupLabelGet(powerup_type), x, y, c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

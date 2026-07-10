var _color = GamePowerupColorGet(powerup_type);
var _radius = 9 + (dsin(pulse) * 1.5);

draw_set_alpha(0.32);
draw_set_color(_color);
draw_circle(x, y, _radius + 6, false);

draw_set_alpha(0.92);
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

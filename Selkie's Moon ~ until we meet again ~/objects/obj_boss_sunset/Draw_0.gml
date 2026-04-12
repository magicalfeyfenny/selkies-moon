// Draw the Sunset boss normally until it enters its destruction pulse.
if (!destruction_active) {
    draw_self();
    exit;
}

var _pulse = 1 + (0.14 * dsin(destruction_timer * 24));
var _alpha = 0.35 + (0.65 * abs(dsin(destruction_timer * 32)));

draw_set_alpha(_alpha);
draw_set_color(c_white);
draw_sprite_ext(sprite_index, 0, x, y, _pulse, _pulse, 0, c_white, _alpha);

draw_set_alpha(0.45);
draw_set_color(make_color_rgb(255, 164, 112));
draw_circle(x, y, 24 + ((BOSS_DESTRUCTION_FRAMES - destruction_timer) * 0.45), false);
draw_set_alpha(1.0);

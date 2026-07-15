// Draw the assigned sprite when present, otherwise fall back to a simple placeholder circle.
// A tiny additive breathing glint keeps bullets legible through elaborate effects
// without turning the playfield into a strobe.
var _flash_alpha = GameEnemyBulletFlashAlphaGet(bullet_age, bullet_flash_phase);
if (sprite_index != -1 && sprite_exists(sprite_index)) {
    draw_self();
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(sprite_index, image_index, x, y,
        image_xscale * 1.04, image_yscale * 1.04,
        image_angle, c_white, _flash_alpha);
    gpu_set_blendmode(bm_normal);
    exit;
}

draw_set_color(c_fuchsia);
draw_circle(x, y, draw_radius, false);
gpu_set_blendmode(bm_add);
draw_set_alpha(_flash_alpha);
draw_set_color(c_white);
draw_circle(x, y, max(1, draw_radius * 0.48), false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);

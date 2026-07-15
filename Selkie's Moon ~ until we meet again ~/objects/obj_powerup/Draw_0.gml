// Route-neutral PC-98-style icons distinguish every reward without relying on
// tiny text. They remain at 1:1 scale on the fixed 640x360 pixel grid.
var _color = GamePowerupColorGet(powerup_type);
var _sprite = GamePowerupSpriteGet(powerup_type);
var _draw_x = round(x);
var _draw_y = round(y);
draw_sprite(_sprite, 0, _draw_x, _draw_y);

// One restrained palette flash keeps pickups visible without changing their
// silhouette or producing a smooth scale pulse.
var _flash_alpha = 0.04 + (0.05 * (0.5 + 0.5 * dsin(pulse)));
gpu_set_blendmode(bm_add);
draw_sprite_ext(_sprite, 0, _draw_x, _draw_y, 1, 1, 0, _color, _flash_alpha);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);

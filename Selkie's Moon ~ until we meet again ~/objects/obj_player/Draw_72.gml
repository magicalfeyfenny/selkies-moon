// Draw Begin owns every broad special effect. Normal Draw then places enemy
// bullets and the player hitbox over these flourishes, preserving readability.
var _ship_id = GameRunShipIdGet();
var _pearl = make_color_rgb(255, 244, 220);
var _cyan = make_color_rgb(118, 236, 255);
var _rose = make_color_rgb(255, 118, 204);
var _violet = make_color_rgb(134, 84, 212);
var _gold = make_color_rgb(255, 214, 112);

// A neo-Victorian clockwork halo makes the hold-to-sword transition explicit.
if (!global.game_runtime.is_berserk && !player_state.hit
    && player_state.fire_hold_frames > 0 && player_state.fire_hold_frames < FIRE_HOLD_FRAMES) {
    var _charge = clamp(player_state.fire_hold_frames / FIRE_HOLD_FRAMES, 0, 1);
    var _charge_radius = lerp(20, 34, _charge);
    var _charge_color = merge_color(_cyan, _gold, _charge);

    draw_sprite_ext(spr_attack_charge_dial, 0, round(x), round(y), 1, 1,
        round((_charge * 12)) * 30, _charge_color, 0.26 + (_charge * 0.34));

    draw_set_alpha(0.18 + (_charge * 0.34));
    draw_set_color(_violet);
    draw_circle(x, y, _charge_radius + 7, false);
    draw_set_alpha(0.55 + (_charge * 0.35));
    draw_set_color(_charge_color);
    draw_circle(x, y, _charge_radius, true);

    for (var cog = 0; cog < 12; cog++) {
        var _cog_angle = (cog * 30) - 90;
        var _lit = (cog / 12) <= _charge;
        draw_set_alpha(_lit ? 0.95 : 0.22);
        draw_set_color(_lit ? _gold : _cyan);
        draw_line_width(
            x + lengthdir_x(_charge_radius - 4, _cog_angle),
            y + lengthdir_y(_charge_radius - 4, _cog_angle),
            x + lengthdir_x(_charge_radius + 4, _cog_angle),
            y + lengthdir_y(_charge_radius + 4, _cog_angle), 2);
    }

    draw_set_alpha(0.72);
    draw_set_color(_pearl);
    draw_triangle(x, y - 10 - (_charge * 5), x - 4, y - 4, x + 4, y - 4, true);
}

// Render the route-specific sweep as an ornate rose-vine or clockwork chakram.
if (player_state.sword_pose != undefined
    && (global.game_runtime.is_berserk || player_state.fire_hold_frames >= FIRE_HOLD_FRAMES)) {
    var _sword_angle = player_state.sword_pose.angle mod 360;
    var _sword_length = player_state.sword_pose.length;
    var _sword_alpha = player_state.sword_pose.moving ? 0.82 : 0.46;

    if (_ship_id == SHIP_SELKIE) {
        var _disc_x = x + lengthdir_x(_sword_length, _sword_angle);
        var _disc_y = y + lengthdir_y(_sword_length, _sword_angle);
        var _spin = player_state.sweep_frame * 18;
        var _disc_radius = 16 + (global.game_runtime.is_berserk ? 7 : 0);

        draw_set_alpha(_sword_alpha * 0.34);
        draw_set_color(_cyan);
        draw_line_width(x, y, _disc_x, _disc_y, 2);
        draw_set_alpha(1);
        draw_sprite_ext(spr_attack_selkie_chakram, 0, round(_disc_x), round(_disc_y),
            1, 1, round(_spin / 15) * 15,
            global.game_runtime.is_berserk ? _gold : c_white, _sword_alpha);
    } else {
        var _prev_x = x;
        var _prev_y = y;
        var _vine_color = global.game_runtime.is_berserk ? _gold : make_color_rgb(88, 210, 150);

        draw_set_alpha(_sword_alpha);
        for (var seg = 1; seg <= 14; seg++) {
            var _t = seg / 14;
            var _wave = dsin((_t * 720) + (player_state.sweep_frame * 11)) * 7 * (1 - (_t * 0.25));
            var _seg_x = x + lengthdir_x(_sword_length * _t, _sword_angle)
                + lengthdir_x(_wave, _sword_angle + 90);
            var _seg_y = y + lengthdir_y(_sword_length * _t, _sword_angle)
                + lengthdir_y(_wave, _sword_angle + 90);
            draw_set_color(_vine_color);
            draw_sprite_ext(spr_attack_moon_thorn, 0, round(_seg_x), round(_seg_y),
                1, 1, round(_sword_angle / 15) * 15, _vine_color, _sword_alpha);

            if ((seg mod 3) == 0) {
                draw_set_color(make_color_rgb(255, 174, 234));
                draw_triangle(_seg_x, _seg_y,
                    _seg_x + lengthdir_x(7, _sword_angle + 126),
                    _seg_y + lengthdir_y(7, _sword_angle + 126),
                    _seg_x + lengthdir_x(7, _sword_angle - 126),
                    _seg_y + lengthdir_y(7, _sword_angle - 126), false);
            }
            _prev_x = _seg_x;
            _prev_y = _seg_y;
        }

        draw_sprite_ext(spr_attack_moon_rose, 0, round(_prev_x), round(_prev_y),
            1, 1, round((player_state.sweep_frame * 5) / 15) * 15,
            global.game_runtime.is_berserk ? _gold : c_white, _sword_alpha);
    }
}

// Bombs expand as layered stained-glass rosettes instead of opaque discs.
if (GamePlayerBombIsActive(player_state)) {
    var _bomb_visual = GamePlayerBombVisualCreate(player_state.bomb_timer);
    var _bomb_spin = (BOMB_DURATION_FRAMES - player_state.bomb_timer) * 5;

    draw_set_alpha(_bomb_visual.fill_alpha * 0.55);
    draw_set_color(_violet);
    draw_circle(x, y, _bomb_visual.outer_radius, false);
    draw_set_alpha(_bomb_visual.ring_alpha);
    draw_set_color(_cyan);
    draw_circle(x, y, _bomb_visual.outer_radius, true);
    draw_set_color(_rose);
    draw_circle(x, y, _bomb_visual.inner_radius, true);

    for (var ray = 0; ray < 16; ray++) {
        var _ray_angle = _bomb_spin + (ray * 22.5);
        var _ray_inner = _bomb_visual.inner_radius + 3;
        var _ray_outer = _bomb_visual.outer_radius - 5;
        draw_set_color((ray mod 2) == 0 ? _gold : _cyan);
        draw_set_alpha(_bomb_visual.ring_alpha * 0.65);
        draw_line_width(x + lengthdir_x(_ray_inner, _ray_angle),
            y + lengthdir_y(_ray_inner, _ray_angle),
            x + lengthdir_x(_ray_outer, _ray_angle),
            y + lengthdir_y(_ray_outer, _ray_angle), 1);
    }
}

// Death is a radial firework of pearls, petals, and sparks—never a large red
// collision-like circle. It remains behind live bullets during the animation.
if (player_state.hit) {
    var _death_progress = 1 - (max(0, player_state.death_timer) / PLAYER_DEATH_ANIMATION_FRAMES);
    var _death_fade = 1 - _death_progress;
    var _burst_radius = lerp(8, 76, _death_progress);

    for (var spark = 0; spark < 28; spark++) {
        var _spark_angle = (spark * 137.507) + (spark mod 3) * 11;
        var _spark_ratio = 0.45 + (((spark * 37) mod 55) / 100);
        var _spark_dist = _burst_radius * _spark_ratio;
        var _spark_x = x + lengthdir_x(_spark_dist, _spark_angle);
        var _spark_y = y + lengthdir_y(_spark_dist, _spark_angle) + (18 * _death_progress * _death_progress);
        var _tail_x = x + lengthdir_x(max(0, _spark_dist - 10), _spark_angle);
        var _tail_y = y + lengthdir_y(max(0, _spark_dist - 10), _spark_angle) + (18 * _death_progress * _death_progress);
        var _spark_color = (spark mod 4 == 0) ? _gold
            : ((spark mod 4 == 1) ? _rose : ((spark mod 4 == 2) ? _cyan : _pearl));

        draw_set_alpha(0.75 * _death_fade);
        draw_set_color(_spark_color);
        draw_line_width(_tail_x, _tail_y, _spark_x, _spark_y, (spark mod 3 == 0) ? 2 : 1);
        draw_circle(_spark_x, _spark_y, (spark mod 5 == 0) ? 3 : 2, false);
    }

    draw_set_alpha(0.65 * _death_fade);
    draw_set_color(_violet);
    draw_circle(x, y, lerp(10, 42, _death_progress), true);
    draw_set_color(_gold);
    for (var point = 0; point < 8; point++) {
        var _point_angle = 22.5 + (point * 45);
        draw_line_width(x + lengthdir_x(6, _point_angle), y + lengthdir_y(6, _point_angle),
            x + lengthdir_x(18 + (_death_progress * 20), _point_angle),
            y + lengthdir_y(18 + (_death_progress * 20), _point_angle), 2);
    }
}

draw_set_alpha(1);
draw_set_color(c_white);

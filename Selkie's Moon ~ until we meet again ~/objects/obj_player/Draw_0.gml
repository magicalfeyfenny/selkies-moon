// Draw the current sword sweep ahead of the player ship when active.
if (player_state.sword_pose != undefined && (global.game_runtime.is_berserk || player_state.fire_hold_frames > FIRE_HOLD_FRAMES)) {
    var _ship_id = GameRunShipIdGet();
    var _sword_angle = player_state.sword_pose.angle mod 360;
    var _sword_length = player_state.sword_pose.length;
    var _sword_alpha = player_state.sword_pose.moving ? 0.82 : 0.46;

    if (_ship_id == SHIP_SELKIE) {
        var _disc_x = x + lengthdir_x(_sword_length, _sword_angle);
        var _disc_y = y + lengthdir_y(_sword_length, _sword_angle);
        var _spin = player_state.sweep_frame * 18;
        var _disc_radius = 16 + (global.game_runtime.is_berserk ? 7 : 0);

        draw_set_alpha(_sword_alpha * 0.45);
        draw_set_color(make_color_rgb(255, 174, 234));
        draw_line_width(x, y, _disc_x, _disc_y, 2);

        draw_set_alpha(_sword_alpha * 0.34);
        draw_set_color(make_color_rgb(184, 244, 255));
        draw_circle(_disc_x, _disc_y, _disc_radius + 8, true);

        draw_set_alpha(_sword_alpha);
        draw_set_color(global.game_runtime.is_berserk ? c_yellow : make_color_rgb(255, 174, 234));
        draw_circle(_disc_x, _disc_y, _disc_radius, true);
        draw_circle(_disc_x, _disc_y, max(5, _disc_radius - 7), true);

        for (var i = 0; i < 6; i++) {
            var _blade_angle = _spin + (i * 60);
            draw_line_width(
                _disc_x + lengthdir_x(5, _blade_angle),
                _disc_y + lengthdir_y(5, _blade_angle),
                _disc_x + lengthdir_x(_disc_radius + 6, _blade_angle + 16),
                _disc_y + lengthdir_y(_disc_radius + 6, _blade_angle + 16),
                2
            );
        }
    } else {
        var _prev_x = x;
        var _prev_y = y;
        var _vine_color = global.game_runtime.is_berserk ? c_yellow : make_color_rgb(88, 210, 150);
        var _rose_color = global.game_runtime.is_berserk ? make_color_rgb(255, 244, 112) : make_color_rgb(255, 96, 196);

        draw_set_alpha(_sword_alpha);

        for (var i = 1; i <= 14; i++) {
            var _t = i / 14;
            var _wave = dsin((_t * 720) + (player_state.sweep_frame * 11)) * 7 * (1 - (_t * 0.25));
            var _seg_x = x + lengthdir_x(_sword_length * _t, _sword_angle) + lengthdir_x(_wave, _sword_angle + 90);
            var _seg_y = y + lengthdir_y(_sword_length * _t, _sword_angle) + lengthdir_y(_wave, _sword_angle + 90);

            draw_set_color(_vine_color);
            draw_line_width(_prev_x, _prev_y, _seg_x, _seg_y, 3);

            if ((i mod 3) == 0) {
                draw_set_color(make_color_rgb(255, 174, 234));
                draw_triangle(
                    _seg_x,
                    _seg_y,
                    _seg_x + lengthdir_x(7, _sword_angle + 126),
                    _seg_y + lengthdir_y(7, _sword_angle + 126),
                    _seg_x + lengthdir_x(7, _sword_angle - 126),
                    _seg_y + lengthdir_y(7, _sword_angle - 126),
                    false
                );
            }

            _prev_x = _seg_x;
            _prev_y = _seg_y;
        }

        draw_set_color(_rose_color);
        for (var p = 0; p < 6; p++) {
            var _petal_angle = (p * 60) + (player_state.sweep_frame * 5);
            draw_circle(_prev_x + lengthdir_x(5, _petal_angle), _prev_y + lengthdir_y(5, _petal_angle), 5, false);
        }

        draw_set_color(make_color_rgb(255, 240, 248));
        draw_circle(_prev_x, _prev_y, 4, false);
    }

    draw_set_alpha(1);
}

// Draw a simple expanding bomb ring while the bomb animation is active.
if (GamePlayerBombIsActive(player_state)) {
    var _bomb_visual = GamePlayerBombVisualCreate(player_state.bomb_timer);

    draw_set_alpha(_bomb_visual.fill_alpha);
    draw_set_color(make_color_rgb(116, 48, 170));
    draw_circle(x, y, _bomb_visual.outer_radius, false);

    draw_set_alpha(_bomb_visual.ring_alpha);
    draw_set_color(make_color_rgb(160, 244, 255));
    draw_circle(x, y, _bomb_visual.outer_radius, true);
    draw_set_color(make_color_rgb(255, 202, 246));
    draw_circle(x, y, _bomb_visual.inner_radius, true);
}

// Draw either the death burst or the live player ship body.
if (player_state.hit) {
    draw_set_alpha(0.9);
    draw_set_color(c_red);
    draw_circle(x, y, 18, false);
    draw_circle(x, y, 8, false);
    draw_set_alpha(1);
    exit;
}

var _blink_alpha = 1;
if (player_state.invuln_timer > 0 && !GamePlayerBombIsActive(player_state) && ((player_state.invuln_timer div 6) mod 2) == 0) {
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

draw_set_alpha(1);
draw_set_color(c_red);
draw_rectangle(x - 1, y - 1, x + 1, y + 1, false);

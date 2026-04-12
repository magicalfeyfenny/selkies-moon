// Draw the gutter masks and HUD entirely outside the playable field.
var _lines = GameGameplayHudLinesCreate();
var _layout = GameGameplayHudLayoutCreate();

draw_set_alpha(_layout.sidebar_alpha);
draw_set_color(_layout.sidebar_color);
draw_rectangle(_layout.left_panel_left, 0, _layout.left_panel_right, GAME_VIEW_HEIGHT, false);
draw_rectangle(_layout.right_panel_left, 0, _layout.right_panel_right, GAME_VIEW_HEIGHT, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_line(_layout.playfield_left, 0, _layout.playfield_left, GAME_VIEW_HEIGHT);
draw_line(_layout.playfield_right, 0, _layout.playfield_right, GAME_VIEW_HEIGHT);

draw_set_font(fn_menu);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);

draw_text(_layout.left_panel_left + _layout.panel_padding, _layout.panel_padding, _lines[0]);
draw_text(_layout.left_panel_left + _layout.panel_padding, _layout.panel_padding + _layout.line_height, _lines[1]);
draw_text(_layout.right_panel_left + _layout.panel_padding, _layout.panel_padding, _lines[2]);
draw_text(_layout.right_panel_left + _layout.panel_padding, _layout.panel_padding + _layout.line_height, _lines[3]);

// Draw the meter bar beneath the right-side score block.
draw_set_color(c_black);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + _layout.meter_width, _layout.meter_top + _layout.meter_height, false);
draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + ((_layout.meter_width * global.game_runtime.meter) / METER_MAX), _layout.meter_top + _layout.meter_height, false);
draw_set_color(c_white);
draw_text(_layout.meter_left, _layout.meter_top + _layout.meter_height + 6, global.game_runtime.is_berserk ? "BERSERK" : "Cancel Meter");

// Draw the continue and game-over overlay over the playable area when requested.
if (global.game_runtime.signals.continue_request) {
    draw_set_alpha(0.75);
    draw_set_color(c_black);
    draw_rectangle(118, 72, 522, 288, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(320, 108, "Continue?");
    draw_text(320, 136, "Score: " + string(global.game_runtime.score));

    if (global.game_runtime.continue_screen.mode == "game_over") {
        draw_set_color(c_red);
        draw_text(320, 186, "Game Over");
    } else {
        var _yes_label = "Yes";
        var _no_label = "No";

        if (global.game_runtime.continue_screen.selected_index == CONTINUE_OPTION_YES) {
            _yes_label = "> Yes <";
        } else {
            _no_label = "> No <";
        }

        draw_set_color(c_white);
        draw_text(320, 180, _yes_label);
        draw_text(320, 210, _no_label);
        draw_text(320, 248, "Up/Down choose  Fire confirm");
    }

    draw_set_halign(fa_left);
}

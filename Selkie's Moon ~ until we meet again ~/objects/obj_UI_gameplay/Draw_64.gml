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

GameUiDrawOutlinedText(_lines[0], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding, c_white);
GameUiDrawOutlinedText(_lines[1], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding + _layout.line_height, c_white);
GameUiDrawOutlinedText(_lines[2], _layout.right_panel_left + _layout.panel_padding, _layout.panel_padding, c_white);
GameUiDrawOutlinedText(_lines[3], _layout.right_panel_left + _layout.panel_padding, _layout.panel_padding + _layout.line_height, c_white);

// Draw the meter bar beneath the right-side score block.
draw_set_color(c_black);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + _layout.meter_width, _layout.meter_top + _layout.meter_height, false);
draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + ((_layout.meter_width * global.game_runtime.meter) / METER_MAX), _layout.meter_top + _layout.meter_height, false);
GameUiDrawOutlinedText(global.game_runtime.is_berserk ? "BERSERK" : "Cancel Meter", _layout.meter_left, _layout.meter_top + _layout.meter_height + 6, c_white);

// Draw the continue and game-over overlay over the playable area when requested.
if (global.game_runtime.signals.continue_request) {
    draw_set_alpha(0.75);
    draw_set_color(c_black);
    draw_rectangle(118, 72, 522, 288, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    GameUiDrawOutlinedText("Continue?", 320, 108, c_white);
    GameUiDrawOutlinedText("Score: " + string(global.game_runtime.score), 320, 136, c_white);

    if (global.game_runtime.continue_screen.mode == "game_over") {
        GameUiDrawOutlinedText("Game Over", 320, 186, c_red);
    } else {
        var _yes_label = "Yes";
        var _no_label = "No";

        if (global.game_runtime.continue_screen.selected_index == CONTINUE_OPTION_YES) {
            _yes_label = "> Yes <";
        } else {
            _no_label = "> No <";
        }

        GameUiDrawOutlinedText(_yes_label, 320, 180, c_white);
        GameUiDrawOutlinedText(_no_label, 320, 210, c_white);
        GameUiDrawOutlinedText("Up/Down choose  Fire confirm", 320, 248, c_white);
    }

    draw_set_halign(fa_left);
}

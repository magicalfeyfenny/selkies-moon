// Draw the top-left gameplay HUD with the current run stats.
var _lines = GameGameplayHudLinesCreate();

draw_set_font(fn_menu);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);

for (var i = 0; i < array_length(_lines); i++) {
    draw_text(16, 16 + (i * 20), _lines[i]);
}

draw_set_color(c_black);
draw_rectangle(16, 98, 224, 112, false);
draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
draw_rectangle(16, 98, 16 + ((208 * global.game_runtime.meter) / METER_MAX), 112, false);
draw_set_color(c_white);
draw_text(16, 116, global.game_runtime.is_berserk ? "BERSERK" : "Cancel Meter");

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

draw_clear_alpha(make_color_rgb(8, 12, 28), 1);

var _core_asset = asset_get_index("spr_dialogue_bg_core");
if (_core_asset != -1 && sprite_exists(_core_asset)) {
    draw_set_alpha(0.42);
    draw_set_color(c_white);
    draw_sprite_stretched(_core_asset, 0, 0, 0, GAME_VIEW_WIDTH, GAME_VIEW_HEIGHT);
}

draw_set_alpha(0.68);
draw_set_color(c_black);
draw_rectangle(0, 0, GAME_VIEW_WIDTH, GAME_VIEW_HEIGHT, false);
draw_set_alpha(1);

draw_set_font(fn_menu);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

for (var i = 0; i < array_length(credits_lines); i++) {
    var _line = credits_lines[i];
    var _y = credits_scroll_y + (i * credits_line_height);

    if (_y < -20 || _y > GAME_VIEW_HEIGHT + 20) {
        continue;
    }

    var _color = c_white;
    if (_line == "Selkie's Moon" || _line == "Characters" || _line == "Game design additions"
        || _line == "Tools and libraries" || _line == "Assets") {
        _color = make_color_rgb(255, 236, 138);
    }

    GameUiDrawOutlinedText(_line, GAME_VIEW_HALF_WIDTH, _y, _color);
}

draw_set_font(fn_dialogue_speech);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
GameUiDrawOutlinedText("Z / C / X skip", GAME_VIEW_WIDTH - 18, 20, make_color_rgb(160, 188, 220));
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Draw the scrolling credits over a dimmed story-art backdrop.
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

var _story_palette = GameUiStoryFramePaletteCreate(false);
GameUiDrawOrnateFrame(24, 10, GAME_VIEW_WIDTH - 48, GAME_VIEW_HEIGHT - 20,
    _story_palette.fill_color, 0.48, _story_palette.border_color, false);

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
    var _is_heading = _line == "Selkie's Moon" || _line == "Characters" || _line == "Game design additions"
        || _line == "Tools and libraries" || _line == "Assets";
    draw_set_font(_is_heading ? fn_dialogue_name : fn_menu);
    if (_is_heading) {
        _color = _story_palette.title_color;
    }

    GameUiDrawOutlinedText(_line, GAME_VIEW_HALF_WIDTH, _y, _color);
}

draw_set_font(fn_dialogue_speech);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
GameUiDrawOutlinedText("Z/C/X or A/B/X skip", GAME_VIEW_WIDTH - 32, 28, _story_palette.muted_text_color);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

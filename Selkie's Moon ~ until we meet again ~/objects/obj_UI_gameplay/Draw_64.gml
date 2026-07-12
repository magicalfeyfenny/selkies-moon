// Draw the gutter masks and HUD entirely outside the playable field.
var _lines = GameGameplayHudLinesCreate();
var _layout = GameGameplayHudLayoutCreate();
var _stage_info = GameStageInfoGet(GameCurrentStageGet());
var _story_palette = GameUiStoryFramePaletteCreate(false);

// Tint the playfield lightly by stage without hiding bullets or enemies.
draw_set_alpha(0.08);
draw_set_color(_stage_info.accent);
draw_rectangle(_layout.playfield_left, 0, _layout.playfield_right, GAME_VIEW_HEIGHT, false);
draw_set_alpha(1);

draw_set_alpha(_layout.sidebar_alpha);
draw_set_color(_layout.sidebar_color);
draw_rectangle(_layout.left_panel_left, 0, _layout.left_panel_right, GAME_VIEW_HEIGHT, false);
draw_rectangle(_layout.right_panel_left, 0, _layout.right_panel_right, GAME_VIEW_HEIGHT, false);
draw_set_alpha(1);

// Pearl-and-rose frames give each information block the same visual grammar as dialogue.
GameUiDrawOrnateFrame(_layout.left_panel_left + 6, 6,
    (_layout.left_panel_right - _layout.left_panel_left) - 12, 100,
    _layout.sidebar_color, 0.62, _story_palette.border_color, false);
GameUiDrawOrnateFrame(_layout.right_panel_left + 6, 6,
    (_layout.right_panel_right - _layout.right_panel_left) - 12, 114,
    _layout.sidebar_color, 0.62, _story_palette.border_color, false);

draw_set_color(_story_palette.inner_border_color);
draw_line(_layout.playfield_left, 0, _layout.playfield_left, GAME_VIEW_HEIGHT);
draw_line(_layout.playfield_right, 0, _layout.playfield_right, GAME_VIEW_HEIGHT);
GameUiDrawOrnamentDiamond(_layout.playfield_left, GAME_VIEW_HALF_HEIGHT, 3, _story_palette.ornament_color);
GameUiDrawOrnamentDiamond(_layout.playfield_right, GAME_VIEW_HALF_HEIGHT, 3, _story_palette.ornament_color);

draw_set_font(fn_dialogue_speech);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

GameUiDrawOutlinedText(_lines[0], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding, c_white);
GameUiDrawOutlinedText(_lines[1], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding + _layout.line_height, c_white);
GameUiDrawOutlinedText(_lines[2], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding + (_layout.line_height * 2), c_white);
GameUiDrawOutlinedText(_lines[3], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding + (_layout.line_height * 3), c_white);
GameUiDrawOutlinedText(_lines[4], _layout.left_panel_left + _layout.panel_padding, _layout.panel_padding + (_layout.line_height * 4), c_white);
GameUiDrawOutlinedText(_lines[5], _layout.right_panel_left + _layout.panel_padding, _layout.panel_padding, c_white);
GameUiDrawOutlinedText(_lines[6], _layout.right_panel_left + _layout.panel_padding, _layout.panel_padding + _layout.line_height, c_white);
GameUiDrawOutlinedText(_lines[7], _layout.right_panel_left + _layout.panel_padding, _layout.panel_padding + (_layout.line_height * 2), c_white);

// Score medals are plentiful, while resource recharge is explicitly earned by
// close-range play. Keep that second economy visible and visually separate.
if (struct_exists(global.game_runtime, "resource_drop_charge")
    && struct_exists(global.game_runtime, "resource_drop_threshold")) {
    var _resource_threshold = max(1, global.game_runtime.resource_drop_threshold);
    var _resource_charge = clamp(global.game_runtime.resource_drop_charge, 0, _resource_threshold);
    var _resource_ratio = _resource_charge / _resource_threshold;

    GameUiDrawOutlinedText("PB Recharge: " + string(_resource_charge) + "/" + string(_resource_threshold),
        _layout.right_panel_left + _layout.panel_padding,
        _layout.panel_padding + (_layout.line_height * 3), _story_palette.inner_border_color);

    draw_set_color(_story_palette.shadow_color);
    draw_rectangle(_layout.meter_left, 79, _layout.meter_left + _layout.meter_width, 82, false);
    draw_set_color(_story_palette.ornament_color);
    draw_rectangle(_layout.meter_left, 79,
        _layout.meter_left + (_layout.meter_width * _resource_ratio), 82, false);
    draw_set_color(_story_palette.inner_border_color);
    draw_rectangle(_layout.meter_left, 79, _layout.meter_left + _layout.meter_width, 82, true);
}

// Draw the meter bar beneath the right-side score block.
draw_set_color(c_black);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + _layout.meter_width, _layout.meter_top + _layout.meter_height, false);
draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + ((_layout.meter_width * global.game_runtime.meter) / METER_MAX), _layout.meter_top + _layout.meter_height, false);
draw_set_color(_story_palette.border_color);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + _layout.meter_width, _layout.meter_top + _layout.meter_height, true);
GameUiDrawOutlinedText(global.game_runtime.is_berserk ? "BERSERK" : "Cancel Meter", _layout.meter_left, _layout.meter_top + _layout.meter_height + 6, c_white);

// Draw the boss health bar segments in the right gutter while a boss is active.
var _boss = instance_find(obj_boss_parent, 0);
if (_boss != noone) {
    var _segments = GameBossBarSegmentsCreate(_boss.phase_index, _boss.hp, _boss.phase_max_hp, _boss.phase_count);
    var _boss_label = variable_instance_exists(_boss, "boss_display_name") ? _boss.boss_display_name : "Boss";
    var _segment_count = array_length(_segments);
    var _boss_gap = (_segment_count > 9) ? 3 : _layout.boss_bar_gap;
    var _boss_bar_top = _layout.boss_bar_top + 12;
    var _boss_available_height = GAME_VIEW_HEIGHT - _boss_bar_top - 16;
    var _boss_max_height = (_segment_count > 9) ? 5 : _layout.boss_bar_height;
    var _boss_bar_height = max(3, min(_boss_max_height,
        floor((_boss_available_height - ((_segment_count - 1) * _boss_gap)) / max(1, _segment_count))));

    GameUiDrawOrnateFrame(_layout.right_panel_left + 8, 122,
        (_layout.right_panel_right - _layout.right_panel_left) - 16, GAME_VIEW_HEIGHT - 130,
        _layout.sidebar_color, 0.46, _story_palette.border_color, false);

    draw_set_font(fn_dialogue_name);
    GameUiDrawOutlinedText(_boss_label, _layout.boss_bar_left, 126, _story_palette.title_color);

    for (var i = 0; i < _segment_count; i++) {
        var _top = _boss_bar_top + (i * (_boss_bar_height + _boss_gap));
        var _fill_color = make_color_rgb(96, 54, 86);

        if (_segments[i] > 0 && _segments[i] < 1) {
            _fill_color = make_color_rgb(255, 210, 122);
        } else if (_segments[i] >= 1) {
            _fill_color = make_color_rgb(255, 126, 108);
        }

        draw_set_color(make_color_rgb(12, 8, 24));
        draw_rectangle(_layout.boss_bar_left, _top, _layout.boss_bar_left + _layout.boss_bar_width, _top + _boss_bar_height, false);
        draw_set_color(_fill_color);
        draw_rectangle(_layout.boss_bar_left, _top, _layout.boss_bar_left + (_layout.boss_bar_width * _segments[i]), _top + _boss_bar_height, false);
        draw_set_color(_story_palette.inner_border_color);
        draw_rectangle(_layout.boss_bar_left, _top, _layout.boss_bar_left + _layout.boss_bar_width, _top + _boss_bar_height, true);
    }
}

var _scene = instance_find(obj_scene_manager, 0);
if (global.game_runtime.stage_notice_timer > 0) {
    var _alpha = clamp(global.game_runtime.stage_notice_timer / STAGE_NOTICE_FRAMES, 0, 1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    GameUiDrawOrnateFrame(_layout.playfield_left + 8, 96,
        (_layout.playfield_right - _layout.playfield_left) - 16, 112,
        _story_palette.fill_color, 0.74, _stage_info.accent, false, _alpha);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Stage " + string(GameCurrentStageGet()), GAME_VIEW_HALF_WIDTH, 110, _stage_info.accent, c_black, _alpha);
    draw_set_font(fn_dialogue_name);
    if (string_width(_stage_info.name) > ((_layout.playfield_right - _layout.playfield_left) - 40)) {
        // Preserve the full chapter name inside the narrow playfield banner.
        draw_set_font(fn_dialogue_speech);
    }
    GameUiDrawOutlinedText(_stage_info.name, GAME_VIEW_HALF_WIDTH, 134, c_white, c_black, _alpha);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedTextExt(_stage_info.subtitle, GAME_VIEW_HALF_WIDTH, 158, 15,
        (_layout.playfield_right - _layout.playfield_left) - 40, make_color_rgb(180, 204, 224), c_black, _alpha);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

if (_scene != noone && _scene.scene_state.mode == "stage_clear") {
    var _practice_complete = GameRunIsPractice();
    var _clear_title = _practice_complete ? "Practice Complete" : "Stage Clear";
    var _clear_subtitle = _practice_complete
        ? "Returning to Practice Select..."
        : (GameStageIsFinal() ? "Ending..." : "Next tide rising...");

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    GameUiDrawOrnateFrame(_layout.playfield_left + 8, 124,
        (_layout.playfield_right - _layout.playfield_left) - 16, 62,
        _story_palette.fill_color, 0.78, _story_palette.border_color, false);
    draw_set_font(fn_dialogue_name);
    GameUiDrawOutlinedText(_clear_title, GAME_VIEW_HALF_WIDTH, 144, c_yellow);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(_clear_subtitle, GAME_VIEW_HALF_WIDTH, 169, c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Draw the continue and game-over overlay over the playable area when requested.
if (global.game_runtime.signals.continue_request) {
    GameUiDrawOrnateFrame(112, 66, 416, 228,
        _story_palette.fill_color, 0.88, _story_palette.border_color, false);

    draw_set_halign(fa_center);
    draw_set_font(fn_title);
    GameUiDrawOutlinedText("Continue?", 320, 108, c_white);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("Score: " + string(global.game_runtime.score), 320, 136, c_white);

    if (global.game_runtime.continue_screen.mode == "game_over") {
        draw_set_font(fn_dialogue_name);
        GameUiDrawOutlinedText("Game Over", 320, 186, c_red);
    } else {
        draw_set_font(fn_dialogue_speech);
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

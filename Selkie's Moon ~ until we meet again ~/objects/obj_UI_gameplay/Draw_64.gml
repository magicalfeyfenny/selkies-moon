// Draw the gutter masks and HUD entirely outside the playable field.
var _lines = GameGameplayHudLinesCreate();
var _layout = GameGameplayHudLayoutCreate();
var _stage_info = GameStageInfoGet(GameCurrentStageGet());
var _story_palette = GameUiStoryFramePaletteCreate(false);

// Gameplay crystal samples the completed world, never the HUD itself.
GameUiCrystalSourceUseApplicationSurface();

// Tint the playfield lightly by stage without hiding bullets or enemies.
draw_set_alpha(0.08);
draw_set_color(_stage_info.accent);
draw_rectangle(_layout.playfield_left, 0, _layout.playfield_right, GAME_VIEW_HEIGHT, false);
draw_set_alpha(1);

GameUiDrawCrystalPane(_layout.left_panel_left, 0,
    _layout.left_panel_right, GAME_VIEW_HEIGHT,
    _layout.sidebar_color, _layout.sidebar_alpha, 1.32);
GameUiDrawCrystalPane(_layout.right_panel_left, 0,
    _layout.right_panel_right, GAME_VIEW_HEIGHT,
    _layout.sidebar_color, _layout.sidebar_alpha, 1.32);

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

// Keep the sword state in the gutter so its activation is unmistakable without
// placing another opaque meter over the bullet field.
var _player_charge = instance_find(obj_player, 0);
if (_player_charge != noone && variable_instance_exists(_player_charge, "player_state")) {
    var _charge_frames = _player_charge.player_state.fire_hold_frames;
    var _charge_ratio = global.game_runtime.is_berserk
        ? 1 : clamp(_charge_frames / FIRE_HOLD_FRAMES, 0, 1);
    var _charge_active = global.game_runtime.is_berserk || _charge_frames >= FIRE_HOLD_FRAMES;
    var _charge_label = global.game_runtime.is_berserk ? "BERSERK SWEEP"
        : (_charge_active ? "SWORD ACTIVE" : ((_charge_frames > 0)
            ? "CHARGE " + string(round(_charge_ratio * 100)) + "%" : "HOLD FIRE"));

    GameUiDrawOrnateFrame(_layout.left_panel_left + 8, 112,
        (_layout.left_panel_right - _layout.left_panel_left) - 16, 48,
        _layout.sidebar_color, 0.58,
        _charge_active ? make_color_rgb(255, 214, 112) : _story_palette.border_color, false);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("SWORD", _layout.left_panel_left + 18, 120,
        _charge_active ? make_color_rgb(255, 236, 138) : _story_palette.title_color);
    // Right-align the variable-width state so SWORD never runs into HOLD FIRE
    // or the longer charging percentage at this bitmap font size.
    draw_set_halign(fa_right);
    GameUiDrawOutlinedText(_charge_label, _layout.left_panel_right - 18, 120, c_white);
    draw_set_halign(fa_left);
    draw_set_color(_story_palette.shadow_color);
    draw_rectangle(_layout.left_panel_left + 18, 143, _layout.left_panel_right - 18, 149, false);
    draw_set_color(_charge_active ? make_color_rgb(255, 214, 112) : make_color_rgb(118, 236, 255));
    draw_rectangle(_layout.left_panel_left + 18, 143,
        lerp(_layout.left_panel_left + 18, _layout.left_panel_right - 18, _charge_ratio), 149, false);
    draw_set_color(_story_palette.inner_border_color);
    draw_rectangle(_layout.left_panel_left + 18, 143, _layout.left_panel_right - 18, 149, true);
}

// The single Berserk economy replaces the old Cancel and point-blank bars.
draw_set_color(c_black);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + _layout.meter_width, _layout.meter_top + _layout.meter_height, false);
draw_set_color(global.game_runtime.is_berserk ? c_yellow : c_aqua);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + ((_layout.meter_width * global.game_runtime.meter) / METER_MAX), _layout.meter_top + _layout.meter_height, false);
draw_set_color(_story_palette.border_color);
draw_rectangle(_layout.meter_left, _layout.meter_top, _layout.meter_left + _layout.meter_width, _layout.meter_top + _layout.meter_height, true);
GameUiDrawOutlinedText(global.game_runtime.is_berserk ? "BERSERK ACTIVE" : "Berserk Meter", _layout.meter_left, _layout.meter_top + _layout.meter_height + 6, c_white);

// The circular ring around each boss owns immediate HP readability. The gutter
// now uses small hearts solely for encounter structure and transition state.
var _boss = instance_find(obj_boss_parent, 0);
var _boss_count = instance_number(obj_boss_parent);
if (_boss_count > 1) {
    GameUiDrawOrnateFrame(_layout.right_panel_left + 8, 122,
        (_layout.right_panel_right - _layout.right_panel_left) - 16, 150,
        _layout.sidebar_color, 0.50, make_color_rgb(255, 174, 234), false);

    draw_set_font(fn_dialogue_speech);
    var _dual_finale = variable_instance_exists(_boss, "dual_finale_active")
        && _boss.dual_finale_active;
    GameUiDrawOutlinedText(_dual_finale ? "SISTERS' GRAND FINALE" : "DUAL ENCOUNTER",
        _layout.boss_bar_left, 132,
        make_color_rgb(255, 214, 112));

    for (var dual = 0; dual < _boss_count; dual++) {
        var _dual_boss = instance_find(obj_boss_parent, dual);
        var _dual_top = 156 + (dual * 62);
        var _dual_name = variable_instance_exists(_dual_boss, "boss_display_name")
            ? _dual_boss.boss_display_name : "Boss";
        var _dual_transition = variable_instance_exists(_dual_boss, "phase_transition_timer")
            && _dual_boss.phase_transition_timer > 0;
        var _dual_waiting = variable_instance_exists(_dual_boss, "dual_individual_defeated")
            && _dual_boss.dual_individual_defeated
            && (!variable_instance_exists(_dual_boss, "dual_finale_active")
                || !_dual_boss.dual_finale_active);

        draw_set_font(fn_dialogue_speech);
        GameUiDrawOutlinedText(_dual_name, _layout.boss_bar_left, _dual_top,
            (dual == 0) ? make_color_rgb(255, 188, 226) : make_color_rgb(168, 222, 255));
        GameUiDrawBossPhaseHearts(_layout.boss_bar_left, _dual_top + 21,
            _dual_boss.phase_index, _dual_boss.phase_count);
        var _dual_status = _dual_waiting ? "DEFEATED - SISTER STANDS"
            : (_dual_transition ? "REFORMING TOGETHER"
                : (_dual_finale ? "SHARED FINAL ATTACK" : "Pattern "
                    + string(_dual_boss.phase_index + 1)));
        GameUiDrawOutlinedText(_dual_status, _layout.boss_bar_left, _dual_top + 36,
            (_dual_transition || _dual_waiting)
                ? _story_palette.title_color : _story_palette.muted_text_color);
    }
} else if (_boss != noone) {
    var _boss_label = variable_instance_exists(_boss, "boss_display_name") ? _boss.boss_display_name : "Boss";
    var _boss_transition = variable_instance_exists(_boss, "phase_transition_timer")
        && _boss.phase_transition_timer > 0;
    var _heart_rows = ceil(_boss.phase_count / 10);
    var _boss_panel_height = 66 + ((_heart_rows - 1) * 11);

    GameUiDrawOrnateFrame(_layout.right_panel_left + 8, 122,
        (_layout.right_panel_right - _layout.right_panel_left) - 16, _boss_panel_height,
        _layout.sidebar_color, 0.46, _story_palette.border_color, false);

    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText(_boss_label, _layout.boss_bar_left, 126,
        make_color_rgb(255, 226, 166));
    GameUiDrawBossPhaseHearts(_layout.boss_bar_left, 150,
        _boss.phase_index, _boss.phase_count);
    GameUiDrawOutlinedText(_boss_transition ? "REFORMING - INVULNERABLE"
        : "Pattern " + string(_boss.phase_index + 1) + "/" + string(_boss.phase_count),
        _layout.boss_bar_left, 166 + ((_heart_rows - 1) * 11),
        _boss_transition ? _story_palette.title_color : _story_palette.muted_text_color);
}

// Introduce each attack over the playfield for its first two active seconds.
if (_boss != noone && !GameGameplayIsFrozen()
    && variable_instance_exists(_boss, "boss_identity")
    && is_struct(_boss.boss_identity)
    && is_array(_boss.boss_identity.phase_plan)
    && array_length(_boss.boss_identity.phase_plan) > 0
    && (!variable_instance_exists(_boss, "destruction_active") || !_boss.destruction_active)) {
    var _notice_plan = _boss.boss_identity.phase_plan;
    var _notice_index = floor(clamp(_boss.phase_index, 0, array_length(_notice_plan) - 1));
    var _notice_phase = _notice_plan[_notice_index];
    var _notice_alpha = GameBossPhaseNoticeAlphaGet(_boss.phase_timer);

    if (_notice_alpha > 0) {
        var _notice_name = GameBossPhaseDisplayNameGet(_notice_phase);
        var _notice_color = GameBossPhaseColorGet(_notice_phase.attack_theme);
        // Keep the attack name pearl-white even when the motif's frame color
        // is deliberately dark. The colored border still carries identity.
        var _notice_text_color = make_color_rgb(246, 232, 255);
        var _notice_left = _layout.playfield_left + 34;
        var _notice_width = (_layout.playfield_right - _layout.playfield_left) - 68;

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        GameUiDrawOrnateFrame(_notice_left, 16, _notice_width, 30,
            _story_palette.fill_color, 0.76, _notice_color, false, _notice_alpha);
        draw_set_font(fn_dialogue_speech);
        GameUiDrawOutlinedText(
            _notice_name, GAME_VIEW_HALF_WIDTH, 31, _notice_text_color, c_black, _notice_alpha);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
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
    // The old prompt sprawled across both HUD gutters. Keep the contract card
    // inside the playfield and veil the paused action behind it instead.
    draw_set_alpha(0.70);
    draw_set_color(make_color_rgb(5, 3, 14));
    draw_rectangle(0, 0, GAME_VIEW_WIDTH, GAME_VIEW_HEIGHT, false);
    draw_set_alpha(1);

    var _continue_left = _layout.playfield_left + 10;
    var _continue_width = (_layout.playfield_right - _layout.playfield_left) - 20;
    GameUiDrawOrnateFrame(_continue_left, 54, _continue_width, 252,
        _story_palette.fill_color, 0.94, _story_palette.border_color, false);

    GameUiDrawOrnamentDiamond(_continue_left + 18, 78, 4,
        _story_palette.ornament_color);
    GameUiDrawOrnamentDiamond(_continue_left + _continue_width - 18, 78, 4,
        _story_palette.ornament_color);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fn_title);
    GameUiDrawOutlinedText("CONTINUE?", GAME_VIEW_HALF_WIDTH, 92,
        _story_palette.title_color);
    draw_set_font(fn_dialogue_speech);
    GameUiDrawOutlinedText("The route is waiting.", GAME_VIEW_HALF_WIDTH, 126,
        _story_palette.muted_text_color);
    GameUiDrawOutlinedText("Score  " + string(global.game_runtime.score),
        GAME_VIEW_HALF_WIDTH, 151, c_white);

    if (global.game_runtime.continue_screen.mode == "game_over") {
        draw_set_font(fn_dialogue_name);
        GameUiDrawOutlinedText("GAME OVER", GAME_VIEW_HALF_WIDTH, 202,
            make_color_rgb(255, 104, 148));
        draw_set_font(fn_dialogue_speech);
        GameUiDrawOutlinedText("Returning to the title...", GAME_VIEW_HALF_WIDTH, 238,
            _story_palette.muted_text_color);

        var _game_over_ratio = clamp(
            global.game_runtime.continue_screen.game_over_timer
                / max(1, GAME_OVER_DELAY_FRAMES), 0, 1);
        draw_set_color(_story_palette.shadow_color);
        draw_rectangle(_continue_left + 30, 266,
            _continue_left + _continue_width - 30, 272, false);
        draw_set_color(make_color_rgb(255, 104, 148));
        draw_rectangle(_continue_left + 30, 266,
            lerp(_continue_left + 30, _continue_left + _continue_width - 30,
                1 - _game_over_ratio), 272, false);
    } else {
        var _yes_selected = global.game_runtime.continue_screen.selected_index
            == CONTINUE_OPTION_YES;
        var _yes_border = _yes_selected
            ? make_color_rgb(255, 218, 122) : _story_palette.inner_border_color;
        var _no_border = !_yes_selected
            ? make_color_rgb(255, 138, 186) : _story_palette.inner_border_color;

        GameUiDrawOrnateFrame(_continue_left + 18, 178, 82, 48,
            _story_palette.fill_color, _yes_selected ? 0.96 : 0.62,
            _yes_border, _yes_selected);
        GameUiDrawOrnateFrame(_continue_left + _continue_width - 100, 178, 82, 48,
            _story_palette.fill_color, !_yes_selected ? 0.96 : 0.62,
            _no_border, !_yes_selected);

        draw_set_font(fn_dialogue_name);
        GameUiDrawOutlinedText("YES", _continue_left + 59, 202,
            _yes_selected ? make_color_rgb(255, 238, 166) : c_white);
        GameUiDrawOutlinedText("NO", _continue_left + _continue_width - 59, 202,
            !_yes_selected ? make_color_rgb(255, 178, 210) : c_white);

        draw_set_font(fn_dialogue_speech);
        GameUiDrawOutlinedText("Up / Down selects", GAME_VIEW_HALF_WIDTH, 254,
            _story_palette.muted_text_color);
        GameUiDrawOutlinedText(GameInputActiveBindingLabel("fire") + " confirms",
            GAME_VIEW_HALF_WIDTH, 276, c_white);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

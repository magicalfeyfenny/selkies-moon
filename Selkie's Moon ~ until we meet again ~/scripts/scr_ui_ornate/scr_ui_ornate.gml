// Shared ornate UI palette, text, filigree, gauge, heart, and frame primitives.

/// @func GameUiDrawOutlinedText(text, x, y, text_color, outline_color, alpha)
/// Draws one line of UI text with a four-direction one-pixel outline.
function GameUiDrawOutlinedText(_text, _x, _y, _text_color = c_white, _outline_color = c_black, _alpha = 1.0) {
    draw_set_alpha(_alpha);
    draw_set_color(_outline_color);
    draw_text(_x - 1, _y, _text);
    draw_text(_x + 1, _y, _text);
    draw_text(_x, _y - 1, _text);
    draw_text(_x, _y + 1, _text);

    draw_set_color(_text_color);
    draw_text(_x, _y, _text);
    draw_set_alpha(1.0);
}

/// @func GameUiDrawOutlinedTextExt(text, x, y, sep, width, text_color, outline_color, alpha)
/// Draws wrapped UI text with the same outline style as single-line text.
function GameUiDrawOutlinedTextExt(_text, _x, _y, _sep, _width, _text_color = c_white, _outline_color = c_black, _alpha = 1.0) {
    draw_set_alpha(_alpha);
    draw_set_color(_outline_color);
    draw_text_ext(_x - 1, _y, _text, _sep, _width);
    draw_text_ext(_x + 1, _y, _text, _sep, _width);
    draw_text_ext(_x, _y - 1, _text, _sep, _width);
    draw_text_ext(_x, _y + 1, _text, _sep, _width);

    draw_set_color(_text_color);
    draw_text_ext(_x, _y, _text, _sep, _width);
    draw_set_alpha(1.0);
}

/// @func GameUiStoryFramePaletteCreate(selected)
/// Returns the shared moon-purple, pearl, and rose palette derived from the story textbox.
function GameUiStoryFramePaletteCreate(_selected = false) {
    var _palette = {
        fill_color: make_color_rgb(28, 12, 48),
        shadow_color: make_color_rgb(8, 5, 20),
        border_color: make_color_rgb(242, 232, 255),
        inner_border_color: make_color_rgb(255, 184, 224),
        ornament_color: make_color_rgb(255, 116, 198),
        vine_color: make_color_rgb(104, 214, 204),
        jewel_color: make_color_rgb(132, 102, 224),
        title_color: make_color_rgb(255, 232, 184),
        text_color: c_white,
        muted_text_color: make_color_rgb(180, 204, 232),
    };

    if (_selected) {
        _palette.fill_color = make_color_rgb(70, 24, 98);
        _palette.inner_border_color = make_color_rgb(255, 220, 150);
        _palette.ornament_color = make_color_rgb(255, 230, 164);
        _palette.vine_color = make_color_rgb(138, 242, 218);
        _palette.jewel_color = make_color_rgb(255, 142, 208);
        _palette.title_color = make_color_rgb(255, 246, 188);
    }

    return _palette;
}

/// @func GameUiDrawOrnamentDiamond(x, y, radius, color, alpha)
/// Draws the small rose-diamond ornament used at story-frame joins.
function GameUiDrawOrnamentDiamond(_x, _y, _radius, _color, _alpha = 1.0) {
    draw_set_alpha(_alpha);
    draw_set_color(_color);
    draw_triangle(_x, _y - _radius, _x + _radius, _y, _x, _y + _radius, false);
    draw_triangle(_x, _y - _radius, _x - _radius, _y, _x, _y + _radius, false);
    draw_set_alpha(1.0);
}

/// @func GameUiDrawPixelFiligreeCorner(x, y, x_sign, y_sign, palette, alpha)
/// Draws one compact vine curl derived from the layered story textbox.
function GameUiDrawPixelFiligreeCorner(_x, _y, _sx, _sy, _palette, _alpha = 1.0) {
    GameUiDrawQuadraticThread(_x, _y,
        _x + (_sx * 8), _y - (_sy * 2),
        _x + (_sx * 16), _y + (_sy * 4),
        _palette.vine_color, _alpha, 10);
    GameUiDrawQuadraticThread(_x, _y,
        _x - (_sx * 2), _y + (_sy * 8),
        _x + (_sx * 4), _y + (_sy * 16),
        _palette.vine_color, _alpha, 10);

    // Rose threads curl back toward their stems instead of terminating in
    // clipped geometric corners.
    GameUiDrawQuadraticThread(_x + (_sx * 7), _y + (_sy * 2),
        _x + (_sx * 15), _y - (_sy * 4),
        _x + (_sx * 12), _y + (_sy * 7),
        _palette.ornament_color, 0.88 * _alpha, 8);
    GameUiDrawQuadraticThread(_x + (_sx * 2), _y + (_sy * 7),
        _x - (_sx * 4), _y + (_sy * 15),
        _x + (_sx * 7), _y + (_sy * 12),
        _palette.inner_border_color, 0.76 * _alpha, 8);
    GameUiDrawOrnamentDiamond(_x + (_sx * 5), _y + (_sy * 5), 2,
        _palette.jewel_color, _alpha);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawQuadraticThread(x0, y0, cx, cy, x1, y1, color, alpha, segments)
/// Draws a one-pixel, integer-snapped thread suitable for 640x360 filigree.
function GameUiDrawQuadraticThread(_x0, _y0, _cx, _cy, _x1, _y1,
    _color, _alpha = 1.0, _segments = 12) {
    var _previous_x = round(_x0);
    var _previous_y = round(_y0);
    _segments = max(2, round(_segments));

    draw_set_alpha(_alpha);
    draw_set_color(_color);
    for (var i = 1; i <= _segments; i++) {
        var _t = i / _segments;
        var _inverse = 1 - _t;
        var _next_x = round((_inverse * _inverse * _x0)
            + (2 * _inverse * _t * _cx) + (_t * _t * _x1));
        var _next_y = round((_inverse * _inverse * _y0)
            + (2 * _inverse * _t * _cy) + (_t * _t * _y1));

        if (_next_x != _previous_x || _next_y != _previous_y) {
            draw_line(_previous_x, _previous_y, _next_x, _next_y);
        }
        _previous_x = _next_x;
        _previous_y = _next_y;
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawFiligreeDivider(left, right, y, palette, alpha, arc, thread_color)
/// Draws an open pearl-and-vine flourish with a rose jewel at its centre.
function GameUiDrawFiligreeDivider(_left, _right, _y, _palette,
    _alpha = 1.0, _arc = -3, _thread_color = -1) {
    var _center = round((_left + _right) * 0.5);
    var _gap = 7;
    var _thread = (_thread_color == -1) ? _palette.border_color : _thread_color;
    var _left_inner = _center - _gap;
    var _right_inner = _center + _gap;
    var _left_span = max(1, _left_inner - _left);
    var _right_span = max(1, _right - _right_inner);
    var _left_wave = round(_left + (_left_span * 0.52));
    var _right_wave = round(_right - (_right_span * 0.52));

    GameUiDrawQuadraticThread(_left, _y,
        _left + (_left_span * 0.24), _y + (_arc * 1.35),
        _left_wave, _y - (_arc * 0.42),
        _thread, _alpha, max(3, _left_span div 15));
    GameUiDrawQuadraticThread(_left_wave, _y - (_arc * 0.42),
        _left + (_left_span * 0.78), _y - (_arc * 1.18),
        _left_inner, _y,
        _thread, _alpha, max(3, _left_span div 15));
    GameUiDrawQuadraticThread(_right_inner, _y,
        _right - (_right_span * 0.78), _y - (_arc * 1.18),
        _right_wave, _y - (_arc * 0.42),
        _thread, _alpha, max(3, _right_span div 15));
    GameUiDrawQuadraticThread(_right_wave, _y - (_arc * 0.42),
        _right - (_right_span * 0.24), _y + (_arc * 1.35),
        _right, _y,
        _thread, _alpha, max(3, _right_span div 15));

    // A second broken thread gives the same airy cyan/pink layering as the
    // original dialogue box without enclosing the panel in a hard rectangle.
    GameUiDrawQuadraticThread(_left + 8, _y - sign(_arc) * 3,
        _left + (_left_span * 0.55), _y - (_arc * 0.55),
        _left_inner - 4, _y - sign(_arc),
        _palette.vine_color, 0.74 * _alpha, max(5, _left_span div 9));
    GameUiDrawQuadraticThread(_right_inner + 4, _y - sign(_arc),
        _right - (_right_span * 0.55), _y - (_arc * 0.55),
        _right - 8, _y - sign(_arc) * 3,
        _palette.vine_color, 0.74 * _alpha, max(5, _right_span div 9));

    GameUiDrawQuadraticThread(_center - 18, _y + sign(_arc) * 2,
        _center - 10, _y + (_arc * 2.2),
        _center - 3, _y + sign(_arc) * 5,
        _palette.ornament_color, 0.82 * _alpha, 7);
    GameUiDrawQuadraticThread(_center + 3, _y + sign(_arc) * 5,
        _center + 10, _y + (_arc * 2.2),
        _center + 18, _y + sign(_arc) * 2,
        _palette.inner_border_color, 0.82 * _alpha, 7);
    GameUiDrawOrnamentDiamond(_center, _y, 3, _palette.jewel_color, _alpha);

    if ((_right - _left) >= 140) {
        GameUiDrawOrnamentDiamond(round(lerp(_left, _center, 0.56)),
            _y + round(_arc * 0.45), 1, _palette.ornament_color, 0.72 * _alpha);
        GameUiDrawOrnamentDiamond(round(lerp(_center, _right, 0.44)),
            _y + round(_arc * 0.45), 1, _palette.ornament_color, 0.72 * _alpha);
    }
}

/// @func GameUiDrawVolumeGauge(left, right, y, ratio, selected)
/// Draws a compact rose-vine slider that sits inside a menu row rather than
/// competing with the row's lower filigree divider.
function GameUiDrawVolumeGauge(_left, _right, _y, _ratio, _selected = false) {
    var _palette = GameUiStoryFramePaletteCreate(_selected);
    var _left_x = round(min(_left, _right));
    var _right_x = round(max(_left, _right));
    var _center_y = round(_y);
    var _value = clamp(_ratio, 0, 1);
    var _thumb_x = round(lerp(_left_x, _right_x, _value));
    var _filled_color = _selected
        ? _palette.title_color : _palette.vine_color;
    var _petal_color = _selected
        ? _palette.ornament_color : _palette.inner_border_color;

    // A dim pair of loose threads defines the whole range. Their opposing
    // curves echo the dialogue-box vines without becoming another hard bar.
    GameUiDrawQuadraticThread(_left_x, _center_y,
        round((_left_x + _right_x) * 0.5), _center_y - 2,
        _right_x, _center_y,
        _palette.jewel_color, 0.42, max(8, (_right_x - _left_x) div 9));
    GameUiDrawQuadraticThread(_left_x, _center_y + 1,
        round((_left_x + _right_x) * 0.5), _center_y + 3,
        _right_x, _center_y + 1,
        _palette.inner_border_color, 0.28,
        max(8, (_right_x - _left_x) div 9));

    // The live portion blooms into brighter interlaced threads.
    if (_thumb_x > _left_x) {
        var _fill_center = round((_left_x + _thumb_x) * 0.5);
        GameUiDrawQuadraticThread(_left_x, _center_y,
            _fill_center, _center_y - 2,
            _thumb_x, _center_y,
            _filled_color, 0.96, max(3, (_thumb_x - _left_x) div 7));
        GameUiDrawQuadraticThread(_left_x, _center_y + 1,
            _fill_center, _center_y + 3,
            _thumb_x, _center_y + 1,
            _petal_color, 0.76, max(3, (_thumb_x - _left_x) div 7));
    }

    // Five restrained petal marks make the adjustment scale legible while
    // remaining decorative at the native 640x360 resolution.
    for (var i = 0; i <= 4; i++) {
        var _tick_x = round(lerp(_left_x, _right_x, i / 4));
        var _tick_active = (i / 4) <= _value;
        draw_set_alpha(_tick_active ? 0.88 : 0.38);
        draw_set_color(_tick_active ? _petal_color : _palette.jewel_color);
        draw_point(_tick_x, _center_y - 2);
        draw_point(_tick_x, _center_y + 3);
    }

    // Curl the stems inward at each end, then use a luminous rose jewel as
    // the thumb so 0% and 100% still have an intentional silhouette.
    GameUiDrawQuadraticThread(_left_x - 4, _center_y + 2,
        _left_x - 1, _center_y - 4,
        _left_x + 3, _center_y,
        _palette.vine_color, 0.72, 5);
    GameUiDrawQuadraticThread(_right_x + 4, _center_y + 2,
        _right_x + 1, _center_y - 4,
        _right_x - 3, _center_y,
        _palette.ornament_color, 0.68, 5);
    GameUiDrawOrnamentDiamond(_thumb_x, _center_y, 3,
        _selected ? _palette.ornament_color : _palette.jewel_color, 1);
    draw_set_color(_palette.border_color);
    draw_point(_thumb_x, _center_y - 1);

    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawPixelHeart(x, y, state, alpha)
/// Draws one 9x8 phase heart: spent, future, or active.
function GameUiDrawPixelHeart(_x, _y, _state, _alpha = 1.0) {
    var _palette = GameUiStoryFramePaletteCreate(_state == 2);
    var _fill = (_state == 0) ? _palette.shadow_color
        : ((_state == 2) ? _palette.title_color : _palette.ornament_color);
    var _outline = (_state == 0) ? _palette.jewel_color : _palette.border_color;
    _x = round(_x);
    _y = round(_y);

    draw_set_alpha((_state == 0 ? 0.42 : 0.94) * _alpha);
    draw_set_color(_outline);
    draw_rectangle(_x + 1, _y, _x + 3, _y + 1, false);
    draw_rectangle(_x + 5, _y, _x + 7, _y + 1, false);
    draw_rectangle(_x, _y + 2, _x + 8, _y + 4, false);
    draw_rectangle(_x + 1, _y + 5, _x + 7, _y + 5, false);
    draw_rectangle(_x + 2, _y + 6, _x + 6, _y + 6, false);
    draw_rectangle(_x + 4, _y + 7, _x + 4, _y + 7, false);

    draw_set_color(_fill);
    draw_rectangle(_x + 2, _y + 1, _x + 2, _y + 2, false);
    draw_rectangle(_x + 6, _y + 1, _x + 6, _y + 2, false);
    draw_rectangle(_x + 1, _y + 3, _x + 7, _y + 4, false);
    draw_rectangle(_x + 2, _y + 5, _x + 6, _y + 5, false);
    draw_rectangle(_x + 3, _y + 6, _x + 5, _y + 6, false);

    if (_state == 2) {
        draw_set_color(c_white);
        draw_point(_x + 2, _y + 2);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @func GameUiDrawBossPhaseHearts(x, y, phase_index, phase_count, alpha)
/// Wraps phase hearts into compact rows suitable for the redesigned gutter.
function GameUiDrawBossPhaseHearts(_x, _y, _phase_index, _phase_count, _alpha = 1.0) {
    var _states = GameBossPhaseHeartStatesCreate(_phase_index, _phase_count);
    var _per_row = 10;

    for (var i = 0; i < array_length(_states); i++) {
        var _heart_x = _x + ((i mod _per_row) * 12);
        var _heart_y = _y + ((i div _per_row) * 11);
        GameUiDrawPixelHeart(_heart_x, _heart_y, _states[i], _alpha);
    }
}

/// @func GameUiDrawOrnateFrame(x, y, width, height, fill_color, fill_alpha, accent_color, selected, frame_alpha)
/// Draws a scalable open filigree panel derived from spr_textbox's wispy threads.
function GameUiDrawOrnateFrame(_x, _y, _w, _h, _fill_color = -1, _fill_alpha = 0.76, _accent_color = -1, _selected = false, _frame_alpha = 1.0) {
    var _palette = GameUiStoryFramePaletteCreate(_selected);
    var _fill = (_fill_color == -1) ? _palette.fill_color : _fill_color;
    var _outer = (_accent_color == -1) ? _palette.border_color : _accent_color;
    var _left = round(_x);
    var _top = round(_y);
    var _right = round(_x + _w);
    var _bottom = round(_y + _h);
    _frame_alpha = clamp(_frame_alpha, 0, 1);

    // Soft offset shadow and refractive ink-dark crystal preserve contrast over
    // art. Compact rows are inset and feathered so their silhouettes do not
    // become a stack of hard purple bricks.
    if (_h < 34) {
        draw_set_alpha(min(0.38, _fill_alpha * 0.54) * _frame_alpha);
        draw_set_color(_palette.shadow_color);
        draw_rectangle(_left + 7, _top + 5, _right - 1, _bottom + 3, false);

        GameUiDrawCrystalPane(_left + 6, _top + 3,
            _right - 6, _bottom - 3, _fill,
            _fill_alpha * _frame_alpha, _selected ? 1.55 : 1.05);
        GameUiDrawCrystalPane(_left + 2, _top + 6,
            _left + 5, _bottom - 6, _fill,
            _fill_alpha * 0.42 * _frame_alpha, 0.85);
        GameUiDrawCrystalPane(_right - 5, _top + 6,
            _right - 2, _bottom - 6, _fill,
            _fill_alpha * 0.42 * _frame_alpha, 0.85);
    } else {
        draw_set_alpha(min(0.5, _fill_alpha * 0.7) * _frame_alpha);
        draw_set_color(_palette.shadow_color);
        draw_rectangle(_left + 3, _top + 3, _right + 3, _bottom + 3, false);

        GameUiDrawCrystalPane(_left, _top, _right, _bottom, _fill,
            _fill_alpha * _frame_alpha, _selected ? 1.65 : 1.18);
    }

    // Open, broken flourishes replace the former doubled rectangles. Small
    // rows deliberately omit side rails so stacked menu entries feel like
    // floating ribbons rather than a spreadsheet.
    if (_w >= 32 && _h < 34) {
        if (_selected) {
            GameUiDrawFiligreeDivider(_left + 12, _right - 12, _top + 2,
                _palette, 0.62 * _frame_alpha, -3, _outer);
        }
        GameUiDrawFiligreeDivider(_left + 4, _right - 4, _bottom - 1,
            _palette, _frame_alpha, 4,
            _selected ? _palette.title_color : _palette.inner_border_color);
    } else if (_w >= 32 && _h >= 34) {
        GameUiDrawFiligreeDivider(_left + 5, _right - 5, _top + 1,
            _palette, _frame_alpha, -3, _outer);
        GameUiDrawFiligreeDivider(_left + 5, _right - 5, _bottom - 1,
            _palette, 0.88 * _frame_alpha, 3, _palette.inner_border_color);
    }

    if (_w >= 42 && _h >= 34) {
        GameUiDrawPixelFiligreeCorner(_left + 3, _top + 3, 1, 1,
            _palette, _frame_alpha);
        GameUiDrawPixelFiligreeCorner(_right - 3, _top + 3, -1, 1,
            _palette, _frame_alpha);
        GameUiDrawPixelFiligreeCorner(_left + 3, _bottom - 3, 1, -1,
            _palette, 0.88 * _frame_alpha);
        GameUiDrawPixelFiligreeCorner(_right - 3, _bottom - 3, -1, -1,
            _palette, 0.88 * _frame_alpha);
    }

    if (_h >= 54) {
        var _center_y = round((_top + _bottom) * 0.5);
        var _side_gap = min(9, max(5, _h div 10));
        var _side_segments = max(5, (_h div 2) div 7);

        GameUiDrawQuadraticThread(_left + 1, _top + 10,
            _left - 2, _center_y - 16,
            _left + 2, _center_y - _side_gap,
            _palette.vine_color, 0.74 * _frame_alpha, _side_segments);
        GameUiDrawQuadraticThread(_left + 2, _center_y + _side_gap,
            _left - 2, _center_y + 16,
            _left + 1, _bottom - 10,
            _palette.ornament_color, 0.70 * _frame_alpha, _side_segments);
        GameUiDrawQuadraticThread(_right - 1, _top + 10,
            _right + 2, _center_y - 16,
            _right - 2, _center_y - _side_gap,
            _palette.inner_border_color, 0.72 * _frame_alpha, _side_segments);
        GameUiDrawQuadraticThread(_right - 2, _center_y + _side_gap,
            _right + 2, _center_y + 16,
            _right - 1, _bottom - 10,
            _palette.vine_color, 0.74 * _frame_alpha, _side_segments);
        GameUiDrawOrnamentDiamond(_left + 1, _center_y, 2,
            _palette.jewel_color, _frame_alpha);
        GameUiDrawOrnamentDiamond(_right - 1, _center_y, 2,
            _palette.jewel_color, _frame_alpha);
    }

    draw_set_alpha(1.0);
    draw_set_color(c_white);
}

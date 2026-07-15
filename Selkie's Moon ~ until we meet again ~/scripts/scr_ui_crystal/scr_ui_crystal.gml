// Shared crystal-glass UI rendering. Panels sample an undistorted backdrop so
// their transparency bends the art beneath them without feeding back through
// previously drawn UI layers.

/// @func GameUiCrystalSourceRegionCreate(left, top, right, bottom, source_width, source_height, gui_width, gui_height)
/// Maps one GUI-space panel rectangle onto its matching backdrop pixels.
function GameUiCrystalSourceRegionCreate(_left, _top, _right, _bottom,
    _source_width, _source_height, _gui_width, _gui_height) {
    var _gui_w = max(1, _gui_width);
    var _gui_h = max(1, _gui_height);
    var _target_left = min(_left, _right);
    var _target_top = min(_top, _bottom);
    var _target_width = abs(_right - _left);
    var _target_height = abs(_bottom - _top);
    var _source_scale_x = _source_width / _gui_w;
    var _source_scale_y = _source_height / _gui_h;

    return {
        source_x: _target_left * _source_scale_x,
        source_y: _target_top * _source_scale_y,
        source_width: _target_width * _source_scale_x,
        source_height: _target_height * _source_scale_y,
        target_x: _target_left,
        target_y: _target_top,
        target_width: _target_width,
        target_height: _target_height,
    };
}

/// @func GameUiCrystalSourceSet(surface)
/// Selects the clean scene or menu backdrop sampled by later crystal panes.
function GameUiCrystalSourceSet(_surface) {
    global.ui_crystal_source_surface = surface_exists(_surface) ? _surface : -1;
    return global.ui_crystal_source_surface;
}

/// @func GameUiCrystalSourceUseApplicationSurface()
/// Makes gameplay panes refract the completed world behind the GUI canvas.
function GameUiCrystalSourceUseApplicationSurface() {
    if (surface_exists(application_surface)) {
        return GameUiCrystalSourceSet(application_surface);
    }

    return GameUiCrystalSourceSet(-1);
}

/// @func GameUiCrystalSourceGet()
/// Returns the selected backdrop, falling back to the application surface.
function GameUiCrystalSourceGet() {
    if (variable_global_exists("ui_crystal_source_surface")
        && surface_exists(global.ui_crystal_source_surface)) {
        return global.ui_crystal_source_surface;
    }

    if (surface_exists(application_surface)) {
        return application_surface;
    }

    return -1;
}

/// @func GameUiCrystalBackdropSurfaceEnsure()
/// Keeps one volatile 640x360 backdrop owned by the persistent app bootstrap.
function GameUiCrystalBackdropSurfaceEnsure() {
    var _owner = instance_find(obj_app_init, 0);
    if (_owner == noone) {
        return -1;
    }

    if (!variable_instance_exists(_owner, "ui_crystal_backdrop_surface")) {
        _owner.ui_crystal_backdrop_surface = -1;
    }

    var _width = max(1, display_get_gui_width());
    var _height = max(1, display_get_gui_height());
    var _surface = _owner.ui_crystal_backdrop_surface;
    if (!surface_exists(_surface)
        || surface_get_width(_surface) != _width
        || surface_get_height(_surface) != _height) {
        if (surface_exists(_surface)) {
            surface_free(_surface);
        }
        _surface = surface_create(_width, _height);
        _owner.ui_crystal_backdrop_surface = _surface;
    }

    return surface_exists(_surface) ? _surface : -1;
}

/// @func GameUiCrystalBackdropBegin()
/// Redirects a title/story background draw into a clean refraction source.
function GameUiCrystalBackdropBegin() {
    var _surface = GameUiCrystalBackdropSurfaceEnsure();
    var _previous_target = surface_get_target();
    var _active = surface_exists(_surface) && _surface != _previous_target;

    if (!_active) {
        return {
            active: false,
            surface: -1,
            previous_target: _previous_target,
        };
    }

    if (_previous_target != -1) {
        surface_reset_target();
    }
    surface_set_target(_surface);
    draw_clear_alpha(c_black, 0);

    return {
        active: true,
        surface: _surface,
        previous_target: _previous_target,
    };
}

/// @func GameUiCrystalBackdropEnd(capture)
/// Restores the prior draw target, presents the backdrop, and selects it.
function GameUiCrystalBackdropEnd(_capture) {
    if (!is_struct(_capture) || !_capture.active
        || !surface_exists(_capture.surface)) {
        GameUiCrystalSourceUseApplicationSurface();
        return false;
    }

    surface_reset_target();
    if (_capture.previous_target != -1
        && surface_exists(_capture.previous_target)) {
        surface_set_target(_capture.previous_target);
    }

    GameUiCrystalSourceSet(_capture.surface);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_surface(_capture.surface, 0, 0);
    return true;
}

/// @func GameUiCrystalUniformsGet(shader)
/// Lazily caches the crystal shader's uniform handles.
function GameUiCrystalUniformsGet(_shader) {
    if (!variable_global_exists("ui_crystal_uniforms")
        || !is_struct(global.ui_crystal_uniforms)
        || global.ui_crystal_uniforms.shader != _shader) {
        global.ui_crystal_uniforms = {
            shader: _shader,
            texel: shader_get_uniform(_shader, "u_texel"),
            time: shader_get_uniform(_shader, "u_time"),
            strength: shader_get_uniform(_shader, "u_strength"),
            tint_amount: shader_get_uniform(_shader, "u_tint_amount"),
        };
    }

    return global.ui_crystal_uniforms;
}

/// @func GameUiDrawCrystalPane(left, top, right, bottom, tint, alpha, strength)
/// Draws a tinted, faceted, chromatically refracted copy of the backdrop.
function GameUiDrawCrystalPane(_left, _top, _right, _bottom, _tint,
    _alpha = 0.76, _strength = 1.0) {
    var _source = GameUiCrystalSourceGet();
    var _shader = asset_get_index("shd_ui_crystal");
    var _clamped_alpha = clamp(_alpha, 0, 1);
    var _can_refract = surface_exists(_source)
        && _shader != -1
        && shader_is_compiled(_shader);

    if (!_can_refract) {
        draw_set_alpha(_clamped_alpha);
        draw_set_color(_tint);
        draw_rectangle(_left, _top, _right, _bottom, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        return false;
    }

    var _source_width = surface_get_width(_source);
    var _source_height = surface_get_height(_source);
    var _region = GameUiCrystalSourceRegionCreate(_left, _top, _right, _bottom,
        _source_width, _source_height,
        display_get_gui_width(), display_get_gui_height());
    if (_region.target_width <= 0 || _region.target_height <= 0
        || _region.source_width <= 0 || _region.source_height <= 0) {
        return false;
    }

    var _uniforms = GameUiCrystalUniformsGet(_shader);
    shader_set(_shader);
    shader_set_uniform_f(_uniforms.texel,
        1 / max(1, _source_width), 1 / max(1, _source_height));
    shader_set_uniform_f(_uniforms.time, current_time * 0.001);
    shader_set_uniform_f(_uniforms.strength, max(0, _strength));
    shader_set_uniform_f(_uniforms.tint_amount,
        clamp(0.16 + (_clamped_alpha * 0.24), 0.16, 0.42));

    draw_surface_part_ext(_source,
        _region.source_x, _region.source_y,
        _region.source_width, _region.source_height,
        _region.target_x, _region.target_y,
        _region.target_width / _region.source_width,
        _region.target_height / _region.source_height,
        _tint, _clamped_alpha);

    shader_reset();
    draw_set_alpha(1);
    draw_set_color(c_white);
    return true;
}

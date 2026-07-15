/// True-3D scrolling stage presentation. Gameplay remains in the ordinary 2D
/// draw and GUI passes, which always occur after obj_scene_manager's Draw Begin.

function GameStage3DVertexFormatCreate() {
    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    return vertex_format_end();
}

function GameStage3DUniformsCreate() {
    return {
        tex_uv: shader_get_uniform(shd_stage_3d, "u_tex_uv"),
        camera: shader_get_uniform(shd_stage_3d, "u_camera"),
        light_dir: shader_get_uniform(shd_stage_3d, "u_light_dir"),
        light_color: shader_get_uniform(shd_stage_3d, "u_light_color"),
        rim_dir: shader_get_uniform(shd_stage_3d, "u_rim_dir"),
        rim_color: shader_get_uniform(shd_stage_3d, "u_rim_color"),
        ambient: shader_get_uniform(shd_stage_3d, "u_ambient"),
        fog_color: shader_get_uniform(shd_stage_3d, "u_fog_color"),
        fog_start: shader_get_uniform(shd_stage_3d, "u_fog_start"),
        fog_end: shader_get_uniform(shd_stage_3d, "u_fog_end"),
        emissive: shader_get_uniform(shd_stage_3d, "u_emissive"),
        time: shader_get_uniform(shd_stage_3d, "u_time")
    };
}

function GameStage3DConfigGet(_stage) {
    switch (clamp(_stage, 1, 5)) {
        case 1:
            return {
                buffer_name: "stage3d_01_shalmii_forge_procession.vbuff",
                texture_sprite: tex_stage3d_01,
                clear_color: make_color_rgb(9, 3, 12),
                speed: 0.028,
                camera_x: [-1.0, 1.5, -1.5, 0.8, -1.0],
                camera_z: [10.0, 9.2, 10.4, 8.8, 10.0],
                target_z: 1.2,
                light_dir: [-0.58, -0.44, -0.68],
                light_color: [1.00, 0.34, 0.10],
                rim_dir: [0.52, 0.20, -0.83],
                rim_color: [0.48, 0.22, 0.56],
                ambient: [0.16, 0.08, 0.14],
                fog_color: [0.12, 0.035, 0.045],
                fog_start: 20.0,
                fog_end: 78.0,
                emissive: 0.62,
                effect: "embers"
            };
        case 2:
            return {
                buffer_name: "stage3d_02_aster_saltwind_ribbon_coast.vbuff",
                texture_sprite: tex_stage3d_02,
                clear_color: make_color_rgb(12, 13, 31),
                speed: 0.025,
                camera_x: [-4.0, -1.0, 4.0, 1.0, -4.0],
                camera_z: [11.0, 12.0, 9.4, 10.5, 11.0],
                target_z: 0.2,
                light_dir: [-0.34, -0.48, -0.81],
                light_color: [0.55, 0.82, 1.00],
                rim_dir: [0.72, 0.10, -0.68],
                rim_color: [1.00, 0.42, 0.73],
                ambient: [0.18, 0.19, 0.35],
                fog_color: [0.18, 0.16, 0.34],
                fog_start: 24.0,
                fog_end: 92.0,
                emissive: 0.42,
                effect: "salt_mist"
            };
        case 3:
            return {
                buffer_name: "stage3d_03_mira_aisha_velvet_wishcourt.vbuff",
                texture_sprite: tex_stage3d_03,
                clear_color: make_color_rgb(8, 3, 18),
                speed: 0.023,
                camera_x: [0.0, -3.5, 3.5, -2.0, 0.0],
                camera_z: [9.5, 10.5, 10.5, 9.0, 9.5],
                target_z: 1.5,
                light_dir: [-0.66, -0.28, -0.70],
                light_color: [1.00, 0.12, 0.54],
                rim_dir: [0.66, 0.16, -0.73],
                rim_color: [0.10, 0.70, 1.00],
                ambient: [0.18, 0.08, 0.24],
                fog_color: [0.11, 0.035, 0.17],
                fog_start: 22.0,
                fog_end: 82.0,
                emissive: 0.58,
                effect: "duet_dust"
            };
        case 4:
            return {
                buffer_name: "stage3d_04_caelia_bloodstar_orrery.vbuff",
                texture_sprite: tex_stage3d_04,
                clear_color: make_color_rgb(3, 3, 12),
                speed: 0.021,
                camera_x: [2.0, -2.5, 1.0, 3.0, 2.0],
                camera_z: [11.5, 12.5, 8.8, 11.8, 11.5],
                target_z: 2.4,
                light_dir: [-0.26, -0.35, -0.90],
                light_color: [0.35, 0.58, 1.00],
                rim_dir: [0.70, 0.34, -0.62],
                rim_color: [0.94, 0.05, 0.22],
                ambient: [0.08, 0.07, 0.20],
                fog_color: [0.04, 0.025, 0.11],
                fog_start: 18.0,
                fog_end: 76.0,
                emissive: 0.68,
                effect: "astral_sparks"
            };
        default:
            return {
                buffer_name: "stage3d_05_moon_selkie_infinite_violet_garden.vbuff",
                texture_sprite: tex_stage3d_05,
                clear_color: make_color_rgb(9, 3, 15),
                speed: 0.019,
                camera_x: [0.0, -3.0, 3.0, -1.5, 0.0],
                camera_z: [8.8, 9.7, 8.3, 10.2, 8.8],
                target_z: 0.8,
                light_dir: [-0.50, -0.32, -0.80],
                light_color: [0.76, 0.38, 1.00],
                rim_dir: [0.58, 0.26, -0.77],
                rim_color: [1.00, 0.72, 0.26],
                ambient: [0.19, 0.08, 0.25],
                fog_color: [0.15, 0.045, 0.18],
                fog_start: 16.0,
                fog_end: 68.0,
                emissive: 0.72,
                effect: "violet_pollen"
            };
    }
}

function GameStage3DBufferEnsure(_owner, _stage) {
    if (_owner.stage3d_stage == _stage && _owner.stage3d_buffer != -1) {
        return true;
    }

    if (_owner.stage3d_buffer != -1) {
        vertex_delete_buffer(_owner.stage3d_buffer);
        _owner.stage3d_buffer = -1;
    }

    _owner.stage3d_stage = _stage;
    _owner.stage3d_config = GameStage3DConfigGet(_stage);
    var _path = program_directory + _owner.stage3d_config.buffer_name;
    if (!file_exists(_path)) {
        _path = program_directory + "datafiles/" + _owner.stage3d_config.buffer_name;
    }
    if (!file_exists(_path)) {
        _path = working_directory + _owner.stage3d_config.buffer_name;
    }
    if (!file_exists(_path)) {
        show_debug_message("Missing 3D stage buffer: " + _path);
        return false;
    }

    var _data = buffer_load(_path);
    _owner.stage3d_buffer = vertex_create_buffer_from_buffer(_data, _owner.stage3d_vertex_format);
    buffer_delete(_data);
    vertex_freeze(_owner.stage3d_buffer);
    return true;
}

function GameStage3DPathSample(_config, _phase) {
    var _scaled = (_phase / 64.0) * 4.0;
    var _segment = min(3, floor(_scaled));
    var _amount = _scaled - _segment;
    // Smooth endpoints keep the modular loop from visibly snapping.
    _amount = _amount * _amount * (3.0 - (2.0 * _amount));
    return {
        x: lerp(_config.camera_x[_segment], _config.camera_x[_segment + 1], _amount),
        y: _phase,
        z: lerp(_config.camera_z[_segment], _config.camera_z[_segment + 1], _amount)
    };
}

function GameStage3DUniformVec3(_location, _value) {
    shader_set_uniform_f(_location, _value[0], _value[1], _value[2]);
}

function GameStage3DRender(_owner, _scene_state) {
    var _stage = clamp(GameCurrentStageGet(), 1, 5);
    var _ready = GameStage3DBufferEnsure(_owner, _stage);
    var _config = _owner.stage3d_config;
    draw_clear(_config.clear_color);

    if (!_ready) {
        return;
    }

    var _phase = ((_scene_state.frame * _config.speed) mod 64.0);
    var _camera = GameStage3DPathSample(_config, _phase);
    var _look_phase = (_phase + 11.0) mod 64.0;
    var _look = GameStage3DPathSample(_config, _look_phase);
    var _look_y = _camera.y + 11.0;

    var _old_world = matrix_get(matrix_world);
    var _old_view = matrix_get(matrix_view);
    var _old_projection = matrix_get(matrix_projection);

    matrix_set(matrix_view, matrix_build_lookat(
        _camera.x, _camera.y, _camera.z,
        _look.x, _look_y, _config.target_z,
        0, 0, 1
    ));
    matrix_set(matrix_projection, matrix_build_projection_perspective_fov(52, 640 / 360, 0.25, 140));

    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);
    gpu_set_blendenable(false);
    shader_set(shd_stage_3d);

    var _uniforms = _owner.stage3d_uniforms;
    var _uv = sprite_get_uvs(_config.texture_sprite, 0);
    shader_set_uniform_f(_uniforms.tex_uv, _uv[0], _uv[1], _uv[2] - _uv[0], _uv[3] - _uv[1]);
    shader_set_uniform_f(_uniforms.camera, _camera.x, _camera.y, _camera.z);
    GameStage3DUniformVec3(_uniforms.light_dir, _config.light_dir);
    GameStage3DUniformVec3(_uniforms.light_color, _config.light_color);
    GameStage3DUniformVec3(_uniforms.rim_dir, _config.rim_dir);
    GameStage3DUniformVec3(_uniforms.rim_color, _config.rim_color);
    GameStage3DUniformVec3(_uniforms.ambient, _config.ambient);
    GameStage3DUniformVec3(_uniforms.fog_color, _config.fog_color);
    shader_set_uniform_f(_uniforms.fog_start, _config.fog_start);
    shader_set_uniform_f(_uniforms.fog_end, _config.fog_end);
    shader_set_uniform_f(_uniforms.emissive, _config.emissive);
    shader_set_uniform_f(_uniforms.time, _scene_state.frame / room_speed);

    var _texture = sprite_get_texture(_config.texture_sprite, 0);
    for (var _copy = -1; _copy <= 1; _copy++) {
        matrix_set(matrix_world, matrix_build(
            0, _copy * 64, 0,
            0, 0, 0,
            1, 1, 1
        ));
        vertex_submit(_owner.stage3d_buffer, pr_trianglelist, _texture);
    }

    shader_reset();
    gpu_set_blendenable(true);
    gpu_set_zwriteenable(false);
    gpu_set_ztestenable(false);
    gpu_set_cullmode(cull_noculling);
    matrix_set(matrix_world, _old_world);
    matrix_set(matrix_view, _old_view);
    matrix_set(matrix_projection, _old_projection);
}

function GameStage3DHash01(_value) {
    var _raw = sin(_value * 12.9898) * 43758.5453;
    return _raw - floor(_raw);
}

function GameStage3DAtmosphereDraw(_scene_state, _config) {
    var _cx = _scene_state.target_x;
    var _top = _scene_state.camera_y - PLAYFIELD_HALF_HEIGHT;
    var _left = _cx - PLAYFIELD_HALF_WIDTH;
    var _width = PLAYFIELD_HALF_WIDTH * 2;
    var _height = PLAYFIELD_HALF_HEIGHT * 2;
    var _frame = _scene_state.frame;

    draw_set_alpha(0.42);
    for (var _index = 0; _index < 28; _index++) {
        var _seed_x = GameStage3DHash01((_index + 1) * 9.17);
        var _seed_y = GameStage3DHash01((_index + 1) * 19.31);
        var _x = round(_left + (_seed_x * _width));
        var _y;

        switch (_config.effect) {
            case "embers":
                _y = round(_top + ((_seed_y * _height - _frame * (0.14 + _seed_x * 0.12)) mod _height + _height) mod _height);
                draw_set_color((_index mod 3 == 0) ? make_color_rgb(255, 213, 94) : make_color_rgb(238, 83, 42));
                draw_rectangle(_x, _y, _x + ((_index mod 5 == 0) ? 1 : 0), _y + 1, false);
                break;
            case "salt_mist":
                _y = round(_top + (_seed_y * _height));
                _x = round(_left + ((_seed_x * _width + _frame * (0.10 + _seed_y * 0.08)) mod _width));
                draw_set_color((_index mod 2 == 0) ? make_color_rgb(166, 225, 224) : make_color_rgb(234, 183, 220));
                draw_line(_x, _y, _x + 2 + (_index mod 4), _y);
                break;
            case "duet_dust":
                _y = round(_top + ((_seed_y * _height - _frame * 0.07) mod _height + _height) mod _height);
                draw_set_color((_x < _cx) ? make_color_rgb(232, 50, 147) : make_color_rgb(58, 185, 235));
                draw_point(_x, _y);
                if (_index mod 6 == 0) draw_point(round((_cx * 2) - _x), _y);
                break;
            case "astral_sparks":
                _y = round(_top + ((_seed_y * _height + _frame * 0.05) mod _height));
                draw_set_color((_index mod 4 == 0) ? make_color_rgb(235, 48, 85) : make_color_rgb(116, 163, 245));
                draw_point(_x, _y);
                if (_index mod 7 == 0) {
                    draw_point(_x - 1, _y);
                    draw_point(_x + 1, _y);
                    draw_point(_x, _y - 1);
                    draw_point(_x, _y + 1);
                }
                break;
            default:
                _y = round(_top + ((_seed_y * _height - _frame * (0.04 + _seed_x * 0.05)) mod _height + _height) mod _height);
                draw_set_color((_index mod 3 == 0) ? make_color_rgb(247, 194, 88) : make_color_rgb(197, 117, 225));
                if (_index mod 5 == 0) {
                    draw_rectangle(_x - 1, _y, _x + 1, _y + 1, false);
                } else {
                    draw_point(_x, _y);
                }
                break;
        }
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

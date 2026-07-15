/// True-3D scrolling stage presentation. Gameplay remains in the ordinary 2D
/// draw and GUI passes, which always occur after obj_scene_manager's Draw Begin.

function GameStage3DVertexFormatCreate() {
    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_normal();
    vertex_format_add_texcoord();
    return vertex_format_end();
}

/// Four reusable textured quads address the four transparent billboard cells
/// in the lower-right texture-atlas quadrant. World matrices turn each quad to
/// face the live camera, so foliage and atmospheric set dressing remain true
/// billboards even after the boss route diverges from the travel route.
function GameStage3DBillboardBuffersCreate(_format) {
    var _buffers = [];

    for (var _tile = 0; _tile < 4; _tile++) {
        var _column = _tile mod 2;
        var _row = _tile div 2;
        var _u0 = 0.5 + (_column * 0.25);
        var _u1 = _u0 + 0.25;
        // GameMaker's 3D UV origin addresses the source image from its lower
        // edge. The authored cards occupy the image's lower-right quadrant,
        // so their V coordinates descend from 0.5 toward 0 rather than using
        // the opaque upper-right architecture quadrant.
        var _v0 = 0.5 - (_row * 0.25);
        var _v1 = _v0 - 0.25;
        var _buffer = vertex_create_buffer();
        vertex_begin(_buffer, _format);

        vertex_position_3d(_buffer, -0.5, 0, 0);
        vertex_normal(_buffer, 0, -1, 0);
        vertex_texcoord(_buffer, _u0, _v1);
        vertex_position_3d(_buffer, -0.5, 0, 1);
        vertex_normal(_buffer, 0, -1, 0);
        vertex_texcoord(_buffer, _u0, _v0);
        vertex_position_3d(_buffer, 0.5, 0, 1);
        vertex_normal(_buffer, 0, -1, 0);
        vertex_texcoord(_buffer, _u1, _v0);

        vertex_position_3d(_buffer, -0.5, 0, 0);
        vertex_normal(_buffer, 0, -1, 0);
        vertex_texcoord(_buffer, _u0, _v1);
        vertex_position_3d(_buffer, 0.5, 0, 1);
        vertex_normal(_buffer, 0, -1, 0);
        vertex_texcoord(_buffer, _u1, _v0);
        vertex_position_3d(_buffer, 0.5, 0, 0);
        vertex_normal(_buffer, 0, -1, 0);
        vertex_texcoord(_buffer, _u1, _v1);

        vertex_end(_buffer);
        vertex_freeze(_buffer);
        array_push(_buffers, _buffer);
    }

    return _buffers;
}

function GameStage3DBillboardCreate(_x, _y, _z, _width, _height, _tile) {
    return {
        x: _x,
        y: _y,
        z: _z,
        width: _width,
        height: _height,
        tile: clamp(_tile, 0, 3),
    };
}

/// Dense deterministic billboard layouts extend the modeled set to the fog
/// horizon without inflating the collision-free presentation mesh.
function GameStage3DBillboardLayoutCreate(_stage) {
    _stage = clamp(_stage, 1, 5);
    var _layout = [];
    var _counts = [18, 24, 22, 20, 48];
    var _count = _counts[_stage - 1];

    for (var _index = 0; _index < _count; _index++) {
        var _y = ((_index * 17) mod 64) + ((_index mod 3) * 0.37);
        var _side = ((_index mod 2) == 0) ? -1 : 1;
        var _x = _side * (10 + ((_index * 7) mod 10));
        var _tile = _index mod 4;
        var _z = -0.05;
        var _width = 4;
        var _height = 6;

        switch (_stage) {
            case 1:
                // Flame plumes, hammer standards, smoke, and stacked weapon silhouettes.
                _width = 3.4 + ((_index mod 4) * 0.7);
                _height = 5.5 + ((_index mod 5) * 1.1);
                _x = _side * (11 + ((_index * 5) mod 8));
                break;

            case 2:
                // Layered woodland trunks, leafy crowns, rabbit topiary, and burrow signs.
                _width = 5.5 + ((_index mod 4) * 1.2);
                _height = 8.5 + ((_index mod 6) * 1.4);
                _x = _side * (9 + ((_index * 3) mod 11));
                break;

            case 3:
                // Casino marquees stay left; curtains, sigils, and conjured stars stay right.
                _x = _side * (9 + ((_index * 5) mod 10));
                _tile = (_side < 0) ? (_index mod 2) : (2 + (_index mod 2));
                _width = 5.0 + ((_index mod 3) * 1.3);
                _height = 6.5 + ((_index mod 4) * 1.1);
                break;

            case 4:
                // Nebula clouds, spiral galaxies, planets, and star nurseries float at depth.
                _x = _side * (7 + ((_index * 7) mod 14));
                _z = 3 + ((_index * 11) mod 12);
                _width = 7.5 + ((_index mod 5) * 2.1);
                _height = 6.5 + ((_index mod 4) * 1.8);
                break;

            default:
                // Near flower clumps and distant vine walls make the field continuous.
                _x = -17 + ((_index * 11) mod 35);
                _width = 5.4 + ((_index mod 5) * 1.15);
                _height = 5.8 + ((_index mod 4) * 1.45);
                _z = 0.02;
                break;
        }

        array_push(_layout, GameStage3DBillboardCreate(
            _x, _y, _z, _width, _height, _tile));

        // A second horizon layer closes gaps between foreground cards.
        if (_stage == 2 || _stage == 5) {
            array_push(_layout, GameStage3DBillboardCreate(
                -_x * 0.78, (_y + 7.5) mod 64, _z + 0.05,
                _width * 0.74, _height * 0.82, (_tile + 1) mod 4));
        }
    }

    return _layout;
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
                boss_camera_x: [-1.0, 3.2, -3.0, 2.4, -1.0],
                boss_camera_z: [10.0, 7.8, 8.7, 7.4, 10.0],
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
                effect: "embers",
                billboards: GameStage3DBillboardLayoutCreate(1),
            };
        case 2:
            return {
                buffer_name: "stage3d_02_aster_saltwind_ribbon_coast.vbuff",
                texture_sprite: tex_stage3d_02,
                clear_color: make_color_rgb(12, 13, 31),
                speed: 0.025,
                camera_x: [-4.0, -1.0, 4.0, 1.0, -4.0],
                camera_z: [11.0, 12.0, 9.4, 10.5, 11.0],
                boss_camera_x: [-4.0, 4.8, -3.8, 2.2, -4.0],
                boss_camera_z: [11.0, 8.0, 9.2, 7.8, 11.0],
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
                effect: "forest_fireflies",
                billboards: GameStage3DBillboardLayoutCreate(2),
            };
        case 3:
            return {
                buffer_name: "stage3d_03_mira_aisha_velvet_wishcourt.vbuff",
                texture_sprite: tex_stage3d_03,
                clear_color: make_color_rgb(8, 3, 18),
                speed: 0.023,
                camera_x: [0.0, -3.5, 3.5, -2.0, 0.0],
                camera_z: [9.5, 10.5, 10.5, 9.0, 9.5],
                boss_camera_x: [0.0, 4.2, -4.0, 3.0, 0.0],
                boss_camera_z: [9.5, 8.1, 9.4, 7.8, 9.5],
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
                effect: "vegas_magic_dust",
                billboards: GameStage3DBillboardLayoutCreate(3),
            };
        case 4:
            return {
                buffer_name: "stage3d_04_caelia_bloodstar_orrery.vbuff",
                texture_sprite: tex_stage3d_04,
                clear_color: make_color_rgb(3, 3, 12),
                speed: 0.021,
                camera_x: [2.0, -2.5, 1.0, 3.0, 2.0],
                camera_z: [11.5, 12.5, 8.8, 11.8, 11.5],
                boss_camera_x: [2.0, 5.0, -5.0, 3.2, 2.0],
                boss_camera_z: [11.5, 8.0, 12.2, 8.6, 11.5],
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
                effect: "deep_space",
                billboards: GameStage3DBillboardLayoutCreate(4),
            };
        default:
            return {
                buffer_name: "stage3d_05_moon_selkie_infinite_violet_garden.vbuff",
                texture_sprite: tex_stage3d_05,
                clear_color: make_color_rgb(9, 3, 15),
                speed: 0.019,
                camera_x: [0.0, -3.0, 3.0, -1.5, 0.0],
                camera_z: [8.8, 9.7, 8.3, 10.2, 8.8],
                boss_camera_x: [0.0, 2.6, -2.6, 1.2, 0.0],
                boss_camera_z: [8.8, 6.8, 7.6, 6.5, 8.8],
                target_z: 0.8,
                light_dir: [-0.50, -0.32, -0.80],
                light_color: [0.92, 0.48, 1.00],
                rim_dir: [0.58, 0.26, -0.77],
                rim_color: [1.00, 0.72, 0.26],
                ambient: [0.30, 0.14, 0.36],
                fog_color: [0.14, 0.055, 0.19],
                fog_start: 22.0,
                fog_end: 84.0,
                emissive: 0.90,
                effect: "violet_pollen",
                billboards: GameStage3DBillboardLayoutCreate(5),
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

function GameStage3DPathSample(_config, _phase, _boss_route = false) {
    var _scaled = (_phase / 64.0) * 4.0;
    var _segment = min(3, floor(_scaled));
    var _amount = _scaled - _segment;
    // Smooth endpoints keep the modular loop from visibly snapping.
    _amount = _amount * _amount * (3.0 - (2.0 * _amount));
    var _path_x = _boss_route ? _config.boss_camera_x : _config.camera_x;
    var _path_z = _boss_route ? _config.boss_camera_z : _config.camera_z;
    return {
        x: lerp(_path_x[_segment], _path_x[_segment + 1], _amount),
        y: _phase,
        z: lerp(_path_z[_segment], _path_z[_segment + 1], _amount)
    };
}

function GameStage3DPathBlendSample(_config, _phase, _blend) {
    var _travel = GameStage3DPathSample(_config, _phase, false);
    var _boss = GameStage3DPathSample(_config, _phase, true);
    _blend = clamp(_blend, 0, 1);
    // Smooth the route handoff while preserving the shared forward distance.
    _blend = _blend * _blend * (3.0 - (2.0 * _blend));
    return {
        x: lerp(_travel.x, _boss.x, _blend),
        y: _phase,
        z: lerp(_travel.z, _boss.z, _blend),
    };
}

function GameStage3DPathLoopIsValid(_config, _boss_route = false) {
    var _path_x = _boss_route ? _config.boss_camera_x : _config.camera_x;
    var _path_z = _boss_route ? _config.boss_camera_z : _config.camera_z;
    return array_length(_path_x) == 5
        && array_length(_path_z) == 5
        && _path_x[0] == _path_x[4]
        && _path_z[0] == _path_z[4];
}

function GameStage3DBillboardsDraw(_owner, _config, _camera, _texture) {
    if (!is_array(_owner.stage3d_billboard_buffers)
        || !is_array(_config.billboards)) {
        return 0;
    }

    var _submitted = 0;
    for (var _copy = -1; _copy <= 1; _copy++) {
        for (var _index = array_length(_config.billboards) - 1; _index >= 0; _index--) {
            var _billboard = _config.billboards[_index];
            var _world_y = _billboard.y + (_copy * 64);
            var _camera_dx = _camera.x - _billboard.x;
            var _camera_dy = _camera.y - _world_y;
            var _yaw = radtodeg(arctan2(_camera_dx, -_camera_dy));

            matrix_set(matrix_world, matrix_build(
                _billboard.x, _world_y, _billboard.z,
                0, 0, _yaw,
                _billboard.width, 1, _billboard.height
            ));
            vertex_submit(
                _owner.stage3d_billboard_buffers[_billboard.tile],
                pr_trianglelist,
                _texture
            );
            _submitted += 1;
        }
    }

    return _submitted;
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

    var _phase = ((_scene_state.background_frame * _config.speed) mod 64.0);
    var _route_blend = _scene_state.background_route_blend;
    var _camera = GameStage3DPathBlendSample(_config, _phase, _route_blend);
    var _look_phase = (_phase + 11.0) mod 64.0;
    var _look = GameStage3DPathBlendSample(_config, _look_phase, _route_blend);
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
    shader_set_uniform_f(_uniforms.time, _scene_state.background_frame / room_speed);

    var _texture = sprite_get_texture(_config.texture_sprite, 0);
    for (var _copy = -1; _copy <= 1; _copy++) {
        matrix_set(matrix_world, matrix_build(
            0, _copy * 64, 0,
            0, 0, 0,
            1, 1, 1
        ));
        vertex_submit(_owner.stage3d_buffer, pr_trianglelist, _texture);
    }

    // Alpha-tested, camera-facing layers add forest canopy, flame and smoke,
    // Vegas signage, nebulae, and the far violet field around the modeled set.
    gpu_set_blendenable(true);
    gpu_set_zwriteenable(false);
    GameStage3DBillboardsDraw(_owner, _config, _camera, _texture);

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
    var _frame = _scene_state.background_frame;

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
            case "forest_fireflies":
                _y = round(_top + ((_seed_y * _height
                    + dsin((_frame * 0.7) + (_index * 31)) * 9) mod _height));
                _x = round(_left + ((_seed_x * _width
                    + dcos((_frame * 0.5) + (_index * 43)) * 7) mod _width));
                draw_set_color((_index mod 3 == 0)
                    ? make_color_rgb(255, 224, 118) : make_color_rgb(132, 238, 166));
                draw_point(_x, _y);
                if ((_index mod 7) == 0) draw_point(_x + 1, _y);
                break;

            case "vegas_magic_dust":
                _y = round(_top + ((_seed_y * _height - _frame * 0.07) mod _height + _height) mod _height);
                if (_x < _cx) {
                    draw_set_color((_index mod 2 == 0)
                        ? make_color_rgb(255, 74, 132) : make_color_rgb(255, 214, 104));
                    draw_rectangle(_x, _y, _x + 1, _y + ((_index mod 4) == 0), false);
                } else {
                    draw_set_color((_index mod 2 == 0)
                        ? make_color_rgb(116, 210, 255) : make_color_rgb(214, 132, 255));
                    draw_point(_x, _y);
                    if ((_index mod 6) == 0) {
                        draw_point(_x - 1, _y);
                        draw_point(_x + 1, _y);
                        draw_point(_x, _y - 1);
                        draw_point(_x, _y + 1);
                    }
                }
                break;

            case "deep_space":
                _y = round(_top + ((_seed_y * _height + _frame * 0.05) mod _height));
                draw_set_color((_index mod 5 == 0)
                    ? make_color_rgb(255, 184, 232) : make_color_rgb(142, 182, 255));
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

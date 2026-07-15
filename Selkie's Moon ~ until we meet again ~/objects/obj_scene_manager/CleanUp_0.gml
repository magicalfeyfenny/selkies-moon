if (stage3d_buffer != -1) {
    vertex_delete_buffer(stage3d_buffer);
    stage3d_buffer = -1;
}

if (is_array(stage3d_billboard_buffers)) {
    for (var _billboard = 0; _billboard < array_length(stage3d_billboard_buffers); _billboard++) {
        if (stage3d_billboard_buffers[_billboard] != -1) {
            vertex_delete_buffer(stage3d_billboard_buffers[_billboard]);
        }
    }
    stage3d_billboard_buffers = [];
}

if (stage3d_vertex_format != -1) {
    vertex_format_delete(stage3d_vertex_format);
    stage3d_vertex_format = -1;
}

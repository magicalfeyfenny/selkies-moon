if (stage3d_buffer != -1) {
    vertex_delete_buffer(stage3d_buffer);
    stage3d_buffer = -1;
}

if (stage3d_vertex_format != -1) {
    vertex_format_delete(stage3d_vertex_format);
    stage3d_vertex_format = -1;
}

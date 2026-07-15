// Draw GUI Begin: capture every GUI object into one true 640x360 pixel canvas.
gpu_set_texfilter(false);

if (!surface_exists(ui_surface)
    || surface_get_width(ui_surface) != 640
    || surface_get_height(ui_surface) != 360) {
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
    }
    ui_surface = surface_create(640, 360);
}

if (surface_exists(ui_surface)) {
    surface_set_target(ui_surface);
    draw_clear_alpha(c_black, 0);
    ui_surface_targeted = true;
}

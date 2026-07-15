// Finish the shared 640x360 GUI canvas, then composite it over the already
// presented application surface. Integer output remains razor-sharp; only a
// fractional fullscreen scale receives bilinear antialiasing.
if (ui_surface_targeted) {
    surface_reset_target();
    ui_surface_targeted = false;
}

if (surface_exists(ui_surface)) {
    var _linear_filter = GamePixelPresentationLinearFilterGet();
    global.game_pixel_present_linear = _linear_filter;
    gpu_set_texfilter(_linear_filter);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_surface(ui_surface, 0, 0);
    gpu_set_texfilter(false);
}

// Visual QA captures run only after every regular and GUI draw event has completed.
GameVisualTourCapturePendingDrawGuiEnd();

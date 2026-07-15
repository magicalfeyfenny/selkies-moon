// Release the volatile GUI surface when the persistent bootstrap is destroyed.
if (ui_surface_targeted) {
    surface_reset_target();
    ui_surface_targeted = false;
}
if (surface_exists(ui_surface)) {
    surface_free(ui_surface);
    ui_surface = -1;
}
if (surface_exists(ui_crystal_backdrop_surface)) {
    surface_free(ui_crystal_backdrop_surface);
    ui_crystal_backdrop_surface = -1;
}

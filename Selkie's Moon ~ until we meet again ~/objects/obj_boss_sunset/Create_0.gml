// Initialize the Sunset boss from the parent defaults, then apply its encounter-specific state.
event_inherited();

points = 30000;
hit_radius = 28;
float_phase = 0;
pattern_timer = 0;
pattern_clockwise_first = true;
anchor_offset_x = 0;
anchor_offset_y = -96;

var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    anchor_offset_x = x - _camera.x;
    anchor_offset_y = y - _camera.y;
}

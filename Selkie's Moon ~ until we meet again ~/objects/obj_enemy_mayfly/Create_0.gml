// Initialize the mayfly enemy from the parent defaults, then apply its anchored spiral-burst state.
event_inherited();

hp = 24;
points = 1200;
hit_radius = 22;
move_speed = 0;
float_phase = 0;
fire_timer = 0;
clockwise_first = true;
anchor_offset_x = 0;
anchor_offset_y = -88;
anchor_target_offset_y = GameMayflyTargetAnchorOffsetYGet();

var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    anchor_offset_x = x - _camera.x;
    anchor_offset_y = y - _camera.y;
}

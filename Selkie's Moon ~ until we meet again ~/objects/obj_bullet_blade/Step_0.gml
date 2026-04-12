// Run the parent bullet step first so cancels, pause freezes, and shared cleanup stay centralized.
event_inherited();

// Hold redirected bullets in place during their freeze window, then relaunch them.
if (freeze_timer > 0) {
    freeze_timer -= 1;

    if (freeze_timer <= 0 && redirect_pending) {
        redirect_pending = false;
        redirected = true;
        move_direction = redirect_direction;
        move_speed = redirect_speed;
    }

    exit;
}

if (redirected) {
    move_speed += redirect_acceleration;
    image_angle = move_direction;

    var _redirect_camera = instance_find(obj_camera, 0);
    if (_redirect_camera != noone && (abs(x - _redirect_camera.x) > 1000 || abs(y - _redirect_camera.y) > 1000)) {
        instance_destroy();
    }

    exit;
}

// Advance the blade bullet outward from its spawn point in a spiral path.
spiral_radius += spiral_radial_speed;
spiral_angle += spiral_turn_speed * spiral_direction;
x = spiral_origin_x + lengthdir_x(spiral_radius, spiral_angle);
y = spiral_origin_y + lengthdir_y(spiral_radius, spiral_angle);
image_angle = spiral_angle;

var _camera = instance_find(obj_camera, 0);
if (_camera != noone && (abs(x - _camera.x) > 1000 || abs(y - _camera.y) > 1000)) {
    instance_destroy();
}

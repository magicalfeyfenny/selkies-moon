// Initialize the blade bullet using inherited bullet defaults plus its spiral motion state.
event_inherited();

move_speed = 0;
draw_radius = 5;
collision_radius = 4;
spiral_origin_x = x;
spiral_origin_y = y;
spiral_angle = 0;
spiral_radius = 0;
spiral_turn_speed = BLADE_TURN_SPEED;
spiral_radial_speed = BLADE_RADIAL_SPEED;
spiral_direction = 1;
freeze_timer = 0;
redirect_pending = false;
redirected = false;
redirect_speed = 0;
redirect_acceleration = 0;
redirect_direction = 0;
image_angle = spiral_angle;

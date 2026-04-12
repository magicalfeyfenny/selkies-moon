// Initialize the bee enemy from the parent defaults, then apply its pursuit and burst-fire stats.
event_inherited();

hp = 10;
points = 500;
hit_radius = 16;
move_speed = BEE_MOVE_SPEED;
fire_interval = BEE_FIRE_INTERVAL;
fire_timer = 0;
image_angle = move_direction;

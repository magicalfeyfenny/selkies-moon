// Initialize the default bullet state used by sword cancels and player collisions.
cancelled = false;
medal_score_value = CANCEL_BONUS;
medal_meter_value = CANCEL_METER;
move_direction = 270;
move_speed = 4;
draw_radius = 4;
collision_radius = 0;
combat_step_blocked = false;
rank_speed_scale = GameRankBulletSpeedScaleGet();
bullet_age = 0;
bullet_flash_phase = irandom(359);
depth = -200;

// Initialize shared boss stats, phase state, and destruction timing.
phase_max_hp = BOSS_PHASE_HP;
hp = phase_max_hp;
points = 5000;
hit_radius = 24;
phase_index = 0;
phase_count = BOSS_PHASE_COUNT;
phase_timer = 0;
destruction_active = false;
destruction_timer = 0;

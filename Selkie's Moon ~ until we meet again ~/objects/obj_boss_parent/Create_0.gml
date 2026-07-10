// Initialize shared boss stats, phase state, and destruction timing.
stage_rank = GameCurrentStageGet();
phase_max_hp = BOSS_PHASE_HP + ((stage_rank - 1) * BOSS_PHASE_HP_STAGE_STEP);
hp = phase_max_hp;
points = 5000 + (stage_rank * 2000);
hit_radius = 24;
phase_index = 0;
phase_count = BOSS_PHASE_COUNT;
phase_timer = 0;
destruction_active = false;
destruction_timer = 0;

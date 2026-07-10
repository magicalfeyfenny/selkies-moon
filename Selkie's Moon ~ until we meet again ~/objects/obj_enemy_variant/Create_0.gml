// Initialize a configurable stage enemy. Spawners overwrite the kind and stats immediately.
event_inherited();

variant_kind = ENEMY_VARIANT_MOTH;
stage_rank = GameCurrentStageGet();
slot_index = 0;
slot_count = 1;
age = 0;
fire_timer = 0;
fire_interval = 72;
wave_phase = 0;
anchor_offset_x = 0;
anchor_offset_y = 0;

GameEnemyVariantConfigure(id, variant_kind, stage_rank, slot_index, slot_count);

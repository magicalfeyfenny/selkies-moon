// Initialize the stage boss from the parent defaults, then apply its encounter-specific state.
event_inherited();

points = 30000 + (stage_rank * 5000);
hit_radius = 28;
float_phase = 0;
pattern_timer = 0;
pattern_clockwise_first = true;
anchor_offset_x = 0;
anchor_offset_y = -96;
boss_identity = GameBossEncounterInfoCreate(GameCurrentStageGet(), GameRunShipIdGet());
boss_display_name = boss_identity.display_name;
boss_ship_name = boss_identity.ship_name;
boss_draw_y_scale = boss_identity.draw_y_scale;
sprite_index = boss_identity.sprite_id;
phase_count = max(1, array_length(boss_identity.phase_plan));
phase_max_hp = GameBossPhaseHpGet(stage_rank, phase_count);
hp = phase_max_hp;

var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    anchor_offset_x = x - _camera.x;
    anchor_offset_y = y - _camera.y;
}

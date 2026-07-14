// Run shared phase transitions and destruction handling before child combat.
event_inherited();

if (combat_step_blocked) {
    exit;
}

// Keep every boss camera-relative while applying its slow figure-eight drift.
var _camera = instance_find(obj_camera, 0);
if (_camera != noone) {
    var _offset = GameMayflyInfinityOffsetCreate(float_phase);
    x = _camera.x + anchor_offset_x + (_offset.x * 0.9);
    y = _camera.y + anchor_offset_y + (_offset.y * 0.9);
}

float_phase = (float_phase + MAYFLY_FLOAT_RATE) mod 360;
phase_timer += 1;

// Encounter creation guarantees a non-empty plan. Fail closed if future data
// violates that contract instead of silently running an unrelated old pattern.
if (!is_struct(boss_identity) || !is_array(boss_identity.phase_plan)
    || array_length(boss_identity.phase_plan) <= 0) {
    exit;
}

var _plan_count = array_length(boss_identity.phase_plan);
var _plan_index = floor(clamp(phase_index, 0, _plan_count - 1));
var _phase = boss_identity.phase_plan[_plan_index];
var _player = instance_find(obj_player, 0);
var _target_x = (_player != noone) ? _player.x : x;
var _target_y = (_player != noone) ? _player.y : y + 160;
var _stage_pressure = max(0, stage_rank - 1);

if (GameBossPhaseAttackStep(id, _phase, phase_timer, _target_x, _target_y, _stage_pressure)) {
    GameEnemyFireSoundPlay();
}

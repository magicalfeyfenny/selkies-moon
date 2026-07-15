// Initialize a configurable stage familiar. The live director replaces this
// default with one of the active stage's four authored identities immediately.
event_inherited();

stage_rank = GameCurrentStageGet();
var _default_roster = GameStageEnemyRosterCreate(stage_rank);
variant_kind = _default_roster[0].id;
enemy_name = _default_roster[0].name;
variant_role = _default_roster[0].role;
pattern_kind = _default_roster[0].pattern;
draw_shape = _default_roster[0].shape;
variant_sprite = _default_roster[0].sprite;
accent_color = _default_roster[0].accent;
core_color = _default_roster[0].core;
slot_index = 0;
slot_count = 1;
age = 0;
fire_timer = 0;
fire_interval = 72;
wave_phase = 0;
anchor_offset_x = 0;
anchor_offset_y = 0;
flyaway_committed = false;

GameEnemyVariantConfigure(id, variant_kind, stage_rank, slot_index, slot_count);

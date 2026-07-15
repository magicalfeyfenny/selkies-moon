// Tell overriding child Steps whether inherited combat handling ended this frame.
combat_step_blocked = false;

// Suspend boss logic while dialogue or continue overlays are active.
if (GameGameplayIsFrozen()) {
    combat_step_blocked = true;
    exit;
}

// Resolve the final destruction countdown and signal the scene manager when the boss is gone.
if (destruction_active) {
    combat_step_blocked = true;
    destruction_timer -= 1;

    if (destruction_timer <= 0) {
        global.game_runtime.score += points;
        var _last_boss = instance_number(obj_boss_parent) <= 1;

        if (_last_boss) {
            global.game_runtime.stage_complete = true;

            var _scene = instance_find(obj_scene_manager, 0);
            if (_scene != noone) {
                _scene.scene_state.boss_defeated = true;
            }
        }

        instance_destroy();
    }

    exit;
}

// Rebuild the next phase's heart during a short invulnerable transition. The
// health ring visibly refills, then holds at full briefly before firing resumes.
if (phase_transition_timer > 0) {
    combat_step_blocked = true;
    var _transition_elapsed = phase_transition_total - phase_transition_timer + 1;
    var _refill_ratio = clamp(_transition_elapsed / BOSS_PHASE_REFILL_FRAMES, 0, 1);
    hp = phase_max_hp * _refill_ratio;
    phase_transition_timer -= 1;

    if (phase_transition_timer <= 0) {
        hp = phase_max_hp;
        phase_timer = 0;
    }

    exit;
}

// Refill the health pool for the next phase until the final destruction sequence begins.
if (hp > 0) {
    exit;
}

if (phase_index < (phase_count - 1)) {
    combat_step_blocked = true;
    phase_index += 1;
    hp = 0;
    phase_timer = 0;
    phase_transition_timer = BOSS_PHASE_TRANSITION_FRAMES;
    phase_transition_total = BOSS_PHASE_TRANSITION_FRAMES;

    if (variable_instance_exists(id, "pattern_clockwise_first")) {
        pattern_clockwise_first = true;
    }

    GameBulletsCancelAll(false);
    GameBossPhaseSoundPlay();
    exit;
}

destruction_active = true;
destruction_timer = BOSS_DESTRUCTION_FRAMES;
hit_radius = 0;
combat_step_blocked = true;
GameBulletsCancelAll(false);
GameBossPhaseSoundPlay();

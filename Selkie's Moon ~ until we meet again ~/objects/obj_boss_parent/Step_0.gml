// Suspend boss logic while dialogue or continue overlays are active.
if (GameGameplayIsFrozen()) {
    exit;
}

// Resolve the final destruction countdown and signal the scene manager when the boss is gone.
if (destruction_active) {
    destruction_timer -= 1;

    if (destruction_timer <= 0) {
        global.game_runtime.score += points;
        global.game_runtime.stage_complete = true;

        var _scene = instance_find(obj_scene_manager, 0);
        if (_scene != noone) {
            _scene.scene_state.boss_defeated = true;
        }

        instance_destroy();
    }

    exit;
}

// Refill the health pool for the next phase until the final destruction sequence begins.
if (hp > 0) {
    exit;
}

if (phase_index < (phase_count - 1)) {
    phase_index += 1;
    hp = phase_max_hp;
    phase_timer = 0;

    if (variable_instance_exists(id, "pattern_timer")) {
        pattern_timer = 0;
    }

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
GameBulletsCancelAll(false);
GameBossPhaseSoundPlay();

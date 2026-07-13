/// @func GameAudioStateEnsure()
/// Ensures the shared audio state exists before music sync logic runs.
function GameAudioStateEnsure() {
    if (!variable_global_exists("game_audio")) {
        global.game_audio = {
            stage_music_playing: false,
            current_music_id: -1,
            music_owner: "room",
            music_preview_instance_id: -1,
            music_preview_sound_id: -1,
            enemy_fire_cycle: 0,
        };
    }

    if (!struct_exists(global.game_audio, "stage_music_playing")) {
        global.game_audio.stage_music_playing = false;
    }

    if (!struct_exists(global.game_audio, "current_music_id")) {
        global.game_audio.current_music_id = global.game_audio.stage_music_playing ? snd_stage_music : -1;
    }

    if (!struct_exists(global.game_audio, "music_owner")) {
        global.game_audio.music_owner = "room";
    }

    if (!struct_exists(global.game_audio, "music_preview_instance_id")) {
        global.game_audio.music_preview_instance_id = -1;
    }

    if (!struct_exists(global.game_audio, "music_preview_sound_id")) {
        global.game_audio.music_preview_sound_id = -1;
    }

    if (!struct_exists(global.game_audio, "enemy_fire_cycle")) {
        global.game_audio.enemy_fire_cycle = 0;
    }

    return true;
}

/// @func GameMusicRoomPreviewIsActive()
/// Returns whether the music room currently owns the looping music channel.
function GameMusicRoomPreviewIsActive() {
    GameAudioStateEnsure();
    var _owns_preview = global.game_audio.music_owner == "music_room"
        && global.game_audio.music_preview_sound_id != -1;

    if (GameShouldQuitAfterTests()) {
        return _owns_preview;
    }

    return _owns_preview
        && global.game_audio.music_preview_instance_id >= 0
        && audio_is_playing(global.game_audio.music_preview_instance_id);
}

/// @func GameMusicRoomPreviewStop(restore_room_music)
/// Releases music-room ownership and optionally restores the room's normal loop.
function GameMusicRoomPreviewStop(_restore_room_music = true) {
    GameAudioStateEnsure();

    if (global.game_audio.music_preview_instance_id >= 0) {
        audio_stop_sound(global.game_audio.music_preview_instance_id);
    }

    global.game_audio.music_preview_instance_id = -1;
    global.game_audio.music_preview_sound_id = -1;
    global.game_audio.music_owner = "room";

    if (_restore_room_music) {
        GameStageMusicSync();
    }
}

/// @func GameMusicRoomPreviewStart(sound_id)
/// Gives the music room exclusive ownership of music playback and starts one loop.
function GameMusicRoomPreviewStart(_sound_id) {
    GameAudioStateEnsure();

    if (GameShouldQuitAfterTests()) {
        global.game_audio.music_owner = "music_room";
        global.game_audio.music_preview_sound_id = _sound_id;
        global.game_audio.music_preview_instance_id = -2;
        return -2;
    }

    if (global.game_audio.music_preview_instance_id >= 0) {
        audio_stop_sound(global.game_audio.music_preview_instance_id);
    }

    if (global.game_audio.current_music_id != -1) {
        audio_stop_sound(global.game_audio.current_music_id);
    }

    global.game_audio.current_music_id = -1;
    global.game_audio.stage_music_playing = false;
    global.game_audio.music_owner = "music_room";
    global.game_audio.music_preview_sound_id = _sound_id;
    global.game_audio.music_preview_instance_id = audio_play_sound(_sound_id, 0, true);
    return global.game_audio.music_preview_instance_id;
}

/// @func GameStageMusicTrackGet(stage)
/// Returns the generated music loop assigned to a stage number.
function GameStageMusicTrackGet(_stage) {
    switch (clamp(_stage, 1, STAGE_COUNT)) {
        case 1: return snd_music_stage_01;
        case 2: return snd_music_stage_02;
        case 3: return snd_music_stage_03;
        case 4: return snd_music_stage_04;
        case 5: return snd_music_stage_05;
        case 6: return snd_music_stage_06;
        case 7: return snd_music_stage_07;
        case 8: return snd_music_stage_08;
        case 9: return snd_music_stage_09;
        case 10: return snd_music_stage_10;
    }

    return snd_stage_music;
}

/// @func GameMusicForRoomGet(room_id)
/// Returns the looped music track for the current high-level room flow.
function GameMusicForRoomGet(_room_id) {
    switch (_room_id) {
        case rm_title:
        case rm_opening:
            return snd_music_title;

        case rm_game:
            return GameStageMusicTrackGet(GameCurrentStageGet());

        case rm_ending:
            return snd_music_ending;

        case rm_credits:
            return snd_music_credits;
    }

    return -1;
}

/// @func GameRunMusicShouldPlay(room_id)
/// Returns whether the stage loop should be active in the given room.
function GameRunMusicShouldPlay(_room_id) {
    return GameMusicForRoomGet(_room_id) != -1;
}

/// @func GameStageMusicSync()
/// Starts or stops the looping stage music to match the current room flow.
function GameStageMusicSync() {
    GameAudioStateEnsure();

    if (GameShouldQuitAfterTests()) {
        if (global.game_audio.music_preview_instance_id >= 0) {
            audio_stop_sound(global.game_audio.music_preview_instance_id);
        }

        if (global.game_audio.current_music_id != -1) {
            audio_stop_sound(global.game_audio.current_music_id);
        }

        global.game_audio.music_owner = "room";
        global.game_audio.music_preview_instance_id = -1;
        global.game_audio.music_preview_sound_id = -1;
        global.game_audio.current_music_id = -1;
        global.game_audio.stage_music_playing = false;
        return;
    }

    // A title-screen preview is an exclusive music route. Room sync resumes only
    // after the preview releases ownership or after leaving the title room.
    if (global.game_audio.music_owner == "music_room") {
        if (room == rm_title && GameMusicRoomPreviewIsActive()) {
            return;
        }

        GameMusicRoomPreviewStop(false);
    }

    var _music_id = GameMusicForRoomGet(room);
    var _should_play = _music_id != -1;

    if (_should_play && global.game_audio.current_music_id != _music_id) {
        if (global.game_audio.current_music_id != -1) {
            audio_stop_sound(global.game_audio.current_music_id);
        }

        audio_play_sound(_music_id, 0, true);
        global.game_audio.current_music_id = _music_id;
        global.game_audio.stage_music_playing = true;
        return;
    }

    if (!_should_play && global.game_audio.stage_music_playing) {
        if (global.game_audio.current_music_id != -1) {
            audio_stop_sound(global.game_audio.current_music_id);
        }

        global.game_audio.current_music_id = -1;
        global.game_audio.stage_music_playing = false;
    }
}

/// @func GameSoundPlay(sound_id)
/// Plays a one-shot sound effect unless the automated test runner is active.
function GameSoundPlay(_sound_id) {
    if (GameShouldQuitAfterTests()) {
        return -1;
    }

    return audio_play_sound(_sound_id, 0, false);
}

/// @func GameEnemyDestroySoundPlay()
/// Plays the shared enemy destruction sound effect.
function GameEnemyDestroySoundPlay() {
    return GameSoundPlay(snd_enemy_destroy);
}

/// @func GamePlayerHitSoundPlay()
/// Plays the player damage sound effect.
function GamePlayerHitSoundPlay() {
    return GameSoundPlay(snd_ow);
}

/// @func GameEnemyFireSoundPlay()
/// Plays the shared enemy firing sound effect.
function GameEnemyFireSoundPlay() {
    GameAudioStateEnsure();

    var _sound_id = snd_typewriter;

    switch (global.game_audio.enemy_fire_cycle mod 3) {
        case 1:
            _sound_id = snd_enemy_fire_arc;
            break;

        case 2:
            _sound_id = snd_enemy_fire_needle;
            break;
    }

    global.game_audio.enemy_fire_cycle += 1;
    return GameSoundPlay(_sound_id);
}

/// @func GamePlayerShotSoundPlay(ship_id, focused, power)
/// Plays a shot sound for one volley tick.
function GamePlayerShotSoundPlay(_ship_id, _focused, _power) {
    if (_focused || _power >= PLAYER_POWER_MAX) {
        return GameSoundPlay(snd_player_focus);
    }

    if (_ship_id == SHIP_SELKIE) {
        return GameSoundPlay(snd_player_shot_selkie);
    }

    return GameSoundPlay(snd_player_shot_moon);
}

/// @func GamePlayerSwordSoundPlay(ship_id)
/// Plays the ship-specific charged melee sound.
function GamePlayerSwordSoundPlay(_ship_id) {
    if (_ship_id == SHIP_SELKIE) {
        return GameSoundPlay(snd_sword_selkie);
    }

    return GameSoundPlay(snd_sword_moon);
}

/// @func GamePowerupCollectSoundPlay()
/// Plays the power-up collection sound.
function GamePowerupCollectSoundPlay() {
    return GameSoundPlay(snd_powerup_collect);
}

/// @func GamePlayerBombSoundPlay()
/// Plays the bomb bloom sound.
function GamePlayerBombSoundPlay() {
    return GameSoundPlay(snd_bomb);
}

/// @func GameStageClearSoundPlay()
/// Plays the stage clear flourish.
function GameStageClearSoundPlay() {
    return GameSoundPlay(snd_stage_clear);
}

/// @func GameBossSpawnSoundPlay()
/// Plays the boss entrance sound.
function GameBossSpawnSoundPlay() {
    return GameSoundPlay(snd_boss_spawn);
}

/// @func GameBossPhaseSoundPlay()
/// Plays the boss phase transition sound.
function GameBossPhaseSoundPlay() {
    return GameSoundPlay(snd_boss_phase);
}

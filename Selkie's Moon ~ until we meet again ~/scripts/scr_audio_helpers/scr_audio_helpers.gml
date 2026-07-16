// Music ownership, room routing, and semantic sound-effect entry points.

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

    // Keep compatibility with audio state created by an older persistent bootstrap.
    GameStructFieldEnsure(global.game_audio, "stage_music_playing", false);
    GameStructFieldEnsure(global.game_audio, "current_music_id", -1);
    GameStructFieldEnsure(global.game_audio, "music_owner", "room");
    GameStructFieldEnsure(global.game_audio, "music_preview_instance_id", -1);
    GameStructFieldEnsure(global.game_audio, "music_preview_sound_id", -1);
    GameStructFieldEnsure(global.game_audio, "enemy_fire_cycle", 0);

    return true;
}

/// @func GameAudioMusicAssetsCreate()
/// Returns every score asset so one persisted music gain controls room loops and previews.
function GameAudioMusicAssetsCreate() {
    return [
        snd_music_title,
        snd_music_stage_shalmii, snd_music_boss_shalmii,
        snd_music_stage_aster, snd_music_boss_aster,
        snd_music_stage_mira_aisha, snd_music_boss_mira_aisha,
        snd_music_stage_caelia, snd_music_boss_caelia,
        snd_music_stage_moon, snd_music_boss_moon,
        snd_music_stage_selkie, snd_music_boss_selkie,
        snd_music_ending, snd_music_credits,
    ];
}

/// @func GameAudioSfxAssetsCreate()
/// Returns every semantic one-shot asset governed by the SFX gain.
function GameAudioSfxAssetsCreate() {
    return [
        snd_bomb, snd_boss_phase, snd_boss_spawn,
        snd_enemy_destroy, snd_enemy_fire_arc, snd_enemy_fire_needle,
        snd_ow, snd_player_focus, snd_player_shot_moon,
        snd_player_shot_selkie, snd_powerup_collect, snd_stage_clear,
        snd_sword_moon, snd_sword_selkie, snd_typewriter,
    ];
}

/// @func GameAudioSfxMixGainGet(sound_id)
/// Returns the production mix trim for one SFX before the user's category gain.
/// Rapid-fire sounds deliberately sit well below cinematic one-shots so repeated
/// volleys read as texture instead of flattening the rest of the mix.
function GameAudioSfxMixGainGet(_sound_id) {
    switch (_sound_id) {
        case snd_player_shot_moon: return 0.22;
        case snd_player_shot_selkie: return 0.22;
        case snd_player_focus: return 0.28;
        case snd_enemy_fire_arc: return 0.26;
        case snd_enemy_fire_needle: return 0.22;
        case snd_typewriter: return 0.18;
        case snd_enemy_destroy: return 0.48;
        case snd_ow: return 0.62;
        case snd_powerup_collect: return 0.46;
        case snd_sword_moon: return 0.64;
        case snd_sword_selkie: return 0.64;
        case snd_boss_phase: return 0.72;
        case snd_boss_spawn: return 0.74;
        case snd_bomb: return 0.78;
        case snd_stage_clear: return 0.72;
    }

    return 0.5;
}

/// @func GameAudioVolumesApply()
/// Applies master, score, and one-shot gains immediately to assets and live instances.
function GameAudioVolumesApply() {
    if (!variable_global_exists("game_config")) {
        return false;
    }

    var _master_gain = clamp(global.game_config.master_volume / 100, 0, 1);
    var _music_gain = clamp(global.game_config.music_volume / 100, 0, 1);
    var _sfx_gain = clamp(global.game_config.sfx_volume / 100, 0, 1);

    audio_master_gain(_master_gain);

    var _music_assets = GameAudioMusicAssetsCreate();
    for (var music = 0; music < array_length(_music_assets); music++) {
        audio_sound_gain(_music_assets[music], _music_gain, 0);
    }

    var _sfx_assets = GameAudioSfxAssetsCreate();
    for (var effect = 0; effect < array_length(_sfx_assets); effect++) {
        var _sound_id = _sfx_assets[effect];
        audio_sound_gain(_sound_id, _sfx_gain * GameAudioSfxMixGainGet(_sound_id), 0);
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

/// @func GameStageMusicTrackGet(stage, ship_id)
/// Returns the character-stage cue, including the route-specific final stage.
function GameStageMusicTrackGet(_stage, _ship_id = undefined) {
    if (_ship_id == undefined) {
        _ship_id = GameRunShipIdGet();
    }

    switch (clamp(_stage, 1, STAGE_COUNT)) {
        case 1: return snd_music_stage_shalmii;
        case 2: return snd_music_stage_aster;
        case 3: return snd_music_stage_mira_aisha;
        case 4: return snd_music_stage_caelia;
        case 5:
            return (_ship_id == SHIP_SELKIE)
                ? snd_music_stage_selkie
                : snd_music_stage_moon;
    }

    return snd_music_stage_shalmii;
}

/// @func GameBossMusicTrackGet(stage, player_ship_id)
/// Returns the guardian cue; the final cue belongs to the opposing heroine.
function GameBossMusicTrackGet(_stage, _player_ship_id = undefined) {
    if (_player_ship_id == undefined) {
        _player_ship_id = GameRunShipIdGet();
    }

    switch (clamp(_stage, 1, STAGE_COUNT)) {
        case 1: return snd_music_boss_shalmii;
        case 2: return snd_music_boss_aster;
        case 3: return snd_music_boss_mira_aisha;
        case 4: return snd_music_boss_caelia;
        case 5:
            return (GameFinalBossOpponentShipIdGet(_player_ship_id) == SHIP_SUNRISE)
                ? snd_music_boss_moon
                : snd_music_boss_selkie;
    }

    return snd_music_boss_shalmii;
}

/// @func GameGameplayMusicTrackGet(stage, mode, boss_spawned, ship_id)
/// Selects stage or guardian music without depending on room instance state.
function GameGameplayMusicTrackGet(_stage, _mode = "scroll", _boss_spawned = false,
                                   _ship_id = undefined) {
    var _boss_mode = (_mode == "boss_intro")
        || (_mode == "boss_fight")
        || (_mode == "boss_outro")
        || (_mode == "stage_clear" && _boss_spawned);

    if (_boss_mode) {
        return GameBossMusicTrackGet(_stage, _ship_id);
    }

    return GameStageMusicTrackGet(_stage, _ship_id);
}

/// @func GameMusicForRoomGet(room_id)
/// Returns the looped music track for the current high-level room flow.
function GameMusicForRoomGet(_room_id) {
    switch (_room_id) {
        case rm_title:
        case rm_opening:
            return snd_music_title;

        case rm_game:
            var _mode = "scroll";
            var _boss_spawned = false;
            var _scene = instance_find(obj_scene_manager, 0);
            if (_scene != noone) {
                _mode = _scene.scene_state.mode;
                _boss_spawned = _scene.scene_state.boss_spawned;
            }
            return GameGameplayMusicTrackGet(
                GameCurrentStageGet(), _mode, _boss_spawned, GameRunShipIdGet());

        case rm_ending:
            return snd_music_ending;

        case rm_credits:
            return snd_music_credits;
    }

    return -1;
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

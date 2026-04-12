/// @func GameAudioStateEnsure()
/// Ensures the shared audio state exists before music sync logic runs.
function GameAudioStateEnsure() {
    if (!variable_global_exists("game_audio")) {
        global.game_audio = {
            stage_music_playing: false,
        };
    }

    if (!struct_exists(global.game_audio, "stage_music_playing")) {
        global.game_audio.stage_music_playing = false;
    }

    return true;
}

/// @func GameRunMusicShouldPlay(room_id)
/// Returns whether the stage loop should be active in the given room.
function GameRunMusicShouldPlay(_room_id) {
    switch (_room_id) {
        case rm_opening:
        case rm_game:
        case rm_ending:
            return true;
    }

    return false;
}

/// @func GameStageMusicSync()
/// Starts or stops the looping stage music to match the current room flow.
function GameStageMusicSync() {
    GameAudioStateEnsure();

    var _should_play = GameRunMusicShouldPlay(room);

    if (_should_play && !global.game_audio.stage_music_playing) {
        audio_play_sound(snd_stage_music, 0, true);
        global.game_audio.stage_music_playing = true;
        return;
    }

    if (!_should_play && global.game_audio.stage_music_playing) {
        audio_stop_sound(snd_stage_music);
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
    return GameSoundPlay(snd_typewriter);
}

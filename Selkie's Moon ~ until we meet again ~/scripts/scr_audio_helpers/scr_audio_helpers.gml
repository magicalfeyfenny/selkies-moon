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

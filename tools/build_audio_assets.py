#!/usr/bin/env python3
"""Build short in-engine score placeholders and the complete SFX suite.

Production music is authored by ``build_logic_score_midi.py`` and finished in
Logic Pro. These intentionally compact loops keep every runtime route audible
before its lossless production master exists. They use the same four-measure
Horizon Theme and the same character-specific secondary leitmotifs.
"""

from __future__ import annotations

import math
import wave
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from build_logic_score_midi import HORIZON_THEME, SECONDARY_MOTIFS


ROOT = Path(__file__).resolve().parents[1]
SOUNDS = ROOT / "Selkie's Moon ~ until we meet again ~" / "sounds"
RATE = 44_100
TAU = math.tau


def midi(note: float) -> float:
    return 440.0 * (2.0 ** ((note - 69.0) / 12.0))


def timebase(duration: float) -> np.ndarray:
    return np.arange(max(1, round(duration * RATE)), dtype=np.float64) / RATE


def envelope(count: int, attack: float, release: float, decay: float = 0.0,
             sustain: float = 1.0) -> np.ndarray:
    env = np.ones(count, dtype=np.float64) * sustain
    attack_n = min(count, max(1, round(attack * RATE)))
    env[:attack_n] = np.linspace(0.0, 1.0, attack_n, endpoint=False)

    if decay > 0 and attack_n < count:
        decay_n = min(count - attack_n, max(1, round(decay * RATE)))
        env[attack_n:attack_n + decay_n] = np.linspace(1.0, sustain, decay_n, endpoint=False)

    release_n = min(count, max(1, round(release * RATE)))
    env[-release_n:] *= np.linspace(1.0, 0.0, release_n)
    return env


def oscillator(freq: float, duration: float, kind: str = "sine", phase: float = 0.0,
               vibrato: float = 0.0) -> np.ndarray:
    t = timebase(duration)
    angle = TAU * freq * t + phase
    if vibrato:
        angle += vibrato * np.sin(TAU * 5.1 * t)
    sine = np.sin(angle)
    if kind == "triangle":
        return (2.0 / math.pi) * np.arcsin(sine)
    if kind == "soft_square":
        return np.tanh(2.2 * sine) / np.tanh(2.2)
    if kind == "saw":
        return (2.0 / math.pi) * np.arctan(np.tan((angle - math.pi) / 2.0))
    return sine


def note_tone(note: float, duration: float, voice: str, amp: float = 1.0) -> np.ndarray:
    freq = midi(note)
    count = max(1, round(duration * RATE))
    t = np.arange(count, dtype=np.float64) / RATE

    if voice == "music_box":
        tone = (
            np.sin(TAU * freq * t)
            + 0.44 * np.sin(TAU * freq * 2.01 * t)
            + 0.20 * np.sin(TAU * freq * 3.98 * t)
        ) * np.exp(-3.4 * t / max(duration, 0.01))
        env = envelope(count, 0.004, min(0.12, duration * 0.35), 0.03, 0.72)
    elif voice == "bell":
        tone = (
            np.sin(TAU * freq * t)
            + 0.48 * np.sin(TAU * freq * 2.72 * t)
            + 0.28 * np.sin(TAU * freq * 4.08 * t)
            + 0.12 * np.sin(TAU * freq * 5.43 * t)
        ) * np.exp(-4.6 * t / max(duration, 0.01))
        env = envelope(count, 0.002, min(0.16, duration * 0.4))
    elif voice == "harpsichord":
        tone = 0.62 * oscillator(freq, duration, "triangle") + 0.26 * oscillator(
            freq * 2.0, duration, "saw", 0.3)
        tone *= np.exp(-2.8 * t / max(duration, 0.01))
        env = envelope(count, 0.003, min(0.08, duration * 0.25))
    elif voice == "organ":
        tremolo = 0.93 + 0.07 * np.sin(TAU * 4.3 * t)
        tone = tremolo * (
            0.70 * np.sin(TAU * freq * t)
            + 0.23 * np.sin(TAU * freq * 2.0 * t)
            + 0.12 * np.sin(TAU * freq * 3.0 * t)
        )
        env = envelope(count, min(0.12, duration * 0.22), min(0.16, duration * 0.25))
    elif voice == "strings":
        tone = (
            0.48 * oscillator(freq * 0.997, duration, "triangle")
            + 0.42 * oscillator(freq * 1.003, duration, "triangle", 0.7)
            + 0.13 * np.sin(TAU * freq * 2.0 * t)
        )
        env = envelope(count, min(0.10, duration * 0.25), min(0.14, duration * 0.3))
    elif voice == "choir":
        tone = (
            0.62 * np.sin(TAU * freq * t + 0.08 * np.sin(TAU * 4.0 * t))
            + 0.26 * np.sin(TAU * freq * 2.0 * t)
            + 0.12 * np.sin(TAU * freq * 3.01 * t)
        )
        env = envelope(count, min(0.18, duration * 0.3), min(0.20, duration * 0.3))
    elif voice == "bass":
        tone = 0.78 * np.sin(TAU * freq * t) + 0.22 * oscillator(freq, duration, "triangle")
        env = envelope(count, 0.008, min(0.10, duration * 0.3))
    else:
        tone = np.sin(TAU * freq * t)
        env = envelope(count, 0.004, min(0.08, duration * 0.3))

    return tone[:count] * env * amp


def add(buffer: np.ndarray, start: float, signal: np.ndarray) -> None:
    first = max(0, round(start * RATE))
    if first >= len(buffer):
        return
    count = min(len(signal), len(buffer) - first)
    if count > 0:
        buffer[first:first + count] += signal[:count]


def noise_burst(duration: float, seed: int, brightness: int = 5) -> np.ndarray:
    rng = np.random.default_rng(seed)
    noise = rng.normal(0.0, 1.0, max(1, round(duration * RATE)))
    # Repeated first differences create glass/metal brightness without filters.
    for _ in range(max(0, brightness)):
        noise = np.concatenate(([0.0], np.diff(noise)))
    peak = max(1e-9, float(np.max(np.abs(noise))))
    return noise / peak


def chirp(start_hz: float, end_hz: float, duration: float, amp: float = 1.0,
          wobble: float = 0.0) -> np.ndarray:
    t = timebase(duration)
    ratio = max(1e-6, end_hz / start_hz)
    phase = TAU * start_hz * duration * (np.power(ratio, t / duration) - 1.0) / math.log(ratio) \
        if abs(ratio - 1.0) > 1e-8 else TAU * start_hz * t
    if wobble:
        phase += wobble * np.sin(TAU * 11.0 * t)
    return np.sin(phase) * envelope(len(t), 0.002, min(0.10, duration * 0.4)) * amp


def normalize(signal: np.ndarray, peak: float) -> np.ndarray:
    signal = np.nan_to_num(signal)
    signal -= float(np.mean(signal))
    maximum = float(np.max(np.abs(signal)))
    if maximum > 1e-9:
        signal *= peak / maximum
    # Gentle saturation catches dense chord coincidences more musically.
    return np.tanh(signal * 1.12) / np.tanh(1.12)


def write_wav(relative: str, signal: np.ndarray, peak: float = 0.78) -> None:
    path = SOUNDS / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.int16(np.clip(normalize(signal, peak), -1.0, 1.0) * 32767)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


@dataclass(frozen=True)
class Movement:
    style: str
    root: int
    melody: str
    pad: str
    seed: int
    intensity: float = 1.0
    major_resolution: bool = False
    secondary_theme: str = ""
    voice_order: str = "primary"


def percussion(buffer: np.ndarray, when: float, beat: float, style: str, seed: int,
               amount: float) -> None:
    if style == "forge":
        hit = note_tone(86, min(0.12, beat * 0.42), "bell", 0.10 * amount)
        hit += noise_burst(len(hit) / RATE, seed, 2) * np.exp(-np.arange(len(hit)) / (RATE * 0.035)) * 0.05
    elif style in ("wishcourt", "aster"):
        hit = note_tone(91, min(0.08, beat * 0.3), "music_box", 0.07 * amount)
    elif style == "cosmic":
        hit = note_tone(74, min(0.18, beat * 0.5), "bell", 0.055 * amount)
    elif style == "garden":
        hit = note_tone(98, min(0.10, beat * 0.35), "bell", 0.045 * amount)
    else:
        hit = note_tone(84, min(0.09, beat * 0.35), "music_box", 0.05 * amount)
    add(buffer, when, hit)


def placeholder_motif_add(buffer: np.ndarray, start: float, beat: float, root: int,
                          motif: tuple[tuple[float, float, int], ...], voice: str,
                          amount: float, major_resolution: bool = False,
                          octave: int = 12) -> None:
    for motif_beat, motif_duration, degree in motif:
        if major_resolution and degree == 3:
            degree = 4
        add(
            buffer,
            start + motif_beat * beat,
            note_tone(
                root + octave + degree,
                motif_duration * beat * 0.88,
                voice,
                amount,
            ),
        )


def placeholder_secondary_plan(movement: Movement) -> tuple[tuple[str, str], ...]:
    if movement.secondary_theme == "horizon_dialogue":
        if movement.voice_order == "selkie_first":
            return (("selkie_answer", "bell"), ("moon_call", "music_box"))
        return (("moon_call", "music_box"), ("selkie_answer", "bell"))
    if movement.secondary_theme == "mira_aisha_medley":
        if movement.voice_order == "aisha_first":
            return (("aisha", "music_box"), ("mira", "strings"))
        return (("mira", "strings"), ("aisha", "music_box"))
    voices = {
        "shalmii": "bell",
        "aster": "strings",
        "caelia": "choir",
    }
    if movement.secondary_theme in voices:
        voice = voices[movement.secondary_theme]
        return ((movement.secondary_theme, voice), (movement.secondary_theme, voice))
    return ()


def build_movement(duration: float, movement: Movement) -> np.ndarray:
    # Eight compact bars provide four bars for the Horizon Theme and four for
    # both halves of every secondary call-and-answer plan.
    bars = 8
    beat = duration / (bars * 4.0)
    buffer = np.zeros(max(1, round(duration * RATE)), dtype=np.float64)
    progressions = (0, -2, -5, -7, -5, -2, 0, -7)

    for bar in range(bars):
        bar_start = bar * beat * 4.0
        degree = progressions[bar % len(progressions)]
        third = 4 if movement.major_resolution and bar >= bars - 2 else 3
        chord = (movement.root + degree, movement.root + degree + third,
                 movement.root + degree + 7)

        for chord_note in chord:
            add(buffer, bar_start, note_tone(
                chord_note, beat * 3.96, movement.pad,
                0.050 * movement.intensity))

        for pulse in range(4):
            pulse_time = bar_start + pulse * beat
            bass_note = movement.root - 12 + degree + (7 if pulse == 2 else 0)
            add(buffer, pulse_time, note_tone(
                bass_note, beat * 0.82, "bass", 0.105 * movement.intensity))
            percussion(buffer, pulse_time, beat, movement.style,
                       movement.seed + bar * 11 + pulse, movement.intensity)

        # Eight-note clockwork ostinato, displaced by style but always harmonic.
        arp_order = (0, 1, 2, 1, 0, 2, 1, 2)
        for step, chord_index in enumerate(arp_order):
            arp_note = chord[chord_index] + 12
            if movement.style == "cosmic" and step % 2:
                arp_note += 12
            add(buffer, bar_start + step * beat * 0.5,
                note_tone(arp_note, beat * 0.42,
                          "harpsichord" if movement.style != "garden" else "music_box",
                          0.040 * movement.intensity))

    # Bars 1-4 establish the score-wide identity; bars 5-8 foreground the
    # character identity or antiphonal dialogue. The production arrangements
    # develop and recombine both ideas across their longer forms.
    placeholder_motif_add(
        buffer, 0.0, beat, movement.root, HORIZON_THEME, movement.melody,
        0.145 * movement.intensity, movement.major_resolution,
    )
    for index, (motif_id, voice) in enumerate(placeholder_secondary_plan(movement)):
        placeholder_motif_add(
            buffer, (4 + index * 2) * beat * 4.0, beat, movement.root,
            SECONDARY_MOTIFS[motif_id], voice,
            (0.145 if index == 0 else 0.125) * movement.intensity,
            movement.major_resolution,
        )

    # Join the loop at matching phase while retaining attacks at the downbeat.
    crossfade = min(round(0.06 * RATE), len(buffer) // 4)
    if crossfade > 1:
        blend = np.linspace(0.0, 1.0, crossfade)
        buffer[-crossfade:] = buffer[-crossfade:] * (1.0 - blend) + buffer[:crossfade] * blend
    return buffer


def build_music() -> None:
    tracks = {
        "snd_music_title/title_theme.wav": (14.4, Movement("title", 50, "music_box", "organ", 101, 0.84, False, "horizon_dialogue", "moon_first")),
        "snd_music_stage_01/stage_01_tideglass.wav": (12.0, Movement("forge", 50, "bell", "organ", 111, 1.04)),
        "snd_music_stage_02/stage_02_lanterns.wav": (12.0, Movement("forge", 50, "harpsichord", "strings", 112, 1.12)),
        "snd_music_stage_03/stage_03_saltwind.wav": (12.0, Movement("aster", 55, "music_box", "strings", 121, 0.96)),
        "snd_music_stage_04/stage_04_kelp_chase.wav": (12.0, Movement("aster", 55, "harpsichord", "organ", 122, 1.10)),
        "snd_music_stage_05/stage_05_moonwake.wav": (12.0, Movement("wishcourt", 48, "bell", "strings", 131, 1.00)),
        "snd_music_stage_06/stage_06_glassreef.wav": (12.0, Movement("wishcourt", 48, "harpsichord", "organ", 132, 1.12)),
        "snd_music_stage_07/stage_07_starfall.wav": (12.0, Movement("cosmic", 45, "bell", "choir", 141, 0.98)),
        "snd_music_stage_08/stage_08_bloodtide.wav": (12.0, Movement("cosmic", 45, "harpsichord", "organ", 142, 1.08)),
        "snd_music_stage_09/stage_09_crescent_gate.wav": (12.0, Movement("cosmic", 45, "bell", "organ", 143, 1.16)),
        "snd_music_stage_10/stage_10_selkie_eclipse.wav": (12.0, Movement("garden", 50, "music_box", "choir", 151, 1.18)),
        "snd_stage_music/stage_music.wav": (12.0, Movement("garden", 50, "bell", "strings", 152, 1.02)),
        "snd_music_stage_shalmii/stage_shalmii.wav": (12.0, Movement("forge", 50, "bell", "organ", 211, 1.04, False, "shalmii")),
        "snd_music_boss_shalmii/boss_shalmii.wav": (12.0, Movement("forge", 50, "bell", "organ", 212, 1.16, False, "shalmii")),
        "snd_music_stage_aster/stage_aster.wav": (12.0, Movement("aster", 55, "music_box", "strings", 221, 0.98, False, "aster")),
        "snd_music_boss_aster/boss_aster.wav": (12.0, Movement("aster", 55, "harpsichord", "strings", 222, 1.12, False, "aster")),
        "snd_music_stage_mira_aisha/stage_mira_aisha.wav": (12.0, Movement("wishcourt", 48, "bell", "strings", 231, 1.00, False, "mira_aisha_medley", "mira_first")),
        "snd_music_boss_mira_aisha/boss_mira_aisha.wav": (12.0, Movement("wishcourt", 48, "harpsichord", "organ", 232, 1.14, False, "mira_aisha_medley", "aisha_first")),
        "snd_music_stage_caelia/stage_caelia.wav": (12.0, Movement("cosmic", 45, "bell", "choir", 241, 1.02, False, "caelia")),
        "snd_music_boss_caelia/boss_caelia.wav": (12.0, Movement("cosmic", 45, "harpsichord", "organ", 242, 1.16, False, "caelia")),
        "snd_music_stage_moon/stage_moon.wav": (12.0, Movement("garden", 50, "music_box", "choir", 251, 1.08, False, "horizon_dialogue", "moon_first")),
        "snd_music_boss_moon/boss_moon.wav": (12.0, Movement("garden", 50, "music_box", "organ", 252, 1.20, False, "horizon_dialogue", "moon_first")),
        "snd_music_stage_selkie/stage_selkie.wav": (12.0, Movement("garden", 50, "bell", "choir", 253, 1.08, False, "horizon_dialogue", "selkie_first")),
        "snd_music_boss_selkie/boss_selkie.wav": (12.0, Movement("garden", 50, "bell", "organ", 254, 1.20, False, "horizon_dialogue", "selkie_first")),
        "snd_music_ending/ending_soft_bloom.wav": (14.4, Movement("garden", 50, "music_box", "choir", 161, 0.78, True, "horizon_dialogue", "selkie_first")),
        "snd_music_credits/credits_moonlit_return.wav": (16.0, Movement("title", 50, "bell", "organ", 171, 0.94, True, "horizon_dialogue", "moon_first")),
    }
    for path, (duration, movement) in tracks.items():
        write_wav(path, build_movement(duration, movement), 0.72)


def blank(duration: float) -> np.ndarray:
    return np.zeros(max(1, round(duration * RATE)), dtype=np.float64)


def add_noise(buffer: np.ndarray, start: float, duration: float, seed: int,
              amp: float, decay: float, brightness: int = 4) -> None:
    signal = noise_burst(duration, seed, brightness)
    signal *= np.exp(-np.arange(len(signal)) / max(1.0, RATE * decay)) * amp
    add(buffer, start, signal)


def build_sfx() -> None:
    effects: dict[str, tuple[float, np.ndarray]] = {}

    duration = 0.780000
    sound = blank(duration)
    add(sound, 0.00, chirp(midi(38), midi(26), duration, 0.42, 0.08))
    for i, note in enumerate((62, 65, 69, 72)):
        add(sound, 0.10 + i * 0.045, note_tone(note, duration - 0.10 - i * 0.045, "bell", 0.24))
    add_noise(sound, 0.02, 0.62, 201, 0.18, 0.24, 2)
    effects["snd_bomb/bomb_bloom.wav"] = (duration, sound)

    duration = 0.620000
    sound = blank(duration)
    for i, note in enumerate((50, 53, 57, 60)):
        add(sound, i * 0.07, note_tone(note, duration - i * 0.07, "bell", 0.25))
    add_noise(sound, 0.0, 0.18, 202, 0.12, 0.04, 3)
    effects["snd_boss_phase/boss_phase.wav"] = (duration, sound)

    duration = 0.920000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(26), midi(38), 0.82, 0.35, 0.12))
    for i, note in enumerate((38, 41, 45)):
        add(sound, 0.16 + i * 0.16, note_tone(note, 0.52, "organ", 0.30))
    add_noise(sound, 0.06, 0.62, 203, 0.13, 0.28, 1)
    effects["snd_boss_spawn/boss_spawn.wav"] = (duration, sound)

    duration = 0.267029
    sound = blank(duration)
    for i, note in enumerate((81, 77, 74)):
        add(sound, i * 0.027, note_tone(note, duration - i * 0.027, "bell", 0.24))
    add_noise(sound, 0.0, duration, 204, 0.30, 0.07, 4)
    effects["snd_enemy_destroy/snd_enemy_destroy.wav"] = (duration, sound)

    duration = 0.160000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(74), midi(77), duration, 0.62, 0.16))
    add(sound, 0.018, note_tone(81, duration - 0.018, "music_box", 0.18))
    effects["snd_enemy_fire_arc/enemy_fire_arc.wav"] = (duration, sound)

    duration = 0.120000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(81), midi(86), duration, 0.65))
    add_noise(sound, 0.0, duration, 205, 0.17, 0.025, 5)
    effects["snd_enemy_fire_needle/enemy_fire_needle.wav"] = (duration, sound)

    duration = 0.615329
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(50), midi(38), 0.48, 0.55, 0.08))
    add_noise(sound, 0.0, 0.28, 206, 0.31, 0.08, 3)
    add(sound, 0.10, note_tone(41, 0.42, "organ", 0.20))
    effects["snd_ow/snd_ow.wav"] = (duration, sound)

    duration = 0.260000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(62), midi(69), duration, 0.52, 0.07))
    add(sound, 0.05, note_tone(74, 0.19, "bell", 0.28))
    effects["snd_player_focus/player_focus.wav"] = (duration, sound)

    duration = 0.180000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(74), midi(77), duration, 0.58, 0.05))
    add(sound, 0.02, note_tone(81, 0.13, "music_box", 0.20))
    effects["snd_player_shot_moon/player_shot_moon.wav"] = (duration, sound)

    duration = 0.200000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(69), midi(74), duration, 0.56, 0.12))
    add(sound, 0.03, note_tone(81, 0.15, "bell", 0.18))
    effects["snd_player_shot_selkie/player_shot_selkie.wav"] = (duration, sound)

    duration = 0.420000
    sound = blank(duration)
    for i, note in enumerate((62, 65, 69, 74)):
        add(sound, i * 0.055, note_tone(note, duration - i * 0.055, "music_box", 0.28))
    effects["snd_powerup_collect/powerup_collect.wav"] = (duration, sound)

    duration = 1.050000
    sound = blank(duration)
    for i, note in enumerate((62, 65, 69, 72, 69, 74)):
        add(sound, i * 0.105, note_tone(note, duration - i * 0.105, "bell", 0.27))
    add(sound, 0.56, note_tone(62, 0.47, "organ", 0.22))
    effects["snd_stage_clear/stage_clear.wav"] = (duration, sound)

    duration = 0.580000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(50), midi(81), 0.48, 0.52, 0.22))
    for i, note in enumerate((62, 65, 69)):
        add(sound, 0.09 + i * 0.045, note_tone(note, duration - 0.09 - i * 0.045, "bell", 0.19))
    add_noise(sound, 0.12, 0.32, 207, 0.18, 0.08, 5)
    effects["snd_sword_moon/sword_moon_rose_whip.wav"] = (duration, sound)

    duration = 0.520000
    sound = blank(duration)
    add(sound, 0.0, chirp(midi(69), midi(86), 0.24, 0.45, 0.55))
    add(sound, 0.20, chirp(midi(86), midi(69), 0.30, 0.40, 0.65))
    add(sound, 0.05, note_tone(74, 0.43, "bell", 0.25))
    effects["snd_sword_selkie/sword_selkie_chakram.wav"] = (duration, sound)

    duration = 0.278639
    sound = blank(duration)
    add(sound, 0.0, note_tone(86, 0.105, "bell", 0.44))
    add(sound, 0.035, note_tone(89, 0.13, "music_box", 0.22))
    add_noise(sound, 0.0, 0.12, 208, 0.20, 0.025, 4)
    effects["snd_typewriter/snd_typewriter.wav"] = (duration, sound)

    for path, (_, signal) in effects.items():
        write_wav(path, signal, 0.76)


def main() -> None:
    build_music()
    build_sfx()
    print("Built 26 short leitmotif score placeholders and 15 neo-Gothic sound effects.")


if __name__ == "__main__":
    main()

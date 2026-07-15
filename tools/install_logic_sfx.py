#!/usr/bin/env python3
"""Slice, gain-stage, and install the 24-bit/48 kHz Logic SFX suite bounce."""

from __future__ import annotations

import json
import math
import re
import shutil
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"
PRODUCTION = ROOT / "art" / "audio_production"
SUITE = PRODUCTION / "sfx_raw_bounces" / "Selkies Moon SFX Production.wav"
MANIFEST = PRODUCTION / "sfx_cue_sheets" / "sfx_suite_manifest.json"
MASTERS = PRODUCTION / "sfx_masters"
BACKUP = PRODUCTION / "superseded" / "sfx_placeholder_wavs"

RUNTIME = {
    "bomb": ("snd_bomb", "bomb_bloom.wav"),
    "boss_phase": ("snd_boss_phase", "boss_phase.wav"),
    "boss_spawn": ("snd_boss_spawn", "boss_spawn.wav"),
    "enemy_destroy": ("snd_enemy_destroy", "snd_enemy_destroy.wav"),
    "enemy_fire_arc": ("snd_enemy_fire_arc", "enemy_fire_arc.wav"),
    "enemy_fire_needle": ("snd_enemy_fire_needle", "enemy_fire_needle.wav"),
    "ow": ("snd_ow", "snd_ow.wav"),
    "player_focus": ("snd_player_focus", "player_focus.wav"),
    "player_shot_moon": ("snd_player_shot_moon", "player_shot_moon.wav"),
    "player_shot_selkie": ("snd_player_shot_selkie", "player_shot_selkie.wav"),
    "powerup_collect": ("snd_powerup_collect", "powerup_collect.wav"),
    "stage_clear": ("snd_stage_clear", "stage_clear.wav"),
    "sword_moon": ("snd_sword_moon", "sword_moon_rose_whip.wav"),
    "sword_selkie": ("snd_sword_selkie", "sword_selkie_chakram.wav"),
    "typewriter": ("snd_typewriter", "snd_typewriter.wav"),
}

TARGET_PEAK_DB = {
    "bomb": -1.5,
    "boss_phase": -3.0,
    "boss_spawn": -2.5,
    "enemy_destroy": -6.0,
    "enemy_fire_arc": -11.0,
    "enemy_fire_needle": -13.0,
    "ow": -5.0,
    "player_focus": -10.0,
    "player_shot_moon": -14.0,
    "player_shot_selkie": -14.0,
    "powerup_collect": -7.0,
    "stage_clear": -3.5,
    "sword_moon": -4.0,
    "sword_selkie": -4.0,
    "typewriter": -18.0,
}


def read_pcm24(path: Path) -> tuple[int, np.ndarray]:
    with wave.open(str(path), "rb") as source:
        if source.getsampwidth() != 3 or source.getnchannels() != 2:
            raise RuntimeError("Expected Logic's stereo 24-bit suite bounce")
        rate = source.getframerate()
        raw = source.readframes(source.getnframes())
    triplets = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3).astype(np.int32)
    values = triplets[:, 0] | (triplets[:, 1] << 8) | (triplets[:, 2] << 16)
    values = np.where(values & 0x800000, values - 0x1000000, values)
    return rate, values.reshape(-1, 2).astype(np.float64) / 8388608.0


def write_pcm24(path: Path, rate: int, audio: np.ndarray) -> None:
    values = np.clip(np.round(audio * 8388607.0), -8388608, 8388607).astype(np.int32).reshape(-1)
    unsigned = values & 0xFFFFFF
    packed = np.empty((values.size, 3), dtype=np.uint8)
    packed[:, 0] = unsigned & 0xFF
    packed[:, 1] = (unsigned >> 8) & 0xFF
    packed[:, 2] = (unsigned >> 16) & 0xFF
    with wave.open(str(path), "wb") as target:
        target.setnchannels(2)
        target.setsampwidth(3)
        target.setframerate(rate)
        target.writeframes(packed.tobytes())


def write_pcm16(path: Path, rate: int, audio: np.ndarray) -> None:
    values = np.clip(np.round(audio * 32767.0), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as target:
        target.setnchannels(2)
        target.setsampwidth(2)
        target.setframerate(rate)
        target.writeframes(values.tobytes())


def fade_and_gain(audio: np.ndarray, rate: int, target_peak_db: float) -> np.ndarray:
    result = audio.copy()
    fade_in = min(len(result), max(1, round(rate * 0.005)))
    fade_out = min(len(result), max(1, round(rate * 0.04)))
    result[:fade_in] *= np.linspace(0.0, 1.0, fade_in)[:, None]
    result[-fade_out:] *= np.linspace(1.0, 0.0, fade_out)[:, None]
    peak = float(np.max(np.abs(result)))
    if peak > 0:
        target = 10.0 ** (target_peak_db / 20.0)
        result *= target / peak
    return np.clip(result, -1.0, 1.0)


def update_sound_metadata(resource: str, filename: str, duration: float) -> None:
    yy = PROJECT / "sounds" / resource / f"{resource}.yy"
    text = yy.read_text(encoding="utf-8")
    text = re.sub(r'("channelFormat":)\d+', r'\g<1>1', text)
    text = re.sub(r'("duration":)[0-9.]+', rf'\g<1>{duration:.6f}', text)
    text = re.sub(r'("sampleRate":)\d+', r'\g<1>48000', text)
    text = re.sub(r'("soundFile":)"[^"]+"', rf'\g<1>"{filename}"', text)
    yy.write_text(text, encoding="utf-8")


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    rate, suite = read_pcm24(SUITE)
    if rate != 48000:
        raise RuntimeError(f"Expected 48 kHz Logic bounce, got {rate}")
    MASTERS.mkdir(parents=True, exist_ok=True)
    BACKUP.mkdir(parents=True, exist_ok=True)
    report = []

    for cue in manifest["cues"]:
        slug = cue["slug"]
        resource, filename = RUNTIME[slug]
        runtime = PROJECT / "sounds" / resource / filename
        backup = BACKUP / f"{resource}__{filename}"
        if runtime.exists() and not backup.exists():
            shutil.copy2(runtime, backup)

        start = round(cue["start_seconds"] * rate)
        frames = round(cue["duration_seconds"] * rate)
        clip = suite[start:start + frames]
        clip = fade_and_gain(clip, rate, TARGET_PEAK_DB[slug])

        master = MASTERS / f"{slug}.wav"
        write_pcm24(master, rate, clip)
        write_pcm16(runtime, rate, clip)
        update_sound_metadata(resource, filename, len(clip) / rate)
        rms = math.sqrt(float(np.mean(np.square(clip)))) if len(clip) else 0.0
        report.append({
            "slug": slug,
            "resource": resource,
            "duration_seconds": len(clip) / rate,
            "master_format": "24-bit stereo PCM / 48 kHz",
            "runtime_format": "16-bit stereo PCM / 48 kHz",
            "peak_dbfs": TARGET_PEAK_DB[slug],
            "rms_dbfs": 20 * math.log10(max(rms, 1e-12)),
        })

    report_path = PRODUCTION / "sfx_cue_sheets" / "sfx_install_report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Installed {len(report)} Logic-authored SFX and wrote {report_path}")


if __name__ == "__main__":
    main()

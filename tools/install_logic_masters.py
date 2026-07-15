#!/usr/bin/env python3
"""Install validated Logic masters into their GameMaker sound resources."""

from __future__ import annotations

import json
import re
import subprocess
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = ROOT / "art" / "audio_production"
MANIFEST = PRODUCTION / "score_manifest.json"
PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"


def gamemaker_ffmpeg_tool(name: str) -> Path:
    tools = sorted(Path("/Users/Shared/GameMakerStudio2-LTS2026/Cache/runtimes").glob(
        f"runtime-*/bin/ffmpeg/macos/{name}"
    ))
    if not tools:
        raise FileNotFoundError(f"GameMaker {name} was not found")
    return max(tools, key=lambda path: path.stat().st_mtime)


def replace_scalar(source: str, key: str, value: str) -> str:
    pattern = rf'("{re.escape(key)}"\s*:\s*)[^,\n]+'
    updated, count = re.subn(pattern, rf'\g<1>{value}', source, count=1)
    if count != 1:
        raise ValueError(f"expected one {key!r} field")
    return updated


def main() -> None:
    manifest = json.loads(MANIFEST.read_text())
    installed = []
    ffmpeg = gamemaker_ffmpeg_tool("ffmpeg")
    ffprobe = gamemaker_ffmpeg_tool("ffprobe")

    for cue in manifest["cues"]:
        sound_id = cue["runtime_sound_id"]
        sound_dir = PROJECT / "sounds" / sound_id
        metadata_path = sound_dir / f"{sound_id}.yy"
        metadata = metadata_path.read_text()
        match = re.search(r'"soundFile"\s*:\s*"([^"]+)"', metadata)
        if not match:
            raise ValueError(f"{metadata_path}: missing soundFile")

        source = PRODUCTION / cue["lossless_master"]
        with wave.open(str(source), "rb") as wav:
            channels = wav.getnchannels()
            sample_width = wav.getsampwidth()
            sample_rate = wav.getframerate()
            frame_count = wav.getnframes()
        if (channels, sample_width, sample_rate) != (2, 3, 48_000):
            raise ValueError(
                f"{source.name}: expected stereo 24-bit/48 kHz PCM, got "
                f"{channels}ch/{sample_width * 8}-bit/{sample_rate} Hz"
            )

        duration = frame_count / sample_rate
        if abs(duration - cue["duration_seconds"]) > 0.001:
            raise ValueError(
                f"{source.name}: duration {duration:.6f}s does not match manifest "
                f"{cue['duration_seconds']:.6f}s"
            )

        previous_target = sound_dir / match.group(1)
        target = previous_target.with_suffix(".ogg")
        subprocess.run([
            str(ffmpeg), "-y", "-hide_banner", "-loglevel", "error",
            "-i", str(source), "-map_metadata", "-1", "-c:a", "libvorbis",
            "-q:a", "8", "-ar", "48000", "-ac", "2", str(target),
        ], check=True)
        probe = json.loads(subprocess.run([
            str(ffprobe), "-v", "error", "-select_streams", "a:0",
            "-show_entries", "stream=codec_name,channels,sample_rate,duration",
            "-of", "json", str(target),
        ], check=True, capture_output=True, text=True).stdout)["streams"][0]
        if (
            probe["codec_name"] != "vorbis"
            or int(probe["channels"]) != 2
            or int(probe["sample_rate"]) != 48_000
            or abs(float(probe["duration"]) - duration) > 0.001
        ):
            raise ValueError(f"{target.name}: invalid runtime Ogg probe {probe}")
        if previous_target != target and previous_target.exists():
            previous_target.unlink()

        # GameMaker's bitDepth field remains its 16-bit runtime conversion target;
        # the checked-in production master stays lossless 24-bit PCM. Preserve the
        # composed stereo field and source sample rate, then stream the compiled Ogg
        # so multi-minute cues do not accumulate as decoded buffers in memory.
        metadata = replace_scalar(metadata, "channelFormat", "1")
        metadata = replace_scalar(metadata, "compression", "3")
        metadata = replace_scalar(metadata, "conversionMode", "0")
        metadata = replace_scalar(metadata, "duration", f"{duration:.6f}")
        metadata = replace_scalar(metadata, "sampleRate", "48000")
        metadata = replace_scalar(metadata, "soundFile", json.dumps(target.name))
        metadata_path.write_text(metadata)
        installed.append((cue["number"], sound_id, duration, target.stat().st_size))

    for number, sound_id, duration, size in installed:
        print(
            f"Installed {number:02d} {sound_id}: {duration:.3f}s stereo 48 kHz "
            f"streamed Ogg ({size / 1_000_000:.1f} MB)"
        )


if __name__ == "__main__":
    main()

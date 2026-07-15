#!/usr/bin/env python3
"""Extract loop-stable second passes from Logic two-cycle WAV bounces.

Logic renders two consecutive copies of each arrangement in one uninterrupted
offline pass.  Taking the second copy preserves the delay, reverb, and synth
state that will exist when the game wraps the finished PCM buffer.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = ROOT / "art" / "audio_production"
MANIFEST = PRODUCTION / "score_manifest.json"


def decode_i24(frame_bytes: bytes, channels: int) -> list[tuple[int, ...]]:
    frame_width = channels * 3
    decoded: list[tuple[int, ...]] = []
    for offset in range(0, len(frame_bytes), frame_width):
        frame = frame_bytes[offset:offset + frame_width]
        if len(frame) != frame_width:
            break
        decoded.append(tuple(
            int.from_bytes(frame[channel * 3:channel * 3 + 3], "little", signed=True)
            for channel in range(channels)
        ))
    return decoded


def rms(frames: list[tuple[int, ...]]) -> float:
    samples = [sample for frame in frames for sample in frame]
    return math.sqrt(sum(sample * sample for sample in samples) / max(1, len(samples)))


def encode_i24(frames: list[tuple[int, ...]]) -> bytes:
    encoded = bytearray()
    for frame in frames:
        for sample in frame:
            encoded.extend(int(max(-8_388_608, min(8_388_607, sample))).to_bytes(
                3, "little", signed=True
            ))
    return bytes(encoded)


def declick_loop_head(pcm: bytes, channels: int, sample_rate: int) -> tuple[bytes, int, int]:
    """Hermite-match the first 5 ms to the final sample and local slopes."""
    frame_width = channels * 3
    transition_frames = max(2, round(sample_rate * 0.005))
    head = decode_i24(pcm[:(transition_frames + 2) * frame_width], channels)
    tail = decode_i24(pcm[-2 * frame_width:], channels)
    pre_step = max(abs(tail[-1][c] - head[0][c]) for c in range(channels))
    p0 = tail[-1]
    p0_prev = tail[-2]
    p1 = head[transition_frames]
    p1_prev = head[transition_frames - 1]
    replacement: list[tuple[int, ...]] = []
    for index in range(transition_frames):
        t = (index + 1) / transition_frames
        h00 = 2 * t ** 3 - 3 * t ** 2 + 1
        h10 = t ** 3 - 2 * t ** 2 + t
        h01 = -2 * t ** 3 + 3 * t ** 2
        h11 = t ** 3 - t ** 2
        frame = []
        for channel in range(channels):
            outgoing_slope = (p0[channel] - p0_prev[channel]) * transition_frames
            incoming_slope = (p1[channel] - p1_prev[channel]) * transition_frames
            sample = (
                h00 * p0[channel] + h10 * outgoing_slope
                + h01 * p1[channel] + h11 * incoming_slope
            )
            frame.append(round(sample))
        replacement.append(tuple(frame))
    smoothed = encode_i24(replacement) + pcm[transition_frames * frame_width:]
    smoothed_head = decode_i24(smoothed[:frame_width], channels)[0]
    post_step = max(abs(tail[-1][c] - smoothed_head[c]) for c in range(channels))
    return smoothed, pre_step, post_step


def extract_second_cycle(raw_path: Path, master_path: Path, expected_seconds: float) -> dict:
    with wave.open(str(raw_path), "rb") as source:
        channels = source.getnchannels()
        sample_width = source.getsampwidth()
        sample_rate = source.getframerate()
        total_frames = source.getnframes()
        compression = source.getcomptype()
        if (channels, sample_width, compression) != (2, 3, "NONE"):
            raise ValueError(
                f"{raw_path.name}: expected stereo 24-bit PCM, got "
                f"{channels}ch/{sample_width * 8}-bit/{compression}"
            )
        expected_frames = round(expected_seconds * sample_rate)
        if abs(total_frames - expected_frames * 2) > 1:
            raise ValueError(
                f"{raw_path.name}: render is {total_frames} frames, expected "
                f"{expected_frames * 2} for two cycles"
            )

        # Some tempos put the exact bar boundary between PCM frames. Logic may
        # round the complete two-pass render one frame longer than twice the
        # independently rounded cycle length. Anchor the extraction at the
        # first rounded musical boundary and ignore that possible tail frame.
        cycle_frames = expected_frames

        source.setpos(expected_frames)
        second_cycle = source.readframes(cycle_frames)

    second_cycle, seam_step_before, seam_step_after = declick_loop_head(
        second_cycle, channels, sample_rate
    )

    master_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(master_path), "wb") as target:
        target.setnchannels(channels)
        target.setsampwidth(sample_width)
        target.setframerate(sample_rate)
        target.writeframes(second_cycle)

    probe_frames = min(round(sample_rate * 0.1), cycle_frames // 4)
    frame_width = channels * sample_width
    head = decode_i24(second_cycle[:probe_frames * frame_width], channels)
    tail = decode_i24(second_cycle[-probe_frames * frame_width:], channels)
    seam_steps = [abs(tail[-1][channel] - head[0][channel]) for channel in range(channels)]
    local_steps = []
    for frames in (head, tail):
        for before, after in zip(frames, frames[1:]):
            local_steps.extend(abs(after[channel] - before[channel]) for channel in range(channels))
    typical_step = statistics.median(local_steps) if local_steps else 1.0
    head_rms = rms(head)
    tail_rms = rms(tail)
    level_delta_db = 20 * math.log10(max(head_rms, 1.0) / max(tail_rms, 1.0))

    return {
        "raw_bounce": str(raw_path.relative_to(PRODUCTION)),
        "master": str(master_path.relative_to(PRODUCTION)),
        "sample_rate_hz": sample_rate,
        "bit_depth": sample_width * 8,
        "channels": channels,
        "cycle_frames": cycle_frames,
        "duration_seconds": cycle_frames / sample_rate,
        "expected_frame_delta": cycle_frames - expected_frames,
        "two_cycle_render_frame_delta": total_frames - expected_frames * 2,
        "seam_step_before_declick_normalized": seam_step_before / 8_388_607,
        "seam_step_peak_normalized": seam_step_after / 8_388_607,
        "seam_step_vs_typical_sample_step": max(seam_steps) / max(typical_step, 1.0),
        "head_tail_rms_delta_db": level_delta_db,
        "declick_transition_ms": 5.0,
        "method": "second cycle of uninterrupted Logic bounce plus 5 ms Hermite seam match",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--require-all", action="store_true",
        help="fail if any cue does not yet have a two-cycle Logic bounce",
    )
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text())
    reports = []
    missing = []
    for cue in manifest["cues"]:
        stem = f"{cue['number']:02d}_{cue['slug']}"
        raw_path = PRODUCTION / "raw_bounces" / f"{stem}_two_cycle.wav"
        master_path = PRODUCTION / cue["lossless_master"]
        if not raw_path.exists():
            missing.append(str(raw_path.relative_to(PRODUCTION)))
            continue
        exact_seconds = cue["bars"] * 4 * 60 / cue["tempo_bpm"]
        report = extract_second_cycle(raw_path, master_path, exact_seconds)
        report.update({"number": cue["number"], "title": cue["title"]})
        reports.append(report)
        print(
            f"Finalized {cue['number']:02d} {cue['title']}: "
            f"{report['duration_seconds']:.3f}s, seam "
            f"{report['seam_step_peak_normalized']:.6f} FS"
        )

    validation = {
        "method": "second cycle extracted from uninterrupted two-cycle Logic Pro bounce",
        "completed": reports,
        "missing": missing,
    }
    (PRODUCTION / "loop_validation.json").write_text(json.dumps(validation, indent=2) + "\n")
    if args.require_all and missing:
        raise SystemExit(f"Missing {len(missing)} two-cycle bounces")


if __name__ == "__main__":
    main()

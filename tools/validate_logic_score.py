#!/usr/bin/env python3
"""Validate the editable score catalog before any Logic production work begins."""

from __future__ import annotations

import json
import struct
from dataclasses import dataclass, field
from pathlib import Path

from build_logic_score_midi import (
    BAR,
    CUES,
    HORIZON_THEME,
    PRODUCTION,
    RUNTIME_SOUND_IDS,
    SECONDARY_MOTIFS,
    TPQ,
    section_map,
)


@dataclass
class ParsedTrack:
    name: str = ""
    end_tick: int = 0
    markers: list[tuple[int, str]] = field(default_factory=list)
    text: list[str] = field(default_factory=list)
    tempos: list[tuple[int, int]] = field(default_factory=list)
    time_signatures: list[tuple[int, bytes]] = field(default_factory=list)
    note_ons: list[tuple[int, int, int]] = field(default_factory=list)
    note_offs: list[tuple[int, int, int]] = field(default_factory=list)


def read_vlq(data: bytes, position: int) -> tuple[int, int]:
    value = 0
    while True:
        if position >= len(data):
            raise ValueError("truncated variable-length quantity")
        byte = data[position]
        position += 1
        value = (value << 7) | (byte & 0x7F)
        if not byte & 0x80:
            return value, position


def parse_track(data: bytes) -> ParsedTrack:
    parsed = ParsedTrack()
    active: dict[tuple[int, int], int] = {}
    tick = 0
    position = 0
    running_status: int | None = None

    while position < len(data):
        delta, position = read_vlq(data, position)
        tick += delta
        status = data[position]
        if status & 0x80:
            position += 1
            if status < 0xF0:
                running_status = status
        elif running_status is not None:
            status = running_status
        else:
            raise ValueError("running status used before a channel status")

        if status == 0xFF:
            kind = data[position]
            position += 1
            length, position = read_vlq(data, position)
            payload = data[position:position + length]
            position += length
            if kind == 0x03:
                parsed.name = payload.decode("utf-8")
            elif kind == 0x06:
                parsed.markers.append((tick, payload.decode("utf-8")))
            elif kind == 0x01:
                parsed.text.append(payload.decode("utf-8"))
            elif kind == 0x51:
                parsed.tempos.append((tick, int.from_bytes(payload, "big")))
            elif kind == 0x58:
                parsed.time_signatures.append((tick, payload))
            elif kind == 0x2F:
                parsed.end_tick = tick
                break
            continue

        if status in (0xF0, 0xF7):
            length, position = read_vlq(data, position)
            position += length
            continue

        message = status & 0xF0
        channel = status & 0x0F
        data_length = 1 if message in (0xC0, 0xD0) else 2
        payload = data[position:position + data_length]
        position += data_length

        if message == 0x90 and payload[1] > 0:
            pitch, velocity = payload
            parsed.note_ons.append((tick, pitch, channel))
            active[(channel, pitch)] = active.get((channel, pitch), 0) + 1
        elif message == 0x80 or (message == 0x90 and payload[1] == 0):
            pitch = payload[0]
            parsed.note_offs.append((tick, pitch, channel))
            key = (channel, pitch)
            if active.get(key, 0) <= 0:
                raise ValueError(f"orphan note-off for channel {channel}, pitch {pitch}")
            active[key] -= 1

    if active and any(count for count in active.values()):
        raise ValueError(f"unclosed notes: {active}")
    return parsed


def parse_midi(path: Path) -> tuple[int, int, list[ParsedTrack]]:
    data = path.read_bytes()
    if data[:4] != b"MThd" or struct.unpack(">I", data[4:8])[0] != 6:
        raise ValueError(f"{path.name}: invalid MIDI header")
    midi_format, track_count, division = struct.unpack(">HHH", data[8:14])
    position = 14
    tracks = []
    while position < len(data):
        if data[position:position + 4] != b"MTrk":
            raise ValueError(f"{path.name}: invalid track chunk at byte {position}")
        length = struct.unpack(">I", data[position + 4:position + 8])[0]
        start = position + 8
        tracks.append(parse_track(data[start:start + length]))
        position = start + length
    if len(tracks) != track_count:
        raise ValueError(f"{path.name}: header says {track_count} tracks, parsed {len(tracks)}")
    return midi_format, division, tracks


def motif_plan(cue) -> list[tuple[str, str, int]]:
    if cue.secondary_theme == "horizon_dialogue":
        if cue.voice_order == "selkie_first":
            return [("lead", "selkie_answer", 0), ("counter", "moon_call", 2)]
        return [("lead", "moon_call", 0), ("counter", "selkie_answer", 2)]
    if cue.secondary_theme == "mira_aisha_medley":
        if cue.voice_order == "aisha_first":
            return [("counter", "aisha", 0), ("lead", "mira", 2)]
        return [("lead", "mira", 0), ("counter", "aisha", 2)]
    return [("lead", cue.secondary_theme, 0)]


def validate_motif_statement(cue, tracks_by_role: dict[str, ParsedTrack],
                             role: str, motif_key: str, start_bar: int) -> None:
    motif = SECONDARY_MOTIFS[motif_key]
    start_tick = start_bar * BAR
    end_tick = start_tick + 8 * TPQ
    notes = [
        (tick, pitch) for tick, pitch, _ in tracks_by_role[role].note_ons
        if start_tick - 8 <= tick < end_tick - 8
    ]
    expected_pitches = []
    expected_ticks = []
    for beat, _, degree in motif:
        if cue.major_resolution and degree == 3:
            degree = 4
        expected_ticks.append(start_tick + round(beat * TPQ))
        expected_pitches.append(cue.root + 12 + degree)

    actual_pitches = [pitch for _, pitch in notes]
    if actual_pitches != expected_pitches:
        raise ValueError(
            f"{cue.number:02d}: {motif_key} pitch identity missing from {role}: "
            f"expected {expected_pitches}, got {actual_pitches}"
        )
    for (actual_tick, _), expected_tick in zip(notes, expected_ticks):
        if abs(actual_tick - expected_tick) > 8:
            raise ValueError(
                f"{cue.number:02d}: {motif_key} rhythm drift at {actual_tick}; "
                f"expected {expected_tick} +/- 8 ticks"
            )


def validate_catalog() -> None:
    manifest_path = PRODUCTION / "score_manifest.json"
    manifest = json.loads(manifest_path.read_text())
    midi_paths = sorted((PRODUCTION / "source_midi").glob("*.mid"))
    sheets = sorted((PRODUCTION / "cue_sheets").glob("*.md"))
    if len(midi_paths) != len(CUES) or len(sheets) != len(CUES):
        raise ValueError(
            f"expected {len(CUES)} MIDI files and cue sheets; "
            f"found {len(midi_paths)} MIDI and {len(sheets)} sheets"
        )
    if len(manifest["cues"]) != len(CUES):
        raise ValueError("manifest cue count does not match the composer catalog")
    if len(HORIZON_THEME) != 20 or max(beat + duration for beat, duration, _ in HORIZON_THEME) != 16:
        raise ValueError("the primary Horizon Theme must span exactly four measures")
    if len({tuple(value) for value in SECONDARY_MOTIFS.values()}) != len(SECONDARY_MOTIFS):
        raise ValueError("secondary leitmotifs must be mutually unique")
    for motif_id, motif in SECONDARY_MOTIFS.items():
        if max(beat + duration for beat, duration, _ in motif) > 8:
            raise ValueError(f"secondary motif {motif_id} exceeds its two-measure cell")

    expected_track_starts = [
        "Arrangement & Markers", "01 ", "02 ", "03 ", "04 ",
        "05 ", "06 Lead - ", "07 ", "08 Countervoice - ", "09 ",
    ]
    for cue, manifest_cue, path in zip(CUES, manifest["cues"], midi_paths):
        expected_name = f"{cue.number:02d}_{cue.slug}.mid"
        if path.name != expected_name or manifest_cue["midi"] != f"source_midi/{expected_name}":
            raise ValueError(f"cue {cue.number:02d}: MIDI filename or manifest path drift")
        if manifest_cue["runtime_sound_id"] != RUNTIME_SOUND_IDS[cue.number]:
            raise ValueError(f"cue {cue.number:02d}: runtime sound routing drift")
        if not 120 <= cue.seconds <= 240:
            raise ValueError(f"cue {cue.number:02d}: duration {cue.seconds:.1f}s is outside 2-4 minutes")
        midi_format, division, tracks = parse_midi(path)
        if (midi_format, division, len(tracks)) != (1, TPQ, 10):
            raise ValueError(
                f"{path.name}: expected format 1, {TPQ} PPQ, and 10 tracks; "
                f"got format {midi_format}, {division} PPQ, and {len(tracks)} tracks"
            )
        for track, name_start in zip(tracks, expected_track_starts):
            if not track.name.startswith(name_start):
                raise ValueError(f"{path.name}: unexpected track name {track.name!r}")
        conductor = tracks[0]
        expected_end = cue.bars * BAR
        if conductor.end_tick != expected_end:
            raise ValueError(
                f"{path.name}: conductor ends at {conductor.end_tick}, expected {expected_end}"
            )
        expected_markers = [name for name, _, _ in section_map(cue)] + ["LOOP END / RETURN TO BAR 1"]
        if [name.split(" (")[0] for _, name in conductor.markers[:-1]] + [conductor.markers[-1][1]] != expected_markers:
            raise ValueError(f"{path.name}: section marker map drift")
        if conductor.tempos != [(0, round(60_000_000 / cue.tempo))]:
            raise ValueError(f"{path.name}: tempo metadata drift")
        if conductor.time_signatures != [(0, bytes((4, 2, 24, 8)))]:
            raise ValueError(f"{path.name}: time signature metadata drift")
        if max(track.end_tick for track in tracks) > expected_end:
            raise ValueError(f"{path.name}: an event extends beyond the loop boundary")
        for track in tracks[1:]:
            if not track.note_ons:
                raise ValueError(f"{path.name}: {track.name} has no editable note data")

        tracks_by_role = {"lead": tracks[6], "counter": tracks[8]}
        for role, motif_key, start_bar in motif_plan(cue):
            validate_motif_statement(cue, tracks_by_role, role, motif_key, start_bar)

        cue_sheet = (PRODUCTION / manifest_cue["cue_sheet"]).read_text()
        if manifest_cue["secondary_leitmotif"] not in cue_sheet:
            raise ValueError(f"{cue.number:02d}: cue sheet omits its secondary leitmotif")

        print(
            f"OK {cue.number:02d} {cue.title}: {cue.seconds:.1f}s, "
            f"{len(tracks) - 1} instruments, {manifest_cue['secondary_leitmotif']}"
        )

    print(f"Validated {len(CUES)} clean-loop score sources and all secondary leitmotif identities.")


if __name__ == "__main__":
    validate_catalog()

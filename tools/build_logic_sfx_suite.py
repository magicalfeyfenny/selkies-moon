#!/usr/bin/env python3
"""Build the editable multi-track MIDI source and cue map for the Logic SFX suite."""

from __future__ import annotations

import json
import struct
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = ROOT / "art" / "audio_production"
SOURCE = PRODUCTION / "sfx_source"
PROJECTS = PRODUCTION / "sfx_logic_projects"
MASTERS = PRODUCTION / "sfx_masters"
RAW = PRODUCTION / "sfx_raw_bounces"
CUES = PRODUCTION / "sfx_cue_sheets"
TPQ = 480
BAR = TPQ * 4
TEMPO = 120


@dataclass(frozen=True)
class Cue:
    slug: str
    title: str
    root: int
    family: str
    duration: float


SFX = (
    Cue("bomb", "Orchestral Night-Bloom", 38, "low orchestral bloom, reversed glass, choral air", 2.30),
    Cue("boss_phase", "Stained-Glass Phase Cadence", 50, "bell cadence and organ punctuation", 1.45),
    Cue("boss_spawn", "Reliquary Gate Opens", 34, "low organ, iron hinge, distant choir", 2.40),
    Cue("enemy_destroy", "Porcelain Familiar Break", 57, "brittle metal and glass collapse", 0.72),
    Cue("enemy_fire_arc", "Occult Ribbon Snap", 62, "air ribbon, harp snap, muted body", 0.42),
    Cue("enemy_fire_needle", "Silver Needle Cast", 74, "dry metallic needle and tiny glass tail", 0.30),
    Cue("ow", "Stained Armor Fracture", 45, "cloth impact, armor body, glass crack", 0.78),
    Cue("player_focus", "Converging Familiar Volley", 55, "restrained layered strike and focused shimmer", 0.40),
    Cue("player_shot_moon", "Moon Rose-Thorn Shot", 69, "silk thorn transient and quiet glass overtone", 0.24),
    Cue("player_shot_selkie", "Selkie Tidal Chakram Shot", 67, "small metal ring and tidal breath", 0.24),
    Cue("powerup_collect", "Votive Glass Collected", 72, "music-box glass pickup", 0.66),
    Cue("stage_clear", "Horizon Seal Flourish", 62, "short Horizon-theme orchestral flourish", 2.20),
    Cue("sword_moon", "Rose-Whip Unsheathed", 57, "thorn sweep, petal shimmer, velvet body", 1.18),
    Cue("sword_selkie", "Chakram Orbit Unsheathed", 55, "metal orbit, sea-air sweep, bright ring", 1.18),
    Cue("typewriter", "Neo-Victorian Clockwork Key", 78, "quiet mechanical key and felt return", 0.18),
)


def vlq(value: int) -> bytes:
    result = bytearray([value & 0x7F])
    value >>= 7
    while value:
        result.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return bytes(result)


def meta(kind: int, payload: bytes) -> bytes:
    return bytes((0xFF, kind)) + vlq(len(payload)) + payload


class Track:
    def __init__(self, name: str, channel: int | None = None, program: int | None = None):
        self.channel = channel
        self.events: list[tuple[int, int, bytes]] = [(0, 0, meta(0x03, name.encode()))]
        if channel is not None and program is not None:
            self.events.append((0, 10, bytes((0xC0 | channel, program))))

    def note(self, tick: int, beats: float, pitch: int, velocity: int) -> None:
        assert self.channel is not None
        duration = max(1, round(beats * TPQ))
        self.events.append((tick, 20, bytes((0x90 | self.channel, pitch, velocity))))
        self.events.append((tick + duration, 15, bytes((0x80 | self.channel, pitch, 0))))

    def marker(self, tick: int, text: str) -> None:
        self.events.append((tick, 1, meta(0x06, text.encode())))

    def chunk(self) -> bytes:
        output = bytearray()
        previous = 0
        for tick, _, message in sorted(self.events, key=lambda event: (event[0], event[1])):
            output.extend(vlq(tick - previous))
            output.extend(message)
            previous = tick
        output.extend(b"\x00\xFF\x2F\x00")
        return b"MTrk" + struct.pack(">I", len(output)) + output


def add_chord(track: Track, tick: int, pitches: tuple[int, ...], beats: float, velocity: int) -> None:
    for index, pitch in enumerate(pitches):
        track.note(tick + index * 7, beats, pitch, max(1, velocity - index * 3))


def build() -> tuple[Path, Path]:
    for directory in (SOURCE, PROJECTS, MASTERS, RAW, CUES):
        directory.mkdir(parents=True, exist_ok=True)

    conductor = Track("SFX Cue Markers")
    conductor.events.append((0, 1, meta(0x51, (500000).to_bytes(3, "big"))))
    conductor.events.append((0, 2, meta(0x58, bytes((4, 2, 24, 8)))))
    metal = Track("01 Metal and Glass", 0, 46)       # orchestral harp
    body = Track("02 Orchestral Body", 1, 48)        # string ensemble
    air = Track("03 Air and Choir", 2, 52)            # choir aahs
    low = Track("04 Organ and Low Bloom", 3, 19)      # church organ
    transient = Track("05 Acoustic Transients", 9, 0) # percussion channel
    tail = Track("06 Bells and Motif Tail", 4, 14)    # tubular bells
    tracks = [conductor, metal, body, air, low, transient, tail]

    for index, cue in enumerate(SFX):
        start = index * BAR * 2
        conductor.marker(start, f"{index + 1:02d} {cue.slug} - {cue.title}")
        root = cue.root
        # Every cue gets an acoustic body, a material identity, and a tail;
        # velocities are intentionally lower for the three repeated-shot families.
        repeated = cue.slug in {"player_shot_moon", "player_shot_selkie", "typewriter", "enemy_fire_arc", "enemy_fire_needle"}
        base_v = 48 if repeated else 72

        if cue.slug == "bomb":
            add_chord(low, start, (root, root + 7, root + 12), 3.2, 92)
            add_chord(air, start + 80, (root + 12, root + 15, root + 19), 3.0, 62)
            metal.note(start + 120, 1.6, root + 31, 74)
            transient.note(start, 0.25, 36, 96)
            transient.note(start + 50, 1.0, 49, 70)
        elif cue.slug in {"boss_phase", "stage_clear", "powerup_collect"}:
            motif = (0, 3, 7, 10) if cue.slug != "stage_clear" else (0, 3, 7, 10, 7, 5, 3, 2)
            spacing = TPQ // 3 if cue.slug != "stage_clear" else TPQ // 2
            for step, degree in enumerate(motif):
                tail.note(start + step * spacing, 0.42, root + degree, base_v + 14)
            add_chord(body, start, (root - 12, root - 5, root), 2.5, base_v)
            metal.note(start + 30, 1.2, root + 19, base_v)
        elif cue.slug == "boss_spawn":
            add_chord(low, start, (root, root + 7, root + 13), 3.6, 84)
            add_chord(air, start + TPQ // 2, (root + 12, root + 15, root + 19), 2.8, 56)
            transient.note(start + 20, 0.4, 41, 78)
            tail.note(start + TPQ, 1.8, root + 30, 58)
        elif cue.slug in {"sword_moon", "sword_selkie"}:
            degrees = (0, 7, 12, 15, 19) if cue.slug == "sword_moon" else (0, 5, 9, 12, 17)
            for step, degree in enumerate(degrees):
                metal.note(start + step * 90, 0.62, root + degree, 72 - step * 3)
            add_chord(body, start + 60, (root - 12, root - 5, root), 1.8, 66)
            air.note(start + 100, 1.9, root + 12, 44)
            tail.note(start + 250, 1.3, root + 24, 60)
        elif cue.slug in {"player_shot_moon", "player_shot_selkie", "player_focus"}:
            interval = 10 if cue.slug == "player_shot_moon" else 7
            if cue.slug == "player_focus": interval = 12
            metal.note(start, 0.18, root, base_v + 16)
            metal.note(start + 18, 0.22, root + interval, base_v + 8)
            body.note(start, 0.28, root - 12, base_v)
            tail.note(start + 25, 0.34, root + 24, base_v - 6)
            transient.note(start, 0.10, 37, base_v + 10)
        elif cue.slug in {"enemy_fire_arc", "enemy_fire_needle", "typewriter"}:
            metal.note(start, 0.12, root, base_v + 10)
            tail.note(start + 12, 0.18, root + (7 if cue.slug == "enemy_fire_arc" else 12), base_v)
            transient.note(start, 0.08, 37 if cue.slug != "enemy_fire_needle" else 42, base_v + 14)
            if cue.slug == "enemy_fire_arc": air.note(start, 0.35, root - 12, 28)
        elif cue.slug in {"enemy_destroy", "ow"}:
            transient.note(start, 0.2, 38 if cue.slug == "ow" else 39, 86)
            transient.note(start + 35, 0.45, 49, 62)
            add_chord(body, start, (root - 12, root - 5, root), 0.7, 66)
            metal.note(start + 20, 0.48, root + 17, 76)
            tail.note(start + 55, 0.72, root + 24, 54)
        else:
            add_chord(body, start, (root - 12, root - 5, root), 1.0, base_v)
            metal.note(start, 0.5, root + 12, base_v + 8)
            tail.note(start + 40, 0.8, root + 24, base_v)

    midi_path = SOURCE / "selkies_moon_sfx_production.mid"
    header = b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), TPQ)
    midi_path.write_bytes(header + b"".join(track.chunk() for track in tracks))

    manifest = {
        "tempo_bpm": TEMPO,
        "slot_seconds": 4.0,
        "logic_project": "sfx_logic_projects/Selkies Moon SFX Production.logicx",
        "layers": ["Metal and Glass", "Orchestral Body", "Air and Choir", "Organ and Low Bloom", "Acoustic Transients", "Bells and Motif Tail"],
        "cues": [
            {"index": i + 1, "slug": cue.slug, "title": cue.title, "start_seconds": i * 4.0,
             "duration_seconds": cue.duration, "family": cue.family}
            for i, cue in enumerate(SFX)
        ],
    }
    manifest_path = CUES / "sfx_suite_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return midi_path, manifest_path


if __name__ == "__main__":
    midi, manifest = build()
    print(midi)
    print(manifest)

#!/usr/bin/env python3
"""Compose production-length, clean-looping format-1 MIDI arrangements for Logic Pro.

Logic opens each file as a new project with software-instrument tracks while
preserving track names, markers, tempo, controllers, and editable note data.
The writing is original and uses broad genre vocabulary rather than quoting any
existing composition.
"""

from __future__ import annotations

import json
import math
import random
import struct
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = ROOT / "art" / "audio_production"
MIDI_DIR = PRODUCTION / "source_midi"
CUE_DIR = PRODUCTION / "cue_sheets"
PROJECT_DIR = PRODUCTION / "logic_projects"
MASTER_DIR = PRODUCTION / "masters"
RAW_BOUNCE_DIR = PRODUCTION / "raw_bounces"

TPQ = 480
BAR = TPQ * 4

# Four measures in 4/4. The first eight notes preserve the placeholder phrase;
# the continuation answers it, reaches upward, then returns to D without simply
# reversing the opening contour.
HORIZON_THEME = (
    (0.0, 1.0, 0), (1.0, 0.5, 3), (1.5, 0.5, 7), (2.0, 1.0, 10), (3.0, 1.0, 7),
    (4.0, 1.0, 5), (5.0, 0.5, 3), (5.5, 0.5, 2), (6.0, 1.0, 7), (7.0, 1.0, 12),
    (8.0, 1.0, 10), (9.0, 0.5, 7), (9.5, 0.5, 3), (10.0, 1.0, 2), (11.0, 1.0, 5),
    (12.0, 1.0, 10), (13.0, 0.5, 7), (13.5, 0.5, 5), (14.0, 1.0, 2), (15.0, 1.0, 0),
)

# Character leitmotifs are intentionally shorter than the score-wide Horizon
# Theme.  They behave as memorable two-measure cells that can be stated,
# answered, fragmented, or combined without displacing the shared theme.
SECONDARY_MOTIFS = {
    "moon_call": (
        (0.0, 1.0, 0), (1.0, 0.5, 7), (1.5, 0.5, 10), (2.0, 1.0, 5),
        (3.0, 1.0, 3), (4.0, 0.5, 7), (4.5, 0.5, 12), (5.0, 1.0, 10),
        (6.0, 0.5, 7), (6.5, 0.5, 5), (7.0, 1.0, 2),
    ),
    "selkie_answer": (
        (0.0, 0.5, 7), (0.5, 0.5, 2), (1.0, 1.0, 5), (2.0, 0.5, 3),
        (2.5, 0.5, 0), (3.0, 1.0, -2), (4.0, 0.5, 2), (4.5, 0.5, 7),
        (5.0, 1.0, 5), (6.0, 0.5, 3), (6.5, 0.5, 2), (7.0, 1.0, 0),
    ),
    "shalmii": (
        (0.0, 0.5, 0), (0.75, 0.25, 0), (1.0, 1.0, 7),
        (2.0, 0.5, 3), (2.75, 0.25, 2), (3.0, 1.0, 0),
        (4.0, 0.5, -2), (4.75, 0.25, 0), (5.0, 1.0, 3),
        (6.0, 0.5, 7), (6.75, 0.25, 5), (7.0, 1.0, 0),
    ),
    "aster": (
        (0.0, 0.5, 0), (0.5, 0.5, 2), (1.0, 0.5, 5), (1.5, 0.5, 9),
        (2.0, 1.0, 7), (3.0, 0.5, 5), (3.5, 0.5, 2),
        (4.0, 0.5, 3), (4.5, 0.5, 7), (5.0, 0.5, 10), (5.5, 0.5, 9),
        (6.0, 1.0, 5), (7.0, 0.5, 2), (7.5, 0.5, 0),
    ),
    "mira": (
        (0.0, 1.0, 0), (1.0, 0.5, 8), (1.5, 0.5, 7), (2.0, 1.0, 3),
        (3.0, 1.0, 5), (4.0, 0.5, 2), (4.5, 0.5, 0), (5.0, 1.0, -4),
        (6.0, 0.5, 0), (6.5, 0.5, 3), (7.0, 1.0, 8),
    ),
    "aisha": (
        (0.0, 0.5, 0), (0.5, 0.5, 3), (1.0, 0.5, 7), (1.5, 0.5, 10),
        (2.0, 0.5, 7), (2.5, 0.5, 3), (3.0, 1.0, 2),
        (4.0, 0.5, 5), (4.5, 0.5, 9), (5.0, 0.5, 12), (5.5, 0.5, 9),
        (6.0, 0.5, 5), (6.5, 0.5, 2), (7.0, 1.0, 0),
    ),
    "caelia": (
        (0.0, 1.0, 0), (1.0, 0.5, 6), (1.5, 0.5, 7), (2.0, 1.0, 3),
        (3.0, 1.0, -1), (4.0, 0.5, 0), (4.5, 0.5, 6), (5.0, 1.0, 10),
        (6.0, 0.5, 7), (6.5, 0.5, 3), (7.0, 1.0, 0),
    ),
}

SECONDARY_THEME_NAMES = {
    "horizon_dialogue": "Two Voices Beyond the Horizon",
    "shalmii": "Anvil Oath",
    "aster": "Saltwind Ribbon",
    "mira_aisha_medley": "Wish-Sigil / Four Suits Medley",
    "caelia": "Bloodstar Orrery",
}


@dataclass(frozen=True)
class Cue:
    number: int
    slug: str
    title: str
    role: str
    root: int
    tempo: int
    bars: int
    style: str
    lead_program: int
    lead_name: str
    counter_program: int
    counter_name: str
    secondary_theme: str
    cue_kind: str
    voice_order: str
    major_resolution: bool = False

    @property
    def seconds(self) -> float:
        return self.bars * 4 * 60 / self.tempo


CUES = (
    Cue(1, "title_promise_across_horizon", "A Promise Across the Horizon", "Title / Opening",
        50, 140, 76, "moonlit", 68, "Moon Oboe", 71, "Selkie Clarinet",
        "horizon_dialogue", "unassigned", "moon_first"),
    Cue(2, "stage1_forge_at_dusk", "The Forge at Dusk", "Stage 1 / Shalmii",
        50, 136, 84, "forge", 56, "Trumpet", 48, "String Ensemble",
        "shalmii", "stage", "primary"),
    Cue(3, "boss_shalmii_iron_vow", "Iron Vow beneath the Ember Moon", "Boss / Shalmii",
        50, 142, 92, "forge_boss", 56, "Trumpet", 48, "String Ensemble",
        "shalmii", "boss", "primary"),
    Cue(4, "stage2_ribbon_over_saltwind", "Ribbon over Saltwind", "Stage 2 / Aster",
        55, 134, 92, "saltwind", 73, "Flute", 40, "Violin",
        "aster", "stage", "primary"),
    Cue(5, "boss_aster_tidebound_lace", "Tidebound Lace in Revolt", "Boss / Aster",
        55, 140, 100, "saltwind_boss", 73, "Flute", 40, "Violin",
        "aster", "boss", "primary"),
    Cue(6, "stage3_covenant_four_suits", "A Covenant in Four Suits", "Stage 3 / Mira & Aisha",
        48, 132, 100, "wishcourt", 40, "Mira Violin", 71, "Aisha Clarinet",
        "mira_aisha_medley", "stage", "mira_first"),
    Cue(7, "boss_mira_aisha_wish_suit", "Wish and Suit, Entwined", "Dual Boss / Mira & Aisha",
        48, 138, 108, "wishcourt_boss", 40, "Mira Violin", 71, "Aisha Clarinet",
        "mira_aisha_medley", "boss", "aisha_first"),
    Cue(8, "stage4_orrery_bloodstar", "Orrery of the Bloodstar", "Stage 4 / Caelia",
        45, 130, 108, "orrery", 60, "French Horn", 52, "Choir Aahs",
        "caelia", "stage", "primary"),
    Cue(9, "boss_caelia_red_orbit", "Red Orbit of the Unforgiving Star", "Boss / Caelia",
        45, 136, 116, "orrery_boss", 60, "French Horn", 52, "Choir Aahs",
        "caelia", "boss", "primary"),
    Cue(10, "stage5_moon_violet_sunset", "Violets beneath Moon's Sunset", "Stage 5 / Moon route",
        50, 128, 116, "violet_moon", 68, "Moon Oboe", 71, "Selkie Clarinet",
        "horizon_dialogue", "stage", "moon_first"),
    Cue(11, "boss_moon_rose_eternity", "Rose-Eternity at the Edge of Morning", "Final Boss / Moon",
        50, 134, 124, "moon_boss", 68, "Moon Oboe", 71, "Selkie Clarinet",
        "horizon_dialogue", "boss", "moon_first"),
    Cue(12, "stage5_selkie_violet_sunrise", "Violets upon Selkie's Sunrise", "Stage 5 / Selkie route",
        50, 128, 116, "violet_selkie", 71, "Selkie Clarinet", 68, "Moon Oboe",
        "horizon_dialogue", "stage", "selkie_first"),
    Cue(13, "boss_selkie_chakram_apotheosis", "Chakram Apotheosis before Daybreak", "Final Boss / Selkie",
        50, 134, 124, "selkie_boss", 71, "Selkie Clarinet", 68, "Moon Oboe",
        "horizon_dialogue", "boss", "selkie_first"),
    Cue(14, "ending_morning_finds_moon", "Where Morning Finds the Moon", "Ending",
        50, 110, 104, "morning", 71, "Selkie Clarinet", 68, "Moon Oboe",
        "horizon_dialogue", "unassigned", "selkie_first", True),
    Cue(15, "credits_until_meet_again", "Until We Meet Again", "Credits",
        50, 114, 112, "reunion", 68, "Moon Oboe", 71, "Selkie Clarinet",
        "horizon_dialogue", "unassigned", "moon_first", True),
)

RUNTIME_SOUND_IDS = {
    1: "snd_music_title",
    2: "snd_music_stage_shalmii",
    3: "snd_music_boss_shalmii",
    4: "snd_music_stage_aster",
    5: "snd_music_boss_aster",
    6: "snd_music_stage_mira_aisha",
    7: "snd_music_boss_mira_aisha",
    8: "snd_music_stage_caelia",
    9: "snd_music_boss_caelia",
    10: "snd_music_stage_moon",
    11: "snd_music_boss_moon",
    12: "snd_music_stage_selkie",
    13: "snd_music_boss_selkie",
    14: "snd_music_ending",
    15: "snd_music_credits",
}


def vlq(value: int) -> bytes:
    result = bytearray([value & 0x7F])
    value >>= 7
    while value:
        result.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return bytes(result)


def meta(kind: int, payload: bytes) -> bytes:
    return bytes((0xFF, kind)) + vlq(len(payload)) + payload


class MidiTrack:
    def __init__(self, name: str, channel: int | None = None, program: int | None = None):
        self.name = name
        self.channel = channel
        self.events: list[tuple[int, int, bytes]] = [(0, 0, meta(0x03, name.encode("utf-8")))]
        if channel is not None and program is not None:
            self.events.append((0, 10, bytes((0xC0 | channel, program))))

    def add_meta(self, tick: int, kind: int, text: str, order: int = 1) -> None:
        self.events.append((tick, order, meta(kind, text.encode("utf-8"))))

    def cc(self, tick: int, controller: int, value: int, order: int = 5) -> None:
        assert self.channel is not None
        self.events.append((tick, order, bytes((0xB0 | self.channel, controller, max(0, min(127, value))))))

    def note(self, tick: int, duration: int, pitch: int, velocity: int, humanize: int = 0,
             rng: random.Random | None = None) -> None:
        assert self.channel is not None
        if humanize and rng:
            tick = max(0, tick + rng.randint(-humanize, humanize))
            velocity = max(1, min(127, velocity + rng.randint(-4, 4)))
        pitch = max(0, min(127, pitch))
        self.events.append((tick, 20, bytes((0x90 | self.channel, pitch, velocity))))
        self.events.append((tick + max(1, duration), 15, bytes((0x80 | self.channel, pitch, 0))))

    def chunk(self) -> bytes:
        events = sorted(self.events, key=lambda event: (event[0], event[1]))
        output = bytearray()
        previous = 0
        for tick, _, message in events:
            output.extend(vlq(tick - previous))
            output.extend(message)
            previous = tick
        output.extend(b"\x00\xFF\x2F\x00")
        return b"MTrk" + struct.pack(">I", len(output)) + bytes(output)


def chord(root: int, quality: str) -> tuple[int, ...]:
    intervals = {
        "minor": (0, 3, 7),
        "major": (0, 4, 7),
        "minor7": (0, 3, 7, 10),
        "major7": (0, 4, 7, 11),
        "dim": (0, 3, 6),
        "sus4": (0, 5, 7),
    }[quality]
    return tuple(root + interval for interval in intervals)


def progression_for(cue: Cue, section: str) -> tuple[tuple[int, str], ...]:
    # Degrees are semitone offsets from cue.root. The two principal cycles link
    # by sharing their last/first dominant colors rather than hard-resetting.
    progressions = {
        "Intro": ((0, "minor7"), (-2, "major"), (-5, "major7"), (-7, "major")),
        "Progression I": ((0, "minor7"), (-5, "major7"), (3, "major"), (-2, "major")),
        "Progression II": ((5, "minor7"), (2, "dim"), (7, "major"), (0, "minor7")),
        "Theme Reprise": ((3, "major7"), (-2, "major"), (0, "minor7"), (7, "major")),
        "Breakdown": ((0, "minor"), (7, "minor"), (-5, "major7"), (7, "sus4")),
        "Development": ((0, "minor7"), (2, "dim"), (3, "major7"), (5, "minor7"),
                        (-2, "major"), (-5, "major7"), (7, "major"), (0, "minor7")),
        "Climax": ((0, "minor7"), (3, "major7"), (5, "minor7"), (7, "major")),
        # The outro is a formal section, but its final dominant is also the
        # turnaround into bar 1.  It deliberately does not cadence to silence.
        "Outro": ((-5, "major7"), (-2, "major"), (7, "major"), (7, "sus4")),
    }
    selected = list(progressions[section])
    if cue.major_resolution and section == "Intro":
        selected[0] = (0, "major7")
    if cue.major_resolution and section in ("Climax", "Outro"):
        if section == "Outro":
            # The major-route cues still return through the dominant; bar 1
            # supplies the audible tonic resolution on every repeat.
            selected[-1] = (7, "major")
        else:
            selected[-1] = (0, "major")
    return tuple(selected)


def section_map(cue: Cue) -> tuple[tuple[str, int, int], ...]:
    development = cue.bars - 72
    lengths = (
        ("Intro", 8),
        ("Progression I", 12),
        ("Progression II", 12),
        ("Theme Reprise", 12),
        ("Breakdown", 8),
        ("Development", development),
        ("Climax", 12),
        ("Outro", 8),
    )
    result = []
    bar = 0
    for name, length in lengths:
        result.append((name, bar, length))
        bar += length
    assert bar == cue.bars and development >= 4 and development % 4 == 0
    return tuple(result)


def theme_notes(cue: Cue, octave: int = 12) -> tuple[tuple[float, float, int], ...]:
    result = []
    for beat, duration, degree in HORIZON_THEME:
        adjusted = degree
        if cue.major_resolution and degree == 3:
            adjusted = 4
        result.append((beat, duration, cue.root + octave + adjusted))
    return tuple(result)


def section_at(cue: Cue, bar: int) -> tuple[str, int, int]:
    for name, start, length in section_map(cue):
        if start <= bar < start + length:
            return name, start, length
    raise ValueError(bar)


def dynamics(section: str, position: float) -> int:
    base = {
        "Intro": 68,
        "Progression I": 82,
        "Progression II": 90,
        "Theme Reprise": 96,
        "Breakdown": 60,
        "Development": 82,
        "Climax": 112,
        "Outro": 54,
    }[section]
    if section == "Development":
        base += round(position * 22)
    if section == "Outro":
        # Match the intro's expression value at the loop seam.  The perceived
        # outro comes from the thinning arrangement, not a fade to silence.
        base += round(position * 14)
    return max(35, min(120, base))


def add_theme(track: MidiTrack, cue: Cue, start_bar: int, velocity: int,
              rng: random.Random, variant: int = 0) -> None:
    for beat, duration, pitch in theme_notes(cue):
        if variant == 1 and beat >= 8:
            pitch += 12
        elif variant == 2:
            pitch = cue.root + 31 - (pitch - (cue.root + 12))
        track.note(start_bar * BAR + round(beat * TPQ), round(duration * TPQ * 0.92),
                   pitch, velocity, 7, rng)


def add_secondary_motif(track: MidiTrack, cue: Cue, start_bar: float,
                        motif_key: str, velocity: int, rng: random.Random,
                        octave: int = 12, variant: int = 0) -> None:
    """States one character motif without changing its identifying rhythm."""
    articulation = 0.76 if cue.cue_kind == "boss" else 0.90
    for beat, duration, degree in SECONDARY_MOTIFS[motif_key]:
        adjusted = degree
        if cue.major_resolution and degree == 3:
            adjusted = 4
        if variant == 1 and beat >= 4:
            adjusted += 12
        elif variant == 2:
            adjusted = 7 - adjusted
        pitch = cue.root + octave + adjusted
        track.note(
            round(start_bar * BAR + beat * TPQ),
            max(1, round(duration * TPQ * articulation)),
            pitch, velocity, 6, rng,
        )


def add_secondary_statement(tracks: dict[str, MidiTrack], cue: Cue,
                            section: str, section_start: int,
                            section_length: int, rng: random.Random) -> None:
    """Places the cue's character motif as dialogue, medley, or solo identity."""
    if section not in (
        "Intro", "Progression II", "Breakdown", "Development", "Climax"
    ):
        return

    block_count = max(1, section_length // 8)
    velocity = min(118, dynamics(section, 0.5) + (8 if cue.cue_kind == "boss" else 0))
    section_end = section_start + section_length
    for block in range(block_count):
        block_bar = section_start + block * 8
        if block_bar + 4 > section_end:
            break

        if cue.secondary_theme == "horizon_dialogue":
            if cue.voice_order == "selkie_first":
                first_track, first_key = tracks["lead"], "selkie_answer"
                second_track, second_key = tracks["counter"], "moon_call"
            else:
                first_track, first_key = tracks["lead"], "moon_call"
                second_track, second_key = tracks["counter"], "selkie_answer"
            add_secondary_motif(first_track, cue, block_bar, first_key, velocity, rng)
            add_secondary_motif(
                second_track, cue, block_bar + 2, second_key,
                max(50, velocity - 8), rng,
            )
            if section == "Climax" and block_bar + 8 <= section_end:
                # They stop merely alternating and finally reach at once.
                add_secondary_motif(first_track, cue, block_bar + 4, first_key,
                                    min(120, velocity + 3), rng, variant=1)
                add_secondary_motif(second_track, cue, block_bar + 4, second_key,
                                    min(116, velocity), rng, variant=1)
            continue

        if cue.secondary_theme == "mira_aisha_medley":
            if cue.voice_order == "aisha_first":
                add_secondary_motif(tracks["counter"], cue, block_bar, "aisha", velocity, rng)
                add_secondary_motif(tracks["lead"], cue, block_bar + 2, "mira",
                                    max(50, velocity - 6), rng)
            else:
                add_secondary_motif(tracks["lead"], cue, block_bar, "mira", velocity, rng)
                add_secondary_motif(tracks["counter"], cue, block_bar + 2, "aisha",
                                    max(50, velocity - 6), rng)
            if block_bar + 8 <= section_end:
                # The second half is a medley proper: both complete identities
                # overlap without being flattened into one hybrid melody.
                add_secondary_motif(tracks["lead"], cue, block_bar + 4, "mira",
                                    min(120, velocity + 2), rng, variant=1)
                add_secondary_motif(tracks["counter"], cue, block_bar + 4, "aisha",
                                    velocity, rng, variant=2)
            continue

        motif_key = cue.secondary_theme
        add_secondary_motif(tracks["lead"], cue, block_bar, motif_key, velocity, rng)
        add_secondary_motif(
            tracks["counter"], cue, block_bar + 2, motif_key,
            max(46, velocity - 16), rng, octave=0, variant=2,
        )
        if cue.cue_kind == "boss" and block_bar + 8 <= section_end:
            add_secondary_motif(tracks["lead"], cue, block_bar + 4, motif_key,
                                min(120, velocity + 4), rng, variant=1)


def compose_cue(cue: Cue) -> list[MidiTrack]:
    rng = random.Random(8000 + cue.number)
    conductor = MidiTrack("Arrangement & Markers")
    mpqn = round(60_000_000 / cue.tempo)
    conductor.events.append((0, 1, meta(0x51, mpqn.to_bytes(3, "big"))))
    conductor.events.append((0, 1, meta(0x58, bytes((4, 2, 24, 8)))))
    conductor.events.append((0, 1, meta(0x59, bytes((255, 1)))))  # one flat, minor
    conductor.add_meta(
        0, 0x01,
        f"Original score: {cue.title}. Four-measure Horizon Theme. "
        f"Secondary leitmotif: {SECONDARY_THEME_NAMES[cue.secondary_theme]}.",
    )
    for name, start, length in section_map(cue):
        conductor.add_meta(start * BAR, 0x06, f"{name} ({length} bars)")
    # Keep Logic's imported project at the exact musical loop boundary even
    # though the turnaround pickup releases slightly before it.
    conductor.add_meta(cue.bars * BAR, 0x06, "LOOP END / RETURN TO BAR 1")

    tracks = {
        "piano": MidiTrack("01 Studio Grand Piano", 0, 0),
        "harpsichord": MidiTrack("02 Harpsichord / Clockwork", 1, 6),
        "strings": MidiTrack("03 Studio Strings", 2, 48),
        "organ": MidiTrack("04 Pipe Organ", 3, 19),
        # Acoustic Bass (GM 33) requires an optional Logic sound pack on a
        # default install.  Synth Bass 1 maps to Logic's installed Retro Synth
        # family and keeps every project self-contained.
        "bass": MidiTrack("05 Neo-Gothic Synth Bass", 4, 38),
        "lead": MidiTrack(f"06 Lead - {cue.lead_name}", 5, cue.lead_program),
        "bells": MidiTrack("07 Tubular Bells / Celesta", 6, 14),
        "counter": MidiTrack(f"08 Countervoice - {cue.counter_name}", 7, cue.counter_program),
        "drums": MidiTrack("09 Drum Kit & Orchestral Percussion", 9, None),
    }

    pans = {"piano": 54, "harpsichord": 35, "strings": 78, "organ": 64,
            "bass": 64, "lead": 48, "bells": 88, "counter": 80, "drums": 64}
    volumes = {"piano": 96, "harpsichord": 79, "strings": 91, "organ": 80,
               "bass": 94, "lead": 102, "bells": 76, "counter": 84, "drums": 96}
    for key, track in tracks.items():
        track.cc(0, 7, volumes[key])
        track.cc(0, 10, pans[key])
        track.cc(0, 91, 40 if key in ("bass", "drums") else 70)

    for section, section_start, section_length in section_map(cue):
        for key, track in tracks.items():
            gain = dynamics(section, 0.0)
            track.cc(section_start * BAR, 11, max(30, min(127, gain + (8 if key == "lead" else 0))))
            track.cc((section_start + section_length) * BAR - 1, 11,
                     max(25, min(127, dynamics(section, 1.0))))

        progression = progression_for(cue, section)
        for local_bar in range(section_length):
            bar = section_start + local_bar
            bar_tick = bar * BAR
            degree, quality = progression[local_bar % len(progression)]
            harmony = chord(cue.root + degree, quality)
            intensity = dynamics(section, local_bar / max(1, section_length - 1))
            if cue.cue_kind == "boss":
                intensity = min(120, intensity + 6)

            # Sustained strings and organ make the harmony readable beneath the
            # denser keyboard writing. Breakdown removes the strings.
            if section != "Breakdown" or local_bar % 2 == 0:
                for pitch in harmony:
                    tracks["strings"].note(bar_tick, BAR - 24, pitch + 12,
                                           max(42, intensity - 24), 2, rng)
            if bar % 2 == 0:
                for pitch in harmony[:3]:
                    tracks["organ"].note(bar_tick, BAR * 2 - 36, pitch,
                                         max(38, intensity - 28), 2, rng)

            # Piano arpeggios connect one progression to the next by retaining
            # upper chord tones across bar lines.
            arp = (0, 1, 2, len(harmony) - 1, 1, 2, 0, 2)
            for step, index in enumerate(arp):
                pitch = harmony[index] + 12 + (12 if step in (3, 7) else 0)
                tracks["piano"].note(bar_tick + step * TPQ // 2, TPQ * 2 // 5,
                                     pitch, max(40, intensity - 10), 8, rng)

            # Harpsichord/celesta becomes the shooter-like motor, but leaves air
            # in intro, breakdown, and outro.
            subdivisions = 8 if section in ("Breakdown", "Outro") else 16
            if section == "Intro" and cue.cue_kind != "boss":
                subdivisions = 8
            for step in range(subdivisions):
                if section == "Breakdown" and step % 2:
                    continue
                pitch = harmony[(step * 2 + bar) % len(harmony)] + 24
                tracks["harpsichord"].note(
                    bar_tick + step * BAR // subdivisions,
                    max(40, BAR // subdivisions * 3 // 5), pitch,
                    max(34, intensity - 28), 5, rng)

            bass_pattern = (0, 0, 2, 0)
            for beat, chord_index in enumerate(bass_pattern):
                pitch = harmony[min(chord_index, len(harmony) - 1)] - 12
                tracks["bass"].note(bar_tick + beat * TPQ, round(TPQ * 0.82),
                                    pitch, max(44, intensity - 12), 5, rng)

            # Bells articulate formal seams and forge/orrery identities.
            if local_bar % 4 == 0 or cue.style.startswith(("forge", "orrery")) and local_bar % 2 == 0:
                bell_pitch = harmony[-1] + 24
                tracks["bells"].note(bar_tick, round(TPQ * 1.8), bell_pitch,
                                     max(45, intensity - 18), 4, rng)

            # Drum language grows from restrained pulse into arcade propulsion.
            if section not in ("Intro", "Breakdown", "Outro") or local_bar >= 4:
                for eighth in range(8):
                    tracks["drums"].note(bar_tick + eighth * TPQ // 2, TPQ // 5,
                                         42 if eighth % 2 == 0 else 44,
                                         max(32, intensity - 26), 4, rng)
                for beat in (0, 2):
                    tracks["drums"].note(bar_tick + beat * TPQ, TPQ // 3, 36,
                                         max(46, intensity - 10), 3, rng)
                for beat in (1, 3):
                    tracks["drums"].note(bar_tick + beat * TPQ, TPQ // 3, 38,
                                         max(42, intensity - 14), 3, rng)
                if section in ("Climax", "Theme Reprise") and local_bar % 4 == 0:
                    tracks["drums"].note(bar_tick, TPQ, 49, min(120, intensity + 4))
                if cue.style == "forge" and local_bar % 2 == 1:
                    tracks["drums"].note(bar_tick + TPQ * 3, TPQ // 2, 47,
                                         max(44, intensity - 8), 2, rng)
                if cue.cue_kind == "boss" and local_bar % 2 == 0:
                    tracks["drums"].note(bar_tick + TPQ // 2, TPQ // 3, 51,
                                         max(42, intensity - 18), 2, rng)

        # The theme recurs across the form rather than appearing once as a logo.
        if section in ("Progression I", "Progression II", "Theme Reprise", "Climax", "Outro"):
            statements = max(1, section_length // 8)
            for statement in range(statements):
                theme_bar = section_start + statement * 8
                if theme_bar + 4 <= section_start + section_length:
                    variant = 1 if section == "Climax" and statement % 2 else 0
                    add_theme(tracks["lead"], cue, theme_bar,
                              min(118, dynamics(section, statement / max(1, statements))), rng, variant)
                    if section in ("Progression II", "Theme Reprise", "Climax"):
                        add_theme(tracks["counter"], cue, theme_bar + 4,
                                  max(52, dynamics(section, 0.5) - 18), rng, 2)

        if section == "Breakdown":
            add_theme(tracks["piano"], cue, section_start,
                      dynamics(section, 0.0), rng, 0)

        add_secondary_statement(tracks, cue, section, section_start, section_length, rng)

    # A restrained final-bar pickup makes the wrap musically explicit.  Its
    # last note releases before the boundary; bar 1 resolves it on the tonic.
    pickup_tick = (cue.bars - 1) * BAR
    pickup_third = 4 if cue.major_resolution else 3
    for beat, degree in ((2.0, 2), (2.5, pickup_third), (3.0, 7)):
        tracks["lead"].note(
            pickup_tick + round(beat * TPQ), round(TPQ * 0.42),
            cue.root + 12 + degree, 58, 3, rng)

    return [conductor, *tracks.values()]


def write_midi(cue: Cue, tracks: list[MidiTrack]) -> Path:
    path = MIDI_DIR / f"{cue.number:02d}_{cue.slug}.mid"
    header = b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), TPQ)
    path.write_bytes(header + b"".join(track.chunk() for track in tracks))
    return path


def write_cue_sheet(cue: Cue) -> Path:
    path = CUE_DIR / f"{cue.number:02d}_{cue.slug}.md"
    sections = section_map(cue)
    lines = [
        f"# {cue.title}", "", f"- Role: {cue.role}",
        f"- Cue kind: {cue.cue_kind}",
        f"- Tempo: {cue.tempo} BPM", f"- Meter: 4/4", f"- Length: {cue.bars} bars / {cue.seconds:.1f} seconds",
        f"- Tonal center MIDI note: {cue.root}", f"- Production character: {cue.style}",
        f"- Secondary leitmotif: {SECONDARY_THEME_NAMES[cue.secondary_theme]}", "",
        "## Arrangement", "", "| Section | Start bar | Bars |", "| --- | ---: | ---: |",
    ]
    for name, start, length in sections:
        lines.append(f"| {name} | {start + 1} | {length} |")
    lines.extend([
        "", "## Editable instrument parts", "",
        "1. Studio Grand Piano", "2. Harpsichord / clockwork keyboard", "3. Studio Strings",
        "4. Pipe Organ", "5. Neo-Gothic Synth Bass", f"6. Lead - {cue.lead_name}",
        "7. Tubular Bells / Celesta", f"8. Countervoice - {cue.counter_name}",
        "9. Drum Kit and orchestral percussion", "",
        "## Leitmotif treatment", "",
    ])
    if cue.secondary_theme == "horizon_dialogue":
        lines.extend([
            "Moon's open-fifth call and Selkie's circling answer occupy separate lead voices. They alternate first, then overlap in the climax; the cue's route identity determines who calls first.", "",
        ])
    elif cue.secondary_theme == "mira_aisha_medley":
        lines.extend([
            "Mira's reaching wish-sigil cell and Aisha's symmetrical four-suit cell are stated independently, alternate in the first half of each medley block, and overlap without losing their individual contours.", "",
        ])
    else:
        lines.extend([
            f"The character-specific {SECONDARY_THEME_NAMES[cue.secondary_theme]} cell appears intact, as a lower-register answer, and in a heightened boss variation where applicable.", "",
        ])
    lines.extend([
        "## Loop contract", "",
        "The Outro is a composed dominant turnaround into bar 1, not a fade-out. Its ending expression matches the Intro, and the lossless master is bounced to the exact bar boundary with normalization and audio-tail extension disabled.", "",
        "The Logic project retains note-level MIDI, per-track expression, pan, reverb send, markers, tempo, and program metadata.",
    ])
    path.write_text("\n".join(lines) + "\n")
    return path


def main() -> None:
    for directory in (MIDI_DIR, CUE_DIR, PROJECT_DIR, MASTER_DIR, RAW_BOUNCE_DIR):
        directory.mkdir(parents=True, exist_ok=True)

    # These two folders are generated catalogs. Remove renamed cue artifacts so
    # an old numbering scheme cannot masquerade as an additional score track.
    expected_midi = {f"{cue.number:02d}_{cue.slug}.mid" for cue in CUES}
    expected_sheets = {f"{cue.number:02d}_{cue.slug}.md" for cue in CUES}
    for path in MIDI_DIR.glob("*.mid"):
        if path.name not in expected_midi:
            path.unlink()
    for path in CUE_DIR.glob("*.md"):
        if path.name not in expected_sheets:
            path.unlink()

    manifest = {"leitmotifs": {
        "primary": {
            "name": "Horizon Theme", "key_center": "D minor",
            "measures": 4,
            "notes": ["D", "F", "A", "C", "A", "G", "F", "E", "A", "D", "C", "A", "F", "E", "G", "Bb", "A", "G", "E", "D"],
        },
        "secondary_families": {
            "horizon_dialogue": {
                "name": SECONDARY_THEME_NAMES["horizon_dialogue"],
                "voices": ["Moon call", "Selkie answer"],
                "use": "Moon, Selkie, title, ending, credits, and other unassigned cues",
            },
            "shalmii": {"name": SECONDARY_THEME_NAMES["shalmii"], "voices": ["Shalmii"]},
            "aster": {"name": SECONDARY_THEME_NAMES["aster"], "voices": ["Aster"]},
            "mira_aisha_medley": {
                "name": SECONDARY_THEME_NAMES["mira_aisha_medley"],
                "voices": ["Mira wish-sigil", "Aisha four-suit"],
            },
            "caelia": {"name": SECONDARY_THEME_NAMES["caelia"], "voices": ["Caelia"]},
        },
    }, "cues": []}

    for cue in CUES:
        tracks = compose_cue(cue)
        midi_path = write_midi(cue, tracks)
        cue_path = write_cue_sheet(cue)
        manifest["cues"].append({
            "number": cue.number, "slug": cue.slug, "title": cue.title,
            "role": cue.role, "tempo_bpm": cue.tempo, "bars": cue.bars,
            "runtime_sound_id": RUNTIME_SOUND_IDS[cue.number],
            "cue_kind": cue.cue_kind,
            "secondary_leitmotif": SECONDARY_THEME_NAMES[cue.secondary_theme],
            "secondary_theme_id": cue.secondary_theme,
            "voice_order": cue.voice_order,
            "duration_seconds": round(cue.seconds, 3), "midi_tracks": len(tracks) - 1,
            "loop_start_seconds": 0.0, "loop_end_seconds": round(cue.seconds, 3),
            "loop_mode": "exact_bar_boundary_dominant_turnaround",
            "midi": str(midi_path.relative_to(PRODUCTION)),
            "cue_sheet": str(cue_path.relative_to(PRODUCTION)),
            "logic_project": f"logic_projects/{cue.number:02d}_{cue.slug}.logicx",
            "lossless_master": f"masters/{cue.number:02d}_{cue.slug}.wav",
        })

    (PRODUCTION / "score_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Composed {len(CUES)} Logic-ready arrangements in {MIDI_DIR}")
    for cue in CUES:
        print(f"  {cue.number:02d} {cue.title}: {cue.bars} bars, {cue.seconds:.1f}s, 9 instruments")


if __name__ == "__main__":
    main()

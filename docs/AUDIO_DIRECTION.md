# Audio Direction

## Primary leitmotif: Horizon Theme

Every cue carries the four-measure **Horizon Theme**. In D minor its contour is:

`D-F-A-C-A | G-F-E-A-D | C-A-F-E-G | Bb-A-G-E-D`

The original eight-note placeholder phrase remains the opening thought, but it
now grows into a complete four-measure statement. The latter half reaches above
the first phrase and returns to D without merely reversing it. Ending and
credits treatments may brighten the minor third while preserving the contour.

The influence palette is Yuki Kajiura, ZUN, Yoko Shimomura, Nobuo Uematsu,
Takumi Ozawa, Kyohei Ozawa, Ryo Furukawa, Yasuhisa Inoue, Naoki "naotyu-"
Chiba, Tatsuhiko Saiki, Kenji Katoh, Masayoshi Iimori, and Manabu Namiki. The
score draws only on their broad vocabulary of melodic counterpoint, theatrical
harmony, rhythmic urgency, tightly articulated percussion and bass motion, and
orchestral/electronic instrumentation. It remains an original work and does not
quote or closely imitate any particular composition.

## Secondary leitmotifs

Secondary motifs identify characters without replacing the Horizon Theme.
Each is a distinct two-measure cell that can be stated, answered, fragmented,
or combined.

| Identity | Motif | Dramatic use |
| --- | --- | --- |
| Moon and Selkie | Two Voices Beyond the Horizon | Moon's open-fifth call and Selkie's circling answer trade the foreground, then overlap. Route cues change who calls first. |
| Shalmii | Anvil Oath | Repeated hammer attacks open into a firm rising vow. |
| Aster | Saltwind Ribbon | A continuous rising ribbon curls back through bright, close intervals. |
| Mira | Wish-Sigil | A reaching, asymmetrical contour that repeatedly redraws its destination. |
| Aisha | Four Suits | A symmetrical jewel-like figure built from two balanced arcs. |
| Caelia | Bloodstar Orrery | A tritone glint circles a dark tonal center like an unforgiving mechanism. |

Mira and Aisha keep separate melodic identities. Their stage and dual-boss
cues form a medley: each motif is stated alone, the two alternate, and their
complete contours eventually overlap without collapsing into one generic duet.

The Moon/Selkie dialogue also belongs to cues without one assigned character:
title, ending, and credits. Moon-led and Selkie-led final-stage cues are separate,
as are the Moon and Selkie final-boss cues.

## Production cue catalog

| No. | Use | Music-room title | Secondary treatment |
| ---: | --- | --- | --- |
| 01 | Title / opening | A Promise Across the Horizon | Moon calls, Selkie answers |
| 02 | Stage 1 / Shalmii | The Forge at Dusk | Anvil Oath |
| 03 | Boss / Shalmii | Iron Vow beneath the Ember Moon | Heightened Anvil Oath |
| 04 | Stage 2 / Aster | Ribbon over Saltwind | Saltwind Ribbon |
| 05 | Boss / Aster | Tidebound Lace in Revolt | Heightened Saltwind Ribbon |
| 06 | Stage 3 / Mira and Aisha | A Covenant in Four Suits | Mira-led medley |
| 07 | Dual boss / Mira and Aisha | Wish and Suit, Entwined | Aisha-led medley and overlap |
| 08 | Stage 4 / Caelia | Orrery of the Bloodstar | Bloodstar Orrery |
| 09 | Boss / Caelia | Red Orbit of the Unforgiving Star | Heightened Bloodstar Orrery |
| 10 | Stage 5 / Moon route | Violets beneath Moon's Sunset | Moon-led call and answer |
| 11 | Final boss / Moon | Rose-Eternity at the Edge of Morning | Moon-led overlap |
| 12 | Stage 5 / Selkie route | Violets upon Selkie's Sunrise | Selkie-led call and answer |
| 13 | Final boss / Selkie | Chakram Apotheosis before Daybreak | Selkie-led overlap |
| 14 | Ending | Where Morning Finds the Moon | Selkie calls, Moon answers |
| 15 | Credits | Until We Meet Again | Moon calls, Selkie answers, then reunion |

Each production cue is 2-4 minutes, grows longer as the game progresses, uses
nine editable instrument parts, and contains an intro, two linked progressions,
repeated material, a breakdown, development, climax, and composed outro. The
outro is a dominant turnaround into bar 1 rather than a fade.

## Runtime routing

`GameStageMusicTrackGet` owns the five stage assignments. Stage 5 chooses the
Moon-led or Selkie-led cue from the playable route. `GameBossMusicTrackGet` owns
the guardian assignments; at the finale it chooses the cue for the opposing
heroine. `GameGameplayMusicTrackGet` switches to the boss cue for intro, fight,
outro, and boss-cleared states, so a stage loop never restarts over the victory
transition.

The Music Room exposes all fifteen production cue slots. All slots currently use
the validated production masters recorded by `loop_validation.json`; the short
motif-correct audition generator remains available for production experiments
but is not the current runtime source.

## Sound-effect language

- Moon shots and sword sounds climb through rose-like thirds.
- Selkie shots and chakram sounds arc around open fifths.
- Enemy fire uses shorter, sharper fragments in the same pitch family.
- Boss arrivals use the theme in the low organ register; phase changes answer
  with stained-glass bells.
- Bombs bloom upward from low D into the full D-minor seventh color.
- Stage clear states the motif directly and reaches one step farther upward.
- Mechanical UI/type sounds are clockwork bell strikes rather than neutral clicks.

## Runtime mixing

`config.sav` stores `master_volume`, `music_volume`, and `sfx_volume` as integer
percentages from 0 through 100. Options changes them in five-point steps, applies
them immediately, and draws a meter in both the title and pause settings pages.
Master gain multiplies both category gains.

`GameAudioVolumesApply` owns runtime mixing. `GameAudioMusicAssetsCreate` and
`GameAudioSfxAssetsCreate` are the authoritative category lists; new assets must
be placed into exactly one of them.

## Production workflow

Generate and validate the editable score sources:

```sh
python3 tools/build_logic_score_midi.py
python3 tools/validate_logic_score.py
```

Open each format-1 MIDI file in Logic Pro, retain all nine software-instrument
tracks and arrangement markers, and save the editable project to the manifest's
`logic_project` path. Instrument patches, articulation, automation, mixing, and
sound design are production decisions made in that project; the MIDI remains
the note-level source of truth. Those manifest-named `.logicx` files are not
present in this checkout even though the validated lossless masters and runtime
encodes are present; see `PROJECT_STATE.md` for the current gap.

For each cue, bounce exactly two uninterrupted cycles as stereo 24-bit PCM with
normalization and audio-tail extension disabled. Then run:

```sh
python3 tools/finalize_logic_loops.py --require-all
```

This extracts the second pass so reverb, delay, and synth state already match a
real loop, applies a 5 ms seam correction, writes the lossless master, and emits
machine-readable seam validation. `score_manifest.json` maps every cue to its
GameMaker `runtime_sound_id`.

Encode all validated masters as high-quality stereo 48 kHz Oggs, install them
into the streamed GameMaker resources, and synchronize duration metadata with:

```sh
python3 tools/install_logic_masters.py
```

To regenerate the short in-engine audition loops and the SFX suite, use a Python
environment with NumPy:

```sh
python3 tools/build_audio_assets.py
```

That placeholder generator is not the production music source.

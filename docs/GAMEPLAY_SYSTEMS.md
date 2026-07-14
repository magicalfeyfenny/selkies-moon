# Gameplay Systems

## Input

`obj_input_manager` polls in Begin Step so every normal Step sees the same snapshot. Keyboard and controller inputs are combined into verbs:

| Verb | Keyboard | Controller | Use |
| --- | --- | --- | --- |
| movement | arrows | D-pad or left stick | Player and menus |
| `fire` | Z | A / face 1 | Volley, held sword charge, confirm |
| `bomb` | X | B / face 2 | Bomb, cancel/back |
| `autofire` | C | X / face 3 | Focused movement and fire |
| `pause` | Escape or P | Start | Pause or title confirm |

The last active device owns analog movement and prompt identity. A neutral controller snapshot clears released analog movement without losing the last-device label.

## Run and stage state

Normal and practice runs share `global.game_runtime`. `GameRunStartInitialize()` resets attempt-scoped values. Normal runs start at stage 1, power 0, three lives, three bombs, meter 0, and rank 50. Practice applies its normalized request and does not record starts, clears, scores, or continues.

`obj_scene_manager.scene_state.mode` is the stage state machine:

| Mode | Behavior |
| --- | --- |
| `scroll` | Camera advances, timeline/director waves run |
| `boss_intro` | Combat actors are cleared; route-specific boss dialogue may run |
| `boss_fight` | Boss owns completion |
| `boss_outro` | Post-defeat dialogue holds the scene before stage clear |
| `stage_clear` | Delay, then advance, end practice, or enter ending |

The camera's X target follows the player within a bounded drag region. The visible playfield remains centered inside the 640x360 GUI, leaving side gutters for the HUD.

## Rank

Rank is clamped to 0-100 and defaults to 50. It affects spawn intervals, enemy fire intervals, and enemy bullet speed. It does not change enemy health, player damage, or boss phase count.

Positive play events and uninterrupted combat raise rank; deaths and continues lower it. Practice may lock rank. `GameRankPressureCreate()` is the single conversion from rank to the three cadence/speed multipliers.

## Player weapons

Both ships use normalized shot specifications, then `obj_player` creates `obj_player_shot` instances:

- Moon/Sunset has the balanced wide pattern and a long sword sweep.
- Selkie/Sunrise has a wider normal crescent and a tighter focused lance.
- Power ranges from 0-5 and changes damage, scale, and color accents.
- Tapped/held fire produces volleys until the hold threshold turns into a sword wind-up.
- Focused autofire bypasses sword charging.

The sword is a swept arc, not one point sample. Each sweep has an ID, and each target records the last sweep that hit it, preventing repeated damage from one animation.

## Damage, death, and continue

Player damage is ignored during invulnerability, death animation, bombs, dialogue, pause, and continue flow. A death reduces rank and lives. With lives remaining, the player respawns at the camera-relative start position. With no lives, the Continue overlay takes ownership.

Accepting a continue restores default lives/bombs, clears meter, lowers rank, increments continues, and respawns. Declining enters a delayed game-over mode, records eligible normal-run results, resets runtime, and returns to title.

## Bullets, bombs, cancel meter, and Berserk

Every enemy bullet inherits `obj_bullet_parent`, which applies this order:

1. freeze guard;
2. active bomb cancellation;
3. cancelled-bullet medal conversion;
4. movement;
5. camera-distance culling.

Blade bullets replace linear motion with spiral or redirected motion after the inherited guard. Sword and bomb cancellation mark bullets; conversion happens in the bullet's own Step.

Medals add score and cancel meter. At 1,000 meter, Berserk begins and cancels all bullets. While active, only the enhanced sword is available. Meter drains over time, and the ending transition cancels bullets again.

Bombs consume stock, run for 60 frames, cancel bullets throughout their active window, and render a growing bloom around the player.

## Enemies

`obj_enemy_parent` owns freeze, damage, defeat, score, pickup attempts, and default motion. Children only add specialized behavior:

- turret: aimed bead shots;
- bee: pursuit drift and three-speed aligned diamond bursts;
- mayfly: camera-lane drop, figure-eight drift, alternating blade spirals;
- variant: moth, kelp, wisp, needle, and mirror patterns scaled by stage.

Steady defeat cadence drops score pickups. A point-blank defeat adds recharge toward a bounded resource drop. Resource type selection accounts for current stock/power and a per-stage cap.

## Bosses

`GameBossEncounterInfoCreate()` returns:

- visual identity;
- display and ship names;
- final and character-boss flags;
- opponent ship for the final encounter;
- draw orientation;
- phase plan and signature.

Boss plans always demonstrate the complete seed set first, followed by complete variant sets and one boss-exclusive final attack:

| Encounter tier | Seeds | Variant sets | Signature finale | Total phases |
| --- | ---: | ---: | ---: | ---: |
| Stages 1-2 | 2 | 1 | 1 | 5 |
| Stages 3-6 | 3 | 1 | 1 | 7 |
| Stages 7-9 | 4 | 1 | 1 | 9 |
| Stage 10 route finale | 5 | 2 | 1 | 16 |

Every stage owns a pattern family. Character encounters use motifs from the character instead of retaining the abstract Core pattern that previously occupied the stage slot:

| Stage | Encounter | Pattern family | Seed demonstrations | Unique finale |
| ---: | --- | --- | --- | --- |
| 1 | Tideglass Core | Tideglass | Spiral; Fan | Maelstrom |
| 2 | Mira / Wildheart | Poker | Four Suits; Dealer Fan | Royal Flush |
| 3 | Saltwind Core | Saltwind | Gale; Spindrift; Needles | Eye |
| 4 | Kelp Core | Kelp | Snare; Bramble; Wall | Abyssal Bloom |
| 5 | Shalmii / Lockstep | Hex runes and hammer | Hex Runes; Hammerfall; Shockwave | Runebreaker |
| 6 | Aisha / Wishbound | Order, chaos, and talismans | Order Circle; Chaos Shards; Talisman Seal | Blade of Desires |
| 7 | Aster / Ribbonstar | Ribbons, bunny arcs, and winged staff | Ribbon Loop; Bunny Hop; Winged Staff; Lavender Knot | Ribbonstar Wish |
| 8 | Bloodtide Core | Bloodtide | Pulse; Rip; Hunt; Deluge | Heart |
| 9 | Caelia / Zenith | Astral orrery | Planetary Orbit; Constellation; Astrolabe; Star Cage | Cosmic Zenith |
| 10 | Moon or Selkie | Rose or chakram | Five route-specific seeds | Rose Eternity or Chakram Apotheosis |

A finale is appended after expansion and is never used as a seed or variant. Expanded phase HP and damage scaling keep total endurance near the original curve while giving each phase enough time to express its pattern. Portrait, dialogue, and ship sprites remain presentation data, so replacing provisional character art does not require changing an attack plan.

Each phase descriptor schedules a `shot_kind`, cadence, burst size, angles, speeds, spread, optional redirect interval, and theme. `scr_boss_patterns` provides shared bullet-spawn primitives, but each boss-family interpreter owns its complete attack geometry. Generic `blade_spiral`, `redirect_spiral`, and `blade_cross` attacks use coherent rings, offset counter-rotation, and layered four-arm crosses respectively. `diamond_fan` uses speed-tiered chevron wings while `bead_arc` remains an evenly spaced aimed fan.

For the first 120 active frames of every phase, the gameplay HUD formats the descriptor `id` as a readable attack title. The banner uses the shared ornate story-panel frame, outlined name typography, pearl-and-rose ornaments, and the attack family's accent color. Its timer pauses with gameplay overlays, with a 12-frame fade in and 30-frame fade out.

## Pickups

| Type | Effect |
| --- | --- |
| score | Adds 5,000 points |
| power | Raises shot power to 5 |
| bomb | Restores a bomb to 6 |
| life | Restores a life to 6 |
| meter | Adds 240 cancel meter |

Score pickups use a diamond silhouette. Earned resource pickups use a ring silhouette and magnetize toward the player within their collection radius.

## Pause and practice

Pause is a real gameplay freeze signal. Dialogue and Continue block pause because they already own confirm/cancel input. Pause can change display settings, confirm a return to title, and—in practice—edit live power, rank, lives, bombs, and meter or restart the selected segment.

Practice configuration is normalized at every boundary. Starting, restarting, completing, or returning to title retains the setup without contaminating persistent run statistics.

## Story and ending

Opening and ending rooms auto-start their default story files. Stages 2, 5, 6, 7, and 9 queue a Mira, Shalmii, Aisha, Aster, or Caelia introduction for the active route, run that character's motif-specific phase plan, then hold in `boss_outro` for route-specific defeat dialogue. Practice skips both seams. Stage 10 queues its route-specific introduction inside `rm_game`, so completion does not change rooms before combat. After the final boss, the scene enters the ending; ending completion records the run before credits cache the result. Credits reset runtime only when they finish or are skipped.

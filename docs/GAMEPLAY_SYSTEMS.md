# Gameplay Systems

## Input

`obj_input_manager` polls in Begin Step so every normal Step sees the same snapshot. Keyboard and controller inputs are combined into verbs:

| Verb | Keyboard | Controller | Use |
| --- | --- | --- | --- |
| movement | arrows | D-pad or left stick | Player and menus |
| `fire` | Z | A / face 1 | Volley, held sword charge, confirm |
| `bomb` | X | B / face 2 | Bomb, cancel/back |
| `autofire` | C | X / face 3 | Continuous fire in the current focus state |
| `focus` | Shift | LB / L1 | Focused fire and slower movement while held |
| `pause` | Escape or P | Start | Pause or title confirm |

The last active device owns analog movement and prompt identity. A neutral controller snapshot clears released analog movement without losing the last-device label. Title Options exposes separate scrolling remap pages for keyboard and gamepad. Remaps persist in `config.sav`, duplicate assignments preserve every action by swapping the displaced binding, and controller hot-plug remains active while a gamepad page listens. The left stick remains an analog movement source while its four digital direction verbs can be rebound.

## Run and stage state

Normal and practice runs share `global.game_runtime`. `GameRunStartInitialize()` resets attempt-scoped values. Normal runs start at stage 1, power 0, three lives, three bombs, meter 0, and rank 0. Practice applies its normalized request and does not record starts, clears, scores, or continues.

`obj_scene_manager.scene_state.mode` is the stage state machine:

| Mode | Behavior |
| --- | --- |
| `scroll` | Camera advances and the data-driven stage roster runs |
| `boss_intro` | Combat actors are cleared; route-specific boss dialogue may run |
| `boss_fight` | Boss owns completion |
| `boss_outro` | Post-defeat dialogue holds the scene before stage clear |
| `stage_clear` | Delay, then advance, end practice, or enter ending |

The camera's X target follows the player within a bounded drag region. The visible playfield remains centered inside the 640x360 GUI, leaving side gutters for the HUD.

## Rank

Rank is clamped to 0-50. Fresh normal runs and fresh Practice setups start at 0, while Practice remains configurable. Rank affects spawn intervals, enemy fire intervals, and enemy bullet speed. It does not change enemy health, player damage, or boss phase count.

Uninterrupted combat raises rank by one every ten seconds, every twelve ordinary shootdowns add one point, and boss defeats or entering Hyper raise it more sharply. Only bombing, dying, and continuing lower it. Practice may lock rank. `GameRankPressureCreate()` is the single conversion from rank to the three cadence/speed multipliers.

## Player weapons

Both ships use normalized shot specifications, then `obj_player` creates `obj_player_shot` instances:

- Moon/Sunset has the balanced wide pattern and a long sword sweep.
- Selkie/Sunrise has a wider normal crescent and a tighter focused lance.
- Power ranges from 0-5 and changes damage, scale, and color accents.
- Tapped/held fire produces volleys until the hold threshold turns into a sword wind-up.
- Autofire bypasses sword charging and follows the independent held-focus state.

The sword is a swept arc, not one point sample. Each sweep has an ID, and each target records the last sweep that hit it, preventing repeated damage from one animation.

## Damage, death, and continue

Player damage is ignored during invulnerability, death animation, bombs, dialogue, pause, and continue flow. A death reduces rank and lives. With lives remaining, the player respawns at the camera-relative start position. With no lives, the Continue overlay takes ownership.

Accepting a continue restores default lives/bombs, clears meter, lowers rank, increments continues, and respawns. Declining enters a delayed game-over mode, records eligible normal-run results, resets runtime, and returns to title.

## Bullets, bombs, medals, and Berserk

Every enemy bullet inherits `obj_bullet_parent`, which applies this order:

1. freeze guard;
2. active bomb cancellation;
3. cancelled-bullet medal conversion;
4. movement;
5. camera-distance culling.

Blade bullets replace linear motion with spiral or redirected motion after the inherited guard. Sword and bomb cancellation mark bullets; conversion happens in the bullet's own Step.

The single Berserk meter replaces the old Cancel and point-blank resource bars. Sustained attacks add a very slow trickle, damaging hits inside Selkie's 108-pixel chakram reach add substantially more, and collected medals add eight points each. Small enemies release one or two medals; anchors and dancers release five to ten; every defeated boss phase releases five to ten. Drops launch in a short radial shower before homing so large rewards never look like one stacked pickup.

At 1,000 meter, Berserk begins automatically, cancels every onscreen enemy bullet, and grants three frames of invulnerability. While active, every manual, autofire, focused, and unfocused attack becomes a larger, twice-as-fast route-specific sweep: Selkie uses chakrams and Moon uses a rose whip. Berserk sweeps deal twice the already-enhanced normal sword damage, and the meter drains over time without a second cancel when it ends.

Bombs consume stock, run their cancel/rosette effect for 60 frames, and grant 120 frames of invulnerability. Player death is a pearl-and-petal firework rather than a collision-like red disc.

## Enemies

`obj_enemy_parent` owns freeze, damage, defeat, score, pickup attempts, and default motion. The live director spawns four `obj_enemy_variant` identities authored for each stage. Chasers make one pass from above and permanently commit downward when the player is absent or behind; anchors enter and hold a lane; dancers follow camera-relative curves; lancers make fast straight passes. Every enemy bullet turns to its actual direction of travel, including spiral blades.

| Stage | Basic-enemy roster | Redistributed pattern ideas |
| ---: | --- | --- |
| 1: Shalmii | Forge Spark, Anvil Familiar, Bellows Imp, Hammer Cherub | Tideglass fan/spiral; shockwave; hammerfall |
| 2: Aster | Ribbon Hare, Winged Staff, Lavender Knot, Saltwind Pinwheel | gale; kelp wall; ribbon loop; spindrift |
| 3: Mira & Aisha | Spade Familiar, Dealer Mask, Order Talisman, Chaos Shard | three-card monte; loaded dice; spell circles; mirrored hexes |
| 4: Caelia | Clockwork Planet, Astrolabe Eye, Constellation Lance, Bloodstar Heart | Bloodtide pulse/hunt; astrolabe; constellation |
| 5: Moon or Selkie | Violet Bee, Twilight Mayfly, Thorn Reliquary, Chakram Seraph | thorn arc; petal spiral; rose bloom; chakram orbit |

The legacy turret, bee, mayfly, and generic variant objects remain only as isolated regression fixtures; the live stage director never spawns them. Violet Bee and Twilight Mayfly are new stage-five identities with new sprites and dedicated projectile art.

Steady defeat cadence drops score pickups and sparsely awards bounded stock/power resources. Point-blank play now belongs exclusively to the visible Berserk economy. Resource type selection still accounts for current stock/power and a per-stage cap.

## Bosses

`GameBossEncounterInfoCreate()` returns:

- visual identity;
- display and ship names;
- final and character-boss flags;
- opponent ship for the final encounter;
- draw orientation;
- phase plan and signature.

There are five stages and no abstract Memory Core boss encounters. Their useful pattern ideas are redistributed across the basic-enemy roster, while the seven named girls retain encounter identity:

| Stage | Encounter | Pattern family | Seed demonstrations | Unique finale |
| ---: | --- | --- | --- | --- |
| 1 | Shalmii / Lockstep | Hex runes and blacksmith hammerwork | Hex Runes; Hammerfall; Shockwave | Runebreaker (3 phases total) |
| 2 | Aster / Ribbonstar | Ribbons, bunny arcs, and winged staff | Ribbon Loop; Bunny Hop; Winged Staff; Lavender Knot | Ribbonstar Wish (5 phases total) |
| 3 | Mira & Aisha / Wildheart and Wishbound | Mira's casino trickery paired with Aisha's stage sorcery | Three-Card Monte; Loaded Dice; Arcane Circle; Mirrored Hex | House Always Wins and Grand Sorcery (3 personal phases each), then Sisters' Grand Illusion |
| 4 | Caelia / Zenith | Astral orrery | Planetary Orbit; Constellation; Astrolabe; Star Cage | Cosmic Zenith (7 phases total) |
| 5 | Moon or Selkie | Rose or chakram | Route-specific seeds | Rose Eternity or Chakram Apotheosis (15 phases total) |

A finale is appended after expansion and is never used as a seed or variant. Mira and Aisha are the exception only in encounter flow: after both three-phase personal plans have been defeated, the sisters reform for one additional synchronized casino-and-sorcery attack backed by a shared life pool. Expanded phase HP and damage scaling keep total endurance near the original curve while giving each phase enough time to express its pattern. Portrait, dialogue, and ship sprites remain presentation data, so replacing provisional character art does not require changing an attack plan.

Each phase descriptor schedules a `shot_kind`, cadence, burst size, angles, speeds, spread, optional redirect interval, and theme. `scr_boss_patterns` provides shared bullet-spawn primitives, but each boss-family interpreter owns its complete attack geometry. Generic `blade_spiral`, `redirect_spiral`, and `blade_cross` attacks use coherent rings, offset counter-rotation, and layered four-arm crosses respectively. `diamond_fan` uses speed-tiered chevron wings while `bead_arc` remains an evenly spaced aimed fan.

For the first 120 active frames of every phase, the gameplay HUD formats the descriptor `id` as a readable attack title. The banner uses the shared ornate story-panel frame, outlined name typography, pearl-and-rose ornaments, and the attack family's accent color. Its timer pauses with gameplay overlays, with a 12-frame fade in and 30-frame fade out.

## Pickups

| Type | Effect |
| --- | --- |
| score | Adds 5,000 points |
| power | Raises shot power to 5 |
| bomb | Restores a bomb to 6 |
| life | Restores a life to 6 |
| meter | Adds 240 Berserk meter |

Score pickups use a diamond silhouette. Earned resource pickups use a ring silhouette and magnetize toward the player within their collection radius.

## Pause and practice

Pause is a real gameplay freeze signal. Dialogue and Continue block pause because they already own confirm/cancel input. Pause can change display settings and the persisted Master, Music, and SFX meters, confirm a return to title, and—in practice—edit live power, rank, lives, bombs, and Berserk meter or restart the selected segment. All three audio values range from 0 to 100 in five-point steps, apply immediately, and clamp instead of wrapping.

Practice configuration is normalized at every boundary. Starting, restarting, completing, or returning to title retains the setup without contaminating persistent run statistics. Practice never opens the Continue prompt; a terminal practice death returns to title. Character Select explains the charge, focused fire, bomb, and Hyper loop and animates each ship demonstrating its attacks.

The production score and effects share the melodic and interval language in
`AUDIO_DIRECTION.md`; music is routed by room, character stage, boss state, and
finale route while every one-shot enters through a semantic helper.

## Story and ending

Opening and ending rooms auto-start their default story files. Stages 1-4 queue Shalmii, Aster, Mira and Aisha together, then Caelia; each uses route-specific introduction and defeat dialogue around its motif-specific fight. Mira and Aisha's combined files explicitly establish their sisterhood and frame their final spell as sibling coordination rather than a new character encounter. Practice skips both seams. Stage 5 queues the Moon-or-Selkie confrontation inside `rm_game`, preserving Sunset chasing Sunrise as the spine of both yuri routes. After the final boss, the scene enters the ending; ending completion records the run before credits cache the result. Credits reset runtime only when they finish or are skipped.

## Background and draw hierarchy

The old violet tile layer is hidden. `obj_scene_manager` submits true-3D modular models and camera-facing texture billboards in Draw Begin, then restores the 2D matrices and disables depth testing before any actor renders. Three adjacent 64-unit copies cover both looping camera paths while compact prebuilt vertex buffers avoid runtime OBJ parsing. The editable Blender sources, packed 1024px texture atlases, layered Krita sources, and triangulated OBJ files remain beside the runtime buffers. The mesh quadrants contain authored forge metal, forest floor and bark, Vegas carpet and velvet, nebular/orbit materials, or dense violet-and-vine surfaces—not UV-debug checker fills.

Each chapter owns two compatible slow looping camera paths: the travel route and a second downward-moving boss route with the same loop seam. Shalmii descends through a blacksmith citadel of furnaces, anvils, chimneys, tools, and molten channels; Aster passes a moonrabbit forest of trees, burrows, mushrooms, logs, and rabbit topiary; Mira and Aisha divide a Vegas illusion stage between roulette/card machinery and curtains, hats, wands, and sorcery rings; Caelia crosses deep space among planets, asteroids, nebulae, galaxy cores, and observatory pylons; Moon and Selkie fly over an endless field of modeled violets, hero flowers, and vine walls. High-resolution billboards extend each location to its horizon, while quantized shader light and ordered fog stipple preserve the 640x360 pixel display grid.

Background scroll never changes collision or spawn coordinates. The 2D gameplay camera still stops for a boss, but the separate 3D presentation clock continues through intro dialogue, combat, and outro while it blends between routes. Background atmosphere remains in Draw Begin. Broad sword, bomb, and death effects draw next; the player ship draws beneath enemy bullets, while its tiny pearl hitbox draws in Draw End above them. Menu backgrounds use silhouettes of all seven girls as decorators.

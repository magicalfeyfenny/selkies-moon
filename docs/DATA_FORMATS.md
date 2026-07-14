# Data Formats

## Story JSON

Story files live in `datafiles/` and must also appear in the project's `IncludedFiles` list. The root may be an array of frames or a struct with a `frames` array.

Each frame accepts:

~~~json
{
  "name": "Moon",
  "text": "Dialogue text.",
  "backgrounds": ["spr_dialogue_bg_core"],
  "portraits": ["spr_moon_portrait"],
  "positions": ["center"]
}
~~~

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `name` | string | `""` | Speaker label |
| `text` | string | `""` | Dialogue body |
| `backgrounds` | string array | `[]` | Sprites drawn in array order |
| `portraits` | string array | `[]` | Portrait sprite asset names |
| `positions` | string array | generated | `left`, `center`, or `right` per portrait |

Missing assets fall back safely: backgrounds are skipped and portraits become stable colored placeholder cards. Text is normalized to at most two lines and clamped with an ellipsis.

Background order matters. Later entries draw over earlier entries. Portraits draw after every background.

Character-boss story files use `<story_id>_<seam>_story_<route>.json`. The seam is `intro` or `defeat`, and the route is `moon_route` or `selkie_route`. Mira (`story_id` `mira`) occupies Stage 2, Shalmii (`shalmii`) Stage 5, Aisha (`aisha`) Stage 6, Aster (`aster`) Stage 7, and Caelia (`caelia`) Stage 9. Each set references its matching portrait sprite; `GameCharacterBossStoryFileGet()` selects the file from the character registry, route, and whether the fight has ended. Story and portrait references do not appear in phase descriptors, so either can be replaced without changing boss mechanics.

## Persistence JSON

`game.sav`:

~~~json
{
  "version": 2,
  "high_score": {
    "ship_A": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "ship_selkie": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  },
  "runs_started": {},
  "runs_finished": {},
  "continues_used": {}
}
~~~

All four stat tables use ten-entry descending/parallel arrays. The score array is sorted; the continues row is inserted at the matching score index. Ship tables may gain new keys, and migration preserves any recognized per-ship arrays.

`config.sav` contains `version`, `view_width`, `view_height`, `target_fps`, `display_scale`, `fullscreen`, and `input_device`.

Never change a persisted shape without updating its version, default factory, validator, migration, and tests.

## Boss phase descriptors

Boss plans are arrays of structs created by `GameMemoryCorePhaseCreate()`:

| Field | Meaning |
| --- | --- |
| `id` | Unique phase identifier; variants append `_vN` and finales append `_finale` |
| `shot_kind` | Interpreter case in `scr_boss_patterns` |
| `cadence` | Base frames between bursts before rank pressure |
| `burst_count` | Pattern-specific projectile count |
| `base_angle` | Starting direction or rotating center |
| `angle_step` | Angular change multiplied by phase timer |
| `speed` | Base linear bullet speed |
| `turn_speed` | Spiral blade angular speed |
| `radial_speed` | Spiral blade outward speed |
| `spread` | Fan width in degrees |
| `redirect_interval` | Frames between blade redirects, or 0 |
| `attack_theme` | Family color/identity used by bullets and the attack-title banner |

Every `shot_kind` must have one explicit runtime interpreter case. Unknown values log a warning and fire nothing. Phase signatures include all behavior fields and are used by regression tests to enforce unique plans.

Current themes are `tideglass`, `saltwind`, `kelp`, and `bloodtide` for abstract Cores; `poker`, `rune`, `desire`, `ribbon`, and `astral` for character bosses; and `rose` or `chakram` for the route finale. Plan construction must preserve this order:

1. every base seed in declaration order;
2. every `_v1` phase in the same order;
3. every `_v2` phase when used by a route-final boss;
4. one non-repeated `_finale` phase.

## Practice configuration

Practice requests contain:

- `ship_id` and `ship_index`;
- `stage` from 1-10;
- `segment`: `full`, `waves`, or `boss`;
- `power` from 0-5;
- `rank` from 0-100;
- `dynamic_rank` boolean;
- `lives` and `bombs` from 0-6;
- `meter` from 0-1,000.

Always pass external or UI-edited practice data through `GamePracticeConfigNormalize()` before storing or applying it.

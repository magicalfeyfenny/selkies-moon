# Asset Pipelines

Load this guide only for asset, audio, 3D, or visual-QA work. Runtime code tasks
should stay within the source owners routed by `ARCHITECTURE.md`.

Generated runtime assets must remain reproducible from their named editable
source or deterministic generator. Do not hand-edit binary PNG, audio, Krita,
Blender, MIDI, or archive files. Review the generator, source manifest, runtime
metadata, and `.yyp` registration as one contract.

## 2D art and portraits

| Tool | Ownership |
| --- | --- |
| `tools/build_gameplay_art.py` | final-stage Violet Bee, Twilight Mayfly, bullets, and portrait-derived menu silhouettes |
| `tools/build_layered_enemy_art.py` | layered enemy sources and exports |
| `tools/build_core_pixel_art.py` | core PC-98-style sprites, attacks, UI, and pickups |
| `tools/build_story_pixel_backgrounds.py` | story background sources and runtime exports |
| `tools/build_font_source_sheets.py` | editable font source sheets |
| `tools/regenerate_character_portraits.py` | portrait generation from its declared source inputs |
| `tools/build_runtime_sprite_source_catalog.py` | exact one-layer editable mirrors of remaining historical runtime frames |

The matching manifests under `art/` are generated source indexes for asset work;
they are not general architecture indexes and should not be loaded for unrelated
tasks. Run a generator only when its owned outputs are in scope, then compare
file counts, dimensions, registration, and deterministic rerun results.

## 3D stages

`tools/blender_build_stage_scenes.py` runs inside Blender and owns five packed
native scenes, editable travel/boss camera curves, billboard proxies, and
triangulated OBJ exports. `tools/build_3d_stage_textures.py` creates layered
Krita texture sources and runtime atlases.

`tools/build_stage3d_runtime_buffers.py` compiles the portable OBJ streams into
GameMaker-ready vertex buffers; it does not replace the OBJ deliverables. Native
3D rendering remains in `obj_scene_manager` Draw Begin so gameplay, effects,
bullets, hitboxes, and UI do not inherit its matrices or depth state.

## Audio

`tools/build_logic_score_midi.py` owns note-level score sources, arrangement,
primary theme, and secondary leitmotifs. `tools/validate_logic_score.py` checks
loop boundaries, duration, instrument count, section metadata, and motif
identity. The full musical contract is in [`AUDIO_DIRECTION.md`](AUDIO_DIRECTION.md).

The checkout currently contains 15 validated lossless score masters and 15
runtime encodes. `tools/finalize_logic_loops.py` validates two-cycle Logic
bounces and extracts the second pass; `tools/install_logic_masters.py` is the
supported installer for runtime streamed encodes and duration metadata. The
manifest-named editable `.logicx` project files are not present; see
[`PROJECT_STATE.md`](PROJECT_STATE.md#known-incomplete-or-intentionally-limited-work).

`tools/build_logic_sfx_suite.py`, `tools/install_logic_sfx.py`, and the SFX
manifest own the production sound-effect path. `tools/build_audio_assets.py`
deterministically rebuilds short audition placeholders and a generated SFX
suite; it is not the production-score source and must not overwrite validated
masters during unrelated work.

Use an environment with NumPy for the Python audio generators. Validate source
MIDI with:

```zsh
python3 tools/validate_logic_score.py
```

Run the specific installer or generator only when its inputs and owned outputs
are explicitly in task scope.

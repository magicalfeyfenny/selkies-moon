# Asset Pipeline and Source Authority

This policy defines which editable file may change an asset and which files are
derived for interchange or the game. Git LFS is a storage mechanism only: an
LFS-tracked derivative does not become a master.

## Canonical master formats

Each production asset has one canonical master family:

| Asset family | Sole canonical master | Derived contract |
| --- | --- | --- |
| 3D models and scenes | Blender `.blend` | OBJ plus MTL for portable exchange; VBUFF for the current GameMaker runtime cache |
| Raster images | Krita `.kra` | PNG for GameMaker and other runtime consumers |
| Music and sound effects | Logic Pro `.logicx` project | WAV for lossless interchange and runtime SFX; OGG for runtime music |

Do not promote an OBJ, MTL, PNG, WAV, OGG, VBUFF, MIDI file, cue sheet, or
manifest into a competing authoring source. If a derivative must be repaired,
repair the canonical master or the exporter and rebuild it.

Immutable original sketches, licensed sources, and other declared reference
material may remain as `reference-only`. They inform the canonical master but
must never be overwritten by a normal build or loaded as an undeclared runtime
substitute.

## 3D: Blender to OBJ/MTL to VBUFF

The `.blend` scene is the sole editable authority for geometry, object
placement, materials, and other 3D authoring decisions. Routine export must
open the existing scene without saving over it. Procedural scene construction
is a separately named bootstrap or migration operation and must never replace
an existing master implicitly.

OBJ and MTL together are the portable 3D export contract: OBJ carries geometry,
normals, texture coordinates, and material assignments; MTL carries portable
material declarations. The current `tools/blender_build_stage_scenes.py`
exporter emits a geometry-only OBJ stream and does not emit MTL. That is
truthful for the current atlas-driven stages. Any future export that carries
materials must emit and reference a matching MTL instead of treating OBJ alone
as a material-preserving format.

`tools/build_stage3d_runtime_buffers.py` compiles the current OBJ stream into
VBUFF files. `scr_stage_3d` loads those VBUFF files with `buffer_load()` and
creates frozen GameMaker vertex buffers from them. VBUFF is therefore the
current compiled runtime cache, not an editable 3D source. OBJ and MTL remain
portable derivatives and should not be packaged merely to duplicate a VBUFF.
The current GameMaker YYP still registers the five OBJ exports as Included
Files even though runtime code loads only VBUFF. Removing those registrations
is a known packaging follow-up and is outside the LFS history rewrite.

## Raster: Krita to PNG

Every shipped raster family has one declared `.kra` master. PNGs flow one way
from that KRA through the manifest-owned exporter. A normal export may render,
crop, scale, pack, validate, and atomically install declared PNG targets, but it
must not draw replacement production pixels, regenerate a KRA, or copy runtime
pixels back into a master.

Legacy ORA files may be retained only when explicitly classified as migration
evidence or reference material. They are not parallel production masters.
GameMaker root frames and editor-layer PNGs are both runtime derivatives of the
same KRA.

## Audio: Logic to WAV/OGG

The native Logic `.logicx` project is the sole canonical master for each music
cue and sound-effect production project. It owns performance, instrumentation,
patches, articulation, automation, sound design, arrangement, and mixing.

Music is bounced to lossless WAV for validation and then encoded to streamed
OGG for GameMaker. Sound effects are bounced or sliced to lossless WAV and
installed as runtime WAV. These WAV and OGG files are derivatives even when a
workflow calls a WAV a "lossless master" in the delivery sense; the Logic
project remains the only editable source authority.

MIDI catalogs, cue sheets, score/SFX manifests, loop reports, hashes, and
installation reports are bootstrap, routing, and validation metadata. They are
valuable reproducibility contracts, but they do not compete with the Logic
project as the master. Change musical or sound-design intent in Logic, then
update or validate the metadata and rebuild the runtime files.

See [Audio Direction](AUDIO_DIRECTION.md) for the musical, bounce, loop, and
mixer contracts.

## Version control and validation

All audited binary asset families are stored through Git LFS, including the
canonical masters, required runtime derivatives, portable interchange files,
legacy/reference binaries, fonts, MIDI bootstrap files, and every file inside
a Logic package. See [Git LFS Migration](LFS_MIGRATION.md) for the coordinated
history rewrite and immutable release anchor.

Before accepting an asset change:

1. identify the canonical master and its manifest owner;
2. rebuild into staging where the tool supports it;
3. validate dimensions, formats, hashes or decoded content, and ownership;
4. confirm that no normal build modified a canonical master;
5. inspect changed visual or audio output; and
6. run `git diff --check` and the relevant GameMaker tests before integration.

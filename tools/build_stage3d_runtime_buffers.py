"""Compile Blender's editable OBJ stage exports into fast GameMaker vertex buffers.

The OBJ files remain the portable interchange assets.  These raw buffers contain
the same triangulated position/normal/UV stream in the exact format consumed by
GameMaker's vertex_create_buffer_from_buffer function.
"""

from __future__ import annotations

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"
DATAFILES = PROJECT / "datafiles"
MANIFEST = ROOT / "art" / "3d_stage_sources" / "stage_3d_scene_manifest.json"


def compile_obj(source: Path, destination: Path) -> tuple[int, int]:
    vertex = None
    texcoord = None
    count = 0

    with source.open("r", encoding="utf-8") as obj, destination.open("wb") as output:
        for line in obj:
            if line.startswith("v "):
                vertex = tuple(float(value) for value in line.split()[1:4])
            elif line.startswith("vt "):
                texcoord = tuple(float(value) for value in line.split()[1:3])
            elif line.startswith("vn "):
                normal = tuple(float(value) for value in line.split()[1:4])
                if vertex is None or texcoord is None:
                    raise ValueError(f"Malformed interleaved OBJ stream in {source}")
                output.write(struct.pack("<8f", *vertex, *normal, *texcoord))
                count += 1
                vertex = None
                texcoord = None

    if count % 3:
        raise ValueError(f"Vertex count is not a triangle list in {source}: {count}")
    return count, destination.stat().st_size


def main() -> None:
    scenes = json.loads(MANIFEST.read_text(encoding="utf-8"))
    compiled = []

    for scene in scenes:
        obj_path = DATAFILES / scene["runtime_obj"]
        buffer_name = obj_path.with_suffix(".vbuff").name
        buffer_path = DATAFILES / buffer_name
        vertices, byte_count = compile_obj(obj_path, buffer_path)
        if vertices != scene["triangles"] * 3:
            raise ValueError(
                f"Triangle mismatch for stage {scene['stage']}: "
                f"manifest={scene['triangles']}, buffer={vertices // 3}"
            )
        compiled.append({
            "stage": scene["stage"],
            "source_obj": scene["runtime_obj"],
            "runtime_buffer": buffer_name,
            "vertex_format": ["position_3d", "normal", "texcoord"],
            "stride_bytes": 32,
            "vertices": vertices,
            "triangles": vertices // 3,
            "bytes": byte_count,
        })

    output = ROOT / "art" / "3d_stage_sources" / "stage_3d_runtime_buffer_manifest.json"
    output.write_text(json.dumps(compiled, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(compiled)} GameMaker 3D vertex buffers.")


if __name__ == "__main__":
    main()

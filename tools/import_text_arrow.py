#!/usr/bin/env python3
"""Import thpj3's animated text arrow and make a layered Krita source."""

from __future__ import annotations

import json
import re
import shutil
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"
SOURCE = Path(
    "/Users/magicalfeyfenny/GameMakerProjects/thpj3/sprites/spr_text_arrow"
)
RUNTIME = PROJECT / "sprites" / "spr_text_arrow"
EDITABLE = ROOT / "art" / "imported_runtime_sources" / "sprites" / "spr_text_arrow"


def source_frame_names(sprite_text: str) -> list[str]:
    frames_block = sprite_text.split('"frames":[', 1)[1].split('],', 1)[0]
    names = re.findall(r'"name":"([0-9a-f-]{36})"', frames_block)
    if len(names) != 8:
        raise RuntimeError(f"Expected eight text-arrow frames, found {len(names)}")
    return names


def runtime_sprite_text(sprite_text: str) -> str:
    parent_pattern = re.compile(
        r'"parent":\{\s*"name":"[^"]+",\s*"path":"[^"]+",?\s*\},'
    )
    replacement = (
        '"parent":{\n'
        '    "name":"Selkies Moon",\n'
        '    "path":"Selkies Moon.yyp",\n'
        '  },'
    )
    updated, count = parent_pattern.subn(replacement, sprite_text, count=1)
    if count != 1:
        raise RuntimeError("Could not replace source sprite parent")
    return updated


def write_layered_ora(frame_paths: list[Path]) -> None:
    layer_lines = []
    # Reverse XML order so frame 00 remains the bottom/base layer in Krita.
    for index in reversed(range(len(frame_paths))):
        visibility = "visible" if index == 0 else "hidden"
        layer_lines.append(
            f'    <layer name="{escape(f"Frame {index:02d} - 3 fps")}" '
            f'src="data/frame_{index:02d}.png" visibility="{visibility}" '
            'opacity="1.0"/>'
        )
    stack = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<image version="0.0.1" w="64" h="64" name="spr_text_arrow_frames">\n'
        '  <stack name="Animation Frames">\n'
        + "\n".join(layer_lines)
        + '\n  </stack>\n</image>\n'
    )

    ora_path = EDITABLE / "spr_text_arrow_frames.ora"
    with zipfile.ZipFile(ora_path, "w") as archive:
        archive.writestr(
            "mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED
        )
        archive.writestr("stack.xml", stack, compress_type=zipfile.ZIP_DEFLATED)
        for index, frame in enumerate(frame_paths):
            archive.write(
                frame,
                f"data/frame_{index:02d}.png",
                compress_type=zipfile.ZIP_DEFLATED,
            )
        archive.write(
            frame_paths[0], "mergedimage.png", compress_type=zipfile.ZIP_DEFLATED
        )


def main() -> None:
    sprite_path = SOURCE / "spr_text_arrow.yy"
    if not sprite_path.is_file():
        raise FileNotFoundError(sprite_path)

    sprite_text = sprite_path.read_text(encoding="utf-8")
    frame_names = source_frame_names(sprite_text)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    EDITABLE.mkdir(parents=True, exist_ok=True)

    (RUNTIME / "spr_text_arrow.yy").write_text(
        runtime_sprite_text(sprite_text), encoding="utf-8"
    )
    runtime_layers = RUNTIME / "layers"
    runtime_layers.mkdir(parents=True, exist_ok=True)

    editable_frames = []
    for index, frame_name in enumerate(frame_names):
        source_frame = SOURCE / f"{frame_name}.png"
        runtime_frame = RUNTIME / source_frame.name
        editable_frame = EDITABLE / f"frame_{index:02d}.png"
        shutil.copy2(source_frame, runtime_frame)
        shutil.copy2(source_frame, editable_frame)
        editable_frames.append(editable_frame)

        source_layers = SOURCE / "layers" / frame_name
        if source_layers.is_dir():
            shutil.copytree(
                source_layers,
                runtime_layers / frame_name,
                dirs_exist_ok=True,
                ignore=shutil.ignore_patterns(".DS_Store"),
            )

    write_layered_ora(editable_frames)
    (EDITABLE / "manifest.json").write_text(
        json.dumps(
            {
                "sprite": "spr_text_arrow",
                "provenance": (
                    "Exact import from thpj3/sprites/spr_text_arrow; source "
                    "sequence and 3 fps timing preserved."
                ),
                "source_size": [64, 64],
                "runtime_scale": 0.5,
                "frames": [
                    {
                        "frame": index,
                        "source_name": frame_name,
                        "runtime_png": str(
                            (RUNTIME / f"{frame_name}.png").relative_to(ROOT)
                        ),
                        "editable_png": str(
                            (EDITABLE / f"frame_{index:02d}.png").relative_to(ROOT)
                        ),
                    }
                    for index, frame_name in enumerate(frame_names)
                ],
                "openraster_source": str(
                    (EDITABLE / "spr_text_arrow_frames.ora").relative_to(ROOT)
                ),
                "layers": [f"Frame {index:02d} - 3 fps" for index in range(8)],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    (EDITABLE / "README.md").write_text(
        "# spr_text_arrow editable source\n\n"
        "Exact eight-frame import from `thpj3/sprites/spr_text_arrow`.\n\n"
        "- `spr_text_arrow_frames.ora` exposes every animation frame as a layer.\n"
        "- Frames retain the source sequence and its authored 3 fps playback.\n"
        "- The 64x64 source is drawn at 50% in Selkie's Moon for its 640x360 UI.\n",
        encoding="utf-8",
    )
    print(f"Imported {len(frame_names)} frames to {RUNTIME}")


if __name__ == "__main__":
    main()

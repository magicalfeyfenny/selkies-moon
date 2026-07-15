"""Import every still-used legacy GameMaker sprite into an editable layer file.

Newly authored assets already have richer multi-layer sources and are skipped.
Each remaining runtime frame is mirrored exactly into a one-layer OpenRaster
document ready for the native Krita batch-save pass. This preserves historical
art without treating a reconstruction as its source of truth.
"""

from __future__ import annotations

import json
import shutil
import struct
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"
SPRITES = PROJECT / "sprites"
OUTPUT = ROOT / "art" / "imported_runtime_sources" / "sprites"


def covered_sprites() -> set[str]:
    paths = (
        ROOT / "art/enemy_sources/enemy_source_manifest.json",
        ROOT / "art/core_pixel_sources/core_pixel_source_manifest.json",
        ROOT / "art/story_background_sources/story_background_manifest.json",
        ROOT / "art/3d_stage_sources/textures/stage_3d_texture_manifest.json",
    )
    covered: set[str] = set()
    for path in paths:
        payload = json.loads(path.read_text(encoding="utf-8"))
        entries = payload.get("scenes", []) if isinstance(payload, dict) else payload
        for entry in entries:
            if "sprite" in entry:
                covered.add(entry["sprite"])
    return covered


def png_size(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG frame: {path}")
    return struct.unpack(">II", header[16:24])


def write_ora(source: Path, destination: Path, layer_name: str) -> None:
    width, height = png_size(source)
    stack = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<image version="0.0.1" w="{width}" h="{height}" name="{escape(destination.stem)}">\n'
        '  <stack name="root">\n'
        f'    <layer name="{escape(layer_name)}" src="data/imported_runtime_pixels.png" visibility="visible" opacity="1.0"/>\n'
        '  </stack>\n'
        '</image>\n'
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, "w") as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        archive.writestr("stack.xml", stack)
        archive.write(source, "data/imported_runtime_pixels.png", compress_type=zipfile.ZIP_DEFLATED)
        archive.write(source, "mergedimage.png", compress_type=zipfile.ZIP_DEFLATED)


def main() -> None:
    covered = covered_sprites()
    manifest = []
    for sprite_dir in sorted(path for path in SPRITES.iterdir() if path.is_dir()):
        sprite = sprite_dir.name
        if sprite in covered:
            continue
        frames = sorted(sprite_dir.glob("*.png"))
        if not frames:
            continue

        source_dir = OUTPUT / sprite
        frame_entries = []
        for index, frame in enumerate(frames):
            stem = f"frame_{index:02d}"
            imported_png = source_dir / f"{stem}_imported_runtime.png"
            ora = source_dir / f"{stem}.ora"
            source_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(frame, imported_png)
            write_ora(imported_png, ora, "Imported Runtime Pixels")
            width, height = png_size(frame)
            frame_entries.append({
                "frame": index,
                "runtime_png": str(frame.relative_to(ROOT)),
                "imported_png": str(imported_png.relative_to(ROOT)),
                "openraster_source": str(ora.relative_to(ROOT)),
                "krita_source": str(ora.with_suffix(".kra").relative_to(ROOT)),
                "size": [width, height],
                "layers": ["Imported Runtime Pixels"],
            })
        manifest.append({
            "sprite": sprite,
            "provenance": "Exact import of prior runtime pixels; no redesign or generated render authority.",
            "frames": frame_entries,
        })

    OUTPUT.mkdir(parents=True, exist_ok=True)
    output = OUTPUT.parent / "sprite_source_manifest.json"
    output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Imported {sum(len(item['frames']) for item in manifest)} frames from {len(manifest)} legacy sprites.")


if __name__ == "__main__":
    main()

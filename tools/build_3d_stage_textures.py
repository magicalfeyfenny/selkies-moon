#!/usr/bin/env python3
"""Build layered Krita-ready pixel textures for the five 3D stage environments."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

from build_gameplay_art import ROOT, install_sprite
from build_core_pixel_art import composite, layer, write_ora


SOURCE = ROOT / "art" / "3d_stage_sources" / "textures"
SIZE = (256, 256)


THEMES = {
    1: ("forge", "tex_stage3d_01", (44, 24, 43), (119, 48, 48), (229, 92, 42), (246, 184, 83), (92, 82, 111)),
    2: ("saltwind", "tex_stage3d_02", (35, 36, 76), (102, 80, 143), (214, 117, 187), (111, 215, 207), (230, 220, 199)),
    3: ("wishcourt", "tex_stage3d_03", (25, 14, 46), (83, 35, 96), (214, 74, 158), (76, 185, 220), (244, 202, 112)),
    4: ("orrery", "tex_stage3d_04", (16, 12, 38), (49, 30, 78), (184, 50, 92), (105, 178, 223), (241, 197, 91)),
    5: ("violet_garden", "tex_stage3d_05", (24, 14, 48), (75, 41, 101), (194, 76, 166), (70, 168, 117), (249, 205, 112)),
}


def checker(draw: ImageDraw.ImageDraw, box, left, right, step: int = 8) -> None:
    x0, y0, x1, y1 = box
    draw.rectangle(box, fill=left)
    for y in range(y0, y1 + 1, step):
        for x in range(x0, x1 + 1, step):
            if ((x - x0) // step + (y - y0) // step) % 2:
                draw.rectangle((x, y, min(x1, x + step - 1), min(y1, y + step - 1)), fill=right)


def build_texture(stage: int) -> tuple[dict[str, Image.Image], list[str]]:
    name, _, ink, mid, accent, cool, gold = THEMES[stage]
    names = ["base_materials", "masonry", "dither_texture", "stage_motifs", "emissive_details", "highlights"]
    layers = {layer_name: layer(SIZE) for layer_name in names}
    base = ImageDraw.Draw(layers["base_materials"])
    masonry = ImageDraw.Draw(layers["masonry"])
    motif = ImageDraw.Draw(layers["stage_motifs"])
    emission = ImageDraw.Draw(layers["emissive_details"])
    highlight = ImageDraw.Draw(layers["highlights"])

    # Four authored atlas quadrants: floor, architecture, accent props, foliage/emission.
    checker(base, (0, 0, 127, 127), (*ink, 255), (*mid, 255), 16)
    checker(base, (128, 0, 255, 127), (*mid, 255), (*ink, 255), 12)
    checker(base, (0, 128, 127, 255), (*accent, 255), (*mid, 255), 16)
    checker(base, (128, 128, 255, 255), (*cool, 255), (*ink, 255), 8)

    # Masonry seams and textile ribs remain on a separate paintable layer.
    for y in range(8, 128, 16):
        masonry.line((0, y, 127, y), fill=(*gold, 160), width=1)
        for x in range((y // 16 % 2) * 16, 128, 32):
            masonry.line((x, y - 8, x, y + 8), fill=(*gold, 110), width=1)
    for x in range(136, 256, 16):
        masonry.line((x, 0, x, 127), fill=(*cool, 120), width=1)

    # Ordered stipple gives distance surfaces PC-98 texture without filtering.
    pixels = layers["dither_texture"].load()
    bayer = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    for y in range(256):
        for x in range(256):
            rank = bayer[y % 4][x % 4]
            if rank == 0:
                pixels[x, y] = (*gold, 52)
            elif rank == 15 and y >= 128:
                pixels[x, y] = (*ink, 72)

    if name == "forge":
        for cx, cy in ((32, 160), (95, 208), (53, 235)):
            motif.polygon([(cx, cy - 18), (cx + 11, cy), (cx + 5, cy + 18),
                           (cx - 5, cy + 18), (cx - 11, cy)], fill=(*accent, 255), outline=(*gold, 255))
        for y in range(144, 256, 24):
            emission.line((136, y, 248, y - 10), fill=(*accent, 220), width=3)
    elif name == "saltwind":
        for offset in range(4):
            points = [(0, 148 + offset * 22 + ((x // 16) % 2) * 7) for x in range(0, 128, 16)]
            points = [(x, 148 + offset * 22 + ((x // 16) % 2) * 7) for x in range(0, 128, 16)]
            motif.line(points, fill=(*(accent if offset % 2 == 0 else cool), 235), width=4)
        for x in range(140, 256, 18):
            emission.line((x, 140, x + 10, 246), fill=(*gold, 150), width=2)
    elif name == "wishcourt":
        suits = [(32, 163), (94, 163), (32, 224), (94, 224)]
        for index, (cx, cy) in enumerate(suits):
            if index % 2 == 0:
                motif.polygon([(cx, cy - 18), (cx + 16, cy), (cx, cy + 18), (cx - 16, cy)],
                              fill=(*(accent if index == 0 else cool), 255), outline=(*gold, 255))
            else:
                motif.ellipse((cx - 16, cy - 16, cx + 16, cy + 16),
                              fill=(*(cool if index == 1 else accent), 255), outline=(*gold, 255), width=2)
        for x in range(140, 250, 22):
            emission.polygon([(x, 148), (x + 8, 160), (x, 172), (x - 8, 160)], fill=(*gold, 210))
    elif name == "orrery":
        for cx, cy, radius in ((34, 163, 22), (94, 205, 27), (42, 239, 13)):
            motif.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(*gold, 255), width=2)
            motif.ellipse((cx - radius, cy - radius // 2, cx + radius, cy + radius // 2), outline=(*cool, 255), width=1)
            motif.point((cx + radius - 2, cy), fill=(*accent, 255))
        for y in range(143, 255, 20):
            emission.line((136, y, 252, 256 - y // 2), fill=(*cool, 180), width=1)
    else:
        # Violet petals and continuous thorn-vine bands are the final-stage signature.
        for x in range(8, 124, 20):
            motif.line((x, 254, x + ((x // 20) % 3 - 1) * 8, 144), fill=(*cool, 255), width=3)
            cx, cy = x + ((x // 20) % 3 - 1) * 8, 154 + ((x * 7) % 48)
            for dx, dy in ((-6, 0), (6, 0), (0, -6), (0, 6), (-4, -4)):
                motif.rectangle((cx + dx - 3, cy + dy - 3, cx + dx + 3, cy + dy + 3), fill=(*accent, 255))
            motif.rectangle((cx - 2, cy - 2, cx + 2, cy + 2), fill=(*gold, 255))
        for y in range(144, 256, 16):
            emission.line((132, y, 252, y - 11), fill=(*cool, 175), width=2)
            for x in range(144, 248, 24):
                emission.polygon([(x, y - 4), (x + 5, y), (x, y + 4)], fill=(*accent, 210))

    highlight.line((1, 1, 126, 1), fill=(255, 244, 218, 210), width=1)
    highlight.line((129, 129, 254, 129), fill=(*gold, 190), width=1)
    return layers, names


def main() -> None:
    manifest = []
    for stage, (theme, sprite, *_palette) in THEMES.items():
        layers, order = build_texture(stage)
        merged = composite(layers, order)
        stage_dir = SOURCE / f"stage_{stage:02d}_{theme}"
        stage_dir.mkdir(parents=True, exist_ok=True)
        for name, image in layers.items():
            image.save(stage_dir / f"{name}.png")
        merged.save(stage_dir / f"{theme}_runtime_texture.png")
        ora = stage_dir / f"{theme}_texture.ora"
        write_ora(ora, layers, order, merged)
        install_sprite(sprite, merged)
        manifest.append({
            "stage": stage,
            "theme": theme,
            "sprite": sprite,
            "openraster_source": str(ora.relative_to(ROOT)),
            "krita_source": str(ora.with_suffix(".kra").relative_to(ROOT)),
            "runtime_png": str((stage_dir / f"{theme}_runtime_texture.png").relative_to(ROOT)),
            "layers": [name.replace("_", " ").title() for name in order],
        })
    SOURCE.mkdir(parents=True, exist_ok=True)
    (SOURCE / "stage_3d_texture_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(manifest)} layered 3D stage textures.")


if __name__ == "__main__":
    main()

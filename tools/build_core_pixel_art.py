#!/usr/bin/env python3
"""Build layered PC-98-inspired player, attack, pickup, and UI pixel art."""

from __future__ import annotations

import json
import math
import shutil
import zipfile
from io import BytesIO
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw

from build_gameplay_art import ROOT, SPRITES, install_sprite, sprite_metadata, stable_uuid


SOURCE = ROOT / "art" / "core_pixel_sources"
REFERENCE = ROOT / "art" / "original_runtime_references" / "core_pixel_pass"


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return (*color, alpha)


def layer(size: tuple[int, int]) -> Image.Image:
    return Image.new("RGBA", size, (0, 0, 0, 0))


def composite(layers: dict[str, Image.Image], order: list[str]) -> Image.Image:
    result = layer(next(iter(layers.values())).size)
    for name in order:
        result = Image.alpha_composite(result, layers[name])
    return result


def backup_runtime_sprite(name: str) -> None:
    source = SPRITES / name
    target = REFERENCE / name
    if target.exists() or not source.exists():
        return
    target.mkdir(parents=True, exist_ok=True)
    for image in source.glob("*.png"):
        shutil.copy2(image, target / image.name)
    metadata = source / f"{name}.yy"
    if metadata.exists():
        shutil.copy2(metadata, target / metadata.name)


def install_with_origin(name: str, image: Image.Image, origin: int = 4, xorigin: int | None = None,
                        yorigin: int | None = None) -> None:
    if origin == 4 and xorigin is None and yorigin is None:
        install_sprite(name, image)
        return

    image = image.convert("RGBA")
    width, height = image.size
    directory = SPRITES / name
    directory.mkdir(parents=True, exist_ok=True)
    frame = stable_uuid(f"{name}/frame")
    image_layer = stable_uuid(f"{name}/layer")
    metadata = sprite_metadata(name, width, height, frame, image_layer)
    metadata["origin"] = origin
    metadata["sequence"]["xorigin"] = width // 2 if xorigin is None else xorigin
    metadata["sequence"]["yorigin"] = height // 2 if yorigin is None else yorigin
    image.save(directory / f"{frame}.png")
    (directory / f"{name}.yy").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")


def write_ora(path: Path, layers: dict[str, Image.Image], order: list[str], merged: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    width, height = merged.size
    top_first = list(reversed(order))
    entries = [
        f'<layer name="{escape(name.replace("_", " ").title())}" '
        f'src="data/{index:02d}_{name}.png" visibility="visible"/>'
        for index, name in enumerate(top_first)
    ]
    stack_xml = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<image version="0.0.1" w="{width}" h="{height}" name="{escape(path.stem)}">'
        f'<stack>{"".join(entries)}</stack></image>'
    )
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        archive.writestr("stack.xml", stack_xml)
        for index, name in enumerate(top_first):
            buffer = BytesIO()
            layers[name].save(buffer, format="PNG")
            archive.writestr(f"data/{index:02d}_{name}.png", buffer.getvalue())
        merged_buffer = BytesIO()
        merged.save(merged_buffer, format="PNG")
        archive.writestr("mergedimage.png", merged_buffer.getvalue())
        archive.writestr("Thumbnails/thumbnail.png", merged_buffer.getvalue())


def add_ordered_dither(mask: Image.Image, target: Image.Image, dark, light, y_split: int | None = None) -> None:
    source = mask.getchannel("A").load()
    pixels = target.load()
    width, height = target.size
    bayer = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    split = height // 2 if y_split is None else y_split
    for y in range(height):
        for x in range(width):
            if source[x, y] < 96:
                continue
            rank = bayer[y % 4][x % 4]
            if y >= split and rank < 4:
                pixels[x, y] = dark
            elif y < split and rank in (1, 9):
                pixels[x, y] = light


def ship_layers(route: str) -> tuple[dict[str, Image.Image], list[str]]:
    size = (64, 64)
    names = ["glow", "silhouette", "materials", "dither_texture", "ornament", "highlights"]
    layers = {name: layer(size) for name in names}
    glow = ImageDraw.Draw(layers["glow"])
    silhouette = ImageDraw.Draw(layers["silhouette"])
    material = ImageDraw.Draw(layers["materials"])
    ornament = ImageDraw.Draw(layers["ornament"])
    highlight = ImageDraw.Draw(layers["highlights"])
    ink = (13, 7, 28, 255)

    if route == "moon":
        # Moon's Sunset: a rose-window interceptor with velvet lunar wings.
        glow.ellipse((13, 22, 51, 58), fill=(176, 72, 222, 45))
        glow.ellipse((20, 27, 44, 53), fill=(255, 104, 180, 54))
        silhouette.polygon([(32, 3), (38, 20), (58, 31), (50, 48), (39, 43),
                            (35, 61), (29, 61), (25, 43), (14, 48), (6, 31), (26, 20)], fill=ink)
        material.polygon([(32, 7), (36, 23), (53, 31), (47, 42), (37, 37),
                          (34, 55), (30, 55), (27, 37), (17, 42), (11, 31), (28, 23)],
                         fill=(79, 42, 139, 255))
        material.polygon([(8, 31), (28, 22), (24, 38), (14, 45)], fill=(134, 69, 174, 255))
        material.polygon([(56, 31), (36, 22), (40, 38), (50, 45)], fill=(203, 72, 143, 255))
        material.polygon([(32, 9), (35, 29), (32, 51), (29, 29)], fill=(238, 131, 185, 255))
        ornament.ellipse((23, 22, 41, 40), fill=(35, 16, 57, 255), outline=(244, 190, 88, 255), width=2)
        for angle in range(0, 360, 60):
            rad = math.radians(angle)
            cx, cy = 32 + round(math.cos(rad) * 5), 31 + round(math.sin(rad) * 5)
            ornament.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(244, 88, 162, 255))
        ornament.ellipse((29, 28, 35, 34), fill=(255, 226, 158, 255))
        ornament.line((16, 34, 26, 29), fill=(236, 196, 104, 255), width=1)
        ornament.line((48, 34, 38, 29), fill=(236, 196, 104, 255), width=1)
        add_ordered_dither(layers["materials"], layers["dither_texture"],
                           (35, 18, 74, 165), (239, 119, 209, 150), 34)
        highlight.line((31, 7, 31, 22), fill=(255, 241, 207, 255), width=1)
        highlight.point([(15, 31), (18, 30), (46, 30), (49, 31)], fill=(255, 220, 246, 255))
    else:
        # Selkie's Sunrise: a tidal crescent craft built around a brass chakram.
        glow.ellipse((11, 20, 53, 58), fill=(64, 213, 239, 45))
        glow.ellipse((20, 25, 44, 52), fill=(255, 184, 96, 52))
        silhouette.polygon([(32, 3), (40, 20), (60, 25), (51, 43), (40, 42),
                            (36, 60), (28, 60), (24, 42), (13, 43), (4, 25), (24, 20)], fill=ink)
        material.polygon([(32, 7), (38, 23), (55, 27), (48, 38), (37, 36),
                          (34, 55), (30, 55), (27, 36), (16, 38), (9, 27), (26, 23)],
                         fill=(32, 133, 151, 255))
        material.polygon([(7, 26), (28, 21), (24, 37), (13, 39)], fill=(60, 193, 195, 255))
        material.polygon([(57, 26), (36, 21), (40, 37), (51, 39)], fill=(226, 121, 73, 255))
        material.polygon([(32, 8), (36, 27), (32, 50), (28, 27)], fill=(245, 181, 83, 255))
        ornament.ellipse((21, 21, 43, 43), outline=(247, 208, 104, 255), width=3)
        ornament.ellipse((26, 26, 38, 38), fill=(24, 55, 79, 255), outline=(183, 242, 235, 255), width=1)
        ornament.polygon([(32, 18), (35, 29), (46, 32), (35, 35), (32, 46),
                          (29, 35), (18, 32), (29, 29)], outline=(255, 234, 163, 255))
        add_ordered_dither(layers["materials"], layers["dither_texture"],
                           (15, 68, 91, 165), (116, 238, 224, 150), 34)
        highlight.line((32, 7, 32, 22), fill=(255, 249, 215, 255), width=1)
        highlight.point([(12, 27), (16, 26), (48, 26), (52, 27)], fill=(218, 255, 251, 255))
    return layers, names


def bullet_layers(route: str) -> tuple[dict[str, Image.Image], list[str]]:
    size = (16, 16)
    names = ["glow", "silhouette", "materials", "highlights"]
    layers = {name: layer(size) for name in names}
    glow = ImageDraw.Draw(layers["glow"])
    silhouette = ImageDraw.Draw(layers["silhouette"])
    material = ImageDraw.Draw(layers["materials"])
    highlight = ImageDraw.Draw(layers["highlights"])
    if route == "moon":
        glow.polygon([(0, 8), (7, 3), (15, 8), (7, 13)], fill=(255, 88, 179, 75))
        silhouette.polygon([(0, 8), (6, 2), (15, 8), (6, 14)], fill=(19, 8, 35, 255))
        material.polygon([(2, 8), (7, 4), (14, 8), (7, 12)], fill=(162, 48, 135, 255))
        material.polygon([(7, 5), (14, 8), (7, 8)], fill=(244, 189, 76, 255))
        highlight.line((3, 7, 9, 7), fill=(255, 229, 244, 255))
    else:
        glow.ellipse((1, 2, 14, 14), fill=(78, 225, 245, 70))
        silhouette.polygon([(1, 8), (6, 2), (15, 8), (6, 14)], fill=(11, 21, 38, 255))
        material.polygon([(3, 8), (7, 4), (14, 8), (7, 12)], fill=(48, 190, 204, 255))
        material.arc((4, 3, 13, 13), 55, 305, fill=(250, 184, 83, 255), width=2)
        highlight.line((4, 7, 10, 7), fill=(222, 255, 250, 255))
    return layers, names


def sword_layers(kind: str) -> tuple[dict[str, Image.Image], list[str]]:
    sizes = {"selkie_chakram": (48, 48), "moon_rose": (24, 24), "moon_thorn": (8, 8), "charge_dial": (80, 80)}
    size = sizes[kind]
    names = ["glow", "silhouette", "materials", "ornament", "highlights"]
    layers = {name: layer(size) for name in names}
    glow = ImageDraw.Draw(layers["glow"])
    silhouette = ImageDraw.Draw(layers["silhouette"])
    material = ImageDraw.Draw(layers["materials"])
    ornament = ImageDraw.Draw(layers["ornament"])
    highlight = ImageDraw.Draw(layers["highlights"])
    w, h = size
    cx, cy = w // 2, h // 2

    if kind == "selkie_chakram":
        glow.ellipse((2, 2, 45, 45), outline=(72, 224, 242, 90), width=4)
        silhouette.ellipse((5, 5, 42, 42), outline=(13, 8, 29, 255), width=6)
        material.ellipse((7, 7, 40, 40), outline=(53, 197, 207, 255), width=4)
        ornament.ellipse((12, 12, 35, 35), outline=(247, 192, 86, 255), width=2)
        for angle in range(0, 360, 45):
            rad = math.radians(angle)
            tip = (cx + round(math.cos(rad) * 23), cy + round(math.sin(rad) * 23))
            left = (cx + round(math.cos(rad - 0.28) * 16), cy + round(math.sin(rad - 0.28) * 16))
            right = (cx + round(math.cos(rad + 0.28) * 16), cy + round(math.sin(rad + 0.28) * 16))
            silhouette.polygon([left, tip, right], fill=(13, 8, 29, 255))
            material.line((left, tip, right), fill=(232, 122, 174, 255), width=2)
        highlight.arc((8, 8, 39, 39), 205, 322, fill=(238, 255, 245, 255), width=1)
    elif kind == "moon_rose":
        glow.ellipse((1, 1, 22, 22), fill=(255, 92, 181, 65))
        for angle in range(0, 360, 60):
            rad = math.radians(angle)
            px, py = cx + round(math.cos(rad) * 6), cy + round(math.sin(rad) * 6)
            silhouette.ellipse((px - 5, py - 4, px + 5, py + 4), fill=(29, 10, 42, 255))
            material.ellipse((px - 4, py - 3, px + 4, py + 3), fill=(215, 63, 145, 255))
        ornament.ellipse((8, 8, 16, 16), fill=(244, 188, 75, 255))
        highlight.point([(10, 8), (7, 11), (14, 14)], fill=(255, 230, 246, 255))
    elif kind == "moon_thorn":
        silhouette.line((0, 7, 7, 0), fill=(15, 8, 29, 255), width=3)
        material.line((0, 6, 7, 0), fill=(63, 180, 120, 255), width=1)
        ornament.polygon([(3, 4), (2, 0), (5, 3)], fill=(233, 94, 169, 255))
        highlight.point((6, 0), fill=(240, 255, 216, 255))
    else:
        glow.ellipse((4, 4, 75, 75), outline=(119, 230, 255, 50), width=5)
        silhouette.ellipse((8, 8, 71, 71), outline=(18, 9, 35, 255), width=5)
        material.ellipse((10, 10, 69, 69), outline=(86, 174, 203, 255), width=2)
        ornament.ellipse((18, 18, 61, 61), outline=(239, 190, 88, 255), width=1)
        for angle in range(0, 360, 30):
            rad = math.radians(angle)
            inner = (cx + round(math.cos(rad) * 25), cy + round(math.sin(rad) * 25))
            outer = (cx + round(math.cos(rad) * 34), cy + round(math.sin(rad) * 34))
            ornament.line((inner, outer), fill=(236, 124, 194, 255), width=2)
        highlight.arc((12, 12, 67, 67), 205, 315, fill=(244, 255, 244, 255), width=1)
    return layers, names


def powerup_layers(kind: str) -> tuple[dict[str, Image.Image], list[str]]:
    size = (32, 32)
    names = ["glow", "silhouette", "materials", "dither_texture", "symbol", "highlights"]
    layers = {name: layer(size) for name in names}
    glow = ImageDraw.Draw(layers["glow"])
    silhouette = ImageDraw.Draw(layers["silhouette"])
    material = ImageDraw.Draw(layers["materials"])
    symbol = ImageDraw.Draw(layers["symbol"])
    highlight = ImageDraw.Draw(layers["highlights"])
    palette = {
        "power": ((226, 132, 45), (255, 217, 94)),
        "bomb": ((112, 68, 181), (219, 126, 239)),
        "life": ((190, 52, 103), (255, 137, 178)),
        "meter": ((36, 152, 177), (112, 235, 239)),
        "score": ((72, 167, 101), (188, 235, 112)),
    }
    dark, light = palette[kind]
    glow.ellipse((3, 3, 28, 28), fill=rgba(light, 55))
    silhouette.polygon([(16, 1), (27, 7), (31, 16), (25, 27), (16, 31), (7, 27), (1, 16), (5, 7)],
                       fill=(15, 8, 29, 255))
    material.polygon([(16, 4), (25, 9), (28, 16), (23, 24), (16, 28), (9, 24), (4, 16), (7, 9)],
                     fill=rgba(dark))
    material.ellipse((8, 8, 24, 24), fill=rgba(light), outline=(247, 208, 126, 255), width=1)
    add_ordered_dither(layers["materials"], layers["dither_texture"], rgba(dark, 160), (255, 240, 200, 145), 17)
    ink = (27, 12, 43, 255)
    pearl = (255, 240, 214, 255)
    if kind == "power":
        symbol.polygon([(16, 7), (11, 17), (15, 16), (13, 25), (22, 13), (18, 14)], fill=ink)
        symbol.line((16, 8, 13, 18), fill=pearl, width=1)
    elif kind == "bomb":
        symbol.ellipse((10, 11, 22, 24), fill=ink)
        symbol.line((19, 12, 23, 7), fill=pearl, width=2)
        symbol.point([(24, 6), (26, 7), (24, 9), (22, 7)], fill=(255, 210, 82, 255))
    elif kind == "life":
        symbol.ellipse((9, 10, 16, 17), fill=ink)
        symbol.ellipse((16, 10, 23, 17), fill=ink)
        symbol.polygon([(9, 14), (23, 14), (16, 24)], fill=ink)
        highlight.point((13, 12), fill=pearl)
    elif kind == "meter":
        symbol.polygon([(10, 8), (22, 8), (19, 14), (13, 14)], outline=ink)
        symbol.polygon([(13, 17), (19, 17), (22, 24), (10, 24)], outline=ink)
        symbol.line((12, 8, 20, 24), fill=pearl, width=1)
    else:
        symbol.ellipse((9, 9, 23, 23), fill=(227, 179, 64, 255), outline=ink, width=2)
        symbol.polygon([(16, 11), (18, 15), (22, 16), (18, 18), (16, 22), (14, 18), (10, 16), (14, 15)], fill=pearl)
    highlight.line((9, 8, 14, 5), fill=(255, 247, 218, 255), width=1)
    return layers, names


def medal_layers() -> tuple[dict[str, Image.Image], list[str]]:
    layers, names = powerup_layers("score")
    symbol = ImageDraw.Draw(layers["symbol"])
    symbol.rectangle((7, 7, 24, 24), fill=(29, 13, 48, 255))
    symbol.polygon([(16, 4), (28, 16), (16, 28), (4, 16)], fill=(58, 135, 214, 255), outline=(245, 197, 86, 255))
    symbol.polygon([(16, 7), (25, 16), (16, 25), (7, 16)], fill=(209, 73, 178, 255))
    symbol.polygon([(16, 10), (22, 16), (16, 22), (10, 16)], fill=(231, 244, 255, 255))
    symbol.point([(15, 11), (11, 15), (21, 15)], fill=(255, 255, 255, 255))
    return layers, names


def textbox_layers() -> tuple[dict[str, Image.Image], list[str]]:
    size = (640, 130)
    names = ["shadow", "velvet_fill", "dither_texture", "legacy_tracery", "frame",
             "filigree", "rose_windows", "highlights"]
    layers = {name: layer(size) for name in names}
    shadow = ImageDraw.Draw(layers["shadow"])
    fill = ImageDraw.Draw(layers["velvet_fill"])
    frame = ImageDraw.Draw(layers["frame"])
    filigree = ImageDraw.Draw(layers["filigree"])
    roses = ImageDraw.Draw(layers["rose_windows"])
    highlight = ImageDraw.Draw(layers["highlights"])

    # The original textbox's curled pearl silhouette remains the design
    # authority. Quantize its alpha and colors onto the authored pixel grid so
    # the tracery stays crisp and remains isolated on its own editable layer.
    originals = sorted((REFERENCE / "spr_textbox").glob("*.png"))
    if originals:
        original = Image.open(originals[0]).convert("RGBA")
        original_pixels = original.load()
        tracery_pixels = layers["legacy_tracery"].load()
        for y in range(min(size[1], original.height)):
            for x in range(min(size[0], original.width)):
                r, g, b, a = original_pixels[x, y]
                if a < 72 or max(r, g, b) < 64:
                    continue
                if r > b + 12:
                    tracery_pixels[x, y] = (236, 104, 185, 255)
                elif b > r + 12:
                    tracery_pixels[x, y] = (118, 211, 225, 255)
                else:
                    tracery_pixels[x, y] = (248, 236, 218, 255)

    # Stepped corners and a velvet field support the original scrollwork rather
    # than replacing it with a plain rectangle.
    outline = [(16, 3), (624, 3), (635, 14), (635, 116), (622, 129), (18, 129),
               (5, 116), (5, 14)]
    shadow.polygon([(x + 2, y + 2) for x, y in outline], fill=(4, 2, 12, 210))
    fill.polygon(outline, fill=(17, 8, 33, 224))
    # Sparse checker texture reads as velvet at 640x360 without muddying text.
    texture = layers["dither_texture"].load()
    for y in range(9, 125):
        for x in range(13, 627):
            if ((x + y * 3) % 8) == 0:
                texture[x, y] = (92, 34, 91, 38)
            elif ((x * 3 + y) % 16) == 0:
                texture[x, y] = (56, 128, 139, 26)
    frame.line(outline + [outline[0]], fill=(247, 226, 194, 255), width=2)
    frame.line([(20, 7), (620, 7), (631, 18), (631, 111), (615, 125), (25, 125),
                (9, 111), (9, 18), (20, 7)], fill=(164, 82, 175, 255), width=1)
    frame.line([(34, 11), (606, 11)], fill=(92, 204, 204, 255), width=1)
    frame.line([(34, 121), (606, 121)], fill=(226, 102, 178, 255), width=1)

    # Layered corner vines, leaves, and pearls extend the old curled frame.
    for side in (1, -1):
        cx = 22 if side == 1 else 618
        filigree.line((cx, 16, cx + side * 11, 27, cx + side * 2, 40,
                       cx + side * 12, 52, cx + side * 3, 65),
                      fill=(91, 207, 199, 255), width=2)
        filigree.line((cx + side * 3, 65, cx + side * 12, 78,
                       cx + side * 2, 91, cx + side * 11, 104, cx, 116),
                      fill=(214, 86, 164, 255), width=2)
        for leaf_y, leaf_side in ((31, 1), (47, -1), (82, 1), (98, -1)):
            lx = cx + side * (7 + leaf_side * 3)
            filigree.polygon([(lx, leaf_y), (lx + side * 7, leaf_y - 4),
                              (lx + side * 5, leaf_y + 4)],
                             fill=(60, 166, 150, 255), outline=(218, 235, 188, 255))
        filigree.point([(cx, 14), (cx + side * 12, 53), (cx + side * 12, 77), (cx, 117)],
                        fill=(255, 244, 218, 255))

    # Rose-window medallions anchor the center and corners, establishing the
    # decorative vocabulary reused by scalable menu frames.
    for cx, cy, radius in ((320, 7, 6), (320, 123, 6), (21, 65, 7), (619, 65, 7)):
        roses.ellipse((cx - radius, cy - radius, cx + radius, cy + radius),
                      fill=(40, 18, 62, 255), outline=(247, 210, 118, 255), width=1)
        for angle in range(0, 360, 90):
            rad = math.radians(angle)
            px = cx + round(math.cos(rad) * (radius - 2))
            py = cy + round(math.sin(rad) * (radius - 2))
            roses.rectangle((px - 1, py - 1, px + 1, py + 1), fill=(226, 91, 172, 255))
        roses.point((cx, cy), fill=(228, 250, 238, 255))

    for x in range(64, 600, 64):
        filigree.point((x, 10), fill=(230, 128, 197, 255))
        filigree.point((x, 122), fill=(94, 210, 218, 255))
    highlight.line((28, 4, 306, 4), fill=(255, 249, 231, 255), width=1)
    highlight.line((334, 4, 612, 4), fill=(255, 249, 231, 255), width=1)
    highlight.point([(18, 13), (622, 13), (8, 113), (632, 113)], fill=(255, 255, 255, 255))
    return layers, names


def save_asset(category: str, slug: str, sprite: str, layers: dict[str, Image.Image], order: list[str],
               *, origin: int = 4, xorigin: int | None = None, yorigin: int | None = None) -> dict:
    directory = SOURCE / category
    layer_dir = directory / "layer_exports" / slug
    layer_dir.mkdir(parents=True, exist_ok=True)
    for name, image in layers.items():
        image.save(layer_dir / f"{name}.png")
    merged = composite(layers, order)
    merged.save(directory / f"{slug}_runtime_preview.png")
    ora = directory / f"{slug}.ora"
    write_ora(ora, layers, order, merged)
    backup_runtime_sprite(sprite)
    install_with_origin(sprite, merged, origin, xorigin, yorigin)
    return {
        "category": category,
        "slug": slug,
        "sprite": sprite,
        "openraster_source": str(ora.relative_to(ROOT)),
        "krita_source": str(ora.with_suffix(".kra").relative_to(ROOT)),
        "size": list(merged.size),
        "layers": [name.replace("_", " ").title() for name in order],
    }


def main() -> None:
    manifest = []
    for route, slug, sprite in (
        ("moon", "moon_sunset_ship", "spr_sunrise"),
        ("selkie", "selkie_sunrise_ship", "spr_sunset"),
    ):
        layers, order = ship_layers(route)
        manifest.append(save_asset("player_ships", slug, sprite, layers, order))

    for route, slug, sprite in (
        ("moon", "moon_rose_thorn_shot", "spr_sunrise_bullet"),
        ("selkie", "selkie_tidal_chakram_shot", "spr_sunset_bullet"),
    ):
        layers, order = bullet_layers(route)
        manifest.append(save_asset("player_attacks", slug, sprite, layers, order))

    for kind, slug, sprite in (
        ("selkie_chakram", "selkie_sword_chakram", "spr_attack_selkie_chakram"),
        ("moon_rose", "moon_sword_rose", "spr_attack_moon_rose"),
        ("moon_thorn", "moon_sword_thorn", "spr_attack_moon_thorn"),
        ("charge_dial", "sword_charge_dial", "spr_attack_charge_dial"),
    ):
        layers, order = sword_layers(kind)
        manifest.append(save_asset("player_attacks", slug, sprite, layers, order))

    for kind in ("power", "bomb", "life", "meter", "score"):
        layers, order = powerup_layers(kind)
        manifest.append(save_asset("powerups", f"{kind}_pickup", f"spr_powerup_{kind}", layers, order))

    layers, order = medal_layers()
    manifest.append(save_asset("ui", "score_medal", "spr_medal", layers, order))
    layers, order = textbox_layers()
    manifest.append(save_asset("ui", "dialogue_textbox", "spr_textbox", layers, order,
                               origin=7, xorigin=320, yorigin=130))

    SOURCE.mkdir(parents=True, exist_ok=True)
    (SOURCE / "core_pixel_source_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Built {len(manifest)} layered core pixel-art assets.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build high-resolution layered texture atlases for the five 3D locations.

Each 1024px atlas reserves three opaque quadrants for modeled surfaces and a
transparent 2x2 cell sheet for camera-facing billboard cards. OpenRaster is
kept as an interchange source and Krita converts it to a native editable KRA.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

from build_gameplay_art import ROOT, install_sprite
from build_core_pixel_art import composite, layer, write_ora


SOURCE = ROOT / "art" / "3d_stage_sources" / "textures"
KRITA = Path("/Applications/krita.app/Contents/MacOS/krita")
SIZE = (1024, 1024)
HALF = 512
CELL = 256


THEMES = {
    1: {
        "slug": "forge",
        "location": "Shalmii's Blacksmith Citadel",
        "sprite": "tex_stage3d_01",
        "palette": ((34, 18, 28), (104, 43, 38), (231, 83, 36), (247, 179, 72), (86, 82, 104)),
    },
    2: {
        "slug": "saltwind",
        "location": "Aster's Moonrabbit Forest",
        "sprite": "tex_stage3d_02",
        "palette": ((25, 40, 40), (59, 91, 66), (211, 132, 192), (112, 206, 153), (236, 219, 168)),
    },
    3: {
        "slug": "wishcourt",
        "location": "Mira and Aisha's Vegas Grand Illusion",
        "sprite": "tex_stage3d_03",
        "palette": ((24, 12, 42), (79, 29, 92), (231, 54, 137), (72, 183, 226), (249, 205, 92)),
    },
    4: {
        "slug": "orrery",
        "location": "Caelia's Deep-Space Orrery",
        "sprite": "tex_stage3d_04",
        "palette": ((8, 8, 30), (38, 26, 74), (190, 60, 156), (87, 154, 238), (242, 204, 118)),
    },
    5: {
        "slug": "violet_garden",
        "location": "The Infinite Violet and Vine Field",
        "sprite": "tex_stage3d_05",
        "palette": ((28, 17, 45), (66, 57, 83), (184, 82, 190), (64, 151, 91), (249, 207, 105)),
    },
}


def gradient_box(image: Image.Image, box, top, bottom) -> None:
    """Fill one atlas region with a smooth opaque material gradient."""
    x0, y0, x1, y1 = box
    draw = ImageDraw.Draw(image)
    height = max(1, y1 - y0)
    for y in range(y0, y1 + 1):
        ratio = (y - y0) / height
        color = tuple(round(top[channel] + (bottom[channel] - top[channel]) * ratio)
                      for channel in range(3)) + (255,)
        draw.line((x0, y, x1, y), fill=color)


def cell_box(index: int, inset: int = 0) -> tuple[int, int, int, int]:
    column = index % 2
    row = index // 2
    x0 = HALF + column * CELL + inset
    y0 = HALF + row * CELL + inset
    return x0, y0, x0 + CELL - 1 - inset, y0 + CELL - 1 - inset


def add_star(draw: ImageDraw.ImageDraw, x: int, y: int, radius: int, color) -> None:
    points = []
    for index in range(10):
        angle = -90 + index * 36
        reach = radius if index % 2 == 0 else max(2, radius // 2)
        radians = angle * 3.141592653589793 / 180
        points.append((x + round(__import__("math").cos(radians) * reach),
                       y + round(__import__("math").sin(radians) * reach)))
    draw.polygon(points, fill=color)


def draw_billboard_cell_backdrops(stage: int, glow: ImageDraw.ImageDraw) -> None:
    for index in range(4):
        x0, y0, x1, y1 = cell_box(index, 12)
        if stage == 1:
            glow.ellipse((x0 + 38, y0 + 30, x1 - 38, y1 - 12), fill=(255, 83, 28, 52))
        elif stage == 2:
            glow.ellipse((x0 + 18, y0 + 18, x1 - 18, y1 - 8), fill=(104, 224, 146, 38))
        elif stage == 3:
            color = (255, 38, 128, 46) if index < 2 else (76, 172, 255, 46)
            glow.rounded_rectangle((x0 + 18, y0 + 24, x1 - 18, y1 - 18), 38, fill=color)
        elif stage == 4:
            color = ((158, 72, 255, 50), (75, 154, 255, 55),
                     (255, 86, 180, 48), (108, 204, 255, 44))[index]
            glow.ellipse((x0 + 10, y0 + 22, x1 - 10, y1 - 22), fill=color)
        else:
            glow.ellipse((x0 + 10, y0 + 34, x1 - 10, y1 - 4), fill=(191, 77, 229, 48))


def draw_forge_billboards(draw: ImageDraw.ImageDraw, emission: ImageDraw.ImageDraw,
                          accent, cool, gold) -> None:
    # 0: layered forge flame.
    x0, y0, x1, y1 = cell_box(0, 18)
    draw.polygon([(x0 + 102, y1), (x0 + 68, y0 + 130), (x0 + 108, y0 + 80),
                  (x0 + 120, y0 + 18), (x0 + 154, y0 + 94),
                  (x0 + 180, y0 + 138), (x0 + 166, y1)], fill=(*accent, 238))
    emission.polygon([(x0 + 111, y1 - 12), (x0 + 94, y0 + 150),
                      (x0 + 128, y0 + 92), (x0 + 150, y1 - 12)], fill=(*gold, 245))

    # 1: hammer and tongs standard.
    x0, y0, x1, y1 = cell_box(1, 18)
    draw.polygon([(x0 + 38, y0 + 32), (x1 - 38, y0 + 32),
                  (x1 - 52, y1 - 28), (x0 + 52, y1 - 28)], fill=(72, 45, 65, 236),
                 outline=(*gold, 255), width=7)
    draw.rectangle((x0 + 108, y0 + 62, x0 + 132, y1 - 52), fill=(*cool, 255))
    draw.rounded_rectangle((x0 + 56, y0 + 54, x0 + 184, y0 + 98), 10, fill=(*gold, 255))
    draw.line((x0 + 72, y1 - 66, x1 - 70, y0 + 112), fill=(*accent, 255), width=13)

    # 2: smoke plume with hard pixel clusters.
    x0, y0, x1, y1 = cell_box(2, 14)
    for index, (cx, cy, radius) in enumerate(((120, 202, 40), (96, 156, 48),
                                               (143, 112, 54), (111, 58, 43))):
        shade = (118 + index * 12, 105 + index * 9, 132 + index * 10, 188 - index * 12)
        draw.ellipse((x0 + cx - radius, y0 + cy - radius,
                      x0 + cx + radius, y0 + cy + radius), fill=shade)

    # 3: sword and spear rack.
    x0, y0, x1, y1 = cell_box(3, 16)
    draw.rectangle((x0 + 32, y1 - 46, x1 - 32, y1 - 20), fill=(*gold, 255))
    for index in range(6):
        x = x0 + 48 + index * 29
        draw.line((x, y1 - 42, x + (8 if index % 2 else -8), y0 + 38),
                  fill=(*cool, 255), width=8)
        draw.polygon([(x - 12, y0 + 58), (x + 12, y0 + 58),
                      (x, y0 + 24)], fill=(*gold, 255))


def draw_forest_billboards(draw: ImageDraw.ImageDraw, emission: ImageDraw.ImageDraw,
                           accent, cool, gold) -> None:
    # 0: old forest tree.
    x0, y0, x1, y1 = cell_box(0, 10)
    draw.polygon([(x0 + 104, y1), (x0 + 116, y0 + 116), (x0 + 76, y0 + 82),
                  (x0 + 119, y0 + 102), (x0 + 148, y0 + 44),
                  (x0 + 139, y0 + 112), (x0 + 188, y0 + 86),
                  (x0 + 151, y0 + 129), (x0 + 164, y1)], fill=(87, 59, 49, 255))
    for cx, cy, radius in ((78, 78, 64), (139, 58, 72), (187, 92, 55), (112, 119, 62)):
        draw.ellipse((x0 + cx - radius, y0 + cy - radius,
                      x0 + cx + radius, y0 + cy + radius), fill=(*cool, 238))

    # 1: rabbit-shaped topiary.
    x0, y0, x1, y1 = cell_box(1, 14)
    draw.ellipse((x0 + 57, y0 + 105, x1 - 35, y1 - 14), fill=(*cool, 248))
    draw.ellipse((x0 + 72, y0 + 58, x1 - 64, y0 + 158), fill=(*cool, 248))
    draw.ellipse((x0 + 78, y0 + 6, x0 + 116, y0 + 96), fill=(*cool, 248))
    draw.ellipse((x0 + 132, y0 + 2, x0 + 170, y0 + 98), fill=(*cool, 248))
    draw.ellipse((x1 - 62, y0 + 126, x1 - 10, y0 + 178), fill=(*accent, 240))
    emission.ellipse((x0 + 103, y0 + 91, x0 + 113, y0 + 101), fill=(*gold, 255))

    # 2: fern and wildflower thicket.
    x0, y0, x1, y1 = cell_box(2, 10)
    for index in range(9):
        stem_x = x0 + 26 + index * 24
        tip_x = stem_x + ((index % 3) - 1) * 28
        tip_y = y0 + 30 + (index % 4) * 19
        draw.line((stem_x, y1, tip_x, tip_y), fill=(*cool, 255), width=8)
        for leaf in range(4):
            ly = y1 - 30 - leaf * 35
            draw.ellipse((stem_x - 22, ly - 10, stem_x + 2, ly + 12), fill=(*cool, 225))
            draw.ellipse((stem_x - 2, ly - 14, stem_x + 24, ly + 8), fill=(*cool, 225))
        if index % 2 == 0:
            emission.ellipse((tip_x - 9, tip_y - 9, tip_x + 9, tip_y + 9), fill=(*accent, 255))

    # 3: mushroom-ring burrow.
    x0, y0, x1, y1 = cell_box(3, 12)
    draw.ellipse((x0 + 38, y0 + 82, x1 - 38, y1 + 78), fill=(60, 48, 50, 255),
                 outline=(*cool, 255), width=10)
    draw.ellipse((x0 + 78, y0 + 116, x1 - 78, y1 + 56), fill=(18, 25, 30, 255))
    for index in range(7):
        mx = x0 + 24 + index * 33
        my = y1 - 50 - (index % 2) * 24
        draw.rectangle((mx - 5, my, mx + 5, y1), fill=(*gold, 255))
        draw.ellipse((mx - 23, my - 19, mx + 23, my + 9), fill=(*accent, 255))


def draw_vegas_billboards(draw: ImageDraw.ImageDraw, emission: ImageDraw.ImageDraw,
                          accent, cool, gold) -> None:
    # Cells 0-1 are Mira's casino/trickery half.
    x0, y0, x1, y1 = cell_box(0, 12)
    draw.rounded_rectangle((x0 + 22, y0 + 48, x1 - 22, y1 - 24), 22,
                           fill=(66, 20, 72, 245), outline=(*gold, 255), width=8)
    for index in range(3):
        cx = x0 + 72 + index * 56
        emission.ellipse((cx - 20, y0 + 96, cx + 20, y0 + 136),
                         fill=(*(accent if index != 1 else gold), 255))
    for bulb in range(9):
        bx = x0 + 36 + bulb * 23
        emission.ellipse((bx - 4, y0 + 58, bx + 4, y0 + 66), fill=(*gold, 255))

    x0, y0, x1, y1 = cell_box(1, 12)
    for card in range(5):
        angle_offset = (card - 2) * 13
        left = x0 + 70 + card * 16
        top = y0 + 44 + abs(card - 2) * 12
        draw.rounded_rectangle((left, top, left + 92, top + 142), 8,
                               fill=(244, 232, 210, 252), outline=(*gold, 255), width=5)
        emission.polygon([(left + 46, top + 32), (left + 61, top + 55),
                          (left + 46, top + 78), (left + 31, top + 55)],
                         fill=(*(accent if card % 2 == 0 else (196, 35, 58)), 255))

    # Cells 2-3 are Aisha's stage-sorcery half.
    x0, y0, x1, y1 = cell_box(2, 10)
    draw.polygon([(x0 + 12, y0 + 16), (x0 + 74, y0 + 46), (x0 + 86, y1),
                  (x0 + 8, y1)], fill=(65, 26, 104, 238))
    draw.polygon([(x1 - 12, y0 + 16), (x1 - 74, y0 + 46), (x1 - 86, y1),
                  (x1 - 8, y1)], fill=(33, 68, 130, 238))
    for radius in (36, 62, 88):
        emission.ellipse((x0 + 128 - radius, y0 + 132 - radius,
                          x0 + 128 + radius, y0 + 132 + radius), outline=(*cool, 255), width=5)
    for arm in range(8):
        import math
        angle = arm * math.tau / 8
        emission.line((x0 + 128, y0 + 132,
                       x0 + 128 + round(math.cos(angle) * 92),
                       y0 + 132 + round(math.sin(angle) * 92)), fill=(*gold, 220), width=4)

    x0, y0, x1, y1 = cell_box(3, 10)
    draw.ellipse((x0 + 45, y0 + 136, x1 - 45, y1 - 18), fill=(24, 19, 45, 255),
                 outline=(*cool, 255), width=7)
    draw.rectangle((x0 + 75, y0 + 82, x1 - 75, y0 + 170), fill=(24, 19, 45, 255),
                   outline=(*cool, 255), width=7)
    draw.line((x0 + 36, y1 - 30, x1 - 28, y0 + 32), fill=(*gold, 255), width=11)
    add_star(emission, x1 - 33, y0 + 30, 22, (*cool, 255))
    for sx, sy in ((46, 64), (88, 32), (168, 68), (201, 116), (52, 142)):
        add_star(emission, x0 + sx, y0 + sy, 9, (*accent, 255))


def draw_space_billboards(draw: ImageDraw.ImageDraw, emission: ImageDraw.ImageDraw,
                          accent, cool, gold) -> None:
    # 0: billowing nebula.
    x0, y0, x1, y1 = cell_box(0, 8)
    for index, (cx, cy, rx, ry) in enumerate(((56, 136, 52, 66), (108, 102, 73, 80),
                                               (164, 124, 72, 70), (205, 90, 42, 52))):
        color = (*((accent if index % 2 == 0 else cool)), 116 + index * 18)
        draw.ellipse((x0 + cx - rx, y0 + cy - ry, x0 + cx + rx, y0 + cy + ry), fill=color)

    # 1: spiral galaxy.
    x0, y0, x1, y1 = cell_box(1, 8)
    import math
    for arm in range(3):
        points = []
        for step in range(54):
            radius = 6 + step * 2.0
            angle = arm * math.tau / 3 + step * 0.25
            points.append((x0 + 128 + round(math.cos(angle) * radius),
                           y0 + 128 + round(math.sin(angle) * radius * 0.53)))
        emission.line(points, fill=(*(cool if arm % 2 else accent), 230), width=8)
    emission.ellipse((x0 + 105, y0 + 105, x0 + 151, y0 + 151), fill=(*gold, 255))

    # 2: ringed planet.
    x0, y0, x1, y1 = cell_box(2, 8)
    emission.ellipse((x0 + 20, y0 + 98, x1 - 20, y0 + 168), outline=(*gold, 225), width=12)
    draw.ellipse((x0 + 66, y0 + 48, x1 - 66, y1 - 40), fill=(*cool, 255),
                 outline=(*accent, 255), width=8)
    draw.arc((x0 + 20, y0 + 98, x1 - 20, y0 + 168), 5, 175, fill=(*gold, 255), width=12)

    # 3: star nursery with a small moon.
    x0, y0, x1, y1 = cell_box(3, 8)
    draw.ellipse((x0 + 42, y0 + 40, x0 + 128, y0 + 126), fill=(196, 214, 242, 245))
    draw.ellipse((x0 + 70, y0 + 28, x0 + 142, y0 + 112), fill=(8, 8, 30, 255))
    for index in range(18):
        sx = x0 + 22 + ((index * 61) % 212)
        sy = y0 + 24 + ((index * 97) % 205)
        add_star(emission, sx, sy, 4 + (index % 3) * 2,
                 (*(gold if index % 5 == 0 else cool), 255))


def draw_violet_billboards(draw: ImageDraw.ImageDraw, emission: ImageDraw.ImageDraw,
                           accent, cool, gold) -> None:
    # 0: dense violet clump.
    x0, y0, x1, y1 = cell_box(0, 4)
    for flower in range(13):
        cx = x0 + 20 + ((flower * 47) % 220)
        cy = y0 + 72 + ((flower * 31) % 148)
        draw.line((cx, y1, cx + ((flower % 3) - 1) * 15, cy), fill=(*cool, 255), width=7)
        for dx, dy in ((-13, 0), (13, 0), (0, -13), (0, 13), (-9, -9)):
            draw.ellipse((cx + dx - 9, cy + dy - 9, cx + dx + 9, cy + dy + 9),
                         fill=(*accent, 248))
        emission.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(*gold, 255))

    # 1: climbing vine arch.
    x0, y0, x1, y1 = cell_box(1, 4)
    points = [(x0 + 24, y1), (x0 + 32, y0 + 112), (x0 + 76, y0 + 34),
              (x0 + 128, y0 + 15), (x1 - 76, y0 + 34),
              (x1 - 32, y0 + 112), (x1 - 24, y1)]
    draw.line(points, fill=(*cool, 255), width=16, joint="curve")
    for index, (px, py) in enumerate(points[1:-1]):
        draw.ellipse((px - 25, py - 12, px + 2, py + 13), fill=(*cool, 235))
        draw.ellipse((px - 2, py - 13, px + 25, py + 12), fill=(*cool, 235))
        if index % 2 == 0:
            draw.ellipse((px - 13, py - 34, px + 13, py - 8), fill=(*accent, 245))

    # 2: prominent foreground bloom.
    x0, y0, x1, y1 = cell_box(2, 4)
    draw.line((x0 + 128, y1, x0 + 128, y0 + 112), fill=(*cool, 255), width=18)
    for index in range(8):
        import math
        angle = index * math.tau / 8
        cx = x0 + 128 + round(math.cos(angle) * 58)
        cy = y0 + 100 + round(math.sin(angle) * 46)
        draw.ellipse((cx - 31, cy - 44, cx + 31, cy + 44), fill=(*accent, 248))
    emission.ellipse((x0 + 91, y0 + 63, x0 + 165, y0 + 137), fill=(*gold, 255))

    # 3: far field strip with vines rising above it.
    x0, y0, x1, y1 = cell_box(3, 4)
    draw.rectangle((x0, y0 + 156, x1, y1), fill=(*cool, 232))
    for index in range(17):
        cx = x0 + 7 + index * 15
        cy = y0 + 137 - (index % 4) * 14
        draw.line((cx, y1, cx, cy), fill=(*cool, 255), width=4)
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(*accent, 246))
        if index % 3 == 0:
            emission.point((cx, cy), fill=(*gold, 255))


def draw_stage_mesh_surfaces(stage: int, layers: dict[str, Image.Image], palette) -> None:
    """Paint the three opaque mesh regions as actual location materials.

    The former atlases used high-contrast checker fills to make UV regions easy
    to debug. Those guides survived into the shipped art and read as missing
    textures, so every quadrant now has a dense, stage-authored material.
    """
    ink, mid, accent, cool, gold = palette
    base_image = layers["base_materials"]
    base = ImageDraw.Draw(base_image)
    detail = ImageDraw.Draw(layers["surface_detail"])
    motif = ImageDraw.Draw(layers["stage_motifs"])
    emission = ImageDraw.Draw(layers["emissive_details"])
    highlight = ImageDraw.Draw(layers["highlights"])
    ground = (0, 0, HALF - 1, HALF - 1)
    architecture = (HALF, 0, 1023, HALF - 1)
    accent_region = (0, HALF, HALF - 1, 1023)

    if stage == 1:
        # Hammered iron road, soot-dark forge walls, and a molten foundry bed.
        gradient_box(base_image, ground, ink, (72, 35, 40))
        for y in range(26, HALF, 62):
            detail.line((0, y, HALF - 1, y - 8), fill=(129, 76, 62, 210), width=5)
            offset = 34 if (y // 62) % 2 else 0
            for x in range(offset, HALF, 86):
                detail.line((x, y - 62, x - 5, y), fill=(91, 70, 78, 190), width=4)
                detail.ellipse((x - 4, y - 35, x + 4, y - 27), fill=(*gold, 180))
        for crack in range(24):
            x = 12 + ((crack * 79) % 478)
            y = 18 + ((crack * 137) % 468)
            detail.line((x, y, x + 18, y + 7, x + 29, y - 5), fill=(19, 13, 22, 190), width=3)

        gradient_box(base_image, architecture, (72, 34, 42), ink)
        for panel in range(6):
            left = HALF + panel * 86
            detail.rounded_rectangle((left + 7, 14, min(1017, left + 79), 496), 10,
                                     outline=(111, 91, 104, 235), width=5)
            for bolt_y in range(40, 490, 76):
                highlight.ellipse((left + 13, bolt_y, left + 19, bolt_y + 6), fill=(*gold, 210))
        for slit in range(5):
            x = HALF + 54 + slit * 102
            emission.rounded_rectangle((x, 134, x + 18, 438), 8, fill=(*accent, 225))
            highlight.line((x + 6, 144, x + 6, 426), fill=(*gold, 180), width=3)

        gradient_box(base_image, accent_region, (93, 38, 37), (31, 18, 28))
        for flow in range(7):
            x = 18 + flow * 75
            emission.line((x, 1008, x + 28, 790, x - 5, 618), fill=(*accent, 225), width=17)
            highlight.line((x + 4, 1008, x + 32, 790, x - 1, 618), fill=(*gold, 180), width=5)
        for island in range(14):
            x = 10 + ((island * 97) % 468)
            y = 560 + ((island * 71) % 420)
            motif.polygon([(x, y + 24), (x + 22, y), (x + 52, y + 11),
                           (x + 61, y + 43), (x + 17, y + 52)], fill=(*ink, 245))

    elif stage == 2:
        # Mossy forest floor, ancient bark halls, and a flowering rabbit glade.
        gradient_box(base_image, ground, (18, 43, 38), (52, 82, 55))
        for root in range(12):
            x = 12 + root * 46
            points = [(x, 512), (x - 18, 370), (x + 16, 244), (x - 8, 80)]
            detail.line(points, fill=(92, 64, 46, 220), width=8, joint="curve")
        for leaf in range(92):
            x = 7 + ((leaf * 67) % 494)
            y = 8 + ((leaf * 109) % 494)
            shade = cool if leaf % 3 else (92, 148, 84)
            motif.ellipse((x, y, x + 9 + leaf % 8, y + 5 + leaf % 5), fill=(*shade, 190))
            if leaf % 13 == 0:
                emission.ellipse((x + 3, y - 4, x + 11, y + 4), fill=(*accent, 230))

        gradient_box(base_image, architecture, (72, 67, 48), (28, 49, 42))
        for trunk in range(6):
            center = HALF + 44 + trunk * 90
            detail.line((center, 0, center - 18, 132, center + 14, 272,
                         center - 9, 511), fill=(104, 73, 50, 245), width=42)
            highlight.line((center - 8, 0, center - 22, 132, center + 2, 272,
                            center - 18, 511), fill=(*gold, 76), width=5)
            motif.ellipse((center - 28, 196, center + 17, 251),
                          outline=(40, 27, 28, 220), width=8)
        for moss in range(34):
            x = HALF + ((moss * 73) % 500)
            y = 12 + ((moss * 131) % 480)
            motif.ellipse((x, y, x + 28, y + 16), fill=(*cool, 165))

        gradient_box(base_image, accent_region, (43, 83, 58), (19, 45, 39))
        for blade in range(78):
            x = 4 + ((blade * 43) % 504)
            top = 550 + ((blade * 59) % 350)
            detail.line((x, 1023, x + ((blade % 5) - 2) * 7, top), fill=(*cool, 205), width=3)
        for flower in range(32):
            x = 12 + ((flower * 83) % 482)
            y = 565 + ((flower * 127) % 425)
            motif.ellipse((x - 11, y - 4, x + 11, y + 4), fill=(*accent, 230))
            motif.ellipse((x - 4, y - 11, x + 4, y + 11), fill=(*accent, 230))
            emission.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(*gold, 255))
        for print_index in range(10):
            x = 54 + print_index * 43
            y = 610 + (print_index % 4) * 88
            motif.ellipse((x, y, x + 15, y + 29), fill=(231, 219, 184, 115))
            motif.ellipse((x + 18, y - 7, x + 33, y + 22), fill=(231, 219, 184, 115))

    elif stage == 3:
        # Casino carpet, velvet proscenium, and a split trick/sorcery stage.
        gradient_box(base_image, ground, (42, 12, 62), (91, 20, 76))
        for ring in range(7):
            radius = 46 + ring * 38
            detail.ellipse((256 - radius, 256 - radius, 256 + radius, 256 + radius),
                           outline=(*gold, 125), width=4)
        for suit in range(28):
            x = 16 + ((suit * 79) % 480)
            y = 18 + ((suit * 137) % 474)
            color = accent if suit % 2 else cool
            motif.polygon([(x, y - 10), (x + 10, y), (x, y + 14), (x - 10, y)],
                          fill=(*color, 180))
            if suit % 5 == 0:
                highlight.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(*gold, 230))

        gradient_box(base_image, architecture, (73, 18, 83), (22, 11, 40))
        for fold in range(11):
            x = HALF + fold * 49
            detail.polygon([(x, 0), (x + 24, 0), (x + 42, 511), (x - 10, 511)],
                           fill=(*(accent if fold % 2 else mid), 82))
            highlight.line((x + 4, 0, x + 20, 511), fill=(*gold, 80), width=3)
        for bulb in range(22):
            x = HALF + 18 + bulb * 23
            emission.ellipse((x - 5, 22, x + 5, 32), fill=(*gold, 245))
            emission.ellipse((x - 5, 478, x + 5, 488), fill=(*cool, 225))

        gradient_box(base_image, accent_region, (66, 18, 84), (18, 12, 42))
        base.rectangle((0, HALF, 252, 1023), fill=(77, 18, 67, 255))
        for radius in (54, 104, 156, 208):
            motif.arc((126 - radius, 768 - radius, 126 + radius, 768 + radius),
                      200, 520, fill=(*gold, 195), width=7)
        for pip in range(18):
            x = 20 + ((pip * 61) % 214)
            y = 548 + ((pip * 101) % 444)
            emission.ellipse((x - 6, y - 6, x + 6, y + 6),
                             fill=(*(accent if pip % 2 else gold), 230))
        for radius in (48, 92, 132, 184):
            motif.ellipse((382 - radius, 768 - radius, 382 + radius, 768 + radius),
                          outline=(*cool, 190), width=5)
        for arm in range(12):
            import math
            angle = arm * math.tau / 12
            emission.line((382, 768, 382 + round(math.cos(angle) * 208),
                           768 + round(math.sin(angle) * 208)), fill=(*gold, 135), width=3)

    elif stage == 4:
        # Nebulae replace any terrestrial floor; the architecture is an orrery.
        gradient_box(base_image, ground, (5, 7, 28), (42, 19, 76))
        for cloud in range(18):
            x = 10 + ((cloud * 89) % 480)
            y = 12 + ((cloud * 157) % 470)
            radius = 28 + (cloud % 6) * 15
            color = accent if cloud % 3 == 0 else cool
            motif.ellipse((x - radius, y - radius // 2, x + radius, y + radius // 2),
                          fill=(*color, 42 + (cloud % 4) * 13))
        for star in range(180):
            x = (star * 83) % 510
            y = (star * 149) % 510
            radius = 1 + (star % 5 == 0) + (star % 17 == 0)
            emission.ellipse((x - radius, y - radius, x + radius, y + radius),
                             fill=(*(gold if star % 11 == 0 else cool), 220))

        gradient_box(base_image, architecture, (17, 16, 52), (5, 8, 30))
        for radius in (58, 104, 158, 218, 282):
            motif.ellipse((768 - radius, 256 - radius // 2,
                           768 + radius, 256 + radius // 2),
                          outline=(*(gold if radius % 2 else cool), 150), width=5)
        for spoke in range(16):
            import math
            angle = spoke * math.tau / 16
            detail.line((768, 256, 768 + round(math.cos(angle) * 290),
                         256 + round(math.sin(angle) * 145)),
                        fill=(90, 89, 132, 140), width=3)
        for planet in range(8):
            x = HALF + 44 + planet * 61
            y = 72 + (planet % 4) * 108
            emission.ellipse((x - 12, y - 12, x + 12, y + 12),
                             fill=(*(accent if planet % 2 else gold), 240))

        gradient_box(base_image, accent_region, (36, 17, 78), (6, 8, 31))
        for cloud in range(14):
            x = 15 + ((cloud * 101) % 475)
            y = 542 + ((cloud * 173) % 456)
            rx = 42 + (cloud % 5) * 17
            ry = 20 + (cloud % 4) * 13
            color = accent if cloud % 2 else cool
            motif.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(*color, 92))
        for planet, (x, y, radius) in enumerate(((96, 654, 52), (338, 820, 78), (188, 944, 34))):
            base.ellipse((x - radius, y - radius, x + radius, y + radius),
                         fill=(*(cool if planet % 2 else accent), 255))
            highlight.arc((x - radius - 24, y - radius // 2,
                           x + radius + 24, y + radius // 2), 5, 175,
                          fill=(*gold, 230), width=8)

    else:
        # Dense violet meadow, vine-covered ruins, and an endless flower field.
        gradient_box(base_image, ground, (20, 45, 37), (55, 75, 54))
        for grass in range(150):
            x = 2 + ((grass * 47) % 508)
            y = 44 + ((grass * 83) % 466)
            detail.line((x, y + 18, x + ((grass % 5) - 2) * 3, y),
                        fill=(*cool, 165), width=2)
            if grass % 9 == 0:
                motif.ellipse((x - 8, y - 4, x + 8, y + 4), fill=(*accent, 220))
                emission.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(*gold, 240))

        gradient_box(base_image, architecture, (53, 53, 73), (24, 31, 42))
        for stone_y in range(18, 512, 76):
            detail.line((HALF, stone_y, 1023, stone_y - 12), fill=(112, 104, 128, 150), width=4)
        for vine in range(9):
            x = HALF + 26 + vine * 61
            points = [(x, 511), (x + 20, 382), (x - 11, 250), (x + 18, 106), (x, 0)]
            motif.line(points, fill=(*cool, 230), width=9, joint="curve")
            for leaf in range(5):
                y = 50 + leaf * 92 + (vine % 2) * 18
                motif.ellipse((x - 25, y - 10, x + 1, y + 12), fill=(*cool, 210))
                motif.ellipse((x - 1, y - 12, x + 25, y + 10), fill=(*cool, 210))
                if (leaf + vine) % 3 == 0:
                    motif.ellipse((x - 11, y - 31, x + 11, y - 9), fill=(*accent, 230))

        gradient_box(base_image, accent_region, (46, 84, 52), (22, 46, 38))
        for stem in range(74):
            x = 4 + ((stem * 37) % 504)
            y = 548 + ((stem * 97) % 438)
            tip_x = x + ((stem % 7) - 3) * 4
            detail.line((x, 1023, tip_x, y), fill=(*cool, 220), width=4)
            petal = 9 + stem % 7
            for dx, dy in ((-petal, 0), (petal, 0), (0, -petal), (0, petal),
                           (-petal * 2 // 3, -petal * 2 // 3)):
                motif.ellipse((tip_x + dx - 6, y + dy - 6,
                               tip_x + dx + 6, y + dy + 6), fill=(*accent, 225))
            emission.ellipse((tip_x - 3, y - 3, tip_x + 3, y + 3), fill=(*gold, 255))

    # Fine deterministic grain keeps the 1024px sources rich when magnified,
    # while never resolving into debugging squares at the 640x360 output size.
    for fleck in range(420):
        x = (fleck * 83 + stage * 29) % 1018
        y = (fleck * 151 + stage * 47) % 1018
        if x >= HALF and y >= HALF:
            continue
        color = (*gold, 28) if fleck % 5 == 0 else (*ink, 36)
        detail.ellipse((x, y, x + 1 + fleck % 3, y + 1 + fleck % 2), fill=color)


def build_texture(stage: int) -> tuple[dict[str, Image.Image], list[str]]:
    theme = THEMES[stage]
    ink, mid, accent, cool, gold = theme["palette"]
    names = [
        "base_materials",
        "surface_detail",
        "stage_motifs",
        "billboard_back_glow",
        "billboard_silhouettes",
        "emissive_details",
        "highlights",
    ]
    layers = {name: layer(SIZE) for name in names}
    base = ImageDraw.Draw(layers["base_materials"])
    detail = ImageDraw.Draw(layers["surface_detail"])
    motif = ImageDraw.Draw(layers["stage_motifs"])
    glow = ImageDraw.Draw(layers["billboard_back_glow"])
    billboard = ImageDraw.Draw(layers["billboard_silhouettes"])
    emission = ImageDraw.Draw(layers["emissive_details"])
    highlight = ImageDraw.Draw(layers["highlights"])

    # Opaque mesh quadrants: location-authored ground, architecture, and accents.
    draw_stage_mesh_surfaces(stage, layers, theme["palette"])

    if stage == 1:
        for x in range(34, 490, 76):
            motif.polygon([(x, 730), (x + 28, 688), (x + 58, 730),
                           (x + 46, 815), (x + 12, 815)], fill=(*accent, 255), outline=(*gold, 255))
        for y in range(548, 1000, 74):
            emission.line((24, y, 486, y - 32), fill=(*gold, 210), width=8)
    elif stage == 2:
        for index in range(36):
            x = 12 + ((index * 71) % 486)
            y = 536 + ((index * 113) % 468)
            motif.ellipse((x, y, x + 18 + index % 11, y + 9 + index % 7), fill=(*cool, 220))
            if index % 4 == 0:
                emission.ellipse((x + 5, y - 7, x + 15, y + 3), fill=(*accent, 255))
    elif stage == 3:
        for x in range(34, 490, 58):
            motif.polygon([(x, 566), (x + 24, 538), (x + 48, 566),
                           (x + 24, 594)], fill=(*(accent if (x // 58) % 2 else cool), 255),
                          outline=(*gold, 255))
        for y in range(628, 998, 72):
            emission.line((24, y, 488, y), fill=(*gold, 190), width=5)
    elif stage == 4:
        for index in range(28):
            x = 18 + ((index * 97) % 470)
            y = 530 + ((index * 167) % 474)
            add_star(emission, x, y, 4 + index % 7, (*(gold if index % 5 == 0 else cool), 255))
        for radius in (54, 98, 148, 196):
            motif.ellipse((256 - radius, 768 - radius // 2,
                           256 + radius, 768 + radius // 2), outline=(*accent, 190), width=4)
    else:
        for x in range(18, 500, 30):
            motif.line((x, 1015, x + ((x // 30) % 3 - 1) * 26, 558), fill=(*cool, 255), width=8)
            cx = x + ((x // 30) % 3 - 1) * 26
            cy = 594 + ((x * 13) % 272)
            for dx, dy in ((-18, 0), (18, 0), (0, -18), (0, 18), (-13, -13)):
                motif.ellipse((cx + dx - 10, cy + dy - 10,
                               cx + dx + 10, cy + dy + 10), fill=(*accent, 255))
            emission.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(*gold, 255))

    draw_billboard_cell_backdrops(stage, glow)
    if stage == 1:
        draw_forge_billboards(billboard, emission, accent, cool, gold)
    elif stage == 2:
        draw_forest_billboards(billboard, emission, accent, cool, gold)
    elif stage == 3:
        draw_vegas_billboards(billboard, emission, accent, cool, gold)
    elif stage == 4:
        draw_space_billboards(billboard, emission, accent, cool, gold)
    else:
        draw_violet_billboards(billboard, emission, accent, cool, gold)

    highlight.line((2, 2, HALF - 3, 2), fill=(255, 246, 225, 225), width=3)
    highlight.line((HALF + 2, 2, 1021, 2), fill=(*gold, 205), width=3)
    highlight.line((2, HALF + 2, HALF - 3, HALF + 2), fill=(*gold, 210), width=3)
    return layers, names


def export_kra(ora: Path, kra: Path) -> None:
    if not KRITA.exists():
        raise FileNotFoundError(f"Krita is required to create native editable source: {KRITA}")

    # Krita shares a resource database with any open GUI instance. Give the
    # deterministic exporter its own database so an artist can keep Krita open
    # while this build produces genuine native KRA files.
    cli_root = ROOT / "tmp" / "krita-cli"
    config_dir = cli_root / "config"
    data_dir = cli_root / "data"
    cache_dir = cli_root / "cache"
    resource_dir = cli_root / "resources"
    for directory in (config_dir, data_dir, cache_dir, resource_dir):
        directory.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["XDG_CONFIG_HOME"] = str(config_dir)
    env["XDG_DATA_HOME"] = str(data_dir)
    env["XDG_CACHE_HOME"] = str(cache_dir)

    subprocess.run(
        [str(KRITA), "--nosplash", "--resource-location", str(resource_dir),
         "--export", "--export-filename", str(kra), str(ora)],
        check=True,
        env=env,
    )
    if not kra.exists() or kra.stat().st_size <= 0:
        raise RuntimeError(f"Krita did not create {kra}")


def main() -> None:
    manifest = []
    for stage, theme in THEMES.items():
        layers, order = build_texture(stage)
        merged = composite(layers, order)
        stage_dir = SOURCE / f"stage_{stage:02d}_{theme['slug']}"
        stage_dir.mkdir(parents=True, exist_ok=True)
        for name, image in layers.items():
            image.save(stage_dir / f"{name}.png")
        runtime_png = stage_dir / f"{theme['slug']}_runtime_texture.png"
        merged.save(runtime_png)
        ora = stage_dir / f"{theme['slug']}_texture.ora"
        kra = stage_dir / f"{theme['slug']}_texture.kra"
        write_ora(ora, layers, order, merged)
        export_kra(ora, kra)
        install_sprite(theme["sprite"], merged)
        manifest.append({
            "stage": stage,
            "theme": theme["slug"],
            "location": theme["location"],
            "sprite": theme["sprite"],
            "resolution": list(SIZE),
            "mesh_regions": {
                "ground": [0, 0, 511, 511],
                "architecture": [512, 0, 1023, 511],
                "modeled_accents": [0, 512, 511, 1023],
            },
            "billboard_cells": [
                [512, 512, 767, 767],
                [768, 512, 1023, 767],
                [512, 768, 767, 1023],
                [768, 768, 1023, 1023],
            ],
            "openraster_source": str(ora.relative_to(ROOT)),
            "krita_source": str(kra.relative_to(ROOT)),
            "runtime_png": str(runtime_png.relative_to(ROOT)),
            "layers": [name.replace("_", " ").title() for name in order],
        })
    SOURCE.mkdir(parents=True, exist_ok=True)
    (SOURCE / "stage_3d_texture_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Built {len(manifest)} layered 1024px 3D stage atlases and native KRA sources.")


if __name__ == "__main__":
    main()

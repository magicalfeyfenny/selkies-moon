#!/usr/bin/env python3
"""Build high-resolution layered texture atlases for the five 3D locations.

Each 1024px atlas reserves three opaque quadrants for modeled surfaces and a
transparent 2x2 cell sheet for camera-facing billboard cards. OpenRaster is
kept as an interchange source and Krita converts it to a native editable KRA.
"""

from __future__ import annotations

import json
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


def checker(draw: ImageDraw.ImageDraw, box, left, right, step: int = 32) -> None:
    x0, y0, x1, y1 = box
    draw.rectangle(box, fill=left)
    for y in range(y0, y1 + 1, step):
        for x in range(x0, x1 + 1, step):
            if ((x - x0) // step + (y - y0) // step) % 2:
                draw.rectangle(
                    (x, y, min(x1, x + step - 1), min(y1, y + step - 1)),
                    fill=right,
                )


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

    # Opaque mesh quadrants: ground, architecture, and modeled accents.
    checker(base, (0, 0, HALF - 1, HALF - 1), (*ink, 255), (*mid, 255), 48)
    checker(base, (HALF, 0, 1023, HALF - 1), (*mid, 255), (*ink, 255), 36)
    checker(base, (0, HALF, HALF - 1, 1023), (*accent, 255), (*mid, 255), 44)

    # High-resolution seams, grain, rivets, bark, carpet, stars, and leaf litter.
    for y in range(24, HALF, 48):
        detail.line((0, y, HALF - 1, y), fill=(*gold, 150), width=3)
        for x in range((y // 48 % 2) * 42, HALF, 84):
            detail.line((x, y - 24, x, y + 24), fill=(*gold, 95), width=3)
    for x in range(HALF + 18, 1024, 32):
        detail.line((x, 0, x, HALF - 1), fill=(*cool, 115), width=2)
    for index in range(160):
        x = (index * 83) % 1018
        y = (index * 151) % 1018
        if x >= HALF and y >= HALF:
            continue
        color = (*gold, 44) if index % 3 == 0 else (*ink, 54)
        detail.rectangle((x, y, x + 2 + index % 5, y + 2 + index % 4), fill=color)

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
    subprocess.run(
        [str(KRITA), "--export", "--export-filename", str(kra), str(ora)],
        check=True,
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

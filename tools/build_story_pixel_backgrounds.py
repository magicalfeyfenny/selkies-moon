#!/usr/bin/env python3
"""Build layered pixel-art story scenes and assign them to story chapters."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

from build_gameplay_art import ROOT, install_sprite
from build_core_pixel_art import composite, layer, write_ora


PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"
SOURCE = ROOT / "art" / "story_background_sources"
DATAFILES = PROJECT / "datafiles"
AUTHOR_SIZE = (320, 180)
RUNTIME_SIZE = (640, 360)


SCENES = {
    "core_chapel": "spr_story_bg_core_chapel",
    "forge_twilight": "spr_story_bg_forge_twilight",
    "saltwind_ribbon": "spr_story_bg_saltwind_ribbon",
    "wishcourt": "spr_story_bg_wishcourt",
    "bloodstar_orrery": "spr_story_bg_bloodstar_orrery",
    "violet_horizon": "spr_story_bg_violet_horizon",
    "morning_reunion": "spr_story_bg_morning_reunion",
}


PALETTES = {
    "core_chapel": ((12, 8, 34), (62, 36, 94), (160, 84, 180), (95, 210, 212), (245, 211, 148)),
    "forge_twilight": ((24, 8, 26), (104, 34, 38), (222, 92, 42), (246, 174, 70), (255, 226, 158)),
    "saltwind_ribbon": ((24, 22, 62), (92, 76, 144), (213, 118, 188), (103, 216, 207), (246, 226, 205)),
    "wishcourt": ((17, 9, 37), (69, 30, 89), (214, 73, 158), (75, 184, 218), (245, 201, 114)),
    "bloodstar_orrery": ((8, 6, 25), (40, 25, 73), (183, 48, 91), (105, 177, 222), (241, 197, 91)),
    "violet_horizon": ((17, 9, 39), (87, 45, 116), (224, 89, 166), (87, 207, 180), (251, 205, 113)),
    "morning_reunion": ((36, 28, 69), (168, 82, 128), (245, 139, 121), (112, 215, 205), (255, 232, 164)),
}


def banded_sky(draw: ImageDraw.ImageDraw, top, bottom) -> None:
    for band in range(18):
        t = band / 17
        color = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        y1 = band * 10
        draw.rectangle((0, y1, 319, min(179, y1 + 10)), fill=(*color, 255))


def ordered_sky_dither(target: Image.Image, top, bottom) -> None:
    pixels = target.load()
    bayer = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    for y in range(8, 122):
        t = y / 180
        color = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        for x in range(320):
            if bayer[y % 4][x % 4] == 0:
                pixels[x, y] = (*color, 80)


def arch(draw: ImageDraw.ImageDraw, cx: int, floor: int, width: int, height: int, fill, edge) -> None:
    left, right = cx - width // 2, cx + width // 2
    top = floor - height
    draw.rectangle((left, top + width // 2, right, floor), fill=fill)
    draw.ellipse((left, top, right, top + width), fill=fill, outline=edge, width=2)
    draw.rectangle((left + 3, top + width // 2, right - 3, floor), fill=fill)
    draw.line((left, top + width // 2, left, floor), fill=edge, width=2)
    draw.line((right, top + width // 2, right, floor), fill=edge, width=2)


def rose_window(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int, colors) -> None:
    ink, accent, cool, gold = colors
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=ink, outline=gold, width=2)
    draw.ellipse((cx - radius + 4, cy - radius + 4, cx + radius - 4, cy + radius - 4), outline=cool, width=1)
    for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        px, py = cx + dx * (radius - 6), cy + dy * (radius - 6)
        draw.rectangle((px - 3, py - 3, px + 3, py + 3), fill=accent)
    draw.rectangle((cx - 2, cy - 2, cx + 2, cy + 2), fill=gold)


def build_scene(theme: str) -> tuple[dict[str, Image.Image], list[str]]:
    names = ["sky", "sky_dither", "architecture", "midground", "lighting", "atmosphere", "foreground"]
    layers = {name: layer(AUTHOR_SIZE) for name in names}
    sky = ImageDraw.Draw(layers["sky"])
    architecture = ImageDraw.Draw(layers["architecture"])
    midground = ImageDraw.Draw(layers["midground"])
    lighting = ImageDraw.Draw(layers["lighting"])
    atmosphere = ImageDraw.Draw(layers["atmosphere"])
    foreground = ImageDraw.Draw(layers["foreground"])
    top, bottom, accent, cool, gold = PALETTES[theme]
    ink = (9, 5, 22, 255)
    banded_sky(sky, top, bottom)
    ordered_sky_dither(layers["sky_dither"], top, bottom)

    # Pixel stars and dust are deterministic, sparse, and intentionally bright.
    for i in range(34):
        x = (i * 83 + 19) % 316 + 2
        y = (i * 47 + 11) % 105 + 3
        atmosphere.point((x, y), fill=(*((gold if i % 5 == 0 else cool)), 170))

    if theme == "core_chapel":
        architecture.rectangle((0, 118, 319, 179), fill=(13, 8, 30, 255))
        for cx in (55, 160, 265):
            arch(architecture, cx, 165, 58, 112, (24, 16, 52, 255), (*accent, 255))
            rose_window(midground, cx, 80, 18, (ink, (*accent, 255), (*cool, 255), (*gold, 255)))
        architecture.polygon([(128, 118), (160, 31), (192, 118)], fill=(18, 11, 42, 255), outline=(*gold, 255))
        lighting.polygon([(160, 45), (112, 175), (208, 175)], fill=(*cool, 36))
        foreground.rectangle((0, 164, 319, 179), fill=(8, 5, 20, 255))
        for x in range(8, 320, 24):
            foreground.line((x, 164, x + 8, 179), fill=(*accent, 255), width=1)

    elif theme == "forge_twilight":
        architecture.rectangle((0, 108, 319, 179), fill=(24, 11, 24, 255))
        for x, height in ((18, 71), (62, 90), (244, 84), (288, 66)):
            architecture.rectangle((x, 108 - height, x + 20, 132), fill=(32, 19, 33, 255), outline=(*accent, 255))
            architecture.rectangle((x + 5, 108 - height - 10, x + 15, 108 - height), fill=(13, 8, 22, 255))
        midground.rectangle((115, 102, 205, 150), fill=(45, 22, 32, 255), outline=(*gold, 255), width=2)
        midground.polygon([(129, 121), (190, 121), (178, 132), (139, 132)], fill=(*accent, 255), outline=(*gold, 255))
        lighting.rectangle((126, 105, 194, 117), fill=(*gold, 110))
        for i in range(18):
            x = 134 + ((i * 17) % 52)
            y = 105 - ((i * 13) % 42)
            atmosphere.point((x, y), fill=(*gold, 230))
        foreground.polygon([(0, 154), (76, 145), (130, 162), (198, 146), (249, 158), (319, 145), (319, 179), (0, 179)],
                           fill=(10, 6, 18, 255))

    elif theme == "saltwind_ribbon":
        architecture.polygon([(0, 111), (45, 91), (78, 119), (118, 83), (160, 119),
                              (207, 88), (251, 116), (286, 92), (319, 112), (319, 179), (0, 179)],
                             fill=(37, 34, 76, 255), outline=(*cool, 255))
        midground.rectangle((0, 127, 319, 179), fill=(32, 91, 116, 255))
        for band in range(5):
            midground.line((0, 137 + band * 8, 319, 132 + band * 9), fill=(*cool, 170), width=1)
        for offset in (0, 1):
            points = []
            for x in range(-10, 331, 20):
                y = 51 + offset * 35 + ((x // 20) % 2) * 12
                points.append((x, y))
            atmosphere.line(points, fill=(*((accent if offset == 0 else gold)), 220), width=3)
        foreground.polygon([(0, 158), (65, 151), (117, 162), (178, 151), (238, 164), (319, 153), (319, 179), (0, 179)],
                           fill=(15, 11, 35, 255))

    elif theme == "wishcourt":
        architecture.rectangle((0, 109, 319, 179), fill=(18, 9, 35, 255))
        arch(architecture, 160, 165, 116, 133, (35, 17, 59, 255), (*gold, 255))
        for cx, color in ((100, accent), (220, cool)):
            rose_window(midground, cx, 72, 25, (ink, (*color, 255), (*cool, 255), (*gold, 255)))
        midground.polygon([(132, 130), (160, 111), (188, 130), (160, 149)], fill=(*accent, 255), outline=(*gold, 255))
        midground.ellipse((145, 116, 175, 146), outline=(*cool, 255), width=2)
        lighting.polygon([(88, 54), (136, 175), (70, 175)], fill=(*accent, 34))
        lighting.polygon([(232, 54), (184, 175), (250, 175)], fill=(*cool, 34))
        foreground.rectangle((0, 160, 319, 179), fill=(7, 4, 17, 255))
        for x in range(0, 320, 16):
            foreground.polygon([(x, 160), (x + 8, 166), (x + 16, 160)], outline=(*gold, 255))

    elif theme == "bloodstar_orrery":
        architecture.rectangle((0, 112, 319, 179), fill=(12, 8, 27, 255))
        rose_window(midground, 160, 77, 48, (ink, (*accent, 255), (*cool, 255), (*gold, 255)))
        for radius, color in ((62, cool), (75, gold)):
            midground.ellipse((160 - radius, 77 - radius // 2, 160 + radius, 77 + radius // 2),
                              outline=(*color, 255), width=1)
        for angle_index in range(8):
            x = 160 + (-60 + angle_index * 17)
            y = 77 + ((angle_index % 3) - 1) * 18
            midground.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(*accent, 255), outline=(*gold, 255))
        foreground.polygon([(0, 150), (85, 136), (160, 151), (235, 136), (319, 150), (319, 179), (0, 179)],
                           fill=(6, 4, 16, 255))
        for x in range(10, 319, 28):
            foreground.line((x, 145, x + 8, 179), fill=(*cool, 255), width=1)

    elif theme == "violet_horizon":
        lighting.ellipse((104, 35, 172, 103), fill=(*accent, 90), outline=(*gold, 255), width=2)
        lighting.ellipse((151, 39, 215, 103), fill=(*gold, 72), outline=(*cool, 255), width=2)
        architecture.polygon([(0, 125), (54, 105), (94, 121), (141, 96), (191, 121),
                              (239, 100), (283, 118), (319, 107), (319, 179), (0, 179)],
                             fill=(30, 20, 55, 255))
        for x in range(12, 320, 26):
            stem_top = 112 + ((x * 7) % 27)
            midground.line((x, 179, x + ((x % 3) - 1) * 9, stem_top), fill=(47, 139, 101, 255), width=2)
            fx, fy = x + ((x % 3) - 1) * 9, stem_top
            for dx, dy in ((-4, 0), (4, 0), (0, -4), (0, 4)):
                midground.rectangle((fx + dx - 2, fy + dy - 2, fx + dx + 2, fy + dy + 2), fill=(*accent, 255))
            midground.point((fx, fy), fill=(*gold, 255))
        foreground.rectangle((0, 164, 319, 179), fill=(8, 5, 18, 255))

    else:  # morning_reunion
        lighting.ellipse((120, 35, 200, 115), fill=(*gold, 105))
        architecture.polygon([(0, 121), (44, 102), (84, 117), (129, 94), (174, 118),
                              (223, 99), (267, 120), (319, 101), (319, 179), (0, 179)],
                             fill=(54, 50, 88, 255))
        arch(midground, 160, 160, 94, 115, (29, 25, 52, 255), (*gold, 255))
        midground.rectangle((151, 64, 169, 160), fill=(*cool, 70))
        for side in (-1, 1):
            midground.line((160, 118, 160 + side * 96, 178), fill=(*accent, 255), width=2)
            midground.line((160, 124, 160 + side * 72, 178), fill=(*cool, 255), width=1)
        foreground.polygon([(0, 157), (67, 148), (118, 161), (160, 151), (205, 162), (265, 148), (319, 158),
                            (319, 179), (0, 179)], fill=(18, 12, 33, 255))

    return layers, names


def save_scene(theme: str, sprite: str) -> dict:
    layers, order = build_scene(theme)
    merged = composite(layers, order)
    runtime = merged.resize(RUNTIME_SIZE, Image.Resampling.NEAREST)
    directory = SOURCE / theme
    directory.mkdir(parents=True, exist_ok=True)
    for name, image in layers.items():
        image.save(directory / f"{name}.png")
    merged.save(directory / f"{theme}_author_preview.png")
    runtime.save(directory / f"{theme}_runtime_preview.png")
    ora = directory / f"{theme}.ora"
    write_ora(ora, layers, order, merged)
    install_sprite(sprite, runtime)
    return {
        "theme": theme,
        "sprite": sprite,
        "openraster_source": str(ora.relative_to(ROOT)),
        "krita_source": str(ora.with_suffix(".kra").relative_to(ROOT)),
        "author_size": list(AUTHOR_SIZE),
        "runtime_size": list(RUNTIME_SIZE),
        "layers": [name.replace("_", " ").title() for name in order],
    }


def background_for_story(filename: str) -> str:
    stem = Path(filename).stem
    if stem.endswith("_v2"):
        stem = stem[:-3]
    if stem == "opening_story":
        return SCENES["core_chapel"]
    if stem.startswith("shalmii_"):
        return SCENES["forge_twilight"]
    if stem.startswith("aster_"):
        return SCENES["saltwind_ribbon"]
    if stem.startswith("mira_") or stem.startswith("aisha_"):
        return SCENES["wishcourt"]
    if stem.startswith("caelia_"):
        return SCENES["bloodstar_orrery"]
    if stem.startswith("boss_intro_story"):
        return SCENES["violet_horizon"]
    if stem.startswith("ending_story"):
        return SCENES["morning_reunion"]
    raise ValueError(f"No story background mapping for {filename}")


def assign_story_backgrounds() -> dict[str, str]:
    assignments = {}
    for path in sorted(DATAFILES.glob("*.json")):
        background = background_for_story(path.name)
        payload = json.loads(path.read_text(encoding="utf-8"))
        for frame in payload:
            frame["backgrounds"] = [background]
        path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        assignments[path.name] = background
    return assignments


def main() -> None:
    manifest = [save_scene(theme, sprite) for theme, sprite in SCENES.items()]
    assignments = assign_story_backgrounds()
    SOURCE.mkdir(parents=True, exist_ok=True)
    (SOURCE / "story_background_manifest.json").write_text(
        json.dumps({"scenes": manifest, "story_assignments": assignments}, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Built {len(manifest)} layered story scenes and assigned {len(assignments)} story files.")


if __name__ == "__main__":
    main()

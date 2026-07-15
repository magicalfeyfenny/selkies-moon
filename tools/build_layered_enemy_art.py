#!/usr/bin/env python3
"""Build layered neo-Gothic enemy art, OpenRaster sources, and GameMaker sprites."""

from __future__ import annotations

import json
import math
import zipfile
from dataclasses import dataclass
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw

from build_gameplay_art import install_sprite


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "enemy_sources"
SIZE = 64
SCALE = 1
HI = SIZE * SCALE


@dataclass(frozen=True)
class Enemy:
    stage: int
    slug: str
    sprite: str
    motif: str
    role: str
    accent: tuple[int, int, int]
    core: tuple[int, int, int]


ENEMIES = (
    Enemy(1, "forge_spark", "spr_enemy_forge_spark", "spark", "chaser", (232, 100, 48), (255, 226, 140)),
    Enemy(1, "anvil_familiar", "spr_enemy_anvil_familiar", "anvil", "anchor", (83, 105, 137), (255, 145, 62)),
    Enemy(1, "bellows_imp", "spr_enemy_bellows_imp", "bellows", "dancer", (136, 55, 62), (255, 204, 100)),
    Enemy(1, "hammer_cherub", "spr_enemy_hammer_cherub", "hammer", "lancer", (151, 112, 212), (255, 202, 104)),
    Enemy(2, "ribbon_hare", "spr_enemy_ribbon_hare", "hare", "chaser", (225, 126, 187), (218, 201, 255)),
    Enemy(2, "winged_staff", "spr_enemy_winged_staff", "staff", "anchor", (151, 118, 220), (99, 220, 243)),
    Enemy(2, "lavender_knot", "spr_enemy_lavender_knot", "knot", "dancer", (190, 126, 228), (255, 238, 209)),
    Enemy(2, "saltwind_pinwheel", "spr_enemy_saltwind_pinwheel", "pinwheel", "lancer", (96, 224, 166), (244, 137, 210)),
    Enemy(3, "spade_familiar", "spr_enemy_spade_familiar", "spade", "chaser", (232, 99, 181), (60, 31, 84)),
    Enemy(3, "dealer_mask", "spr_enemy_dealer_mask", "mask", "anchor", (237, 187, 78), (255, 237, 207)),
    Enemy(3, "order_talisman", "spr_enemy_order_talisman", "talisman", "dancer", (83, 166, 228), (244, 190, 81)),
    Enemy(3, "chaos_shard", "spr_enemy_chaos_shard", "shard", "lancer", (87, 219, 239), (231, 76, 177)),
    Enemy(4, "clockwork_planet", "spr_enemy_clockwork_planet", "planet", "chaser", (205, 128, 230), (240, 72, 109)),
    Enemy(4, "astrolabe_eye", "spr_enemy_astrolabe_eye", "astrolabe", "anchor", (238, 190, 82), (91, 214, 237)),
    Enemy(4, "constellation_lance", "spr_enemy_constellation_lance", "constellation", "dancer", (155, 142, 220), (255, 237, 210)),
    Enemy(4, "bloodstar_heart", "spr_enemy_bloodstar_heart", "heart", "lancer", (235, 58, 96), (241, 183, 82)),
    Enemy(5, "violet_bee", "spr_violet_bee", "bee", "chaser", (130, 62, 183), (244, 190, 74)),
    Enemy(5, "twilight_mayfly", "spr_twilight_mayfly", "mayfly", "dancer", (82, 188, 226), (237, 105, 149)),
    Enemy(5, "thorn_reliquary", "spr_enemy_thorn_reliquary", "reliquary", "anchor", (223, 70, 172), (70, 190, 134)),
    Enemy(5, "chakram_seraph", "spr_enemy_chakram_seraph", "chakram", "lancer", (229, 130, 204), (83, 202, 230)),
)


def sc(value: float) -> int:
    return round(value * SCALE)


def pts(values: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(sc(x), sc(y)) for x, y in values]


def rgba(rgb: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return (*rgb, alpha)


def shade(rgb: tuple[int, int, int], factor: float) -> tuple[int, int, int, int]:
    return rgba(tuple(max(0, min(255, round(c * factor))) for c in rgb))


def mix(
    left: tuple[int, int, int],
    right: tuple[int, int, int],
    amount: float,
    alpha: int = 255,
) -> tuple[int, int, int, int]:
    """Blend two swatches while keeping the result on an authored pixel-art ramp."""
    return rgba(tuple(round(a + (b - a) * amount) for a, b in zip(left, right)), alpha)


def layer() -> Image.Image:
    return Image.new("RGBA", (HI, HI), (0, 0, 0, 0))


def line(draw: ImageDraw.ImageDraw, coordinates: list[tuple[float, float]], fill, width: float = 1) -> None:
    draw.line(pts(coordinates), fill=fill, width=max(1, sc(width)), joint="curve")


def ellipse(draw: ImageDraw.ImageDraw, box: tuple[float, float, float, float], **kwargs) -> None:
    draw.ellipse(tuple(sc(v) for v in box), **kwargs)


def polygon(draw: ImageDraw.ImageDraw, coordinates: list[tuple[float, float]], **kwargs) -> None:
    draw.polygon(pts(coordinates), **kwargs)


def role_hull(enemy: Enemy, layers: dict[str, Image.Image]) -> None:
    # A broader, jewel-toned ramp evokes PC-98/late-2D console art while the
    # near-black violet keeps every silhouette readable over stage effects.
    dark = mix((8, 5, 18), enemy.accent, 0.10)
    deep = mix((15, 8, 30), enemy.accent, 0.28)
    mid = mix(enemy.accent, enemy.core, 0.16)
    accent = rgba(enemy.accent)
    secondary = mix(enemy.accent, enemy.core, 0.58)
    light = mix(enemy.core, (255, 244, 232), 0.30)
    ds = ImageDraw.Draw(layers["silhouette"])
    dm = ImageDraw.Draw(layers["materials"])

    if enemy.motif == "bee":
        for box in ((4, 14, 30, 37), (34, 14, 60, 37), (9, 30, 30, 48), (34, 30, 55, 48)):
            ellipse(ds, box, fill=dark)
        ellipse(dm, (7, 17, 29, 35), fill=(91, 205, 235, 175))
        ellipse(dm, (35, 17, 57, 35), fill=(202, 110, 232, 175))
        polygon(ds, [(24, 10), (40, 10), (44, 33), (39, 54), (32, 61), (25, 54), (20, 33)], fill=dark)
        polygon(dm, [(27, 13), (37, 13), (40, 32), (36, 52), (32, 57), (28, 52), (24, 32)], fill=deep)
        ellipse(dm, (26, 13, 38, 27), fill=secondary)
        polygon(dm, [(28, 29), (36, 29), (37, 36), (27, 36)], fill=accent)
        return

    if enemy.motif == "mayfly":
        for box in ((3, 7, 30, 32), (34, 7, 61, 32), (8, 27, 30, 50), (34, 27, 56, 50)):
            ellipse(ds, box, fill=dark)
        ellipse(dm, (6, 10, 29, 30), fill=(83, 202, 235, 170))
        ellipse(dm, (35, 10, 58, 30), fill=(236, 110, 131, 170))
        ellipse(dm, (11, 30, 29, 47), fill=(145, 109, 219, 160))
        ellipse(dm, (35, 30, 53, 47), fill=(229, 101, 176, 160))
        polygon(ds, [(25, 9), (39, 9), (41, 28), (36, 56), (32, 62), (28, 56), (23, 28)], fill=dark)
        polygon(dm, [(28, 12), (36, 12), (37, 28), (34, 54), (32, 58), (30, 54), (27, 28)], fill=deep)
        polygon(dm, [(29, 17), (35, 17), (35, 30), (29, 30)], fill=secondary)
        return

    if enemy.role == "chaser":
        polygon(ds, [(32, 5), (42, 17), (59, 22), (49, 36), (42, 35), (39, 53), (32, 61), (25, 53), (22, 35), (15, 36), (5, 22), (22, 17)], fill=dark)
        polygon(dm, [(32, 9), (39, 20), (53, 23), (46, 31), (38, 29), (36, 49), (32, 56), (28, 49), (26, 29), (18, 31), (11, 23), (25, 20)], fill=deep)
        polygon(dm, [(32, 11), (37, 24), (32, 47), (27, 24)], fill=secondary)
        polygon(dm, [(32, 12), (35, 24), (32, 32), (29, 24)], fill=light)
    elif enemy.role == "anchor":
        polygon(ds, [(32, 4), (41, 13), (56, 14), (61, 30), (51, 45), (40, 43), (36, 59), (28, 59), (24, 43), (13, 45), (3, 30), (8, 14), (23, 13)], fill=dark)
        polygon(dm, [(32, 9), (40, 17), (52, 18), (56, 29), (48, 40), (38, 37), (34, 54), (30, 54), (26, 37), (16, 40), (8, 29), (12, 18), (24, 17)], fill=deep)
        polygon(dm, [(32, 10), (39, 27), (32, 51), (25, 27)], fill=secondary)
        polygon(dm, [(32, 11), (36, 26), (32, 35), (28, 26)], fill=light)
    elif enemy.role == "dancer":
        for quad in (((32, 30), (8, 8), (25, 35)), ((32, 30), (56, 8), (39, 35)), ((32, 34), (8, 55), (26, 40)), ((32, 34), (56, 55), (38, 40))):
            center, tip, inner = quad
            polygon(ds, [center, tip, inner], fill=dark)
        polygon(ds, [(32, 5), (42, 21), (40, 46), (32, 60), (24, 46), (22, 21)], fill=dark)
        polygon(dm, [(32, 9), (38, 23), (36, 44), (32, 55), (28, 44), (26, 23)], fill=secondary)
        polygon(dm, [(29, 30), (11, 13), (24, 36)], fill=deep)
        polygon(dm, [(35, 30), (53, 13), (40, 36)], fill=deep)
        polygon(dm, [(29, 36), (12, 51), (25, 39)], fill=accent)
        polygon(dm, [(35, 36), (52, 51), (39, 39)], fill=accent)
    else:
        polygon(ds, [(32, 3), (40, 20), (55, 29), (41, 37), (36, 59), (32, 63), (28, 59), (23, 37), (9, 29), (24, 20)], fill=dark)
        polygon(dm, [(32, 7), (37, 23), (49, 29), (37, 34), (34, 55), (32, 59), (30, 55), (27, 34), (15, 29), (27, 23)], fill=deep)
        polygon(dm, [(32, 8), (35, 27), (32, 54), (29, 27)], fill=secondary)
        polygon(dm, [(32, 9), (33, 27), (32, 37), (31, 27)], fill=light)


def add_dither_texture(enemy: Enemy, layers: dict[str, Image.Image]) -> None:
    """Add restrained, hand-editable ordered dithering inside material shapes."""
    material = layers["materials"]
    texture = layers["dither_texture"]
    source = material.load()
    target = texture.load()
    bayer = (
        (0, 8, 2, 10),
        (12, 4, 14, 6),
        (3, 11, 1, 9),
        (15, 7, 13, 5),
    )
    shadow = mix((10, 5, 25), enemy.accent, 0.34, 150)
    jewel = mix(enemy.accent, enemy.core, 0.42, 145)
    glint = mix(enemy.core, (255, 248, 236), 0.42, 150)

    for y in range(7, SIZE - 5):
        for x in range(5, SIZE - 5):
            if source[x, y][3] < 96:
                continue
            rank = bayer[y % 4][x % 4]
            # Denser shadow stipple below the center; sparse jewel glints above.
            if y > 34 and rank < 4:
                target[x, y] = shadow
            elif y <= 34 and rank in (1, 9):
                target[x, y] = jewel
            elif y < 25 and rank == 5:
                target[x, y] = glint


def draw_motif(enemy: Enemy, layers: dict[str, Image.Image]) -> None:
    ornament = ImageDraw.Draw(layers["ornament"])
    highlight = ImageDraw.Draw(layers["highlights"])
    gold = rgba((245, 196, 88))
    pale = rgba((246, 238, 255))
    core = rgba(enemy.core)
    motif = enemy.motif

    ellipse(ornament, (25, 25, 39, 39), fill=(28, 14, 42, 230), outline=gold, width=sc(1.2))
    ellipse(ornament, (28, 28, 36, 36), fill=core)

    if motif == "spark":
        for angle in range(0, 360, 45):
            a = math.radians(angle)
            line(ornament, [(32 + math.cos(a) * 8, 32 + math.sin(a) * 8), (32 + math.cos(a) * 19, 32 + math.sin(a) * 19)], gold, 1.6)
    elif motif == "anvil":
        polygon(ornament, [(20, 25), (44, 25), (39, 31), (36, 34), (36, 42), (42, 45), (22, 45), (28, 42), (28, 34), (25, 31)], fill=gold)
    elif motif == "bellows":
        polygon(ornament, [(19, 24), (36, 20), (36, 44), (19, 40), (25, 32)], outline=gold, fill=(69, 25, 43, 220))
        line(ornament, [(36, 32), (48, 32)], gold, 3)
    elif motif == "hammer":
        polygon(ornament, [(19, 20), (43, 20), (48, 25), (43, 30), (19, 30)], fill=gold)
        line(ornament, [(31, 29), (37, 49)], pale, 4)
    elif motif == "hare":
        ellipse(ornament, (23, 27, 41, 45), fill=(60, 29, 74, 230), outline=gold, width=sc(1))
        ellipse(ornament, (23, 15, 30, 31), outline=gold, width=sc(2))
        ellipse(ornament, (34, 15, 41, 31), outline=gold, width=sc(2))
    elif motif == "staff":
        line(ornament, [(32, 15), (32, 49)], pale, 3)
        ellipse(ornament, (27, 16, 37, 26), outline=gold, width=sc(2))
        polygon(ornament, [(29, 27), (14, 20), (22, 34)], fill=gold)
        polygon(ornament, [(35, 27), (50, 20), (42, 34)], fill=gold)
    elif motif == "knot":
        ellipse(ornament, (17, 23, 34, 40), outline=gold, width=sc(2))
        ellipse(ornament, (30, 23, 47, 40), outline=pale, width=sc(2))
        line(ornament, [(24, 39), (40, 25)], core, 2)
    elif motif == "pinwheel":
        for angle in range(0, 360, 90):
            a = math.radians(angle)
            b = math.radians(angle + 50)
            polygon(ornament, [(32, 32), (32 + math.cos(a) * 18, 32 + math.sin(a) * 18), (32 + math.cos(b) * 9, 32 + math.sin(b) * 9)], fill=gold)
    elif motif == "spade":
        ellipse(ornament, (19, 23, 33, 36), fill=gold)
        ellipse(ornament, (31, 23, 45, 36), fill=gold)
        polygon(ornament, [(32, 15), (19, 31), (45, 31)], fill=gold)
        polygon(ornament, [(32, 31), (25, 48), (39, 48)], fill=gold)
    elif motif == "mask":
        ellipse(ornament, (18, 18, 46, 44), fill=(239, 218, 177, 240), outline=gold, width=sc(1))
        ellipse(ornament, (23, 26, 30, 32), fill=(28, 12, 38, 255))
        ellipse(ornament, (34, 26, 41, 32), fill=(28, 12, 38, 255))
        line(ornament, [(26, 38), (38, 38)], (112, 37, 78, 255), 1.5)
    elif motif == "talisman":
        polygon(ornament, [(23, 15), (41, 15), (41, 49), (32, 44), (23, 49)], fill=(226, 215, 181, 240), outline=gold)
        line(ornament, [(32, 20), (32, 42)], core, 2)
        line(ornament, [(27, 27), (37, 27)], core, 2)
    elif motif == "shard":
        polygon(ornament, [(32, 12), (20, 39), (31, 35), (28, 51), (45, 26), (35, 29)], fill=core, outline=pale)
    elif motif == "planet":
        ellipse(ornament, (22, 22, 42, 42), fill=core, outline=gold, width=sc(1))
        ellipse(ornament, (14, 27, 50, 37), outline=pale, width=sc(2))
        ellipse(ornament, (34, 24, 38, 28), fill=gold)
    elif motif == "astrolabe":
        ellipse(ornament, (16, 16, 48, 48), outline=gold, width=sc(2))
        ellipse(ornament, (25, 15, 39, 49), outline=pale, width=sc(1.5))
        ellipse(ornament, (15, 25, 49, 39), outline=core, width=sc(1.5))
    elif motif == "constellation":
        stars = [(20, 39), (26, 23), (34, 31), (41, 18), (46, 41)]
        line(ornament, stars, pale, 1.2)
        for x, y in stars:
            ellipse(ornament, (x - 2, y - 2, x + 2, y + 2), fill=gold)
    elif motif == "heart":
        ellipse(ornament, (19, 20, 34, 34), fill=core)
        ellipse(ornament, (30, 20, 45, 34), fill=core)
        polygon(ornament, [(19, 28), (45, 28), (32, 49)], fill=core)
        line(ornament, [(32, 20), (32, 46)], gold, 1.5)
    elif motif in {"bee", "mayfly"}:
        for y in (28, 36, 44):
            line(ornament, [(27, y), (37, y)], gold, 2)
        line(ornament, [(27, 17), (20, 9)], gold, 1.5)
        line(ornament, [(37, 17), (44, 9)], gold, 1.5)
    elif motif == "reliquary":
        ellipse(ornament, (18, 14, 46, 49), outline=gold, width=sc(2))
        for angle in range(0, 360, 60):
            a = math.radians(angle)
            line(ornament, [(32 + math.cos(a) * 15, 32 + math.sin(a) * 15), (32 + math.cos(a) * 23, 32 + math.sin(a) * 23)], core, 2)
    elif motif == "chakram":
        ellipse(ornament, (14, 14, 50, 50), outline=core, width=sc(4))
        ellipse(ornament, (21, 21, 43, 43), outline=gold, width=sc(1.5))
        for angle in range(0, 360, 90):
            a = math.radians(angle)
            b = math.radians(angle + 18)
            c = math.radians(angle - 18)
            polygon(ornament, [(32 + math.cos(c) * 19, 32 + math.sin(c) * 19), (32 + math.cos(a) * 27, 32 + math.sin(a) * 27), (32 + math.cos(b) * 19, 32 + math.sin(b) * 19)], fill=pale)

    # Neo-Gothic edge seams and a few crisp specular points remain editable.
    line(ornament, [(32, 8), (32, 20)], gold, 1)
    line(ornament, [(20, 42), (27, 49)], gold, 1)
    line(ornament, [(44, 42), (37, 49)], gold, 1)
    ellipse(highlight, (29, 27, 32, 30), fill=(255, 255, 255, 225))
    line(highlight, [(17, 23), (23, 20)], (255, 245, 226, 180), 1)
    line(highlight, [(47, 23), (41, 20)], (255, 245, 226, 180), 1)


def render(enemy: Enemy) -> dict[str, Image.Image]:
    layers = {name: layer() for name in ("core_glow", "silhouette", "materials", "dither_texture", "ornament", "highlights")}
    role_hull(enemy, layers)
    add_dither_texture(enemy, layers)
    draw_motif(enemy, layers)
    glow = ImageDraw.Draw(layers["core_glow"])
    ellipse(glow, (21, 21, 43, 43), fill=rgba(enemy.core, 64))
    # Pixel-art glow is a deliberate two-band halo rather than a soft blur.
    ellipse(glow, (24, 24, 40, 40), fill=rgba(enemy.core, 160))
    return layers


def composite(layers: dict[str, Image.Image]) -> Image.Image:
    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    for name in ("core_glow", "silhouette", "materials", "dither_texture", "ornament", "highlights"):
        result = Image.alpha_composite(result, layers[name])
    return result


def write_ora(path: Path, layers: dict[str, Image.Image], merged: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    order = ("highlights", "ornament", "dither_texture", "materials", "silhouette", "core_glow")
    stack = [f'<layer name="{escape(name.replace("_", " ").title())}" src="data/{index:02d}_{name}.png" visibility="visible"/>' for index, name in enumerate(order)]
    xml = f'<?xml version="1.0" encoding="UTF-8"?><image version="0.0.1" w="{SIZE}" h="{SIZE}" name="{escape(path.stem)}"><stack>{"".join(stack)}</stack></image>'
    from io import BytesIO
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        archive.writestr("stack.xml", xml)
        for index, name in enumerate(order):
            buffer = BytesIO()
            layers[name].save(buffer, format="PNG")
            archive.writestr(f"data/{index:02d}_{name}.png", buffer.getvalue())
        merged_buffer = BytesIO()
        merged.save(merged_buffer, format="PNG")
        archive.writestr("mergedimage.png", merged_buffer.getvalue())
        archive.writestr("Thumbnails/thumbnail.png", merged_buffer.getvalue())


def main() -> None:
    manifest = []
    for enemy in ENEMIES:
        layers = render(enemy)
        merged = composite(layers)
        stage_dir = SOURCE / f"stage_{enemy.stage:02d}"
        layer_dir = stage_dir / "layer_exports" / enemy.slug
        layer_dir.mkdir(parents=True, exist_ok=True)
        for name, image in layers.items():
            image.save(layer_dir / f"{name}.png")
        merged.save(stage_dir / f"{enemy.slug}_runtime_preview.png")
        ora = stage_dir / f"{enemy.slug}.ora"
        write_ora(ora, layers, merged)
        install_sprite(enemy.sprite, merged)
        manifest.append({
            "stage": enemy.stage,
            "slug": enemy.slug,
            "sprite": enemy.sprite,
            "openraster_source": str(ora.relative_to(ROOT)),
            "krita_source": str(ora.with_suffix(".kra").relative_to(ROOT)),
            "layers": ["Core Glow", "Silhouette", "Materials", "Dither Texture", "Ornament", "Highlights"],
        })
    (SOURCE / "enemy_source_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(ENEMIES)} layered enemies, ORA interchange sources, and runtime sprites.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build editable Krita/OpenRaster glyph sheets for the runtime pixel serifs."""

from __future__ import annotations

import io
import re
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "art" / "font_sources" / "not_jam_old_style"
WIDTH = 512
HEIGHT = 320
CHARACTERS = "".join(chr(code) for code in range(32, 127))
GAME_ROOT = ROOT / "Selkie's Moon ~ until we meet again ~"


def threshold_alpha(image: Image.Image) -> Image.Image:
    red, green, blue, alpha = image.split()
    alpha = alpha.point(lambda value: 255 if value >= 128 else 0)
    return Image.merge("RGBA", (red, green, blue, alpha))


def glyph_layer(font_path: Path, size: int, top: int, label: str) -> Image.Image:
    layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font = ImageFont.truetype(str(font_path), size)
    draw.text((8, top), label, font=font, fill=(255, 220, 132, 255))

    grid_top = top + size + 8
    cell_width = 30
    cell_height = size + 7
    for index, character in enumerate(CHARACTERS):
        column = index % 16
        row = index // 16
        draw.text(
            (8 + (column * cell_width), grid_top + (row * cell_height)),
            character,
            font=font,
            fill=(255, 255, 255, 255),
        )

    return threshold_alpha(layer)


def png_bytes(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


def runtime_glyph(font: ImageFont.FreeTypeFont, code: int, line_height: int) -> tuple[Image.Image, int, int]:
    if code == 9647:
        width = max(7, line_height // 2)
        shift = width + 1
        glyph = Image.new("RGBA", (width, line_height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(glyph)
        draw.rectangle((1, 1, width - 2, line_height - 2), outline=(255, 255, 255, 255))
        return glyph, shift, 0

    character = chr(code)
    shift = max(0, round(font.getlength(character)))
    if code == 127:
        return Image.new("RGBA", (0, line_height), (0, 0, 0, 0)), shift, 0

    left, _top, right, _bottom = font.getbbox(character)
    width = max(1, right - left, shift)
    glyph = Image.new("RGBA", (width, line_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glyph)
    draw.text((-left, 0), character, font=font, fill=(255, 255, 255, 255))
    return threshold_alpha(glyph), shift, left


def build_runtime_font(font_path: Path, size: int, resource_dir: Path, atlas_height: int) -> None:
    font = ImageFont.truetype(str(font_path), size)
    ascender, _descender = font.getmetrics()
    atlas = Image.new("RGBA", (256, atlas_height), (0, 0, 0, 0))
    glyph_entries: list[str] = []
    cursor_x = 2
    cursor_y = 2
    row_height = size + 2

    for code in [*range(32, 128), 9647]:
        glyph, shift, offset = runtime_glyph(font, code, size)
        width = glyph.width

        if width > 0 and cursor_x + width + 2 > atlas.width:
            cursor_x = 2
            cursor_y += row_height

        if cursor_y + size + 2 > atlas.height:
            raise RuntimeError(f"{resource_dir.name} glyphs exceed the authored atlas")

        x = cursor_x
        y = cursor_y
        if width > 0:
            atlas.alpha_composite(glyph, (x, y))
            cursor_x += width + 2

        glyph_entries.append(
            f'    "{code}":{{"character":{code},"h":{size},"offset":{offset},'
            f'"shift":{shift},"w":{width},"x":{x},"y":{y},}},'
        )

    atlas.save(resource_dir / f"{resource_dir.name}.png")
    yy_path = resource_dir / f"{resource_dir.name}.yy"
    resource = yy_path.read_text(encoding="utf-8")
    glyph_block = '  "glyphs":{\n' + "\n".join(glyph_entries) + '\n  },\n  "hinting"'
    resource, replacements = re.subn(
        r'  "glyphs":\{\n.*?\n  \},\n  "hinting"',
        glyph_block,
        resource,
        count=1,
        flags=re.DOTALL,
    )
    if replacements != 1:
        raise RuntimeError(f"Could not replace glyph table in {yy_path}")
    resource = re.sub(r'  "ascender":-?\d+,', f'  "ascender":{ascender},', resource, count=1)
    resource = re.sub(r'  "ascenderOffset":-?\d+,', '  "ascenderOffset":0,', resource, count=1)
    yy_path.write_text(resource, encoding="utf-8")


def build() -> None:
    font_14 = SOURCE_DIR / "NotJamOldStyle14.ttf"
    font_11 = SOURCE_DIR / "NotJamOldStyle11.ttf"
    layer_14 = glyph_layer(font_14, 14, 8, "NOT JAM OLD STYLE 14")
    layer_11 = glyph_layer(font_11, 11, 174, "NOT JAM OLD STYLE 11")
    merged = Image.alpha_composite(layer_14, layer_11)

    merged.save(SOURCE_DIR / "NotJamOldStyleGlyphs.png")
    thumbnail = merged.copy()
    thumbnail.thumbnail((256, 256), Image.Resampling.NEAREST)

    stack_xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<image version="0.0.1" w="{WIDTH}" h="{HEIGHT}" '
        'name="Not Jam Old Style Runtime Glyphs">\n'
        '  <stack name="Runtime Pixel Serifs">\n'
        '    <layer name="Old Style 11 Body Serif" '
        'src="data/old_style_11.png" visibility="visible"/>\n'
        '    <layer name="Old Style 14 Menu Serif" '
        'src="data/old_style_14.png" visibility="visible"/>\n'
        '  </stack>\n'
        '</image>\n'
    )

    ora_path = SOURCE_DIR / "NotJamOldStyleGlyphs.ora"
    with zipfile.ZipFile(ora_path, "w") as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        archive.writestr("stack.xml", stack_xml, compress_type=zipfile.ZIP_DEFLATED)
        archive.writestr("mergedimage.png", png_bytes(merged), compress_type=zipfile.ZIP_DEFLATED)
        archive.writestr(
            "Thumbnails/thumbnail.png",
            png_bytes(thumbnail),
            compress_type=zipfile.ZIP_DEFLATED,
        )
        archive.writestr(
            "data/old_style_14.png",
            png_bytes(layer_14),
            compress_type=zipfile.ZIP_DEFLATED,
        )
        archive.writestr(
            "data/old_style_11.png",
            png_bytes(layer_11),
            compress_type=zipfile.ZIP_DEFLATED,
        )

    build_runtime_font(
        font_14,
        14,
        GAME_ROOT / "fonts" / "fn_menu",
        128,
    )
    build_runtime_font(
        font_11,
        11,
        GAME_ROOT / "fonts" / "fn_dialogue_speech",
        128,
    )


if __name__ == "__main__":
    build()

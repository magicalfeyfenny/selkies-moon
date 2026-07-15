#!/usr/bin/env python3
"""Build a numbered contact sheet from full-body portrait candidates."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("character", help="Character name used in the sheet title")
    parser.add_argument("output", type=Path, help="Output PNG path")
    parser.add_argument("images", nargs="+", type=Path, help="Candidate images in display order")
    return parser.parse_args()


def contain(image: Image.Image, width: int, height: int) -> Image.Image:
    result = image.convert("RGB")
    result.thumbnail((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (width, height), (28, 26, 38))
    x = (width - result.width) // 2
    y = (height - result.height) // 2
    canvas.paste(result, (x, y))
    return canvas


def main() -> None:
    args = parse_args()
    if len(args.images) != 10:
        raise SystemExit(f"expected exactly 10 candidates, received {len(args.images)}")

    columns = 5
    rows = 2
    tile_width = 320
    tile_height = 448
    label_height = 44
    title_height = 70
    gutter = 16
    sheet_width = (columns * tile_width) + ((columns + 1) * gutter)
    sheet_height = title_height + (rows * (tile_height + label_height)) + ((rows + 1) * gutter)
    sheet = Image.new("RGB", (sheet_width, sheet_height), (16, 14, 26))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=24)
    title_font = ImageFont.load_default(size=34)
    draw.text((gutter, 18), f"{args.character} portrait candidates", fill=(242, 236, 255), font=title_font)

    for index, path in enumerate(args.images):
        row = index // columns
        column = index % columns
        x = gutter + (column * (tile_width + gutter))
        y = title_height + gutter + (row * (tile_height + label_height + gutter))
        tile = contain(Image.open(path), tile_width, tile_height)
        sheet.paste(tile, (x, y))
        label = f"{index + 1:02d}"
        bounds = draw.textbbox((0, 0), label, font=font)
        label_width = bounds[2] - bounds[0]
        draw.text(
            (x + ((tile_width - label_width) // 2), y + tile_height + 8),
            label,
            fill=(255, 226, 126),
            font=font,
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.output)


if __name__ == "__main__":
    main()

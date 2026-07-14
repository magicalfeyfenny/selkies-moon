#!/usr/bin/env python3
"""Align full-body portrait masters and derive GameMaker dialogue sprites.

Each ``*_full.png`` master is normalized onto the same transparent canvas and
baseline before a square, upper-body dialogue crop is written to both the
GameMaker frame image and its editable layer image.  The operation is
idempotent: an already aligned master can be processed again without drift.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


MASTER_SIZE = (1536, 2048)
MASTER_SIDE_PADDING = 64
MASTER_TOP_PADDING = 64
MASTER_BOTTOM_MARGIN = 96
DIALOGUE_SIZE = (360, 360)
DIALOGUE_VISIBLE_HEIGHT_RATIO = 0.72
DIALOGUE_HEADROOM_RATIO = 0.02


@dataclass(frozen=True)
class PortraitSpec:
    """Connect one named master to its GameMaker sprite directory."""

    name: str
    sprite_name: str


PORTRAITS = (
    PortraitSpec("aisha", "spr_aisha_portrait"),
    PortraitSpec("aster", "spr_aster_portrait"),
    PortraitSpec("caelia", "spr_caelia_portrait"),
    PortraitSpec("mira", "spr_mira_portrait"),
    PortraitSpec("moon", "spr_moon_portrait"),
    PortraitSpec("selkie", "spr_selkie_portrait"),
    PortraitSpec("shalmii", "spr_shalmii_portrait"),
)


def opaque_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    """Return the non-transparent bounds or fail for an empty master."""

    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("portrait contains no opaque pixels")
    return bounds


def align_master(image: Image.Image) -> Image.Image:
    """Center a cutout and place its lowest pixel on the shared baseline."""

    subject = image.crop(opaque_bounds(image))
    max_width = MASTER_SIZE[0] - (MASTER_SIDE_PADDING * 2)
    max_height = MASTER_SIZE[1] - MASTER_TOP_PADDING - MASTER_BOTTOM_MARGIN
    scale = min(1.0, max_width / subject.width, max_height / subject.height)

    if scale < 1.0:
        scaled_size = (
            max(1, round(subject.width * scale)),
            max(1, round(subject.height * scale)),
        )
        subject = subject.resize(scaled_size, Image.Resampling.LANCZOS)

    x = (MASTER_SIZE[0] - subject.width) // 2
    y = MASTER_SIZE[1] - MASTER_BOTTOM_MARGIN - subject.height
    canvas = Image.new("RGBA", MASTER_SIZE, (0, 0, 0, 0))
    canvas.alpha_composite(subject, (x, y))
    return canvas


def dialogue_crop(master: Image.Image) -> Image.Image:
    """Create a readable upper-body crop for the fixed 360px story slot."""

    left, top, right, bottom = opaque_bounds(master)
    subject_height = bottom - top
    crop_side = round(subject_height * DIALOGUE_VISIBLE_HEIGHT_RATIO)
    center_x = (left + right) / 2
    crop_left = round(center_x - (crop_side / 2))
    crop_top = round(top - (subject_height * DIALOGUE_HEADROOM_RATIO))
    crop = master.crop(
        (
            crop_left,
            crop_top,
            crop_left + crop_side,
            crop_top + crop_side,
        )
    )
    return crop.resize(DIALOGUE_SIZE, Image.Resampling.LANCZOS)


def sole_png(path: Path, *, recursive: bool) -> Path:
    """Find the single frame/layer PNG expected by a one-frame sprite."""

    candidates = sorted(path.rglob("*.png") if recursive else path.glob("*.png"))
    if len(candidates) != 1:
        raise ValueError(f"expected one PNG in {path}, found {len(candidates)}")
    return candidates[0]


def process_portrait(project_root: Path, spec: PortraitSpec) -> None:
    """Normalize one master and replace both GameMaker image copies."""

    master_path = project_root / "art" / "character_portraits" / f"{spec.name}_full.png"
    sprite_dir = project_root / "sprites" / spec.sprite_name
    frame_path = sole_png(sprite_dir, recursive=False)
    layer_path = sole_png(sprite_dir / "layers", recursive=True)

    with Image.open(master_path) as source:
        master = align_master(source.convert("RGBA"))
    master.save(master_path, optimize=True)

    runtime = dialogue_crop(master)
    runtime.save(frame_path, optimize=True)
    runtime.save(layer_path, optimize=True)

    bounds = opaque_bounds(master)
    baseline = bounds[3]
    print(
        f"{spec.name}: master={master.size} bounds={bounds} "
        f"baseline={baseline} runtime={runtime.size}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Selkie's Moon ~ until we meet again ~",
        help="GameMaker project directory containing art/ and sprites/",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    for portrait in PORTRAITS:
        process_portrait(args.project_root.resolve(), portrait)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""One-time, non-destructive migration of legacy PNGs into native Krita masters."""

from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
import zipfile
from io import BytesIO
from pathlib import Path

from PIL import Image

from krita_export import (
    find_krita,
    isolated_krita_environment,
    visible_pixels_equivalent,
)


def validate_native_kra(path: Path) -> tuple[int, int]:
    """Validate the basic native archive contract and return canvas dimensions."""

    if not path.is_file():
        raise FileNotFoundError(path)
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError(f"Corrupt Krita archive: {path}")
        if archive.read("mimetype").strip() != b"application/x-krita":
            raise ValueError(f"Not a native Krita archive: {path}")
        if "maindoc.xml" not in archive.namelist() or "mergedimage.png" not in archive.namelist():
            raise ValueError(f"Incomplete Krita archive: {path}")
        with Image.open(BytesIO(archive.read("mergedimage.png"))) as image:
            return image.size


def migrate_png(source: Path, destination: Path) -> str:
    """Create one KRA from a legacy PNG, refusing to replace an existing master."""

    source = source.resolve()
    destination = destination.resolve()
    if not source.is_file():
        raise FileNotFoundError(source)
    if destination.exists():
        validate_native_kra(destination)
        return "existing"

    destination.parent.mkdir(parents=True, exist_ok=True)
    environment, resources = isolated_krita_environment()
    with tempfile.TemporaryDirectory(prefix=f".{destination.stem}-", dir=destination.parent) as staging:
        staged = Path(staging) / destination.name
        result = subprocess.run(
            [
                str(find_krita()),
                "--nosplash",
                "--resource-location",
                str(resources),
                "--export",
                "--export-filename",
                str(staged),
                str(source),
            ],
            check=False,
            capture_output=True,
            text=True,
            env=environment,
            timeout=180,
        )
        if result.returncode != 0:
            details = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
            raise RuntimeError(
                f"Krita failed to migrate {source} (exit {result.returncode})"
                + (f":\n{details}" if details else "")
            )
        validate_native_kra(staged)
        with Image.open(source) as source_image, zipfile.ZipFile(staged) as archive:
            source_rgba = source_image.convert("RGBA")
            with Image.open(BytesIO(archive.read("mergedimage.png"))) as merged:
                migrated = merged.convert("RGBA")
                if source_rgba.size != migrated.size or not visible_pixels_equivalent(
                    source_rgba.tobytes(), migrated.tobytes()
                ):
                    raise ValueError(f"Krita migration changed visible pixels for {source}")
        os.replace(staged, destination)
    return "created"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="legacy PNG to migrate")
    parser.add_argument("--destination", type=Path, required=True, help="new .kra master path")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(migrate_png(args.source, args.destination))


if __name__ == "__main__":
    main()

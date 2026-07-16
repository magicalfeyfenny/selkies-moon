#!/usr/bin/env python3
"""Retired compatibility entry point; stage textures use KRA masters."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export 3D-stage runtime texture PNGs from their KRA masters."""

    export_assets({"stage3d"})


if __name__ == "__main__":
    main()

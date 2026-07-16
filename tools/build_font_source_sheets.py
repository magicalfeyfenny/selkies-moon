#!/usr/bin/env python3
"""Retired font-art generator; standalone KRA masters own raster glyph art."""

from export_krita_runtime import export_assets


def build() -> None:
    """Export standalone runtime art from KRA masters."""

    export_assets({"standalone"})


def main() -> None:
    """Preserve the historical command-line entry point."""

    build()


if __name__ == "__main__":
    main()

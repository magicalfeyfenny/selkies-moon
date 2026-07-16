#!/usr/bin/env python3
"""Retired compatibility entry point; story art is authored in KRA masters."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export story-background runtime PNGs from their KRA masters."""

    export_assets({"story"})


if __name__ == "__main__":
    main()

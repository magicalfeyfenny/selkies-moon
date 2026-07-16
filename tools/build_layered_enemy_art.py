#!/usr/bin/env python3
"""Retired compatibility entry point; enemy art is authored in KRA masters."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export enemy runtime PNGs from their KRA masters."""

    export_assets({"enemy"})


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Retired compatibility entry point; core art is authored in KRA masters."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export core runtime PNGs from their KRA masters."""

    export_assets({"core"})


if __name__ == "__main__":
    main()

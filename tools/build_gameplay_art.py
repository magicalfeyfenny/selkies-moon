#!/usr/bin/env python3
"""Retired compatibility entry point; KRA masters now export gameplay art."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export enemy and imported gameplay assets from their KRA masters."""

    export_assets({"enemy", "imported"})


if __name__ == "__main__":
    main()

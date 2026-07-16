#!/usr/bin/env python3
"""Retired reverse importer; migrated KRA masters now export runtime art."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export migrated runtime-sprite PNGs from their KRA masters."""

    export_assets({"imported"})


if __name__ == "__main__":
    main()

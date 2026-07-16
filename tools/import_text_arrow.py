#!/usr/bin/env python3
"""Retired reverse importer; the text-arrow KRA is now the master."""

from export_krita_runtime import export_assets


def main() -> None:
    """Export text-arrow runtime frames from the KRA master."""

    export_assets({"text"})


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Export migrated dialogue portraits without rewriting accepted source art.

Accepted full-resolution portrait KRAs are source-only.  This compatibility
entry point updates the imported GameMaker runtime assets and never exports or
normalizes the accepted full portraits.
"""

from export_krita_runtime import export_assets


def main() -> None:
    """Export migrated runtime art, including the dialogue portrait sprites."""

    export_assets({"imported"})


if __name__ == "__main__":
    main()

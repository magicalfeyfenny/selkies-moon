#!/usr/bin/env python3
"""Read-only Krita CLI support shared by migration and validation tools.

Normal asset builds use ``export_krita_runtime.py`` and may never write a KRA.
The separately named legacy migration tool imports these helpers but enforces
non-destructive, create-only promotion itself.
"""

from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_KRITA = Path("/Applications/Krita.app/Contents/MacOS/krita")
_cli_session: tempfile.TemporaryDirectory[str] | None = None


def find_krita() -> Path:
    """Resolve Krita from KRITA_BIN, PATH, or the normal macOS app location."""

    configured = os.environ.get("KRITA_BIN")
    candidates: list[Path] = []
    if configured:
        configured_path = Path(configured).expanduser()
        resolved = shutil.which(configured) if configured_path.parent == Path(".") else None
        candidates.append(Path(resolved) if resolved else configured_path)
    on_path = shutil.which("krita")
    if on_path:
        candidates.append(Path(on_path))
    candidates.append(DEFAULT_KRITA)

    for candidate in candidates:
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return candidate.resolve()
    attempted = ", ".join(str(path) for path in candidates)
    raise FileNotFoundError(
        "Krita is required. Install Krita or set KRITA_BIN to its executable. "
        f"Tried: {attempted}"
    )


def isolated_krita_environment() -> tuple[dict[str, str], Path]:
    """Return one isolated Krita resource environment reused by this process."""

    global _cli_session
    if _cli_session is None:
        parent = ROOT / "tmp"
        parent.mkdir(parents=True, exist_ok=True)
        _cli_session = tempfile.TemporaryDirectory(prefix="krita-cli-", dir=parent)
    session = Path(_cli_session.name)
    config = session / "config"
    data = session / "data"
    cache = session / "cache"
    resources = session / "resources"
    for directory in (config, data, cache, resources):
        directory.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment.update({
        "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data),
        "XDG_CACHE_HOME": str(cache),
    })
    return environment, resources


def visible_pixels_equivalent(left: bytes, right: bytes, *, rgb_tolerance: int = 1) -> bool:
    """Compare RGBA pixels, ignoring hidden RGB and bounded profile roundoff."""

    if left == right:
        return True
    if len(left) != len(right) or len(left) % 4 != 0:
        return False
    for offset in range(0, len(left), 4):
        left_alpha = left[offset + 3]
        right_alpha = right[offset + 3]
        if left_alpha != right_alpha:
            return False
        if left_alpha == 0:
            continue
        if any(
            abs(left[offset + channel] - right[offset + channel]) > rgb_tolerance
            for channel in range(3)
        ):
            return False
    return True

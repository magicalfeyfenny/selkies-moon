#!/usr/bin/env python3
"""Retired procedural audio generator.

Production score and sound effects are authored through the tracked MIDI and
Logic projects.  This historical entry point deliberately refuses to generate
placeholder WAVs because doing so would overwrite Logic-derived runtime audio.
"""


def main() -> None:
    """Stop with directions to the authoritative audio workflows."""

    raise SystemExit(
        "tools/build_audio_assets.py is retired: use build_logic_score_midi.py / "
        "validate_logic_score.py for score sources and build_logic_sfx_suite.py / "
        "install_logic_sfx.py for production SFX."
    )


if __name__ == "__main__":
    main()

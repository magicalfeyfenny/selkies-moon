#!/usr/bin/env python3

from __future__ import annotations

import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))

import check_repository_hygiene as hygiene  # noqa: E402


class RepositoryHygieneUnitTests(unittest.TestCase):
    def test_game_maker_trailing_commas_do_not_change_strings(self) -> None:
        source = '{"value":"literal,}","items":[1,2,],}'
        self.assertEqual(
            hygiene._without_trailing_commas(source),
            '{"value":"literal,}","items":[1,2]}',
        )

    def test_canonical_lfs_pointer_is_accepted(self) -> None:
        pointer = (
            b"version https://git-lfs.github.com/spec/v1\n"
            b"oid sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\n"
            b"size 42\n"
        )
        self.assertTrue(hygiene._is_lfs_pointer(pointer))
        self.assertFalse(hygiene._is_lfs_pointer(pointer.rstrip()))
        self.assertFalse(hygiene._is_lfs_pointer(pointer.replace(b"size 42", b"size 042")))
        self.assertFalse(
            hygiene._is_lfs_pointer(
                pointer.replace(
                    b"oid sha256:",
                    b"ext-garbage value\noid sha256:",
                )
            )
        )

    def test_junk_and_retired_paths_are_rejected(self) -> None:
        self.assertIsNotNone(hygiene._junk_reason("sprites/.DS_Store"))
        self.assertIsNotNone(hygiene._junk_reason("fonts/font.old.png"))
        self.assertIsNotNone(hygiene._junk_reason("output/build/result.zip"))
        self.assertIsNotNone(
            hygiene._junk_reason(
                "Selkie's Moon ~ until we meet again ~/timelines/tml_stage/tml_stage.yy"
            )
        )
        self.assertIsNone(hygiene._junk_reason("art/audio_production/sfx_raw_bounces/suite.wav"))

    def test_lfs_include_path_escapes_gitignore_metacharacters(self) -> None:
        self.assertEqual(
            hygiene._escape_lfs_fetch_pattern(r"art/[draft]/take*?.wav"),
            r"art/\[draft\]/take\*\?.wav",
        )


if __name__ == "__main__":
    unittest.main()

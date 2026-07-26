#!/usr/bin/env python3

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parents[1]
CHECKER = TOOLS / "check_governance.py"


class GovernanceCheckTests(unittest.TestCase):
    def _fixture(self) -> tempfile.TemporaryDirectory[str]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        docs = root / "docs"
        tools = root / "tools"
        game = root / "Selkie's Moon ~ until we meet again ~"
        gameplay = game / "scripts" / "scr_gameplay_helpers"
        tests = game / "scripts" / "test_bootstrap"
        helpers = game / "scripts" / "scr_test_helpers"
        workflow = root / ".github" / "workflows"
        templates = root / ".github" / "ISSUE_TEMPLATE"

        for path in (docs, tools, gameplay, tests, helpers, workflow, templates):
            path.mkdir(parents=True, exist_ok=True)
        shutil.copy2(CHECKER, tools / "check_governance.py")

        (root / "AGENTS.md").write_text(
            "[Handoff](docs/GOVERNANCE_HANDOFF.md)\nissue/branch/PR lifecycle\n",
            encoding="utf-8",
        )
        (root / "README.md").write_text("# Fixture\n", encoding="utf-8")
        (docs / "GOVERNANCE_HANDOFF.md").write_text(
            "Agent Review Policy\nBranch and Release Policy\nAsset Pipeline\nissue/branch/PR lifecycle\n",
            encoding="utf-8",
        )
        (docs / "AGENT_REVIEW_POLICY.md").write_text("Exact-head validation\n", encoding="utf-8")
        (docs / "ARCHITECTURE.md").write_text("# Architecture\n", encoding="utf-8")
        (docs / "ASSET_PIPELINE.md").write_text("# Asset Pipeline\n", encoding="utf-8")
        (docs / "BRANCH_AND_RELEASE_POLICY.md").write_text(
            "This is the authoritative repository policy for the lifecycle\n",
            encoding="utf-8",
        )
        (docs / "HANDOFF_TEMPLATE.md").write_text("This is not repository policy.\n", encoding="utf-8")
        (docs / "PROJECT_STATE.md").write_text(
            "\n".join(
                (
                    "ASSET_PIPELINE.md",
                    "Consolidated stages: `5`.",
                    "material from `10` legacy wave",
                    "Rank range: `0-50`.",
                    "`50` is the established default.",
                    "Boss stage phase counts: `3,5,3+3+shared,7,15`.",
                    "GMTL tests declared: `2`.",
                    "Visual-tour captures declared: `26`.",
                )
            )
            + "\n",
            encoding="utf-8",
        )
        (docs / "VALIDATION.md").write_text("Required CI\nvisual-tour\n", encoding="utf-8")
        (root / ".github" / "pull_request_template.md").write_text(
            "\n".join(
                f"## {heading}" for heading in (
                    "Primary issue", "Scope", "Acceptance mapping", "Important files and ownership",
                    "Validation", "Review status", "Remaining risks", "Merge intention",
                    "External-action authority", "Rollback or final disposition", "Non-merge record",
                    "Lifecycle exception",
                )
            ) + "\n<!-- pr-contract:v1 -->\n",
            encoding="utf-8",
        )
        (templates / "task-contract.md").write_text(
            "\n".join(
                f"## {heading}" for heading in (
                    "Objective", "Acceptance criteria", "Non-goals", "Expected validation",
                    "Known risks and blockers", "External-action authority", "Dependencies",
                    "Relevant repository documents or milestones",
                )
            ) + "\n",
            encoding="utf-8",
        )
        (game / "Selkies Moon.yyp").write_text("{}\n", encoding="utf-8")
        (gameplay / "scr_gameplay_helpers.gml").write_text(
            "\n".join(
                (
                    "#macro STAGE_COUNT 5",
                    "#macro LEGACY_STAGE_COUNT 10",
                    "#macro RANK_MIN 0",
                    "#macro RANK_MAX 50",
                    "#macro RANK_DEFAULT 50",
                    "#macro FINAL_BOSS_EXPANDED_PHASE_COUNT 14",
                    "rank = RANK_MIN;",
                    "function GameBossExpandedPhaseCountForStage(_stage) {",
                    "    switch (_stage) {",
                    "        case 1: return 2;",
                    "        case 2: return 4;",
                    "        case DUAL_BOSS_STAGE: return 2;",
                    "        case 4: return 6;",
                    "    }",
                    "}",
                    "/// @func GameBossPhaseCountForStage",
                )
            )
            + "\n",
            encoding="utf-8",
        )
        (tests / "test_bootstrap.gml").write_text("test(\"one\");\ntest(\"two\");\n", encoding="utf-8")
        (helpers / "scr_test_helpers.gml").write_text("expected_capture_count: 26,\n", encoding="utf-8")
        for name in ("check_repository_hygiene.py", "run_gmtl_tests_ci.ps1"):
            (tools / name).write_text("# fixture\n", encoding="utf-8")
        for name in ("run_gmtl_tests.zsh", "run_yyc_playtest.zsh"):
            path = tools / name
            path.write_text("#!/bin/zsh\n", encoding="utf-8")
            path.chmod(0o755)
        (workflow / "gamemaker-tests.yml").write_text(
            "\n".join(
                (
                    "jobs:",
                    "  repository_hygiene:",
                    "    steps:",
                    "      - run: |",
                    "          python3 tools/check_governance.py",
                    "  pr_governance:",
                    "    steps:",
                    "      - run: |",
                    "          python3 tools/check_pr_governance.py \\",
                    "            --event fixture.json",
                    "  required_ci:",
                    "    name: 'Required CI'",
                )
            )
            + "\n",
            encoding="utf-8",
        )
        return temporary

    def _run(self, root: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "tools/check_governance.py"],
            cwd=root,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_current_fixture_passes(self) -> None:
        with self._fixture() as temporary:
            result = self._run(Path(temporary))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_stale_state_summary_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            state = root / "docs" / "PROJECT_STATE.md"
            state.write_text(state.read_text(encoding="utf-8").replace("`5`", "`6`", 1), encoding="utf-8")
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("stage count does not match", result.stderr)

    def test_missing_boss_phase_function_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            gameplay = root / "Selkie's Moon ~ until we meet again ~" / "scripts" / "scr_gameplay_helpers" / "scr_gameplay_helpers.gml"
            gameplay.write_text(
                gameplay.read_text(encoding="utf-8").replace("GameBossExpandedPhaseCountForStage", "RemovedBossPhaseFunction"),
                encoding="utf-8",
            )
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("GameBossExpandedPhaseCountForStage is missing", result.stderr)

    def test_other_source_fact_mismatches_fail(self) -> None:
        cases = (
            ("#macro LEGACY_STAGE_COUNT 10", "#macro LEGACY_STAGE_COUNT 9", "legacy wave count"),
            ("#macro RANK_MAX 50", "#macro RANK_MAX 51", "rank range"),
            ("#macro RANK_DEFAULT 50", "#macro RANK_DEFAULT 49", "rank default"),
            ("case 2: return 4;", "case 2: return 3;", "boss phase counts"),
            ("#macro FINAL_BOSS_EXPANDED_PHASE_COUNT 14", "#macro FINAL_BOSS_EXPANDED_PHASE_COUNT 13", "boss phase counts"),
        )
        for old, new, expected in cases:
            with self.subTest(expected=expected), self._fixture() as temporary:
                root = Path(temporary)
                gameplay = root / "Selkie's Moon ~ until we meet again ~" / "scripts" / "scr_gameplay_helpers" / "scr_gameplay_helpers.gml"
                gameplay.write_text(gameplay.read_text(encoding="utf-8").replace(old, new), encoding="utf-8")
                result = self._run(root)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected, result.stderr)

        with self._fixture() as temporary:
            root = Path(temporary)
            tests = root / "Selkie's Moon ~ until we meet again ~" / "scripts" / "test_bootstrap" / "test_bootstrap.gml"
            tests.write_text("test(\"one\");\n", encoding="utf-8")
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("test count", result.stderr)

        with self._fixture() as temporary:
            root = Path(temporary)
            helpers = root / "Selkie's Moon ~ until we meet again ~" / "scripts" / "scr_test_helpers" / "scr_test_helpers.gml"
            helpers.write_text("expected_capture_count: 25,\n", encoding="utf-8")
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("visual-tour count", result.stderr)

    def test_broken_local_link_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            (root / "README.md").write_text("[Missing](docs/missing.md)\n", encoding="utf-8")
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("broken local link", result.stderr)

    def test_out_of_repository_local_link_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            (root / "README.md").write_text("[Outside](/usr)\n", encoding="utf-8")
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("escapes repository", result.stderr)

    def test_out_of_repository_reference_and_autolinks_fail(self) -> None:
        cases = (
            "[Outside][outside]\n\n[outside]: /usr\n",
            "<file:///usr>\n",
        )
        for body in cases:
            with self.subTest(body=body), self._fixture() as temporary:
                root = Path(temporary)
                (root / "README.md").write_text(body, encoding="utf-8")
                result = self._run(root)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("escapes repository", result.stderr)

    def test_missing_governance_check_invocation_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            workflow = root / ".github" / "workflows" / "gamemaker-tests.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace("          python3 tools/check_governance.py\n", ""),
                encoding="utf-8",
            )
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not run the governance check", result.stderr)

    def test_missing_required_workflow_gate_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            workflow = root / ".github" / "workflows" / "gamemaker-tests.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8").replace("  pr_governance:\n", ""), encoding="utf-8")
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PR-governance gate", result.stderr)

    def test_missing_required_ci_aggregator_fails(self) -> None:
        with self._fixture() as temporary:
            root = Path(temporary)
            workflow = root / ".github" / "workflows" / "gamemaker-tests.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace("  required_ci:\n    name: 'Required CI'\n", ""),
                encoding="utf-8",
            )
            result = self._run(root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Required CI", result.stderr)


if __name__ == "__main__":
    unittest.main()

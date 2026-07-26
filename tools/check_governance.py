#!/usr/bin/env python3
"""Check the repository's live governance entry points and state summary."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "Selkie's Moon ~ until we meet again ~"
GAMEPLAY = GAME / "scripts" / "scr_gameplay_helpers" / "scr_gameplay_helpers.gml"
TESTS = GAME / "scripts" / "test_bootstrap" / "test_bootstrap.gml"
TEST_HELPERS = GAME / "scripts" / "scr_test_helpers" / "scr_test_helpers.gml"
STATE = ROOT / "docs" / "PROJECT_STATE.md"
WORKFLOW = ROOT / ".github" / "workflows" / "gamemaker-tests.yml"

REQUIRED_PATHS = (
    ROOT / "AGENTS.md",
    ROOT / "README.md",
    ROOT / "docs" / "GOVERNANCE_HANDOFF.md",
    ROOT / "docs" / "AGENT_REVIEW_POLICY.md",
    ROOT / "docs" / "ARCHITECTURE.md",
    ROOT / "docs" / "ASSET_PIPELINE.md",
    ROOT / "docs" / "BRANCH_AND_RELEASE_POLICY.md",
    ROOT / "docs" / "HANDOFF_TEMPLATE.md",
    STATE,
    ROOT / "docs" / "VALIDATION.md",
    ROOT / "tools" / "check_governance.py",
    ROOT / "tools" / "check_repository_hygiene.py",
    WORKFLOW,
    ROOT / "tools" / "run_gmtl_tests.zsh",
    ROOT / "tools" / "run_gmtl_tests_ci.ps1",
    ROOT / "tools" / "run_yyc_playtest.zsh",
    GAME / "Selkies Moon.yyp",
    GAMEPLAY,
    TESTS,
    TEST_HELPERS,
)


errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


for path in REQUIRED_PATHS:
    require(path.exists(), f"missing required path: {path.relative_to(ROOT)}")

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


agents = read(ROOT / "AGENTS.md")
handoff = read(ROOT / "docs" / "GOVERNANCE_HANDOFF.md")
review_policy = read(ROOT / "docs" / "AGENT_REVIEW_POLICY.md")
state = read(STATE)
validation = read(ROOT / "docs" / "VALIDATION.md")
gameplay = read(GAMEPLAY)
tests = read(TESTS)
test_helpers = read(TEST_HELPERS)
workflow = read(WORKFLOW)

# The root instructions deliberately route to the authoritative governance map
# instead of copying its rules.
require("docs/GOVERNANCE_HANDOFF.md" in agents, "AGENTS.md does not route to Governance Handoff")
require("Agent Review Policy" in handoff, "Governance Handoff does not route to Agent Review Policy")
require("Branch and Release Policy" in handoff, "Governance Handoff does not route to Branch and Release Policy")
require("Asset Pipeline" in handoff, "Governance Handoff does not route to Asset Pipeline")
require("Exact-head validation" in review_policy, "Agent Review Policy no longer documents exact-head review")
require("ASSET_PIPELINE.md" in state, "PROJECT_STATE.md does not use the current Asset Pipeline name")
require("not repository policy" in read(ROOT / "docs" / "HANDOFF_TEMPLATE.md"), "HANDOFF_TEMPLATE.md does not preserve policy authority")
require("Required CI" in validation, "VALIDATION.md does not document exact-head Required CI evidence")
require("visual-tour" in validation, "VALIDATION.md does not document visual validation")
require(
    re.search(r"^\s*python3 tools/check_governance\.py\s*$", workflow, re.MULTILINE) is not None,
    "GitHub Actions does not run the governance check",
)
require(
    re.search(r"^\s{2}pr_governance:\s*$", workflow, re.MULTILINE) is not None
    and re.search(r"^\s*python3 tools/check_pr_governance\.py(?:\s+\\)?\s*$", workflow, re.MULTILINE) is not None,
    "GitHub Actions no longer runs the PR-governance gate",
)
require(
    re.search(r"^\s{2}required_ci:\s*$", workflow, re.MULTILINE) is not None
    and "'Required CI'" in workflow,
    "GitHub Actions no longer aggregates pull-request evidence as Required CI",
)

# Validate local Markdown links in the compact governance/documentation surface.
inline_link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
reference_link_pattern = re.compile(r"^\s*\[[^\]]+\]:\s*(?:<([^>]+)>|(\S+))", re.MULTILINE)
autolink_pattern = re.compile(r"<(file:[^<>\s]+)>", re.IGNORECASE)
markdown_files = [ROOT / "AGENTS.md", ROOT / "README.md", *sorted((ROOT / "docs").glob("*.md"))]
for document in markdown_files:
    body = read(document)
    targets = list(inline_link_pattern.findall(body))
    targets.extend(first or second for first, second in reference_link_pattern.findall(body))
    targets.extend(autolink_pattern.findall(body))
    for target in targets:
        target = target.strip().strip("<>")
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        parsed = urlparse(target)
        local_path = unquote(parsed.path if parsed.scheme == "file" else target.split("#", 1)[0])
        if not local_path:
            continue
        resolved = (document.parent / local_path).resolve()
        try:
            resolved.relative_to(ROOT)
        except ValueError:
            require(
                False,
                f"local link escapes repository in {document.relative_to(ROOT)}: {target}",
            )
            continue
        require(resolved.exists(), f"broken local link in {document.relative_to(ROOT)}: {target}")


def macro_int(name: str) -> int | None:
    match = re.search(rf"^#macro\s+{re.escape(name)}\s+(-?\d+)\s*$", gameplay, re.MULTILINE)
    return int(match.group(1)) if match else None


stage_count = macro_int("STAGE_COUNT")
legacy_stage_count = macro_int("LEGACY_STAGE_COUNT")
rank_min = macro_int("RANK_MIN")
rank_max = macro_int("RANK_MAX")
rank_default = macro_int("RANK_DEFAULT")
final_expanded_phase_count = macro_int("FINAL_BOSS_EXPANDED_PHASE_COUNT")

require(stage_count is not None, "STAGE_COUNT is not a simple integer macro")
require(legacy_stage_count is not None, "LEGACY_STAGE_COUNT is not a simple integer macro")
require(rank_min is not None and rank_max is not None, "rank bounds are not simple integer macros")
require(rank_default is not None, "RANK_DEFAULT is not a simple integer macro")
require(final_expanded_phase_count is not None, "FINAL_BOSS_EXPANDED_PHASE_COUNT is not a simple integer macro")

if stage_count is not None:
    require(f"Consolidated stages: `{stage_count}`" in state, "PROJECT_STATE.md stage count does not match STAGE_COUNT")
if legacy_stage_count is not None:
    require(
        f"material from `{legacy_stage_count}` legacy wave" in state,
        "PROJECT_STATE.md legacy wave count does not match LEGACY_STAGE_COUNT",
    )
if rank_min is not None and rank_max is not None:
    require(f"Rank range: `{rank_min}-{rank_max}`" in state, "PROJECT_STATE.md rank range does not match rank macros")
    require("rank = RANK_MIN;" in gameplay, "normal run initialization no longer visibly starts at RANK_MIN")
if rank_default is not None:
    require(f"`{rank_default}` is the established" in state, "PROJECT_STATE.md rank default does not match RANK_DEFAULT")

phase_function = "function GameBossExpandedPhaseCountForStage"
phase_boundary = "/// @func GameBossPhaseCountForStage"
require(phase_function in gameplay, "GameBossExpandedPhaseCountForStage is missing")
require(phase_boundary in gameplay, "GameBossPhaseCountForStage contract marker is missing")
phase_body = gameplay.split(phase_function, 1)[1] if phase_function in gameplay else ""
phase_body = phase_body.split(phase_boundary, 1)[0]


def expanded_case(label: str) -> int | None:
    match = re.search(rf"case\s+{re.escape(label)}:\s*return\s+(\d+);", phase_body)
    return int(match.group(1)) if match else None


expanded_counts = [expanded_case("1"), expanded_case("2"), expanded_case("DUAL_BOSS_STAGE"), expanded_case("4")]
require(all(count is not None for count in expanded_counts), "boss phase switch is not discoverable")
if all(count is not None for count in expanded_counts) and final_expanded_phase_count is not None:
    counts = [count + 1 for count in expanded_counts]
    summary = f"{counts[0]},{counts[1]},{counts[2]}+{counts[2]}+shared,{counts[3]},{final_expanded_phase_count + 1}"
    require(f"Boss stage phase counts: `{summary}`" in state, "PROJECT_STATE.md boss phase counts do not match constructors")

test_count = len(re.findall(r"^\s*test\(", tests, re.MULTILINE))
require(f"GMTL tests declared: `{test_count}`" in state, "PROJECT_STATE.md test count does not match test declarations")
capture_match = re.search(r"expected_capture_count:\s*(\d+)", test_helpers)
require(capture_match is not None, "visual-tour expected capture count is missing")
capture_count = int(capture_match.group(1)) if capture_match else 0
if capture_match:
    require(
        f"Visual-tour captures declared: `{capture_count}`" in state,
        "PROJECT_STATE.md visual-tour count does not match scr_test_helpers",
    )

for script in (ROOT / "tools" / "run_gmtl_tests.zsh", ROOT / "tools" / "run_yyc_playtest.zsh"):
    require(script.stat().st_mode & 0o111 != 0, f"documented script is not executable: {script.relative_to(ROOT)}")

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"Governance checks passed: {test_count} declared GMTL tests; {capture_count} visual-tour captures.")
print("Governance routing, local Markdown links, state summaries, and CI integration are consistent.")

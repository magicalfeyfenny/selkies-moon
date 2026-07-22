#!/usr/bin/env python3
"""Check compact governance entry points against the current project tree."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "Selkie's Moon ~ until we meet again ~"
GAMEPLAY = GAME / "scripts/scr_gameplay_helpers/scr_gameplay_helpers.gml"
TESTS = GAME / "scripts/test_bootstrap/test_bootstrap.gml"
TEST_HELPERS = GAME / "scripts/scr_test_helpers/scr_test_helpers.gml"
STATE = ROOT / "docs/PROJECT_STATE.md"

REQUIRED_PATHS = (
    ROOT / "AGENTS.md",
    ROOT / "README.md",
    STATE,
    ROOT / "docs/ARCHITECTURE.md",
    ROOT / "docs/DEVELOPMENT.md",
    ROOT / "docs/GAMEPLAY_SYSTEMS.md",
    ROOT / "docs/DATA_FORMATS.md",
    ROOT / "docs/VALIDATION.md",
    ROOT / "docs/ASSET_PIPELINES.md",
    ROOT / "docs/HANDOFF_TEMPLATE.md",
    ROOT / "docs/AUDIO_DIRECTION.md",
    ROOT / ".github/workflows/gamemaker-tests.yml",
    ROOT / "tools/run_gmtl_tests.zsh",
    ROOT / "tools/run_gmtl_tests_ci.ps1",
    ROOT / "tools/run_yyc_playtest.zsh",
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

agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
state = STATE.read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
gameplay = GAMEPLAY.read_text(encoding="utf-8")
tests = TESTS.read_text(encoding="utf-8")
test_helpers = TEST_HELPERS.read_text(encoding="utf-8")
workflow = (ROOT / ".github/workflows/gamemaker-tests.yml").read_text(encoding="utf-8")

# Keep the only automatically loaded project file small. Nested instructions
# are intentionally absent; add them only with an indexed ownership need.
agents_size = (ROOT / "AGENTS.md").stat().st_size
require(agents_size <= 4096, f"AGENTS.md exceeds the 4096-byte context budget: {agents_size}")
require("docs/PROJECT_STATE.md" in agents, "AGENTS.md does not route through project state")
require("docs/ARCHITECTURE.md" in agents, "AGENTS.md does not route through architecture")
require(
    "run: python3 tools/check_governance.py" in workflow,
    "GitHub Actions does not run the governance check",
)

# Validate local Markdown links in the small governance/documentation surface.
markdown_files = [ROOT / "AGENTS.md", ROOT / "README.md", *sorted((ROOT / "docs").glob("*.md"))]
link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
for document in markdown_files:
    body = document.read_text(encoding="utf-8")
    for target in link_pattern.findall(body):
        target = target.strip().strip("<>")
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        local_path = unquote(target.split("#", 1)[0])
        if not local_path:
            continue
        resolved = (document.parent / local_path).resolve()
        require(resolved.exists(), f"broken local link in {document.relative_to(ROOT)}: {target}")


def macro_int(name: str) -> int | None:
    match = re.search(rf"^#macro\s+{re.escape(name)}\s+(-?\d+)\s*$", gameplay, re.MULTILINE)
    return int(match.group(1)) if match else None


stage_count = macro_int("STAGE_COUNT")
legacy_stage_count = macro_int("LEGACY_STAGE_COUNT")
rank_min = macro_int("RANK_MIN")
rank_max = macro_int("RANK_MAX")
rank_default = macro_int("RANK_DEFAULT")
final_boss_phases = macro_int("FINAL_BOSS_PHASE_COUNT")

require(stage_count is not None, "STAGE_COUNT is not a simple integer macro")
require(legacy_stage_count is not None, "LEGACY_STAGE_COUNT is not a simple integer macro")
require(rank_min is not None and rank_max is not None, "rank bounds are not simple integer macros")
require(rank_default is not None, "RANK_DEFAULT is not a simple integer macro")
require(final_boss_phases is not None, "FINAL_BOSS_PHASE_COUNT is not a simple integer macro")

if None not in (stage_count, legacy_stage_count):
    require(
        f"Consolidated stages: `{stage_count}`" in state,
        "PROJECT_STATE.md stage count does not match STAGE_COUNT",
    )
    require(
        f"material from `{legacy_stage_count}` legacy wave" in state,
        "PROJECT_STATE.md legacy wave count does not match LEGACY_STAGE_COUNT",
    )
if None not in (rank_min, rank_max):
    require(
        f"Rank range: `{rank_min}-{rank_max}`" in state,
        "PROJECT_STATE.md rank range does not match rank macros",
    )
    require(
        f"rank = RANK_MIN;" in gameplay,
        "normal run initialization no longer visibly starts at RANK_MIN",
    )
if rank_default is not None:
    require(
        f"`{rank_default}` is the established/default" in state,
        "PROJECT_STATE.md rank default does not match RANK_DEFAULT",
    )
if final_boss_phases is not None:
    expanded_body = gameplay.split("function GameBossExpandedPhaseCountForStage", 1)[-1]
    expanded_body = expanded_body.split("/// @func GameBossPhaseCountForStage", 1)[0]

    def expanded_case(label: str) -> int | None:
        match = re.search(rf"case\s+{re.escape(label)}:\s*return\s+(\d+);", expanded_body)
        return int(match.group(1)) if match else None

    expanded_counts = [
        expanded_case("1"),
        expanded_case("2"),
        expanded_case("DUAL_BOSS_STAGE"),
        expanded_case("4"),
    ]
    require(all(count is not None for count in expanded_counts), "boss stage phase switch is not discoverable")
    if all(count is not None for count in expanded_counts):
        phase_summary = [count + 1 for count in expanded_counts]
        bound_summary = (
            f"{phase_summary[0]},{phase_summary[1]},{phase_summary[2]}+shared,"
            f"{phase_summary[3]},{final_boss_phases}"
        )
        require(
            f"Boss stage phase counts: `{bound_summary}`" in state,
            "PROJECT_STATE.md boss phase counts do not match constructors",
        )

require("10 stages" not in readme, "README.md still describes a ten-stage runtime")
require("stage 10" not in readme.lower(), "README.md still routes completion through stage 10")
require("0-100" not in readme, "README.md still describes the obsolete rank range")
require("five consolidated stages" in readme, "README.md lacks the consolidated stage description")

test_count = len(re.findall(r"^\s*test\(", tests, re.MULTILINE))
require(
    f"GMTL tests declared: `{test_count}`" in state,
    f"PROJECT_STATE.md test count does not match {test_count} declarations",
)
capture_match = re.search(r"expected_capture_count:\s*(\d+)", test_helpers)
require(capture_match is not None, "visual-tour expected capture count is missing")
if capture_match:
    capture_count = int(capture_match.group(1))
    require(
        f"Visual-tour captures declared: `{capture_count}`" in state,
        "PROJECT_STATE.md visual-tour count does not match scr_test_helpers",
    )

# Verify the task-specific production index without loading it during cold start.
audio_root = ROOT / "art/audio_production"
score_manifest_path = audio_root / "score_manifest.json"
loop_validation_path = audio_root / "loop_validation.json"
require(score_manifest_path.exists(), "missing score manifest")
require(loop_validation_path.exists(), "missing loop validation report")
if score_manifest_path.exists() and loop_validation_path.exists():
    score_manifest = json.loads(score_manifest_path.read_text(encoding="utf-8"))
    loop_validation = json.loads(loop_validation_path.read_text(encoding="utf-8"))
    cues = score_manifest.get("cues", [])
    completed = loop_validation.get("completed", [])
    missing = loop_validation.get("missing", [])
    require(len(cues) == len(completed) == 15, "score manifest/validation is not complete for 15 cues")
    require(not missing, f"loop validation reports missing cues: {missing}")
    for cue in cues:
        master = audio_root / cue.get("lossless_master", "")
        require(master.is_file(), f"missing lossless score master: {master.relative_to(ROOT)}")
        sound_id = cue.get("runtime_sound_id", "")
        sound_metadata = GAME / "sounds" / sound_id / f"{sound_id}.yy"
        require(sound_metadata.is_file(), f"missing runtime sound metadata for {sound_id}")
        if sound_metadata.is_file():
            sound_text = sound_metadata.read_text(encoding="utf-8")
            duration_match = re.search(r'"duration":([0-9.]+)', sound_text)
            file_match = re.search(r'"soundFile":"([^"]+)"', sound_text)
            require(duration_match is not None, f"runtime duration is missing for {sound_id}")
            require(file_match is not None, f"runtime sound file is missing for {sound_id}")
            if duration_match:
                duration_delta = abs(float(duration_match.group(1)) - float(cue["duration_seconds"]))
                require(duration_delta < 0.01, f"runtime duration drift for {sound_id}")
            if file_match:
                runtime_audio = sound_metadata.parent / file_match.group(1)
                require(runtime_audio.is_file(), f"runtime audio file is missing for {sound_id}")
    logic_projects = [audio_root / cue.get("logic_project", "") for cue in cues]
    logic_present = sum(path.is_file() for path in logic_projects)
    require(
        f"Editable Logic projects present: `{logic_present}/{len(cues)}`" in state,
        "PROJECT_STATE.md Logic project count does not match the score manifest",
    )
    if logic_present == 0:
        require("none are present in this checkout" in state, "PROJECT_STATE.md omits the Logic source gap")

ignore_text = (ROOT / ".gitignore").read_text(encoding="utf-8")
for ignored in ("/cache/", "/output/", "/test-results/", "/tmp/"):
    require(ignored in ignore_text, f"root .gitignore is missing {ignored}")

for script in (ROOT / "tools/run_gmtl_tests.zsh", ROOT / "tools/run_yyc_playtest.zsh"):
    require(script.stat().st_mode & 0o111 != 0, f"documented script is not executable: {script.relative_to(ROOT)}")

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)

routed_size = sum(
    path.stat().st_size
    for path in (ROOT / "AGENTS.md", STATE, ROOT / "docs/ARCHITECTURE.md")
)
print(f"Governance checks passed: {test_count} tests, {capture_count} visual captures, 15 audio cues.")
print(f"Always-loaded project instructions: AGENTS.md {agents_size} bytes; nested instruction files 0.")
print(f"Core routed cold-start context: {routed_size} bytes before task-specific sections.")

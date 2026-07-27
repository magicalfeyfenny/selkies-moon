#!/usr/bin/env python3
"""Validate a PR contract and independent review-agent attestations."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Iterable, Sequence


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_SECTIONS = (
    "Primary issue",
    "Intent",
    "Scope",
    "Non-goals",
    "Acceptance mapping",
    "Important files and ownership",
    "Risk",
    "Validation",
    "Review status",
    "Remaining risks",
    "Merge intention",
    "External-action authority",
    "Rollback or final disposition",
    "Non-merge record",
    "Lifecycle exception",
    "Independent agent review",
)
RISK_ORDER = {
    "low": 0,
    "standard": 1,
    "high": 2,
    "main-promotion": 3,
}
REQUIRED_ROLES = {
    "low": {"correctness"},
    "standard": {"correctness", "validation"},
    "high": {"correctness", "validation", "governance"},
    "main-promotion": {"correctness", "validation", "release-governance"},
}
CONTRACT_FIELDS = {
    "version",
    "repository",
    "pr_number",
    "head_sha",
    "base_sha",
    "base_ref",
    "head_ref",
    "implementation_agent",
    "acceptance_sha256",
    "risk",
    "controls",
}
MAIN_CONTRACT_FIELDS = CONTRACT_FIELDS | {"candidate_sha", "candidate_tree"}
CONTROL_FIELDS = {"target_branch", "lfs", "generated_ownership", "documentation"}
ATTESTATION_FIELDS = {
    "version",
    "repository",
    "pr_number",
    "head_sha",
    "base_sha",
    "base_ref",
    "head_ref",
    "contract_sha256",
    "implementation_agent",
    "risk",
    "role",
    "reviewer_agent",
    "verdict",
    "blocking_findings",
    "evidence",
}
INTERNAL_ATTESTATION_FIELDS = {
    "__comment_id",
    "__comment_order",
    "__comment_updated_at",
}
CONTROL_VALUES = {
    "lfs": {"not-applicable", "verified"},
    "generated_ownership": {"not-applicable", "verified"},
    "documentation": {"not-applicable", "updated", "verified-current"},
}
SHA_PATTERN = re.compile(r"[0-9a-f]{40}")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
PRIMARY_ISSUE_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_./#-])#([1-9][0-9]*)"
    r"(?![A-Za-z0-9_#]|[./-][A-Za-z0-9])"
)
BRANCH_ISSUE_PATTERN = re.compile(r"(?:^|[-_/])([1-9][0-9]*)(?=$|[-_/])")
LIFECYCLE_FIELD_PATTERN = re.compile(
    r"\b(?P<label>"
    r"Legacy registration|Immutable candidate SHA|Reason|Original branch identity|"
    r"Original primary issue|Retained evidence|Intended disposition|Purpose|"
    r"Exact candidate or workflow SHA|Final disposition|Close or deletion conditions"
    r"):"
)
EXACT_SHA_VALUE_PATTERN = re.compile(
    r"(?<![0-9A-Fa-f])[0-9a-f]{40}(?![0-9A-Fa-f])"
)
LEGACY_REGISTRATION_VALUE_PATTERN = re.compile(r"#47[.!?]?")
CLOSES_ISSUE_PATTERN = re.compile(r"\bCloses\s+#[1-9][0-9]*\b", re.IGNORECASE)
LIFECYCLE_NON_MERGE_PREDICATE_PATTERN = re.compile(
    r"\b(?:"
    r"(?:must|shall|should|will|would|can|could|may)\s+(?:not|never)\s+"
    r"(?:(?:be|being)\s+)?merg(?:e|ed|ing)|"
    r"(?:mustn't|shouldn't|won't|wouldn't|can't|couldn't|isn't|aren't)\s+"
    r"(?:(?:be|being|to\s+be)\s+)?merg(?:e|ed|ing)|"
    r"cannot\s+(?:be\s+)?merg(?:e|ed|ing)|"
    r"(?:is|are|was|were)\s+(?:not|never)\s+"
    r"(?:(?:being|to\s+be)\s+)?merg(?:e|ed|ing)|"
    r"(?:is|are)\s+(?:forbidden|prohibited|barred)\s+from\s+merging"
    r")\b",
    re.IGNORECASE,
)
LIFECYCLE_NON_MERGE_IMPERATIVE_PATTERN = re.compile(
    r"\b(?:"
    r"do(?:es)?(?:\s+|-)+not(?:\s+|-)+merge|"
    r"don't\s+merge|doesn't\s+merge|"
    r"never(?:\s+|-)+merge"
    r")\b",
    re.IGNORECASE,
)
LIFECYCLE_REPLACEMENT_COMPARISON_PATTERN = re.compile(
    r"\b(?:instead\s+of|rather\s+than|without)\s+"
    r"(?:(?:being|be)\s+)?merg(?:e|ing|ed)\b",
    re.IGNORECASE,
)
LIFECYCLE_HOUSEKEEPING_VERB_PATTERN = re.compile(
    r"\b(?:retain|archive|preserve|close|delete|keep)\b",
    re.IGNORECASE,
)
LIFECYCLE_ACTION_OBJECT_PATTERN = re.compile(
    r"\b(?:"
    r"candidate(?:s)?|branch(?:es)?|pull[\s-]+request(?:s)?|prs?|changes?|"
    r"evidence|logs?|records?|objects?|files?"
    r")\b",
    re.IGNORECASE,
)
POST_MERGE_QUALIFIER_PATTERN = re.compile(
    r"\b(?:"
    r"after\s+(?:a\s+|the\s+)?(?:successful\s+)?(?:merge|integration)|"
    r"after\s+(?:this|the\s+current)\s+"
    r"(?:candidate|branch|pull[\s-]+request|pr)\s+(?:merges|is\s+merged)|"
    r"after\s+(?:pull[\s-]+request|pr)\s*#[1-9][0-9]*\s+merges|"
    r"once\s+(?:(?:this|the\s+current)\s+"
    r"(?:candidate|branch|pull[\s-]+request|pr)\s+is\s+)?"
    r"(?:successfully\s+)?merged|"
    r"upon\s+(?:successful\s+)?(?:merge|integration)|"
    r"following\s+successful\s+integration"
    r")\b",
    re.IGNORECASE,
)
LIFECYCLE_HARD_BOUNDARY_PATTERN = re.compile(r"[.!?;:\n]")
LIFECYCLE_COORDINATION_BOUNDARY_PATTERN = re.compile(
    r"(?:,\s*)?\b(?:but|however|yet|then|although)\b|"
    r",\s*\band\b|"
    r"\band\b(?=\s+(?:this|the|current|these|it|they|after|once|upon|"
    r"following|do|never|retain|archive|preserve|close|delete|keep)\b)",
    re.IGNORECASE,
)
LIFECYCLE_DESCRIPTIVE_FRAME_PATTERN = re.compile(
    r"\b(?:"
    r"checker|parser|policy|(?:validation\s+)?rule|tests?|test[\s-]+cases?|"
    r"examples?|documentation|description|prose|sentences?|phrases?|wording"
    r")\b"
    r"(?:(?![.!?;\n]).){0,140}?"
    r"\b(?:"
    r"rejects?|detects?|describes?|documents?|explains?|tests?|covers?|"
    r"quotes?|mentions?|recognizes?|illustrates?|accepts?|flags?|matches?|"
    r"parses?|asserts?|exercises?|states?|says?|claims?|instructions?"
    r")\b",
    re.IGNORECASE,
)
LIFECYCLE_QUOTATION_PATTERN = re.compile(
    r'"[^"\n]*"|“[^”\n]*”|(?<![A-Za-z0-9])\'[^\'\n]+\'(?![A-Za-z0-9])'
)
OTHER_CANDIDATE_REFERENCE_PATTERN = re.compile(
    r"\b(?:(?:this|that|the|a|an)\s+)?"
    r"(?:historical|legacy|previous|prior|other|unrelated)\s+"
    r"(?:candidate(?:s)?|branch(?:es)?|pull[\s-]+request(?:s)?|prs?|changes?)\b|"
    r"\b(?:pull[\s-]+request|pr)\s*#\s*[1-9][0-9]*\b",
    re.IGNORECASE,
)
LIFECYCLE_OTHER_MERGE_OBJECT_PATTERN = re.compile(
    r"^\s+(?:(?:the|an?|any|these|those)\s+)?"
    r"(?:unrelated|other|historical|legacy|previous|prior)\s+"
    r"(?:changes?|branches?|pull[\s-]+requests?|prs?|commits?)\b",
    re.IGNORECASE,
)
REPOSITORY_PATTERN = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
AGENT_ID_PATTERN = re.compile(r"[A-Za-z0-9/][A-Za-z0-9._:/@-]{1,127}")
PLACEHOLDER_PATTERN = re.compile(
    r"(?:\b(?:todo|tbd|fixme|placeholder|changeme|replace[-_ ]?me)\b|"
    r"<[^>\n]+>|\{\{[^}\n]+\}\})",
    re.IGNORECASE,
)
SECTION_PLACEHOLDER_PATTERN = re.compile(
    r"(?:(?<![^\W_])(?:todo|tbd|fixme|placeholder|changeme|replace[-_ ]?me)"
    r"(?![^\W_])|"
    r"\{\{[^}\n]+\}\})",
    re.IGNORECASE,
)
MARKDOWN_ENTITY_PATTERN = re.compile(
    r"&(?:#[0-9]{1,7}|#[xX][0-9A-Fa-f]{1,6}|[A-Za-z][A-Za-z0-9]+);"
)
GITHUB_EMOJI_ALIAS_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_]):[A-Za-z0-9_+-]+:(?![A-Za-z0-9_])"
)
GITHUB_CONTEXT_REFERENCE_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_.-])(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#[0-9]+\b"
)
URL_PATTERN = re.compile(r"(?:https?://|mailto:)[^\s<>]+", re.IGNORECASE)
FULL_SHA_PATTERN = re.compile(r"(?<![0-9A-Fa-f])[0-9A-Fa-f]{40}(?![0-9A-Fa-f])")
KEYCAP_SEQUENCE_PATTERN = re.compile(r"[#*0-9]\ufe0f?\u20e3")
PLAIN_PROSE_TOKEN_PATTERN = re.compile(
    r"[A-Za-z][A-Za-z0-9]*(?:['-][A-Za-z0-9]+)*"
)
PLAIN_PROSE_TOKEN_TRIM = ".,;:!?()\"'_*~=-+"
PLAIN_PROSE_LIST_PATTERN = re.compile(r"(?:[-+*]|[0-9]{1,9}[.)])(?:[ \t]|$)")
INLINE_HTML_TAG_PATTERN = re.compile(
    r"</?[A-Za-z][A-Za-z0-9-]*"
    r"(?:[ \t\r\n]+[A-Za-z_:][A-Za-z0-9_.:-]*"
    r"(?:[ \t\r\n]*=[ \t\r\n]*"
    r"(?:[^\s\"'=<>`]+|'[^']*'|\"[^\"]*\"))?)*"
    r"[ \t\r\n]*/?>"
)
NON_RENDERING_HTML_PATTERN = re.compile(
    r"<\?.*?\?>|<!\[CDATA\[.*?\]\]>|<![A-Za-z][^>]*>",
    re.DOTALL,
)
HTML_SHAPED_TAG_PATTERN = re.compile(
    r"<(?!https?://|mailto:)/?[A-Za-z][A-Za-z0-9:-]*"
    r"(?=[ \t\r\n/>]|\Z)",
    re.IGNORECASE,
)
HTML_SHAPED_DECLARATION_PATTERN = re.compile(
    r"<(?:\?|![A-Za-z]|!\[CDATA\[)",
    re.IGNORECASE,
)
MINIMUM_SECTION_ALPHANUMERIC_CHARACTERS = 12
MINIMUM_SECTION_WORDS = 3
MINIMUM_EVIDENCE_ALPHANUMERIC_CHARACTERS = 20
MINIMUM_EVIDENCE_WORDS = 4
HTML_COMMENT_PATTERN = re.compile(r"<!--(?P<content>.*?)-->", re.DOTALL)
RAW_HTML_BLOCK_PATTERN = re.compile(
    r"^ {0,3}(?:"
    r"</?[A-Za-z][A-Za-z0-9:-]*(?:[ \t]|/?>|\r?$)|"
    r"<\?|<![A-Za-z]|<!\[CDATA\["
    r")",
    re.MULTILINE,
)
MARKER_OPEN_PATTERNS = {
    "pr-contract:v1": re.compile(r"<!--\s*pr-contract:v1\b", re.IGNORECASE),
    "agent-review:v1": re.compile(r"<!--\s*agent-review:v1\b", re.IGNORECASE),
}
HIGH_RISK_EXACT_PATHS = {
    ".gitattributes",
    ".gitignore",
    ".gitmodules",
    ".lfsconfig",
    "AGENTS.md",
    "art/audio_production/sfx_cue_sheets/sfx_install_report.json",
    "art/runtime_package_manifest.json",
    "docs/AGENT_REVIEW_POLICY.md",
    "docs/ARCHITECTURE.md",
    "docs/ASSET_PIPELINE.md",
    "docs/BRANCH_AND_RELEASE_POLICY.md",
    "docs/DATA_FORMATS.md",
    "docs/DEVELOPMENT.md",
    "docs/GOVERNANCE_HANDOFF.md",
    "docs/HANDOFF_TEMPLATE.md",
    "docs/PROJECT_STATE.md",
    "docs/VALIDATION.md",
    "docs/LFS_MIGRATION.md",
    "Selkie's Moon ~ until we meet again ~/art/character_portraits/PORTRAIT_BRIEFS.md",
    "Selkie's Moon ~ until we meet again ~/art/character_portraits/README.md",
    "tools/check_pr_governance.py",
    "tools/check_governance.py",
    "tools/check_repository_hygiene.py",
    "tools/tests/test_check_governance.py",
    "tools/tests/test_check_pr_governance.py",
    "tools/tests/test_check_repository_hygiene.py",
}
DEPENDENCY_BASENAMES = {
    "Cargo.lock",
    "Cargo.toml",
    "Gemfile",
    "Gemfile.lock",
    "Pipfile",
    "Pipfile.lock",
    "composer.json",
    "composer.lock",
    "go.mod",
    "go.sum",
    "package-lock.json",
    "package.json",
    "pnpm-lock.yaml",
    "poetry.lock",
    "pyproject.toml",
    "uv.lock",
    "yarn.lock",
}
SOURCE_AUTHORITY_SUFFIXES = {".blend", ".kra", ".logicx"}
PACKAGE_SUFFIXES = {".yyp", ".yymps"}
DOC_SUFFIXES = {".md"}
TRUSTED_REVIEW_COMMENT_IDENTITIES = {26424169: "magicalfeyfenny"}
BROAD_CHANGE_PATH_THRESHOLD = 25
CROSS_SYSTEM_PATH_THRESHOLD = 8
CROSS_SYSTEM_DOMAIN_THRESHOLD = 4
PROJECT_DIRECTORY = "selkie's moon ~ until we meet again ~"


class DuplicateKeyError(ValueError):
    """Raised when a supposedly canonical JSON object repeats a key."""


def _reject_duplicate_keys(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def _loads_strict(payload: str) -> object:
    return json.loads(payload, object_pairs_hook=_reject_duplicate_keys)


def _load_json_file(path: str) -> object:
    return _loads_strict(Path(path).read_text(encoding="utf-8"))


def _run_git(*args: str) -> bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout


def _parse_name_status(output: bytes) -> list[str]:
    """Return every affected path, including both sides of copies and renames."""
    tokens = output.split(b"\0")
    if tokens and not tokens[-1]:
        tokens.pop()
    paths: list[str] = []
    index = 0
    while index < len(tokens):
        status = tokens[index].decode("ascii", errors="strict")
        index += 1
        path_count = 2 if status.startswith(("R", "C")) else 1
        if not re.fullmatch(r"(?:[ACDMRTUXB]|[RC][0-9]{1,3})", status):
            raise RuntimeError(f"git diff returned unsupported status {status!r}")
        if index + path_count > len(tokens):
            raise RuntimeError("git diff returned a truncated name-status record")
        for raw_path in tokens[index : index + path_count]:
            paths.append(raw_path.decode("utf-8", errors="surrogateescape"))
        index += path_count
    return sorted(set(paths))


def _changed_paths(base_sha: str, head_sha: str) -> list[str]:
    output = _run_git(
        "diff",
        "--name-status",
        "-z",
        "--find-renames",
        f"{base_sha}...{head_sha}",
    )
    return _parse_name_status(output)


def _tree_sha(commit_sha: str) -> str:
    value = _run_git("rev-parse", "--verify", f"{commit_sha}^{{tree}}")
    tree_sha = value.decode("ascii", errors="strict").strip()
    if not SHA_PATTERN.fullmatch(tree_sha):
        raise RuntimeError("git rev-parse did not return a full SHA-1 tree identity")
    return tree_sha


def _commit_sha(ref: str) -> str:
    value = _run_git("rev-parse", "--verify", f"{ref}^{{commit}}")
    commit_sha = value.decode("ascii", errors="strict").strip()
    if not SHA_PATTERN.fullmatch(commit_sha):
        raise RuntimeError("git rev-parse did not return a full SHA-1 commit identity")
    return commit_sha


def _is_ancestor(base_sha: str, head_sha: str) -> bool:
    result = subprocess.run(
        ["git", "merge-base", "--is-ancestor", base_sha, head_sha],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode == 0:
        return True
    if result.returncode == 1:
        return False
    detail = result.stderr.decode("utf-8", errors="replace").strip()
    raise RuntimeError(f"git merge-base --is-ancestor failed: {detail}")


def _path_parts(path: str) -> tuple[str, ...]:
    pure = PurePosixPath(path)
    return pure.parts


def _is_high_risk_path(path: str) -> bool:
    parts = _path_parts(path)
    basename = parts[-1] if parts else path
    suffix = PurePosixPath(path).suffix.lower()
    lowered = path.lower()
    lowered_parts = tuple(part.lower() for part in parts)
    lowered_basename = basename.lower()
    if path in HIGH_RISK_EXACT_PATHS:
        return True
    if path == "AGENTS.md" or path.endswith("/AGENTS.md"):
        return True
    if path.startswith(".github/"):
        return True
    if re.fullmatch(r"(?:licen[cs]e|copying|notice)(?:\..+)?", lowered_basename):
        return True
    if lowered_basename in {"security.md", "privacy.md", ".env", "id_rsa", "id_dsa"}:
        return True
    if lowered_basename.startswith(".env.") or suffix in {".key", ".pem", ".p12", ".pfx"}:
        return True
    if "secrets" in lowered_parts or "credentials" in lowered_parts:
        return True
    if "options" in lowered_parts and suffix in {".yy", ".json", ".plist", ".xml"}:
        return True
    if basename in DEPENDENCY_BASENAMES or re.fullmatch(r"requirements(?:-[^/]+)?\.txt", basename):
        return True
    if suffix in SOURCE_AUTHORITY_SUFFIXES or any(
        part.lower().endswith(".logicx") for part in parts
    ):
        return True
    if suffix in PACKAGE_SUFFIXES:
        return True
    if any(part in {"migrations", "packages", "vendor"} for part in lowered_parts):
        return True
    if lowered.startswith(
        (
            "tools/migrate_",
            "scripts/migrate_",
            "tools/export_",
            "tools/build_",
            "tools/install_",
            "tools/finalize_",
            "tools/validate_logic_",
            "tools/blender_",
            "selkie's moon ~ until we meet again ~/scripts/scr_setup/",
        )
    ):
        return True
    if "art" in lowered_parts and any(
        token in lowered_parts
        for token in {"master", "masters", "originals", "original_character_references", "source", "sources"}
    ):
        return True
    if "manifest" in basename.lower() and (
        lowered.startswith(("art/", "packages/")) or "/package" in lowered
    ):
        return True
    if lowered.startswith("docs/") and "policy" in basename.lower():
        return True
    return False


def _is_documentation_path(path: str) -> bool:
    return PurePosixPath(path).suffix.lower() in DOC_SUFFIXES


def _change_domain(path: str) -> str:
    parts = tuple(part.lower() for part in PurePosixPath(path).parts)
    if not parts:
        return path.lower()
    if parts[0] == PROJECT_DIRECTORY and len(parts) > 1:
        return "/".join(parts[:2])
    return parts[0]


def minimum_risk(base_branch: str, changed_paths: Iterable[str]) -> str:
    paths = sorted(set(changed_paths))
    if base_branch == "main":
        return "main-promotion"
    if any(_is_high_risk_path(path) for path in paths):
        return "high"
    domains = {_change_domain(path) for path in paths}
    if len(paths) >= BROAD_CHANGE_PATH_THRESHOLD:
        return "high"
    if (
        len(paths) >= CROSS_SYSTEM_PATH_THRESHOLD
        and len(domains) >= CROSS_SYSTEM_DOMAIN_THRESHOLD
    ):
        return "high"
    if paths and all(_is_documentation_path(path) for path in paths):
        return "low"
    return "standard"


def canonical_contract_sha256(contract: dict[str, object]) -> str:
    payload = json.dumps(
        contract,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _mask_non_newlines(characters: list[str], start: int, end: int) -> None:
    for index in range(start, end):
        if characters[index] not in "\r\n":
            characters[index] = " "


def _fence_opening(line: str) -> tuple[str, int] | None:
    match = re.fullmatch(r" {0,3}(?P<fence>`{3,}|~{3,})(?P<info>[^\r\n]*)", line)
    if match is None:
        return None
    fence = match.group("fence")
    if fence[0] == "`" and "`" in match.group("info"):
        return None
    return fence[0], len(fence)


def _fence_closing(line: str, fence: tuple[str, int]) -> bool:
    character, minimum_length = fence
    return bool(
        re.fullmatch(
            rf" {{0,3}}{re.escape(character)}{{{minimum_length},}}[ \t]*",
            line,
        )
    )


def _leading_indentation_columns(line: str) -> int:
    columns = 0
    for character in line:
        if character == " ":
            columns += 1
        elif character == "\t":
            columns += 4 - (columns % 4)
        else:
            break
    return columns


def _mask_markdown_code(text: str) -> str:
    """Mask Markdown code while preserving byte offsets and HTML comments."""
    characters = list(text)
    fence: tuple[str, int] | None = None
    in_html_comment = False
    offset = 0

    for raw_line in text.splitlines(keepends=True):
        line = raw_line.rstrip("\r\n")
        structural_line = line
        content_end = offset + len(line)

        if fence is not None:
            _mask_non_newlines(characters, offset, offset + len(raw_line))
            if _fence_closing(structural_line, fence):
                fence = None
            offset += len(raw_line)
            continue

        if not in_html_comment:
            opening = _fence_opening(structural_line)
            if opening is not None:
                fence = opening
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                offset += len(raw_line)
                continue
            if _leading_indentation_columns(structural_line) >= 4:
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                offset += len(raw_line)
                continue

        index = offset
        while index < content_end:
            if in_html_comment:
                closing = text.find("-->", index, content_end)
                if closing < 0:
                    index = content_end
                else:
                    in_html_comment = False
                    index = closing + 3
                continue

            if text.startswith("<!--", index):
                in_html_comment = True
                index += 4
                continue
            if text[index] == "`":
                run_end = index + 1
                while run_end < content_end and text[run_end] == "`":
                    run_end += 1
                index = run_end
                continue
            index += 1
        offset += len(raw_line)

    # Resolve inline code in linear time. Outside code, HTML comments suppress
    # backtick parsing and odd-backslash runs are escaped. Once a real opener
    # exists, the next same-length run closes it even if comment-shaped text or
    # backslashes occur between the delimiters.
    structure = "".join(characters)
    characters = list(structure)
    runs: list[tuple[int, int, int]] = []
    position = 0
    while position < len(structure):
        opening = structure.find("`", position)
        if opening < 0:
            break
        run_end = opening + 1
        while run_end < len(structure) and structure[run_end] == "`":
            run_end += 1
        runs.append((opening, run_end, run_end - opening))
        position = run_end

    next_same: list[int | None] = [None] * len(runs)
    next_by_length: dict[int, int] = {}
    for index in range(len(runs) - 1, -1, -1):
        run_length = runs[index][2]
        next_same[index] = next_by_length.get(run_length)
        next_by_length[run_length] = index

    position = 0
    run_index = 0
    while run_index < len(runs):
        opening, run_end, _run_length = runs[run_index]
        if opening < position:
            run_index += 1
            continue

        comment_start = structure.find("<!--", position, opening)
        if comment_start >= 0:
            comment_end = structure.find("-->", comment_start + 4)
            position = len(structure) if comment_end < 0 else comment_end + 3
            continue

        backslashes = 0
        escape_cursor = opening - 1
        while escape_cursor >= 0 and structure[escape_cursor] == "\\":
            backslashes += 1
            escape_cursor -= 1
        if backslashes % 2:
            position = run_end
            run_index += 1
            continue

        closing_index = next_same[run_index]
        if closing_index is None:
            position = run_end
            run_index += 1
            continue
        _closing_start, closing_end, _closing_length = runs[closing_index]
        _mask_non_newlines(characters, opening, closing_end)
        position = closing_end
        run_index = closing_index + 1
    return "".join(characters)


def _html_comment_spans_outside_code(text: str) -> list[tuple[int, int]]:
    code_masked = _mask_markdown_code(text)
    spans: list[tuple[int, int]] = []
    offset = 0
    while True:
        start = code_masked.find("<!--", offset)
        if start < 0:
            break
        closing = code_masked.find("-->", start + 4)
        end = len(code_masked) if closing < 0 else closing + 3
        spans.append((start, end))
        if closing < 0:
            break
        offset = end
    return spans


def _mask_html_comments_outside_code(text: str) -> str:
    characters = list(text)
    for start, end in _html_comment_spans_outside_code(text):
        _mask_non_newlines(characters, start, end)
    return "".join(characters)


def _reviewable_markdown_structure(text: str) -> str:
    return _mask_markdown_code(_mask_html_comments_outside_code(text))


def _contains_forbidden_html(text: str) -> bool:
    comments_masked = _mask_html_comments_outside_code(text)
    structure = _mask_markdown_code(comments_masked)
    return bool(
        RAW_HTML_BLOCK_PATTERN.search(structure)
        or INLINE_HTML_TAG_PATTERN.search(structure)
        or NON_RENDERING_HTML_PATTERN.search(structure)
        or HTML_SHAPED_TAG_PATTERN.search(structure)
        or HTML_SHAPED_DECLARATION_PATTERN.search(structure)
    )


def _is_top_level_position(text: str, position: int) -> bool:
    line_start = text.rfind("\n", 0, position) + 1
    return position == line_start


def _html_comments_outside_code(text: str) -> list[re.Match[str]]:
    code_masked = _mask_markdown_code(text)
    return [
        match
        for match in HTML_COMMENT_PATTERN.finditer(code_masked)
        if _is_top_level_position(text, match.start())
    ]


def _top_level_marker_open_count(text: str, marker: str) -> int:
    code_masked = _mask_markdown_code(text)
    return sum(
        _is_top_level_position(text, match.start())
        for match in MARKER_OPEN_PATTERNS[marker].finditer(code_masked)
    )


def _body_without_machine_contract(body: str) -> str:
    contract_comments = [
        match
        for match in _html_comments_outside_code(body)
        if re.match(
            r"^pr-contract:v1\b",
            match.group("content").strip(),
            re.IGNORECASE,
        )
    ]
    if len(contract_comments) != 1:
        # Contract parsing reports missing, malformed, or duplicate markers.
        # Preserve the entire body here so ambiguous input cannot be excluded
        # from the acceptance digest.
        return body
    contract_comment = contract_comments[0]
    return body[: contract_comment.start()] + body[contract_comment.end() :]


def _normalize_acceptance_body(body: str) -> str:
    normalized = _body_without_machine_contract(body).replace("\r\n", "\n").replace(
        "\r", "\n"
    )
    lines = [line.rstrip() for line in normalized.split("\n")]
    while lines and not lines[0]:
        lines.pop(0)
    while lines and not lines[-1]:
        lines.pop()
    return "\n".join(lines)


def canonical_acceptance_sha256(body: str) -> str:
    # Exclude only the unique machine contract to avoid digest recursion. Hash
    # every other body byte, including comment-shaped text rendered inside
    # Markdown code, so no visible scope can bypass review invalidation.
    payload = _normalize_acceptance_body(body).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _section_content(body: str, structure: str, section: str) -> str | None:
    pattern = re.compile(
        rf"^##[ \t]+{re.escape(section)}[ \t]*\r?(?:\n|\Z)"
        rf"(?P<content>.*?)(?=^##[ \t]+|\Z)",
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(structure)
    if match is None:
        return None
    start, end = match.span("content")
    content = body[start:end]
    content = re.sub(r"\A(?:[ \t]*(?:\r\n|\r|\n))+", "", content)
    content = re.sub(r"(?:(?:\r\n|\r|\n)[ \t]*)+\Z", "", content)
    return content


def _section_heading_count(structure: str, section: str) -> int:
    pattern = re.compile(
        rf"^##[ \t]+{re.escape(section)}[ \t]*\r?$",
        re.IGNORECASE | re.MULTILINE,
    )
    return len(pattern.findall(structure))


def _marker_payloads(
    text: str,
    marker: str,
    location: str,
    errors: list[str],
) -> list[str]:
    if _contains_forbidden_html(text):
        errors.append(
            f"{location}: forbidden HTML-shaped source cannot contain or accompany "
            "machine evidence"
        )
        return []
    open_count = _top_level_marker_open_count(text, marker)
    payloads: list[str] = []
    marker_pattern = re.compile(rf"^{re.escape(marker)}(?:\s+)(?P<payload>.+)$", re.DOTALL)
    for html_comment in _html_comments_outside_code(text):
        start, end = html_comment.span("content")
        content = text[start:end].strip()
        if not re.match(rf"^{re.escape(marker)}\b", content, re.IGNORECASE):
            continue
        match = marker_pattern.fullmatch(content)
        if not match:
            errors.append(f"{location}: malformed {marker} marker")
            continue
        payloads.append(match.group("payload").strip())
    if open_count > len(payloads):
        errors.append(f"{location}: malformed or unclosed {marker} marker")
    return payloads


def _parse_json_object(payload: str, label: str, errors: list[str]) -> dict[str, object] | None:
    try:
        value = _loads_strict(payload)
    except (json.JSONDecodeError, DuplicateKeyError) as error:
        errors.append(f"{label}: invalid canonical JSON: {error}")
        return None
    if not isinstance(value, dict):
        errors.append(f"{label}: JSON root must be an object")
        return None
    return value


def _parse_contract(body: str, errors: list[str]) -> dict[str, object] | None:
    payloads = _marker_payloads(body, "pr-contract:v1", "contract", errors)
    if not payloads:
        errors.append("contract: missing <!-- pr-contract:v1 ... --> marker")
        return None
    if len(payloads) != 1:
        errors.append(f"contract: expected exactly one marker, found {len(payloads)}")
        return None
    if _top_level_marker_open_count(body, "agent-review:v1"):
        errors.append("review: agent-review:v1 attestations must be PR comments, not PR-body claims")
    return _parse_json_object(payloads[0], "contract", errors)


def _parse_attestations(comments: object, errors: list[str]) -> list[dict[str, object]]:
    if isinstance(comments, dict) and set(comments) == {"comments"}:
        comments = comments["comments"]
    if not isinstance(comments, list):
        errors.append("review: comments fixture must be an array")
        return []
    attestations: list[dict[str, object]] = []
    for index, comment in enumerate(comments):
        if not isinstance(comment, dict):
            errors.append(f"review: comments[{index}] must be an object")
            continue
        body = comment.get("body")
        if not isinstance(body, str):
            continue
        author = comment.get("user")
        login = author.get("login") if isinstance(author, dict) else None
        author_id = author.get("id") if isinstance(author, dict) else None
        trusted_login = (
            TRUSTED_REVIEW_COMMENT_IDENTITIES.get(author_id)
            if type(author_id) is int
            else None
        )
        if (
            not isinstance(login, str)
            or trusted_login is None
            or login.casefold() != trusted_login.casefold()
        ):
            # Untrusted comments must be unable to approve or denial-of-service
            # governance merely by copying a machine-readable marker.
            continue
        if not _top_level_marker_open_count(body, "agent-review:v1"):
            continue
        payloads = _marker_payloads(body, "agent-review:v1", f"review: comments[{index}]", errors)
        if len(payloads) > 1:
            errors.append(
                f"review: comments[{index}] contains {len(payloads)} agent-review:v1 markers; expected at most one"
            )
        for marker_index, payload in enumerate(payloads):
            value = _parse_json_object(
                payload,
                f"review: comments[{index}] marker[{marker_index}]",
                errors,
            )
            if value is not None:
                reserved = sorted(INTERNAL_ATTESTATION_FIELDS & set(value))
                if reserved:
                    errors.append(
                        f"review: comments[{index}] marker[{marker_index}]: "
                        f"reserved field(s): {', '.join(reserved)}"
                    )
                    continue
                updated_at = comment.get("updated_at")
                created_at = comment.get("created_at")
                value["__comment_updated_at"] = (
                    updated_at
                    if isinstance(updated_at, str)
                    else created_at
                    if isinstance(created_at, str)
                    else ""
                )
                value["__comment_id"] = (
                    comment.get("id") if type(comment.get("id")) is int else -1
                )
                value["__comment_order"] = index
                attestations.append(value)
    if not attestations:
        errors.append("review: no agent-review:v1 attestations found in PR comments")
    return attestations


def _check_exact_keys(
    value: dict[str, object],
    expected: set[str],
    label: str,
    errors: list[str],
) -> None:
    missing = sorted(expected - set(value))
    unknown = sorted(set(value) - expected)
    if missing:
        errors.append(f"{label}: missing field(s): {', '.join(missing)}")
    if unknown:
        errors.append(f"{label}: unknown field(s): {', '.join(unknown)}")


def _contains_placeholder(value: object) -> bool:
    if isinstance(value, str):
        return not value.strip() or bool(PLACEHOLDER_PATTERN.search(value))
    if isinstance(value, list):
        return any(_contains_placeholder(item) for item in value)
    if isinstance(value, dict):
        return any(_contains_placeholder(item) for item in value.values())
    return False


def _section_is_placeholder_only(value: str) -> bool:
    reviewable = _mask_markdown_code(value)
    if not SECTION_PLACEHOLDER_PATTERN.search(reviewable):
        return False
    remainder = SECTION_PLACEHOLDER_PATTERN.sub("", reviewable)
    return not re.sub(r"[\W_]+", "", remainder)


def _plain_prose_words(value: str) -> list[str]:
    """Return conservative, runtime-stable words eligible for prose gates.

    Governance does not need to reproduce every CommonMark or GitHub rendering
    extension. Only unindented top-level prose lines are eligible. Markup and
    container lines remain useful context, but cannot satisfy the gate.
    """
    if _contains_forbidden_html(value):
        return []

    comments_masked = _mask_html_comments_outside_code(value)
    fence: tuple[str, int] | None = None
    in_math_block = False
    bracket_depth = 0
    words: list[str] = []

    for raw_line in comments_masked.splitlines():
        line = raw_line.rstrip("\r")
        if fence is not None:
            if _fence_closing(line, fence):
                fence = None
            continue
        opening = _fence_opening(line)
        if opening is not None:
            fence = opening
            continue

        if line.strip() == "$$":
            in_math_block = not in_math_block
            continue
        if in_math_block or not line or line[0].isspace():
            continue

        opening_brackets = line.count("[")
        closing_brackets = line.count("]")
        if bracket_depth or opening_brackets or closing_brackets:
            bracket_depth = max(
                0,
                bracket_depth + opening_brackets - closing_brackets,
            )
            continue

        if (
            line.startswith((">", "#", "<"))
            or PLAIN_PROSE_LIST_PATTERN.match(line)
            or any(marker in line for marker in ("`", "$"))
        ):
            continue

        candidate = KEYCAP_SEQUENCE_PATTERN.sub(" ", line)
        candidate = MARKDOWN_ENTITY_PATTERN.sub(" ", candidate)
        candidate = GITHUB_EMOJI_ALIAS_PATTERN.sub(" ", candidate)
        candidate = URL_PATTERN.sub(" ", candidate)
        candidate = GITHUB_CONTEXT_REFERENCE_PATTERN.sub(" ", candidate)
        candidate = FULL_SHA_PATTERN.sub(" ", candidate)
        for chunk in candidate.split():
            token = chunk.strip(PLAIN_PROSE_TOKEN_TRIM)
            if PLAIN_PROSE_TOKEN_PATTERN.fullmatch(token):
                words.append(token)
    return words


def _visible_evidence_text(value: str) -> str:
    return " ".join(_plain_prose_words(value))


def _has_substantive_visible_text(
    value: str,
    *,
    minimum_alphanumeric: int = MINIMUM_SECTION_ALPHANUMERIC_CHARACTERS,
    minimum_words: int = MINIMUM_SECTION_WORDS,
) -> bool:
    words = _plain_prose_words(value)
    return (
        len(words) >= minimum_words
        and sum(character.isalnum() for word in words for character in word)
        >= minimum_alphanumeric
    )


def _valid_review_evidence_item(value: object) -> bool:
    if not isinstance(value, str):
        return False
    if _contains_forbidden_html(value) or _section_is_placeholder_only(value):
        return False
    visible = _visible_evidence_text(value)
    return (
        len(visible.split()) >= MINIMUM_EVIDENCE_WORDS
        and sum(character.isalnum() for character in visible)
        >= MINIMUM_EVIDENCE_ALPHANUMERIC_CHARACTERS
    )


def _valid_sha(value: object) -> bool:
    return isinstance(value, str) and bool(SHA_PATTERN.fullmatch(value))


def _valid_agent_id(value: object) -> bool:
    return (
        isinstance(value, str)
        and bool(AGENT_ID_PATTERN.fullmatch(value))
        and bool(re.search(r"[A-Za-z0-9]", value))
        and not _contains_placeholder(value)
    )


def _main_source_allowed(head_branch: str) -> bool:
    return (
        head_branch == "dev"
        or bool(re.fullmatch(r"release/[1-9][0-9]*-v[0-9]+\.[0-9]+\.[0-9]+", head_branch))
        or bool(
            re.fullmatch(
                r"hotfix/[1-9][0-9]*-[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?",
                head_branch,
            )
        )
    )


def _parse_lifecycle_fields(value: str) -> dict[str, list[str]]:
    """Return visible lifecycle field values without allowing cross-line borrowing.

    The input is already canonical reviewable prose, so hidden Markdown has been
    replaced with whitespace. Each field is therefore parsed from one physical
    line and ends at the next recognized lifecycle label on that line.
    """
    fields: dict[str, list[str]] = {}
    for line in value.splitlines():
        matches = list(LIFECYCLE_FIELD_PATTERN.finditer(line))
        for index, match in enumerate(matches):
            end = matches[index + 1].start() if index + 1 < len(matches) else len(line)
            field_value = line[match.end() : end].strip()
            values = fields.setdefault(match.group("label").lower(), [])
            if field_value:
                values.append(field_value)
    return fields


def _field_values(fields: dict[str, list[str]], label: str) -> list[str]:
    return fields.get(label.lower(), [])


def _has_exact_sha_field(fields: dict[str, list[str]], label: str) -> str | None:
    for value in _field_values(fields, label):
        match = EXACT_SHA_VALUE_PATTERN.search(value)
        if match is not None:
            return match.group(0)
    return None


def _operative_lifecycle_prose(value: str) -> str:
    """Mask quoted/code-style examples while preserving operative prose offsets."""
    characters = list(value)
    offset = 0
    for raw_line in value.splitlines(keepends=True):
        line = raw_line.rstrip("\r\n")
        if re.match(r"^[ \t]{0,3}>", line):
            _mask_non_newlines(characters, offset, offset + len(raw_line))
        offset += len(raw_line)
    quoted = "".join(characters)
    for match in LIFECYCLE_QUOTATION_PATTERN.finditer(quoted):
        for index in range(match.start(), match.end()):
            if characters[index] not in "\r\n.!?;":
                characters[index] = " "
    return (
        "".join(characters)
        .replace("\u2019", "'")
        .replace("\u2018", "'")
        .replace("\u2010", "-")
        .replace("\u2011", "-")
    )


def _current_candidate_reference_pattern(
    context: dict[str, object],
) -> re.Pattern[str]:
    pr_number = context.get("pr_number")
    head_ref = context.get("head_ref")
    alternatives = [
        (
            r"\b(?:this|these|current|the\s+current)\s+"
            r"(?:(?:source|temporary|tracking|candidate|validation|feature)\s+){0,3}"
            r"(?:candidate(?:s)?|branch(?:es)?|changes?|"
            r"pull[\s-]+request(?:s)?|prs?)\b"
        ),
        (
            r"\bthe\s+"
            r"(?!(?:historical|legacy|previous|prior|other|unrelated)\b)"
            r"(?:(?:source|temporary|tracking|candidate|validation|feature)\s+){0,3}"
            r"(?:candidate(?:s)?|branch(?:es)?|changes?|"
            r"pull[\s-]+request(?:s)?|prs?)\b"
        ),
    ]
    if type(pr_number) is int:
        alternatives.append(
            rf"\b(?:pull[\s-]+request|pr)\s*#\s*{pr_number}\b"
        )
    if isinstance(head_ref, str) and head_ref:
        alternatives.append(
            rf"(?<![A-Za-z0-9_.-]){re.escape(head_ref)}(?![A-Za-z0-9_.-])"
        )
    return re.compile("(?:" + "|".join(alternatives) + ")", re.IGNORECASE)


def _paragraph_start(value: str, position: int) -> int:
    blank_line = max(
        value.rfind("\n\n", 0, position),
        value.rfind("\r\n\r\n", 0, position),
    )
    heading = value.rfind("\n## ", 0, position)
    blank_start = blank_line + 2 if blank_line >= 0 else 0
    heading_start = heading + 1 if heading >= 0 else 0
    return max(0, position - 360, blank_start, heading_start)


def _local_clause_bounds(value: str, position: int) -> tuple[int, int]:
    start = _paragraph_start(value, position)
    end = len(value)
    for pattern in (
        re.compile(r"[.!?;\n]"),
        LIFECYCLE_COORDINATION_BOUNDARY_PATTERN,
    ):
        for match in pattern.finditer(value, start):
            if match.end() <= position:
                start = max(start, match.end())
            elif match.start() >= position:
                end = min(end, match.start())
                break
    return start, end


def _is_descriptive_occurrence(value: str, position: int) -> bool:
    start, _end = _local_clause_bounds(value, position)
    prefix = value[start:position]
    return bool(
        LIFECYCLE_DESCRIPTIVE_FRAME_PATTERN.search(prefix)
        or re.search(
            r"\b(?:example|test[\s-]+case|sentence|phrase|wording)\s*:\s*$",
            prefix,
            re.IGNORECASE,
        )
    )


def _reference_identity_before(
    value: str,
    position: int,
    current_pattern: re.Pattern[str],
) -> tuple[str | None, int, int]:
    start = _paragraph_start(value, position)
    references: list[tuple[int, int, str]] = [
        (match.start(), match.end(), "current")
        for match in current_pattern.finditer(value, start, position)
    ]
    current_spans = {(item[0], item[1]) for item in references}
    for match in OTHER_CANDIDATE_REFERENCE_PATTERN.finditer(value, start, position):
        if (match.start(), match.end()) not in current_spans:
            references.append((match.start(), match.end(), "other"))
    if not references:
        return None, -1, -1
    reference_start, reference_end, identity = max(
        references, key=lambda item: (item[1], item[0], item[2] == "current")
    )
    return identity, reference_start, reference_end


def _current_subject_before(
    value: str,
    position: int,
    current_pattern: re.Pattern[str],
) -> bool:
    clause_start, _clause_end = _local_clause_bounds(value, position)
    pronoun_pattern = re.compile(r"\b(?:it|they)\b", re.IGNORECASE)
    pronouns = list(pronoun_pattern.finditer(value, clause_start, position))
    if pronouns:
        pronoun = pronouns[-1]
        identity, _start, _end = _reference_identity_before(
            value, pronoun.start(), current_pattern
        )
        if identity == "current":
            return True
    identity, _start, end = _reference_identity_before(value, position, current_pattern)
    return identity == "current" and end >= clause_start


def _current_object_after(
    value: str,
    start: int,
    current_pattern: re.Pattern[str],
) -> bool:
    _clause_start, clause_end = _local_clause_bounds(value, start)
    current = current_pattern.search(value, start, clause_end)
    other = OTHER_CANDIDATE_REFERENCE_PATTERN.search(value, start, clause_end)
    if current is not None and (other is None or current.start() <= other.start()):
        return True
    pronoun = re.match(r"\s+(?:it|them|they)\b", value[start:clause_end], re.IGNORECASE)
    if pronoun is not None:
        identity, _reference_start, _reference_end = _reference_identity_before(
            value, start, current_pattern
        )
        return identity == "current"
    return False


def _lifecycle_actions(
    value: str,
    current_pattern: re.Pattern[str],
) -> list[tuple[int, int, bool]]:
    actions: list[tuple[int, int, bool]] = []
    for verb in LIFECYCLE_HOUSEKEEPING_VERB_PATTERN.finditer(value):
        _clause_start, clause_end = _local_clause_bounds(value, verb.start())
        comma = value.find(",", verb.end(), clause_end)
        object_end = comma if comma >= 0 else clause_end
        object_match = LIFECYCLE_ACTION_OBJECT_PATTERN.search(
            value, verb.end(), object_end
        )
        pronoun = re.match(
            r"\s+(?:it|them)\b", value[verb.end() : object_end], re.IGNORECASE
        )
        if object_match is None and pronoun is None:
            continue
        end = object_match.end() if object_match is not None else verb.end() + pronoun.end()
        phrase = value[verb.start() : end]
        current = current_pattern.search(phrase) is not None
        if pronoun is not None:
            identity, _reference_start, _reference_end = _reference_identity_before(
                value, verb.start(), current_pattern
            )
            current = identity == "current"
        actions.append((verb.start(), end, current))
    return actions


def _qualifier_matches_current(
    qualifier: re.Match[str],
    context: dict[str, object],
) -> bool:
    numbered = re.search(
        r"\b(?:pull[\s-]+request|pr)\s*#\s*([1-9][0-9]*)",
        qualifier.group(0),
        re.IGNORECASE,
    )
    return numbered is None or str(context.get("pr_number")) == numbered.group(1)


def _post_merge_qualifies_action(
    value: str,
    action: tuple[int, int, bool],
    actions: list[tuple[int, int, bool]],
    current_pattern: re.Pattern[str],
    context: dict[str, object],
) -> bool:
    action_start, action_end, _current = action
    qualifiers = [
        match
        for match in POST_MERGE_QUALIFIER_PATTERN.finditer(value)
        if _qualifier_matches_current(match, context)
    ]
    for qualifier in qualifiers:
        if qualifier.end() <= action_start:
            between = value[qualifier.end() : action_start]
            if not re.fullmatch(r"\s*,?\s*", between):
                continue
        elif action_end <= qualifier.start():
            between = value[action_end : qualifier.start()]
            if (
                re.search(r"[,;:.!?\n]", between)
                or LIFECYCLE_COORDINATION_BOUNDARY_PATTERN.search(between)
                or current_pattern.search(between)
                or OTHER_CANDIDATE_REFERENCE_PATTERN.search(between)
            ):
                continue
        else:
            continue
        low = min(action_end, qualifier.end())
        high = max(action_start, qualifier.start())
        if any(
            other_start >= low
            and other_end <= high
            and (other_start, other_end) != (action_start, action_end)
            for other_start, other_end, _other_current in actions
        ):
            continue
        return True
    return False


def _has_replacement_comparison(
    value: str,
    current_pattern: re.Pattern[str],
    *,
    allow_implicit_candidate: bool,
) -> bool:
    for comparison in LIFECYCLE_REPLACEMENT_COMPARISON_PATTERN.finditer(value):
        if _is_descriptive_occurrence(value, comparison.start()):
            continue
        clause_start, clause_end = _local_clause_bounds(value, comparison.start())
        clause = value[clause_start:clause_end]
        if LIFECYCLE_HOUSEKEEPING_VERB_PATTERN.search(clause) is None:
            continue
        if allow_implicit_candidate or current_pattern.search(clause) is not None:
            return True
        pronoun = re.search(r"\b(?:it|them|they)\b", clause, re.IGNORECASE)
        if pronoun is not None:
            identity, _reference_start, _reference_end = _reference_identity_before(
                value, clause_start + pronoun.start(), current_pattern
            )
            if identity == "current":
                return True
    return False


def _has_candidate_non_merge_contradiction(
    value: str,
    context: dict[str, object],
    *,
    allow_implicit_replacement: bool = False,
) -> bool:
    """Detect operative non-merge claims about the exact current PR candidate."""
    operative = _operative_lifecycle_prose(value)
    current_pattern = _current_candidate_reference_pattern(context)

    for predicate in LIFECYCLE_NON_MERGE_PREDICATE_PATTERN.finditer(operative):
        if _is_descriptive_occurrence(operative, predicate.start()):
            continue
        _clause_start, clause_end = _local_clause_bounds(operative, predicate.start())
        tail = operative[predicate.end() : clause_end]
        if re.match(r"\s+(?:until|unless|before)\b", tail, re.IGNORECASE):
            continue
        if predicate.group(0).lower().rstrip().endswith(("merge", "merging")):
            if LIFECYCLE_OTHER_MERGE_OBJECT_PATTERN.match(tail):
                continue
        if _current_subject_before(operative, predicate.start(), current_pattern):
            return True

    for imperative in LIFECYCLE_NON_MERGE_IMPERATIVE_PATTERN.finditer(operative):
        if _is_descriptive_occurrence(operative, imperative.start()):
            continue
        if _current_object_after(operative, imperative.end(), current_pattern):
            return True

    gerund_pattern = re.compile(
        rf"\bmerging\s+{current_pattern.pattern}\s+"
        r"(?:is|remains)\s+(?:forbidden|prohibited|disallowed|not\s+allowed)\b",
        re.IGNORECASE,
    )
    for gerund in gerund_pattern.finditer(operative):
        if not _is_descriptive_occurrence(operative, gerund.start()):
            return True

    if _has_replacement_comparison(
        operative,
        current_pattern,
        allow_implicit_candidate=allow_implicit_replacement,
    ):
        return True

    actions = _lifecycle_actions(operative, current_pattern)
    for action in actions:
        if not action[2] or _is_descriptive_occurrence(operative, action[0]):
            continue
        if not _post_merge_qualifies_action(
            operative, action, actions, current_pattern, context
        ):
            return True
    return False


def _has_non_merge_final_disposition(
    value: str,
    context: dict[str, object],
) -> bool:
    """Detect a non-merge outcome with one-to-one post-merge action scoping."""
    fields = _parse_lifecycle_fields(value)
    dispositions = (
        _field_values(fields, "Final disposition")
        + _field_values(fields, "Close or deletion conditions")
    )
    return any(
        _has_candidate_non_merge_contradiction(
            disposition,
            context,
            allow_implicit_replacement=True,
        )
        for disposition in dispositions
    )


def _validate_lifecycle(
    reviewable_prose: str,
    context: dict[str, object],
    errors: list[str],
) -> None:
    """Validate local branch/issue metadata without relying on live GitHub state."""
    primary = _section_content(reviewable_prose, reviewable_prose, "Primary issue") or ""
    primary_issues = PRIMARY_ISSUE_PATTERN.findall(primary)
    if not primary_issues:
        errors.append("lifecycle: name one primary issue as #<number> in '## Primary issue'")
        return
    if len(primary_issues) != 1:
        errors.append("lifecycle: '## Primary issue' must name exactly one #<number>")
        return
    primary_issue = primary_issues[0]

    merge_intention = (
        _section_content(reviewable_prose, reviewable_prose, "Merge intention") or ""
    )
    merge_words = merge_intention.lower()
    is_non_merge = "not intended to merge" in merge_words
    is_merge = "is intended to merge" in merge_words
    if is_non_merge == is_merge:
        errors.append(
            "lifecycle: state whether this branch is intended to merge or not intended to merge"
        )

    non_merge = (
        _section_content(reviewable_prose, reviewable_prose, "Non-merge record") or ""
    )
    final_disposition = (
        _section_content(
            reviewable_prose, reviewable_prose, "Rollback or final disposition"
        )
        or ""
    )
    non_merge_fields = _parse_lifecycle_fields(non_merge)
    if is_merge and (
        _field_values(non_merge_fields, "Purpose")
        or _field_values(non_merge_fields, "Exact candidate or workflow SHA")
        or _field_values(non_merge_fields, "Retained evidence")
        or _field_values(non_merge_fields, "Final disposition")
        or _field_values(non_merge_fields, "Close or deletion conditions")
    ):
        errors.append("lifecycle: merge-intended branch must not declare a non-merge record")
    if is_merge and _has_non_merge_final_disposition(final_disposition, context):
        errors.append(
            "lifecycle: merge-intended branch must not declare a non-merge final disposition"
        )
    if is_merge and _has_candidate_non_merge_contradiction(reviewable_prose, context):
        errors.append(
            "lifecycle: merge-intended branch must not make a candidate-specific non-merge contradiction"
        )
    if is_non_merge and CLOSES_ISSUE_PATTERN.search(reviewable_prose) is not None:
        errors.append("lifecycle: non-merge branch must not use 'Closes #<issue>'")

    exception = (
        _section_content(reviewable_prose, reviewable_prose, "Lifecycle exception") or ""
    )
    legacy_fields = _parse_lifecycle_fields(exception)
    legacy_declared = "legacy registration" in legacy_fields
    if legacy_declared:
        if primary_issue != "47":
            errors.append("lifecycle: only primary issue #47 may declare a legacy registration")
        registrations = _field_values(legacy_fields, "Legacy registration")
        candidate = _has_exact_sha_field(legacy_fields, "Immutable candidate SHA")
        if len(registrations) != 1 or LEGACY_REGISTRATION_VALUE_PATTERN.fullmatch(
            registrations[0].strip()
        ) is None:
            errors.append("lifecycle: legacy exception must declare 'Legacy registration: #47'")
        if candidate is None:
            errors.append("lifecycle: legacy exception must declare its immutable candidate SHA")
        elif candidate != context["head_sha"]:
            errors.append("lifecycle: legacy immutable candidate SHA must equal the PR head SHA")
        if not _field_values(legacy_fields, "Reason"):
            errors.append("lifecycle: legacy exception must state a reason")
        if not _field_values(legacy_fields, "Original branch identity"):
            errors.append("lifecycle: legacy exception must state the original branch identity")
        if not any(
            re.fullmatch(r"(?:#[1-9][0-9]*|unknown)\.?", value)
            for value in _field_values(legacy_fields, "Original primary issue")
        ):
            errors.append("lifecycle: legacy exception must state the original primary issue or unknown")
        if not _field_values(legacy_fields, "Retained evidence"):
            errors.append("lifecycle: legacy exception must state retained evidence")
        if not _field_values(legacy_fields, "Intended disposition"):
            errors.append("lifecycle: legacy exception must state intended disposition")
        return

    head_ref = context.get("head_ref")
    if head_ref in {"dev", "main"}:
        return
    if not isinstance(head_ref, str):
        return
    branch_issue = BRANCH_ISSUE_PATTERN.search(head_ref)
    if branch_issue is None:
        errors.append(
            "lifecycle: source branch must include its primary issue number; use codex/<issue>-<slug>"
        )
    elif branch_issue.group(1) != primary_issue:
        errors.append("lifecycle: source branch issue number must match '## Primary issue'")
    if head_ref.startswith(("archival/", "archive/")) and not is_non_merge:
        errors.append(
            "lifecycle: archival branch must state it is not intended to merge"
        )
    if is_non_merge:
        if not _field_values(non_merge_fields, "Purpose"):
            errors.append("lifecycle: non-merge branch must state its purpose")
        candidate = _has_exact_sha_field(non_merge_fields, "Exact candidate or workflow SHA")
        if candidate is None:
            errors.append("lifecycle: non-merge branch must state its exact candidate or workflow SHA")
        if not _field_values(non_merge_fields, "Retained evidence"):
            errors.append("lifecycle: non-merge branch must state retained evidence")
        if not (
            _field_values(non_merge_fields, "Final disposition")
            or _field_values(non_merge_fields, "Close or deletion conditions")
        ):
            errors.append("lifecycle: non-merge branch must state final disposition or close/deletion conditions")


def _event_context(event: object, errors: list[str]) -> dict[str, object] | None:
    if not isinstance(event, dict) or not isinstance(event.get("pull_request"), dict):
        errors.append("event: pull_request object is missing")
        return None
    pull_request = event["pull_request"]
    base = pull_request.get("base")
    head = pull_request.get("head")
    repository = event.get("repository")
    if not isinstance(base, dict) or not isinstance(head, dict):
        errors.append("event: pull_request base/head objects are missing")
        return None
    if not isinstance(repository, dict):
        errors.append("event: repository object is missing")
        return None
    context = {
        "body": pull_request.get("body"),
        "repository": repository.get("full_name"),
        "pr_number": event.get("number"),
        "base_ref": base.get("ref"),
        "base_sha": base.get("sha"),
        "base_repository": base.get("repo", {}).get("full_name")
        if isinstance(base.get("repo"), dict)
        else None,
        "head_ref": head.get("ref"),
        "head_sha": head.get("sha"),
        "head_repository": head.get("repo", {}).get("full_name")
        if isinstance(head.get("repo"), dict)
        else None,
    }
    if not isinstance(context["body"], str):
        context["body"] = ""
    if not isinstance(context["repository"], str) or not REPOSITORY_PATTERN.fullmatch(
        context["repository"]
    ):
        errors.append("event: repository.full_name must be owner/repository")
    if type(context["pr_number"]) is not int or context["pr_number"] <= 0:
        errors.append("event: PR number must be a positive integer")
    for field in ("base_ref", "head_ref"):
        if not isinstance(context[field], str) or not context[field]:
            errors.append(f"event: {field} must be a nonempty string")
    for field in ("base_sha", "head_sha"):
        if not _valid_sha(context[field]):
            errors.append(f"event: {field} must be a full lowercase SHA-1")
    if context["base_repository"] != context["repository"]:
        errors.append("event: base repository does not match repository.full_name")
    return context


def _validate_contract(
    contract: dict[str, object],
    context: dict[str, object],
    changed_paths: Sequence[str],
    actual_candidate_tree: str | None,
    actual_base_is_ancestor: bool | None,
    errors: list[str],
) -> str:
    base_ref = context["base_ref"]
    expected_fields = MAIN_CONTRACT_FIELDS if base_ref == "main" else CONTRACT_FIELDS
    _check_exact_keys(contract, expected_fields, "contract", errors)
    if contract.get("version") != 1 or type(contract.get("version")) is not int:
        errors.append("contract: version must be integer 1")
    for field in ("repository", "head_sha", "base_sha", "base_ref", "head_ref"):
        if contract.get(field) != context[field]:
            errors.append(f"contract: {field} does not match the current PR event")
    if contract.get("pr_number") != context["pr_number"] or type(contract.get("pr_number")) is not int:
        errors.append("contract: pr_number does not match the current PR event")
    if not _valid_agent_id(contract.get("implementation_agent")):
        errors.append("contract: implementation_agent must be a non-placeholder agent ID")
    acceptance_sha256 = contract.get("acceptance_sha256")
    if not isinstance(acceptance_sha256, str) or not SHA256_PATTERN.fullmatch(
        acceptance_sha256
    ):
        errors.append("contract: acceptance_sha256 must be a full lowercase SHA-256")
    elif acceptance_sha256 != canonical_acceptance_sha256(str(context["body"])):
        errors.append("contract: acceptance_sha256 does not match the canonical PR body")
    if _contains_placeholder(contract):
        errors.append("contract: placeholder or empty string detected")

    computed_risk = minimum_risk(str(base_ref), changed_paths)
    risk = contract.get("risk")
    if not isinstance(risk, str) or risk not in RISK_ORDER:
        errors.append(f"contract: risk must be one of {sorted(RISK_ORDER)}")
        risk = computed_risk
    elif base_ref == "main" and risk != "main-promotion":
        errors.append("contract: every PR targeting main must declare main-promotion risk")
    elif base_ref != "main" and risk == "main-promotion":
        errors.append("contract: main-promotion risk is reserved for PRs targeting main")
    elif RISK_ORDER[risk] < RISK_ORDER[computed_risk]:
        errors.append(f"contract: declared risk {risk!r} is lower than computed risk {computed_risk!r}")

    controls = contract.get("controls")
    if not isinstance(controls, dict):
        errors.append("contract: controls must be an object")
    else:
        _check_exact_keys(controls, CONTROL_FIELDS, "contract: controls", errors)
        if controls.get("target_branch") != base_ref:
            errors.append("contract: controls.target_branch must equal base_ref")
        for name, allowed in CONTROL_VALUES.items():
            control_value = controls.get(name)
            if not isinstance(control_value, str) or control_value not in allowed:
                errors.append(f"contract: controls.{name} must be one of {sorted(allowed)}")

    if actual_base_is_ancestor is None:
        errors.append("branch: current base ancestry was not independently resolved")
    elif not actual_base_is_ancestor:
        errors.append(
            f"branch: PR head must contain the exact current {base_ref} base"
        )

    if base_ref == "main":
        head_ref = context["head_ref"]
        if not isinstance(head_ref, str) or not _main_source_allowed(head_ref):
            errors.append("branch: PRs into main must come from dev, release/<issue>-vX.Y.Z, or hotfix/<issue>-<slug>")
        if context["head_repository"] != context["repository"]:
            errors.append("branch: main-promotion candidates must come from the same repository")
        if contract.get("candidate_sha") != context["head_sha"]:
            errors.append("contract: candidate_sha must equal the current PR head SHA")
        candidate_tree = contract.get("candidate_tree")
        if not _valid_sha(candidate_tree):
            errors.append("contract: candidate_tree must be a full lowercase SHA-1")
        if actual_candidate_tree is None:
            errors.append("contract: main-promotion candidate tree was not independently resolved")
        elif candidate_tree != actual_candidate_tree:
            errors.append("contract: candidate_tree does not match the current PR head tree")
    return str(risk)


def _validate_attestations(
    attestations: Sequence[dict[str, object]],
    contract: dict[str, object],
    context: dict[str, object],
    risk: str,
    errors: list[str],
) -> None:
    contract_hash = canonical_contract_sha256(contract)
    required_roles = REQUIRED_ROLES.get(
        risk,
        REQUIRED_ROLES[minimum_risk(str(context["base_ref"]), [])],
    )
    binding_fields = (
        "repository",
        "pr_number",
        "head_sha",
        "base_sha",
        "base_ref",
        "head_ref",
    )
    current_by_role: dict[str, dict[str, object]] = {}
    ambiguous_current_roles: set[str] = set()
    stale_required_by_role: dict[str, dict[str, object]] = {}
    current_unkeyed: list[dict[str, object]] = []
    implementation_agent = contract.get("implementation_agent")

    def recency(value: dict[str, object]) -> tuple[str, int, int]:
        updated_at = value.get("__comment_updated_at")
        comment_id = value.get("__comment_id")
        comment_order = value.get("__comment_order")
        return (
            updated_at if isinstance(updated_at, str) else "",
            comment_id if type(comment_id) is int else -1,
            comment_order if type(comment_order) is int else -1,
        )

    for attestation in attestations:
        binding_is_current = all(
            attestation.get(field) == context[field] for field in binding_fields
        ) and all(
            (
                attestation.get("contract_sha256") == contract_hash,
                attestation.get("implementation_agent") == implementation_agent,
                attestation.get("risk") == risk,
            )
        )
        role = attestation.get("role")
        if binding_is_current:
            if isinstance(role, str):
                # Edited comments retain their creation position in GitHub's
                # REST array. Live timestamps have only whole-second precision,
                # so distinct same-role comments tied at the latest timestamp
                # are ambiguous and fail closed below.
                existing = current_by_role.get(role)
                if existing is None:
                    current_by_role[role] = attestation
                else:
                    current_recency = recency(attestation)
                    existing_recency = recency(existing)
                    if current_recency[0] > existing_recency[0]:
                        current_by_role[role] = attestation
                        ambiguous_current_roles.discard(role)
                    elif current_recency[0] == existing_recency[0]:
                        current_id = current_recency[1]
                        existing_id = existing_recency[1]
                        distinct_comments = (
                            current_id != existing_id
                            if current_id >= 0 and existing_id >= 0
                            else current_recency[2] != existing_recency[2]
                        )
                        if current_recency[0] and distinct_comments:
                            ambiguous_current_roles.add(role)
                        if current_recency >= existing_recency:
                            current_by_role[role] = attestation
            else:
                current_unkeyed.append(attestation)
        elif isinstance(role, str) and role in required_roles:
            existing = stale_required_by_role.get(role)
            if existing is None or recency(attestation) >= recency(existing):
                stale_required_by_role[role] = attestation

    for role in sorted(ambiguous_current_roles):
        errors.append(
            "review: multiple current attestations for role "
            f"{role!r} share the latest whole-second updated_at; post or edit "
            "one attestation later"
        )

    selected_by_role = dict(current_by_role)
    for role in required_roles - set(selected_by_role):
        if role in stale_required_by_role:
            selected_by_role[role] = stale_required_by_role[role]
    attestations = [*current_unkeyed, *selected_by_role.values()]

    seen_roles: set[str] = set()
    seen_reviewers: set[str] = set()
    for index, attestation in enumerate(attestations):
        label = f"review: attestation[{index}]"
        role = attestation.get("role")
        _check_exact_keys(
            attestation,
            ATTESTATION_FIELDS | INTERNAL_ATTESTATION_FIELDS,
            label,
            errors,
        )
        if attestation.get("version") != 1 or type(attestation.get("version")) is not int:
            errors.append(f"{label}: version must be integer 1")
        for field in ("repository", "pr_number", "head_sha", "base_sha", "base_ref", "head_ref"):
            if attestation.get(field) != context[field]:
                errors.append(f"{label}: {field} does not match the current PR event")
        if type(attestation.get("pr_number")) is not int:
            errors.append(f"{label}: pr_number must be an integer")
        if attestation.get("contract_sha256") != contract_hash:
            errors.append(f"{label}: contract_sha256 does not match the canonical PR contract")
        if attestation.get("implementation_agent") != implementation_agent:
            errors.append(f"{label}: implementation_agent does not match the PR contract")
        if attestation.get("risk") != risk:
            errors.append(f"{label}: risk does not match the validated PR contract")
        # Evidence has its own rendered-prose validation below. Applying the
        # broad machine-field placeholder grammar to it would incorrectly
        # reject legitimate prose containing CommonMark autolinks or angle
        # comparisons such as ``x < y > z``.
        placeholder_fields = {
            key: value
            for key, value in attestation.items()
            if key != "evidence" and key not in INTERNAL_ATTESTATION_FIELDS
        }
        if _contains_placeholder(placeholder_fields):
            errors.append(f"{label}: placeholder or empty string detected")

        if not isinstance(role, str) or role not in set().union(*REQUIRED_ROLES.values()):
            errors.append(f"{label}: role is not a recognized review role")
        elif role in seen_roles:
            errors.append(f"{label}: role duplicates {role!r}")
        else:
            seen_roles.add(role)

        reviewer = attestation.get("reviewer_agent")
        normalized_reviewer = reviewer.casefold() if isinstance(reviewer, str) else None
        normalized_implementation = (
            implementation_agent.casefold() if isinstance(implementation_agent, str) else None
        )
        if not _valid_agent_id(reviewer):
            errors.append(f"{label}: reviewer_agent must be a non-placeholder agent ID")
        else:
            if normalized_reviewer == normalized_implementation:
                errors.append(f"{label}: reviewer_agent cannot be the implementation agent")
            if normalized_reviewer in seen_reviewers:
                errors.append(f"{label}: reviewer_agent duplicates {reviewer!r}")
            else:
                seen_reviewers.add(str(normalized_reviewer))

        if attestation.get("verdict") != "pass":
            errors.append(f"{label}: verdict must be 'pass'")
        blocking = attestation.get("blocking_findings")
        if not isinstance(blocking, list):
            errors.append(f"{label}: blocking_findings must be an array")
        elif blocking:
            errors.append(f"{label}: blocking_findings must be empty")
        evidence = attestation.get("evidence")
        if not isinstance(evidence, list) or not evidence:
            errors.append(f"{label}: evidence must be a nonempty array")
        elif any(not _valid_review_evidence_item(item) for item in evidence):
            errors.append(
                f"{label}: every evidence item must contain at least four plain "
                "ASCII words and 20 ASCII letters or digits, with no forbidden "
                "HTML-shaped source"
            )

    missing = sorted(required_roles - seen_roles)
    if missing:
        errors.append(f"review: missing required role(s) for {risk}: {', '.join(missing)}")


def validate_pull_request(
    event: object,
    changed_paths: Iterable[str],
    comments: object,
    *,
    actual_candidate_tree: str | None = None,
    actual_base_is_ancestor: bool | None = None,
) -> list[str]:
    """Return deterministic governance findings; an empty list means pass."""
    errors: list[str] = []
    context = _event_context(event, errors)
    if context is None:
        return errors
    body = str(context["body"])
    structure = _reviewable_markdown_structure(body)
    for section in REQUIRED_SECTIONS:
        heading_count = _section_heading_count(structure, section)
        if heading_count == 0:
            errors.append(f"body: missing required section '## {section}'")
            continue
        if heading_count != 1:
            errors.append(
                f"body: expected exactly one '## {section}' section, found {heading_count}"
            )
        content = _section_content(body, structure, section)
        if content is None:
            errors.append(f"body: section '## {section}' has no reviewable content")
            continue
        visible = _mask_html_comments_outside_code(content)
        if _section_is_placeholder_only(visible):
            errors.append(f"body: section '## {section}' contains placeholder text")
        elif _contains_forbidden_html(content):
            errors.append(
                f"body: section '## {section}' contains forbidden HTML-shaped source"
            )
        elif not visible.strip() or not _has_substantive_visible_text(visible):
            errors.append(f"body: section '## {section}' has no reviewable content")

    _validate_lifecycle(structure, context, errors)

    paths = list(changed_paths)
    valid_paths: list[str] = []
    if not paths:
        errors.append("diff: PR has no changed paths")
    for path in paths:
        if (
            not isinstance(path, str)
            or not path
            or path.startswith(("/", "./"))
            or "\\" in path
            or ".." in PurePosixPath(path).parts
        ):
            errors.append(f"diff: invalid repository-relative path {path!r}")
        else:
            valid_paths.append(path)

    contract = _parse_contract(body, errors)
    attestations = _parse_attestations(comments, errors)
    if contract is None:
        return errors
    risk = _validate_contract(
        contract,
        context,
        valid_paths,
        actual_candidate_tree,
        actual_base_is_ancestor,
        errors,
    )
    _validate_attestations(attestations, contract, context, risk, errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--event",
        default=os.environ.get("GITHUB_EVENT_PATH"),
        help="GitHub pull_request event JSON (defaults to GITHUB_EVENT_PATH)",
    )
    parser.add_argument(
        "--comments",
        default=os.environ.get("PR_REVIEW_COMMENTS_PATH")
        or os.environ.get("GITHUB_PR_COMMENTS_PATH"),
        help="GitHub issue-comments JSON (defaults to PR_REVIEW_COMMENTS_PATH)",
    )
    args = parser.parse_args()
    if not args.event:
        parser.error("--event or GITHUB_EVENT_PATH is required")
    if not args.comments:
        parser.error("--comments or PR_REVIEW_COMMENTS_PATH is required")

    try:
        event = _load_json_file(args.event)
        comments = _load_json_file(args.comments)
        if not isinstance(event, dict) or not isinstance(event.get("pull_request"), dict):
            raise KeyError("pull_request")
        pull_request = event["pull_request"]
        base = pull_request["base"]
        head = pull_request["head"]
        changed_paths = _changed_paths(base["sha"], head["sha"])
        checkout_sha = _commit_sha("HEAD")
        if checkout_sha != head["sha"]:
            raise RuntimeError(
                "checked-out validation commit does not match the current PR head"
            )
        is_main_promotion = base["ref"] == "main"
        candidate_tree = _tree_sha(checkout_sha) if is_main_promotion else None
        base_is_ancestor = _is_ancestor(base["sha"], checkout_sha)
        errors = validate_pull_request(
            event,
            changed_paths,
            comments,
            actual_candidate_tree=candidate_tree,
            actual_base_is_ancestor=base_is_ancestor,
        )
    except (KeyError, OSError, RuntimeError, UnicodeError, json.JSONDecodeError, DuplicateKeyError) as error:
        print(f"PR governance could not run: {error}", file=sys.stderr)
        return 2

    if errors:
        print(f"PR governance failed with {len(errors)} finding(s):", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    base_branch = event["pull_request"]["base"]["ref"]
    risk = minimum_risk(base_branch, changed_paths)
    print(
        f"PR governance passed: {len(changed_paths)} affected path(s); "
        f"minimum risk {risk}; contract and independent reviews match the current PR."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Validate a PR contract and independent review-agent attestations."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import string
import subprocess
import sys
import unicodedata
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
LIFECYCLE_FIELD_LABEL_PATTERN = re.compile(
    r"(?P<label>"
    r"Legacy registration|Immutable candidate SHA|Reason|Original branch identity|"
    r"Original primary issue|Retained evidence|Intended disposition|Purpose|"
    r"Exact candidate or workflow SHA|Final disposition|Close or deletion conditions"
    r"):"
)
LIFECYCLE_FIELD_PATTERN = re.compile(
    LIFECYCLE_FIELD_LABEL_PATTERN.pattern + r"[ \t]*(?P<value>.*?)[ \t]*"
)
COMMONMARK_BACKSLASH_ESCAPE_PATTERN = re.compile(
    r"""\\([!"#$%&'()*+,\-./:;<=>?@\[\]\\^_`{|}~])"""
)
NON_MERGE_FIELD_LABELS = frozenset(
    {
        "Purpose",
        "Exact candidate or workflow SHA",
        "Retained evidence",
        "Final disposition",
        "Close or deletion conditions",
    }
)
NON_MERGE_REQUIRED_FIELD_LABELS = frozenset(
    {
        "Purpose",
        "Exact candidate or workflow SHA",
        "Retained evidence",
    }
)
LEGACY_FIELD_LABELS = frozenset(
    {
        "Legacy registration",
        "Original branch identity",
        "Original primary issue",
        "Immutable candidate SHA",
        "Retained evidence",
        "Intended disposition",
        "Reason",
    }
)
FINAL_DISPOSITION_FIELD_LABELS = frozenset(
    {"Final disposition", "Close or deletion conditions"}
)
EXACT_SHA_VALUE_PATTERN = re.compile(
    r"(?<![0-9A-Fa-f])[0-9a-f]{40}(?![0-9A-Fa-f])"
)
LEGACY_REGISTRATION_VALUE_PATTERN = re.compile(r"#47[.!?]?")
CLOSES_ISSUE_PATTERN = re.compile(r"\bCloses\s+#[1-9][0-9]*\b", re.IGNORECASE)
MERGE_INTENTION_PATTERN = re.compile(r"\bis\s+intended\s+to\s+merge\b", re.IGNORECASE)
NON_MERGE_INTENTION_PATTERN = re.compile(
    r"\b(?:is\s+not\s+intended\s+to\s+merge|is\s+intended\s+not\s+to\s+merge)\b",
    re.IGNORECASE,
)
LIFECYCLE_NEGATED_MERGE_ACTION_PATTERN = re.compile(
    r"\b(?:"
    r"(?:must|shall|should|will|would|can|could|may)\s+(?:not|never)\s+merge|"
    r"(?:mustn't|shouldn't|won't|wouldn't|can't|couldn't)\s+merge|"
    r"cannot\s+merge|"
    r"do(?:es)?(?:\s+|-)+not(?:\s+|-)+merge|"
    r"don't\s+merge|doesn't\s+merge|"
    r"never(?:\s+|-)+merge"
    r")\b",
    re.IGNORECASE,
)
LIFECYCLE_PROHIBITION_AUXILIARY_FRAGMENT = (
    r"(?:is|are|was|were|'s|'re|'s\s+been|'ve\s+been|"
    r"'ll\s+be|'d\s+be|will\s+be|would\s+be|shall\s+be|"
    r"should\s+be|must\s+be|may\s+be|might\s+be|can\s+be|could\s+be|"
    r"is\s+being|are\s+being|was\s+being|were\s+being|"
    r"has\s+been|have\s+been|had\s+been|will\s+have\s+been|"
    r"remains?|remained|becomes?|became|"
    r"continues?\s+to\s+be|continued\s+to\s+be)"
)
LIFECYCLE_NON_MERGE_STATE_PATTERN = re.compile(
    r"\b(?:"
    r"(?:must|shall|should|will|would|can|could|may)\s+(?:not|never)\s+"
    r"(?:be\s+)?merged|"
    r"(?:mustn't|shouldn't|won't|wouldn't|can't|couldn't)\s+"
    r"(?:be\s+)?merged|"
    r"cannot\s+be\s+merged|"
    r"(?:is|are|was|were)\s+(?:not|never)\s+"
    r"(?:(?:being|to\s+be)\s+)?merged|"
    r"(?:isn't|aren't|wasn't|weren't)\s+"
    r"(?:(?:being|to\s+be)\s+)?merged|"
    r"(?:is|are|was|were)\s+not\s+intended\s+"
    r"(?:to\s+(?:merge|be\s+merged)|for\s+(?:a\s+)?merge|for\s+merging)|"
    r"(?:isn't|aren't|wasn't|weren't)\s+intended\s+"
    r"(?:to\s+(?:merge|be\s+merged)|for\s+(?:a\s+)?merge|for\s+merging)|"
    r"(?:'s|'re)\s+not\s+intended\s+to\s+(?:merge|be\s+merged)|"
    r"(?:has|have|had)\s+not\s+been\s+intended\s+"
    r"to\s+(?:merge|be\s+merged)|"
    r"(?:hasn't|haven't|hadn't)\s+been\s+intended\s+"
    r"to\s+(?:merge|be\s+merged)|"
    r"(?:will|would|shall)\s+not\s+be\s+intended\s+"
    r"to\s+(?:merge|be\s+merged)|"
    r"(?:won't|wouldn't|shouldn't|mustn't|can't|couldn't|shan't)\s+"
    r"be\s+intended\s+"
    r"to\s+(?:merge|be\s+merged)|"
    r"(?:must|shall|should|can|could|may|might)\s+not\s+be\s+intended\s+"
    r"to\s+(?:merge|be\s+merged)|"
    r"(?:is|are|was|were|'s|'re)\s+intended\s+(?:not|never)\s+"
    r"to\s+(?:merge|be\s+merged)|"
    r"(?:is|are|was|were|'s|'re)\s+"
    r"(?:(?:now|currently|presently)\s+)?never\s+intended\s+"
    r"(?:to\s+(?:merge|be\s+merged)|for\s+(?:a\s+)?merge|for\s+merging)|"
    r"(?:has|have|had)\s+never\s+been\s+intended\s+"
    r"(?:to\s+(?:merge|be\s+merged)|for\s+(?:a\s+)?merge|for\s+merging)|"
    r"(?:will|would|shall|should|must|can|could|may|might)\s+never\s+"
    r"be\s+intended\s+"
    r"(?:to\s+(?:merge|be\s+merged)|for\s+(?:a\s+)?merge|for\s+merging)|"
    r"(?:(?:must|shall|should|will|would|can|could|may)\s+)?"
    r"(?:remain|remains|remained|become|becomes|became|stay|stays|stayed)\s+"
    r"unmerged|"
    r"(?:is|are|was|were|remains?|becomes?)\s+"
    r"(?:unmerged|unmergeable|non[\s-]?mergeable|non[\s-]?merging)|"
    r"(?:is|are|was|were)\s+"
    r"(?:designated|classified|declared|marked)\s+(?:as\s+)?"
    r"(?:non[\s-]?merge|unmerged|unmergeable|non[\s-]?mergeable)|"
    rf"{LIFECYCLE_PROHIBITION_AUXILIARY_FRAGMENT}\s+"
    r"(?:(?:still|now|currently|presently)\s+)?"
    r"(?:forbidden|prohibited|barred|disallowed|prevented|blocked|not\s+allowed)"
    r"\s+(?:from\s+being|to\s+be)\s+merged"
    r")\b",
    re.IGNORECASE,
)
LIFECYCLE_PROHIBITED_MERGE_ACTION_PATTERN = re.compile(
    rf"\b{LIFECYCLE_PROHIBITION_AUXILIARY_FRAGMENT}\s+"
    r"(?:(?:still|now|currently|presently)\s+)?"
    r"(?:forbidden|prohibited|barred|disallowed|prevented|blocked|not\s+allowed)\s+"
    r"(?:from\s+merging|to\s+merge)\b",
    re.IGNORECASE,
)
LIFECYCLE_ATX_HEADING_BOUNDARY_PATTERN = re.compile(
    r"^ {0,3}#{1,6}(?=[ \t]|$).*$",
    re.MULTILINE,
)
LIFECYCLE_SETEXT_UNDERLINE_PATTERN = re.compile(
    r"^ {0,3}(?:=+|-+)[ \t]*$",
    re.MULTILINE,
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
LIFECYCLE_HARD_BOUNDARY_PATTERN = re.compile(r"[.!?;\r\n]")
LIFECYCLE_COORDINATION_BOUNDARY_PATTERN = re.compile(
    r"(?:,\s*)?\b(?:while|whereas|so|therefore|thus|consequently|because|"
    r"although|though|but|however|yet|then|nevertheless|nonetheless)\b|"
    r",\s*\band\b|"
    r"\band\b(?=\s+(?:this|the|current|these|it|they|after|once|upon|"
    r"following|do|never|must|retain|archive|preserve|close|delete|keep)\b)",
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
    r'"[^"]{0,4000}"|“[^”]{0,4000}”|'
    r"(?<![A-Za-z0-9])'[^'\n]{1,1000}'(?![A-Za-z0-9])"
)
OTHER_CANDIDATE_REFERENCE_PATTERN = re.compile(
    r"\b(?:(?:this|that|the|a|an)\s+)?"
    r"(?:historical|legacy|previous|prior|other|unrelated)\s+"
    r"(?:candidate(?:s)?|branch(?:es)?|pull[\s-]+request(?:s)?|prs?|changes?|"
    r"commits?|revisions?|patch(?:es)?)\b|"
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
LIFECYCLE_LIST_ITEM_PATTERN = re.compile(
    r" {0,3}(?:[-+*]|[0-9]{1,9}[.)])(?:[ \t]|$)"
)
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


def _is_markdown_blank_line(value: str) -> bool:
    return not value.strip(" \t")


def _commonmark_lines(
    value: str,
    *,
    keepends: bool = False,
) -> list[str]:
    lines: list[str] = []
    position = 0
    for ending in re.finditer(r"\r\n|\r|\n", value):
        lines.append(
            value[position : ending.end()]
            if keepends
            else value[position : ending.start()]
        )
        position = ending.end()
    if position < len(value):
        lines.append(value[position:])
    return lines


def _mask_markdown_code(text: str) -> str:
    """Mask Markdown code while preserving byte offsets and HTML comments."""
    characters = list(text)
    fence: tuple[tuple[str, int], tuple[str, ...]] | None = None
    active_containers: tuple[str, ...] = ()
    paragraph_containers: tuple[str, ...] | None = None
    in_html_comment = False
    offset = 0

    for raw_line in _commonmark_lines(text, keepends=True):
        line = raw_line.rstrip("\r\n")
        structural_line, containers = _strip_markdown_container_prefix(line)
        if active_containers:
            active_content = _content_inside_markdown_containers(
                line,
                active_containers,
            )
            if active_content is not None:
                structural_line = active_content
                containers = active_containers
            elif _is_markdown_blank_line(line):
                structural_line = ""
            else:
                active_containers = ()
        content_end = offset + len(line)

        if fence is not None:
            fence_spec, fence_containers = fence
            fenced_content = _content_inside_markdown_containers(
                line,
                fence_containers,
            )
            if (
                fenced_content is None
                and _blank_line_continues_list_containers(
                    structural_line,
                    containers,
                    fence_containers,
                )
            ):
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                active_containers = fence_containers
                offset += len(raw_line)
                continue
            if fenced_content is not None:
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                if _fence_closing(fenced_content, fence_spec):
                    fence = None
                active_containers = fence_containers
                paragraph_containers = None
                offset += len(raw_line)
                continue
            fence = None

        if not in_html_comment:
            opening = _fence_opening(structural_line)
            if opening is not None:
                fence = opening, containers
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                if any(
                    container.startswith("list:")
                    for container in containers
                ):
                    active_containers = containers
                paragraph_containers = None
                offset += len(raw_line)
                continue
            if (
                _leading_indentation_columns(structural_line) >= 4
                and paragraph_containers != containers
            ):
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                if any(
                    container.startswith("list:")
                    for container in containers
                ):
                    active_containers = containers
                paragraph_containers = None
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
        if _is_markdown_blank_line(structural_line):
            paragraph_containers = None
        elif (
            re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", structural_line)
            or _is_thematic_break_line(structural_line)
            or re.fullmatch(
                r"[ \t]{0,3}(?:=+|-+)[ \t]*",
                structural_line,
            )
        ):
            paragraph_containers = None
        else:
            paragraph_containers = containers
        if any(container.startswith("list:") for container in containers):
            active_containers = containers
        elif not _is_markdown_blank_line(line):
            active_containers = ()
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

    for raw_line in _commonmark_lines(comments_masked):
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


def _remove_html_comments_outside_code(value: str) -> str:
    spans = _html_comment_spans_outside_code(value)
    if not spans:
        return value
    rendered: list[str] = []
    position = 0
    for start, end in spans:
        rendered.append(value[position:start])
        position = end
    rendered.append(value[position:])
    return "".join(rendered)


def _normalize_markdown_reference_label(value: str) -> str:
    rendered = _render_commonmark_character_references(value).casefold()
    return re.sub(r"[ \t\r\n]+", " ", rendered).strip(" ")


def _commonmark_reference_destination_status(value: str) -> str:
    value = value.replace("\r\n", "\n").replace("\r", "\n")
    content = value.lstrip(" \t")
    if not content:
        return "invalid"

    position = 0
    if content.startswith("<"):
        position = 1
        while position < len(content):
            character = content[position]
            if (
                character == "\\"
                and position + 1 < len(content)
                and content[position + 1] in string.punctuation
            ):
                position += 2
                continue
            if character == ">":
                position += 1
                break
            if character in "<\r\n":
                return "invalid"
            position += 1
        else:
            return "invalid"
    else:
        depth = 0
        while position < len(content) and content[position] not in " \t\r\n":
            character = content[position]
            if (
                character == "\\"
                and position + 1 < len(content)
                and content[position + 1] in string.punctuation
            ):
                position += 2
                continue
            if (
                character == "<"
                or ord(character) < 0x20
                or ord(character) == 0x7F
            ):
                return "invalid"
            if character == "(":
                depth += 1
                if depth > 32:
                    return "invalid"
            elif character == ")":
                if depth == 0:
                    return "invalid"
                depth -= 1
            position += 1
        if position == 0 or depth:
            return "invalid"

    remainder = content[position:].strip(" \t")
    if not remainder:
        return "valid"
    closing = {'"': '"', "'": "'", "(": ")"}.get(remainder[0])
    if closing is None:
        return "invalid"
    if re.search(r"\n[ \t]*\n", remainder):
        return "invalid"
    position = 1
    while position < len(remainder):
        character = remainder[position]
        if (
            character == "\\"
            and position + 1 < len(remainder)
            and remainder[position + 1] in string.punctuation
        ):
            position += 2
            continue
        if character == closing:
            return (
                "valid"
                if not remainder[position + 1 :].strip(" \t")
                else "invalid"
            )
        if remainder[0] == "(" and character == "(":
            return "invalid"
        position += 1
    return "incomplete-title"


def _valid_commonmark_reference_destination(value: str) -> bool:
    return _commonmark_reference_destination_status(value) == "valid"


def _markdown_list_marker(
    value: str,
) -> tuple[str, int | None, int, bool] | None:
    content = value
    while True:
        blockquote = re.match(r"^[ \t]{0,3}>[ \t]?", content)
        if blockquote is None:
            break
        content = content[blockquote.end() :]
    match = re.match(
        r"(?P<indent> {0,3})(?P<marker>[-+*]|"
        r"(?P<number>[0-9]{1,9})[.)])(?P<padding>[ \t]+|$)",
        content,
    )
    if match is None or _is_thematic_break_line(content):
        return None
    number = match.group("number")
    return (
        (
            "ordered"
            if number is not None
            else "hyphen"
            if match.group("marker") == "-"
            else "bullet"
        ),
        int(number) if number is not None else None,
        len(match.group("indent")),
        _is_markdown_blank_line(content[match.end() :]),
    )


def _strip_markdown_container_prefix(
    value: str,
) -> tuple[str, tuple[str, ...]]:
    content = value
    containers: list[str] = []
    while True:
        blockquote = re.match(r"^[ \t]{0,3}>[ \t]?", content)
        if blockquote is not None:
            content = content[blockquote.end() :]
            containers.append("blockquote")
            continue
        list_item = re.match(
            r" {0,3}(?:[-+*]|[0-9]{1,9}[.)])(?P<padding>[ \t]+)",
            content,
        )
        if list_item is not None and not _is_thematic_break_line(content):
            marker_end = list_item.start("padding")
            padding = list_item.group("padding")
            marker_columns = 0
            for character in content[:marker_end]:
                if character == "\t":
                    marker_columns += 4 - (marker_columns % 4)
                else:
                    marker_columns += 1
            padding_columns = 0
            for character in padding:
                width = (
                    4 - ((marker_columns + padding_columns) % 4)
                    if character == "\t"
                    else 1
                )
                padding_columns += width
            indentation = padding_columns if padding_columns <= 4 else 1
            content = (
                " " * (padding_columns - indentation)
                + content[list_item.end("padding") :]
            )
            columns = marker_columns + indentation
            containers.append(f"list:{columns}")
            continue
        return content, tuple(containers)


def _reference_container_continues(
    opening: tuple[str, ...],
    continuation: tuple[str, ...],
    content: str,
) -> bool:
    if continuation == opening:
        return True
    missing = opening[len(continuation) :]
    required_indentation = sum(
        int(container.partition(":")[2])
        for container in missing
        if container.startswith("list:")
    )
    return (
        opening[: len(continuation)] == continuation
        and bool(missing)
        and all(container.startswith("list:") for container in missing)
        and _leading_indentation_columns(content) >= required_indentation
    )


def _blank_line_continues_list_containers(
    content: str,
    continuation: tuple[str, ...],
    opening: tuple[str, ...],
) -> bool:
    missing = opening[len(continuation) :]
    return (
        _is_markdown_blank_line(content)
        and opening[: len(continuation)] == continuation
        and bool(missing)
        and all(container.startswith("list:") for container in missing)
    )


def _content_inside_markdown_containers(
    value: str,
    containers: tuple[str, ...],
) -> str | None:
    content = value
    for container in containers:
        if container == "blockquote":
            blockquote = re.match(r"^[ \t]{0,3}>[ \t]?", content)
            if blockquote is None:
                return None
            content = content[blockquote.end() :]
            continue
        if not container.startswith("list:"):
            return None
        required = int(container.partition(":")[2])
        columns = 0
        position = 0
        while position < len(content) and content[position] in " \t":
            if content[position] == "\t":
                columns += 4 - (columns % 4)
            else:
                columns += 1
            position += 1
            if columns >= required:
                break
        if columns < required:
            return None
        content = content[position:]
    return content


def _markdown_link_label_fragment(
    value: str,
    *,
    starts_label: bool,
) -> tuple[str, str, str | None]:
    if starts_label:
        opening = re.match(r"^[ \t]{0,3}\[", value)
        if opening is None:
            return "invalid", "", None
        start = opening.end()
    else:
        start = 0

    position = start
    while position < len(value):
        character = value[position]
        if (
            character == "\\"
            and position + 1 < len(value)
            and value[position + 1] in string.punctuation
        ):
            position += 2
            continue
        if character == "[":
            return "invalid", "", None
        if character == "]":
            if position + 1 < len(value) and value[position + 1] == ":":
                return (
                    "closed",
                    value[start:position],
                    value[position + 2 :],
                )
            return "invalid", "", None
        position += 1
    return "open", value[start:], None


def _markdown_reference_labels(
    value: str,
    *,
    definition_spans: list[tuple[int, int]] | None = None,
) -> frozenset[str]:
    comments_masked = _mask_html_comments_outside_code(value)
    lines: list[tuple[str | None, tuple[str, ...]]] = []
    fence: tuple[tuple[str, int], tuple[str, ...]] | None = None
    active_containers: tuple[str, ...] = ()
    for raw_line in _commonmark_lines(comments_masked):
        content, containers = _strip_markdown_container_prefix(raw_line)
        if active_containers:
            active_content = _content_inside_markdown_containers(
                raw_line,
                active_containers,
            )
            if active_content is not None:
                content = active_content
                containers = active_containers
            elif _is_markdown_blank_line(raw_line):
                content = ""
            else:
                active_containers = ()
        if fence is not None:
            fence_spec, fence_containers = fence
            fenced_content = _content_inside_markdown_containers(
                raw_line,
                fence_containers,
            )
            if (
                fenced_content is None
                and _blank_line_continues_list_containers(
                    content,
                    containers,
                    fence_containers,
                )
            ):
                lines.append((None, containers))
                active_containers = fence_containers
                continue
            if fenced_content is None:
                fence = None
            else:
                if _fence_closing(fenced_content, fence_spec):
                    fence = None
                lines.append((None, containers))
                active_containers = fence_containers
                continue
        opening = _fence_opening(content)
        if opening is not None:
            fence = opening, containers
            lines.append((None, containers))
            if any(
                container.startswith("list:")
                for container in containers
            ):
                active_containers = containers
            continue
        lines.append((content, containers))
        if any(container.startswith("list:") for container in containers):
            active_containers = containers
        elif not _is_markdown_blank_line(raw_line):
            active_containers = ()

    labels: set[str] = set()
    paragraph_containers: tuple[str, ...] | None = None
    definition_continuation_end = -1
    raw_lines_with_ends = _commonmark_lines(comments_masked, keepends=True)
    raw_lines = _commonmark_lines(comments_masked)
    line_offsets: list[int] = []
    line_offset = 0
    for raw_line in raw_lines_with_ends:
        line_offsets.append(line_offset)
        line_offset += len(raw_line)
    for index, (content, containers) in enumerate(lines):
        if index <= definition_continuation_end:
            continue
        if content is None:
            paragraph_containers = None
            continue
        if _is_markdown_blank_line(content):
            empty_list_marker = _markdown_list_marker(raw_lines[index])
            if (
                empty_list_marker is not None
                and empty_list_marker[3]
                and paragraph_containers is not None
            ):
                marker_kind = empty_list_marker[0]
                marker_indentation = empty_list_marker[2]
                prior_list_indentation = sum(
                    int(container.partition(":")[2])
                    for container in paragraph_containers
                    if container.startswith("list:")
                )
                if (
                    marker_kind == "hyphen"
                    or (
                        prior_list_indentation > 0
                        and marker_indentation < prior_list_indentation
                    )
                ):
                    paragraph_containers = None
            else:
                paragraph_containers = None
            continue
        if _leading_indentation_columns(content) >= 4:
            continue
        label_status, label_fragment, fragment_tail = (
            _markdown_link_label_fragment(
                content,
                starts_label=True,
            )
        )
        label: str | None = None
        tail: str | None = None
        destination_index = index + 1
        if label_status == "closed":
            label = label_fragment
            tail = fragment_tail
            if len(label) > 999:
                label = None
                tail = None
        elif label_status == "open":
            label_parts = [label_fragment]
            raw_label_length = len(label_fragment)
            for continuation_index in range(index + 1, len(lines)):
                continuation, continuation_containers = lines[
                    continuation_index
                ]
                if (
                    continuation is None
                    or _is_markdown_blank_line(continuation)
                    or not _reference_container_continues(
                        containers,
                        continuation_containers,
                        continuation,
                    )
                ):
                    break
                (
                    continuation_status,
                    continuation_fragment,
                    continuation_tail,
                ) = _markdown_link_label_fragment(
                    continuation,
                    starts_label=False,
                )
                if continuation_status == "invalid":
                    break
                raw_label_length += 1 + len(continuation_fragment)
                if raw_label_length > 999:
                    break
                label_parts.append(continuation_fragment)
                if continuation_status == "closed":
                    label = "\n".join(label_parts)
                    tail = continuation_tail
                    destination_index = continuation_index + 1
                    break
        if label is not None and not re.search(r"[^ \t\r\n]", label):
            label = None
            tail = None
        if label is None or tail is None:
            atx_heading = bool(
                re.match(r"^[ \t]{0,3}#{1,6}(?:[ \t]+|$)", content)
            )
            setext_heading = bool(
                re.fullmatch(r"[ \t]{0,3}(?:=+|-+)[ \t]*", content)
                and paragraph_containers == containers
            )
            empty_list_marker = _markdown_list_marker(raw_lines[index])
            if atx_heading or setext_heading or _is_thematic_break_line(content):
                paragraph_containers = None
            elif (
                empty_list_marker is not None
                and empty_list_marker[3]
            ):
                marker_indentation = empty_list_marker[2]
                prior_list_indentation = sum(
                    int(container.partition(":")[2])
                    for container in (paragraph_containers or ())
                    if container.startswith("list:")
                )
                if (
                    paragraph_containers is None
                    or (
                        prior_list_indentation > 0
                        and marker_indentation < prior_list_indentation
                    )
                ):
                    paragraph_containers = None
            else:
                paragraph_containers = containers
            continue
        _, explicit_containers = _strip_markdown_container_prefix(
            raw_lines[index]
        )
        list_marker = _markdown_list_marker(raw_lines[index])
        starts_new_list_item = False
        if list_marker is not None:
            (
                marker_kind,
                start_number,
                marker_indentation,
                _empty_marker,
            ) = list_marker
            prior_list_indentation = sum(
                int(container.partition(":")[2])
                for container in (paragraph_containers or ())
                if container.startswith("list:")
            )
            starts_new_list_item = (
                marker_kind in {"bullet", "hyphen"}
                or start_number == 1
                or (
                    prior_list_indentation > 0
                    and marker_indentation < prior_list_indentation
                )
            )
        starts_new_container = (
            list_marker is None
            and bool(explicit_containers)
            and explicit_containers != paragraph_containers
        )
        if paragraph_containers is not None and not (
            starts_new_list_item or starts_new_container
        ):
            paragraph_containers = containers
            continue
        destination = tail
        continuation_index = destination_index
        if _is_markdown_blank_line(destination) and continuation_index < len(lines):
            destination, destination_containers = lines[destination_index]
            if (
                destination is None
                or _is_markdown_blank_line(destination)
                or not _reference_container_continues(
                    containers,
                    destination_containers,
                    destination,
                )
            ):
                continue
            continuation_index += 1
        status = _commonmark_reference_destination_status(destination)
        while (
            status == "incomplete-title"
            and continuation_index < len(lines)
        ):
            continuation, continuation_containers = lines[continuation_index]
            if (
                continuation is None
                or _is_markdown_blank_line(continuation)
                or not _reference_container_continues(
                    containers,
                    continuation_containers,
                    continuation,
                )
            ):
                break
            destination += "\n" + continuation
            continuation_index += 1
            status = _commonmark_reference_destination_status(destination)
        has_destination = status == "valid"
        if has_destination:
            labels.add(_normalize_markdown_reference_label(label))
            definition_continuation_end = continuation_index - 1
            if definition_spans is not None:
                definition_spans.append(
                    (
                        line_offsets[index],
                        (
                            line_offsets[continuation_index]
                            if continuation_index < len(line_offsets)
                            else len(value)
                        ),
                    )
                )
            paragraph_containers = None
        else:
            paragraph_containers = containers
    return frozenset(labels)


def _is_default_ignorable_code_point(character: str) -> bool:
    code_point = ord(character)
    return (
        code_point in {0x00AD, 0x034F, 0x061C, 0x3164, 0xFEFF, 0xFFA0}
        or 0x115F <= code_point <= 0x1160
        or 0x17B4 <= code_point <= 0x17B5
        or 0x180B <= code_point <= 0x180F
        or 0x200B <= code_point <= 0x200F
        or 0x202A <= code_point <= 0x202E
        or 0x2060 <= code_point <= 0x206F
        or 0xFE00 <= code_point <= 0xFE0F
        or 0xFFF0 <= code_point <= 0xFFF8
        or 0x1BCA0 <= code_point <= 0x1BCA3
        or 0x1D173 <= code_point <= 0x1D17A
        or 0xE0000 <= code_point <= 0xE0FFF
    )


def _render_lifecycle_label_line(
    original: str,
    operative: str,
    reference_labels: frozenset[str],
) -> str:
    if not operative.strip():
        return operative
    escaped_markup: list[str] = []

    def protect_markup_escape(match: re.Match[str]) -> str:
        escaped_markup.append(match.group(1))
        return f"\ue000{len(escaped_markup) - 1}\ue001"

    def protect_bracket_entity(match: re.Match[str]) -> str:
        character = html.unescape(match.group(0))
        if character not in "[]":
            return match.group(0)
        escaped_markup.append(character)
        return f"\ue000{len(escaped_markup) - 1}\ue001"

    def restore_markup_escapes(value: str) -> str:
        for index, character in enumerate(escaped_markup):
            value = value.replace(f"\ue000{index}\ue001", character)
        return value

    protected = re.sub(
        r"\\([*_\[\]~`])",
        protect_markup_escape,
        original,
    )
    protected = MARKDOWN_ENTITY_PATTERN.sub(
        protect_bracket_entity,
        protected,
    )
    rendered = _operative_lifecycle_prose(
        _remove_html_comments_outside_code(protected)
    )
    inline_link = re.compile(r"\[([^\]\n]+)\]\([^)\n]*\)")
    reference_link = re.compile(r"\[([^\]\n]+)\]\[([^\[\]\n]*)\]")
    shortcut_link = re.compile(r"\[([^\[\]\n]+)\]")
    previous = None
    while previous != rendered:
        previous = rendered
        rendered = inline_link.sub(r"\1", rendered)
        rendered = reference_link.sub(
            lambda match: (
                match.group(1)
                if _normalize_markdown_reference_label(
                    restore_markup_escapes(
                        match.group(2) or match.group(1)
                    )
                )
                in reference_labels
                else match.group(0)
            ),
            rendered,
        )
        rendered = shortcut_link.sub(
            lambda match: (
                match.group(1)
                if _normalize_markdown_reference_label(
                    restore_markup_escapes(match.group(1))
                )
                in reference_labels
                else match.group(0)
            ),
            rendered,
        )
        for emphasis in (
            re.compile(r"\*\*(?=\S)(.+?\S)\*\*"),
            re.compile(r"__(?=\S)(.+?\S)__"),
            re.compile(r"~~(?=\S)(.+?\S)~~"),
            re.compile(r"\*(?=\S)(.+?\S)\*"),
            re.compile(r"_(?=\S)(.+?\S)_"),
        ):
            rendered = emphasis.sub(r"\1", rendered)
    return restore_markup_escapes(rendered)


def _parse_lifecycle_fields(
    value: str,
    allowed_labels: frozenset[str] | None = None,
    *,
    reference_labels: frozenset[str] | None = None,
    location: str | None = None,
    errors: list[str] | None = None,
) -> dict[str, list[str]]:
    """Return canonical column-zero lifecycle fields from reviewable prose.

    Quoted and blockquoted examples are masked before structural recognition.
    Every canonical metadata line must contain exactly one visible canonical
    lifecycle label. Explanatory prefixes, parentheticals, and later label-like
    substrings therefore cannot lend metadata to a record or hide behind the
    first recognized value.
    """
    fields: dict[str, list[str]] = {}
    if reference_labels is None:
        reference_labels = _markdown_reference_labels(value)
    operative = _operative_lifecycle_prose(
        _reviewable_markdown_structure(value),
        mask_list_items=True,
    )
    original_lines = _commonmark_lines(value)
    operative_lines = _commonmark_lines(operative)
    for line_number, (original, visible) in enumerate(
        zip(original_lines, operative_lines),
        start=1,
    ):
        rendered_visible = _render_lifecycle_label_line(
            original,
            visible,
            reference_labels,
        )
        matches = list(LIFECYCLE_FIELD_LABEL_PATTERN.finditer(rendered_visible))
        if not matches or matches[0].start() != 0:
            continue
        label = matches[0].group("label")
        if len(matches) != 1:
            if errors is not None:
                label_names = ", ".join(
                    f"'{match.group('label')}'" for match in matches
                )
                errors.append(
                    f"lifecycle: {location or 'metadata'} line {line_number} has "
                    f"{len(matches)} visible canonical labels ({label_names}); "
                    "expected exactly one canonical field per physical line"
                )
            continue
        prefix = f"{label}:"
        if not original.startswith(prefix):
            continue
        if allowed_labels is not None and label not in allowed_labels:
            continue
        match = LIFECYCLE_FIELD_PATTERN.fullmatch(visible)
        if match is None:
            continue
        field_value = rendered_visible[len(prefix) :].strip()
        if not any(
            not character.isspace()
            and unicodedata.category(character)
            not in {"Cc", "Cf", "Cs", "Co", "Cn"}
            and not _is_default_ignorable_code_point(character)
            for character in field_value
        ):
            field_value = ""
        fields.setdefault(label.lower(), []).append(field_value)
    return fields


def _direct_lifecycle_section_body(value: str) -> str:
    """Return metadata-bearing prose before the first nested Markdown heading."""
    reviewable = _reviewable_markdown_structure(value)
    boundaries: list[int] = []
    reviewable_offset = 0
    for reviewable_line in _commonmark_lines(reviewable, keepends=True):
        content = reviewable_line.rstrip("\r\n")
        if re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", content):
            boundaries.append(reviewable_offset)
        reviewable_offset += len(reviewable_line)
    comments_masked = _mask_html_comments_outside_code(value)
    original_lines = _commonmark_lines(comments_masked, keepends=True)
    reviewable_lines = _commonmark_lines(reviewable, keepends=True)
    line_offsets: list[int] = []
    offset = 0
    for line in original_lines:
        line_offsets.append(offset)
        offset += len(line)
    for line_index, reviewable_line in enumerate(reviewable_lines):
        line = reviewable_line.rstrip("\r\n")
        if (
            line_index == 0
            or LIFECYCLE_SETEXT_UNDERLINE_PATTERN.fullmatch(line) is None
        ):
            continue
        block_start = line_index - 1
        while block_start >= 0:
            candidate = original_lines[block_start].rstrip("\r\n")
            if (
                _is_markdown_blank_line(candidate)
                or _leading_indentation_columns(candidate) >= 4
                or re.match(r"^[ \t]{0,3}>", candidate)
                or _fence_opening(candidate) is not None
                or re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", candidate)
                or _is_thematic_break_line(candidate)
                or PLAIN_PROSE_LIST_PATTERN.match(candidate)
            ):
                break
            block_start -= 1
        heading_start = block_start + 1
        if heading_start < line_index:
            boundaries.append(line_offsets[heading_start])
    if not boundaries:
        return value
    return value[: min(boundaries)]


def _field_values(fields: dict[str, list[str]], label: str) -> list[str]:
    return fields.get(label.lower(), [])


def _single_lifecycle_field_value(
    fields: dict[str, list[str]],
    label: str,
) -> str | None:
    values = _field_values(fields, label)
    if len(values) != 1 or not values[0].strip():
        return None
    return values[0]


def _validate_lifecycle_field_cardinality(
    fields: dict[str, list[str]],
    allowed_labels: frozenset[str],
    location: str,
    errors: list[str],
) -> None:
    for label in sorted(allowed_labels, key=str.casefold):
        values = _field_values(fields, label)
        if len(values) <= 1:
            continue
        conflicting = len({value.strip() for value in values}) > 1
        conflict_detail = " with conflicting values" if conflicting else ""
        errors.append(
            f"lifecycle: {location} field '{label}' has {len(values)} visible "
            f"canonical occurrences{conflict_detail}; expected at most one"
        )


def _validate_disposition_alternatives(
    fields: dict[str, list[str]],
    location: str,
    errors: list[str],
) -> None:
    count = sum(
        len(_field_values(fields, label))
        for label in FINAL_DISPOSITION_FIELD_LABELS
    )
    if count > 1:
        errors.append(
            f"lifecycle: {location} must declare at most one disposition alternative: "
            "'Final disposition' or 'Close or deletion conditions'"
        )


def _has_exact_sha_field(fields: dict[str, list[str]], label: str) -> str | None:
    value = _single_lifecycle_field_value(fields, label)
    if value is None:
        return None
    match = EXACT_SHA_VALUE_PATTERN.search(value)
    return match.group(0) if match is not None else None


def _render_commonmark_character_references(value: str) -> str:
    escaped: list[str] = []

    def protect_escape(match: re.Match[str]) -> str:
        escaped.append(match.group(1))
        return f"\uf000{len(escaped) - 1}\uf001"

    protected = COMMONMARK_BACKSLASH_ESCAPE_PATTERN.sub(protect_escape, value)
    rendered = MARKDOWN_ENTITY_PATTERN.sub(
        lambda match: html.unescape(match.group(0)),
        protected,
    )
    for index, character in enumerate(escaped):
        rendered = rendered.replace(f"\uf000{index}\uf001", character)
    return rendered


def _is_thematic_break_line(value: str) -> bool:
    return bool(
        re.fullmatch(
            r" {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|"
            r"(?:_[ \t]*){3,})",
            value,
        )
    )


def _render_commonmark_emphasis(value: str) -> str:
    escaped: list[str] = []

    def protect_escape(match: re.Match[str]) -> str:
        escaped.append(match.group(1))
        return f"\uf100{len(escaped) - 1}\uf101"

    rendered = re.sub(r"\\([*_])", protect_escape, value)
    previous = None
    while previous != rendered:
        previous = rendered
        for emphasis in (
            re.compile(
                r"\*\*(?=\S)((?:(?!\r?\n[ \t]*\r?\n).)+?\S)\*\*",
                re.DOTALL,
            ),
            re.compile(
                r"__(?=\S)((?:(?!\r?\n[ \t]*\r?\n).)+?\S)__",
                re.DOTALL,
            ),
            re.compile(
                r"\*(?=\S)((?:(?!\r?\n[ \t]*\r?\n).)+?\S)\*",
                re.DOTALL,
            ),
            re.compile(
                r"_(?=\S)((?:(?!\r?\n[ \t]*\r?\n).)+?\S)_",
                re.DOTALL,
            ),
        ):
            rendered = emphasis.sub(r"\1", rendered)
    for index, character in enumerate(escaped):
        rendered = rendered.replace(f"\uf100{index}\uf101", character)
    return rendered


def _render_commonmark_links(
    value: str,
    reference_labels: frozenset[str],
) -> str:
    """Render visible link labels without lending prose from invalid links."""

    def is_unescaped(position: int) -> bool:
        backslashes = 0
        cursor = position - 1
        while cursor >= 0 and value[cursor] == "\\":
            backslashes += 1
            cursor -= 1
        return backslashes % 2 == 0

    def label_end(opening: int) -> int | None:
        depth = 1
        position = opening + 1
        while position < len(value):
            character = value[position]
            if (
                character == "\\"
                and position + 1 < len(value)
                and value[position + 1] in string.punctuation
            ):
                position += 2
                continue
            if character == "[":
                depth += 1
            elif character == "]":
                depth -= 1
                if depth == 0:
                    return position
            elif character in "\r\n" and re.match(
                r"\r?\n[ \t]*\r?\n",
                value[position:],
            ):
                return None
            position += 1
        return None

    def inline_destination_end(opening: int) -> int | None:
        position = opening + 1
        while position < len(value):
            if (
                value[position] == "\\"
                and position + 1 < len(value)
                and value[position + 1] in string.punctuation
            ):
                position += 2
                continue
            if value[position] == ")":
                destination = value[opening + 1 : position]
                if (
                    not destination.strip(" \t\r\n")
                    or _valid_commonmark_reference_destination(destination)
                ):
                    return position + 1
            if re.match(r"\r?\n[ \t]*\r?\n", value[position:]):
                return None
            position += 1
        return None

    rendered: list[str] = []
    position = 0
    while position < len(value):
        opening = value.find("[", position)
        if opening < 0:
            rendered.append(value[position:])
            break
        prefix = value[position:opening]
        if not is_unescaped(opening):
            rendered.append(prefix)
            rendered.append("[")
            position = opening + 1
            continue
        is_image = (
            opening > 0
            and value[opening - 1] == "!"
            and is_unescaped(opening - 1)
        )
        closing = label_end(opening)
        if is_image and closing is not None:
            image_end = closing + 1
            label = value[opening + 1 : closing]
            suffix = closing + 1
            if suffix < len(value) and value[suffix] == "(":
                inline_end = inline_destination_end(suffix)
                if inline_end is not None:
                    image_end = inline_end
            elif suffix < len(value) and value[suffix] == "[":
                reference_end = label_end(suffix)
                if reference_end is not None:
                    reference = value[suffix + 1 : reference_end] or label
                    if (
                        len(reference) <= 999
                        and _normalize_markdown_reference_label(reference)
                        in reference_labels
                    ):
                        image_end = reference_end + 1
            elif (
                len(label) <= 999
                and _normalize_markdown_reference_label(label)
                in reference_labels
            ):
                image_end = closing + 1
            rendered.append(prefix[:-1])
            rendered.append(
                "".join(
                    character if character in "\r\n" else " "
                    for character in value[opening - 1 : image_end]
                )
            )
            position = image_end
            continue
        rendered.append(prefix)
        if is_image:
            rendered.append("[")
            position = opening + 1
            continue
        if closing is None or (
            closing + 1 < len(value) and value[closing + 1] == ":"
        ):
            rendered.append("[")
            position = opening + 1
            continue

        label = value[opening + 1 : closing]
        link_end: int | None = None
        suffix = closing + 1
        if suffix < len(value) and value[suffix] == "(":
            link_end = inline_destination_end(suffix)
        elif suffix < len(value) and value[suffix] == "[":
            reference_end = label_end(suffix)
            if reference_end is not None:
                reference = value[suffix + 1 : reference_end] or label
                if (
                    len(reference) <= 999
                    and _normalize_markdown_reference_label(reference)
                    in reference_labels
                ):
                    link_end = reference_end + 1
        elif (
            len(label) <= 999
            and _normalize_markdown_reference_label(label) in reference_labels
        ):
            link_end = closing + 1

        if link_end is None:
            rendered.append("[")
            position = opening + 1
            continue
        rendered.append(label)
        position = link_end
    return "".join(rendered)


def _mask_non_link_bracket_text(value: str) -> str:
    """Mask bracketed literals left after valid links have been rendered."""
    tokens: list[tuple[int, int, str]] = []
    position = 0
    while position < len(value):
        if value[position] in "[]":
            tokens.append((position, position + 1, value[position]))
            position += 1
            continue
        entity = MARKDOWN_ENTITY_PATTERN.match(value, position)
        if entity is not None:
            rendered = html.unescape(entity.group(0))
            backslashes = 0
            cursor = position - 1
            while cursor >= 0 and value[cursor] == "\\":
                backslashes += 1
                cursor -= 1
            if rendered in "[]" and backslashes % 2 == 0:
                tokens.append((position, entity.end(), rendered))
            position = entity.end()
            continue
        position += 1

    characters = list(value)
    openings: list[tuple[int, int, int]] = []
    for start, end, bracket in tokens:
        while openings and start >= openings[-1][2]:
            openings.pop()
        if bracket == "[":
            openings.append(
                (start, end, _markdown_inline_block_end(value, start))
            )
            continue
        if not openings:
            continue
        opening_start, _opening_end, _block_end = openings.pop()
        if end < len(value) and value[end] == ":":
            continue
        _mask_non_newlines(characters, opening_start, end)
    return "".join(characters)


def _markdown_inline_block_end(value: str, position: int) -> int:
    offset = 0
    containing_line_seen = False
    for raw_line in _commonmark_lines(value, keepends=True):
        line_start = offset
        offset += len(raw_line)
        if not containing_line_seen:
            if position < offset or offset == len(value):
                containing_line_seen = True
            continue
        line = raw_line.rstrip("\r\n")
        list_marker = _markdown_list_marker(line)
        list_interrupts = bool(
            list_marker is not None
            and not list_marker[3]
            and (
                list_marker[0] != "ordered"
                or list_marker[1] == 1
            )
        )
        if (
            _is_markdown_blank_line(line)
            or re.match(r"^[ \t]{0,3}>[ \t]?", line)
            or list_interrupts
            or _fence_opening(line) is not None
            or re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", line)
            or _is_thematic_break_line(line)
            or re.fullmatch(r"[ \t]{0,3}(?:=+|-+)[ \t]*", line)
            or _leading_indentation_columns(line) >= 4
        ):
            return line_start
    return len(value)


def _mask_gfm_strikethrough(value: str) -> str:
    characters = list(value)

    def unescaped(position: int) -> bool:
        backslashes = 0
        cursor = position - 1
        while cursor >= 0 and value[cursor] == "\\":
            backslashes += 1
            cursor -= 1
        return backslashes % 2 == 0

    position = 0
    while position + 1 < len(value):
        if not (
            value[position : position + 2] == "~~"
            and unescaped(position)
            and position + 2 < len(value)
            and not value[position + 2].isspace()
        ):
            position += 1
            continue
        block_end = _markdown_inline_block_end(value, position)
        closing = position + 2
        while closing + 1 < block_end:
            if (
                value[closing : closing + 2] == "~~"
                and unescaped(closing)
                and not value[closing - 1].isspace()
            ):
                _mask_non_newlines(characters, position, closing + 2)
                position = closing + 2
                break
            closing += 1
        else:
            position += 2
    return "".join(characters)


def _operative_lifecycle_prose(
    value: str,
    *,
    mask_list_items: bool = False,
    mask_non_link_brackets: bool = False,
) -> str:
    """Mask quoted/code-style examples while preserving operative prose offsets."""
    reference_definition_spans: list[tuple[int, int]] = []
    reference_labels = _markdown_reference_labels(
        value,
        definition_spans=reference_definition_spans,
    )
    value = _reviewable_markdown_structure(value)
    characters = list(value)
    for start, end in reference_definition_spans:
        _mask_non_newlines(characters, start, end)
    offset = 0
    lazy_container_paragraph = False
    for raw_line in _commonmark_lines(value, keepends=True):
        line = raw_line.rstrip("\r\n")
        blockquote = re.match(r"^[ \t]{0,3}>[ \t]?", line)
        list_item = LIFECYCLE_LIST_ITEM_PATTERN.match(line)
        mask_list_item = (
            mask_list_items
            and list_item is not None
            and not _is_thematic_break_line(line)
        )
        if blockquote is not None or mask_list_item:
            _mask_non_newlines(characters, offset, offset + len(raw_line))
            marker_end = (
                blockquote.end() if blockquote is not None else list_item.end()
            )
            content = line[marker_end:]
            lazy_container_paragraph = (
                not _is_markdown_blank_line(content)
            ) and not (
                _fence_opening(content) is not None
                or re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", content)
                or PLAIN_PROSE_LIST_PATTERN.match(content)
            )
        elif lazy_container_paragraph and not _is_markdown_blank_line(line):
            interrupts_paragraph = bool(
                _fence_opening(line) is not None
                or re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", line)
                or _is_thematic_break_line(line)
                or LIFECYCLE_LIST_ITEM_PATTERN.match(line)
                or _leading_indentation_columns(line) >= 4
            )
            if not interrupts_paragraph:
                _mask_non_newlines(characters, offset, offset + len(raw_line))
            else:
                lazy_container_paragraph = False
        else:
            lazy_container_paragraph = False
        offset += len(raw_line)
    quoted = _render_commonmark_emphasis(
        _mask_gfm_strikethrough("".join(characters))
    )
    quoted = _render_commonmark_links(
        quoted,
        reference_labels,
    )
    if mask_non_link_brackets:
        quoted = _mask_non_link_bracket_text(quoted)
    quoted = (
        _render_commonmark_character_references(quoted)
        .replace("\u2019", "'")
        .replace("\u2018", "'")
        .replace("\u2010", "-")
        .replace("\u2011", "-")
    )
    characters = list(quoted)
    for match in LIFECYCLE_QUOTATION_PATTERN.finditer(quoted):
        for index in range(match.start(), match.end()):
            if characters[index] not in "\r\n.!?;":
                characters[index] = " "
    return "".join(characters)


def _current_candidate_reference_pattern(
    context: dict[str, object],
) -> re.Pattern[str]:
    pr_number = context.get("pr_number")
    head_ref = context.get("head_ref")
    head_sha = context.get("head_sha")
    alternatives = [
        (
            r"\b(?:this|these|current|the\s+current)\s+"
            r"(?:(?:source|temporary|tracking|candidate|validation|feature|"
            r"head|exact)\s+){0,3}"
            r"(?:candidate(?:s)?|branch(?:es)?|changes?|commits?|revisions?|"
            r"patch(?:es)?|"
            r"pull[\s-]+request(?:s)?|prs?)\b"
        ),
        (
            r"\bthe\s+"
            r"(?!(?:historical|legacy|previous|prior|other|unrelated)\b)"
            r"(?:(?:source|temporary|tracking|candidate|validation|feature|"
            r"head|exact)\s+){0,3}"
            r"(?:candidate(?:s)?|branch(?:es)?|changes?|commits?|revisions?|"
            r"patch(?:es)?|"
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
    if isinstance(head_sha, str) and re.fullmatch(
        r"[0-9A-Fa-f]{40}", head_sha
    ):
        alternatives.append(
            rf"(?<![0-9A-Fa-f]){re.escape(head_sha)}(?![0-9A-Fa-f])"
        )
    return re.compile("(?:" + "|".join(alternatives) + ")", re.IGNORECASE)


def _paragraph_start(value: str, position: int) -> int:
    blank_start = 0
    heading_start = 0
    offset = 0
    for raw_line in _commonmark_lines(value[:position], keepends=True):
        line = raw_line.rstrip("\r\n")
        if _is_markdown_blank_line(line):
            blank_start = offset + len(raw_line)
        elif re.match(r"^ {0,3}#{1,6}(?=[ \t]|$)", line):
            heading_start = offset
        offset += len(raw_line)
    return max(0, position - 360, blank_start, heading_start)


def _local_clause_bounds(value: str, position: int) -> tuple[int, int]:
    start = _paragraph_start(value, position)
    end = len(value)
    for pattern in (
        LIFECYCLE_HARD_BOUNDARY_PATTERN,
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


def _lifecycle_intentions(value: str) -> tuple[bool, bool]:
    """Return operative merge and non-merge intention declarations."""
    operative = _operative_lifecycle_prose(
        value,
        mask_non_link_brackets=True,
    )
    merge = any(
        not _is_descriptive_occurrence(operative, match.start())
        for match in MERGE_INTENTION_PATTERN.finditer(operative)
    )
    non_merge = any(
        not _is_descriptive_occurrence(operative, match.start())
        for match in NON_MERGE_INTENTION_PATTERN.finditer(operative)
    )
    return merge, non_merge


def _has_operative_closes(value: str) -> bool:
    """Return whether visible operative prose contains a closure keyword."""
    operative = _operative_lifecycle_prose(
        value,
        mask_non_link_brackets=True,
    )
    return any(
        not _is_descriptive_occurrence(operative, match.start())
        for match in CLOSES_ISSUE_PATTERN.finditer(operative)
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
    if identity == "current":
        earlier = max(
            (
                item
                for item in references
                if item[1] <= reference_start
            ),
            key=lambda item: (item[1], item[0]),
            default=None,
        )
        if (
            earlier is not None
            and re.fullmatch(
                r"\s*(?:,?\s*unlike|\(\s*unlike)\s*",
                value[earlier[1] : reference_start],
                re.IGNORECASE,
            )
            is not None
        ):
            return earlier[2], earlier[0], reference_end
    if identity == "other":
        coordinated = sorted(
            (
                item
                for item in references
                if item[1] <= reference_end
            ),
            key=lambda item: (item[0], item[1]),
        )
        chain_start = reference_start
        for earlier_start, earlier_end, earlier_identity in reversed(
            coordinated[:-1]
        ):
            if re.fullmatch(
                r"\s*(?:,|,?\s*(?:and|or|nor)|"
                r",?\s*(?:together\s+with|as\s+well\s+as)|"
                r",?\s*unlike|\(\s*unlike)\s*",
                value[earlier_end:chain_start],
                re.IGNORECASE,
            ) is None:
                break
            if earlier_identity == "current":
                return "current", earlier_start, reference_end
            chain_start = earlier_start
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
    if identity != "current":
        return False
    if end >= clause_start:
        return True
    return bool(
        re.fullmatch(
            r"[^.!?;\n]{0,240}\b(?:and|but|yet)\s*",
            value[end:position],
            re.IGNORECASE,
        )
        and not value[clause_start:position].strip()
    )


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


def _has_temporary_merge_restriction_tail(value: str) -> bool:
    return bool(
        re.match(
            r"\s+(?:until|unless|before|pending)\b",
            value,
            re.IGNORECASE,
        )
        or re.match(
            r"\s+while\b[^.!?;\n]{0,200}\b(?:is|remains)\s+pending\b",
            value,
            re.IGNORECASE,
        )
    )


def _has_fronted_temporary_merge_restriction(
    value: str,
    position: int,
) -> bool:
    start = _paragraph_start(value, position)
    prefix = value[start:position]
    reset = list(
        re.finditer(
            r"(?:,\s*(?:and|or|nor)\b|"
            r"\b(?:and|or|nor)\b(?=\s+(?:this|the|current|these|it|they)\b)|"
            r"\b(?:but|however|yet|whereas|therefore|thus|consequently|then|"
            r"nevertheless|nonetheless)\b)",
            prefix,
            re.IGNORECASE,
        )
    )
    if reset:
        prefix = prefix[reset[-1].end() :]
    return bool(
        re.match(
            r"\s*(?:until|unless|before)\b[^.!?;\n]{0,240},"
            r"[^.!?;\n]{0,160}$",
            prefix,
            re.IGNORECASE,
        )
        or re.match(
            r"\s*while\b[^.!?;\n]{0,200}\b(?:is|remains)\s+pending\b"
            r"[^.!?;\n]{0,80},[^.!?;\n]{0,160}$",
            prefix,
            re.IGNORECASE,
        )
        or re.match(
            r"\s*pending\b[^.!?;\n]{0,240},[^.!?;\n]{0,160}$",
            prefix,
            re.IGNORECASE,
        )
    )


def _is_historical_lifecycle_occurrence(value: str, position: int) -> bool:
    start, _end = _local_clause_bounds(value, position)
    prefix = value[start:position]
    historical = re.match(
        r"\s*(?:previously|formerly|historically|earlier)\b",
        prefix,
        re.IGNORECASE,
    )
    if historical is None:
        return False
    occurrence = value[position:]
    if re.match(
        r"(?:is|are|remains?|continues?\s+to\s+be|will\s+be|shall\s+be)\b",
        occurrence,
        re.IGNORECASE,
    ):
        return False
    remainder = prefix[historical.end() :]
    if re.search(
        r"\b(?:now|currently|presently|today)\b",
        remainder,
        re.IGNORECASE,
    ):
        return False
    comma = remainder.find(",")
    if comma >= 0 and remainder[:comma].strip():
        return bool(
            re.match(
                r"(?:was|were|had\s+been|hadn't\s+been|remained|became|"
                r"continued\s+to\s+be)\b",
                occurrence,
                re.IGNORECASE,
            )
        )
    return True


def _has_candidate_non_merge_contradiction(
    value: str,
    context: dict[str, object],
    *,
    allow_implicit_replacement: bool = False,
) -> bool:
    """Detect operative non-merge claims about the exact current PR candidate."""
    operative = _operative_lifecycle_prose(
        value,
        mask_non_link_brackets=True,
    )
    current_pattern = _current_candidate_reference_pattern(context)

    for action in LIFECYCLE_NEGATED_MERGE_ACTION_PATTERN.finditer(operative):
        if (
            _is_descriptive_occurrence(operative, action.start())
            or _is_historical_lifecycle_occurrence(operative, action.start())
            or _has_fronted_temporary_merge_restriction(
                operative,
                action.start(),
            )
        ):
            continue
        _clause_start, clause_end = _local_clause_bounds(operative, action.start())
        tail = operative[action.end() : clause_end]
        if _has_temporary_merge_restriction_tail(operative[action.end() :]):
            continue
        current_subject = _current_subject_before(
            operative, action.start(), current_pattern
        )
        if current_subject and LIFECYCLE_OTHER_MERGE_OBJECT_PATTERN.match(tail):
            current_subject = False
        if current_subject or _current_object_after(
            operative, action.end(), current_pattern
        ):
            return True

    for state in LIFECYCLE_NON_MERGE_STATE_PATTERN.finditer(operative):
        if (
            _is_descriptive_occurrence(operative, state.start())
            or _is_historical_lifecycle_occurrence(operative, state.start())
            or _has_fronted_temporary_merge_restriction(
                operative,
                state.start(),
            )
        ):
            continue
        _clause_start, clause_end = _local_clause_bounds(operative, state.start())
        tail = operative[state.end() : clause_end]
        if _has_temporary_merge_restriction_tail(operative[state.end() :]):
            continue
        if _current_subject_before(operative, state.start(), current_pattern):
            return True

    for prohibition in LIFECYCLE_PROHIBITED_MERGE_ACTION_PATTERN.finditer(operative):
        if (
            _is_descriptive_occurrence(operative, prohibition.start())
            or _is_historical_lifecycle_occurrence(
                operative,
                prohibition.start(),
            )
            or _has_fronted_temporary_merge_restriction(
                operative,
                prohibition.start(),
            )
        ):
            continue
        _clause_start, clause_end = _local_clause_bounds(
            operative,
            prohibition.start(),
        )
        tail = operative[prohibition.end() : clause_end]
        if _has_temporary_merge_restriction_tail(
            operative[prohibition.end() :]
        ):
            continue
        current_subject = _current_subject_before(
            operative, prohibition.start(), current_pattern
        )
        if current_subject and LIFECYCLE_OTHER_MERGE_OBJECT_PATTERN.match(tail):
            current_subject = False
        if current_subject or _current_object_after(
            operative,
            prohibition.end(),
            current_pattern,
        ):
            return True

    gerund_pattern = re.compile(
        rf"\bmerging\s+{current_pattern.pattern}\s+"
        r"(?:is|remains)\s+"
        r"(?:forbidden|prohibited|barred|disallowed|prevented|not\s+allowed)\b",
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
    reference_labels: frozenset[str],
) -> bool:
    """Detect a non-merge outcome with one-to-one post-merge action scoping."""
    fields = _parse_lifecycle_fields(
        _direct_lifecycle_section_body(value),
        allowed_labels=FINAL_DISPOSITION_FIELD_LABELS,
        reference_labels=reference_labels,
    )
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
    body: str,
    structure: str,
    context: dict[str, object],
    errors: list[str],
) -> None:
    """Validate local branch/issue metadata without relying on live GitHub state."""
    reference_labels = _markdown_reference_labels(body)
    primary = _section_content(structure, structure, "Primary issue") or ""
    primary_issues = PRIMARY_ISSUE_PATTERN.findall(primary)
    if not primary_issues:
        errors.append("lifecycle: name one primary issue as #<number> in '## Primary issue'")
        return
    if len(primary_issues) != 1:
        errors.append("lifecycle: '## Primary issue' must name exactly one #<number>")
        return
    primary_issue = primary_issues[0]

    merge_intention = (
        _section_content(body, structure, "Merge intention") or ""
    )
    is_merge, is_non_merge = _lifecycle_intentions(merge_intention)
    if is_non_merge == is_merge:
        errors.append(
            "lifecycle: state whether this branch is intended to merge or not intended to merge"
        )

    non_merge = (
        _section_content(body, structure, "Non-merge record") or ""
    )
    final_disposition = (
        _section_content(
            body, structure, "Rollback or final disposition"
        )
        or ""
    )
    direct_non_merge = _direct_lifecycle_section_body(non_merge)
    direct_final_disposition = _direct_lifecycle_section_body(final_disposition)
    non_merge_fields = _parse_lifecycle_fields(
        direct_non_merge,
        allowed_labels=NON_MERGE_FIELD_LABELS,
        reference_labels=reference_labels,
        location="non-merge record",
        errors=errors,
    )
    _validate_lifecycle_field_cardinality(
        non_merge_fields,
        NON_MERGE_REQUIRED_FIELD_LABELS,
        "non-merge record",
        errors,
    )
    final_disposition_fields = _parse_lifecycle_fields(
        direct_final_disposition,
        allowed_labels=FINAL_DISPOSITION_FIELD_LABELS,
        reference_labels=reference_labels,
        location="rollback or final disposition",
        errors=errors,
    )
    disposition_fields = {
        label.lower(): (
            _field_values(non_merge_fields, label)
            + _field_values(final_disposition_fields, label)
        )
        for label in FINAL_DISPOSITION_FIELD_LABELS
    }
    _validate_lifecycle_field_cardinality(
        disposition_fields,
        FINAL_DISPOSITION_FIELD_LABELS,
        "disposition metadata",
        errors,
    )
    _validate_disposition_alternatives(
        disposition_fields,
        "disposition metadata",
        errors,
    )
    if is_merge and (
        _field_values(non_merge_fields, "Purpose")
        or _field_values(non_merge_fields, "Exact candidate or workflow SHA")
        or _field_values(non_merge_fields, "Retained evidence")
        or _field_values(non_merge_fields, "Final disposition")
        or _field_values(non_merge_fields, "Close or deletion conditions")
    ):
        errors.append("lifecycle: merge-intended branch must not declare a non-merge record")
    if is_merge and _has_non_merge_final_disposition(
        direct_final_disposition,
        context,
        reference_labels,
    ):
        errors.append(
            "lifecycle: merge-intended branch must not declare a non-merge final disposition"
        )
    if is_merge and _has_candidate_non_merge_contradiction(body, context):
        errors.append(
            "lifecycle: merge-intended branch must not make a candidate-specific non-merge contradiction"
        )
    if is_non_merge and _has_operative_closes(body):
        errors.append("lifecycle: non-merge branch must not use 'Closes #<issue>'")

    exception = (
        _section_content(body, structure, "Lifecycle exception") or ""
    )
    direct_exception = _direct_lifecycle_section_body(exception)
    legacy_fields = _parse_lifecycle_fields(
        direct_exception,
        allowed_labels=LEGACY_FIELD_LABELS,
        reference_labels=reference_labels,
        location="legacy exception",
        errors=errors,
    )
    _validate_lifecycle_field_cardinality(
        legacy_fields,
        LEGACY_FIELD_LABELS,
        "legacy exception",
        errors,
    )
    head_ref = context.get("head_ref")
    legacy_declared = bool(legacy_fields) or (
        primary_issue == "47"
        and isinstance(head_ref, str)
        and head_ref not in {"dev", "main"}
        and BRANCH_ISSUE_PATTERN.search(head_ref) is None
    )
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
        if _single_lifecycle_field_value(legacy_fields, "Reason") is None:
            errors.append("lifecycle: legacy exception must state a reason")
        if (
            _single_lifecycle_field_value(legacy_fields, "Original branch identity")
            is None
        ):
            errors.append("lifecycle: legacy exception must state the original branch identity")
        original_primary_issue = _single_lifecycle_field_value(
            legacy_fields,
            "Original primary issue",
        )
        if original_primary_issue is None or re.fullmatch(
            r"(?:#[1-9][0-9]*|unknown)\.?",
            original_primary_issue,
        ) is None:
            errors.append("lifecycle: legacy exception must state the original primary issue or unknown")
        if _single_lifecycle_field_value(legacy_fields, "Retained evidence") is None:
            errors.append("lifecycle: legacy exception must state retained evidence")
        if (
            _single_lifecycle_field_value(legacy_fields, "Intended disposition")
            is None
        ):
            errors.append("lifecycle: legacy exception must state intended disposition")
        return

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
        if _single_lifecycle_field_value(non_merge_fields, "Purpose") is None:
            errors.append("lifecycle: non-merge branch must state its purpose")
        candidate = _has_exact_sha_field(non_merge_fields, "Exact candidate or workflow SHA")
        if candidate is None:
            errors.append("lifecycle: non-merge branch must state its exact candidate or workflow SHA")
        if (
            _single_lifecycle_field_value(non_merge_fields, "Retained evidence")
            is None
        ):
            errors.append("lifecycle: non-merge branch must state retained evidence")
        dispositions = (
            _field_values(non_merge_fields, "Final disposition")
            + _field_values(non_merge_fields, "Close or deletion conditions")
        )
        if len(dispositions) != 1 or not dispositions[0].strip():
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

    _validate_lifecycle(body, structure, context, errors)

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

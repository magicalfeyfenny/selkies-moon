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
    "Intent",
    "Scope",
    "Non-goals",
    "Risk",
    "Validation",
    "Rollback",
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
CONTROL_VALUES = {
    "lfs": {"not-applicable", "verified"},
    "generated_ownership": {"not-applicable", "verified"},
    "documentation": {"not-applicable", "updated", "verified-current"},
}
SHA_PATTERN = re.compile(r"[0-9a-f]{40}")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
REPOSITORY_PATTERN = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
AGENT_ID_PATTERN = re.compile(r"[A-Za-z0-9/][A-Za-z0-9._:/@-]{1,127}")
PLACEHOLDER_PATTERN = re.compile(
    r"(?:\b(?:todo|tbd|fixme|placeholder|changeme|replace[-_ ]?me)\b|"
    r"<[^>\n]+>|\{\{[^}\n]+\}\})",
    re.IGNORECASE,
)
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
    "art/runtime_package_manifest.json",
    "docs/AGENT_REVIEW_POLICY.md",
    "docs/ASSET_PIPELINE.md",
    "docs/BRANCH_AND_RELEASE_POLICY.md",
    "docs/DATA_FORMATS.md",
    "docs/LFS_MIGRATION.md",
    "tools/check_pr_governance.py",
    "tools/check_repository_hygiene.py",
    "tools/tests/test_check_pr_governance.py",
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
DOC_SUFFIXES = {".md", ".txt"}
TRUSTED_REVIEW_COMMENT_AUTHORS = {"magicalfeyfenny"}
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


def _matching_backtick_run_end(
    text: str,
    start: int,
    content_end: int,
    run_length: int,
) -> int | None:
    cursor = start
    while cursor < content_end:
        opening = text.find("`", cursor, content_end)
        if opening < 0:
            return None
        run_end = opening + 1
        while run_end < content_end and text[run_end] == "`":
            run_end += 1
        if run_end - opening == run_length:
            return run_end
        cursor = run_end
    return None


def _mask_markdown_code(text: str) -> str:
    """Mask Markdown code while preserving byte offsets and HTML comments."""
    characters = list(text)
    fence: tuple[str, int] | None = None
    in_html_comment = False
    offset = 0

    for raw_line in text.splitlines(keepends=True):
        line = raw_line.rstrip("\r\n")
        content_end = offset + len(line)

        if fence is not None:
            _mask_non_newlines(characters, offset, offset + len(raw_line))
            if _fence_closing(line, fence):
                fence = None
            offset += len(raw_line)
            continue

        if not in_html_comment:
            opening = _fence_opening(line)
            if opening is not None:
                fence = opening
                _mask_non_newlines(characters, offset, offset + len(raw_line))
                offset += len(raw_line)
                continue
            if _leading_indentation_columns(line) >= 4:
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
                closing_end = _matching_backtick_run_end(
                    text,
                    run_end,
                    content_end,
                    run_end - index,
                )
                if closing_end is None:
                    index = run_end
                else:
                    _mask_non_newlines(characters, index, closing_end)
                    index = closing_end
                continue
            index += 1
        offset += len(raw_line)

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


def _contains_raw_html_block(text: str) -> bool:
    comments_masked = _mask_html_comments_outside_code(text)
    return bool(RAW_HTML_BLOCK_PATTERN.search(_mask_markdown_code(comments_masked)))


def _is_top_level_position(text: str, position: int) -> bool:
    line_start = text.rfind("\n", 0, position) + 1
    prefix = text[line_start:position]
    prefix_without_comments = HTML_COMMENT_PATTERN.sub("", prefix)
    return bool(
        re.fullmatch(r"(?:-->[ \t]*)?", prefix_without_comments)
    )


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
        rf"^##[ \t]+{re.escape(section)}[ \t]*\r?$\n"
        rf"(?P<content>.*?)(?=^##[ \t]+|\Z)",
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(structure)
    if match is None:
        return None
    start, end = match.span("content")
    return body[start:end].strip()


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
    if _contains_raw_html_block(text):
        errors.append(
            f"{location}: raw HTML blocks cannot contain or accompany machine evidence"
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
        if not isinstance(login, str) or login.casefold() not in {
            value.casefold() for value in TRUSTED_REVIEW_COMMENT_AUTHORS
        }:
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
        or bool(re.fullmatch(r"release/v[0-9]+\.[0-9]+\.[0-9]+", head_branch))
        or bool(re.fullmatch(r"hotfix/[A-Za-z0-9._/-]+", head_branch))
    )


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

    if base_ref == "main":
        head_ref = context["head_ref"]
        if not isinstance(head_ref, str) or not _main_source_allowed(head_ref):
            errors.append("branch: PRs into main must come from dev, release/vX.Y.Z, or hotfix/*")
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
        if actual_base_is_ancestor is None:
            errors.append("branch: main-promotion base ancestry was not independently resolved")
        elif not actual_base_is_ancestor:
            errors.append(
                "branch: main-promotion head must contain the exact current main base"
            )
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
    stale_required_by_role: dict[str, dict[str, object]] = {}
    current_unkeyed: list[dict[str, object]] = []
    implementation_agent = contract.get("implementation_agent")
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
                # GitHub issue comments are oldest first. Only a newer review
                # bound to this same contract supersedes an earlier current
                # verdict; stale history can never erase a current blocker.
                current_by_role[role] = attestation
            else:
                current_unkeyed.append(attestation)
        elif isinstance(role, str) and role in required_roles:
            stale_required_by_role[role] = attestation

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
        _check_exact_keys(attestation, ATTESTATION_FIELDS, label, errors)
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
        if _contains_placeholder(attestation):
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
        elif any(not isinstance(item, str) or len(item.strip()) < 20 for item in evidence):
            errors.append(f"{label}: every evidence item must be a concrete string of at least 20 characters")

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
        if content is not None:
            visible = _mask_html_comments_outside_code(content).strip()
            if not visible:
                errors.append(f"body: section '## {section}' has no reviewable content")

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
        base_is_ancestor = (
            _is_ancestor(base["sha"], checkout_sha) if is_main_promotion else None
        )
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

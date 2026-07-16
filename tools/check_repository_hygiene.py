#!/usr/bin/env python3
"""Reject repository junk, oversized Git blobs, and unreachable packaged assets."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
PROJECT_NAME = "Selkie's Moon ~ until we meet again ~"
PROJECT_REL = PurePosixPath(PROJECT_NAME)
PROJECT = ROOT / PROJECT_NAME
YYP = PROJECT / "Selkies Moon.yyp"
PACKAGE_MANIFEST = ROOT / "art" / "runtime_package_manifest.json"
STAGE3D_MANIFEST = ROOT / "art" / "3d_stage_sources" / "stage_3d_runtime_buffer_manifest.json"
SCORE_MANIFEST = ROOT / "art" / "audio_production" / "score_manifest.json"
SFX_REPORT = ROOT / "art" / "audio_production" / "sfx_cue_sheets" / "sfx_install_report.json"

MAX_ORDINARY_GIT_BLOB_BYTES = 1024 * 1024
LFS_POINTER_LIMIT = 512
LFS_POINTER = re.compile(
    rb"version https://git-lfs.github.com/spec/v1\n"
    rb"oid sha256:(?P<oid>[0-9a-f]{64})\n"
    rb"size (?P<size>0|[1-9][0-9]*)\n"
)

RESOURCE_ROOTS = {
    "animcurves",
    "extensions",
    "folders",
    "fonts",
    "notes",
    "objects",
    "particles",
    "paths",
    "rooms",
    "scripts",
    "sequences",
    "shaders",
    "sounds",
    "sprites",
    "tilesets",
    "timelines",
}
JUNK_DIRECTORY_NAMES = {
    "__pycache__",
    "cache",
    "output",
    "screenshots",
    "superseded",
    "test-results",
    "tmp",
}
JUNK_FILENAMES = {
    ".ds_store",
    ".resource_order",
    "desktop.ini",
    "ehthumbs.db",
    "ehthumbs_vista.db",
    "thumbs.db",
    "thumbs.db:encryptable",
}
JUNK_SUFFIXES = (".bak", ".orig", ".pyc", ".pyo", ".rej", ".swp", ".tmp")
ALLOWED_INCLUDED_SUFFIXES = {".json", ".vbuff"}
RETIRED_PATH_PREFIXES = (
    f"{PROJECT_NAME}/timelines/tml_stage/",
)
RETIRED_PATHS = {
    "tools/regenerate_stage_timeline.zsh",
}
CONTROL_PATHS = {
    ".github/pull_request_template.md",
    ".github/workflows/gamemaker-tests.yml",
    "AGENTS.md",
    "art/3d_stage_sources/stage_3d_runtime_buffer_manifest.json",
    "art/audio_production/score_manifest.json",
    "art/audio_production/sfx_cue_sheets/sfx_install_report.json",
    "art/runtime_package_manifest.json",
    "docs/AGENT_REVIEW_POLICY.md",
    f"{PROJECT_NAME}/Selkies Moon.yyp",
    "tools/check_pr_governance.py",
    "tools/check_repository_hygiene.py",
    "tools/tests/test_check_pr_governance.py",
    "tools/tests/test_check_repository_hygiene.py",
}


def _run_git(*args: str, input_bytes: bytes | None = None) -> bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        input=input_bytes,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        command = "git " + " ".join(args)
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"{command} failed: {detail}")
    return result.stdout


def _decode_path(raw: bytes) -> str:
    return raw.decode("utf-8", errors="surrogateescape")


def _without_trailing_commas(text: str) -> str:
    """Remove GameMaker's trailing commas without changing string contents."""

    result: list[str] = []
    in_string = False
    escaped = False
    index = 0
    while index < len(text):
        character = text[index]
        if in_string:
            result.append(character)
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            index += 1
            continue
        if character == '"':
            in_string = True
            result.append(character)
            index += 1
            continue
        if character == ",":
            lookahead = index + 1
            while lookahead < len(text) and text[lookahead].isspace():
                lookahead += 1
            if lookahead < len(text) and text[lookahead] in "}]":
                index += 1
                continue
        result.append(character)
        index += 1
    return "".join(result)


def _load_json(path: Path, *, gamemaker: bool = False) -> object:
    text = path.read_text(encoding="utf-8")
    if gamemaker:
        text = _without_trailing_commas(text)
    return json.loads(text)


def _index_entries() -> dict[str, str]:
    entries: dict[str, str] = {}
    for record in _run_git("ls-files", "--stage", "-z").split(b"\0"):
        if not record:
            continue
        metadata, raw_path = record.split(b"\t", 1)
        _mode, sha, stage = metadata.decode("ascii").split()
        path = _decode_path(raw_path)
        if stage != "0":
            raise RuntimeError(f"unmerged index entry for {path} at stage {stage}")
        entries[path] = sha
    return entries


def _snapshot_findings() -> list[str]:
    findings: list[str] = []
    unstaged = [
        _decode_path(path)
        for path in _run_git("diff", "--name-only", "-z").split(b"\0")
        if path
    ]
    untracked = [
        _decode_path(path)
        for path in _run_git("ls-files", "--others", "--exclude-standard", "-z").split(b"\0")
        if path
    ]
    for path in unstaged:
        findings.append(f"snapshot: unstaged path would create a hybrid check: {path}")
    for path in untracked:
        findings.append(f"snapshot: untracked path would be absent from the checked index: {path}")
    return findings


def _filter_attributes(paths: Iterable[str]) -> dict[str, str]:
    path_list = list(paths)
    if not path_list:
        return {}
    payload = b"".join(path.encode("utf-8", errors="surrogateescape") + b"\0" for path in path_list)
    values = _run_git("check-attr", "--cached", "-z", "--stdin", "filter", input_bytes=payload).split(b"\0")
    if values and values[-1] == b"":
        values.pop()
    if len(values) != len(path_list) * 3:
        raise RuntimeError("git check-attr returned an unexpected record count")
    return {
        _decode_path(values[index]): values[index + 2].decode("utf-8", errors="replace")
        for index in range(0, len(values), 3)
    }


def _blob_sizes(shas: Iterable[str]) -> dict[str, int]:
    unique = sorted(set(shas))
    if not unique:
        return {}
    payload = ("\n".join(unique) + "\n").encode("ascii")
    output = _run_git("cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", input_bytes=payload)
    sizes: dict[str, int] = {}
    for line in output.decode("ascii").splitlines():
        sha, object_type, raw_size = line.split()
        if object_type != "blob":
            raise RuntimeError(f"index object {sha} is {object_type}, expected blob")
        sizes[sha] = int(raw_size)
    return sizes


def _blob_contents(shas: Iterable[str]) -> dict[str, bytes]:
    unique = sorted(set(shas))
    if not unique:
        return {}
    payload = ("\n".join(unique) + "\n").encode("ascii")
    output = _run_git("cat-file", "--batch", input_bytes=payload)
    contents: dict[str, bytes] = {}
    offset = 0
    for requested_sha in unique:
        header_end = output.find(b"\n", offset)
        if header_end < 0:
            raise RuntimeError(f"git cat-file omitted a header for {requested_sha}")
        header = output[offset:header_end].decode("ascii").split()
        if len(header) != 3 or header[1] != "blob":
            raise RuntimeError(f"git cat-file returned an invalid header for {requested_sha}")
        actual_sha, _object_type, raw_size = header
        size = int(raw_size)
        content_start = header_end + 1
        content_end = content_start + size
        contents[actual_sha] = output[content_start:content_end]
        if output[content_end:content_end + 1] != b"\n":
            raise RuntimeError(f"git cat-file returned an invalid blob terminator for {requested_sha}")
        offset = content_end + 1
    if offset != len(output):
        raise RuntimeError("git cat-file returned unexpected trailing data")
    return contents


def _is_lfs_pointer(content: bytes | None) -> bool:
    return bool(content is not None and LFS_POINTER.fullmatch(content))


def _junk_reason(path: str) -> str | None:
    pure = PurePosixPath(path)
    lowered_parts = [part.lower() for part in pure.parts]
    lowered_name = pure.name.lower()
    if lowered_name in JUNK_FILENAMES or pure.name.startswith("._"):
        return "platform or GameMaker metadata junk"
    if any(part in JUNK_DIRECTORY_NAMES for part in lowered_parts):
        return "generated, cache, review, or superseded directory"
    if lowered_name.endswith(JUNK_SUFFIXES) or lowered_name.endswith("~"):
        return "backup, editor, or Python cache file"
    if lowered_name.endswith(".old") or ".old." in lowered_name:
        return "obsolete GameMaker backup file"
    if path in RETIRED_PATHS or any(path.startswith(prefix) for prefix in RETIRED_PATH_PREFIXES):
        return "retired legacy production path"
    return None


def _escape_lfs_fetch_pattern(path: str) -> str:
    """Quote gitignore wildcard metacharacters in one literal LFS include path."""

    return "".join(f"\\{character}" if character in "\\*?[]" else character for character in path)


def _manifest_paths(data: object, field: str, errors: list[str]) -> set[str]:
    if not isinstance(data, dict) or not isinstance(data.get(field), list):
        errors.append(f"package: manifest field {field!r} must be an array")
        return set()
    paths: set[str] = set()
    for group_index, group in enumerate(data[field]):
        if not isinstance(group, dict):
            errors.append(f"package: {field}[{group_index}] must be an object")
            continue
        owner = group.get("owner")
        reason = group.get("reason")
        group_paths = group.get("paths")
        if not isinstance(owner, str) or not owner.strip():
            errors.append(f"package: {field}[{group_index}] has no owner")
        if not isinstance(reason, str) or not reason.strip():
            errors.append(f"package: {field}[{group_index}] has no reason")
        if not isinstance(group_paths, list) or not group_paths:
            errors.append(f"package: {field}[{group_index}].paths must be a nonempty array")
            continue
        for raw_path in group_paths:
            if not isinstance(raw_path, str):
                errors.append(f"package: {field}[{group_index}] contains a non-string path")
                continue
            path = PurePosixPath(raw_path)
            if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != "datafiles":
                errors.append(f"package: invalid project-relative datafile path {raw_path!r}")
                continue
            normalized = path.as_posix()
            if normalized in paths:
                errors.append(f"package: duplicate {field} path {normalized}")
            paths.add(normalized)
    return paths


def _check_git_storage(entries: dict[str, str], errors: list[str]) -> tuple[int, int, str, int]:
    ignored = [_decode_path(path) for path in _run_git("ls-files", "--cached", "--ignored", "--exclude-standard", "-z").split(b"\0") if path]
    for path in ignored:
        errors.append(f"junk: tracked path is ignored by repository rules: {path}")

    attributes = _filter_attributes(entries)
    sizes = _blob_sizes(entries.values())
    inspect_shas = {
        sha
        for path, sha in entries.items()
        if attributes.get(path) == "lfs" or sizes[sha] <= LFS_POINTER_LIMIT
    }
    contents = _blob_contents(inspect_shas)
    lfs_count = 0
    ordinary_count = 0
    largest_path = ""
    largest_size = -1
    for path, sha in entries.items():
        reason = _junk_reason(path)
        if reason:
            errors.append(f"junk: {path}: {reason}")
        size = sizes[sha]
        content = contents.get(sha)
        pointer = _is_lfs_pointer(content)
        if attributes.get(path) == "lfs":
            lfs_count += 1
            if not pointer:
                errors.append(f"lfs: {path} is covered by filter=lfs but its index blob is not a canonical pointer")
            continue
        ordinary_count += 1
        if pointer:
            errors.append(f"lfs: {path} contains an LFS pointer but is not covered by filter=lfs")
        if size > MAX_ORDINARY_GIT_BLOB_BYTES:
            errors.append(
                f"size: {path} stores {size:,} bytes in ordinary Git; maximum is "
                f"{MAX_ORDINARY_GIT_BLOB_BYTES:,} bytes"
            )
        if size > largest_size:
            largest_path = path
            largest_size = size
    return ordinary_count, lfs_count, largest_path, largest_size


def _check_range(base: str, errors: list[str]) -> int:
    _run_git("rev-parse", "--verify", f"{base}^{{commit}}")
    records = _run_git("rev-list", "--objects", f"{base}..HEAD").decode("utf-8", errors="surrogateescape").splitlines()
    object_paths: dict[str, str] = {}
    for record in records:
        sha, separator, path = record.partition(" ")
        object_paths.setdefault(sha, path if separator else "")
    if not object_paths:
        return 0
    payload = ("\n".join(object_paths) + "\n").encode("ascii")
    output = _run_git("cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", input_bytes=payload)
    blob_count = 0
    for line in output.decode("ascii").splitlines():
        sha, object_type, raw_size = line.split()
        if object_type != "blob":
            continue
        blob_count += 1
        size = int(raw_size)
        path = object_paths.get(sha, "")
        reason = _junk_reason(path) if path else None
        if reason:
            errors.append(f"history: {path} introduced repository junk in {base}..HEAD: {reason}")
        if size > MAX_ORDINARY_GIT_BLOB_BYTES:
            label = path or sha
            errors.append(
                f"history: {label} introduced a {size:,}-byte ordinary Git blob in {base}..HEAD; "
                "rewrite the branch so large payloads enter through LFS"
            )
    return blob_count


def _changed_lfs_paths(base: str, entries: dict[str, str]) -> list[str]:
    changed_paths = [
        _decode_path(path)
        for path in _run_git("diff", "--name-only", "--diff-filter=ACMR", "-z", f"{base}..HEAD").split(b"\0")
        if path and _decode_path(path) in entries
    ]
    attributes = _filter_attributes(changed_paths)
    return sorted(path for path in changed_paths if attributes.get(path) == "lfs")


def _check_changed_lfs_remote(
    base: str,
    remote: str,
    entries: dict[str, str],
    errors: list[str],
) -> int:
    lfs_paths = _changed_lfs_paths(base, entries)
    if not lfs_paths:
        return 0
    if any("," in path for path in lfs_paths):
        errors.append("lfs-remote: changed LFS paths containing commas cannot be safely batched")
        return 0

    try:
        _run_git(
            "lfs",
            "fetch",
            f"--include={','.join(_escape_lfs_fetch_pattern(path) for path in lfs_paths)}",
            "--exclude=",
            remote,
            "HEAD",
        )
    except RuntimeError as error:
        errors.append(f"lfs-remote: changed payload fetch failed: {error}")
        return 0

    contents = _blob_contents(entries[path] for path in lfs_paths)
    verified = 0
    for path in lfs_paths:
        pointer = contents.get(entries[path])
        match = LFS_POINTER.fullmatch(pointer or b"")
        if match is None:
            continue
        oid = match.group("oid").decode("ascii")
        declared_size = int(match.group("size"))
        raw_object_path = _run_git(
            "rev-parse",
            "--git-path",
            f"lfs/objects/{oid[:2]}/{oid[2:4]}/{oid}",
        ).decode("utf-8", errors="surrogateescape").strip()
        object_path = Path(raw_object_path)
        if not object_path.is_absolute():
            object_path = ROOT / object_path
        if not object_path.is_file():
            errors.append(f"lfs-remote: fetched payload is missing locally for {path} ({oid})")
            continue
        actual_size = object_path.stat().st_size
        if actual_size != declared_size:
            errors.append(
                f"lfs-remote: {path} declares {declared_size:,} bytes but fetched {actual_size:,}"
            )
            continue
        digest = hashlib.sha256()
        with object_path.open("rb") as payload:
            for chunk in iter(lambda: payload.read(1024 * 1024), b""):
                digest.update(chunk)
        if digest.hexdigest() != oid:
            errors.append(f"lfs-remote: fetched payload hash differs from pointer for {path}")
            continue
        verified += 1
    return verified


def _check_package(entries: dict[str, str], errors: list[str]) -> tuple[int, int]:
    for path in sorted(CONTROL_PATHS - set(entries)):
        errors.append(f"controls: required hygiene/package contract is not tracked: {path}")

    project_data = _load_json(YYP, gamemaker=True)
    package_data = _load_json(PACKAGE_MANIFEST)
    if not isinstance(project_data, dict):
        errors.append("package: YYP root must be an object")
        return 0, 0

    included_manifest = _manifest_paths(package_data, "included", errors)
    repository_only = _manifest_paths(package_data, "repository_only", errors)
    overlap = included_manifest & repository_only
    for path in sorted(overlap):
        errors.append(f"package: {path} is both included and repository-only")

    included_yyp: set[str] = set()
    included_records = project_data.get("IncludedFiles")
    if not isinstance(included_records, list):
        errors.append("package: YYP IncludedFiles must be an array")
        included_records = []
    for index, record in enumerate(included_records):
        if not isinstance(record, dict):
            errors.append(f"package: IncludedFiles[{index}] must be an object")
            continue
        file_path = record.get("filePath")
        name = record.get("name")
        if not isinstance(file_path, str) or not isinstance(name, str):
            errors.append(f"package: IncludedFiles[{index}] has no valid filePath/name")
            continue
        path = (PurePosixPath(file_path) / name).as_posix()
        if path in included_yyp:
            errors.append(f"package: duplicate YYP IncludedFile {path}")
        included_yyp.add(path)
        suffix = PurePosixPath(path).suffix.lower()
        if suffix not in ALLOWED_INCLUDED_SUFFIXES:
            errors.append(
                f"package: {path} has non-runtime IncludedFile type {suffix or '<none>'}; "
                f"allowed types are {', '.join(sorted(ALLOWED_INCLUDED_SUFFIXES))}"
            )
        if _junk_reason(f"{PROJECT_NAME}/{path}"):
            errors.append(f"package: {path} is classified as junk or retired")

    for path in sorted(included_manifest - included_yyp):
        errors.append(f"package: manifest-owned runtime file is missing from YYP: {path}")
    for path in sorted(included_yyp - included_manifest):
        errors.append(f"package: YYP includes an undeclared runtime file: {path}")

    datafile_prefix = f"{PROJECT_NAME}/datafiles/"
    tracked_datafiles = {
        path.removeprefix(f"{PROJECT_NAME}/")
        for path in entries
        if path.startswith(datafile_prefix)
    }
    declared_datafiles = included_manifest | repository_only
    for path in sorted(declared_datafiles - tracked_datafiles):
        errors.append(f"package: declared datafile is not tracked: {path}")
    for path in sorted(tracked_datafiles - declared_datafiles):
        errors.append(f"package: tracked datafile has no runtime/repository-only classification: {path}")

    stage3d_data = _load_json(STAGE3D_MANIFEST)
    if not isinstance(stage3d_data, list):
        errors.append("package: stage 3D runtime manifest must be an array")
    else:
        expected_vbuff = {
            f"datafiles/{record.get('runtime_buffer')}"
            for record in stage3d_data
            if isinstance(record, dict) and isinstance(record.get("runtime_buffer"), str)
        }
        expected_obj = {
            f"datafiles/{record.get('source_obj')}"
            for record in stage3d_data
            if isinstance(record, dict) and isinstance(record.get("source_obj"), str)
        }
        if expected_vbuff != {path for path in included_manifest if path.endswith(".vbuff")}:
            errors.append("package: runtime package manifest VBUFF set differs from the stage 3D buffer manifest")
        if expected_obj != {path for path in repository_only if path.endswith(".obj")}:
            errors.append("package: repository-only OBJ set differs from the stage 3D buffer manifest")

    resources = project_data.get("resources")
    if not isinstance(resources, list):
        errors.append("resources: YYP resources must be an array")
        resources = []
    registered_paths: set[str] = set()
    registered_names: set[str] = set()
    registered_resource_directories: set[str] = set()
    sound_resources: dict[str, str] = {}
    for index, record in enumerate(resources):
        identity = record.get("id") if isinstance(record, dict) else None
        if not isinstance(identity, dict):
            errors.append(f"resources: resources[{index}] has no id object")
            continue
        name = identity.get("name")
        path = identity.get("path")
        if not isinstance(name, str) or not isinstance(path, str):
            errors.append(f"resources: resources[{index}] has no valid name/path")
            continue
        if path in registered_paths:
            errors.append(f"resources: duplicate YYP resource path {path}")
        registered_paths.add(path)
        if name in registered_names:
            errors.append(f"resources: duplicate YYP resource name {name}")
        registered_names.add(name)
        resource_parent = PurePosixPath(path).parent.as_posix()
        registered_resource_directories.add(resource_parent)
        repo_path = f"{PROJECT_NAME}/{path}"
        if repo_path not in entries:
            errors.append(f"resources: registered metadata is not tracked: {path}")
        if path.startswith("sounds/"):
            sound_resources[name] = path

    folder_records = project_data.get("Folders")
    if not isinstance(folder_records, list):
        errors.append("resources: YYP Folders must be an array")
        folder_records = []
    registered_folder_paths: set[str] = set()
    for index, record in enumerate(folder_records):
        folder_path = record.get("folderPath") if isinstance(record, dict) else None
        if not isinstance(folder_path, str):
            errors.append(f"resources: Folders[{index}] has no valid folderPath")
            continue
        if folder_path in registered_folder_paths or folder_path in registered_paths:
            errors.append(f"resources: duplicate YYP folder/resource path {folder_path}")
        registered_folder_paths.add(folder_path)
        repo_path = f"{PROJECT_NAME}/{folder_path}"
        if repo_path not in entries:
            errors.append(f"resources: registered folder metadata is not tracked: {folder_path}")
    registered_paths |= registered_folder_paths

    tracked_resource_metadata = {
        path.removeprefix(f"{PROJECT_NAME}/")
        for path in entries
        if path.startswith(f"{PROJECT_NAME}/")
        and path.endswith(".yy")
        and len(PurePosixPath(path.removeprefix(f"{PROJECT_NAME}/")).parts) >= 2
        and PurePosixPath(path.removeprefix(f"{PROJECT_NAME}/")).parts[0] in RESOURCE_ROOTS
    }
    for path in sorted(tracked_resource_metadata - registered_paths):
        errors.append(f"resources: tracked GameMaker metadata is not registered in the YYP: {path}")

    for repo_path in sorted(entries):
        project_prefix = f"{PROJECT_NAME}/"
        if not repo_path.startswith(project_prefix):
            continue
        project_path = PurePosixPath(repo_path.removeprefix(project_prefix))
        if not project_path.parts or project_path.parts[0] not in RESOURCE_ROOTS:
            continue
        if project_path.parts[0] == "folders":
            if project_path.as_posix() not in registered_folder_paths:
                errors.append(f"resources: folder payload is not registered in the YYP: {project_path}")
            continue
        if len(project_path.parts) < 3:
            errors.append(f"resources: file is outside a resource-owned directory: {project_path}")
            continue
        owner_directory = PurePosixPath(*project_path.parts[:2]).as_posix()
        if owner_directory not in registered_resource_directories:
            errors.append(
                f"resources: file belongs to no registered GameMaker resource directory: {project_path}"
            )

    score_data = _load_json(SCORE_MANIFEST)
    sfx_data = _load_json(SFX_REPORT)
    music_ids: set[str] = set()
    music_records = score_data.get("cues", []) if isinstance(score_data, dict) else []
    if not isinstance(music_records, list):
        errors.append("audio: score manifest cues must be an array")
        music_records = []
    for index, cue in enumerate(music_records):
        sound_id = cue.get("runtime_sound_id") if isinstance(cue, dict) else None
        if not isinstance(sound_id, str) or not sound_id:
            errors.append(f"audio: score cue {index} has no runtime_sound_id")
            continue
        if sound_id in music_ids:
            errors.append(f"audio: duplicate score owner for {sound_id}")
        music_ids.add(sound_id)

    sfx_ids: set[str] = set()
    if not isinstance(sfx_data, list):
        errors.append("audio: SFX install report must be an array")
        sfx_data = []
    for index, cue in enumerate(sfx_data):
        sound_id = cue.get("resource") if isinstance(cue, dict) else None
        if not isinstance(sound_id, str) or not sound_id:
            errors.append(f"audio: SFX report entry {index} has no resource")
            continue
        if sound_id in sfx_ids:
            errors.append(f"audio: duplicate SFX owner for {sound_id}")
        sfx_ids.add(sound_id)
    for sound_id in sorted(music_ids & sfx_ids):
        errors.append(f"audio: sound resource has both score and SFX owners: {sound_id}")
    expected_sound_ids = music_ids | sfx_ids
    actual_sound_ids = set(sound_resources)
    for sound_id in sorted(expected_sound_ids - actual_sound_ids):
        errors.append(f"audio: manifest-owned sound resource is missing from YYP: {sound_id}")
    for sound_id in sorted(actual_sound_ids - expected_sound_ids):
        errors.append(f"audio: YYP sound resource has no score/SFX manifest owner: {sound_id}")

    for sound_id, metadata_path in sorted(sound_resources.items()):
        metadata = _load_json(PROJECT / metadata_path, gamemaker=True)
        if not isinstance(metadata, dict):
            errors.append(f"audio: {metadata_path} root must be an object")
            continue
        if metadata.get("name") != sound_id:
            errors.append(f"audio: {metadata_path} name does not match resource id {sound_id}")
        sound_file = metadata.get("soundFile")
        if not isinstance(sound_file, str) or not sound_file:
            errors.append(f"audio: {metadata_path} has no soundFile")
            continue
        expected_suffix = ".ogg" if sound_id in music_ids else ".wav"
        if PurePosixPath(sound_file).suffix.lower() != expected_suffix:
            errors.append(f"audio: {sound_id} must use {expected_suffix}, found {sound_file}")
        directory = PurePosixPath(metadata_path).parent
        payloads = {
            PurePosixPath(path).name
            for path in entries
            if path.startswith(f"{PROJECT_NAME}/{directory.as_posix()}/")
            and PurePosixPath(path).suffix.lower() in {".ogg", ".wav"}
        }
        if payloads != {sound_file}:
            errors.append(
                f"audio: {sound_id} payload set is {sorted(payloads)}, expected exactly [{sound_file!r}]"
            )
    return len(included_yyp), len(sound_resources)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--base",
        help="also reject oversized ordinary-Git blobs and junk introduced by BASE..HEAD, even if later deleted",
    )
    parser.add_argument(
        "--verify-lfs-remote",
        metavar="REMOTE",
        help="fetch and hash changed LFS payloads from REMOTE; requires --base",
    )
    parser.add_argument(
        "--forbid-changed-lfs",
        action="store_true",
        help="reject changed final-state LFS paths; requires --base and is intended for untrusted fork CI",
    )
    args = parser.parse_args()

    if (args.verify_lfs_remote or args.forbid_changed_lfs) and not args.base:
        parser.error("--verify-lfs-remote and --forbid-changed-lfs require --base")

    errors: list[str] = []
    try:
        snapshot_errors = _snapshot_findings()
        if snapshot_errors:
            print(f"Repository hygiene failed with {len(snapshot_errors)} finding(s):", file=sys.stderr)
            for error in snapshot_errors:
                print(f"- {error}", file=sys.stderr)
            return 1
        entries = _index_entries()
        ordinary_count, lfs_count, largest_path, largest_size = _check_git_storage(entries, errors)
        included_count, sound_count = _check_package(entries, errors)
        range_blob_count = _check_range(args.base, errors) if args.base else 0
        remote_lfs_count = (
            _check_changed_lfs_remote(args.base, args.verify_lfs_remote, entries, errors)
            if args.verify_lfs_remote
            else 0
        )
        if args.forbid_changed_lfs:
            for path in _changed_lfs_paths(args.base, entries):
                errors.append(
                    f"lfs-fork: untrusted fork changed LFS path {path}; "
                    "a maintainer must transfer and verify this payload on a same-repository branch"
                )
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"Repository hygiene could not run: {error}", file=sys.stderr)
        return 2

    if errors:
        print(f"Repository hygiene failed with {len(errors)} finding(s):", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    range_summary = f"; {range_blob_count} range blobs checked" if args.base else ""
    remote_summary = (
        f"; {remote_lfs_count} changed LFS payloads verified from {args.verify_lfs_remote}"
        if args.verify_lfs_remote
        else ""
    )
    print(
        "Repository hygiene passed: "
        f"{len(entries)} tracked paths; {ordinary_count} ordinary Git paths; {lfs_count} LFS paths; "
        f"largest ordinary blob {largest_size:,} bytes ({largest_path}); "
        f"{included_count} packaged datafiles; {sound_count} manifest-owned sounds"
        f"{range_summary}{remote_summary}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

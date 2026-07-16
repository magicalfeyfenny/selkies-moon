#!/usr/bin/env python3
"""Export GameMaker runtime PNGs from read-only Krita master documents.

The manifests are the asset catalog, the GameMaker ``.yy`` files are the
authority for frame and image-layer UUIDs, and ``.kra`` files are the only
pixel sources read by this tool.  Nothing in this module creates or modifies a
Krita master.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import uuid
import zipfile
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from xml.dom import minidom

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = ROOT / "Selkie's Moon ~ until we meet again ~"
SPRITE_ROOT = GAME_ROOT / "sprites"
RUNTIME_EXPORT_MANIFEST = ROOT / "art/krita_runtime_export_manifest.json"

FAMILY_MANIFESTS = {
    "core": ROOT / "art/core_pixel_sources/core_pixel_source_manifest.json",
    "enemy": ROOT / "art/enemy_sources/enemy_source_manifest.json",
    "story": ROOT / "art/story_background_sources/story_background_manifest.json",
    "stage3d": ROOT / "art/3d_stage_sources/textures/stage_3d_texture_manifest.json",
    "imported": ROOT / "art/imported_runtime_sources/sprite_source_manifest.json",
    "text": ROOT / "art/imported_runtime_sources/sprites/spr_text_arrow/manifest.json",
    "standalone": RUNTIME_EXPORT_MANIFEST,
}
GAMEPLAY_FAMILIES = frozenset({"core", "enemy", "story", "stage3d", "imported", "text"})
ALL_FAMILIES = frozenset(FAMILY_MANIFESTS)
EXPECTED_ALL_SPRITES = 77
EXPECTED_ALL_FRAMES = 84
EXPECTED_STANDALONE_ASSETS = 6
EXPECTED_SOURCE_ONLY_MASTERS = 9
EXPECTED_RUNTIME_PNG_TARGETS = 174


class KritaRuntimeError(RuntimeError):
    """A source, manifest, GameMaker layout, or export invariant failed."""


class KritaRuntimeCheckError(KritaRuntimeError):
    """One or more checked runtime PNGs differ from their Krita master."""


@dataclass(frozen=True)
class SpriteLayout:
    name: str
    directory: Path
    frames: tuple[str, ...]
    image_layer: str
    width: int
    height: int


@dataclass(frozen=True)
class OutputTarget:
    path: Path
    size: tuple[int, int]
    purpose: str


@dataclass(frozen=True)
class ExportJob:
    family: str
    sprite: str
    frame_index: int
    frame_uuid: str
    source: Path
    source_size: tuple[int, int]
    selected_krita_layer: str | None
    targets: tuple[OutputTarget, ...]

    @property
    def label(self) -> str:
        if self.family == "standalone":
            return f"standalone:{self.sprite}"
        return f"{self.family}:{self.sprite}[{self.frame_index}]"


@dataclass(frozen=True)
class ExportSummary:
    families: tuple[str, ...]
    sprite_count: int
    frame_count: int
    standalone_count: int
    target_count: int
    changed_count: int
    unchanged_count: int
    check: bool


def _read_json(path: Path, *, tolerant_trailing_commas: bool = False) -> Any:
    if not path.is_file():
        raise KritaRuntimeError(f"Required JSON file does not exist: {path}")
    text = path.read_text(encoding="utf-8-sig")
    if tolerant_trailing_commas:
        text = _without_trailing_commas(text)
    try:
        return json.loads(text)
    except json.JSONDecodeError as error:
        raise KritaRuntimeError(f"Cannot parse {path}: {error}") from error


def _without_trailing_commas(text: str) -> str:
    """Remove JSON trailing commas without changing commas inside strings."""

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


def _repo_path(value: str, *, field: str) -> Path:
    if not isinstance(value, str) or not value:
        raise KritaRuntimeError(f"Manifest field {field!r} must be a non-empty path")
    candidate = (ROOT / value).resolve()
    try:
        candidate.relative_to(ROOT)
    except ValueError as error:
        raise KritaRuntimeError(f"Manifest field {field!r} escapes the repository: {value}") from error
    return candidate


def _uuid(value: Any, *, field: str, yy_path: Path) -> str:
    if not isinstance(value, str):
        raise KritaRuntimeError(f"{yy_path}: {field} is not a UUID string")
    try:
        parsed = uuid.UUID(value)
    except ValueError as error:
        raise KritaRuntimeError(f"{yy_path}: {field} is not a UUID: {value!r}") from error
    canonical = str(parsed)
    if canonical != value.lower():
        raise KritaRuntimeError(f"{yy_path}: {field} is not a canonical UUID: {value!r}")
    return value


def _sprite_layout(sprite: str) -> SpriteLayout:
    if not isinstance(sprite, str) or not sprite:
        raise KritaRuntimeError(f"Invalid sprite name in manifest: {sprite!r}")
    directory = SPRITE_ROOT / sprite
    yy_path = directory / f"{sprite}.yy"
    document = _read_json(yy_path, tolerant_trailing_commas=True)
    if not isinstance(document, dict) or document.get("name") != sprite:
        raise KritaRuntimeError(f"{yy_path}: GameMaker sprite name does not match {sprite!r}")

    frame_records = document.get("frames")
    layer_records = document.get("layers")
    if not isinstance(frame_records, list) or not frame_records:
        raise KritaRuntimeError(f"{yy_path}: sprite must declare at least one frame")
    if not isinstance(layer_records, list) or len(layer_records) != 1:
        count = len(layer_records) if isinstance(layer_records, list) else "invalid"
        raise KritaRuntimeError(
            f"{yy_path}: KRA exporter requires exactly one declared GM image layer; found {count}"
        )

    frames = tuple(
        _uuid(frame.get("name"), field=f"frames[{index}].name", yy_path=yy_path)
        for index, frame in enumerate(frame_records)
        if isinstance(frame, dict)
    )
    if len(frames) != len(frame_records):
        raise KritaRuntimeError(f"{yy_path}: every frame record must be an object")
    layer = layer_records[0]
    if not isinstance(layer, dict):
        raise KritaRuntimeError(f"{yy_path}: image-layer record must be an object")
    image_layer = _uuid(layer.get("name"), field="layers[0].name", yy_path=yy_path)
    width = document.get("width")
    height = document.get("height")
    if not isinstance(width, int) or not isinstance(height, int) or width <= 0 or height <= 0:
        raise KritaRuntimeError(f"{yy_path}: invalid sprite dimensions {width!r} x {height!r}")
    return SpriteLayout(sprite, directory, frames, image_layer, width, height)


def _gm_targets(layout: SpriteLayout, frame_index: int) -> list[OutputTarget]:
    try:
        frame_uuid = layout.frames[frame_index]
    except IndexError as error:
        raise KritaRuntimeError(
            f"{layout.name}: manifest frame {frame_index} is outside its {len(layout.frames)} YY frames"
        ) from error
    size = (layout.width, layout.height)
    return [
        OutputTarget(layout.directory / f"{frame_uuid}.png", size, "GameMaker composite"),
        OutputTarget(
            layout.directory / "layers" / frame_uuid / f"{layout.image_layer}.png",
            size,
            "GameMaker image layer",
        ),
    ]


def _size(value: Any, *, field: str) -> tuple[int, int]:
    if (
        not isinstance(value, list)
        or len(value) != 2
        or not all(isinstance(number, int) and number > 0 for number in value)
    ):
        raise KritaRuntimeError(f"Manifest field {field!r} must be [positive width, positive height]")
    return value[0], value[1]


def _deduplicate_job_targets(targets: Iterable[OutputTarget]) -> tuple[OutputTarget, ...]:
    unique: dict[Path, OutputTarget] = {}
    for target in targets:
        resolved = target.path.resolve()
        try:
            resolved.relative_to(ROOT)
        except ValueError as error:
            raise KritaRuntimeError(f"Runtime target escapes the repository: {target.path}") from error
        previous = unique.get(resolved)
        if previous is not None and previous.size != target.size:
            raise KritaRuntimeError(
                f"Runtime target has conflicting sizes: {resolved} ({previous.size} and {target.size})"
            )
        unique.setdefault(resolved, OutputTarget(resolved, target.size, target.purpose))
    return tuple(unique.values())


def _one_frame_job(
    family: str,
    item: dict[str, Any],
    *,
    source_size_field: str | None = None,
) -> ExportJob:
    sprite = item.get("sprite")
    layout = _sprite_layout(sprite)
    if len(layout.frames) != 1:
        raise KritaRuntimeError(f"{family}:{sprite} must have exactly one frame, found {len(layout.frames)}")
    source = _repo_path(item.get("krita_source"), field=f"{family}.{sprite}.krita_source")
    source_size = (
        _size(item.get(source_size_field), field=f"{family}.{sprite}.{source_size_field}")
        if source_size_field
        else (layout.width, layout.height)
    )
    targets = _gm_targets(layout, 0)
    return ExportJob(
        family,
        sprite,
        0,
        layout.frames[0],
        source,
        source_size,
        None,
        _deduplicate_job_targets(targets),
    )


def _load_core() -> list[ExportJob]:
    records = _read_json(FAMILY_MANIFESTS["core"])
    if not isinstance(records, list):
        raise KritaRuntimeError("Core pixel source manifest must contain a list")
    jobs: list[ExportJob] = []
    for item in records:
        if not isinstance(item, dict):
            raise KritaRuntimeError("Core pixel source records must be objects")
        job = _one_frame_job(
            "core",
            item,
            source_size_field="size",
        )
        if job.source_size != job.targets[0].size:
            raise KritaRuntimeError(f"{job.label}: manifest size and GameMaker size differ")
        jobs.append(job)
    return jobs


def _load_enemy() -> list[ExportJob]:
    records = _read_json(FAMILY_MANIFESTS["enemy"])
    if not isinstance(records, list):
        raise KritaRuntimeError("Enemy source manifest must contain a list")
    jobs: list[ExportJob] = []
    for item in records:
        if not isinstance(item, dict):
            raise KritaRuntimeError("Enemy source records must be objects")
        jobs.append(
            _one_frame_job(
                "enemy",
                item,
            )
        )
    return jobs


def _load_story() -> list[ExportJob]:
    manifest = _read_json(FAMILY_MANIFESTS["story"])
    scenes = manifest.get("scenes") if isinstance(manifest, dict) else None
    if not isinstance(scenes, list):
        raise KritaRuntimeError("Story background manifest must contain a scenes list")
    jobs: list[ExportJob] = []
    for scene in scenes:
        if not isinstance(scene, dict):
            raise KritaRuntimeError("Story scene records must be objects")
        sprite = scene.get("sprite")
        theme = scene.get("theme")
        if not isinstance(theme, str) or not theme:
            raise KritaRuntimeError(f"story:{sprite} has no valid theme")
        layout = _sprite_layout(sprite)
        if len(layout.frames) != 1:
            raise KritaRuntimeError(f"story:{sprite} must have exactly one frame")
        author_size = _size(scene.get("author_size"), field=f"story.{sprite}.author_size")
        runtime_size = _size(scene.get("runtime_size"), field=f"story.{sprite}.runtime_size")
        if runtime_size != (author_size[0] * 2, author_size[1] * 2):
            raise KritaRuntimeError(f"story:{sprite} must use an exact 2x author-to-runtime scale")
        if runtime_size != (layout.width, layout.height):
            raise KritaRuntimeError(f"story:{sprite} runtime size does not match its GameMaker YY")
        source = _repo_path(scene.get("krita_source"), field=f"story.{sprite}.krita_source")
        targets = _gm_targets(layout, 0)
        jobs.append(
            ExportJob(
                "story",
                sprite,
                0,
                layout.frames[0],
                source,
                author_size,
                None,
                _deduplicate_job_targets(targets),
            )
        )
    return jobs


def _load_stage3d() -> list[ExportJob]:
    records = _read_json(FAMILY_MANIFESTS["stage3d"])
    if not isinstance(records, list):
        raise KritaRuntimeError("3D stage texture manifest must contain a list")
    jobs: list[ExportJob] = []
    for item in records:
        if not isinstance(item, dict):
            raise KritaRuntimeError("3D stage texture records must be objects")
        job = _one_frame_job(
            "stage3d",
            item,
            source_size_field="resolution",
        )
        if job.source_size != job.targets[0].size:
            raise KritaRuntimeError(f"{job.label}: texture resolution and GameMaker size differ")
        jobs.append(job)
    return jobs


def _load_imported() -> list[ExportJob]:
    records = _read_json(FAMILY_MANIFESTS["imported"])
    if not isinstance(records, list):
        raise KritaRuntimeError("Imported runtime source manifest must contain a list")
    jobs: list[ExportJob] = []
    for record in records:
        if not isinstance(record, dict):
            raise KritaRuntimeError("Imported runtime source records must be objects")
        sprite = record.get("sprite")
        layout = _sprite_layout(sprite)
        frame_records = record.get("frames")
        if not isinstance(frame_records, list) or len(frame_records) != len(layout.frames):
            raise KritaRuntimeError(
                f"imported:{sprite} manifest has {len(frame_records) if isinstance(frame_records, list) else 'invalid'} "
                f"frames, YY has {len(layout.frames)}"
            )
        for frame_record in frame_records:
            if not isinstance(frame_record, dict) or not isinstance(frame_record.get("frame"), int):
                raise KritaRuntimeError(f"imported:{sprite} has an invalid frame record")
            frame_index = frame_record["frame"]
            if not 0 <= frame_index < len(layout.frames):
                raise KritaRuntimeError(f"imported:{sprite} frame index is out of range: {frame_index}")
            source = _repo_path(
                frame_record.get("krita_source"),
                field=f"imported.{sprite}.frames[{frame_index}].krita_source",
            )
            source_size = _size(
                frame_record.get("size"),
                field=f"imported.{sprite}.frames[{frame_index}].size",
            )
            if source_size != (layout.width, layout.height):
                raise KritaRuntimeError(f"imported:{sprite}[{frame_index}] source size differs from YY size")
            targets = _gm_targets(layout, frame_index)
            for field in ("runtime_png",):
                if field in frame_record:
                    targets.append(
                        OutputTarget(
                            _repo_path(
                                frame_record[field],
                                field=f"imported.{sprite}.frames[{frame_index}].{field}",
                            ),
                            source_size,
                            field,
                        )
                    )
            jobs.append(
                ExportJob(
                    "imported",
                    sprite,
                    frame_index,
                    layout.frames[frame_index],
                    source,
                    source_size,
                    None,
                    _deduplicate_job_targets(targets),
                )
            )
    return jobs


def _load_standalone() -> list[ExportJob]:
    manifest = _read_json(FAMILY_MANIFESTS["standalone"])
    if not isinstance(manifest, dict):
        raise KritaRuntimeError("Krita runtime export manifest must contain an object")
    policy = manifest.get("policy")
    if not isinstance(policy, dict) or policy.get("normal_build_may_write_kra") is not False:
        raise KritaRuntimeError("Krita runtime manifest must forbid normal builds from writing KRA")
    records = manifest.get("standalone")
    if not isinstance(records, list):
        raise KritaRuntimeError("Krita runtime export manifest must contain a standalone list")

    jobs: list[ExportJob] = []
    for record in records:
        if not isinstance(record, dict):
            raise KritaRuntimeError("Standalone Krita records must be objects")
        asset_id = record.get("asset_id")
        if not isinstance(asset_id, str) or not asset_id:
            raise KritaRuntimeError("Standalone Krita record has no asset_id")
        source = _repo_path(record.get("master_kra"), field=f"standalone.{asset_id}.master_kra")
        target = _repo_path(record.get("export_png"), field=f"standalone.{asset_id}.export_png")
        size = _size(record.get("size"), field=f"standalone.{asset_id}.size")
        metrics = record.get("metrics")
        if metrics is not None:
            metrics_path = _repo_path(metrics, field=f"standalone.{asset_id}.metrics")
            if not metrics_path.is_file():
                raise KritaRuntimeError(f"standalone:{asset_id} metrics file does not exist: {metrics_path}")
        jobs.append(
            ExportJob(
                "standalone",
                asset_id,
                0,
                "",
                source,
                size,
                None,
                (OutputTarget(target, size, "standalone export"),),
            )
        )
    return jobs


def _load_text() -> list[ExportJob]:
    manifest = _read_json(FAMILY_MANIFESTS["text"])
    if not isinstance(manifest, dict):
        raise KritaRuntimeError("Text-arrow manifest must contain an object")
    sprite = manifest.get("sprite")
    layout = _sprite_layout(sprite)
    frame_records = manifest.get("frames")
    layer_names = manifest.get("layers")
    if not isinstance(frame_records, list) or len(frame_records) != len(layout.frames):
        raise KritaRuntimeError(f"text:{sprite} manifest frame count differs from YY")
    if not isinstance(layer_names, list) or len(layer_names) != len(layout.frames):
        raise KritaRuntimeError(f"text:{sprite} requires one named Krita layer per YY frame")
    source = _repo_path(manifest.get("krita_source"), field=f"text.{sprite}.krita_source")
    source_size = _size(manifest.get("source_size"), field=f"text.{sprite}.source_size")
    if source_size != (layout.width, layout.height):
        raise KritaRuntimeError(f"text:{sprite} KRA canvas size must match its GameMaker YY size")

    jobs: list[ExportJob] = []
    seen_indices: set[int] = set()
    for frame_record in frame_records:
        if not isinstance(frame_record, dict) or not isinstance(frame_record.get("frame"), int):
            raise KritaRuntimeError(f"text:{sprite} has an invalid frame record")
        frame_index = frame_record["frame"]
        if frame_index in seen_indices or not 0 <= frame_index < len(layout.frames):
            raise KritaRuntimeError(f"text:{sprite} has a duplicate or invalid frame index: {frame_index}")
        seen_indices.add(frame_index)
        layer_name = layer_names[frame_index]
        if not isinstance(layer_name, str) or not layer_name.startswith(f"Frame {frame_index:02d}"):
            raise KritaRuntimeError(
                f"text:{sprite}[{frame_index}] must map to a Krita layer beginning with "
                f"'Frame {frame_index:02d}', found {layer_name!r}"
            )
        targets = _gm_targets(layout, frame_index)
        if "runtime_png" in frame_record:
            targets.append(
                OutputTarget(
                    _repo_path(
                        frame_record["runtime_png"],
                        field=f"text.{sprite}.frames[{frame_index}].runtime_png",
                    ),
                    source_size,
                    "runtime_png",
                )
            )
        jobs.append(
            ExportJob(
                "text",
                sprite,
                frame_index,
                layout.frames[frame_index],
                source,
                source_size,
                layer_name,
                _deduplicate_job_targets(targets),
            )
        )
    return jobs


LOADERS: dict[str, Callable[[], list[ExportJob]]] = {
    "core": _load_core,
    "enemy": _load_enemy,
    "story": _load_story,
    "stage3d": _load_stage3d,
    "imported": _load_imported,
    "text": _load_text,
    "standalone": _load_standalone,
}


def _validate_source_only_masters() -> None:
    """Validate registered editable masters that intentionally have no PNG output."""

    manifest = _read_json(RUNTIME_EXPORT_MANIFEST)
    records = manifest.get("source_only_masters") if isinstance(manifest, dict) else None
    if not isinstance(records, list) or len(records) != EXPECTED_SOURCE_ONLY_MASTERS:
        found = len(records) if isinstance(records, list) else "invalid"
        raise KritaRuntimeError(
            "Source-only KRA catalog coverage changed unexpectedly: "
            f"found {found}, expected {EXPECTED_SOURCE_ONLY_MASTERS}."
        )
    asset_ids: set[str] = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            raise KritaRuntimeError(f"source_only_masters[{index}] must be an object")
        asset_id = record.get("asset_id")
        if not isinstance(asset_id, str) or not asset_id or asset_id in asset_ids:
            raise KritaRuntimeError(f"source_only_masters[{index}] has an invalid or duplicate asset_id")
        asset_ids.add(asset_id)
        master = _repo_path(record.get("master_kra"), field=f"source_only_masters.{asset_id}.master_kra")
        if master.suffix.lower() != ".kra" or not master.is_file():
            raise KritaRuntimeError(f"source-only master is not an existing KRA: {master}")


def _collect_jobs(families: frozenset[str]) -> list[ExportJob]:
    jobs: list[ExportJob] = []
    for family in FAMILY_MANIFESTS:
        if family in families:
            jobs.extend(LOADERS[family]())
    if not jobs:
        raise KritaRuntimeError("No Krita runtime export jobs were selected")

    gameplay_jobs = [job for job in jobs if job.family in GAMEPLAY_FAMILIES]
    sprites = {(job.family, job.sprite) for job in gameplay_jobs}
    if GAMEPLAY_FAMILIES.issubset(families):
        if len(sprites) != EXPECTED_ALL_SPRITES or len(gameplay_jobs) != EXPECTED_ALL_FRAMES:
            raise KritaRuntimeError(
                "Full KRA runtime catalog coverage changed unexpectedly: "
                f"found {len(sprites)} sprites/{len(gameplay_jobs)} frames, expected "
                f"{EXPECTED_ALL_SPRITES}/{EXPECTED_ALL_FRAMES}. Update the manifest coverage "
                "and reviewed expectations together."
            )
    standalone_count = sum(job.family == "standalone" for job in jobs)
    if "standalone" in families and standalone_count != EXPECTED_STANDALONE_ASSETS:
        raise KritaRuntimeError(
            "Standalone KRA catalog coverage changed unexpectedly: "
            f"found {standalone_count}, expected {EXPECTED_STANDALONE_ASSETS}. "
            "Update the registry and reviewed expectation together."
        )
    if "standalone" in families:
        _validate_source_only_masters()

    target_owners: dict[Path, str] = {}
    for job in jobs:
        if job.source.suffix.lower() != ".kra":
            raise KritaRuntimeError(f"{job.label}: master is not a .kra file: {job.source}")
        if not job.source.is_file():
            raise KritaRuntimeError(f"{job.label}: Krita master does not exist: {job.source}")
        for target in job.targets:
            previous = target_owners.get(target.path)
            if previous is not None and previous != job.label:
                raise KritaRuntimeError(
                    f"Duplicate runtime target {target.path} is owned by both {previous} and {job.label}"
                )
            target_owners[target.path] = job.label
    if families == ALL_FAMILIES and len(target_owners) != EXPECTED_RUNTIME_PNG_TARGETS:
        raise KritaRuntimeError(
            "Full runtime PNG target coverage changed unexpectedly: "
            f"found {len(target_owners)}, expected {EXPECTED_RUNTIME_PNG_TARGETS}."
        )
    return jobs


def _runtime_png_roots() -> tuple[Path, ...]:
    """Load and validate the registry roots whose PNGs require declared owners."""

    manifest = _read_json(RUNTIME_EXPORT_MANIFEST)
    configured = manifest.get("runtime_png_roots") if isinstance(manifest, dict) else None
    if not isinstance(configured, list):
        raise KritaRuntimeError(
            f"{RUNTIME_EXPORT_MANIFEST}: required top-level runtime_png_roots must be a list"
        )

    roots: dict[Path, None] = {}
    for index, value in enumerate(configured):
        root = _repo_path(value, field=f"runtime_png_roots[{index}]")
        if not root.exists():
            raise KritaRuntimeError(f"runtime_png_roots[{index}] does not exist: {root}")
        if not root.is_dir():
            raise KritaRuntimeError(f"runtime_png_roots[{index}] is not a directory: {root}")
        roots.setdefault(root, None)
    return tuple(roots)


def _unowned_paths(discovered: Iterable[Path], declared: Iterable[Path]) -> tuple[Path, ...]:
    """Return a deterministic set difference over resolved filesystem paths."""

    declared_paths = {path.resolve() for path in declared}
    unowned = {path.resolve() for path in discovered if path.resolve() not in declared_paths}
    return tuple(
        sorted(
            unowned,
            key=lambda path: (
                path.relative_to(ROOT).as_posix().casefold(),
                path.relative_to(ROOT).as_posix(),
            ),
        )
    )


def _unowned_runtime_pngs(jobs: Iterable[ExportJob]) -> tuple[Path, ...]:
    declared = [target.path for job in jobs for target in job.targets]
    discovered: list[Path] = []
    for root in _runtime_png_roots():
        for candidate in root.rglob("*"):
            if not candidate.is_file() or candidate.suffix.lower() != ".png":
                continue
            resolved = candidate.resolve()
            try:
                resolved.relative_to(ROOT)
            except ValueError as error:
                raise KritaRuntimeError(
                    f"Runtime PNG under configured root escapes the repository: {candidate}"
                ) from error
            discovered.append(resolved)
    return _unowned_paths(discovered, declared)


def _check_runtime_png_ownership(jobs: Iterable[ExportJob]) -> None:
    unowned = _unowned_runtime_pngs(jobs)
    if not unowned:
        return
    listing = "\n".join(f"  - {path.relative_to(ROOT).as_posix()}" for path in unowned)
    raise KritaRuntimeCheckError(
        f"{len(unowned)} unowned runtime PNG(s) are not declared export targets:\n{listing}"
    )


def _find_krita() -> Path:
    configured = os.environ.get("KRITA_BIN")
    candidates: list[Path] = []
    if configured:
        configured_path = Path(configured).expanduser()
        located = shutil.which(configured) if configured_path.parent == Path(".") else None
        candidates.append(Path(located) if located else configured_path)
    located = shutil.which("krita")
    if located:
        candidates.append(Path(located))
    candidates.append(Path("/Applications/Krita.app/Contents/MacOS/krita"))
    for candidate in candidates:
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return candidate.resolve()
    attempted = ", ".join(str(candidate) for candidate in candidates)
    raise KritaRuntimeError(
        "Krita is required for runtime export. Install Krita or set KRITA_BIN. "
        f"Tried: {attempted}"
    )


def _patch_kra_visibility(source: Path, destination: Path, selected_layer: str) -> None:
    """Copy a KRA and alter only the temporary copy's paint-layer visibility."""

    try:
        with zipfile.ZipFile(source, "r") as archive:
            if archive.read("mimetype").strip() != b"application/x-krita":
                raise KritaRuntimeError(f"Not a Krita archive: {source}")
            xml_bytes = archive.read("maindoc.xml")
            document = minidom.parseString(xml_bytes)
            paint_layers = [
                node
                for node in document.getElementsByTagName("layer")
                if node.getAttribute("nodetype") == "paintlayer"
            ]
            matches = [node for node in paint_layers if node.getAttribute("name") == selected_layer]
            if len(matches) != 1:
                available = [node.getAttribute("name") for node in paint_layers]
                raise KritaRuntimeError(
                    f"{source}: expected exactly one Krita layer {selected_layer!r}; "
                    f"available layers: {available}"
                )
            for node in paint_layers:
                node.setAttribute("visible", "1" if node is matches[0] else "0")
            patched_xml = document.toxml(encoding="UTF-8")

            destination.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(destination, "w") as patched:
                for member in archive.infolist():
                    data = patched_xml if member.filename == "maindoc.xml" else archive.read(member.filename)
                    patched.writestr(member, data)
    except (KeyError, zipfile.BadZipFile, minidom.ExpatError) as error:
        raise KritaRuntimeError(f"Cannot create temporary visibility view of {source}: {error}") from error


def _krita_environment(stage_root: Path) -> tuple[dict[str, str], Path]:
    config = stage_root / "krita-config"
    data = stage_root / "krita-data"
    cache = stage_root / "krita-cache"
    resources = stage_root / "krita-resources"
    for directory in (config, data, cache, resources):
        directory.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment.update({
        "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data),
        "XDG_CACHE_HOME": str(cache),
    })
    return environment, resources


def _run_krita_export(
    executable: Path,
    source: Path,
    destination: Path,
    *,
    environment: dict[str, str],
    resources: Path,
    timeout: int = 180,
) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(executable),
        "--nosplash",
        "--resource-location",
        str(resources),
        "--export",
        "--export-filename",
        str(destination),
        str(source),
    ]
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            env=environment,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as error:
        raise KritaRuntimeError(f"Krita timed out exporting {source}") from error
    if result.returncode != 0 or not destination.is_file():
        details = "\n".join(
            part.strip() for part in (result.stdout, result.stderr) if part.strip()
        )
        raise KritaRuntimeError(
            f"Krita failed to export {source} (exit {result.returncode})"
            + (f":\n{details}" if details else "")
        )


def _rgba(path: Path) -> tuple[tuple[int, int], bytes]:
    try:
        with Image.open(path) as image:
            rgba = image.convert("RGBA")
            return rgba.size, rgba.tobytes()
    except (OSError, ValueError) as error:
        raise KritaRuntimeError(f"Cannot decode PNG {path}: {error}") from error


def _equivalent(left: Path, right: Path) -> bool:
    if not left.is_file() or not right.is_file():
        return False
    left_size, left_pixels = _rgba(left)
    right_size, right_pixels = _rgba(right)
    if left_size != right_size or len(left_pixels) != len(right_pixels):
        return False
    if left_pixels == right_pixels:
        return True
    for offset in range(0, len(left_pixels), 4):
        left_alpha = left_pixels[offset + 3]
        right_alpha = right_pixels[offset + 3]
        if left_alpha != right_alpha:
            return False
        if left_alpha == 0:
            continue
        if left_pixels[offset:offset + 3] != right_pixels[offset:offset + 3]:
            return False
    return True


def _stage_target(source_png: Path, destination: Path, size: tuple[int, int]) -> None:
    try:
        with Image.open(source_png) as image:
            rgba = image.convert("RGBA")
            if rgba.size != size:
                rgba = rgba.resize(size, resample=Image.Resampling.NEAREST)
            destination.parent.mkdir(parents=True, exist_ok=True)
            rgba.save(destination, format="PNG", optimize=False, compress_level=9)
    except (OSError, ValueError) as error:
        raise KritaRuntimeError(f"Cannot stage runtime PNG {destination}: {error}") from error


def _selected_families(families: set[str] | None) -> frozenset[str]:
    selected = ALL_FAMILIES if families is None else frozenset(families)
    unknown = selected - ALL_FAMILIES
    if unknown:
        raise KritaRuntimeError(f"Unknown KRA runtime families: {', '.join(sorted(unknown))}")
    if not selected:
        raise KritaRuntimeError("At least one KRA runtime family must be selected")
    return selected


def export_assets(
    families: set[str] | None = None,
    check: bool = False,
    *,
    progress: Callable[[str], None] | None = None,
) -> ExportSummary:
    """Export or verify runtime art for the selected manifest families.

    In export mode every output is staged first and only pixel-different files
    are atomically replaced.  Check mode performs the same Krita render and
    decoded-RGBA comparison but never writes outside its temporary directory.
    """

    selected = _selected_families(families)
    jobs = _collect_jobs(selected)
    if check:
        ownership_jobs = jobs if selected == ALL_FAMILIES else _collect_jobs(ALL_FAMILIES)
        _check_runtime_png_ownership(ownership_jobs)
    executable = _find_krita()
    sprite_count = len({(job.family, job.sprite) for job in jobs if job.family in GAMEPLAY_FAMILIES})
    frame_count = sum(job.family in GAMEPLAY_FAMILIES for job in jobs)
    standalone_count = sum(job.family == "standalone" for job in jobs)
    target_count = sum(len(job.targets) for job in jobs)
    changed: list[tuple[Path, Path]] = []
    unchanged_count = 0
    mismatches: list[str] = []
    temp_parent = ROOT / "tmp"
    temp_parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="krita-runtime-", dir=temp_parent) as temporary:
        stage_root = Path(temporary)
        environment, resources = _krita_environment(stage_root)
        for ordinal, job in enumerate(jobs, start=1):
            if progress:
                progress(f"[{ordinal}/{len(jobs)}] {job.label}")
            render_source = job.source
            if job.selected_krita_layer is not None:
                render_source = stage_root / "views" / f"{ordinal:03d}-{job.sprite}-{job.frame_index}.kra"
                _patch_kra_visibility(job.source, render_source, job.selected_krita_layer)
            rendered = stage_root / "renders" / f"{ordinal:03d}-{job.sprite}-{job.frame_index}.png"
            _run_krita_export(
                executable,
                render_source,
                rendered,
                environment=environment,
                resources=resources,
            )
            rendered_size, _ = _rgba(rendered)
            if rendered_size != job.source_size:
                raise KritaRuntimeError(
                    f"{job.label}: Krita rendered {rendered_size}, expected KRA canvas {job.source_size}"
                )

            for target_index, target in enumerate(job.targets):
                staged = stage_root / "outputs" / f"{ordinal:03d}-{target_index:02d}.png"
                _stage_target(rendered, staged, target.size)
                if _equivalent(staged, target.path):
                    unchanged_count += 1
                    continue
                if check:
                    reason = "missing" if not target.path.is_file() else "pixel mismatch"
                    mismatches.append(f"{job.label}: {reason}: {target.path.relative_to(ROOT)}")
                else:
                    changed.append((staged, target.path))

        if mismatches:
            preview = "\n".join(f"  - {message}" for message in mismatches[:30])
            remainder = len(mismatches) - 30
            if remainder > 0:
                preview += f"\n  - ... and {remainder} more"
            raise KritaRuntimeCheckError(
                f"{len(mismatches)} runtime PNG target(s) differ from their KRA masters:\n{preview}"
            )

        if not check:
            for staged, target in changed:
                target.parent.mkdir(parents=True, exist_ok=True)
                os.replace(staged, target)

    return ExportSummary(
        tuple(sorted(selected)),
        sprite_count,
        frame_count,
        standalone_count,
        target_count,
        0 if check else len(changed),
        unchanged_count,
        check,
    )


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Export GameMaker runtime PNGs from read-only native Krita masters."
    )
    parser.add_argument(
        "--family",
        action="append",
        choices=tuple(FAMILY_MANIFESTS),
        help="Export only this asset family; repeat for multiple families (default: all).",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Render to temporary files and fail if tracked PNGs do not match; write nothing.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        summary = export_assets(
            set(arguments.family) if arguments.family else None,
            check=arguments.check,
            progress=print,
        )
    except KritaRuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    verb = "verified" if summary.check else "exported"
    print(
        f"KRA runtime {verb}: {summary.sprite_count} sprites, {summary.frame_count} frames, "
        f"{summary.standalone_count} standalone assets, "
        f"{summary.target_count} targets; {summary.changed_count} changed, "
        f"{summary.unchanged_count} unchanged."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

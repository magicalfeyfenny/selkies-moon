# Repository Guidance

This file contains only Selkie's Moon rules. Higher-priority platform and user
instructions still apply.

## Authority and cold start

Use this order when repository sources disagree:

1. the active task and this file for scope and process;
2. [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) for the current supported and
   incomplete state;
3. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for subsystem ownership and task
   routing;
4. the relevant subsystem guide for behavior and data contracts;
5. project-owned `/// @func` contracts, executable code, and tests for the
   implemented behavior.

Treat a code/document disagreement as drift to resolve, not permission to
silently choose whichever source is convenient.

For a new task:

1. read `docs/PROJECT_STATE.md`;
2. read only the matching row and linked section in `docs/ARCHITECTURE.md`;
3. inspect `git status --short` and preserve unrelated work;
4. open the named owner files and their focused tests.

Do not read every guide or enumerate the full resource tree during onboarding.

## Scope boundaries

- The GameMaker project is
  `Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp`.
- New resources need the implementation file, matching `.yy`, and `.yyp`
  registration. Review metadata diffs for accidental IDE churn.
- Do not hand-edit binary image, audio, Krita, Blender, or archive data.
- Keep object events orchestration-focused; shared behavior belongs in the
  owning script named by `docs/ARCHITECTURE.md`.
- Preserve persistence through explicit versioned migrations and tests.
- `GMTL_*` scripts are vendored test-library code and are out of normal refactor
  scope.

Normally ignore `.git/`, `output/`, `cache/`, `test-results/`, `tmp/`, and
platform build products. For code tasks, also avoid `art/`, `sprites/`,
`sounds/`, and generated source manifests unless the routed owner or task
requires them.

## Validation and continuity

Choose the smallest sufficient validation tier from
[`docs/VALIDATION.md`](docs/VALIDATION.md). Every governance or documentation
change must run:

```zsh
python3 tools/check_governance.py
git diff --check
```

Runtime changes normally require the full GMTL suite. Asset and release checks
are task-specific; do not launch local GUI tooling merely to inspect structure.

A completed commit with explicit validation is the normal durable handoff. If
work must stop in a non-obvious state, create a task-specific note from
[`docs/HANDOFF_TEMPLATE.md`](docs/HANDOFF_TEMPLATE.md); do not turn
`PROJECT_STATE.md` into a chronological task log. Update `PROJECT_STATE.md` only
when a durable supported feature, known gap, owner, or validation fact changes.

# GameMaker metadata workflow

1. Identify every affected implementation or binary, matching `.yy`, project entry in `Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp`, and applicable `folders/*.yy` metadata before editing.
2. Preserve resource identities and all existing references. Avoid unnecessary renames; do not reorganize unrelated resources during a bounded code extraction.
3. Register a new resource in the same `.yyp` style as comparable resources and assign an appropriate existing or deliberately created Asset Browser folder. IDE folders do not need to mirror physical directories.
4. Prefer the project’s existing folder taxonomy over inventing one. Treat a broad Asset Browser cleanup as its own dedicated task.
5. Check the affected scope for orphaned `.yy` resources, missing or duplicate `.yyp` registrations, invalid resource paths, and stale folder references. Review the diff for accidental IDE metadata churn.
6. Validate metadata and compilation with the documented tier in `docs/VALIDATION.md`; use terminal and headless checks by default. Do not launch GameMaker, Igor, or the runner unless the task expressly authorizes it.
7. Preserve pre-existing work, including `.DS_Store`.

Do not add a metadata-integrity checker automatically. If repeated manual checks cannot establish these invariants and no existing repository tool covers them, first propose a small deterministic checker with its inputs, checks, output, and failure behavior; add it only with task approval and without duplicating an existing tool.

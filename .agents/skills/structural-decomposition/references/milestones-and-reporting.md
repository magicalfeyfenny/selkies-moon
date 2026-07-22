# Milestone completion and report

Before closing a milestone:

- Confirm exactly one responsibility cluster moved and the approved stop point was reached.
- Confirm intended callers, state ownership, initialization dependencies, and compatibility wrappers are accounted for.
- Run focused validation after extraction and the full relevant tier before completion; record commands and results.
- Update `docs/ARCHITECTURE.md`, module mapping, `docs/PROJECT_STATE.md`, or a handoff only when a durable ownership, supported-state, or continuity fact changed. Follow `docs/HANDOFF_TEMPLATE.md` for an interrupted non-obvious state.

Final report format:

1. Target and extracted responsibility.
2. Public-contract/caller migration and any remaining facade.
3. Behavior-sensitive contracts checked, including a `$determinism-validation` result when applicable.
4. Validation evidence and unverified behavior.
5. Durable documentation or handoff updates, if any.
6. Explicit stop point and follow-up extraction, if any.

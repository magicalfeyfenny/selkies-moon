# Determinism workflow

1. State the contract being preserved and define comparable checkpoints. Identify the run inputs, initial state, relevant state fields, and expected events.
2. Identify every relevant RNG source, seed, owner, and consumption order. Do not add, remove, or move a random draw without treating it as a contract change.
3. Identify the timing source, Begin/Step/End Step/Draw ordering, initialization order, and frame-sensitive behavior.
4. Select the smallest applicable existing test or harness. Use focused GMTL coverage first; use project-owned test helpers or visual-tour facilities only when their evidence fits the contract.
5. Compare checkpoint state using existing project facilities where available. Compare applicable events: spawns; entity creation/destruction; score/rank changes; wave transitions; drops; boss/phase transitions; save/load restoration; and replay results.
6. When divergence occurs, report the first divergent frame, event, state field, or RNG-consumption point that can be established. Record unknowns rather than inferring equivalence.
7. Distinguish successful compilation from a runtime test. For a full GMTL pass, require both documented summary lines and every declared test to pass; follow `docs/VALIDATION.md` for the current command and criteria.
8. Never describe the known local runner failure as a pass. When local runtime execution remains unavailable, use the documented hosted Windows validation fallback in `docs/VALIDATION.md`.
9. Do not change production behavior merely to make validation easier. Explicitly record behavior that could not be verified.

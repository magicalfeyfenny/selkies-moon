---
name: determinism-validation
description: "Validate deterministic GameMaker gameplay before and after changes that touch seeded RNG ownership or consumption, timing or step order, replayability, wave/spawn/score/rank/progression/entity sequencing, save/load continuity, initialization order, or structural extraction dependent on those contracts. Do not use merely because a file is large or ordinary tests exist."
---

# Determinism Validation

Define the deterministic contract and scope before selecting tests. Read [the validation workflow](references/determinism-workflow.md), then use the smallest existing project facilities that can expose divergence.

Follow `docs/VALIDATION.md` for authoritative commands and acceptance criteria. Do not change production behavior to simplify a test, and do not treat a compile or the known unavailable local runner as a runtime pass.

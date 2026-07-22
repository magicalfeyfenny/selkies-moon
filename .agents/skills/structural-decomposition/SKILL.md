---
name: structural-decomposition
description: "Plan and carry out behavior-preserving decomposition of an oversized, multi-responsibility, or highly coupled GameMaker production owner. Use for responsibility audits, one cohesive extraction, caller migration through a compatibility facade, facade retirement, or durable module-ownership updates. Do not use for gameplay or balance work, broad cleanup, arbitrary line-count reduction, renaming-only work, or localized fixes that do not change ownership."
---

# Structural Decomposition

Start from the named owner and its routed scope in `docs/ARCHITECTURE.md`; preserve unrelated work. Read [the structural audit](references/structural-audit.md) before selecting an extraction.

Use [characterization-first extraction](references/characterization-first-extraction.md) for the selected responsibility, [compatibility facades](references/compatibility-facades.md) whenever callers cannot migrate atomically, and [milestones and reporting](references/milestones-and-reporting.md) to close the approved milestone.

Route new, moved, or reorganized GameMaker resources through `$gamemaker-resource-change`. Route RNG, timing, replay, save/load, or state-equivalence concerns through `$determinism-validation`. Stop when the approved milestone is complete.

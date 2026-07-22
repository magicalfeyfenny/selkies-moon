# Characterization-first extraction

1. Establish focused characterization coverage before moving behavior whose contract is not already verified. Prefer existing focused GMTL tests; add the smallest contract test when needed.
2. Move one coherent cluster per milestone. Keep object events orchestration-focused and place shared behavior in the routed owner.
3. Preserve observable behavior, balance, save formats, messages, initialization order, event/timing semantics, and RNG consumption order unless the approved task explicitly changes and tests that contract.
4. Keep the new interface narrow and explicit. Avoid broad renaming, formatting churn, duplicate ownership, and unrelated cleanup.
5. If the extraction creates, moves, or registers a GameMaker resource, invoke `$gamemaker-resource-change` before changing metadata.
6. Run focused validation after each meaningful extraction. Use the full relevant validation tier before completion, following `docs/VALIDATION.md`.

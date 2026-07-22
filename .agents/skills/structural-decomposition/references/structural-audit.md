# Structural audit

1. Start with the named target, its `/// @func` contracts, direct callers, adjacent tests, and the matching `docs/ARCHITECTURE.md` route. Expand only for a demonstrated dependency.
2. Inventory public functions, direct callers, externally accessed instance/global/struct state, side effects, initialization dependencies, object-event ordering, and required GameMaker resources. Record the source and destination owner for each candidate responsibility.
3. Cluster behavior by cohesive responsibility, data ownership, and dependency direction. Do not select work merely to shorten a file or because adjacent functions have similar names.
4. Mark compatibility-sensitive contracts: gameplay behavior and balance, save formats, message contracts, initialization order, timing semantics, and deterministic RNG consumption. Invoke `$determinism-validation` for the applicable contracts.
5. Choose one independently reviewable responsibility cluster. Define its narrow interface, expected callers, validation, and a stop point before editing.

Keep the audit in the task or handoff; update architecture ownership only once the result is durable.

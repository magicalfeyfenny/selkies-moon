# Compatibility-facade lifecycle

Use a forwarding wrapper when callers cannot safely migrate together or when a public contract needs a stable seam.

1. Keep the original public entry point and forward to the new narrow owner without changing arguments, return values, side effects, timing, or RNG use.
2. Migrate intended callers in a bounded milestone and verify that the facade and new owner do not contain duplicated implementation.
3. Remove the old implementation only after intended callers use the new owner and characterization coverage passes.
4. Retire the facade only after its remaining callers are deliberately migrated and no external contract requires it. Treat facade removal as its own reviewable milestone when it is not atomic with the extraction.

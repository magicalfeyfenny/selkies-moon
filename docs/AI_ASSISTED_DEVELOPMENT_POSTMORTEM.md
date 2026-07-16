# AI-Assisted Development Post-Mortem

**Project:** *Selkie's Moon ~ until we meet again ~*

**Audit date:** 2026-07-15

**Scope:** Repository history through `ef83473`, the `dev` base plus the current post-mortem branch, merged pull requests, code and test architecture, documentation, editable asset sources, build tools, and validation evidence.

## Executive summary

This project is a strong demonstration of what agentic AI can do in a familiar engine: it moved from a small hackathon shooter to a documented, tested, data-driven game with two playable heroines, five themed stages, character bosses, route-specific finales, practice tools, native 3D backgrounds, a production audio pipeline, and editable art sources. The repository contains substantially more engineering discipline than a typical game jam project.

Its central success was **turning one-off content into systems**. Input became device-neutral verbs; run state gained schemas and migrations; stages and bosses became data-driven; visual QA became an automated tour; generated art gained manifests and editable companion files; and local tests eventually gained an independent Windows CI runner.

Its central failure was **allowing throughput to outrun reviewability**. Several changes were too broad to understand as one unit, most pull requests were merged without an independent review, the public README drifted behind the current game, asset ownership is not always explicit, and large binary masters were committed to ordinary Git. The project often added the right safeguard, but only after the class of problem had already appeared.

The most important general lesson is:

> AI should optimize for a maintainable chain of evidence, not the largest plausible change. Every feature needs an explicit owner, source of truth, editable source contract, acceptance matrix, bounded milestones, and independent verification.

## Evidence and limits

This is a repository post-mortem, not an interview. “Went wrong” means one or more of the following left visible evidence: immediate corrective commits, a later replacement architecture, conflicting documentation, failed validation, unreviewable change size, missing provenance, or source-control cost. It does not imply that experimentation itself was a mistake.

The audit examined:

- 63 commits reachable from `dev`, beginning on 2026-04-10;
- 12 merged pull requests;
- the current GML, Python, shell, PowerShell, shaders, GameMaker metadata, JSON, and documentation;
- editable and runtime assets under `art/` and the GameMaker project;
- local GMTL behavior on the audit machine;
- current GitHub Actions history for the GameMaker test workflow.

The audit cannot establish player enjoyment, long-session balance, accessibility quality, frame-time behavior on low-end hardware, or whether every artistic result matches the creators' intent. Those require playtesting and human judgment.

During review of this post-mortem, the editable-raster finding prompted an immediate correction and then a more important source-authority clarification. Seventy-six missing native files were migrated, thirteen additional shipped-raster masters were added, and the normal pipeline was inverted: KRA is now the read-only build input and runtime PNG is the output. The former Python drawing and reverse-import entry points are compatibility wrappers around one staged exporter and cannot regenerate a master. After validation, parallel ORA, named layer-export, imported-runtime PNG, and preview mirrors were removed from the production source tree. The cleanup retired the placeholder-audio builder, made routine Blender export read existing `.blend` masters without saving over them, and a later repository-hygiene pass stopped packaging portable OBJ intermediates alongside runtime VBUFF files. The snapshot below reflects that corrected working branch; the original inconsistencies remain documented as development lessons.

The later coordinated storage follow-up is now addressed by [Asset Pipeline](ASSET_PIPELINE.md) and the [Git LFS Migration](LFS_MIGRATION.md): BLEND, KRA, and Logic projects are the sole 3D, raster, and audio masters, while the audited master, runtime, interchange, and reference binary families are stored through LFS. The historical measurements and findings below intentionally remain as the pre-migration audit record.

The later repository-hygiene follow-up reconciled the remaining packaging correction: the YYP now registers only VBUFF, while OBJ remains a repository-only interchange/build derivative. The same pass removed unowned font backups, unreachable individual Mira/Aisha story files, the idle timeline and its generator, three fixture-only legacy enemies and their raster sources, and obsolete SFX backup behavior. A machine-readable package manifest and hosted gate now prevent those classes of debris from returning.

Before mirror cleanup, the corrected raster pipeline was validated twice. The normal export covered 80 sprites, 87 active frames, 15 standalone assets, and 251 then-declared PNG targets; it repaired or created 76 derivatives while 175 were already current. A fresh `--check` render then reported 0 changes and 251 matches. Before/after SHA-256 inventories were identical for all 95 KRA masters and all 201 GameMaker `.yy` files, proving that the normal build changed neither source art nor engine metadata. The subsequent catalog cleanup removed redundant art-side targets, and the later fixture purge removed three exact-import masters that no longer had runtime consumers. The current static gate registers all 92 KRAs, covers 77 sprites and 84 frames, distinguishes six standalone runtime assets from nine source-only masters, and proves exact ownership of all 174 required runtime PNG targets with no unowned outputs.

### Current repository snapshot

| Signal | Observed state | Interpretation |
| --- | ---: | --- |
| GML | 18,276 lines | Substantial game code, no longer jam-sized |
| GMTL tests | 126 tests in one centralized suite | Broad regression intent, but centralized test maintenance |
| Largest project module | `scr_gameplay_helpers.gml`, 3,836 lines | Shared ownership succeeded, then became too broad |
| Editable raster sources | 92 `.kra` masters; no parallel production mirrors | KRA is the sole source for shipped raster art |
| Runtime sprite source mapping | 77/77 resources, 84/84 active frames | Every active root frame and GameMaker editor-layer copy is exported from KRA |
| Native 3D sources | 5 `.blend`, 5 repository-only OBJ build intermediates, and 5 packaged VBUFF files | Runtime code and package load only VBUFF; the exact split is manifest-owned |
| Audio production | 16 MIDI metadata files, 16 canonical Logic projects, 30 lossless WAV derivatives, 15 runtime OGG and 15 runtime WAV | Complete source-to-runtime production chains |
| Tracked audio-production size | about 878 MB | Ordinary Git is being used as a large-binary store |
| Loose Git object database | about 1.4 GiB | Clone, fetch, storage, and history-rewrite costs are already material |
| Hosted test workflow | [current `dev` run passed](https://github.com/magicalfeyfenny/selkies-moon/actions/runs/29449774072) | Independent Windows signal now exists |
| Local audit test run | 126/126 passed; latest run succeeded on attempt 3 after two compiler crashes | Retry isolates the known compiler fault without masking completed test failures |

## Development chronology

### 1. Hackathon foundation: 2026-04-10 through 2026-04-14

The first phase had a sensible engineering order. GMTL was introduced in the second commit (`4d166f3`) before most gameplay existed. Save/config tests, boot behavior, title flow, story flow, player scaffolding, and gameplay followed in mostly focused commits and pull requests.

What this phase did well:

- Established tests before feature complexity.
- Used scaffolding comments as implementation contracts.
- Built reusable title, story, setup, and gameplay helpers instead of placing everything in room code.
- Adopted object inheritance for enemies and bullets.
- Kept several early pull requests small enough to comprehend.
- Tagged the jam state (`jam`) so the historical submission remains recoverable.

What this phase foreshadowed:

- PR #6 grew to 193 files and 23 commits, mixing gameplay implementation and many assets.
- Local tests existed, but hosted CI did not.
- The branch target was `main`; later development moved to `dev` without a durable branch-policy document.

### 2. Large expansion: 2026-07-10 through 2026-07-11

Commit `f5057fb` added the ten-stage Selkie update in a single 100-file change. The next commits added a visual tour and improved movement/firing feel. This phase demonstrated very high AI throughput and added important player-facing breadth.

What worked:

- New content reused existing runtime structures instead of creating ten separate rooms.
- The visual-tour harness converted presentation review into a repeatable process.
- Player-feel work was isolated into a focused follow-up.
- Test counts in PR evidence rose from 65 to 68 as behavior expanded.

What did not:

- The expansion was too large for its commit to explain its internal decisions.
- The ten-stage structure later became a five-stage structure, but the README was not migrated with the authoritative code and system docs.
- The visual QA harness arrived after the large expansion rather than being an acceptance gate for it.

### 3. Mechanics and boss-system consolidation: 2026-07-12 through 2026-07-14

The mechanics pass, boss-variety work, documentation, and original-character archive substantially improved maintainability. Boss attacks moved out of a roughly 500-line object Step event and into encounter descriptors plus a dedicated interpreter module. Route identity became explicit: Moon retained rose attacks and Selkie retained chakram attacks.

What worked:

- `GameBossEncounterInfoCreate`, generated `phase_plan` data, and `scr_boss_patterns` established real extension points.
- Phase counts and HP scaling became calculations rather than scattered special cases.
- Tests began checking generated plan length instead of assuming three phases.
- Invalid boss descriptors fail closed instead of silently selecting an unrelated fallback attack.
- Original character references were copied into a stable non-runtime archive and declared design authority.
- Architecture, gameplay, data-format, and development documents were added.
- PR #9 recorded 97 passing tests and a clean diff check.

What did not:

- Commit `f034094` is literally titled “i had codex do a bunch of random shit lol,” with a body about exhausted usage credits. It is unusually direct evidence of an unbounded AI session with no coherent task contract.
- PR #8's history contains both a squashed aggregate and the original broad branch as merge parents. The code survived, but ancestry and blame became harder to read.
- The first boss-pattern pass used `layer` as a local name, colliding with a GameMaker builtin and breaking compilation.
- A validation attempt initially observed stale build output after the source had been fixed.
- The original-reference archive was corrective work. Design authority should have been declared before generated portraits were produced.

### 4. Five-stage production overhaul: 2026-07-15

[PR #10](https://github.com/magicalfeyfenny/selkies-moon/pull/10) consolidated the campaign into five themed stages and added a large neo-gothic production pipeline. [PR #11](https://github.com/magicalfeyfenny/selkies-moon/pull/11) rebuilt the 3D stages and added the sisters' combined finale. [PR #12](https://github.com/magicalfeyfenny/selkies-moon/pull/12) added crystal UI and brought up Windows CI.

What worked:

- The project acquired editable art, font, 3D, score, and SFX production artifacts instead of keeping only runtime exports.
- Manifests connect authored sources to runtime identifiers and outputs.
- The five-stage structure is more coherent in the current system documentation and code.
- Validation evidence grew to 123, then 125, then 128 GMTL tests.
- PR #10 also recorded a successful YYC build.
- PR #11 recorded 25 inspected visual-tour captures and format/manifest checks.
- PR #12 recorded 26 captures and produced a green 128-test Windows CI run for the current `dev` commit.

What did not:

- PR #10 changed 1,161 files with 759,219 additions and was merged about 12 minutes after opening. That is a publication event, not a realistic review window.
- PR #11 changed 120 files with 565,689 additions and 637,641 deletions. Most was generated geometry, but logic, story, assets, docs, and runtime buffers still traveled together.
- Follow-up work immediately corrected 3D projection orientation, billboard UV selection, background movement at boss seams, combat balance, reward economy, and the missing sisters' finale. These were integration acceptance criteria that the first mega-pass did not hold simultaneously.
- Hosted CI arrived only after the largest July changes had already merged. Bringing it up required six failed workflow runs before the first success.
- At merge time the repository had no Git LFS configuration despite hundreds of megabytes of binary production data. The cleanup branch initially routed only KRA files through LFS; the later coordinated migration recorded in [Git LFS Migration](LFS_MIGRATION.md) addresses the WAV, Logic, and other audited asset history while preserving the immutable release anchor.

## What went right

### Tests were treated as product infrastructure

Adding GMTL at the beginning was one of the best decisions in the project. The suite now covers setup, title flow, gameplay calculations, controllers, pause, practice, rank, persistence, story behavior, boss plans, asset/category registries, and representative event behavior.

Particularly strong practices include:

- isolating tests in a copied project tree;
- failing if summaries are missing or zero tests run;
- cleaning persistence artifacts in setup/teardown;
- exposing pure calculation/report helpers for balance checks;
- testing compatibility migrations instead of discarding older saves;
- adding Windows CI as an independent engine/runtime path;
- retaining CI logs even on failure.

The test-count progression in PR evidence—65, 68, 97, 123, 125, 128—shows that tests generally expanded with the game rather than remaining frozen at the jam baseline.

### The architecture evolved toward ownership and data

The current architecture has recognizable owners:

- `scr_setup` owns schemas, migrations, and boot data;
- `scr_input_helpers` owns device-neutral input verbs;
- `scr_audio_helpers` owns routing and category gains;
- `scr_gameplay_helpers` owns run/stage rules and encounter data;
- `scr_boss_patterns` owns attack interpretation;
- `scr_story_helpers` owns story loading and rendering;
- `scr_stage_3d` owns presentation-only 3D state;
- `scr_ui_crystal` owns the reusable refractive panel effect.

The best specific pattern is the boss refactor: encounter identity, plan generation, execution, presentation data, and HP scaling are separate enough that new phases can extend a family without duplicating an object event. The project also preserves route identity in data rather than treating alternate endings as a cosmetic swap.

### Compatibility was respected

The project uses default factories, compatibility passes, schema versions, and migrations for saves/config. Story filenames use version suffixes to avoid older GameMaker sandbox copies shadowing updated included files. Those are mature decisions for a rapidly changing game.

### Visual QA became repeatable

The visual tour is more valuable than a pile of ad hoc screenshots because it is launched from the game and captures at a stable point after world and GUI drawing. Its coverage grew with the project and PR descriptions record actual inspection, not merely capture generation.

That distinction matters: a screenshot existing is not evidence that anyone looked at it.

### Editable asset preservation became a first-class concern

The current tree preserves several useful classes of source:

- immutable original character and enemy references;
- genuine KRA masters with manifest-declared runtime PNG targets;
- Blender scenes with packed textures, camera curves, manifests, and OBJ-to-VBUFF build intermediates;
- MIDI note metadata, cue sheets, canonical Logic projects, lossless WAV derivatives, runtime OGGs, and loop-validation records;
- licensed font source material and editable glyph sheets.

During the one-time migration, 82 ORA/KRA baseline pairs passed archive integrity, dimensions, layer name/order/visibility/opacity/offset, and flattened-pixel equivalence checks before the KRAs were promoted. Thirteen additional KRA masters cover the seven full portraits, five shipped font atlas textures, and macOS icon. Once validated, the ORAs and art-side mirror exports were removed; they are historical migration inputs, not a second current catalog. The production gate now validates the KRA files themselves and renders every declared runtime target from them.

### Documentation and API comments substantially caught up

The project now has architecture, development, gameplay, data, and audio guides. Most named project functions have `/// @func` contracts, and object events usually state their ownership role. The docs explain not only what functions exist but where future work should go. This is strong progress even though the current documentation overstates the annotation coverage of the 3D module.

### Failures were converted into tooling

Several corrections became reusable safeguards:

- compiler crashes led to a retrying isolated GMTL wrapper;
- presentation regressions led to the visual tour;
- runtime-only art led to editable-source catalogs;
- sparse/provisional backgrounds led to Blender/Krita pipelines and manifests;
- missing hosted validation led to Windows CI;
- obsolete story data shadowing led to versioned filenames.

That is the healthiest pattern in the history: a failure was not merely patched; its class was partially automated away.

## What went wrong, and why it matters

### 1. Scope was sometimes defined by capability rather than intent

The broad mechanics commit and the July mega-overhauls changed many independent systems at once. AI made this technically possible, but technical possibility is not a useful scope boundary.

Consequences:

- failures could not be attributed to one conceptual change;
- subjective problems appeared only after full integration;
- PR summaries had to describe entire game eras;
- later agents had to reconstruct decisions from large diffs;
- credit and attention were spent on changes that were difficult to inspect.

**Better rule:** one task may cross layers for a vertical slice, but it should not cross independent player promises. If “stage art,” “rank economy,” “boss roster,” and “audio production” can each be accepted or rejected independently, they need separate milestones even if one agent can implement all of them.

### 2. Pull requests often packaged work without reviewing it

Eleven of the twelve merged PRs show zero recorded reviews, and all show zero general PR comments. This is understandable in a solo project, but an AI-heavy solo project needs a substitute: a deliberate self-review pass, a second agent with a narrow review brief, or a cooling-off playtest before merge.

The clearest example is PR #10: 1,161 files merged roughly 12 minutes after opening. The branch and PR preserved a checkpoint, which was good, but they did not create meaningful review pressure.

**Better rule:** a PR is not ready because it has a summary. It is ready when a reviewer can map each acceptance criterion to a diff, a test, a capture, or an explicitly deferred risk.

### 3. Public and internal documentation disagree

The current code defines `STAGE_COUNT` as 5 and rank as 0–50 with a fresh value of 0. `docs/GAMEPLAY_SYSTEMS.md` agrees. At audit time, the README still claimed:

- ten stages;
- rank 0–100 starting at 50;
- a point-blank recharge/resource gauge;
- the older cancel-meter economy;
- bullet-cancel behavior at both Berserk activation and ending that no longer matches the implementation;
- the old 5/7/9/16 boss progression instead of the current 3, 5, dual 3+3 plus shared finale, 7, and 15 structure;
- the older 2024 GameMaker environment while CI uses LTS 2026.
- “no additional third-party assets” even though the current tree includes licensed Not Jam font sources and an exact text-arrow import from `thpj3`.

The cleanup reconciled those README claims, corrected the practice-life contract, stopped overstating API annotation coverage, and replaced the visual-tour fixture's obsolete stage 8/rank 80 values with the named current limits. Remaining documentation work includes the in-game credits and cross-platform handling for font resources that name non-vendored system faces.

This is not merely stale prose. It can make an AI “correct” current code back toward obsolete behavior.

**Better rule:** every durable fact has one canonical source. Public docs should reference or be checked against constants/registries. A feature is incomplete until every duplicated claim is updated or removed.

### 4. The local validation gate is robust in policy but fragile in availability

The wrapper correctly distinguishes missing summaries from passing tests and retries known compiler crashes. An early audit run exhausted all eight attempts with `System.AccessViolationException`, sometimes after GML compilation during asset emission. Two cleanup validations later passed all 128 tests on attempts two and four after one and three transient compiler crashes respectively.

The current Windows CI run also passed 128/128. The project therefore has valid local and independent hosted results, but the macOS signal remains intermittently unavailable and must never be reported as green unless a complete summary is produced.

**Better rule:** known flaky infrastructure needs a second implementation, not only more retries. Classify outcomes as pass, product failure, or infrastructure unavailable. Never silently convert the third into the first.

### 5. Shared helper modules became new monoliths

Moving logic out of events was correct. The next boundary problem is that `scr_gameplay_helpers.gml` is now 3,836 lines and the single test suite is 2,991 lines. Title, story, boss, and setup modules are also large.

Large files are especially costly for AI because:

- retrieval may omit relevant distant contracts;
- similarly named helpers are easier to duplicate;
- unrelated edits create conflict hotspots;
- tests become difficult to run or reason about by domain;
- code review loses a clear ownership unit.

Centralized data is not yet the same thing as a single source of truth. Stage identity is repeated across stage info, enemy rosters, boss registries, story routing, audio routing, 3D configuration, and asset manifests. The 3D manifest and runtime configuration already encode some camera/fog values differently. `GameMemoryCorePhaseCreate` also exposes a twelve-position argument list, which is easy for either a human or an AI to misorder.

**Better rule:** “thin events” is only the first boundary. Split helper modules by stable domain once they have separate invariants, tests, or change cadence. Give each content family one canonical named schema and derive secondary registries; prefer validated named descriptors over long positional factories.

### 6. Editable does not always mean authoritative

The audit found three competing historical models: native hand-authored masters, Python-generated editable files, and exact one-layer wrappers around runtime pixels. All can be opened in an editor, but only an explicit authority rule answers what may overwrite what. A one-layer ORA preserves pixels without reconstructing lost layers; a KRA generated on every build is editable only until the next build destroys the edits.

The initial tree contained concrete authority conflicts:

- `spr_violet_bee` and `spr_twilight_mayfly` were outputs of both the layered-enemy builder and the older gameplay-art builder, and their runtime pixels differed materially. The correction chooses the layered KRA for each and retires both Python runtime writes.
- Seventy-four manifest `krita_source` paths did not exist even though the corresponding ORAs did. Review created genuine native migrations rather than extension renames, then clarified that those KRAs are promoted masters—not generated companions.
- Fifty-five declared GameMaker editor-layer PNGs were missing and eleven were stale, so opening a sprite in the IDE could recompose from pixels different from its active root frame. The KRA exporter now owns both copies for all 84 active frames while leaving `.yy` metadata untouched.
- The audit found nine additional PNGs in GameMaker sprite directories under frame/layer UUIDs that no current `.yy` referenced. The cleanup removed those inactive files, and the cleaned static gate now proves that the 174 remaining GameMaker/runtime PNGs are exactly the manifest-owned target set with no unowned outputs.
- The story-background manifest named 29 non-`_v2` runtime JSON files while all 29 then-current runtime story files used `_v2`; the cleanup repaired every assignment key. The later reachability purge retained and verifies only the 21 live assignments.

AI portrait provenance is also incomplete. At audit time, the production tree retained 70 candidates and seven contact sheets (about 129 MB) plus the selected full-size masters, but no tracked manifest recorded the model/version, prompt, seed, reference hashes, transformations, or selection rationale. Cleanup removed the transient candidate and contact-sheet pool from the production source tree, retained the seven selected KRA masters, and promoted the best surviving design-authority brief beside those masters. Exact model/version, seed, reference hashes, and selection history still cannot be reconstructed retroactively.

**Better rule:** for this project's shipped 2D raster art, every manifest must declare one of three source modes:

- `krita-master`: created and maintained in Krita; the KRA is canonical;
- `migrated-krita-master`: imported once from legacy material, then promoted so only later Krita edits are authoritative;
- `reference-only`: immutable sketches, candidates, contact sheets, or archives that must never be overwritten or imported directly at runtime.

Python may crop, scale, pack, copy, and validate a KRA export. It may not draw replacement production art, regenerate a KRA, or copy runtime PNGs backward into a master.

### 7. Binary preservation was not paired with binary-storage design

Preserving canonical Logic projects and lossless WAV deliveries was right. Committing them to ordinary Git without LFS was not scalable. The current audio-production files alone account for about 878 MB of tracked content; the loose object database is about 1.4 GiB. Before cleanup, WAVs, Logic packages, runtime OGGs, packaged OBJ text, vertex buffers, previews, and layer exports duplicated information at several pipeline stages. Removing disposable raster mirrors and superseded audio resources reduced that duplication; the later repository-hygiene pass also stopped registering OBJ intermediates as Included Files. The valuable binary history still needed an intentional storage policy.

**Better rule:** preserve valuable masters in Git LFS or a versioned asset store. Keep small manifests and hashes in normal Git. Decide deliberately which generated derivatives must be versioned for engine usability and which belong in CI/release artifacts.

**Follow-up status:** Addressed by the coordinated rewrite recorded in [Git LFS Migration](LFS_MIGRATION.md). The migration covers the audited binary families across every old remote head while preserving the immutable `jam` tag and release; [Asset Pipeline](ASSET_PIPELINE.md) separately defines which LFS-tracked files are canonical and which remain derivatives.

### 8. Asset tooling lacks one reproducible environment and one gate

The asset tools use Pillow and NumPy, Blender scripts require `bpy`, and production audio requires Logic. There is no checked-in Python dependency lock or one command that rebuilds and validates every eligible asset class. The new KRA runtime exporter is now a real staged build/check gate for shipped raster art, but GameMaker CI still does not run it or regenerate the Blender/audio catalogs and require a clean diff.

At audit time, `tools/blender_build_stage_scenes.py` and `tools/install_logic_masters.py` contained checkout-specific paths. The cleanup converted these to repository-relative discovery. The retired text-arrow import no longer participates in normal builds, and the shared Krita exporter supports `KRITA_BIN`, `PATH`, and the normal macOS application location, but the overall pipeline still depends on several separately installed tools rather than one reproducible environment.

Several non-raster builders still write destinations sequentially and in place. A mid-run failure can therefore leave a mixture of old and new assets. Native archives also contain metadata that prevents useful byte-for-byte comparisons even when rendered output is stable; the raster gate correctly compares decoded pixels and promotes only after the complete target set validates.

**Better rule:** pin the tools that can be pinned, document the tools that cannot, provide one `build-assets` entry point and one `validate-assets` entry point, and make generators support a no-write/check mode. Build into staging, validate there, clean only manifest-owned stale outputs, and atomically promote the result. Compare native archives semantically or normalize their metadata.

### 9. Integration criteria were discovered after integration

The follow-up history found issues that unit tests could not decide:

- 3D projection was oriented incorrectly;
- transparent billboard cells sampled the wrong atlas quadrant;
- the background stopped or used the wrong route at boss seams;
- the sisters' encounter lacked the requested combined finale;
- combat and reward balance needed another pass.

These are not arguments against iterative work. They are evidence that the acceptance matrix was incomplete before the first implementation.

The 128-test count should not be confused with complete coverage. The balance report duplicates director formulas rather than observing the live director, uncontrolled random calls do not emit a reproducible run seed, 3D assertions do not render the final projection, visual captures have no stable perceptual baseline, and there is no fully scripted route smoke test across stage, boss, dialogue, ending, and return-to-title seams. These gaps line up closely with the regressions that escaped.

**Better rule:** before implementation, enumerate behavior, presentation, content identity, transition seams, performance, persistence, and platform expectations. For every row, name the verification method.

### 10. Replaced systems remain partly packaged and protected

The live director had deliberately left the old `tml_stage` timeline idle while the project still shipped 72 timeline moment files and a tool that regenerated them. Individual Mira/Aisha story files remained registered even though the live stage-three route used combined sister files. The audit also found portable OBJ meshes packaged beside compiled VBUFF files and eleven superseded score placeholders registered beside the complete Logic-derived score, even though runtime routing used neither legacy family. Follow-up cleanup removed the placeholder resources, timeline, generator, individual sister files, and OBJ Included Files; only manifest-owned live data and VBUFF remain in the package.

Some legacy fixtures are valuable migration evidence, but others now consume package size, test attention, and cognitive space. Tests can accidentally make dead production content permanent when they assert that unused assets still exist.

**Better rule:** after every replacement, perform a reachability audit. Label each leftover as live runtime, migration compatibility, regression fixture, source/reference, or removal. Only live optimized derivatives belong in the shipping package.

### 11. Branch and release roles are ambiguous

Early PRs target `main`; later work targets `dev`. The remote default branch still points to `main`, which remains at the ten-stage update, while the current five-stage production version is on `dev`. Only the April jam state is tagged.

This may be intentional, but the repository does not clearly say whether `main` is the latest release, a stable museum branch, or awaiting promotion.

**Better rule:** document branch roles, required gates, promotion flow, and release tagging. The default clone should not surprise a new contributor or AI agent.

### 12. Repository hygiene was mostly automated, but not fully repaired

Build outputs, caches, raw bounces, Python bytecode, screenshots, and platform metadata are ignored, and the cleanup removed the tracked root `.DS_Store` plus current local artifacts.

**Better rule:** an ignore rule prevents new files; it does not untrack existing ones. Add a lightweight repository-hygiene check for tracked platform junk and unexpectedly large files.

## Root-cause synthesis

The problems were not caused by “using AI” in the abstract. They came from four mismatches:

1. **Generation speed exceeded evaluation speed.** Code, art, audio, and metadata could be created faster than a person could play, inspect, and understand them.
2. **Outcome prompts were stronger than process contracts.** The desired feature identity was often clear, but milestone size, source authority, acceptance evidence, and stop conditions were not equally explicit.
3. **Safeguards were reactive.** The project repeatedly built excellent tools after a failure—visual tour, reference archive, retry harness, CI—rather than installing them as prerequisites for the next expansion.
4. **Git was asked to be code history, asset archive, build cache, and review system simultaneously.** Those roles need different storage and review policies.

## Best practices for large AI-assisted game projects

### A. Establish a project constitution before feature work

Keep a short, versioned document that answers:

- What is the current player promise and non-goal list?
- Which mechanics, characters, routes, and visual motifs are identity-critical?
- Which files or references are design authority?
- What are the runtime, toolchain, target-platform, and performance constraints?
- Who owns each subsystem and data contract?
- Which branches mean development, release, and archive?
- What evidence is required before a change is complete?

An AI should quote the relevant constraints in its plan. Paraphrase is not enough when wording encodes identity, such as “the first boss has 3 phases” or “Moon's finale uses rose attacks.”

### B. Use a task contract, not an open-ended request

Every substantial task should include:

| Field | Required question |
| --- | --- |
| Player outcome | What should the player notice? |
| Non-negotiables | What exact constraints must survive? |
| Non-goals | What tempting adjacent work is excluded? |
| Owners | Which existing modules/data contracts should change? |
| Compatibility | What saves, controls, content, or tools must remain valid? |
| Assets | What is design authority and what editable source is required? |
| Acceptance | How will behavior, visuals, audio, performance, and platforms be checked? |
| Milestones | Where should work pause for review or commit? |
| Stop conditions | What ambiguity or risk requires asking before continuing? |

### C. Make reviewability a hard engineering constraint

- Begin from a cleanly identified base and create a feature branch before edits.
- Preserve unrelated user changes and generated workspace noise.
- Build the smallest end-to-end slice that can prove the design.
- Separate refactoring, behavior, source assets, generated exports, and documentation into intentional commits when possible.
- If a diff spans independent systems, split it even if the implementation is already available.
- Never use “while I am here” as authorization for a redesign.
- Before merge, perform a dedicated diff review with a fresh context or a review-only agent.
- Report what was deliberately left unchanged.

### D. Extend ownership boundaries instead of adding local exceptions

- Find the existing owner, insertion point, factory, registry, or descriptor before writing code.
- Prefer data-driven content when many variants share a behavior contract.
- Keep engine event code thin, but also split oversized helper modules by domain.
- Centralize defaults and migrate old data; do not scatter compatibility checks.
- Fail visibly on invalid authored data instead of hiding it behind unrelated fallbacks.
- Preserve event order and engine-specific lifecycle contracts in comments and tests.
- Do not refactor vendored code as if it were project-owned.

### E. Give every asset a source contract

For each asset or asset family, record:

```text
asset_id
source_mode: krita-master | migrated-krita-master | native-authored-master | reference-only
design_authority
canonical_source_path
editor_and_version
generator_and_version
exact_build_command
dependencies
runtime_outputs
license_and_provenance
generation_provenance: model/version, prompt, seed, reference hashes, transformations, selection rationale
dimensions/frame_layout/sample_rate/loop contract
privacy_metadata_review
validation method
content hash
```

Rules:

- Preserve original references byte-for-byte in a non-runtime folder.
- Do not use a prior generated render as design authority unless the creator explicitly selects it.
- Record AI/tool generation and candidate-selection provenance in tracked text, never only in an ignored temporary folder.
- Review EXIF and other embedded metadata before publishing immutable originals; keep a restricted original and sanitized public proxy when necessary.
- Never claim lost layers were reconstructed when only a flattened runtime image was wrapped.
- For shipped 2D raster art, KRA is the only master. Python may transform a rendered export but may not draw production pixels, regenerate a KRA, or import runtime pixels backward during a normal build.
- A generator must not overwrite any authored master. A one-time legacy migration must be separately named, refuse replacement, and promote its result before normal builds resume.
- Treat a filename extension as a contract, not a costume: a native Krita source must be a genuine `application/x-krita` archive, never OpenRaster bytes renamed to `.kra`.
- Do not maintain ORA, named layer-export, imported-runtime PNG, or preview mirrors beside a production KRA. Generate an interchange copy downstream into staging or artifact storage only when a handoff explicitly requires it.
- Every runtime output must have exactly one declared owner; manifests must not list nonexistent required paths.
- Build paths must be repository-relative or configurable, never hard-coded to one developer's home directory.
- Keep source and runtime filenames linked through a manifest, not tribal knowledge.
- Store large binary masters with Git LFS or an asset store, not ordinary Git objects.
- Put candidate pools, raw bounces, superseded versions, caches, and intermediate renders in artifact/review storage unless they are intentionally versioned evidence.
- Build multi-output asset families in staging, validate them, and promote atomically.

### F. Validate with a ladder, not one test command

1. **Static integrity:** parse data, validate manifests, check references, inspect engine metadata churn, and run `git diff --check`.
2. **Unit logic:** test calculations, migrations, selection rules, and descriptor generation.
3. **Engine integration:** simulate representative object/event ordering and run the complete in-engine suite.
4. **Asset regeneration:** rebuild eligible outputs and require no unexpected diff.
5. **Visual/audio QA:** generate a deterministic tour, inspect every changed scene at target resolution, and validate loop/seam/loudness contracts.
6. **Gameplay QA:** play the smallest path that exercises the changed promise, including transitions and failure states.
7. **Performance QA:** measure frame time, memory, load time, draw calls, instance/bullet caps, and asset size against budgets.
8. **Platform QA:** test the supported runtime/export paths, ideally with an independent CI environment.

For a flaky toolchain:

- retry only known fingerprints and cap attempts;
- discard stale artifacts before retrying;
- distinguish product failure from infrastructure failure;
- keep logs from every failed attempt;
- use an independent runner/platform as the tie-breaker;
- never call the result green if no complete summary was produced.

### G. Keep documentation executable where possible

- Put durable values in constants/registries and generate or test duplicated documentation claims.
- Add a consistency test for stage count, rank range/default, route roster, control bindings, test count, and toolchain version.
- Update public docs, system docs, inline contracts, and credits in the same milestone.
- Record major architectural decisions in short ADRs or decision-log entries.
- Include provenance and AI/tool credits at the asset-family level, not only in a global credits screen.

### H. End every AI task with an evidence handoff

The completion report should state:

```text
Outcome
Files/systems changed
Acceptance criteria satisfied
Automated tests and exact results
Visual/audio/playtest evidence inspected
Editable source assets created or updated
Generated outputs and reproduction commands
Compatibility/migration impact
Known risks and unverified items
Unrelated user changes preserved
Git branch/status and next safe action
```

“Tests pass” without the command, count, and distinction between current and stale output is insufficient.

## Ready-to-paste general instruction block

The following is intentionally written as agent instructions rather than commentary:

```text
When working on a large game project, optimize for maintainability, reviewability,
and reproducible evidence rather than maximum change volume.

Before editing:
- Read the project guidance, architecture, data contracts, asset manifests, and
  relevant history. Inspect the current branch and dirty worktree.
- Identify the existing subsystem owner and source of truth. Quote all
  identity-critical user constraints verbatim in the plan.
- Define the player-visible outcome, non-goals, compatibility requirements,
  acceptance matrix, risks, and bounded milestones.
- If an ambiguity would change the design, content identity, canonical source,
  destructive behavior, or external publication scope, stop and ask.

While implementing:
- Work on a feature branch and preserve unrelated user changes.
- Implement the smallest end-to-end slice first. Do not broaden scope with
  unrelated cleanup or redesign.
- Extend existing abstractions, registries, factories, and data descriptors.
  Keep engine events thin and split helper modules when domains have separate
  invariants or tests.
- Preserve backward-compatible save/config/content migrations.
- Add or update tests with the rule. Generated collections must be tested using
  their actual lengths and descriptors, not obsolete fixed bounds.
- Make randomized gameplay reproducible in development: accept/record a seed and
  include it in failing tests, captures, logs, and bug reports.
- Keep logic/refactors, authored sources, generated exports, and docs in
  reviewable milestones. Pause when a diff becomes too broad to explain.

For assets:
- Declare the source mode for every asset family: krita-master,
  migrated-krita-master, native-authored-master, or reference-only.
- Preserve original references byte-for-byte outside runtime assets. Treat the
  creator-selected original as design authority; never promote a generated
  derivative without explicit approval.
- Author shipped 2D raster art in a genuine KRA master. Produce runtime PNGs
  only by rendering that KRA, followed by declared crop/scale/pack operations.
  Python may transform pixels after render but may not draw production art or
  recreate the KRA during a normal build.
- Include provenance, license, tool version, exact export command, manifest
  mapping, and validation evidence.
- For AI-assisted assets, track model/version, prompt, seed, reference hashes,
  transformations, accepted candidate, and selection rationale outside `tmp/`.
- Review embedded metadata/privacy before publishing source references.
- Never claim that a flattened runtime import has reconstructed original layers.
- Never let a generator overwrite an authored master. Keep one-time migration
  commands separate, non-destructive, and unable to replace an existing KRA.
- Never satisfy a native-format request by renaming another format. Validate the
  file signature or archive MIME. Keep only the canonical KRA in the production
  source tree; generate requested interchange files downstream as temporary
  handoff artifacts.
- Require exactly one declared generator/owner for each runtime output. Validate
  that all required manifest paths exist and that build paths are repository-
  relative or configurable rather than tied to one developer's home directory.
- Put large binary masters in Git LFS or a versioned asset store. Keep build
  caches, raw intermediates, and disposable previews out of ordinary Git.
- Build into staging, validate the complete family, clean only manifest-owned
  stale outputs, and atomically promote rather than rewriting destinations in
  an order-dependent sequence.

Before completion:
- Run static integrity checks, unit and engine tests, asset regeneration checks,
  visual/audio inspection, a representative playtest, performance checks, and
  supported-platform validation in proportion to risk.
- For flaky infrastructure, use bounded retries only for known signatures,
  discard stale artifacts, retain logs, and report pass, product failure, or
  infrastructure unavailable accurately.
- Review the entire diff with fresh context. Check engine metadata for churn,
  scan for large/tracked junk files, and confirm documentation agrees with code.
- Do not describe a PR as reviewed merely because it exists. Map every acceptance
  criterion to a test, capture, measurement, diff, or explicitly deferred risk.
- Finish with an evidence handoff listing exact commands/results, inspected
  artifacts, source files, reproduction steps, compatibility impact, known
  risks, preserved unrelated changes, and Git status.
```

## Prompt templates

### 1. Project reconnaissance and plan

```text
Audit this game project before changing it.

Goal: [player/project outcome]
Non-negotiable constraints, preserve verbatim:
- [constraint]
- [constraint]
Non-goals:
- [excluded work]

Inspect the repository guidance, current branch/worktree, architecture, engine
lifecycle, save/data schemas, tests, build/release tooling, asset sources and
manifests, and the history of the affected subsystem. Identify:
1. the current source of truth and owning modules;
2. extension points that should be reused;
3. compatibility and migration risks;
4. editable-source/provenance requirements;
5. an acceptance matrix for logic, integration, visuals, audio, performance,
   persistence, and supported platforms;
6. bounded implementation milestones and stop/ask conditions.

Do not edit yet. Return an evidence-based plan with exact paths and call out any
conflict between my request and current project contracts.
```

### 2. Reviewable feature implementation

```text
Implement [feature] as a bounded vertical slice.

Player-visible outcome: [outcome]
Must preserve:
- [mechanic/content/identity constraint]
- [compatibility constraint]
Out of scope:
- [non-goal]

Start from [base branch] on a new feature branch. Preserve unrelated changes.
Use the existing owner/registry/data contract at [path or symbol] and avoid local
special cases. Add tests before or alongside sensitive rules. Update public docs,
system docs, and inline contracts that duplicate changed facts.

Milestones:
1. contract/tests;
2. smallest working implementation;
3. presentation/assets with editable sources;
4. integration and migration;
5. validation and fresh-context diff review.

At each milestone, summarize the diff and acceptance evidence. Stop before
expanding into independent systems. Complete only when every acceptance item is
mapped to a test, inspected capture, playtest, measurement, or named deferral.
```

### 3. Editable asset creation or replacement

```text
Create or replace [asset family] for [runtime use].

Design authority: [exact original/reference path]
Required source mode: [krita-master | migrated-krita-master | reference-only]
Style and identity constraints:
- [constraint]
- [constraint]
Technical contract:
- dimensions/frame layout/origin/alpha/color space: [values]
- engine/runtime outputs: [paths/formats]
- performance or size budget: [budget]

Preserve the original references byte-for-byte in a non-runtime reference folder.
Do not use prior generated derivatives as references unless I explicitly list
them. Author the production raster art in a genuine KRA and make that file the
only master. Never obtain it by renaming another format: validate the native
archive MIME. Runtime PNGs must be rendered from the KRA into staging and may
then receive only the declared crop, scale, packing, or color-space transform.
Python may automate those transforms and validation but must not draw replacement
production art, recreate the KRA, or import runtime PNGs backward during a normal
build. Do not add ORA, named layer-export, imported-runtime PNG, or preview mirrors
to the production source tree. If an external handoff explicitly requires an
interchange file, generate it downstream into staging or artifact storage. A
separately named one-time migration may create a missing KRA but must refuse to
overwrite an existing master.

Add a manifest containing provenance, license, source mode, design authority,
tool/version, generator/version, exact build command, dependencies, runtime
outputs, hashes, and QA method. For AI-assisted work, also record model/version,
prompt, seed, reference hashes, transformations, accepted candidate, and selection
rationale in tracked text. Review embedded metadata/privacy before publishing.
Export into staging, validate that required paths exist and every output has
exactly one owner, then check registration, frame order, alpha, dimensions,
pivots, seams, target-resolution appearance, and a clean regeneration diff.
Promote atomically, use repository-relative/configurable paths, and store large
binaries through the project's LFS/asset-storage policy.
```

### 4. Architecture/refactor request

```text
Refactor [subsystem] without changing its player-visible behavior except for
[explicit behavior changes].

First map current callers, engine event order, state ownership, data schemas,
fallbacks, tests, and known compatibility paths. Write characterization tests for
the behavior that must survive. Identify which complexity is accidental and
which encodes engine or content constraints.

Move behavior toward one declared owner and data contract. Do not merely transfer
a monolith from object events into one giant helper file. Split by stable domain,
keep public APIs small, preserve migrations, and fail visibly on invalid authored
data. Make intermediate commits buildable and testable. Run old and new paths in
comparison where practical, then remove the obsolete path only after evidence
shows no caller remains.

Finish with a before/after ownership map, test results, migration impact,
performance comparison, and remaining debt.
```

### 5. Visual integration and playtest pass

```text
Perform a focused visual/gameplay QA pass for [feature or milestone]. Do not
redesign unrelated systems.

Build a coverage matrix containing every affected screen/state, transition seam,
route/character variant, input device, failure state, target resolution, and
supported platform. Generate deterministic captures after world and GUI layers
are complete. Inspect the images rather than only confirming that files exist.

Also play the shortest paths that exercise entry, active behavior, pause/overlay,
success, failure, retry, stage/room transition, persistence, and return-to-menu.
Record concrete defects with reproduction steps and severity. Fix only in-scope
defects, rerun the relevant matrix, and report untested combinations explicitly.
```

### 6. Stabilization and release candidate

```text
Prepare [branch/commit] as a release candidate without adding new features.

Freeze scope. Audit branch ancestry, version/credits, changelog, migration paths,
runtime assets, manifests, licenses, large-file policy, ignored/tracked junk, and
public documentation. Confirm the release branch and tag policy.

Run the complete verification ladder: static checks, unit/in-engine tests, clean
asset regeneration, visual/audio tour inspection, representative full-run
playtest, performance budgets, and every supported export platform. Use an
independent CI environment. Treat missing summaries or known tool crashes as
infrastructure unavailable, never as a pass.

Return a go/no-go table. Every risk must have an owner and disposition: fixed,
accepted, deferred to a named issue, or release-blocking. Do not publish until I
authorize the external action.
```

### 7. AI self-review / red-team pass

```text
Review this change as if you did not implement it. Do not edit during the first
pass.

Reconstruct the task contract from the request and repository guidance. Check the
entire diff for scope creep, broken identity constraints, duplicated ownership,
fixed-size assumptions, lifecycle/order mistakes, migration loss, stale docs,
unreproducible or flattened-only assets, generator/master conflicts, accidental
metadata churn, large binary mistakes, missing licenses, and validation claims
that rely on stale or incomplete output.

Map every acceptance criterion to evidence. Inspect changed visual/audio output.
Classify findings by player impact and confidence, then propose the smallest
repairs. Clearly separate product defects, maintainability debt, and toolchain
failures.
```

## Recommended follow-up backlog for this repository

These remain after the KRA-authority and repository-hygiene corrections made during this post-mortem. The cleanup already reconciled the README's major gameplay claims, removed the tracked `.DS_Store`, repaired the 29 then-current story-assignment keys and retained the 21 reachable assignments, added exact runtime-PNG ownership rejection, retained the portrait design brief in tracked source history, and removed superseded runtime derivatives.

### Priority 0: prevent further ambiguity and repository growth

1. Document `main`/`dev`/release promotion and decide which branch should be the remote default.
2. **Addressed:** expand the KRA-only Git LFS rule and rewrite the audited WAV, Logic, Blender, runtime, interchange, and other binary history in one coordinated migration while preserving the immutable jam release. See [Git LFS Migration](LFS_MIGRATION.md).
3. **Addressed:** automated large-file/tracked-junk, LFS-pointer, exact datafile ownership, GameMaker resource, and sound-ownership checks now run locally and in hosted CI; the same follow-up purged the proven-dead package content.
4. Extend the machine-readable KRA registry with per-asset design authority, provenance, license, tool version, and content hashes.
5. Keep the exact raster target-set check as a required local and hosted gate so unowned GameMaker PNGs cannot return.
6. Add a tracked portrait generation/selection manifest for the provenance that is still recoverable; reference external review artifacts without returning the heavy candidate pool to the production tree.
7. Reconcile the in-game credits, verify cross-platform font sources, and audit privacy metadata in immutable references.
8. Preserve the Windows CI path and keep improving deterministic fallback diagnostics for times when the macOS asset compiler cannot complete.

### Priority 1: make the pipelines reproducible and reviewable

1. Add a pinned Python environment for Pillow/NumPy-based tools and record Blender/Krita/Logic versions.
2. Aggregate the raster build/check gate with Blender, audio, and data generation under project-wide `build-assets` and `validate-assets` entry points.
3. Bring the remaining non-raster asset builds up to the raster exporter's staged, atomic, duplicate-owner-checked behavior, including manifest-owned stale cleanup.
4. Split `scr_gameplay_helpers.gml` and `test_bootstrap.gml` into domain-owned modules/suites.
5. Add consistency tests or generated documentation for stage count, rank bounds/default, route roster, and toolchain versions.
6. **Addressed with Priority 0 item 3:** the package manifest and repository-hygiene gate reject OBJ Included Files, unowned sound resources, superseded backups, undeclared datafiles, and unregistered GameMaker metadata.
7. Isolate generated geometry/exports from code and authored-source diffs in commits and PR presentation.
8. Require a fresh-context self-review or review-only agent report before merging broad AI changes.

### Priority 2: strengthen production confidence

1. Add performance budgets and telemetry for frame time, memory, bullets/instances, vertex counts, and load time.
2. Add deterministic run seeds and a scripted route smoke test covering every gameplay/story transition seam.
3. Add release-candidate full-run and route matrix checklists.
4. Add release tags and changelog entries after promotion from `dev`.
5. Add lightweight architecture decision records for campaign structure, asset authority, audio production, and branch policy.
6. Declare and validate music/SFX LUFS, true-peak, and dynamic-range targets in addition to existing loop/format checks.
7. Consider visual-diff tooling for stable captures while retaining human inspection for intentional art changes.

## Final assessment

The project did not fail. It succeeded so quickly that its governance became the bottleneck.

The codebase's current strengths—tests, data-driven bosses, compatibility migrations, visual tours, editable sources, manifests, and CI—are exactly the foundations needed for a large AI-assisted game. The next improvement is not “more AI” or “less AI.” It is making the AI work inside tighter contracts, smaller review units, explicit source-authority rules, and a verification ladder that includes human perception.

The reusable principle is simple:

> Generate boldly, integrate narrowly, preserve sources, verify independently, and publish only what a human can still explain.

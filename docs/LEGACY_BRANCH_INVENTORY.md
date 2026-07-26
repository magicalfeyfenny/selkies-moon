# Legacy Branch Inventory

## Purpose and snapshot scope

This is the Issue #47 migration snapshot for the repository's existing branch
names. It records traceability and disposition as observed on 2026-07-25; it
is not routine onboarding and does not promise that mutable remote heads will
never change. The comparison base is `origin/dev` at
`3440b08163487c25f3253d8c7b7e3da49d40e683`.

The inventory covers the 27 unique non-default branch names found in local
heads and `origin` tracking refs after `git fetch origin --prune`. It excludes
the integration refs `origin/dev` and local `dev`, the release refs
`origin/main` and local `main`, and the symbolic `origin`/`origin/HEAD`
remote alias. The migration branch itself is included because it is an active
documentation/governance branch in this snapshot.

Evidence was collected with `git for-each-ref`, `git rev-parse`,
`git merge-base --is-ancestor`, `git diff --quiet`, `git log`, and GitHub issue
and pull-request metadata. `L` and `R` below mean local and `origin` presence;
when both identities are shown, they are deliberately divergent identities.
GitHub PR, issue, run, and artifact numbers are durable evidence identifiers.

## Classification definitions

- **Active documentation/governance**: current bounded governance work that
  may receive only its registered scope.
- **Validation-only**: preserved test/characterization evidence, not a merge
  candidate and not a source of further substantive work.
- **CI/tooling**: preserved workflow identity, independent from candidates it
  once exercised.
- **Merged/completed**: work integrated through the cited PR or demonstrated
  equivalent integrated tree/patch; original commit ancestry need not survive
  a squash or rewrite.
- **Historical reference**: retained provenance that must not be revived or
  merged without a new primary issue and branch; it may describe superseded or
  reverted work.

## Exempt references

| Reference | Exact SHA | Reason |
| --- | --- | --- |
| `origin/dev` | `3440b08163487c25f3253d8c7b7e3da49d40e683` | Integration comparison base. |
| local `dev` | `acdf8e529ffe68e38fb87580c73ca5cee2286f6d` | Divergent local integration reference; out of scope and untouched. |
| `origin/main` and local `main` | `cd1f35e35dd8f6b1c36d3df8f4b75006f27e1ca6` | Release-pinned reference. |

## Approved category totals

| Category | Count |
| --- | ---: |
| Active implementation | 0 |
| Active documentation/governance | 1 |
| Validation-only | 1 |
| CI/tooling | 1 |
| Merged/completed | 20 |
| Historical reference, including superseded extraction | 4 |
| Abandoned | 0 |
| Unknown | 0 |
| **Total** | **27** |

## Active documentation/governance (1)

- **`codex/47-register-legacy-branches`** — `L,R`
  `3440b08163487c25f3253d8c7b7e3da49d40e683`; category: active
  documentation/governance; associated record: Issue #47 (no PR yet at this
  snapshot). Purpose: create this migration inventory and durable legacy
  registrations. Merge intention: intended to merge into `dev` only through
  its own exact-head review and separately granted authority. Validation:
  governance and hygiene checks are required before publication. Legacy-name
  status: conformant issue-numbered name. Additional substantive work: only
  Issue #47 scope. Disposition: retain as the live migration candidate until
  its draft PR has completed the governed lifecycle. Evidence: Issue #47 and
  comparison-base identity above.

## Validation-only (1)

- **`validation/ornate-ui-characterization-acdf8e5`** — `R`
  `acdf8e529ffe68e38fb87580c73ca5cee2286f6d`; category: validation-only;
  associated records: Issue #54 and open PR #52. Purpose: six-test ornate UI
  characterization evidence. Merge intention: not intended to merge.
  Validation: GMTL runs 29889767822 and 29889855774; visual-tour run
  29889883786; artifacts 8517827393, 8517851190, 8517875522, and 8517875688.
  Legacy-name status: retained legacy exception under Issue #47. Additional
  substantive work: prohibited. Disposition: retain unchanged until a clean
  replacement characterization preserves its required contracts and extraction
  no longer depends on the evidence; deletion requires separate authority.

## CI/tooling (1)

- **`codex/ornate-ui-visual-tour-ci`** — `R`
  `23340db00676a343c826db3ef51ef2b2e60aa543`; category: CI/tooling;
  associated record: Issue #60 under Issue #47; no PR is useful for this
  archival workflow identity.
  Purpose: retain the exact visual-tour workflow used for ornate UI candidates. Merge intention:
  not intended to merge. Validation/evidence: run 29889883786 built
  `acdf8e529ffe68e38fb87580c73ca5cee2286f6d` (artifacts 8517875522 and
  8517875688); run 29890720589 built `b090a49f2211d01e19c8b430089a84821130a5bb`
  (artifacts 8518162147 and 8518162552); run 29891263867 built
  `40c6ef01f81303ac8807f2dcea6354d56d33d6d9` (artifacts 8518337972 and
  8518338126). Artifact expiry: 2026-08-05. Legacy-name status: retained
  legacy exception under Issue #47. Additional substantive work: prohibited.
  Disposition: retain until clean replacement work no longer depends on it and
  logs, manifests, hashes, and review conclusions are preserved durably;
  deletion requires separate authority.

## Merged/completed (20)

- **`codex-bootstrap-gmtl`** — `L,R`
  `f2bc5115383bde5601e96c0aa7896d5fcf52b1d3`; associated PR #1 to `main`;
  category: merged/completed. Purpose: bootstrap GMTL. Merge intention:
  completed. Validation: PR #1 merge record. Legacy-name status: retained
  pre-policy name, registered by this inventory. Additional substantive work:
  no. Disposition: historical branch reference; do not revive it.
- **`codex/46-branch-pr-lifecycle-policy`** — `L,R`
  `c8c5a9824a0b8d24bab26cf7226a97a1e8bfda75`; associated Issue #46 and
  merged PR #59 to `dev`; category: merged/completed. Purpose: lifecycle
  policy. Merge intention: completed. Validation: merge commit
  `3440b08163487c25f3253d8c7b7e3da49d40e683`. Legacy-name status: conformant
  issue-numbered name. Additional substantive work: no. Disposition: retained
  completed reference.
- **`codex/53-structural-decomposition-plan`** — `L,R`
  `19f62d4c6eb136102f9f81529723a979f4019dd7`; associated Issue #53 and
  merged PR #58 to `dev`; category: merged/completed. Purpose: structural
  decomposition plan and skills. Merge intention: completed. Validation:
  merge record. Legacy-name status: conformant issue-numbered name. Additional
  substantive work: no. Disposition: retained completed reference.
- **`codex/55-repository-foundation`** — `L,R`
  `4e5d247cd92b94efcc77b6cfcebbb88c0dae84d7`; associated Issue #55 and
  merged PR #57 to `dev` (earlier PR #56 closed); category: merged/completed.
  Purpose: repository validation and handoff foundation. Merge intention:
  completed. Validation: merge record. Legacy-name status: conformant
  issue-numbered name. Additional substantive work: no. Disposition: retained
  completed reference.
- **`codex/agent-review-governance`** — `R`
  `ccb1983839a558ad86030175e53903b80182e37f`; associated Issue #16 and
  merged PR #45 to `dev`; category: merged/completed. Purpose: delegated
  review governance. Merge intention: completed. Validation: merge record.
  Legacy-name status: retained pre-policy name, registered by this inventory.
  Additional substantive work: no. Disposition: retained completed reference.
- **`codex/boss-variety-overhaul`** — divergent `L`
  `08e76bf280103947084a157d397b31b18a8dab1b`, `R`
  `785f03c3ead908d66cf85ac597385726a22d3821`; associated merged PR #9 to
  `dev`; category: merged/completed. Purpose: boss variety and encounters.
  Merge intention: completed. Validation: PR #9 merge record. Legacy-name
  status: retained pre-policy name, registered by this inventory. Additional
  substantive work: no. Disposition: retain divergent identities as historical
  provenance; do not rewrite either.
- **`codex/build-player-object`** — `L,R`
  `dc966fdbb6dd5b57208d3aab8a1cc56672ec8fda`; associated merged PR #6 to
  `main`; category: merged/completed. Purpose: gameplay systems. Merge
  intention: completed. Validation: PR #6 merge record. Legacy-name status:
  retained pre-policy name, registered by this inventory. Additional
  substantive work: no. Disposition: retained completed reference.
- **`codex/create-dialogue-handler`** — `L`
  `6d0f39a030876fcf1d668b277c395a93d853a465`; no separate PR; shared exact
  tip with merged PR #3 (`codex/create-title-menu`) to `main`; category:
  merged/completed. Purpose: dialogue-handler precursor. Merge intention:
  completed through the integrated shared tree. Validation: PR #3 merge
  evidence. Legacy-name status: retained pre-policy name. Additional
  substantive work: no. Disposition: retain local provenance only.
- **`codex/create-title-menu`** — `L,R`
  `6d0f39a030876fcf1d668b277c395a93d853a465`; associated merged PR #3 to
  `main`; category: merged/completed. Purpose: title-menu flow. Merge
  intention: completed. Validation: PR #3 merge record. Legacy-name status:
  retained pre-policy name. Additional substantive work: no. Disposition:
  retained completed reference.
- **`codex/crystal-ui-refraction`** — divergent `L`
  `75d43d82fb970a0b8a9dbf5c56be7f9c086cc1d6`, `R`
  `595cc9cab7c9324ad9cb3b131a960c6f034fb999`; associated merged PR #12 to
  `dev`; category: merged/completed. Purpose: refractive crystal UI and CI
  compatibility. Merge intention: completed. Validation: PR #12 and remote
  tree equivalence to integrated commit
  `77e65d798e4f24541f613c4869d1f836e83d8582`; original commit ancestry is
  not required. Legacy-name status: retained pre-policy name. Additional
  substantive work: no. Disposition: retain divergent identities as
  post-integration provenance.
- **`codex/development-postmortem`** — divergent `L`
  `d5ca3be1142adcac404d2bd74c11823a2ef70297`, `R`
  `c3b711d49090b5fd0e221d188707ad3b0192432d`; associated merged PR #13 to
  `dev`; category: merged/completed. Purpose: post-mortem and KRA authority.
  Merge intention: completed after the coordinated history rewrite. Validation:
  remote tree equivalence to integrated commit
  `8f6832e93fe944020a6b1341d780dc673321f021`; ancestry is not the sole
  integration test. Legacy-name status: retained pre-policy name. Additional
  substantive work: no. Disposition: retain divergent historical identities.
- **`codex/fenny-player-object-game-rules-scaffolding`** — `L,R`
  `76c7880601d6e3c2cab258c5c9348ea245a11a6b`; associated merged PR #5 to
  `main`; category: merged/completed. Purpose: player and rules scaffolding.
  Merge intention: completed. Validation: PR #5 merge record. Legacy-name
  status: retained pre-policy name. Additional substantive work: no.
  Disposition: retained completed reference.
- **`fenny-scaffolding`** — `L,R`
  `6dd322ca271a6da7245fad71215f858c74ee9871`; associated merged PR #2 to
  `main`; category: merged/completed. Purpose: object scaffolding. Merge
  intention: completed. Validation: PR #2 merge record. Legacy-name status:
  retained pre-policy name. Additional substantive work: no. Disposition:
  retained completed reference.
- **`codex/implement-story-ui`** — `L,R`
  `558eb3ee528538758e5f1e7a753529fe167142d5`; associated merged PR #4 to
  `main`; category: merged/completed. Purpose: story dialogue UI. Merge
  intention: completed. Validation: PR #4 merge record. Legacy-name status:
  retained pre-policy name. Additional substantive work: no. Disposition:
  retained completed reference.
- **`codex/lush-3d-boss-route-overhaul`** — divergent `L`
  `f5bec7cda3fb1cb49f9b5f4c0ce82382f19a422e`, `R`
  `a603b2b574930d21bca39e7b69948174585e5e0e`; associated merged PR #11 to
  `dev`; category: merged/completed. Purpose: lush 3D route and finale. Merge
  intention: completed. Validation: PR #11 merge record. Legacy-name status:
  retained pre-policy name. Additional substantive work: no. Disposition:
  retain divergent historical identities.
- **`codex/mechanics-polish-pass`** — divergent `L`
  `f0340940bdf9dce2fe0bd6e3a7347e039d651339`, `R`
  `487f36d0e5ca0fd80badf91187539063f6b42e7a`; associated merged PR #8 to
  `dev`; category: merged/completed. Purpose: movement and firing polish.
  Merge intention: completed. Validation: PR #8 merge record. Legacy-name
  status: retained pre-policy name. Additional substantive work: no.
  Disposition: retain divergent historical identities.
- **`codex/neo-gothic-gameplay-overhaul`** — divergent `L`
  `fe5a350fdd604db788326af6fdfcf1bcf8fa8981`, `R`
  `064303be4e6de71122187b3f42d97bbb23955b58`; associated merged PR #10 to
  `dev`; category: merged/completed. Purpose: five-stage neo-gothic overhaul.
  Merge intention: completed. Validation: PR #10 merge record. Legacy-name
  status: retained pre-policy name. Additional substantive work: no.
  Disposition: retain divergent historical identities.
- **`codex/player-controls`** — `L`
  `558eb3ee528538758e5f1e7a753529fe167142d5`; no separate PR; shared exact
  tip with merged PR #4 (`codex/implement-story-ui`) to `main`; category:
  merged/completed. Purpose: player-controls precursor. Merge intention:
  completed through the integrated shared tree. Validation: PR #4 merge
  evidence. Legacy-name status: retained pre-policy name. Additional
  substantive work: no. Disposition: retain local provenance only.
- **`codex/repository-hygiene-gates`** — `R`
  `61e8605a0ad44fd41b97399ad4d442d59d8dc025`; associated Issue #14 and
  merged PR #44 to `dev`; category: merged/completed. Purpose: hygiene gates.
  Merge intention: completed. Validation: PR #44 merge record. Legacy-name
  status: retained pre-policy name. Additional substantive work: no.
  Disposition: retained completed reference.
- **`codex/visual-polish-pass`** — divergent `L`
  `81171d5dafd414045cfabadbba2a228e4f275940`, `R`
  `fd10773af21c760fe76903dc34dd70ebfa874be0`; associated merged PR #7 to
  `dev`; category: merged/completed. Purpose: visual polish and visual tour.
  Merge intention: completed. Validation: PR #7 merge record. Legacy-name
  status: retained pre-policy name. Additional substantive work: no.
  Disposition: retain divergent historical identities.

## Historical reference (4)

- **`codex/10-stage-selkie-update`** — `L`
  `f5057fbbea8253690f6f56c9e11778f983e1ae98`; associated evidence: commit
  `642588917d788db08bad11932a0ea4edabc0c52b`, followed by the release-line
  revert at `cd1f35e35dd8f6b1c36d3df8f4b75006f27e1ca6`; category: historical
  reference. Purpose: the 10-stage Selkie update explicitly reverted from the
  release line. Merge intention: not intended to merge. Validation: historical
  commit/revert evidence. Legacy-name status: retained legacy exception under
  Issue #47. Additional substantive work: prohibited. Disposition: retain as
  reference only; any future implementation needs a new issue, branch, and PR.
- **`codex/extract-ornate-ui`** — `L,R`
  `c6c6307ac8d0cf5bf678a0307a9b7c6384093036`; associated Issue #50 and open
  PR #51; category: historical/superseded implementation evidence. Purpose:
  retain provenance for the intended 11-helper ornate UI extraction. Merge
  intention: not intended to merge. Validation: GMTL run 29891263836 and
  visual-tour run 29891263867 apply only to historical candidate
  `40c6ef01f81303ac8807f2dcea6354d56d33d6d9`, not the retained current head.
  Current-head difference: `.DS_Store` and
  `options/mac/options_mac.yy` display-name correction; there is no exact-head
  workflow, authoritative GMTL summary, visual capture, executable validation,
  or fresh review for `c6c6307ac8d0cf5bf678a0307a9b7c6384093036`. Legacy-name
  status: retained legacy exception under Issue #47. Additional substantive
  work: prohibited. Disposition: retain as provenance until clean replacement
  work no longer needs it; deletion requires separate authority.
- **`codex/fix-current-playtest-launch`** — `L`
  `0e570044ffb600e1e15376494be4e4749cfa8eba`; associated evidence: historical
  commit identity immediately following the PR #9 merge sequence; category:
  historical reference. Purpose: preserve the local playtest-launch reference
  without manufacturing a retrospective PR. Merge intention: not intended to
  merge. Validation: no independent current validation record retained.
  Legacy-name status: retained legacy exception under Issue #47. Additional
  substantive work: prohibited. Disposition: retain as provenance only; a new
  issue and branch are required for future work.
- **`codex/ornate-ui-m1-validation-docs`** — `R`
  `ea640a11a8950e40a29e384ccc55c96890bb26d7`; associated evidence: the
  characterization candidate
  `acdf8e529ffe68e38fb87580c73ca5cee2286f6d`; category: historical reference.
  Purpose: completed milestone-1 validation documentation. Merge intention:
  not intended to merge. Validation: applies to the cited characterization
  candidate, not an assertion about a mutable future branch state. Legacy-name
  status: retained legacy exception under Issue #47. Additional substantive
  work: prohibited. Disposition: retain as historical evidence; new work needs
  a new primary issue and PR.

## Registration completion record

The `legacy-branch-name` label was created with the description “Predates
issue-numbered branch governance and is retained under issue #47.” It was
applied to Issues #50, #54, and #60, and to open PRs #51 and #52. Issues #50
and #54 remain open archival records; PRs #51 and #52 remain open and their
branches are not intended to merge.

The PR label application completed, but PR-body registration is intentionally
deferred. Proposed bodies for #51 and #52 pass the current grammar, legacy
field, contract, high-risk-path, and simulated-attestation checks with their
live PR number, base, and head. The same live checker rejects both immutable
heads because neither contains the live `dev` base
`7cbb17daa5f8da86f4da14b49a329297a743cbd1`. Updating their bodies would
therefore violate the approved requirement that the proposed body pass before
it is saved. No base, head, branch ref, workflow, issue state, or PR state was
changed to bypass that gate.

Issue #60, **[Legacy CI] Retain ornate UI visual-tour workflow evidence**,
records the `codex/ornate-ui-visual-tour-ci` identity. No legacy branch was
renamed, modified, or deleted.

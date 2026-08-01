# Branch and Release Policy

This policy governs repository work and releases from its adoption onward. The
source commit for binaries published before this policy may not be recoverable
with certainty; do not claim that the historical `main` branch matches a
published binary without separate evidence. The first release made under this
policy establishes the verified baseline.

## Issue, branch, and pull-request lifecycle

This is the authoritative repository policy for the lifecycle of every future
non-default branch. `dev` and `main`, the declared integration/default
branches, are exempt. Create one primary GitHub issue before creating a branch;
that issue is the authoritative bounded task contract. Each non-default branch
has exactly one primary issue and exactly one primary pull request, and a
primary issue is never reused for a second branch.

Use `codex/<issue-number>-<short-slug>` where practical. `validation/`,
`hotfix/`, and `release/` are approved prefixes, but their branch names still
include the primary issue number; a release stabilization branch is
`release/<issue-number>-vX.Y.Z`. Push after the first coherent commit and open
a linked draft PR shortly afterward. Keep the PR body current as candidate,
risk, scope, and evidence change. Make it ready only after its acceptance
criteria, validation, and required review are complete. Open a separate issue
for follow-up work rather than silently expanding scope.

The primary issue includes these concise sections: objective, acceptance
criteria, non-goals, expected validation, known risks and blockers,
external-action authority, dependencies, and relevant repository documents or
milestones. The PR records its primary issue, scope and non-goals,
acceptance-criteria mapping, important files or ownership changes, validation
evidence, review status, remaining risks, merge intention, external-action
authority, and rollback or final disposition. Use `Closes #<issue>` only when
merging should complete that primary issue.

The PR checker verifies branch/issue syntax deterministically, and the
authorized GitHub workflow verifies that the named primary issue exists. The
requirement that an issue predate branch creation remains a documented rule:
it cannot be reconstructed reliably after the fact without a brittle history
claim.

For an already approved bounded task, standing authority covers creating its
primary issue, its issue-numbered branch, a push, a linked draft PR, and
validation or review evidence. It does not cover merging, closing incomplete
work as complete, force-pushing or rewriting history, deleting branches,
tagging, releasing, deploying, publishing binaries, changing repository
visibility or access, or expanding scope. Each requires separate explicit
authority. Review approval establishes readiness only; it never grants merge,
release, deployment, or publication authority.

### Non-merge, validation, and legacy branches

`validation/` is an approved issue-numbered branch prefix, not a non-merge
disposition. A validation branch that adds durable reviewed tests,
characterization, documentation, or other repository changes may be intended
to merge and follows the same exact-base, contract, review, CI, readiness, and
merge-authority requirements as every other merge-intended branch.

Validation-only, CI/tooling, documentation, archival, and other explicitly
non-mergeable branches use the same issue and PR lifecycle. Their contract
records purpose, exact candidate or workflow SHA, retained
logs/artifacts/validation evidence, and the final disposition or conditions
for closing or deleting the branch. Do not infer that disposition from the
`validation/` prefix or add a process-only commit to an immutable candidate
merely to satisfy this policy.

Issue #47 owns legacy registration. Its traceability-first exception records
the original branch identity, primary issue where known, exact immutable
candidate SHA, retained evidence, intended disposition, and why normal naming
or PR linkage is unavailable. It must not rename immutable branches, rebase or
amend frozen candidates, force-push, manufacture meaningless commits or PRs,
invalidate exact identities, or delete branches without separate authority.
This policy does not inventory, register, alter, close, or delete legacy
branches; perform that migration only through #47.

## Branch roles

| Branch | Role |
| --- | --- |
| `main` | Source tree for the currently published binary release. It is not a general integration branch and must not move ahead of the published release. |
| `dev` | Normal integration branch and base for ongoing development. Completed work merges here before release promotion. |
| Feature/work branches | Short-lived, remotely backed branches for bounded changes. They normally start from `dev` and merge into `dev` through a pull request. |
| `release/<issue>-vX.Y.Z` | Optional stabilization branch cut from a frozen `dev` candidate when release-only fixes are needed. Every such fix must also return to `dev`. |
| `hotfix/<issue>-<short-slug>` | Exceptional branch cut from the current release tag or `main` for an urgent patch to the published release. |

Do not commit ordinary work directly to `main` or `dev`. Push the work branch,
open a pull request into `dev`, run the required checks, and merge only when
separately authorized. Record the final issue, PR, and branch disposition;
delete a branch only with separate authority.

## Delegated pull-request review

Independent fresh-context agent review may satisfy the review requirement
without a manual approval click from Fenny. Review depth scales from one agent
for low-risk documentation to three agents for CI, governance, source-authority,
or other high-risk changes. Every pull request into `main` requires distinct
correctness, validation, and release-governance reviews tied to the exact PR
contract, base commit, and candidate commit. See [Agent Review Policy](AGENT_REVIEW_POLICY.md).

Review readiness and merge authority are separate. An active task that
explicitly authorizes merging a named bounded change may authorize the
orchestrator to merge its passing PR into `dev` without another manual review.
The head must contain the exact current base. After the final attestation, the
orchestrator reruns the newest exact pull-request-event workflow and re-fetches
live refs, contract, and comments immediately before merge; a later trusted
attestation change requires another rerun. Manual-dispatch checks are not merge
evidence. Automatic invalidation after comment or base mutation is part of
issue #17's remote-enforcement rollout.
Advancing `main` still requires an explicit promotion or release request for
the named frozen candidate. Tagging, deploying, and publishing binaries are
separate actions and are not implied by review completion.

## Releasing from `dev`

1. Select and freeze an exact candidate from `dev`. Update version, credits,
   changelog, and release notes before freezing it. Use
   `release/<issue>-vX.Y.Z` if the candidate needs stabilization while other
   development continues.
2. Run the complete release gates and build every distributable binary from
   that exact source. Stage uploads as drafts or otherwise keep them
   unpublished while verification is incomplete.
3. Promote the candidate's unchanged source tree to `main`. A fast-forward is
   preferred. If branch protection requires a merge commit, verify that its
   tree is identical to the tested candidate; never squash, rebase, or add
   content during promotion. Complete the required delegated main-promotion
   reviews against that exact candidate and base before merging.
4. Create an annotated `vX.Y.Z` tag for the exact source used to build the
   binaries. Record the source identifier, supported platforms, toolchain, and
   artifact checksums in the release notes.
5. Publish the staged binaries and release notes together, then verify that the
   current `main` tree, release tag tree, and published artifacts describe the
   same release. Do not advance `main` again until replacement binaries are
   ready to publish.
6. Merge any release-only fixes back into `dev` so development does not lose
   them.

## Hotfixes

A hotfix is the one normal exception to the `dev`-first merge path. Branch from
the current `vX.Y.Z` tag or `main`, make only the release-blocking correction,
and validate/build it as a new patch release. Promote it to `main`, tag it with
a new version, and publish its binaries using the same release procedure. Then
forward-port the exact fix to `dev` through a pull request. Never silently
replace binaries beneath an existing version tag.

## History rewrites

Published history is immutable by default. A coordinated repository-wide
maintenance operation, such as an explicitly approved Git LFS migration, is a
rare exception; tidying individual commits is not.

Before an approved rewrite, freeze pushes, finish or pause open pull requests,
make backup refs, and record the old identifiers for `main`, `dev`, release
tags, and published artifacts. Rewrite all affected refs in one operation and
use force-with-lease rather than an unguarded force-push. Afterwards, verify
branch contents, tag contents, LFS availability, and release provenance, then
tell every collaborator to re-clone or deliberately reset/rebase their work.

If storage migration changes a published tag's object identifier, record the
old and new identifiers and prove that the checked-out source content is
unchanged. A version tag must never be reused for different source content.

The coordinated 2026 asset-history rewrite and its unchanged immutable release
anchor are recorded in [Git LFS Migration](LFS_MIGRATION.md).

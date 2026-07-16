# Branch and Release Policy

This policy governs repository work and releases from its adoption onward. The
source commit for binaries published before this policy may not be recoverable
with certainty; do not claim that the historical `main` branch matches a
published binary without separate evidence. The first release made under this
policy establishes the verified baseline.

## Branch roles

| Branch | Role |
| --- | --- |
| `main` | Source tree for the currently published binary release. It is not a general integration branch and must not move ahead of the published release. |
| `dev` | Normal integration branch and base for ongoing development. Completed work merges here before release promotion. |
| Feature/work branches | Short-lived, remotely backed branches for bounded changes. They normally start from `dev` and merge into `dev` through a pull request. |
| `release/vX.Y.Z` | Optional stabilization branch cut from a frozen `dev` candidate when release-only fixes are needed. Every such fix must also return to `dev`. |
| `hotfix/*` | Exceptional branch cut from the current release tag or `main` for an urgent patch to the published release. |

Do not commit ordinary work directly to `main` or `dev`. Push the work branch,
open a pull request into `dev`, run the required checks, and merge only the
reviewed scope. Delete the work branch when it is no longer useful.

## Releasing from `dev`

1. Select and freeze an exact candidate from `dev`. Update version, credits,
   changelog, and release notes before freezing it. Use `release/vX.Y.Z` if the
   candidate needs stabilization while other development continues.
2. Run the complete release gates and build every distributable binary from
   that exact source. Stage uploads as drafts or otherwise keep them
   unpublished while verification is incomplete.
3. Promote the candidate's unchanged source tree to `main`. A fast-forward is
   preferred. If branch protection requires a merge commit, verify that its
   tree is identical to the tested candidate; never squash, rebase, or add
   content during promotion.
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

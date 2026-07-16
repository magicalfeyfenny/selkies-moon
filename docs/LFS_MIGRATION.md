# Git LFS Migration Record

This document records the coordinated Git LFS history migration that followed
[pull request #13](https://github.com/magicalfeyfenny/selkies-moon/pull/13).
PR #13 established KRA-only source authority, added LFS pointers for its newly
introduced KRAs, and deliberately deferred rewriting existing Krita, Blender,
music, SFX, runtime, and interchange history to a separate maintenance task.
This migration addresses that deferred repository-storage work without
changing the source-authority rules in [Asset Pipeline](ASSET_PIPELINE.md).

This file retains verified pre-rewrite identifiers and records verified
post-rewrite identifiers separately in the completion evidence below. The
authoritative old-to-new object map and the pre-rewrite backup remain outside
the rewritten repository.

## Immutable jam release anchor

The historical jam release remains immutable and outside the rewrite:

| Item | Preserved value |
| --- | --- |
| Lightweight tag | `jam` |
| Tagged commit | `7e6de657ec998e1065858f4f8a38879ad1dc75c6` |
| GitHub release | [`v0.1-alpha` (`jam`)](https://github.com/magicalfeyfenny/selkies-moon/releases/tag/jam), published as a prerelease on 2026-04-14 |

Do not move, delete, recreate, or force-update `refs/tags/jam`, and do not edit
or replace the hosted release beneath it. It is intentional that objects kept
alive only by this tag remain ordinary historical Git objects rather than LFS
pointers. The release assets remain attached to the preserved tag:

| Release asset | Recorded SHA-256 |
| --- | --- |
| `selkies-moon.AppImage` | `8e6468612c8cf343dc190b99a003eb0f316754a254bd879b942a6375fc4925d8` |
| `Selkies.Moon.dmg` | `98ca8e1185c45c2b542e08d48450a0041d79ac8fc777aed177d5e3451e2a4f7d` |
| `Selkies.Moon.zip` | `dd85ad07b926ae1d80be01c8b468c4a150f8587f8142462617ffa925a8e0c42f` |

## Pre-rewrite remote heads

The migration preflight compared the current `origin` heads with this
`git for-each-ref` snapshot. These are the 15 old branch tips that the rewrite
must map and that force-with-lease protection must use:

| Remote head | Old commit |
| --- | --- |
| `codex-bootstrap-gmtl` | `f2bc5115383bde5601e96c0aa7896d5fcf52b1d3` |
| `codex/boss-variety-overhaul` | `08e76bf280103947084a157d397b31b18a8dab1b` |
| `codex/build-player-object` | `dc966fdbb6dd5b57208d3aab8a1cc56672ec8fda` |
| `codex/create-title-menu` | `6d0f39a030876fcf1d668b277c395a93d853a465` |
| `codex/crystal-ui-refraction` | `75d43d82fb970a0b8a9dbf5c56be7f9c086cc1d6` |
| `codex/development-postmortem` | `d5ca3be1142adcac404d2bd74c11823a2ef70297` |
| `codex/fenny-player-object-game-rules-scaffolding` | `76c7880601d6e3c2cab258c5c9348ea245a11a6b` |
| `codex/implement-story-ui` | `558eb3ee528538758e5f1e7a753529fe167142d5` |
| `codex/lush-3d-boss-route-overhaul` | `f5bec7cda3fb1cb49f9b5f4c0ce82382f19a422e` |
| `codex/mechanics-polish-pass` | `f0340940bdf9dce2fe0bd6e3a7347e039d651339` |
| `codex/neo-gothic-gameplay-overhaul` | `fe5a350fdd604db788326af6fdfcf1bcf8fa8981` |
| `codex/visual-polish-pass` | `81171d5dafd414045cfabadbba2a228e4f275940` |
| `dev` | `4577dc9735426af5c0c2e68fb93363e603b2d0ba` |
| `fenny-scaffolding` | `6dd322ca271a6da7245fad71215f858c74ee9871` |
| `main` | `f5057fbbea8253690f6f56c9e11778f983e1ae98` |

No post-rewrite SHA belongs in this table. Store the generated old-to-new
mapping beside the external backup and use it for provenance and recovery.

## Rewrite scope

The coordinated rewrite covers every old remote head above and every historical
file in the audited asset families. The `jam` tag is excluded.

- canonical masters: `.blend`, `.kra`, monolithic `.logicx`, and every file
  recursively inside a `.logicx` package;
- runtime and interchange derivatives: `.mtl`, `.obj`, `.ogg`, `.png`,
  `.vbuff`, and `.wav`; and
- legacy, bootstrap/reference, and other binary assets: `.jpeg`, `.jpg`,
  `.mid`, `.ora`, and `.ttf`.

Tracking a file in LFS changes storage representation, not its authority or
whether it belongs in a shipped package. The runtime still uses PNG, WAV, OGG,
and VBUFF; authoring still begins only from BLEND, KRA, or Logic as defined in
the asset policy.

## Coordinated procedure and retained evidence

1. Freeze all pushes and pause or finish open pull requests. Confirm that each
   remote head still equals the old identifier above; abort on any mismatch.
2. Create a full pre-rewrite mirror or bundle in storage outside this checkout
   and outside any location that a repository cleanup can prune. Verify the
   backup before rewriting.
3. Rewrite the 15 heads in one operation, excluding `refs/tags/jam`, and ask
   Git LFS migration tooling to write its old-to-new object map to the external
   evidence directory. Do not store the only copy inside rewritten history.
4. Retain the mirror, object map, migration command/log, LFS object inventory,
   and release checksums without automatic expiry. They are the recovery and
   provenance record for old commit links.
5. Upload every required LFS object before moving a remote head. Update each
   head with a force-with-lease expectation fixed to its recorded old SHA;
   never use an unguarded force push.
6. Verify all rewritten refs, `git lfs fsck`, pointer integrity, asset counts,
   and a fresh-clone GameMaker build. Compare source trees semantically where
   native archives contain nondeterministic metadata.
7. Reconfirm that `refs/tags/jam`, the `v0.1-alpha` release, and its hosted
   artifacts are unchanged, then end the push freeze and notify collaborators.

## Completion evidence (2026-07-16)

The coordinated migration completed with `git-lfs/3.7.1`. The import rewrote
32 commit objects reachable from the 15 recorded branch heads, excluded
`refs/tags/jam`, and left no selected post-jam asset blob in ordinary Git
storage. Before any branch ref moved, `git lfs push --all` completed for the
1,030 required LFS objects, whose payloads total 1,255,854,035 bytes. One
atomic branch push then used an explicit `--force-with-lease` expectation for
each recorded old head. A post-push `git ls-remote --heads` matched the
published tips below exactly.

| Branch | Old remote tip | Atomic migration-push tip |
| --- | --- | --- |
| `codex-bootstrap-gmtl` | `f2bc5115383bde5601e96c0aa7896d5fcf52b1d3` | `f2bc5115383bde5601e96c0aa7896d5fcf52b1d3` |
| `codex/boss-variety-overhaul` | `08e76bf280103947084a157d397b31b18a8dab1b` | `785f03c3ead908d66cf85ac597385726a22d3821` |
| `codex/build-player-object` | `dc966fdbb6dd5b57208d3aab8a1cc56672ec8fda` | `dc966fdbb6dd5b57208d3aab8a1cc56672ec8fda` |
| `codex/create-title-menu` | `6d0f39a030876fcf1d668b277c395a93d853a465` | `6d0f39a030876fcf1d668b277c395a93d853a465` |
| `codex/crystal-ui-refraction` | `75d43d82fb970a0b8a9dbf5c56be7f9c086cc1d6` | `595cc9cab7c9324ad9cb3b131a960c6f034fb999` |
| `codex/development-postmortem` | `d5ca3be1142adcac404d2bd74c11823a2ef70297` | `c3b711d49090b5fd0e221d188707ad3b0192432d` |
| `codex/fenny-player-object-game-rules-scaffolding` | `76c7880601d6e3c2cab258c5c9348ea245a11a6b` | `76c7880601d6e3c2cab258c5c9348ea245a11a6b` |
| `codex/implement-story-ui` | `558eb3ee528538758e5f1e7a753529fe167142d5` | `558eb3ee528538758e5f1e7a753529fe167142d5` |
| `codex/lush-3d-boss-route-overhaul` | `f5bec7cda3fb1cb49f9b5f4c0ce82382f19a422e` | `a603b2b574930d21bca39e7b69948174585e5e0e` |
| `codex/mechanics-polish-pass` | `f0340940bdf9dce2fe0bd6e3a7347e039d651339` | `487f36d0e5ca0fd80badf91187539063f6b42e7a` |
| `codex/neo-gothic-gameplay-overhaul` | `fe5a350fdd604db788326af6fdfcf1bcf8fa8981` | `064303be4e6de71122187b3f42d97bbb23955b58` |
| `codex/visual-polish-pass` | `81171d5dafd414045cfabadbba2a228e4f275940` | `fd10773af21c760fe76903dc34dd70ebfa874be0` |
| `dev` | `4577dc9735426af5c0c2e68fb93363e603b2d0ba` | `f441366b0e43663e063a5662b7692e9cffc122a7` |
| `fenny-scaffolding` | `6dd322ca271a6da7245fad71215f858c74ee9871` | `6dd322ca271a6da7245fad71215f858c74ee9871` |
| `main` | `f5057fbbea8253690f6f56c9e11778f983e1ae98` | `642588917d788db08bad11932a0ea4edabc0c52b` |

The retained migration map records the old PR #13 `dev` tip
`4577dc9735426af5c0c2e68fb93363e603b2d0ba` rewriting to
`8f6832e93fe944020a6b1341d780dc673321f021`. The pre-rewrite asset-policy
commit `836fd8d19b34a4d83b3b054e3acb3b66b38ac5c5`, whose parent was that PR #13
tip, rewrote to `f441366b0e43663e063a5662b7692e9cffc122a7`; that policy commit was the
`dev` tip in the atomic migration push. The documentation-only commit that
adds this completion record follows `f441366b...` and deliberately does not
embed its own SHA. Its identity is available from repository history, avoiding
a self-referential identifier.

The verified recovery evidence retained outside rewritten history is:

| Evidence file | Bytes | SHA-256 |
| --- | ---: | --- |
| `selkies-moon-pre-lfs-20260715.bundle` | 1,115,000,972 | `501d05f1c2d1f10d94212f1acb0ea8d7c9a45cf9dcd8d64f546de1537066f4f6` |
| `selkies-moon-lfs-object-map-20260715.csv` | 2,624 | `a1c52fdb4bbb11b92a872fa89a734475e72674048910f53da33ecd53a332e495` |
| `selkies-moon-lfs-old-heads-20260715.tsv` | 1,159 | `6435e1599f45239419f29de7c1a80ad77c36ace582258ce0c5bb938def46e420` |

`git bundle verify` confirmed complete history and all 16 retained refs in the
backup. The dry-run and actual 32-entry object maps were byte-identical.
Repository and LFS integrity checks passed on all 15 migrated heads, and a
content verifier matched all 513 selected assets, totaling 1,043,266,939
bytes, to their pre-rewrite payloads exactly.

A fresh clone of `dev` at `f441366b...` passed Git fsck, LFS pointer fsck, and
an all-ref inventory of 1,030 pointers before downloading content. It then
completed `git lfs fetch --all`; the resulting store contained exactly 1,030
objects totaling 1,255,854,035 bytes, and both LFS pointer and object fsck
passed. A selective checkout hydrated the 239 runtime-tree LFS files, about
146 MB, and left zero pointer stubs under
`Selkie's Moon ~ until we meet again ~/`.

A separate audit worktree at that same commit passed Logic score validation.
GMTL passed all 128 tests on attempt 3 of the configured 8-attempt retry run
after two known macOS GameMaker asset-compiler access violations. The
rewritten `dev` tip also passed the GitHub Actions Windows GameMaker workflow in
[run 29481089418](https://github.com/magicalfeyfenny/selkies-moon/actions/runs/29481089418),
including its selective runtime-tree LFS hydration step.

The Krita parity command stopped before render comparison because three
tracked font backups are not declared export targets:
`fn_dialogue_name.old.png`, `fn_subtitle.old.png`, and `fn_title.old.png`.
Each blocker existed before the rewrite and its payload matched the
pre-rewrite SHA-256 exactly. The command therefore did not produce a parity
result, while the independent 513-file content comparison established that
the migration itself introduced no asset-byte drift.

The subsequent repository-hygiene follow-up removed those unowned backup
pairs and three exact-import masters whose legacy enemy fixtures had no runtime
callers. After hydrating only the remaining 92 KRA masters, the full exporter
check rendered all 90 jobs and verified 77 sprites, 84 frames, six standalone
assets, and all 174 declared PNG targets with zero changes and 174 matches.

After the branch update, `refs/tags/jam` still resolved to
`7e6de657ec998e1065858f4f8a38879ad1dc75c6`. `gh release verify jam` passed
and reproduced the three release-asset SHA-256 values recorded above. The tag,
release, and hosted artifacts therefore remained unchanged by the migration.

### Verified-signature caveat

History rewriting creates new commit objects. A signature belongs to the old
object, so a rewritten commit does not inherit its prior GitHub **Verified**
status; generated rewrite commits are normally unsigned. Do not claim that a
new SHA carries an old signature, and do not recreate signatures or tags merely
to restore a badge. The excluded `jam` commit and tag remain byte-for-byte
unchanged. If future rewritten tips require signatures, sign those new objects
explicitly and retain the old-to-new map as the provenance link.

## Collaborator recovery

Before the freeze, collaborators must commit and push finished work, or make an
external patch, bundle, and copy of any untracked asset source. Once the freeze
begins, do not push an old-history branch.

After the rewrite, a fresh clone is the safest and preferred recovery path:

1. keep the old clone offline as a temporary recovery source;
2. clone the repository into a new directory and run `git lfs pull`;
3. verify the intended branch and assets before deleting the old clone; and
4. recreate open pull requests from rewritten branches rather than merging old
   and new histories.

For unpushed work, first preserve the old clone with a branch plus an external
bundle or patch. In the fresh clone, replay only the collaborator's own commits
onto the corresponding rewritten base with `git cherry-pick` or `git am`.
Resolve binary assets from the preserved working copy so the current
`.gitattributes` clean filter creates LFS pointers. Do not merge the old branch
wholesale and do not force-push an old-history tip.

A collaborator with a provably clean clone and no local-only commits may reset
an existing checkout deliberately after making a backup: fetch the rewritten
refs, switch to the intended branch, and reset that branch to its new remote
tip. Anyone uncertain whether local work exists must re-clone instead. A normal
`git pull` is not an appropriate recovery operation across rewritten history.

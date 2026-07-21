# Governance Handoff

This is the first repository document to read for a fresh governance task. It
records the governance implementation state as of 2026-07-21 without depending
on a prior Codex conversation.

## Authority and reading order

Current task instructions and live global Codex policy outrank repository
files. Within the repository, use this order:

1. `AGENTS.md` routes always-loaded project rules.
2. This handoff identifies current state and the owning documents.
3. [Agent Review Policy](AGENT_REVIEW_POLICY.md) owns review roles, contracts,
   attestations, and exact-head merge evidence.
4. [Branch and Release Policy](BRANCH_AND_RELEASE_POLICY.md) owns branch,
   promotion, hotfix, tag, and history-rewrite authority.
5. [Development Guide](DEVELOPMENT.md) owns project layout and verification;
   [Architecture](ARCHITECTURE.md) maps runtime subsystems and extension rules.
6. [Asset Pipeline](ASSET_PIPELINE.md) owns canonical BLEND, KRA, and Logic
   sources plus derivative ownership.

The [AI-assisted development post-mortem](AI_ASSISTED_DEVELOPMENT_POSTMORTEM.md)
is historical evidence and a status ledger. It is not live policy.

## Current governance state

- `dev` is the normal integration branch. `main` is reserved for a verified
  published-release tree; historical binary/source correspondence remains
  unproven until a policy-governed promotion establishes it.
- Issue #16 and PR #45 are the implementation record for delegated review
  governance. The live GitHub state is authoritative for whether the PR is
  still draft, merged, or has closed the issue.
- The root instructions route rather than duplicate detail. The PR template
  supplies the human acceptance sections and strict `pr-contract:v1` object.
- `tools/check_pr_governance.py` computes risk, validates exact base/head and
  acceptance bindings, accepts attestations only from the configured immutable
  GitHub identity, orders edited reviews by live update time, and applies the
  conservative plain-prose evidence gate documented in the review policy.
- `.github/workflows/gamemaker-tests.yml` fetches live PR context before running
  repository code, checks out the exact event head, and reserves `Required CI`
  for pull-request-event merge evidence.
- `tools/check_repository_hygiene.py` protects the governance files and rejects
  mixed staged/unstaged validation.
- The coordinated LFS rewrite and canonical asset-format decision are already
  recorded in [Git LFS Migration](LFS_MIGRATION.md) and
  [Asset Pipeline](ASSET_PIPELINE.md); they are not part of governance PR #45.

## Scoping, decisions, and handoffs

Start one bounded issue or explicit acceptance contract per task. Put the
outcome, scope, non-goals, risk, verification, rollback, and publish authority
in the pull request. Record adjacent work as a named issue rather than silently
expanding the change.

Durable project decisions belong in the scoped owning document above. Task
decisions, evidence, and deferred risks belong in the issue and PR. Update this
handoff only when the governance implementation or its authority map changes;
do not turn it into a general development log.

## Verification

After staging one clean intended snapshot, run from the repository root:

```zsh
python3 tools/check_repository_hygiene.py
python3 -m unittest discover -s tools/tests -p 'test_*.py'
git diff --cached --check
git status --short
```

When changing the workflow, also run:

```zsh
ruby -e "require 'yaml'; YAML.load_file('.github/workflows/gamemaker-tests.yml')"
```

For a PR, add fresh reviews for the computed risk, rerun the newest
exact `pull_request` workflow after the final attestation, require a green
`Required CI`, and re-fetch live refs, body, and comments immediately before an
authorized merge. GameMaker/GMTL is required when runtime or the workflow's
shipping path changes; governance-only local work should remain headless.

## Unresolved governance gaps

- Issue #17 owns the remote default-branch decision, rulesets, strict-current
  required checks, auto-merge/branch-deletion settings, and a trusted producer
  that invalidates status automatically after attestation comment mutations.
  Until it is implemented, the final exact PR-event rerun and immediate live
  refresh are mandatory; do not claim the remote alone enforces freshness.
- Issue #15 retains broader repository-constitution and structured task-contract
  work that is not satisfied merely by PR #45.

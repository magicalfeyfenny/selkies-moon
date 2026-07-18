# Agent Review Policy

Independent Codex review is the normal substitute for a manual approval click
in this solo, AI-assisted repository. Review depth scales with risk so small
changes stay inexpensive while broad, sensitive, or release-facing changes
receive stronger governance. The global Codex policy supplies the general
rules; this document defines this repository's roles and machine-readable
evidence.

## Authority boundary

Codex may create fresh-context review agents, collect their findings, post
review attestations, and treat a unanimous passing result as review approval.
No separate confirmation from Fenny is required for those review actions.

Review approval establishes readiness, not new authority. The orchestrating
agent may merge an approved pull request into `dev` when the active task already
authorizes implementing and publishing that bounded change. A passing review of
a pull request into `main` does not by itself authorize advancing the published
release branch, creating a tag, or publishing binaries. Those actions require
an explicit promotion or release task for the named candidate.

All spawned agents currently use the repository owner's GitHub identity. Their
independence is fresh-context and role-based, not account-level. Record their
work as delegated-review attestations and a status check, not as supposedly
identity-distinct GitHub approvals. Account-level enforcement would require a
separate GitHub App or bot.

## Independence and evidence

The primary implementation agent is the orchestrator and never counts as a
reviewer. Each reviewer must have a distinct run identifier and a narrow,
read-only first-pass brief. It receives the issue or acceptance contract,
repository policy, exact base and head, complete diff, and validation evidence,
but not the implementer's conclusions. If a reviewer edits the change, replace
it with a new fresh-context reviewer before approval.

Every reviewer reports concrete files, checks, or call paths inspected;
findings classified as P0 blocking, P1 high, P2 moderate, or P3 advisory; and
one verdict: `pass`, `request-changes`, or `blocked`. P0 and P1 findings block.
A P2 must be fixed or deferred to a named issue with evidence that the task
contract still holds. Every P2 blocks a `main` promotion unless Fenny explicitly
accepts it. P3 findings are advisory.

The orchestrator may attest `pass` only when every required role passes and no
blocking finding remains. A head commit, base advance, target change, or
semantic contract edit changes the reviewed diff and invalidates every prior
attestation.

## Risk and required roles

Risk is determined by blast radius and reversibility, not line count alone. A
mixed change uses the highest applicable class. Declaring a higher risk is
allowed; declaring lower than the path-derived class fails the check.

| Risk | Minimum trigger | Required independent roles |
| --- | --- | --- |
| `low` | Documentation-only change outside governance/release policy | `correctness` |
| `standard` | Normal code, tests, content, or derivative assets targeting `dev` | `correctness`, `validation` |
| `high` | CI, governance, dependencies, migrations, save/schema changes, canonical asset ownership, packaging, privacy/licensing/security, destructive cleanup, or broad cross-system work | `correctness`, `validation`, `governance` |
| `main-promotion` | Every pull request targeting `main` | `correctness`, `validation`, `release-governance` |

Pull requests into `main` must come from `dev`, an exact `release/vX.Y.Z`
branch, or a nonempty `hotfix/*` branch. Ordinary feature branches target
`dev`. A main-promotion contract identifies the exact candidate commit and Git
tree so the promotion cannot quietly change the tested source.

### Review briefs

- `correctness`: inspect behavior, edge cases, regressions, security, resource
  reachability, and whether the complete diff satisfies the issue.
- `validation`: inspect and rerun safe checks, audit false-green or skipped
  paths, and verify test, documentation, and asset consequences.
- `governance`: inspect scope, authority, policy consistency, source/generated
  ownership, dependencies, rollback, and whether the change weakens its own
  safeguards.
- `release-governance`: inspect candidate/tree identity, full release gates,
  version/credits/changelog, artifact provenance, hotfix forward-porting, and
  exact correspondence with the authorized release plan.

## Pull-request contract

The PR body keeps the human-readable sections from the repository template and
exactly one hidden `pr-contract:v1` JSON object. The contract uses full Git
identifiers and names the implementation run. Its canonical SHA-256 is computed
from UTF-8 JSON with sorted keys and compact separators. The contract also
contains `acceptance_sha256`, a canonical digest of the entire PR body except
for the unique `pr-contract:v1` machine comment, after line-ending and
non-semantic trailing-whitespace normalization. Editing a
required section or adding visible scope elsewhere therefore changes the
contract hash and invalidates its reviews.

Required headings count only when they are rendered as top-level Markdown;
headings hidden in HTML comments or shown inside code are not contract
sections. Machine contracts and attestations likewise count only as HTML
comments beginning at column zero outside fenced, indented, or inline code.
Raw HTML blocks are not permitted in a review contract or attestation; use
ordinary Markdown or a fenced example instead.

```text
<!-- pr-contract:v1
{
  "version": 1,
  "repository": "magicalfeyfenny/selkies-moon",
  "pr_number": 45,
  "head_sha": "<40-character PR head SHA>",
  "base_sha": "<40-character PR base SHA>",
  "base_ref": "dev",
  "head_ref": "codex/example",
  "implementation_agent": "codex-thread:<thread-id>/root",
  "acceptance_sha256": "<64-character canonical PR-body SHA-256>",
  "risk": "standard",
  "controls": {
    "target_branch": "dev",
    "lfs": "not-applicable",
    "generated_ownership": "not-applicable",
    "documentation": "updated"
  }
}
-->
```

For `main-promotion`, the contract additionally requires `candidate_sha` equal
to the PR head and `candidate_tree` equal to that commit's full Git tree ID.
Those fields are forbidden for other risk classes. Unknown fields, duplicate
JSON keys, duplicate required headings, short SHAs, stale visible-acceptance
digests, and placeholders are invalid.

## Reviewer attestations

Each independent reviewer posts one separate PR comment containing its report
and exactly one hidden attestation. Keeping reviews out of the author-editable
PR body makes the acceptance contract and reviewer evidence distinct.

```text
<!-- agent-review:v1
{
  "version": 1,
  "repository": "magicalfeyfenny/selkies-moon",
  "pr_number": 45,
  "head_sha": "<40-character PR head SHA>",
  "base_sha": "<40-character PR base SHA>",
  "base_ref": "dev",
  "head_ref": "codex/example",
  "contract_sha256": "<64-character canonical contract SHA-256>",
  "implementation_agent": "codex-thread:<thread-id>/root",
  "risk": "standard",
  "role": "correctness",
  "reviewer_agent": "codex-thread:<thread-id>/root/correctness-review",
  "verdict": "pass",
  "blocking_findings": [],
  "evidence": [
    "Inspected the complete base-to-head diff and traced the changed callers."
  ]
}
-->
```

The `PR governance` check fetches live PR metadata and comments, computes the
minimum risk from the target and both old/new paths of changes, verifies the
strict contract schema, and requires unique non-implementing agents for every
role. Copied attestations, stale head or base identifiers, stale contract
hashes, unresolved blocking findings, and nonpassing verdicts fail.
Only comments from the repository's configured trusted review identity are
eligible; untrusted commenters can neither approve nor block the check by
copying a marker. The newest trusted attestation for each role supersedes older
historical comments, so a corrected commit can be reviewed again without
erasing the earlier report. A current trusted request-changes or blocking
finding fails governance even when that review role was optional for the
computed tier.

GitHub does not start a pull-request workflow merely because an issue comment
was added. After posting the required review comments, the orchestrator reruns
the current governance workflow (or moves the draft to ready) so the live
comments are evaluated against the same head. This is an automated coordination
step, not a request for Fenny to approve the review.

## Mandatory escalation

Stop and request direction when:

- required reviewers disagree or remain blocked after repair and rereview;
- a required check fails, is unavailable, or is skipped without an explicit
  policy exception;
- a correctness, security, data-loss, privacy, licensing, or provenance finding
  remains unresolved;
- work would expose or rotate secrets, rewrite published history, change
  canonical source authority, or exceed the active task's authorization;
- a `main` candidate cannot be tied exactly to the tested build and requested
  release.

## GitHub enforcement boundary

The check runs on pull requests into `dev` and `main`. Remote rulesets,
required-check sources, default-branch choice, and auto-merge settings belong to
issue #17 and must be bootstrapped and tested before enforcement. Until then,
this is a mandatory Codex policy plus visible CI evidence, not a claim that the
unprotected remote cannot be bypassed.

Because a same-repository pull request can modify its own workflow, a policy or
workflow self-change requires the independent governance role even when CI is
green. Once the trusted workflow is present on the release/default branch,
remote protection should bind the stable aggregate check to GitHub Actions and
disallow direct pushes.

<!--
Under every required heading, write at least one separate, unindented
plain-prose sentence. Lists, checkboxes, quotes, links, and examples may follow
but do not satisfy the evidence gate by themselves.
-->

## Primary issue

<!-- Name exactly one primary issue as #<number>. Use Closes #<number> only when merging should complete it. -->

## Intent

<!-- State the outcome and why the primary issue needs it. -->

## Scope

<!-- List the bounded changes included in this PR. -->

## Non-goals

<!-- State nearby work deliberately left out or deferred to a named issue. -->

## Acceptance mapping

<!-- Map each acceptance criterion to the scoped change or validation evidence. -->

## Important files and ownership

<!-- Name important files and any runtime, generated, or policy owner affected. -->

## Risk

<!-- Declare low, standard, high, or main-promotion and explain the largest failure mode. -->

- [ ] Target branch and authority are correct.
- [ ] LFS payload availability is verified or explicitly not applicable.
- [ ] Generated/runtime ownership is verified or explicitly not applicable.
- [ ] Documentation is updated or verified current.
- [ ] Rollback is concrete and safe.

## Validation

<!-- Map each acceptance criterion to exact commands, checks, or inspected artifacts. Explain any unavailable signal. Include provenance plus inspected visual/audio evidence for affected assets. -->

## Review status

<!-- State the required review tier, current attestation status, and any remaining review work. -->

## Remaining risks

<!-- State unresolved risks, blockers, dependencies, or explicitly say none remain. -->

## Merge intention

<!-- State exactly whether this branch is intended to merge or not intended to merge. A validation branch may be merge-intended; validation-only and other explicitly non-merge branches must say not intended to merge. -->

## External-action authority

<!-- State whether merge, release, deployment, or publication authority was granted. Review approval never grants it. -->

## Rollback or final disposition

<!-- Explain a safe rollback, or record retention, closure, or deletion conditions for a non-merge branch. -->

## Non-merge record

<!-- For any branch declared non-merge, state Purpose, Exact candidate or workflow SHA, Retained evidence, and Final disposition or close/deletion conditions. Otherwise state that this merge-intended branch has no non-merge record. -->

## Lifecycle exception

<!-- Say that no exception applies. A legacy branch must instead use primary issue #47 and name Legacy registration: #47, Original branch identity, Original primary issue or unknown, Immutable candidate SHA, Retained evidence, Intended disposition, and a Reason. -->

## Independent agent review

Fresh-agent attestations are posted as PR comments and bind the contract below.
After the final attestation, rerun the newest exact `pull_request` workflow and
re-fetch live refs, body, and comments immediately before merge. A subsequent
trusted attestation change requires another rerun. Manual-dispatch runs are not
merge evidence.

<!--
Replace every placeholder after the PR number and exact base/head are known.
Also set the contextual defaults (`base_ref`, `risk`, `controls.target_branch`,
and the three applicability controls) to this PR's actual target and scope.
Fresh reviewers post agent-review:v1 attestations as separate PR comments.
Any commit, base advance, target change, or semantic contract edit requires new reviews.
Only the final current pull-request-event run named Required CI counts as merge evidence.
-->
<!-- pr-contract:v1
{
  "version": 1,
  "repository": "magicalfeyfenny/selkies-moon",
  "pr_number": "REPLACE_WITH_PR_NUMBER",
  "head_sha": "REPLACE_WITH_40_CHARACTER_HEAD_SHA",
  "base_sha": "REPLACE_WITH_40_CHARACTER_BASE_SHA",
  "base_ref": "dev",
  "head_ref": "REPLACE_WITH_HEAD_BRANCH",
  "implementation_agent": "REPLACE_WITH_UNIQUE_IMPLEMENTATION_RUN_ID",
  "acceptance_sha256": "REPLACE_WITH_64_CHARACTER_CANONICAL_BODY_SHA256",
  "risk": "standard",
  "controls": {
    "target_branch": "dev",
    "lfs": "not-applicable",
    "generated_ownership": "not-applicable",
    "documentation": "updated"
  }
}
-->

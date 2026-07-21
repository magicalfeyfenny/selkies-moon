<!--
Under every required heading, write at least one separate, unindented
plain-prose sentence. Lists, checkboxes, quotes, links, and examples may follow
but do not satisfy the evidence gate by themselves.
-->

## Intent

<!-- State the outcome, root cause, why it is needed, and the issue/acceptance criteria. -->

## Scope

<!-- List the bounded changes included in this PR. -->

## Non-goals

<!-- State nearby work deliberately left out or deferred to a named issue. -->

## Risk

<!-- Declare low, standard, high, or main-promotion and explain the largest failure mode. -->

- [ ] Target branch and authority are correct.
- [ ] LFS payload availability is verified or explicitly not applicable.
- [ ] Generated/runtime ownership is verified or explicitly not applicable.
- [ ] Documentation is updated or verified current.
- [ ] Rollback is concrete and safe.

## Validation

<!-- Map each acceptance criterion to exact commands, checks, or inspected artifacts. Explain any unavailable signal. Include provenance plus inspected visual/audio evidence for affected assets. -->

## Rollback

<!-- Explain how to revert or disable the change safely. -->

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

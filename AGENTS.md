# Repository Agent Review Policy

Before describing a pull request as reviewed, marking it ready, or merging it,
read and follow [Agent Review Policy](docs/AGENT_REVIEW_POLICY.md).

- Codex may create independent review agents without asking Fenny for a separate
  approval. Review agents must use fresh context, remain read-only, and may not
  be the implementation agent.
- Scale review to the computed risk. Low-risk documentation needs one
  correctness reviewer; standard work needs correctness and validation;
  high-risk work needs correctness, validation, and governance; every pull
  request into `main` needs correctness, validation, and release-governance.
- Put the acceptance contract in the pull-request body and each independent
  review attestation in a separate pull-request comment. Bind every review to
  the repository, pull-request number, full head and base SHAs, target branch,
  and canonical contract hash. Any commit, base advance, target change, or
  semantic contract edit invalidates the review and requires fresh agents.
- Fenny's manual review approval is not required when all required agents pass,
  required checks are green, and no blocking finding remains.
- Review authority is not merge or release authority. Merge only when the task
  authorizes publishing that change. Advancing `main`, tagging, or publishing
  binaries still requires an explicit promotion/release task.
- Escalate disagreements, failed or skipped required checks, unresolved
  correctness/security findings, secrets, privacy or licensing decisions,
  destructive history operations, and ambiguous release provenance.

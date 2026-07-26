# Validation

Select the smallest validation tier that can disprove the change. Record the
command, result, and relevant log or artifact in the active task, pull request,
or handoff; do not append routine runs to [Project State](PROJECT_STATE.md).
This guide describes evidence, while [Agent Review Policy](AGENT_REVIEW_POLICY.md)
owns review roles and exact-head approval requirements.

## Repository governance and documentation

Run from the repository root after staging one intended snapshot:

```zsh
python3 tools/check_governance.py
python3 tools/check_repository_hygiene.py
git diff --cached --check
git status --short
```

`check_governance.py` validates the live governance entry points, local Markdown
links, current game-state summaries, and workflow integration. It is a compact
consistency check, not a gameplay test. `check_repository_hygiene.py` validates
the staged snapshot, LFS and package ownership, registered GameMaker resources,
and repository debris; it deliberately rejects a mixed staged/unstaged snapshot.

When changing the workflow, also parse it locally:

```zsh
ruby -e "require 'yaml'; YAML.load_file('.github/workflows/gamemaker-tests.yml')"
```

## Hosted GMTL regression evidence

For GML, `.yy`/`.yyp`, runtime-data, behavior, or shipping-workflow changes,
the authoritative full-suite signal is the licensed Windows `GMTL unit tests`
job in [the GitHub Actions workflow](../.github/workflows/gamemaker-tests.yml).
It checks out the exact event head, hydrates registered runtime assets, builds
with the pinned GameMaker runtime, and runs `tools/run_gmtl_tests_ci.ps1`.

Local full-suite runs use:

```zsh
GMTL_TEST_ATTEMPTS=8 ./tools/run_gmtl_tests.zsh
```

A valid result contains both `Test Suites:` and `Tests:` summary lines with no
failures. A compile succeeding without those summaries is not a test pass. The
macOS harness retries transient GameMaker access violations; if bounded attempts
still end without both summaries, preserve the log and stop retrying until the
environment changes. Do not report declarations, compilation, or a partial log
as GMTL execution evidence.

Fork pull requests cannot use the repository `ACCESS_KEY`, so they cannot prove
the licensed Windows GMTL gate. Transfer the exact candidate to a
maintainer-owned branch before requesting merge evidence.

## Pull-request governance and exact-head review

For a pull request, create the required `pr-contract:v1` body and obtain the
risk-scaled fresh-context reviews defined by [Agent Review
Policy](AGENT_REVIEW_POLICY.md). The `PR governance` job refreshes live pull
request context, validates the exact base and head, and checks the required
attestations before the GMTL job can run.

After the final attestation, rerun the newest `pull_request` workflow for the
same exact head. Confirm its green `Required CI` result, then re-fetch the live
base, head, body, and review comments immediately before an authorized merge.
Manual-dispatch runs are diagnostic and are not merge evidence. See
[Branch and Release Policy](BRANCH_AND_RELEASE_POLICY.md) for promotion and
release authority.

## Visual validation

For draw order, UI, room flow, presentation, or other visual changes, run the
opt-in 26-capture tour with `--visual-tour` or a `.visual-tour.txt` marker in the
runtime working directory. `scr_test_helpers` writes captures below the runtime
sandbox `visual-tour/` directory after Draw GUI End, so both world and GUI
layers are present. Review the captures relevant to the changed scene and keep
their artifact paths with the task evidence.

The tour supplements focused scene inspection; it does not replace gameplay
tests or visual review. Governance-only work does not need GMTL, visual-tour, or
native YYC execution unless it changes those paths or claims fresh runtime
evidence.

## Native YYC playtest

For intentional native macOS behavior checks or a release candidate, run:

```zsh
YYC_NO_RUN=1 ./tools/run_yyc_playtest.zsh
```

Omit `YYC_NO_RUN=1` only when opening the application is intentional and
permitted. Follow [Asset Pipeline](ASSET_PIPELINE.md) before validating changed
production assets, and use the release gates in [Branch and Release
Policy](BRANCH_AND_RELEASE_POLICY.md) before any promotion.

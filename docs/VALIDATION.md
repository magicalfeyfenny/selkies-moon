# Validation

Select the smallest tier that can disprove the change. Record the command and
result in the task, commit, or handoff; do not append routine run history to
`PROJECT_STATE.md`.

## Governance and documentation

Run from repository root:

```zsh
python3 tools/check_governance.py
git diff --check
git status --short
```

The governance check validates required entry points and links, instruction
size, mutable state summaries against code/test sources, ignored build paths,
and production-audio manifest continuity. It does not validate gameplay.

## GameMaker regression suite

For GML, `.yy`/`.yyp`, runtime data, or behavior changes:

```zsh
GMTL_TEST_ATTEMPTS=8 ./tools/run_gmtl_tests.zsh
```

The harness discovers the newest installed compatible runtime and licensed user
directory, copies the project to `output/gmtl-project`, strips non-macOS options
from that copy, builds and runs GMTL, and retries compiler/runner crashes. A
valid result reaches both summary lines with all 128 tests passing. A GML
compiler error or completed test failure is not transient.

A successful compile without GMTL summaries is still a failed validation. If a
local host cannot launch the macOS runner, use the Windows Actions job rather
than reporting the compile as a test pass.

`GameStageBalanceReportCreate()` is intentionally test-facing and checks stage
pressure against no-continue viability bounds without requiring repeated full
playthroughs.

## GitHub Actions

`.github/workflows/gamemaker-tests.yml` first runs the governance check on an
unlicensed Linux job. It independently builds a Windows VM runner and executes
`tools/run_gmtl_tests_ci.ps1` for pull requests to `dev`, pushes to `dev`, and
manual dispatches. The workflow retains runner and compiler logs for 14 days.

Licensed CI requires the repository secret `ACCESS_KEY`. Fork pull requests
skip the licensed job because GitHub does not expose repository secrets to
untrusted fork code. Never commit or paste the access key into workflow files.

The PowerShell harness accepts a build directory, finds the produced archive or
unpacked executable, launches it with `--run-test`, and requires nonzero test
summaries with no failures.

## Visual QA

`scripts/scr_test_helpers` owns an opt-in 26-capture tour across title, stages,
combat, bosses, story, credits, practice, pause, and continue states. Launch with
`--visual-tour` or create `.visual-tour.txt` in the runtime working directory.
Captures are written beneath the runtime sandbox's `visual-tour/`; the debug log
reports paths and progress.

Capture requests are queued during Step and written in Draw GUI End so world and
GUI layers are complete. Use the tour after visual, draw-order, room-flow, or
presentation changes. It supplements, rather than replaces, focused manual
review of the changed scene.

## Native YYC playtest

For native macOS behavior or release-candidate validation:

```zsh
YYC_NO_RUN=1 ./tools/run_yyc_playtest.zsh
```

The script isolates the checkout, retries unstable YYC emission, and builds the
generated Xcode project. Omit `YYC_NO_RUN=1` only when opening the app is
intentional and permitted. Local builds are ad-hoc signed; release automation
may supply `YYC_CODE_SIGN_IDENTITY` and `YYC_DEVELOPMENT_TEAM` for the normal
notarization path.

Governance-only changes do not require GMTL, visual-tour, or YYC execution unless
they modify those commands or claim fresh runtime evidence.

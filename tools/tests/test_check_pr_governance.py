#!/usr/bin/env python3

from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))

import check_pr_governance as governance  # noqa: E402


REPOSITORY = "magicalfeyfenny/selkies-moon"
PR_NUMBER = 45
HEAD_SHA = "a" * 40
BASE_SHA = "b" * 40
TREE_SHA = "c" * 40
IMPLEMENTATION_AGENT = "/root"


def _roles_for(risk: str) -> list[str]:
    return sorted(governance.REQUIRED_ROLES[risk])


def _contract(
    *,
    base_ref: str = "dev",
    head_ref: str = "codex/governance",
    risk: str = "standard",
) -> dict[str, object]:
    value: dict[str, object] = {
        "version": 1,
        "repository": REPOSITORY,
        "pr_number": PR_NUMBER,
        "head_sha": HEAD_SHA,
        "base_sha": BASE_SHA,
        "base_ref": base_ref,
        "head_ref": head_ref,
        "implementation_agent": IMPLEMENTATION_AGENT,
        "risk": risk,
        "controls": {
            "target_branch": base_ref,
            "lfs": "not-applicable",
            "generated_ownership": "not-applicable",
            "documentation": "updated",
        },
    }
    if risk == "main-promotion":
        value["candidate_sha"] = HEAD_SHA
        value["candidate_tree"] = TREE_SHA
    value["acceptance_sha256"] = "0" * 64
    value["acceptance_sha256"] = governance.canonical_acceptance_sha256(_body(value))
    return value


def _body(contract: dict[str, object], *, raw_contract: str | None = None) -> str:
    payload = raw_contract if raw_contract is not None else json.dumps(contract, indent=2)
    sections = [
        "## Intent\n\nDeliver one bounded governance change.",
        "## Scope\n\nAdd a machine-checked contract and review evidence.",
        "## Non-goals\n\nDo not publish a release.",
        f"## Risk\n\nDeclared risk: {contract.get('risk', 'unknown')}.",
        "## Validation\n\nRun the governance unit tests and repository checks.",
        "## Rollback\n\nRevert the governance commit.",
        (
            "## Independent agent review\n\n"
            "Attestations are supplied in PR comments and bind this exact contract.\n\n"
            f"<!-- pr-contract:v1\n{payload}\n-->"
        ),
    ]
    return "\n\n".join(sections)


def _attestation(
    contract: dict[str, object],
    role: str,
    *,
    reviewer: str | None = None,
) -> dict[str, object]:
    return {
        "version": 1,
        "repository": contract["repository"],
        "pr_number": contract["pr_number"],
        "head_sha": contract["head_sha"],
        "base_sha": contract["base_sha"],
        "base_ref": contract["base_ref"],
        "head_ref": contract["head_ref"],
        "contract_sha256": governance.canonical_contract_sha256(contract),
        "implementation_agent": contract["implementation_agent"],
        "risk": contract["risk"],
        "role": role,
        "reviewer_agent": reviewer or f"/root/{role.replace('-', '_')}_review",
        "verdict": "pass",
        "blocking_findings": [],
        "evidence": [f"Inspected the complete diff and verified the {role} invariants."],
    }


def _comment(
    attestation: dict[str, object],
    *,
    raw: str | None = None,
    author: str = "magicalfeyfenny",
) -> dict[str, object]:
    payload = raw if raw is not None else json.dumps(attestation, indent=2)
    return {
        "id": 100,
        "user": {"login": author},
        "body": f"<!-- agent-review:v1\n{payload}\n-->",
    }


def _fixture(
    *,
    base_ref: str = "dev",
    head_ref: str = "codex/governance",
    risk: str = "standard",
    head_repository: str = REPOSITORY,
) -> tuple[dict[str, object], dict[str, object], list[dict[str, object]]]:
    contract = _contract(base_ref=base_ref, head_ref=head_ref, risk=risk)
    event: dict[str, object] = {
        "number": PR_NUMBER,
        "repository": {"full_name": REPOSITORY},
        "pull_request": {
            "body": _body(contract),
            "base": {
                "ref": base_ref,
                "sha": BASE_SHA,
                "repo": {"full_name": REPOSITORY},
            },
            "head": {
                "ref": head_ref,
                "sha": HEAD_SHA,
                "repo": {"full_name": head_repository},
            },
        },
    }
    comments = [_comment(_attestation(contract, role)) for role in _roles_for(risk)]
    return event, contract, comments


def _validate(
    event: dict[str, object],
    comments: object,
    paths: list[str] | None = None,
    *,
    candidate_tree: str | None = None,
) -> list[str]:
    return governance.validate_pull_request(
        event,
        paths or ["objects/obj_player/Step_0.gml"],
        comments,
        actual_candidate_tree=candidate_tree,
    )


class PullRequestGovernanceTests(unittest.TestCase):
    def test_valid_standard_contract_and_two_comment_reviews_pass(self) -> None:
        event, _contract_value, comments = _fixture()
        self.assertEqual(_validate(event, comments), [])

    def test_low_documentation_change_requires_only_correctness(self) -> None:
        event, _contract_value, comments = _fixture(risk="low")
        self.assertEqual(_validate(event, comments, ["docs/GAMEPLAY.md"]), [])

    def test_high_risk_path_classes_are_not_underdeclared(self) -> None:
        high_risk_paths = [
            ".github/workflows/checks.yml",
            "tools/migrate_assets.py",
            "package-lock.json",
            "art/masters/moon.kra",
            "audio/score.logicx/ProjectData",
            "Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp",
            "Selkie's Moon ~ until we meet again ~/art/original_character_references/moon.png",
            "Selkie's Moon ~ until we meet again ~/scripts/scr_setup/scr_setup.gml",
            "tools/build_stage3d_runtime_buffers.py",
            "docs/ASSET_PIPELINE.md",
            "art/font_sources/not_jam_old_style/Licence.txt",
            "docs/SECURITY.md",
            "Selkie's Moon ~ until we meet again ~/options/windows/options_windows.yy",
            ".env",
        ]
        for path in high_risk_paths:
            with self.subTest(path=path):
                event, _contract_value, comments = _fixture()
                errors = _validate(event, comments, [path])
                self.assertTrue(any("lower than computed risk" in error for error in errors), errors)

    def test_broad_or_cross_system_change_computes_high_risk(self) -> None:
        broad_docs = [f"docs/generated/topic-{index}.md" for index in range(25)]
        self.assertEqual(governance.minimum_risk("dev", broad_docs), "high")

        cross_system = [
            "README.md",
            "docs/GAMEPLAY.md",
            "docs/ARCHITECTURE.md",
            "tools/report.py",
            "tools/check.py",
            "objects/player.gml",
            "scripts/setup.gml",
            "rooms/title.yy",
        ]
        self.assertEqual(governance.minimum_risk("dev", cross_system), "high")

    def test_valid_high_risk_contract_requires_three_roles(self) -> None:
        event, _contract_value, comments = _fixture(risk="high")
        self.assertEqual(_validate(event, comments, ["AGENTS.md"]), [])
        errors = _validate(event, comments[:-1], ["AGENTS.md"])
        self.assertTrue(any("missing required role" in error for error in errors), errors)

    def test_valid_main_promotion_binds_candidate_tree(self) -> None:
        event, _contract_value, comments = _fixture(
            base_ref="main", head_ref="dev", risk="main-promotion"
        )
        self.assertEqual(_validate(event, comments, ["README.md"], candidate_tree=TREE_SHA), [])

    def test_main_promotion_rejects_disallowed_or_fork_source(self) -> None:
        event, _contract_value, comments = _fixture(
            base_ref="main",
            head_ref="codex/feature",
            risk="main-promotion",
            head_repository="fork/selkies-moon",
        )
        errors = _validate(event, comments, ["README.md"], candidate_tree=TREE_SHA)
        self.assertTrue(any("PRs into main" in error for error in errors), errors)
        self.assertTrue(any("same repository" in error for error in errors), errors)

    def test_main_promotion_rejects_missing_or_mismatched_candidate_identity(self) -> None:
        event, contract, comments = _fixture(
            base_ref="main", head_ref="dev", risk="main-promotion"
        )
        errors = _validate(event, comments, ["README.md"])
        self.assertTrue(any("not independently resolved" in error for error in errors), errors)

        contract["candidate_sha"] = "d" * 40
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("main-promotion")]
        errors = _validate(event, comments, ["README.md"], candidate_tree="e" * 40)
        self.assertTrue(any("candidate_sha" in error for error in errors), errors)
        self.assertTrue(any("candidate_tree" in error for error in errors), errors)

    def test_stale_head_base_and_contract_hash_are_rejected(self) -> None:
        event, contract, comments = _fixture()
        stale = copy.deepcopy(comments)
        stale[0]["body"] = stale[0]["body"].replace(HEAD_SHA, "d" * 40)
        stale[1]["body"] = stale[1]["body"].replace(BASE_SHA, "e" * 40)
        errors = _validate(event, stale)
        self.assertTrue(any("head_sha" in error for error in errors), errors)
        self.assertTrue(any("base_sha" in error for error in errors), errors)

        contract["controls"]["documentation"] = "verified-current"  # type: ignore[index]
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        errors = _validate(event, comments)
        self.assertTrue(any("contract_sha256" in error for error in errors), errors)

    def test_visible_acceptance_edit_invalidates_contract_and_reviews(self) -> None:
        event, _contract_value, comments = _fixture()
        event["pull_request"]["body"] = event["pull_request"]["body"].replace(  # type: ignore[index]
            "Deliver one bounded governance change.",
            "Advance main and publish an unrelated release.",
        )
        errors = _validate(event, comments)
        self.assertTrue(any("acceptance_sha256" in error for error in errors), errors)

        event, _contract_value, comments = _fixture()
        event["pull_request"]["body"] += "\n\n## Added scope\n\nPublish binaries."  # type: ignore[index,operator]
        errors = _validate(event, comments)
        self.assertTrue(any("acceptance_sha256" in error for error in errors), errors)

    def test_comment_shaped_text_in_markdown_code_is_hashed(self) -> None:
        inline_before = "Scope: `<!-- do not release -->`"
        inline_after = "Scope: `<!-- publish release -->`"
        self.assertNotEqual(
            governance.canonical_acceptance_sha256(inline_before),
            governance.canonical_acceptance_sha256(inline_after),
        )

        fenced_before = "```html\n<!-- do not release -->\n```"
        fenced_after = "```html\n<!-- publish release -->\n```"
        self.assertNotEqual(
            governance.canonical_acceptance_sha256(fenced_before),
            governance.canonical_acceptance_sha256(fenced_after),
        )

        event, _contract_value, comments = _fixture()
        event["pull_request"]["body"] = event["pull_request"]["body"].replace(  # type: ignore[index]
            "Do not publish a release.",
            "Keep this binding text: `<!-- do not publish a release -->`.",
        )
        errors = _validate(event, comments)
        self.assertTrue(any("acceptance_sha256" in error for error in errors), errors)

    def test_copied_repository_or_pr_number_is_rejected(self) -> None:
        event, contract, comments = _fixture()
        contract["repository"] = "someone/copied-repo"
        contract["pr_number"] = PR_NUMBER + 1
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        errors = _validate(event, comments)
        self.assertTrue(any("repository does not match" in error for error in errors), errors)
        self.assertTrue(any("pr_number does not match" in error for error in errors), errors)

    def test_contract_duplicate_keys_unknown_fields_and_placeholders_fail(self) -> None:
        event, contract, comments = _fixture()
        raw = json.dumps(contract)[:-1] + ',"risk":"standard"}'
        event["pull_request"]["body"] = _body(contract, raw_contract=raw)  # type: ignore[index]
        errors = _validate(event, comments)
        self.assertTrue(any("duplicate JSON key" in error for error in errors), errors)

        event, contract, comments = _fixture()
        contract["self_approved"] = True
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        errors = _validate(event, comments)
        self.assertTrue(any("unknown field" in error for error in errors), errors)

        event, contract, comments = _fixture()
        contract["implementation_agent"] = "TODO"
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        errors = _validate(event, comments)
        self.assertTrue(any("placeholder" in error for error in errors), errors)

    def test_malformed_control_value_is_a_finding_not_an_exception(self) -> None:
        event, contract, comments = _fixture()
        contract["controls"]["lfs"] = []  # type: ignore[index]
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        errors = _validate(event, comments)
        self.assertTrue(any("controls.lfs" in error for error in errors), errors)

    def test_malformed_changed_path_is_a_finding_not_an_exception(self) -> None:
        event, _contract_value, comments = _fixture()
        errors = governance.validate_pull_request(
            event,
            ["objects/player.gml", []],  # type: ignore[list-item]
            comments,
        )
        self.assertTrue(any("invalid repository-relative path" in error for error in errors), errors)

    def test_contract_marker_must_be_unique_well_formed_and_not_self_review(self) -> None:
        event, contract, comments = _fixture()
        event["pull_request"]["body"] += "\n<!-- pr-contract:v1 {bad -->"  # type: ignore[index,operator]
        errors = _validate(event, comments)
        self.assertTrue(any("expected exactly one" in error or "malformed" in error for error in errors), errors)

        event, contract, comments = _fixture()
        event["pull_request"]["body"] += "\n<!-- agent-review:v1\n{}\n-->"  # type: ignore[index,operator]
        errors = _validate(event, comments)
        self.assertTrue(any("PR comments" in error for error in errors), errors)

    def test_attestation_duplicate_unknown_and_multiple_markers_fail(self) -> None:
        event, contract, comments = _fixture()
        review = _attestation(contract, "correctness")
        raw = json.dumps(review)[:-1] + ',"role":"correctness"}'
        comments[0] = _comment(review, raw=raw)
        errors = _validate(event, comments)
        self.assertTrue(any("duplicate JSON key" in error for error in errors), errors)

        event, contract, comments = _fixture()
        review = _attestation(contract, "correctness")
        review["approval"] = True
        comments[0] = _comment(review)
        errors = _validate(event, comments)
        self.assertTrue(any("unknown field" in error for error in errors), errors)

        event, contract, comments = _fixture()
        comments[0]["body"] += comments[1]["body"]
        errors = _validate(event, comments)
        self.assertTrue(any("expected at most one" in error for error in errors), errors)

    def test_attestation_pr_number_rejects_boolean_even_for_pr_one(self) -> None:
        event, contract, comments = _fixture()
        event["number"] = 1
        contract["pr_number"] = 1
        event["pull_request"]["body"] = _body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        review = _attestation(contract, "correctness")
        review["pr_number"] = True
        comments[0] = _comment(review)
        errors = _validate(event, comments)
        self.assertTrue(any("pr_number must be an integer" in error for error in errors), errors)

    def test_reviewer_agents_are_independent_and_distinct(self) -> None:
        event, contract, comments = _fixture()
        comments[0] = _comment(_attestation(contract, "correctness", reviewer=IMPLEMENTATION_AGENT))
        comments[1] = _comment(_attestation(contract, "validation", reviewer=IMPLEMENTATION_AGENT))
        errors = _validate(event, comments)
        self.assertTrue(any("cannot be the implementation" in error for error in errors), errors)
        self.assertTrue(any("duplicates" in error for error in errors), errors)

    def test_non_pass_or_blocking_findings_are_rejected(self) -> None:
        event, contract, comments = _fixture()
        review = _attestation(contract, "correctness")
        review["verdict"] = "fail"
        review["blocking_findings"] = ["The policy can be bypassed by a stale review."]
        comments[0] = _comment(review)
        errors = _validate(event, comments)
        self.assertTrue(any("verdict must be 'pass'" in error for error in errors), errors)
        self.assertTrue(any("blocking_findings must be empty" in error for error in errors), errors)

    def test_extra_specialist_role_does_not_replace_or_block_required_roles(self) -> None:
        event, contract, comments = _fixture(risk="low")
        comments.append(_comment(_attestation(contract, "validation")))
        self.assertEqual(_validate(event, comments, ["docs/README.md"]), [])

        blocking = _attestation(contract, "validation")
        blocking["verdict"] = "request-changes"
        blocking["blocking_findings"] = ["P1: the current contract has a security bypass."]
        comments[-1] = _comment(blocking)
        errors = _validate(event, comments, ["docs/README.md"])
        self.assertTrue(any("verdict must be 'pass'" in error for error in errors), errors)
        self.assertTrue(any("blocking_findings must be empty" in error for error in errors), errors)

    def test_untrusted_comment_authors_cannot_attest_or_block(self) -> None:
        event, contract, comments = _fixture()
        untrusted = [
            _comment(_attestation(contract, role), author="untrusted-reviewer")
            for role in _roles_for("standard")
        ]
        errors = _validate(event, untrusted)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

        malformed = {
            "id": 99,
            "user": {"login": "untrusted-reviewer"},
            "body": "<!-- agent-review:v1 this is deliberately malformed -->",
        }
        self.assertEqual(_validate(event, [malformed, *comments]), [])

    def test_latest_trusted_attestation_per_role_supersedes_stale_history(self) -> None:
        event, _contract_value, current = _fixture()
        stale = copy.deepcopy(current)
        for comment in stale:
            comment["body"] = comment["body"].replace(HEAD_SHA, "d" * 40)
        self.assertEqual(_validate(event, [*stale, *current]), [])

    def test_rename_parser_returns_both_sides_and_deletion_path(self) -> None:
        output = b"R100\0docs/old.md\0.github/workflows/new.yml\0D\0AGENTS.md\0"
        self.assertEqual(
            governance._parse_name_status(output),
            [".github/workflows/new.yml", "AGENTS.md", "docs/old.md"],
        )
        self.assertEqual(
            governance.minimum_risk("dev", governance._parse_name_status(output)),
            "high",
        )

    def test_canonical_hash_is_stable_across_key_order_and_changes_on_content(self) -> None:
        contract = _contract()
        reordered = dict(reversed(list(contract.items())))
        self.assertEqual(
            governance.canonical_contract_sha256(contract),
            governance.canonical_contract_sha256(reordered),
        )
        reordered["head_ref"] = "codex/different"
        self.assertNotEqual(
            governance.canonical_contract_sha256(contract),
            governance.canonical_contract_sha256(reordered),
        )

    def test_required_body_sections_and_comment_attestations_cannot_be_omitted(self) -> None:
        event, _contract_value, comments = _fixture()
        event["pull_request"]["body"] = event["pull_request"]["body"].replace(  # type: ignore[index]
            "## Rollback", "## Removed"
        )
        errors = _validate(event, comments)
        self.assertTrue(any("## Rollback" in error for error in errors), errors)

        event, _contract_value, _comments = _fixture()
        errors = _validate(event, [])
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

    def test_required_body_sections_cannot_be_duplicated(self) -> None:
        event, _contract_value, comments = _fixture()
        duplicate = "\n\n## Scope\n\nSmuggle unrelated release work."
        event["pull_request"]["body"] += duplicate  # type: ignore[index,operator]
        errors = _validate(event, comments)
        self.assertTrue(any("expected exactly one '## Scope'" in error for error in errors), errors)

    def test_token_bearing_context_fetch_precedes_checkout_and_uses_isolated_python(self) -> None:
        workflow = (governance.ROOT / ".github/workflows/gamemaker-tests.yml").read_text(
            encoding="utf-8"
        )
        governance_job = workflow.split("  pr_governance:\n", 1)[1].split("\n  gmtl:\n", 1)[0]
        self.assertLess(
            governance_job.index("- name: Fetch live pull request review context"),
            governance_job.index("- name: Check out complete validation history"),
        )
        self.assertIn("python3 -I -", governance_job)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3

from __future__ import annotations

import copy
import json
import re
import sys
import textwrap
import unittest
from pathlib import Path
from unittest import mock


TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))

import check_pr_governance as governance  # noqa: E402


REPOSITORY = "magicalfeyfenny/selkies-moon"
PR_NUMBER = 45
HEAD_SHA = "a" * 40
BASE_SHA = "b" * 40
TREE_SHA = "c" * 40
IMPLEMENTATION_AGENT = "/root"
TRUSTED_REVIEWER_ID = 26424169


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


def _hidden_body(contract: dict[str, object]) -> str:
    sections = [
        "## Intent\n\nDeliver one bounded governance change.",
        "## Scope\n\nAdd a machine-checked contract and review evidence.",
        "## Non-goals\n\nDo not publish a release.",
        f"## Risk\n\nDeclared risk: {contract.get('risk', 'unknown')}.",
        "## Validation\n\nRun the governance unit tests and repository checks.",
        "## Rollback\n\nRevert the governance commit.",
        "## Independent agent review\n\nAttestations bind this exact contract.",
    ]
    hidden_sections = "\n\n".join(f"<!--\n{section}\n-->" for section in sections)
    payload = json.dumps(contract, indent=2)
    return f"{hidden_sections}\n\n<!-- pr-contract:v1\n{payload}\n-->"


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
    author_id: int | None = None,
) -> dict[str, object]:
    payload = raw if raw is not None else json.dumps(attestation, indent=2)
    if author_id is None:
        author_id = TRUSTED_REVIEWER_ID if author == "magicalfeyfenny" else 999999999
    return {
        "id": 100,
        "user": {"login": author, "id": author_id},
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
    base_is_ancestor: bool | None = True,
) -> list[str]:
    return governance.validate_pull_request(
        event,
        paths or ["objects/obj_player/Step_0.gml"],
        comments,
        actual_candidate_tree=candidate_tree,
        actual_base_is_ancestor=base_is_ancestor,
    )


def _rebind_modified_body(
    event: dict[str, object],
    contract: dict[str, object],
    body: str,
) -> tuple[dict[str, object], list[dict[str, object]]]:
    rebound = copy.deepcopy(contract)
    rebound["acceptance_sha256"] = governance.canonical_acceptance_sha256(body)
    marker = f"<!-- pr-contract:v1\n{json.dumps(rebound, indent=2)}\n-->"
    body, replacements = re.subn(
        r"<!--\s*pr-contract:v1\b.*?-->",
        marker,
        body,
        count=1,
        flags=re.DOTALL | re.IGNORECASE,
    )
    if replacements != 1:
        raise AssertionError("test fixture must contain one PR contract")
    event["pull_request"]["body"] = body  # type: ignore[index]
    comments = [
        _comment(_attestation(rebound, role))
        for role in _roles_for(str(rebound["risk"]))
    ]
    return rebound, comments


def _replace_required_section_content(body: str, section: str, content: str) -> str:
    pattern = re.compile(
        rf"(^##[ \t]+{re.escape(section)}[ \t]*\r?\n)"
        rf"(?P<content>.*?)(?=^##[ \t]+|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(body)
    if match is None:
        raise AssertionError(f"test fixture is missing section {section!r}")
    machine_contract = ""
    if section == "Independent agent review":
        contract_match = re.search(
            r"<!--\s*pr-contract:v1\b.*?-->",
            match.group("content"),
            re.DOTALL | re.IGNORECASE,
        )
        if contract_match is None:
            raise AssertionError("test fixture is missing the PR contract")
        machine_contract = f"\n\n{contract_match.group(0)}"
    replacement = f"{match.group(1)}\n{content}{machine_contract}\n"
    return body[: match.start()] + replacement + body[match.end() :]


class PullRequestGovernanceTests(unittest.TestCase):
    def test_valid_standard_contract_and_two_comment_reviews_pass(self) -> None:
        event, _contract_value, comments = _fixture()
        self.assertEqual(_validate(event, comments), [])

    def test_low_documentation_change_requires_only_correctness(self) -> None:
        for path in ("README.md", "docs/GAMEPLAY.md"):
            with self.subTest(path=path):
                event, _contract_value, comments = _fixture(risk="low")
                self.assertEqual(_validate(event, comments, [path]), [])

    def test_high_risk_path_classes_are_not_underdeclared(self) -> None:
        high_risk_paths = [
            ".github/workflows/checks.yml",
            "tools/migrate_assets.py",
            "package-lock.json",
            "art/masters/moon.kra",
            "audio/score.logicx/ProjectData",
            "art/audio_production/sfx_cue_sheets/sfx_install_report.json",
            "Selkie's Moon ~ until we meet again ~/Selkies Moon.yyp",
            "Selkie's Moon ~ until we meet again ~/art/original_character_references/moon.png",
            "Selkie's Moon ~ until we meet again ~/art/character_portraits/PORTRAIT_BRIEFS.md",
            "Selkie's Moon ~ until we meet again ~/art/character_portraits/README.md",
            "Selkie's Moon ~ until we meet again ~/scripts/scr_setup/scr_setup.gml",
            "tools/build_stage3d_runtime_buffers.py",
            "tools/tests/test_check_repository_hygiene.py",
            "docs/ARCHITECTURE.md",
            "docs/ASSET_PIPELINE.md",
            "docs/DEVELOPMENT.md",
            "docs/GOVERNANCE_HANDOFF.md",
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

    def test_non_document_text_defaults_to_standard_risk(self) -> None:
        path = "Selkie's Moon ~ until we meet again ~/datafiles/shipping-dialogue.txt"
        self.assertEqual(governance.minimum_risk("dev", [path]), "standard")
        event, _contract_value, comments = _fixture(risk="low")
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
        self.assertEqual(
            _validate(
                event,
                comments,
                ["README.md"],
                candidate_tree=TREE_SHA,
                base_is_ancestor=True,
            ),
            [],
        )

    def test_main_promotion_rejects_disallowed_or_fork_source(self) -> None:
        event, _contract_value, comments = _fixture(
            base_ref="main",
            head_ref="codex/feature",
            risk="main-promotion",
            head_repository="fork/selkies-moon",
        )
        errors = _validate(
            event,
            comments,
            ["README.md"],
            candidate_tree=TREE_SHA,
            base_is_ancestor=True,
        )
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
        errors = _validate(
            event,
            comments,
            ["README.md"],
            candidate_tree="e" * 40,
            base_is_ancestor=True,
        )
        self.assertTrue(any("candidate_sha" in error for error in errors), errors)
        self.assertTrue(any("candidate_tree" in error for error in errors), errors)

    def test_main_promotion_requires_candidate_to_contain_current_main(self) -> None:
        event, _contract_value, comments = _fixture(
            base_ref="main", head_ref="dev", risk="main-promotion"
        )
        errors = _validate(
            event,
            comments,
            ["README.md"],
            candidate_tree=TREE_SHA,
            base_is_ancestor=False,
        )
        self.assertTrue(any("contain the exact current main base" in error for error in errors), errors)

    def test_dev_requires_independently_resolved_current_base_ancestry(self) -> None:
        event, _contract_value, comments = _fixture()
        self.assertEqual(_validate(event, comments, base_is_ancestor=True), [])

        errors = _validate(event, comments, base_is_ancestor=False)
        self.assertTrue(any("contain the exact current dev base" in error for error in errors), errors)

        errors = _validate(event, comments, base_is_ancestor=None)
        self.assertTrue(any("base ancestry was not independently resolved" in error for error in errors), errors)

    def test_main_resolves_base_ancestry_for_dev(self) -> None:
        event, _contract_value, comments = _fixture()
        with (
            mock.patch.object(governance, "_load_json_file", side_effect=[event, comments]),
            mock.patch.object(governance, "_changed_paths", return_value=["objects/player.gml"]),
            mock.patch.object(governance, "_commit_sha", return_value=HEAD_SHA),
            mock.patch.object(governance, "_is_ancestor", return_value=True) as ancestry,
            mock.patch.object(sys, "argv", ["check_pr_governance.py", "--event", "event.json", "--comments", "comments.json"]),
        ):
            self.assertEqual(governance.main(), 0)
        ancestry.assert_called_once_with(BASE_SHA, HEAD_SHA)

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
        self.assertFalse(governance._contains_forbidden_html("`<div>example</div>`"))
        ordinary_comment = (
            "<!-- hidden markup never counts -->\n"
            "Reviewed the complete diff and tests."
        )
        self.assertFalse(governance._contains_forbidden_html(ordinary_comment))
        self.assertTrue(governance._valid_review_evidence_item(ordinary_comment))
        self.assertFalse(
            governance._has_substantive_visible_text(
                "<!-- hidden prose cannot satisfy a section -->"
            )
        )

        event, _contract_value, comments = _fixture()
        event["pull_request"]["body"] = event["pull_request"]["body"].replace(  # type: ignore[index]
            "Do not publish a release.",
            "Keep this binding text: `<!-- do not publish a release -->`.",
        )
        errors = _validate(event, comments)
        self.assertTrue(any("acceptance_sha256" in error for error in errors), errors)

    def test_unmatched_backticks_do_not_hide_later_raw_html(self) -> None:
        event, contract, _comments = _fixture()
        contract["acceptance_sha256"] = "0" * 64

        def unmatched_body() -> str:
            return (
                _body(contract)
                + "\n\n`unclosed inline delimiter\n\n"
                + '<div style="display:none">\nHidden material\n</div>'
            )

        contract["acceptance_sha256"] = governance.canonical_acceptance_sha256(
            unmatched_body()
        )
        event["pull_request"]["body"] = unmatched_body()  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        self.assertTrue(governance._contains_forbidden_html(unmatched_body()))
        errors = _validate(event, comments)
        self.assertTrue(any("HTML-shaped source" in error for error in errors), errors)

    def test_comment_and_escaped_backticks_cannot_hide_duplicate_sections(self) -> None:
        event, contract, _comments = _fixture()
        for suffix in (
            "\n\n<!-- stray ` comment -->\n\n## Scope\nDuplicate rendered scope.\n`tail",
            "\n\n\\`\n## Scope\nDuplicate rendered scope.\n\\`",
        ):
            with self.subTest(suffix=suffix):
                body = str(event["pull_request"]["body"]) + suffix
                rebound_event = copy.deepcopy(event)
                _rebound, comments = _rebind_modified_body(
                    rebound_event,
                    contract,
                    body,
                )
                errors = _validate(rebound_event, comments)
                self.assertTrue(
                    any("expected exactly one '## Scope'" in error for error in errors),
                    errors,
                )

    def test_attestation_comment_backticks_do_not_hide_machine_evidence(self) -> None:
        event, contract, comments = _fixture()
        for comment, role in zip(comments, _roles_for("standard")):
            review = _attestation(contract, role)
            review["evidence"] = [
                "`example`\nReviewed the complete diff and tests."
            ]
            comment["body"] = (
                "<!-- agent-review:v1\n"
                f"{json.dumps(review, indent=2)}\n"
                "-->"
            )
        self.assertEqual(_validate(event, comments), [])

    def test_hidden_or_fenced_required_sections_and_contract_are_rejected(self) -> None:
        event, contract, _comments = _fixture()
        contract["acceptance_sha256"] = "0" * 64
        hidden_body = _hidden_body(contract)
        contract["acceptance_sha256"] = governance.canonical_acceptance_sha256(hidden_body)
        event["pull_request"]["body"] = _hidden_body(contract)  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        errors = _validate(event, comments)
        self.assertTrue(any("missing required section" in error for error in errors), errors)

        event, contract, comments = _fixture()
        event["pull_request"]["body"] = f"```markdown\n{_body(contract)}\n```"  # type: ignore[index]
        errors = _validate(event, comments)
        self.assertTrue(any("missing required section" in error for error in errors), errors)
        self.assertTrue(any("missing <!-- pr-contract" in error for error in errors), errors)

    def test_machine_markers_must_begin_at_column_zero(self) -> None:
        for body in (
            "--><!-- agent-review:v1 {} -->",
            "<!-- note --><!-- agent-review:v1 {} -->",
            " <!-- agent-review:v1 {} -->",
        ):
            with self.subTest(body=body):
                self.assertEqual(
                    governance._top_level_marker_open_count(body, "agent-review:v1"),
                    0,
                )

    def test_split_headings_are_not_treated_as_markdown_sections(self) -> None:
        event, contract, _comments = _fixture()
        contract["acceptance_sha256"] = "0" * 64

        def split_heading_body() -> str:
            body = _body(contract)
            for section in governance.REQUIRED_SECTIONS:
                body = body.replace(f"## {section}", f"##\n{section}")
            return body

        contract["acceptance_sha256"] = governance.canonical_acceptance_sha256(
            split_heading_body()
        )
        event["pull_request"]["body"] = split_heading_body()  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        errors = _validate(event, comments)
        self.assertTrue(any("missing required section" in error for error in errors), errors)

    def test_indented_or_blockquoted_machine_markers_are_rejected(self) -> None:
        event, contract, _comments = _fixture()
        body = _body(contract)
        marker = governance.HTML_COMMENT_PATTERN.search(body)
        self.assertIsNotNone(marker)
        assert marker is not None
        payload = json.dumps(contract, separators=(",", ":"))

        indented_marker = f" \t<!-- pr-contract:v1 {payload} -->"
        event["pull_request"]["body"] = (  # type: ignore[index]
            body[: marker.start()] + indented_marker + body[marker.end() :]
        )
        errors = _validate(event, [])
        self.assertTrue(any("missing <!-- pr-contract" in error for error in errors), errors)

        blockquoted_marker = (
            f"> ~~~html\n> <!-- pr-contract:v1 {payload} -->\n> ~~~"
        )
        event["pull_request"]["body"] = (  # type: ignore[index]
            body[: marker.start()] + blockquoted_marker + body[marker.end() :]
        )
        errors = _validate(event, [])
        self.assertTrue(any("missing <!-- pr-contract" in error for error in errors), errors)

        list_marker = f"- machine evidence:\n  <!-- pr-contract:v1 {payload} -->"
        event["pull_request"]["body"] = (  # type: ignore[index]
            body[: marker.start()] + list_marker + body[marker.end() :]
        )
        errors = _validate(event, [])
        self.assertTrue(any("missing <!-- pr-contract" in error for error in errors), errors)

        indented_reviews = [
            {
                "id": index,
                "user": {
                    "login": "magicalfeyfenny",
                    "id": TRUSTED_REVIEWER_ID,
                },
                "body": (
                    " \t<!-- agent-review:v1 "
                    + json.dumps(_attestation(contract, role), separators=(",", ":"))
                    + " -->"
                ),
            }
            for index, role in enumerate(_roles_for("standard"))
        ]
        event["pull_request"]["body"] = body  # type: ignore[index]
        errors = _validate(event, indented_reviews)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

        blockquoted_reviews = copy.deepcopy(indented_reviews)
        for comment in blockquoted_reviews:
            comment["body"] = f"> ~~~html\n> {comment['body'].lstrip()}\n> ~~~"
        errors = _validate(event, blockquoted_reviews)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

        list_reviews = copy.deepcopy(indented_reviews)
        for comment in list_reviews:
            comment["body"] = f"- review evidence:\n  {comment['body'].lstrip()}"
        errors = _validate(event, list_reviews)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

    def test_raw_html_blocks_cannot_hide_contract_structure_or_reviews(self) -> None:
        for tag in ("pre", "div"):
            with self.subTest(tag=tag):
                event, contract, _comments = _fixture()
                contract["acceptance_sha256"] = "0" * 64

                def raw_html_body() -> str:
                    body = _body(contract)
                    marker = governance.HTML_COMMENT_PATTERN.search(body)
                    assert marker is not None
                    return (
                        f"<{tag}>\n"
                        + body[: marker.start()]
                        + f"</{tag}>\n"
                        + body[marker.start() :]
                    )

                contract["acceptance_sha256"] = governance.canonical_acceptance_sha256(
                    raw_html_body()
                )
                event["pull_request"]["body"] = raw_html_body()  # type: ignore[index]
                comments = [
                    _comment(_attestation(contract, role))
                    for role in _roles_for("standard")
                ]
                errors = _validate(event, comments)
                self.assertTrue(any("HTML-shaped source" in error for error in errors), errors)

        for opening, line_ending in (
            ("<pre", "\n"),
            ("<PRE", "\n"),
            ("<div", "\n"),
            ("<pre", "\r\n"),
        ):
            with self.subTest(unclosed_opening=opening, line_ending=line_ending):
                event, contract, _comments = _fixture()
                contract["acceptance_sha256"] = "0" * 64

                def unclosed_raw_html_body() -> str:
                    return f"{opening}{line_ending}{_body(contract)}"

                contract["acceptance_sha256"] = governance.canonical_acceptance_sha256(
                    unclosed_raw_html_body()
                )
                event["pull_request"]["body"] = unclosed_raw_html_body()  # type: ignore[index]
                comments = [
                    _comment(_attestation(contract, role))
                    for role in _roles_for("standard")
                ]
                errors = _validate(event, comments)
                self.assertTrue(any("HTML-shaped source" in error for error in errors), errors)

        event, _contract_value, comments = _fixture()
        for comment in comments:
            comment["body"] = f"<pre>\n{comment['body']}\n</pre>"
        errors = _validate(event, comments)
        self.assertTrue(any("HTML-shaped source" in error for error in errors), errors)

    def test_fenced_examples_do_not_create_duplicate_sections_or_attestations(self) -> None:
        event, contract, _comments = _fixture()
        contract["acceptance_sha256"] = "0" * 64

        def body_with_example() -> str:
            return (
                _body(contract)
                + "\n\n```markdown\n## Scope\n\n<div>Example only.</div>\n"
                + "<!-- agent-review:v1\n{}\n-->\n```\n\n"
                + "> ~~~html\n> <!-- agent-review:v1 {} -->\n> ~~~\n\n"
                + " \t<!-- agent-review:v1 {} -->"
            )

        contract["acceptance_sha256"] = governance.canonical_acceptance_sha256(
            body_with_example()
        )
        event["pull_request"]["body"] = body_with_example()  # type: ignore[index]
        comments = [_comment(_attestation(contract, role)) for role in _roles_for("standard")]
        self.assertEqual(_validate(event, comments), [])

        fenced_comments = copy.deepcopy(comments)
        for comment in fenced_comments:
            comment["body"] = f"```html\n{comment['body']}\n```"
        errors = _validate(event, fenced_comments)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

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
        comments[0]["body"] += "\n" + comments[1]["body"]
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

    def test_each_live_evaluation_rejects_edited_or_deleted_attestations(self) -> None:
        event, contract, comments = _fixture()
        self.assertEqual(_validate(event, comments), [])

        edited = copy.deepcopy(comments)
        blocking = _attestation(contract, "correctness")
        blocking["verdict"] = "request-changes"
        blocking["blocking_findings"] = ["P1: the current review was withdrawn."]
        edited[0] = _comment(blocking)
        errors = _validate(event, edited)
        self.assertTrue(any("verdict must be 'pass'" in error for error in errors), errors)

        errors = _validate(event, comments[1:])
        self.assertTrue(any("missing required role" in error for error in errors), errors)

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

        claimed_login = [
            _comment(
                _attestation(contract, role),
                author_id=999999999,
            )
            for role in _roles_for("standard")
        ]
        errors = _validate(event, claimed_login)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

        mismatched_login = [
            _comment(
                _attestation(contract, role),
                author="renamed-or-claimed-login",
                author_id=TRUSTED_REVIEWER_ID,
            )
            for role in _roles_for("standard")
        ]
        errors = _validate(event, mismatched_login)
        self.assertTrue(any("no agent-review" in error for error in errors), errors)

        malformed = {
            "id": 99,
            "user": {"login": "untrusted-reviewer"},
            "body": "<!-- agent-review:v1 this is deliberately malformed -->",
        }
        self.assertEqual(_validate(event, [malformed, *comments]), [])

        unrelated_trusted = {
            "id": 101,
            "user": {
                "login": "magicalfeyfenny",
                "id": TRUSTED_REVIEWER_ID,
            },
            "body": "<details><summary>Discussion notes</summary>Nothing here is a review.</details>",
        }
        self.assertEqual(_validate(event, [unrelated_trusted, *comments]), [])

    def test_latest_trusted_attestation_per_role_supersedes_stale_history(self) -> None:
        event, _contract_value, current = _fixture()
        stale = copy.deepcopy(current)
        for comment in stale:
            comment["body"] = comment["body"].replace(HEAD_SHA, "d" * 40)
        self.assertEqual(_validate(event, [*stale, *current]), [])
        self.assertEqual(_validate(event, [*current, *stale]), [])

        event, contract, required = _fixture(risk="low")
        blocking = _attestation(contract, "validation")
        blocking["verdict"] = "request-changes"
        blocking["blocking_findings"] = ["P1: the current optional review found a blocker."]
        stale_pass = _attestation(contract, "validation")
        stale_pass["head_sha"] = "d" * 40
        errors = _validate(
            event,
            [*required, _comment(blocking), _comment(stale_pass)],
            ["docs/README.md"],
        )
        self.assertTrue(any("verdict must be 'pass'" in error for error in errors), errors)

        current_pass = _attestation(contract, "validation")
        self.assertEqual(
            _validate(
                event,
                [*required, _comment(blocking), _comment(current_pass)],
                ["docs/README.md"],
            ),
            [],
        )

    def test_later_edit_time_supersedes_later_creation_position(self) -> None:
        event, contract, comments = _fixture()
        blocking = _attestation(contract, "correctness")
        blocking["verdict"] = "request-changes"
        blocking["blocking_findings"] = ["P1: an edited review withdrew its pass."]
        edited_older = _comment(blocking)
        edited_older.update(
            {
                "id": 90,
                "created_at": "2026-07-21T10:00:00Z",
                "updated_at": "2026-07-21T12:00:00Z",
            }
        )

        newer_pass = _comment(_attestation(contract, "correctness"))
        newer_pass.update(
            {
                "id": 100,
                "created_at": "2026-07-21T11:00:00Z",
                "updated_at": "2026-07-21T11:00:00Z",
            }
        )
        validation = next(
            comment
            for comment, role in zip(comments, _roles_for("standard"))
            if role == "validation"
        )

        errors = _validate(event, [edited_older, newer_pass, validation])
        self.assertTrue(any("verdict must be 'pass'" in error for error in errors), errors)
        self.assertTrue(any("blocking_findings must be empty" in error for error in errors), errors)

    def test_equal_second_same_role_attestations_fail_closed(self) -> None:
        event, contract, comments = _fixture()
        blocking = _attestation(contract, "correctness")
        blocking["verdict"] = "request-changes"
        blocking["blocking_findings"] = ["P1: same-second edit withdrew approval."]
        edited_older = _comment(blocking)
        edited_older.update(
            {
                "id": 90,
                "created_at": "2026-07-21T10:00:00Z",
                "updated_at": "2026-07-21T12:00:00Z",
            }
        )
        newer_pass = _comment(_attestation(contract, "correctness"))
        newer_pass.update(
            {
                "id": 100,
                "created_at": "2026-07-21T11:00:00Z",
                "updated_at": "2026-07-21T12:00:00Z",
            }
        )
        validation = next(
            comment
            for comment, role in zip(comments, _roles_for("standard"))
            if role == "validation"
        )

        errors = _validate(event, [edited_older, newer_pass, validation])
        self.assertTrue(any("share the latest whole-second updated_at" in error for error in errors), errors)

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

    def test_every_required_section_rejects_a_bare_heading_at_eof(self) -> None:
        for section in governance.REQUIRED_SECTIONS:
            with self.subTest(section=section):
                event, contract, _comments = _fixture()
                body = str(event["pull_request"]["body"])
                body = body.replace(
                    f"## {section}\n",
                    f"## Moved {section}\n",
                    1,
                ).rstrip() + f"\n\n## {section}"
                _rebound, comments = _rebind_modified_body(event, contract, body)
                errors = _validate(event, comments)
                self.assertTrue(
                    any(
                        f"section '## {section}' has no reviewable content" in error
                        for error in errors
                    ),
                    errors,
                )

    def test_every_required_section_rejects_placeholder_content(self) -> None:
        for section in governance.REQUIRED_SECTIONS:
            for placeholder in ("TODO", "_TBD_", "__TODO__"):
                with self.subTest(section=section, placeholder=placeholder):
                    self._assert_required_section_rejects_placeholder(
                        section,
                        placeholder,
                    )

    def _assert_required_section_rejects_placeholder(
        self,
        section: str,
        placeholder: str,
    ) -> None:
        event, contract, _comments = _fixture()
        body = str(event["pull_request"]["body"])
        body = _replace_required_section_content(body, section, placeholder)
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertTrue(
            any(
                f"section '## {section}' contains placeholder text" in error
                for error in errors
            ),
            errors,
        )

    def test_required_sections_allow_autolinks_and_angle_comparisons(self) -> None:
        examples = (
            "See <https://example.com/report> for the hosted log.",
            "The supported range is x < y > z.",
            "The placeholder check rejects a bare TODO marker.",
        )
        for content in examples:
            with self.subTest(content=content):
                event, contract, _comments = _fixture()
                body = str(event["pull_request"]["body"])
                pattern = re.compile(
                    r"(^##[ \t]+Validation[ \t]*\r?\n)"
                    r"(?P<content>.*?)(?=^##[ \t]+|\Z)",
                    re.MULTILINE | re.DOTALL,
                )
                match = pattern.search(body)
                self.assertIsNotNone(match)
                assert match is not None
                replacement = f"{match.group(1)}\n{content}\n\n"
                body = body[: match.start()] + replacement + body[match.end() :]
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertEqual(_validate(event, comments), [])

    def test_every_required_section_rejects_visually_blank_content(self) -> None:
        for section in governance.REQUIRED_SECTIONS:
            for content in (
                "&nbsp;",
                "...",
                "- [ ]",
                "\u200b",
                "A" + "." * 19,
                "A" + "\ufe0f" * 19,
                "A" + "\u0301" * 19,
                "![twenty character label](https://example.com/image.png)",
                ":abcdefghijklmnopqrst:",
                "```text\nabcdefghijklmnopqrst\n```",
            ):
                with self.subTest(section=section, content=content):
                    event, contract, _comments = _fixture()
                    body = _replace_required_section_content(
                        str(event["pull_request"]["body"]),
                        section,
                        content,
                    )
                    _rebound, comments = _rebind_modified_body(event, contract, body)
                    errors = _validate(event, comments)
                    self.assertTrue(
                        any(
                            f"section '## {section}' has no reviewable content" in error
                            for error in errors
                        ),
                        errors,
                    )

    def test_production_main_rejects_blank_sections_and_review_evidence(self) -> None:
        event, contract, _comments = _fixture(risk="high")
        body = str(event["pull_request"]["body"])
        for section in governance.REQUIRED_SECTIONS:
            body = _replace_required_section_content(body, section, "&nbsp;")
        rebound, _comments = _rebind_modified_body(event, contract, body)
        comments = []
        for role in _roles_for("high"):
            review = _attestation(rebound, role)
            review["evidence"] = ["&nbsp;&nbsp;&nbsp;&nbsp;"]
            comments.append(_comment(review))

        errors = _validate(event, comments, ["AGENTS.md"])
        self.assertEqual(
            sum("four plain ASCII words" in error for error in errors),
            3,
            errors,
        )

        with (
            mock.patch.object(governance, "_load_json_file", side_effect=[event, comments]),
            mock.patch.object(governance, "_changed_paths", return_value=["AGENTS.md"]),
            mock.patch.object(governance, "_commit_sha", return_value=HEAD_SHA),
            mock.patch.object(governance, "_is_ancestor", return_value=True),
            mock.patch.object(
                sys,
                "argv",
                [
                    "check_pr_governance.py",
                    "--event",
                    "event.json",
                    "--comments",
                    "comments.json",
                ],
            ),
        ):
            self.assertEqual(governance.main(), 1)

    def test_production_main_rejects_link_definition_only_evidence(self) -> None:
        event, contract, _comments = _fixture(risk="high")
        body = str(event["pull_request"]["body"])
        definition_forms = (
            "[hidden-section-0]: https://example.com/section-0",
            "> [hidden-section-1]: https://example.com/section-1",
            "- [hidden-section-2]: https://example.com/section-2",
            "1. [hidden-section-3]: https://example.com/section-3",
            "> - [hidden-section-4]: https://example.com/section-4",
            "[hidden-section-5]:\nhttps://example.com/section-5",
            "> [hidden-section-6]:\n> https://example.com/section-6",
        )
        for index, section in enumerate(governance.REQUIRED_SECTIONS):
            body = _replace_required_section_content(
                body,
                section,
                definition_forms[index],
            )
        rebound, _comments = _rebind_modified_body(event, contract, body)
        comments = []
        evidence_forms = (
            "- [hidden-review-0]: https://example.com/review-0",
            "[hidden-review-1]:\nhttps://example.com/review-1",
            "[\nhidden-review-2\n]: https://example.com/review-2",
        )
        for index, role in enumerate(_roles_for("high")):
            review = _attestation(rebound, role)
            review["evidence"] = [evidence_forms[index]]
            comments.append(_comment(review))

        errors = _validate(event, comments, ["AGENTS.md"])
        self.assertEqual(
            sum("has no reviewable content" in error for error in errors),
            len(governance.REQUIRED_SECTIONS),
            errors,
        )
        self.assertEqual(
            sum("four plain ASCII words" in error for error in errors),
            3,
            errors,
        )
        self.assertFalse(
            governance._has_substantive_visible_text(
                "```text\n[visible-example]: https://example.com/report\n```"
            )
        )

        with (
            mock.patch.object(governance, "_load_json_file", side_effect=[event, comments]),
            mock.patch.object(governance, "_changed_paths", return_value=["AGENTS.md"]),
            mock.patch.object(governance, "_commit_sha", return_value=HEAD_SHA),
            mock.patch.object(governance, "_is_ancestor", return_value=True),
            mock.patch.object(
                sys,
                "argv",
                [
                    "check_pr_governance.py",
                    "--event",
                    "event.json",
                    "--comments",
                    "comments.json",
                ],
            ),
        ):
            self.assertEqual(governance.main(), 1)

    def test_plain_prose_gate_rejects_markup_padding(self) -> None:
        definition_forms = (
            "[hidden]: https://example.com/report",
            "> [hidden]: https://example.com/report",
            "- [hidden]: https://example.com/report",
            "1. [hidden]: https://example.com/report",
            "> - 1. [hidden]: https://example.com/report",
            "[hidden]:\nhttps://example.com/report",
            "> [hidden]:\n> https://example.com/report",
            "- [hidden]:\n  https://example.com/report",
            "[\nhidden\n]: https://example.com/report",
            "[hidden]: https://example.com/a(b(c(d(e))))",
            "[hidden]:\n    https://example.com/report",
            "[hidden]: https://example.com/report\n    \"hidden title text\"",
            "-\n    [hidden]: https://example.com/report",
            "-\n    -\n        [hidden]: https://example.com/report",
            (
                "-\n    -\n        [hidden]:\n"
                "            https://example.com/report"
            ),
        )
        for value in definition_forms:
            with self.subTest(definition=value):
                self.assertFalse(governance._valid_review_evidence_item(value))

        plain_prose = (
            "Reviewed the complete diff and all tests.",
            "Verified expected behavior across every changed governance path.",
            "Confirmed the placeholder rule rejects unfinished review text.",
        )
        for value in plain_prose:
            with self.subTest(plain_prose=value):
                self.assertTrue(governance._valid_review_evidence_item(value))

        padding = (
            "A" + "." * 19,
            "A" + "\ufe0f" * 19,
            "A" + "\u0301" * 19,
            "![twenty character label](https://example.com/image.png)",
            "![abcdefghijklmnopqrst [x]](https://example.com/image.png)",
            "![abcdefghijklmnopqrst \\]](https://example.com/image.png)",
            "![\nabcdefghijklmnopqrst\n](https://example.com/image.png)",
            (
                "![abcdefghijklmnopqrst\\" +
                "\nmore](https://example.com/image.png)"
            ),
            "![abcdefghijklmnopqrst](https://example.com/a(b(c(d(e)))))",
            "![abcdefghijklmnopqrst](https://example.com/a\u00a0b)",
            "![abcdefghijklmnopqrst](https://example.com/a\u2003b)",
            "![abcdefghijklmnopqrst](https://example.com/a\u202fb)",
            "![abcdefghijklmnopqrst](https://example.com/a\u3000b)",
            "![abcdefghijklmnopqrst](/asset.png )",
            "![abcdefghijklmnopqrst](/asset.png\t)",
            "![abcdefghijklmnopqrst](/asset.png\n)",
            "![abcdefghijklmnopqrst](</asset.png> )",
            "![abcdefghijklmnopqrst][ref]\n\n[ref]: /asset.png",
            (
                "![abcdefghijklmnopqrst][re\nf]\n\n"
                "[re\nf]: /asset.png"
            ),
            (
                "![abcdefghijklmnopqrst][]\n\n"
                "[abcdefghijklmnopqrst]: /asset.png"
            ),
            "[O[K]](https://example.com/a-very-long-destination)",
            "[x [y](/abcdefghijklmnopqrst)]",
            "![x ![abcdefghijklmnopqrst](/asset.png)]",
            "[^abcdefghijklmnopqrst]\n\n[^abcdefghijklmnopqrst]: &nbsp;",
            '<span title="> hidden attribute text"></span>',
            "x <details><summary>x</summary>abcdefghijklmnopqrst</details>",
            "x <video>\nabcdefghijklmnopqrst\nx </video>",
            "> - x <span>abcdefghijklmnopqrst</span>",
            "> <pre\nReviewed complete diff and validation evidence.",
            "- <div\n\nReviewed complete diff and validation evidence.",
            "> <!DOCTYPE\n\nReviewed complete diff and validation evidence.",
            "- <?target\n\nReviewed complete diff and validation evidence.",
            "> <![CDATA[\n\nReviewed complete diff and validation evidence.",
            "````abcdefghijkl\n````",
            "````abcdefghijkl````",
            "````\nabcdefghijklmnopqrst\n````",
            "123456789. ```text\nabcdefghijklmnopqrst\n123456789. ```",
            "-     abcdefghijklmnopqrst",
            "1.     abcdefghijklmnopqrst",
            "> -     abcdefghijklmnopqrst",
            "****abcdefghijkl****",
            r"$\phantom{abcdefghijklmnopqrst}$",
            r"$$\phantom{abcdefghijklmnopqrst}$$",
            "<!DOCTYPE abcdefghijklmnopqrst>",
            "<?abcdefghijklmnopqrst?>",
            "<![CDATA[abcdefghijklmnopqrst]]>",
            "> <!DOCTYPE abcdefghijklmnopqrst>",
            "- <!DOCTYPE abcdefghijklmnopqrst>",
            "> <?abcdefghijklmnopqrst?>",
            "- <![CDATA[abcdefghijklmnopqrst]]>",
            "\n".join("- [ ]" for _ in range(20)),
            "\n".join("- [x]" for _ in range(20)),
            "\r\n".join("- [x]" for _ in range(21)),
            "\r".join("- [x]" for _ in range(20)),
            "\n".join("- [x]\u00a0" for _ in range(20)),
            "\n".join("- [x]\u2003" for _ in range(20)),
            ":abcdefghijklmnopqrst:",
            " ".join("1\ufe0f\u20e3" for _ in range(20)),
            "\u115f" * 20,
            "\u1160" * 20,
            "\u3164" * 20,
            "\uffa0" * 20,
            "2d0d8f1fef81f5fa2c6e5121c76f7cdea1d1154c",
            "https://github.com/magicalfeyfenny/selkies-moon/issues/17",
            "magicalfeyfenny/selkies-moon#17",
            "TODO TODO TODO TODO TODO",
            "```text\n[visible-example]: https://example.com/report\n```",
            "`[visible-example]: https://example.com/report`",
            "    [visible-code]: https://example.com/report",
            "\t[visible-code]: https://example.com/report",
            ">     [visible-code]: https://example.com/report",
            (
                "> ```text\n"
                "> [visible-code]: https://example.com/report\n"
                "> ```"
            ),
            (
                "> ```text\n"
                "> &nbsp; remains literal inside code\n"
                "> ```"
            ),
        )
        for value in padding:
            with self.subTest(padding=value):
                self.assertFalse(governance._valid_review_evidence_item(value))

    def test_plain_prose_gate_boundaries_and_eligible_lines(self) -> None:
        self.assertTrue(governance._has_substantive_visible_text("four five tree"))
        self.assertFalse(governance._has_substantive_visible_text("governance complete"))
        self.assertFalse(governance._has_substantive_visible_text("four five six"))

        self.assertTrue(
            governance._valid_review_evidence_item("alpha bravo delta gamma")
        )
        self.assertFalse(
            governance._valid_review_evidence_item("governance review completed")
        )
        self.assertFalse(
            governance._valid_review_evidence_item("alpha bravo delta four")
        )

        for content in (
            "> Reviewed the complete diff and tests.",
            "- Reviewed the complete diff and tests.",
            "    Reviewed the complete diff and tests.",
            "`example` Reviewed the complete diff and tests.",
            "[example] Reviewed the complete diff and tests.",
        ):
            with self.subTest(ineligible_line=content):
                self.assertFalse(governance._valid_review_evidence_item(content))

    def test_markup_examples_can_accompany_separate_plain_prose(self) -> None:
        examples = (
            "```text\nnot review prose\n```\nReviewed the complete diff and tests.",
            "> ```\n> not review prose\n> ```\nReviewed the complete diff and tests.",
            "![diagram](/asset.png)\nReviewed the complete diff and tests.",
            "- [x] example\nReviewed the complete diff and tests.",
            ":white_check_mark:\nReviewed the complete diff and tests.",
        )
        for content in examples:
            with self.subTest(content=content):
                self.assertTrue(governance._valid_review_evidence_item(content))

    def test_production_main_rejects_code_only_sections_and_evidence(self) -> None:
        event, contract, _comments = _fixture(risk="high")
        body = str(event["pull_request"]["body"])
        for index, section in enumerate(governance.REQUIRED_SECTIONS):
            indentation = "    " if index % 2 == 0 else "\t"
            body = _replace_required_section_content(
                body,
                section,
                f"{indentation}[visible-code-{index}]: https://example.com/report-{index}",
            )
        rebound, _comments = _rebind_modified_body(event, contract, body)
        comments = []
        for index, role in enumerate(_roles_for("high")):
            review = _attestation(rebound, role)
            review["evidence"] = [
                f"    [visible-review-{index}]: https://example.com/report-{index}"
            ]
            comments.append(_comment(review))

        errors = _validate(event, comments, ["AGENTS.md"])
        self.assertEqual(
            sum("has no reviewable content" in error for error in errors),
            len(governance.REQUIRED_SECTIONS),
            errors,
        )
        self.assertEqual(
            sum("four plain ASCII words" in error for error in errors),
            3,
            errors,
        )
        with (
            mock.patch.object(governance, "_load_json_file", side_effect=[event, comments]),
            mock.patch.object(governance, "_changed_paths", return_value=["AGENTS.md"]),
            mock.patch.object(governance, "_commit_sha", return_value=HEAD_SHA),
            mock.patch.object(governance, "_is_ancestor", return_value=True),
            mock.patch.object(
                sys,
                "argv",
                [
                    "check_pr_governance.py",
                    "--event",
                    "event.json",
                    "--comments",
                    "comments.json",
                ],
            ),
        ):
            self.assertEqual(governance.main(), 1)

    def test_production_main_rejects_composed_non_prose_governance(self) -> None:
        event, contract, _comments = _fixture(risk="high")
        section_padding = (
            "-     abcdefghijklmnopqrst",
            "![abcdefghijklmnopqrst](/asset.png )",
            "\r\n".join("- [x]" for _ in range(21)),
            r"$\phantom{abcdefghijklmnopqrst}$",
            "2d0d8f1fef81f5fa2c6e5121c76f7cdea1d1154c",
            "[abcdefghijklmnopqrst]: /asset.png",
            "```text\nabcdefghijklmnopqrst\n```",
        )
        body = str(event["pull_request"]["body"])
        for section, padding in zip(governance.REQUIRED_SECTIONS, section_padding):
            body = _replace_required_section_content(body, section, padding)
        rebound, _comments = _rebind_modified_body(event, contract, body)

        evidence_padding = (
            "-     abcdefghijklmnopqrst",
            "![abcdefghijklmnopqrst](/asset.png )",
            "\r\n".join("- [x]" for _ in range(21)),
        )
        comments = []
        for role, padding in zip(_roles_for("high"), evidence_padding):
            review = _attestation(rebound, role)
            review["evidence"] = [padding]
            comments.append(_comment(review))

        errors = _validate(event, comments, ["AGENTS.md"])
        self.assertEqual(
            sum("has no reviewable content" in error for error in errors),
            len(governance.REQUIRED_SECTIONS),
            errors,
        )
        self.assertEqual(
            sum("four plain ASCII words" in error for error in errors),
            3,
            errors,
        )
        with (
            mock.patch.object(governance, "_load_json_file", side_effect=[event, comments]),
            mock.patch.object(governance, "_changed_paths", return_value=["AGENTS.md"]),
            mock.patch.object(governance, "_commit_sha", return_value=HEAD_SHA),
            mock.patch.object(governance, "_is_ancestor", return_value=True),
            mock.patch.object(
                sys,
                "argv",
                [
                    "check_pr_governance.py",
                    "--event",
                    "event.json",
                    "--comments",
                    "comments.json",
                ],
            ),
        ):
            self.assertEqual(governance.main(), 1)

    def test_review_evidence_allows_autolinks_and_angle_comparisons(self) -> None:
        examples = (
            "Reviewed the hosted log at <https://example.com/report> completely.",
            "Verified that the supported range x < y > z remains unchanged.",
            "Confirmed the placeholder check rejects a bare TODO marker.",
        )
        for content in examples:
            with self.subTest(content=content):
                event, contract, comments = _fixture()
                for comment, role in zip(comments, _roles_for("standard")):
                    review = _attestation(contract, role)
                    review["evidence"] = [content]
                    comment["body"] = (
                        "<!-- agent-review:v1\n"
                        f"{json.dumps(review, indent=2)}\n"
                        "-->"
                    )
                self.assertEqual(_validate(event, comments), [])

    def test_required_sections_reject_raw_html_blocks(self) -> None:
        event, contract, _comments = _fixture()
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Validation",
            "<details>\n<summary>&nbsp;</summary>\n"
            "abcdefghijklmnopqrst\n</details>",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertTrue(
            any(
                "section '## Validation' contains forbidden HTML-shaped source" in error
                for error in errors
            ),
            errors,
        )

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
        self.assertIn("EXPECTED_BASE_SHA", governance_job)
        self.assertIn("EXPECTED_BASE_REF", governance_job)
        self.assertIn("EXPECTED_HEAD_REF", governance_job)
        self.assertIn('live["base"]["sha"] != expected_base', governance_job)
        self.assertIn('live["base"]["ref"] != expected_base_ref', governance_job)
        self.assertIn('live["head"]["ref"] != expected_head_ref', governance_job)
        self.assertIn("ref: ${{ github.event.pull_request.head.sha }}", governance_job)

        collector = governance_job.split("<<'PY'\n", 1)[1].split("\n          PY", 1)[0]
        compile(textwrap.dedent(collector), "workflow-context-collector", "exec")

        self.assertGreaterEqual(
            workflow.count(
                "ref: ${{ github.event.pull_request.head.sha || github.sha }}"
            ),
            2,
        )

    def test_required_ci_name_is_reserved_for_pull_request_runs(self) -> None:
        workflow = (governance.ROOT / ".github/workflows/gamemaker-tests.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "name: ${{ github.event_name == 'pull_request' && 'Required CI' || "
            "'Non-PR CI (not merge evidence)' }}",
            workflow,
        )
        self.assertIn("Manual dispatches are diagnostic", workflow)
        required_job = workflow.split("  required_ci:\n", 1)[1]
        self.assertIn('if [[ "$EVENT_NAME" == "pull_request" ]]', required_job)
        self.assertIn(
            'require_result "PR governance" "$GOVERNANCE_RESULT" "success"',
            required_job,
        )


if __name__ == "__main__":
    unittest.main()

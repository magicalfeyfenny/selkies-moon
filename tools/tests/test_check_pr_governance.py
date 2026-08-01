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
    head_ref: str = "codex/46-governance",
    risk: str = "standard",
    pr_number: int = PR_NUMBER,
) -> dict[str, object]:
    value: dict[str, object] = {
        "version": 1,
        "repository": REPOSITORY,
        "pr_number": pr_number,
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
        "## Primary issue\n\nPrimary issue #46 defines this bounded governance task.",
        "## Intent\n\nDeliver one bounded governance change.",
        "## Scope\n\nAdd a machine-checked contract and review evidence.",
        "## Non-goals\n\nDo not publish a release.",
        "## Acceptance mapping\n\nThe checker and templates implement every stated lifecycle requirement.",
        "## Important files and ownership\n\nGovernance documentation and the PR checker own these changes.",
        f"## Risk\n\nDeclared risk: {contract.get('risk', 'unknown')}.",
        "## Validation\n\nRun the governance unit tests and repository checks.",
        "## Review status\n\nRequired independent reviewers will attest to this exact candidate.",
        "## Remaining risks\n\nRemote issue existence remains verified by GitHub workflow context when available.",
        "## Merge intention\n\nThis branch is intended to merge after required validation and review.",
        "## External-action authority\n\nNo merge, release, deployment, or publication authority is granted by this PR.",
        "## Rollback or final disposition\n\nRevert the governance commit or record the retained branch disposition.",
        "## Non-merge record\n\nThis merge-intended branch has no non-merge record.",
        "## Lifecycle exception\n\nNo lifecycle exception applies to this issue-numbered branch.",
        (
            "## Independent agent review\n\n"
            "Attestations are supplied in PR comments and bind this exact contract.\n\n"
            f"<!-- pr-contract:v1\n{payload}\n-->"
        ),
    ]
    return "\n\n".join(sections)


def _hidden_body(contract: dict[str, object]) -> str:
    sections = [
        "## Primary issue\n\nPrimary issue #46 defines this bounded governance task.",
        "## Intent\n\nDeliver one bounded governance change.",
        "## Scope\n\nAdd a machine-checked contract and review evidence.",
        "## Non-goals\n\nDo not publish a release.",
        "## Acceptance mapping\n\nThe checker and templates implement every stated lifecycle requirement.",
        "## Important files and ownership\n\nGovernance documentation and the PR checker own these changes.",
        f"## Risk\n\nDeclared risk: {contract.get('risk', 'unknown')}.",
        "## Validation\n\nRun the governance unit tests and repository checks.",
        "## Review status\n\nRequired independent reviewers will attest to this exact candidate.",
        "## Remaining risks\n\nRemote issue existence remains verified by GitHub workflow context when available.",
        "## Merge intention\n\nThis branch is intended to merge after required validation and review.",
        "## External-action authority\n\nNo merge, release, deployment, or publication authority is granted by this PR.",
        "## Rollback or final disposition\n\nRevert the governance commit or record the retained branch disposition.",
        "## Non-merge record\n\nThis merge-intended branch has no non-merge record.",
        "## Lifecycle exception\n\nNo lifecycle exception applies to this issue-numbered branch.",
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
    head_ref: str = "codex/46-governance",
    risk: str = "standard",
    head_repository: str = REPOSITORY,
    pr_number: int = PR_NUMBER,
) -> tuple[dict[str, object], dict[str, object], list[dict[str, object]]]:
    contract = _contract(
        base_ref=base_ref,
        head_ref=head_ref,
        risk=risk,
        pr_number=pr_number,
    )
    event: dict[str, object] = {
        "number": pr_number,
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


def _hidden_lifecycle_prose(content: str, form: str) -> str:
    if form == "fenced":
        return f"```text\n{content}\n```"
    if form == "inline":
        return f"`{content}`"
    if form == "indented":
        return textwrap.indent(content, "    ")
    if form == "comment":
        return f"<!-- {content} -->"
    raise AssertionError(f"unknown hidden-prose form: {form}")


def _non_merge_record(
    *,
    hidden_field: str | None = None,
    hidden_form: str | None = None,
) -> str:
    fields = {
        "purpose": "Purpose: preserve validation evidence.",
        "candidate": f"Exact candidate or workflow SHA: {HEAD_SHA}.",
        "evidence": "Retained evidence: hosted logs remain available.",
        "disposition": "Final disposition: close after issue review.",
    }
    if hidden_field == "all":
        if hidden_form is None:
            raise AssertionError("hidden records need a Markdown form")
        return _hidden_lifecycle_prose(" ".join(fields.values()), hidden_form)

    record: list[str] = []
    for name, value in fields.items():
        if name == hidden_field:
            if hidden_form is None:
                raise AssertionError("hidden fields need a Markdown form")
            record.append(_hidden_lifecycle_prose(value, hidden_form))
        else:
            record.append(value)
    return "\n\n".join(record)


def _field_with_hidden_value(label: str, value: str, form: str) -> str:
    return f"{label}:\n{_hidden_lifecycle_prose(value, form)}"


def _validate_lifecycle_sections(
    replacements: dict[str, str],
    *,
    head_ref: str = "validation/46-lifecycle-regression",
    pr_number: int = PR_NUMBER,
) -> list[str]:
    event, contract, _comments = _fixture(
        head_ref=head_ref,
        pr_number=pr_number,
    )
    body = str(event["pull_request"]["body"])
    for section, content in replacements.items():
        body = _replace_required_section_content(body, section, content)
    _rebound, comments = _rebind_modified_body(event, contract, body)
    return _validate(event, comments)


class PullRequestGovernanceTests(unittest.TestCase):
    def test_valid_standard_contract_and_two_comment_reviews_pass(self) -> None:
        event, _contract_value, comments = _fixture()
        self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_accepts_merge_intended_validation_branch(self) -> None:
        event, _contract, comments = _fixture(head_ref="validation/46-durable-evidence")
        self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_intention_and_closure_render_only_valid_links(self) -> None:
        self.assertEqual(
            governance._lifecycle_intentions(
                "Context remains reviewable. [This branch is intended to "
                "merge][missing]."
            ),
            (False, False),
        )
        self.assertEqual(
            governance._lifecycle_intentions(
                "[This branch is intended to merge][target].\n\n[target]: /url"
            ),
            (True, False),
        )
        self.assertEqual(
            governance._lifecycle_intentions(
                "Context remains reviewable. [This branch is not intended to "
                "merge][missing]."
            ),
            (False, False),
        )
        self.assertEqual(
            governance._lifecycle_intentions(
                "[This branch is not intended to merge][target].\n\n"
                "[target]: /url"
            ),
            (False, True),
        )
        self.assertFalse(governance._has_operative_closes("[Closes #46][missing]."))
        self.assertTrue(
            governance._has_operative_closes(
                "[Closes #46][target].\n\n[target]: /url"
            )
        )

    def test_lifecycle_accepts_non_merge_validation_and_codex_branches(self) -> None:
        event, contract, _comments = _fixture(head_ref="validation/46-candidate-evidence")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Merge intention",
            "This validation branch is not intended to merge and retains its test evidence.",
        )
        body = _replace_required_section_content(
            body,
            "Non-merge record",
            _non_merge_record(),
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        self.assertEqual(_validate(event, comments), [])

        event, contract, _comments = _fixture(head_ref="codex/46-candidate-evidence")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Merge intention",
            "This codex branch is not intended to merge and retains its test evidence.",
        )
        body = _replace_required_section_content(
            body,
            "Non-merge record",
            _non_merge_record(),
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_accepts_documented_legacy_name_exception(self) -> None:
        event, contract, _comments = _fixture(
            head_ref="validation/ornate-ui-characterization-acdf8e5"
        )
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Primary issue",
            "Primary issue #47 registers this frozen legacy candidate.",
        )
        body = _replace_required_section_content(
            body,
            "Lifecycle exception",
            "\n".join(
                (
                    "Legacy registration: #47.",
                    (
                        "Original branch identity: "
                        "validation/ornate-ui-characterization-acdf8e5."
                    ),
                    "Original primary issue: #54.",
                    f"Immutable candidate SHA: {HEAD_SHA}.",
                    "Retained evidence: historical logs remain attached.",
                    "Intended disposition: retain until migration closes.",
                    "Reason: frozen candidate retains its original identity.",
                )
            ),
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_rejects_missing_branch_issue_or_primary_issue(self) -> None:
        event, _contract_value, comments = _fixture(head_ref="codex/lifecycle")
        errors = _validate(event, comments)
        self.assertIn("lifecycle: source branch must include its primary issue number; use codex/<issue>-<slug>", errors)

        event, _contract_value, comments = _fixture()
        event["pull_request"]["body"] = event["pull_request"]["body"].replace(  # type: ignore[index]
            "## Primary issue", "## Removed primary issue"
        )
        errors = _validate(event, comments)
        self.assertTrue(any("name one primary issue" in error for error in errors), errors)

    def test_lifecycle_rejects_malformed_or_mismatched_issue_metadata(self) -> None:
        event, contract, _comments = _fixture()
        malformed = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Primary issue",
            "Primary issue 46 defines this bounded governance task.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, malformed)
        errors = _validate(event, comments)
        self.assertTrue(any("name one primary issue" in error for error in errors), errors)

        event, _contract_value, comments = _fixture(head_ref="validation/47-other-task")
        errors = _validate(event, comments)
        self.assertIn("lifecycle: source branch issue number must match '## Primary issue'", errors)

        event, _contract_value, comments = _fixture(head_ref="validation/other-task")
        errors = _validate(event, comments)
        self.assertIn(
            "lifecycle: source branch must include its primary issue number; use codex/<issue>-<slug>",
            errors,
        )

    def test_lifecycle_rejects_merge_intended_archival_and_incomplete_legacy_metadata(self) -> None:
        event, _contract_value, comments = _fixture(head_ref="archival/46-evidence")
        errors = _validate(event, comments)
        self.assertIn(
            "lifecycle: archival branch must state it is not intended to merge",
            errors,
        )

        event, contract, _comments = _fixture(head_ref="frozen-candidate")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Lifecycle exception",
            "Legacy registration: #47 documents this preserved candidate.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertIn("lifecycle: legacy exception must declare its immutable candidate SHA", errors)
        self.assertIn("lifecycle: legacy exception must state a reason", errors)
        self.assertIn("lifecycle: only primary issue #47 may declare a legacy registration", errors)

    def test_lifecycle_rejects_non_merge_branch_without_complete_retention_record(self) -> None:
        event, contract, _comments = _fixture(head_ref="documentation/46-retained-notes")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Merge intention",
            "This documentation branch is not intended to merge and remains retained for reference.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertIn("lifecycle: non-merge branch must state its exact candidate or workflow SHA", errors)
        self.assertIn("lifecycle: non-merge branch must state retained evidence", errors)

    def test_lifecycle_rejects_contradictory_dispositions_and_invalid_main_hotfix_name(self) -> None:
        event, contract, _comments = _fixture(head_ref="validation/46-contradictory")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Merge intention",
            "This branch is intended to merge but is not intended to merge after validation.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertIn(
            "lifecycle: state whether this branch is intended to merge or not intended to merge",
            errors,
        )

        event, contract, _comments = _fixture(head_ref="validation/46-archival-disposition")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Rollback or final disposition",
            "Final disposition: retain this candidate permanently as evidence; it will never merge.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertIn(
            "lifecycle: merge-intended branch must not declare a non-merge final disposition",
            errors,
        )

        event, contract, _comments = _fixture(head_ref="validation/46-historical-context")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Rollback or final disposition",
            "A normal revert restores the prior rule. After merge, archival documentation preserves historical context.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        self.assertEqual(_validate(event, comments), [])

        for disposition in (
            "Final disposition: archive the evidence after merge.",
            "Final disposition: retain the candidate after merge for audit evidence.",
            "Final disposition: close this branch after merge.",
        ):
            with self.subTest(disposition=disposition):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-post-merge-disposition"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Rollback or final disposition",
                    disposition,
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertEqual(_validate(event, comments), [])

        event, contract, _comments = _fixture(head_ref="validation/46-post-merge-bypass")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Rollback or final disposition",
            "Final disposition: retain this candidate permanently without merging. After merge, preserve the audit log.",
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertIn(
            "lifecycle: merge-intended branch must not declare a non-merge final disposition",
            errors,
        )

        for disposition in (
            "Final disposition: retain this candidate permanently without merging, then archive evidence after merge.",
            "Final disposition: retain this candidate permanently without merging but archive evidence after merge.",
        ):
            with self.subTest(disposition=disposition):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-mixed-disposition"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Rollback or final disposition",
                    disposition,
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                errors = _validate(event, comments)
                self.assertIn(
                    "lifecycle: merge-intended branch must not declare a non-merge final disposition",
                    errors,
                )

        event, contract, _comments = _fixture(head_ref="validation/46-non-merge-closes")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Scope",
            "This candidate retains the current evidence. Closes #46 when this pull request merges.",
        )
        body = _replace_required_section_content(
            body,
            "Merge intention",
            "This validation branch is not intended to merge and retains its test evidence.",
        )
        body = _replace_required_section_content(
            body,
            "Non-merge record",
            _non_merge_record(),
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        errors = _validate(event, comments)
        self.assertIn("lifecycle: non-merge branch must not use 'Closes #<issue>'", errors)

        event, contract, _comments = _fixture(head_ref="validation/46-code-example")
        body = _replace_required_section_content(
            str(event["pull_request"]["body"]),
            "Scope",
            "This retained candidate documents a command example.\n\n```text\nCloses #46\n```",
        )
        body = _replace_required_section_content(
            body,
            "Merge intention",
            "This validation branch is not intended to merge and retains its test evidence.",
        )
        body = _replace_required_section_content(
            body,
            "Non-merge record",
            _non_merge_record(),
        )
        _rebound, comments = _rebind_modified_body(event, contract, body)
        self.assertEqual(_validate(event, comments), [])

        for head_ref in ("hotfix/46-/nested", "hotfix/46-patch/extra"):
            with self.subTest(head_ref=head_ref):
                event, _contract_value, comments = _fixture(
                    base_ref="main", head_ref=head_ref, risk="main-promotion"
                )
                errors = _validate(
                    event, comments, ["README.md"], candidate_tree=TREE_SHA, base_is_ancestor=True
                )
                self.assertTrue(any("PRs into main" in error for error in errors), errors)

    def test_lifecycle_requires_visible_non_merge_record_fields(self) -> None:
        missing_errors = {
            "purpose": "lifecycle: non-merge branch must state its purpose",
            "candidate": "lifecycle: non-merge branch must state its exact candidate or workflow SHA",
            "evidence": "lifecycle: non-merge branch must state retained evidence",
            "disposition": (
                "lifecycle: non-merge branch must state final disposition or close/deletion conditions"
            ),
        }
        for form in ("fenced", "inline", "indented", "comment"):
            for field, expected_error in missing_errors.items():
                with self.subTest(form=form, field=field):
                    event, contract, _comments = _fixture(
                        head_ref="validation/46-hidden-non-merge-record"
                    )
                    body = _replace_required_section_content(
                        str(event["pull_request"]["body"]),
                        "Merge intention",
                        "This validation branch is not intended to merge and retains test evidence.",
                    )
                    body = _replace_required_section_content(
                        body,
                        "Non-merge record",
                        _non_merge_record(hidden_field=field, hidden_form=form),
                    )
                    _rebound, comments = _rebind_modified_body(event, contract, body)
                    self.assertIn(expected_error, _validate(event, comments))

            with self.subTest(form=form, field="all"):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-hidden-complete-record"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Merge intention",
                    "This validation branch is not intended to merge and retains test evidence.",
                )
                body = _replace_required_section_content(
                    body,
                    "Non-merge record",
                    _non_merge_record(hidden_field="all", hidden_form=form),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                errors = _validate(event, comments)
                for expected_error in missing_errors.values():
                    self.assertIn(expected_error, errors)

    def test_lifecycle_fields_are_line_bounded_when_values_are_hidden(self) -> None:
        required_fields = (
            ("Purpose", "preserve validation evidence.", "lifecycle: non-merge branch must state its purpose"),
            (
                "Exact candidate or workflow SHA",
                HEAD_SHA,
                "lifecycle: non-merge branch must state its exact candidate or workflow SHA",
            ),
            (
                "Retained evidence",
                "hosted logs remain available.",
                "lifecycle: non-merge branch must state retained evidence",
            ),
            (
                "Final disposition",
                "close after issue review.",
                "lifecycle: non-merge branch must state final disposition or close/deletion conditions",
            ),
        )
        for form in ("fenced", "inline", "indented", "comment"):
            for hidden_index, (label, value, expected_error) in enumerate(required_fields):
                with self.subTest(form=form, label=label):
                    record = []
                    for index, (other_label, other_value, _error) in enumerate(required_fields):
                        if index == hidden_index:
                            record.append(_field_with_hidden_value(other_label, other_value, form))
                        else:
                            record.append(f"{other_label}: {other_value}")
                    event, contract, _comments = _fixture(
                        head_ref="validation/46-line-bounded-fields"
                    )
                    body = _replace_required_section_content(
                        str(event["pull_request"]["body"]),
                        "Merge intention",
                        "This validation branch is not intended to merge and retains test evidence.",
                    )
                    body = _replace_required_section_content(
                        body, "Non-merge record", "\n".join(record)
                    )
                    _rebound, comments = _rebind_modified_body(event, contract, body)
                    self.assertIn(expected_error, _validate(event, comments))

            with self.subTest(form=form, labels="all-visible-values-hidden"):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-all-hidden-values"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Merge intention",
                    "This validation branch is not intended to merge and retains test evidence.",
                )
                body = _replace_required_section_content(
                    body,
                    "Non-merge record",
                    "\n".join(
                        _field_with_hidden_value(label, value, form)
                        for label, value, _error in required_fields
                    ),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                errors = _validate(event, comments)
                for _label, _value, expected_error in required_fields:
                    self.assertIn(expected_error, errors)

            with self.subTest(form=form, label="Close or deletion conditions"):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-hidden-close-conditions"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Merge intention",
                    "This validation branch is not intended to merge and retains test evidence.",
                )
                body = _replace_required_section_content(
                    body,
                    "Non-merge record",
                    "\n".join(
                        (
                            "Purpose: preserve validation evidence.",
                            f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                            "Retained evidence: hosted logs remain available.",
                            _field_with_hidden_value(
                                "Close or deletion conditions", "close after issue review.", form
                            ),
                        )
                    ),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertIn(
                    "lifecycle: non-merge branch must state final disposition or close/deletion conditions",
                    _validate(event, comments),
                )

    def test_lifecycle_legacy_fields_are_line_bounded_when_values_are_hidden(self) -> None:
        required_fields = (
            ("Legacy registration", "#47", "lifecycle: legacy exception must declare 'Legacy registration: #47'"),
            ("Immutable candidate SHA", HEAD_SHA, "lifecycle: legacy exception must declare its immutable candidate SHA"),
            ("Reason", "frozen candidate retains its original identity.", "lifecycle: legacy exception must state a reason"),
            ("Original branch identity", "validation/legacy-candidate", "lifecycle: legacy exception must state the original branch identity"),
            ("Original primary issue", "#54", "lifecycle: legacy exception must state the original primary issue or unknown"),
            ("Retained evidence", "historical logs remain attached.", "lifecycle: legacy exception must state retained evidence"),
            ("Intended disposition", "retain until migration closes.", "lifecycle: legacy exception must state intended disposition"),
        )
        for form in ("fenced", "inline", "indented", "comment"):
            for hidden_index, (label, value, expected_error) in enumerate(required_fields):
                with self.subTest(form=form, label=label):
                    exception = []
                    for index, (other_label, other_value, _error) in enumerate(required_fields):
                        if index == hidden_index:
                            exception.append(_field_with_hidden_value(other_label, other_value, form))
                        else:
                            exception.append(f"{other_label}: {other_value}")
                    event, contract, _comments = _fixture(
                        head_ref="validation/legacy-candidate-acdf8e5"
                    )
                    body = _replace_required_section_content(
                        str(event["pull_request"]["body"]),
                        "Primary issue",
                        "Primary issue #47 registers this frozen legacy candidate.",
                    )
                    body = _replace_required_section_content(
                        body, "Lifecycle exception", "\n".join(exception)
                    )
                    _rebound, comments = _rebind_modified_body(event, contract, body)
                    self.assertIn(expected_error, _validate(event, comments))

    def test_lifecycle_ignores_hidden_non_merge_examples(self) -> None:
        for form in ("fenced", "inline", "indented", "comment"):
            with self.subTest(form=form):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-hidden-disposition-example"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Merge intention",
                    "This branch is intended to merge after validation.\n\n"
                    + _hidden_lifecycle_prose(
                        "This branch is not intended to merge.", form
                    ),
                )
                body = _replace_required_section_content(
                    body,
                    "Non-merge record",
                    "No non-merge record applies to this candidate.\n\n"
                    + _non_merge_record(hidden_field="all", hidden_form=form),
                )
                body = _replace_required_section_content(
                    body,
                    "Rollback or final disposition",
                    "Final disposition: This section describes a hidden parser example.\n\n"
                    + _hidden_lifecycle_prose("This branch will not be merged.", form),
                )
                body = _replace_required_section_content(
                    body,
                    "Lifecycle exception",
                    "No lifecycle exception applies to this candidate.\n\n"
                    + _hidden_lifecycle_prose(
                        f"Legacy registration: #47. Immutable candidate SHA: {HEAD_SHA}.",
                        form,
                    ),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_uses_reviewable_prose_for_closes_detection(self) -> None:
        for form in ("visible", "list", "fenced", "inline", "indented", "comment"):
            with self.subTest(form=form):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-closes-prose"
                )
                if form == "visible":
                    closes = "Closes #46"
                elif form == "list":
                    closes = "- Closes #46"
                else:
                    closes = _hidden_lifecycle_prose("Closes #46", form)
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Scope",
                    f"This retained candidate records the lifecycle rule.\n\n{closes}",
                )
                body = _replace_required_section_content(
                    body,
                    "Merge intention",
                    "This validation branch is not intended to merge and retains test evidence.",
                )
                body = _replace_required_section_content(
                    body,
                    "Non-merge record",
                    _non_merge_record(),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                errors = _validate(event, comments)
                if form in {"visible", "list"}:
                    self.assertIn(
                        "lifecycle: non-merge branch must not use 'Closes #<issue>'", errors
                    )
                else:
                    self.assertEqual(errors, [])

    def test_lifecycle_rejects_ordinary_non_merge_dispositions(self) -> None:
        dispositions = (
            "Final disposition: The candidate will not be merged.",
            "Final disposition: This branch will never be merged!",
            "Final disposition: Retain this candidate instead of merging it.",
            "Final disposition: Close the branch rather than merge.",
            "Final disposition: Close the branch rather than merging.",
            "Final disposition: Retain the evidence without merging.",
            "Final disposition: Do not merge the candidate.",
        )
        for disposition in dispositions:
            with self.subTest(disposition=disposition):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-ordinary-non-merge"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Rollback or final disposition",
                    disposition,
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertIn(
                    "lifecycle: merge-intended branch must not declare a non-merge final disposition",
                    _validate(event, comments),
                )

    def test_lifecycle_rejects_candidate_specific_contradictions_outside_disposition(self) -> None:
        contradictions = (
            ("Scope", "This candidate will never be merged."),
            ("Remaining risks", "This branch will not be merged."),
            ("External-action authority", "The pull request should not be merged."),
            ("Independent agent review", "Do not merge this candidate."),
            ("Scope", "Retain this branch instead of merging it."),
            ("Remaining risks", "Preserve the candidate without merging."),
            ("External-action authority", "This candidate is not being merged."),
        )
        expected_error = (
            "lifecycle: merge-intended branch must not make a candidate-specific non-merge contradiction"
        )
        for section, contradiction in contradictions:
            with self.subTest(section=section, contradiction=contradiction):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-visible-contradiction"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]), section, contradiction
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertIn(expected_error, _validate(event, comments))

        for form in ("fenced", "inline", "indented", "comment"):
            with self.subTest(form=form):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-hidden-contradiction"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Scope",
                    "This scope retains ordinary parser documentation.\n\n"
                    "The checker recognizes the phrase `will never be merged`.\n\n"
                    + _hidden_lifecycle_prose("This candidate will never be merged.", form),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_accepts_post_merge_cleanup_language(self) -> None:
        dispositions = (
            "Final disposition: After a successful merge, delete the branch with separate authority.",
            "Final disposition: After successful integration, delete the branch with separate authority.",
            "Final disposition: After this pull request merges, retain the evidence.",
            "Final disposition: Once successfully merged, close the temporary tracking branch.",
            "Final disposition: Upon successful integration, archive the logs.",
            "Final disposition: Following successful integration, retain the evidence.",
            "Final disposition: Archive the evidence after merge.",
        )
        for disposition in dispositions:
            with self.subTest(disposition=disposition):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-post-merge-cleanup"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Rollback or final disposition",
                    disposition,
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_post_merge_qualification_cannot_legalize_an_earlier_action(self) -> None:
        dispositions = (
            "Final disposition: Delete this branch instead of merging it; after merge, preserve the logs.",
            "Final disposition: Retain this candidate without merging, then archive evidence after merge.",
            "Final disposition: This candidate will never be merged, but logs may be retained after integration.",
            "Final disposition: Do not merge this branch. After a successful merge, delete temporary records.",
            "Final disposition: Retain this candidate without merging. Archive evidence after merge.",
        )
        for disposition in dispositions:
            with self.subTest(disposition=disposition):
                event, contract, _comments = _fixture(
                    head_ref="validation/46-post-merge-scope"
                )
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Rollback or final disposition",
                    disposition,
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertIn(
                    "lifecycle: merge-intended branch must not declare a non-merge final disposition",
                    _validate(event, comments),
                )

    def test_lifecycle_primary_issue_requires_one_raw_reference(self) -> None:
        valid = (
            "Closes #46 upon merge.",
            "The bounded task closes (#46) after merge.",
            "Closes #46 upon merge; malformed neighbors #046 and repo#46 do not count.",
        )
        for content in valid:
            with self.subTest(valid=content):
                self.assertEqual(
                    _validate_lifecycle_sections({"Primary issue": content}),
                    [],
                )

        invalid = (
            (
                "zero",
                "The primary issue number is intentionally absent from this sentence.",
                "lifecycle: name one primary issue as #<number> in '## Primary issue'",
            ),
            (
                "two",
                "Issues #46 and #47 both appear as raw references here.",
                "lifecycle: '## Primary issue' must name exactly one #<number>",
            ),
            (
                "descriptive plus closes",
                "The bounded correction is tracked by #46. Closes #46 upon merge.",
                "lifecycle: '## Primary issue' must name exactly one #<number>",
            ),
        )
        for name, content, expected in invalid:
            with self.subTest(invalid=name):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Primary issue": content}),
                )

        malformed = (
            "issue 46",
            "#046",
            "# 46",
            "word#46",
            "repo#46",
            "##46",
            "#46word",
            "#46_suffix",
            "#46-neighbor",
            "#46.7",
            "#46#47",
        )
        for token in malformed:
            with self.subTest(malformed=token):
                content = f"The malformed neighboring token {token} is not a raw issue reference."
                self.assertIn(
                    "lifecycle: name one primary issue as #<number> in '## Primary issue'",
                    _validate_lifecycle_sections({"Primary issue": content}),
                )

    def test_lifecycle_exact_sha_fields_use_full_hex_token_boundaries(self) -> None:
        labels = ("Immutable candidate SHA", "Exact candidate or workflow SHA")
        valid_values = (
            HEAD_SHA,
            f" {HEAD_SHA} ",
            f"({HEAD_SHA})",
            f"[{HEAD_SHA}]",
            f"g{HEAD_SHA}z",
            f"G{HEAD_SHA}Z",
            f"_{HEAD_SHA}-",
            f"={HEAD_SHA},",
        )
        invalid_values = (
            "a" * 39,
            "A" * 40,
            "a" * 41,
            "b" + HEAD_SHA,
            HEAD_SHA + "c",
            "A" + HEAD_SHA,
            HEAD_SHA + "F",
            "0" + HEAD_SHA,
            HEAD_SHA + "9",
            "a" + HEAD_SHA + "b",
            "A" + HEAD_SHA + "F",
            "0" + HEAD_SHA + "9",
        )
        for label in labels:
            for value in valid_values:
                with self.subTest(label=label, valid=value):
                    fields = governance._parse_lifecycle_fields(f"{label}: {value}")
                    self.assertEqual(
                        governance._has_exact_sha_field(fields, label),
                        HEAD_SHA,
                    )
            for value in invalid_values:
                with self.subTest(label=label, invalid=value):
                    fields = governance._parse_lifecycle_fields(f"{label}: {value}")
                    self.assertIsNone(governance._has_exact_sha_field(fields, label))

        for name, value in (
            ("uppercase prefix", "A" + HEAD_SHA),
            ("uppercase suffix", HEAD_SHA + "F"),
            ("uppercase both sides", "A" + HEAD_SHA + "F"),
            ("numeric both sides", "0" + HEAD_SHA + "9"),
        ):
            with self.subTest(non_merge=name):
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains deterministic evidence."
                        ),
                        "Non-merge record": "\n".join(
                            (
                                "Purpose: preserve validation evidence.",
                                f"Exact candidate or workflow SHA: {value}.",
                                "Retained evidence: hosted logs remain available.",
                                "Final disposition: close after issue review.",
                            )
                        ),
                    }
                )
                self.assertIn(
                    "lifecycle: non-merge branch must state its exact candidate or workflow SHA",
                    errors,
                )

            with self.subTest(legacy=name):
                errors = _validate_lifecycle_sections(
                    {
                        "Primary issue": (
                            "Primary issue #47 registers this frozen legacy candidate."
                        ),
                        "Lifecycle exception": "\n".join(
                            (
                                "Legacy registration: #47.",
                                "Original branch identity: validation/frozen-candidate.",
                                "Original primary issue: #54.",
                                f"Immutable candidate SHA: {value}.",
                                "Retained evidence: historical logs remain attached.",
                                "Intended disposition: retain until migration closes.",
                                "Reason: frozen history retains its original identity.",
                            )
                        ),
                    },
                    head_ref="validation/frozen-candidate",
                )
                self.assertIn(
                    "lifecycle: legacy exception must declare its immutable candidate SHA",
                    errors,
                )

    def test_lifecycle_rejects_bounded_candidate_contradiction_grammar(self) -> None:
        expected = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        contradictions = (
            ("punctuation", "This candidate, emphatically, will never be merged."),
            (
                "singular pronoun",
                "This candidate remains the subject here. It will never be merged.",
            ),
            (
                "plural pronoun",
                "These changes are the current candidate. They should not be merged.",
            ),
            ("plural subject", "These candidate branches will never be merged."),
            ("won't", "This pull request won't be merged."),
            ("shouldn't", "This PR shouldn't merge."),
            ("can't", "These changes can't be merged."),
            ("isn't", "This branch isn't being merged."),
            ("must not active", "The PR must not merge."),
            ("must not passive", "The current branch must not be merged."),
            ("do-not imperative", "Do-not-merge this branch after validation."),
            ("never-merge imperative", "Never-merge this PR after validation."),
            ("passive prohibition", "This PR is prohibited from merging."),
            ("gerund prohibition", "Merging this PR is forbidden by this contract."),
            (
                "rather than",
                "Retain this branch rather than merging it into the target.",
            ),
            (
                "instead of",
                "Archive this candidate instead of merging it into dev.",
            ),
            ("without", "Close this PR without merging it into dev."),
            ("retain replacement", "Retain this candidate as the final outcome."),
            ("archive replacement", "Archive this branch as the final outcome."),
            ("preserve replacement", "Preserve these changes as the final outcome."),
            ("close replacement", "Close this pull request as the final outcome."),
            ("delete replacement", "Delete the current branch as the final outcome."),
        )
        for name, contradiction in contradictions:
            with self.subTest(name=name):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        numbered_errors = _validate_lifecycle_sections(
            {"Scope": "Pull request #65 should not be merged."},
            pr_number=65,
        )
        self.assertIn(expected, numbered_errors)

        head_ref = "codex/46-exact-candidate"
        self.assertIn(
            expected,
            _validate_lifecycle_sections(
                {"Scope": f"{head_ref} will never be merged."},
                head_ref=head_ref,
            ),
        )

        safe_controls = (
            "The historical branch will not be merged.",
            "Pull request #66 should not be merged.",
            "Do not merge unrelated changes into this candidate.",
            "This branch must not merge unrelated changes.",
            "This branch must not merge until validation finishes.",
            "After this pull request merges, archive the branch.",
        )
        for content in safe_controls:
            with self.subTest(safe=content):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {"Scope": content},
                        pr_number=65,
                    ),
                    [],
                )

    def test_lifecycle_distinguishes_descriptive_and_operative_clauses(self) -> None:
        descriptive = (
            'The checker rejects the example "This branch must not merge."',
            "The checker rejects the example “This branch must not merge.”",
            "The checker rejects the example 'This branch must not merge.'",
            "The checker rejects statements saying this candidate will never be merged.",
            "This policy detects and rejects the contradiction that this branch will not be merged.",
            "The validation rule rejects instructions such as do not merge this candidate.",
            "This test case describes when the current branch must not merge.",
            (
                "This parser example remains descriptive prose.\n\n"
                "> This branch must not merge."
            ),
            (
                "This parser example remains descriptive prose.\n\n"
                "`This branch must not merge.`"
            ),
            (
                "This parser example remains descriptive prose.\n\n"
                "```text\nThis branch must not merge.\n```"
            ),
        )
        for content in descriptive:
            with self.subTest(descriptive=content):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": content}),
                    [],
                )

        expected = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        mixed = (
            (
                "descriptive then sentence",
                (
                    "The checker rejects the sentence "
                    '"This branch must not merge." This PR must not merge.'
                ),
            ),
            (
                "descriptive then semicolon",
                (
                    "The policy describes the rejected phrase "
                    '"this branch must not merge"; this PR must not merge.'
                ),
            ),
            (
                "descriptive then coordinated clause",
                (
                    "The checker rejects the phrase "
                    '"this branch must not merge", but this PR must not merge.'
                ),
            ),
            (
                "operative then descriptive",
                (
                    "This PR must not merge. The checker later explains the "
                    'rejected phrase "this branch must not merge."'
                ),
            ),
        )
        for name, content in mixed:
            with self.subTest(mixed=name):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": content}),
                )

    def test_lifecycle_rejects_fresh_review_non_merge_predicates(self) -> None:
        expected = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        contradictions = (
            "This branch doesn't merge.",
            "Must not merge this PR.",
            "This PR is prohibited from being merged.",
            "This PR is not intended to merge.",
            "This branch must remain unmerged.",
            "This PR does not merge.",
            "This candidate is designated non-merge.",
            "We must not merge this PR.",
            "Maintainers must not merge this pull request.",
            "We won't merge this PR.",
            "Reviewers cannot merge this candidate.",
            "The orchestrator should not merge this branch.",
            "We mustn't merge these changes.",
            "This PR must remain unmerged.",
            "This PR is non-mergeable.",
            "This PR isn't intended to merge.",
            "This branch is not intended for merge.",
            "This candidate is intended not to merge.",
            "Do not merge these changes.",
            "This candidate remains unmerged.",
            "This candidate became unmerged.",
            "This branch is unmergeable.",
            "This PR is nonmergeable.",
            "This candidate is forbidden from being merged.",
            "This branch is barred from being merged.",
            "This PR is disallowed from being merged.",
            "This candidate is prevented from being merged.",
            "Maintainers are barred from merging this branch.",
            "These changes should remain unmerged.",
            "This branch cannot be merged.",
            "This PR must not merge and evidence remains until validation.",
        )
        for contradiction in contradictions:
            with self.subTest(contradiction=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

    def test_lifecycle_rejects_permission_form_merge_prohibitions(self) -> None:
        expected = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        contradictions = (
            "This PR is not allowed to merge.",
            "This PR is not allowed to be merged.",
            "This branch is not allowed to merge.",
            "These changes are not allowed to be merged.",
        )
        for contradiction in contradictions:
            with self.subTest(contradiction=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        inert_controls = (
            'The checker rejects the example "This PR is not allowed to merge."',
            (
                "This section documents an inert inline code example.\n\n"
                "The checker rejects `This PR is not allowed to be merged.`"
            ),
            (
                "This section documents an inert fenced code example.\n\n"
                "```text\nThis branch is not allowed to merge.\n```"
            ),
            (
                "This section documents an inert blockquote example.\n\n"
                "> These changes are not allowed to be merged."
            ),
            (
                "The checker rejects statements saying these changes are not "
                "allowed to be merged."
            ),
            "Previously, this PR was not allowed to merge.",
            "Previously, these changes were not allowed to be merged.",
            "The historical branch is not allowed to merge.",
            "The unrelated changes are not allowed to be merged.",
            "This PR is not allowed to merge the unrelated changes.",
            "This PR is not allowed to merge until Required CI passes.",
            (
                "These changes are not allowed to be merged while Required CI "
                "is pending."
            ),
            "Pending Required CI, this branch is not allowed to merge.",
        )
        for control in inert_controls:
            with self.subTest(inert_control=control):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": control}),
                    [],
                )

    def test_lifecycle_rejects_blocked_passive_and_infinitival_prohibitions(
        self,
    ) -> None:
        expected = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        required = (
            "This PR is blocked from merging.",
            "This branch is blocked from being merged.",
            "These changes are blocked from being merged.",
            "This PR is not intended to be merged.",
            "This PR is forbidden to merge.",
            "This PR is forbidden to be merged.",
            "This branch is prohibited to merge.",
            "This branch is prohibited to be merged.",
            f"Commit {HEAD_SHA} must not be merged.",
            "This commit must not be merged.",
            "This head commit is blocked from merging.",
            "The current revision must never merge.",
            "This patch is never intended to be merged.",
            "The exact candidate commit must not be merged.",
        )
        nearby_variants = (
            "These pull requests are blocked from merging.",
            "This branch was blocked from being merged.",
            "These changes have been prohibited to merge.",
            "This PR had been forbidden to be merged.",
            "This candidate remains blocked from merging.",
            "This PR will be blocked from merging.",
            "This PR will be forbidden to merge.",
            "This PR will be forbidden to be merged.",
            "This branch is being blocked from merging.",
            "This candidate became blocked from merging.",
            "This PR is still forbidden to merge.",
            "This PR has not been intended to be merged.",
            "This PR shall be forbidden to be merged.",
            "This PR continues to be blocked from merging.",
            "This PR and the historical branch are blocked from being merged.",
            (
                "This PR, the historical branch, and the prior PR are blocked "
                "from merging."
            ),
            (
                "This PR, unlike the historical branch, is blocked from "
                "merging."
            ),
            (
                "This PR together with the historical branch is blocked from "
                "merging."
            ),
            (
                "This PR, as well as the historical branch, is blocked from "
                "merging."
            ),
            (
                "This PR (unlike the previous candidate) is prohibited to "
                "merge."
            ),
            (
                "Neither this PR nor the historical branch is blocked from "
                "merging."
            ),
            "This PR's forbidden to merge.",
            "This PR’s forbidden to be merged.",
            "This PR's blocked from merging.",
            "This PR&#39;s blocked from merging.",
            "This PR’s not intended to be merged.",
            "This PR’s been blocked from merging.",
            "These changes’ve been forbidden to be merged.",
            "This PR’ll be prohibited to merge.",
            "This PR hasn&#39;t been intended to be merged.",
            "This branch hadn't been intended to be merged.",
            "This PR won't be intended to be merged.",
            "This PR mustn't be intended to be merged.",
            "This PR must not be intended to be merged.",
            "This PR is intended not to be merged.",
            "THIS PR IS FORBIDDEN TO BE MERGED.",
            "These changes aren't intended to be merged.",
            "This branch wasn't intended to be merged.",
        )
        for contradiction in (*required, *nearby_variants):
            with self.subTest(contradiction=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        never_intended_variants = (
            "This PR is never intended to be merged.",
            "This PR has never been intended to be merged.",
            "This PR will never be intended to be merged.",
            "This branch shall never be intended to be merged.",
            "This PR is never intended for merging.",
            "These changes are never intended for a merge.",
            "This candidate had never been intended to merge.",
            "This branch might never be intended for merge.",
        )
        for contradiction in never_intended_variants:
            with self.subTest(never_intended=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        for phrase in never_intended_variants[:5]:
            for control in (
                f'The checker rejects the example "{phrase}"',
                f"The checker rejects `{phrase}`",
                f"```text\n{phrase}\n```",
                f"> {phrase}",
            ):
                with self.subTest(
                    never_intended_phrase=phrase,
                    inert_control=control,
                ):
                    self.assertEqual(
                        _validate_lifecycle_sections(
                            {
                                "Scope": (
                                    "This section documents inert parser "
                                    "controls.\n\n"
                                    + control
                                )
                            }
                        ),
                        [],
                    )

        for control in (
            "The historical branch is never intended to be merged.",
            "Previously, this PR was never intended to be merged.",
            (
                "Until Required CI passes, this PR is never intended to be "
                "merged."
            ),
        ):
            with self.subTest(never_intended_inert_context=control):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": control}),
                    [],
                )

        for phrase in required:
            controls = (
                f'The checker rejects the example "{phrase}"',
                f"The checker rejects `{phrase}`",
                f"```text\n{phrase}\n```",
                f"> {phrase}",
            )
            for control in controls:
                with self.subTest(phrase=phrase, control=control):
                    self.assertEqual(
                        _validate_lifecycle_sections(
                            {
                                "Scope": (
                                    "This section documents inert parser controls.\n\n"
                                    + control
                                )
                            }
                        ),
                        [],
                    )

        contracted_controls = (
            "This PR's forbidden to merge.",
            "This PR’s blocked from being merged.",
            "This PR hasn't been intended to be merged.",
            "This PR won't be intended to be merged.",
        )
        for phrase in contracted_controls:
            for control in (
                f'The checker rejects the example "{phrase}"',
                f"The checker rejects `{phrase}`",
            ):
                with self.subTest(phrase=phrase, control=control):
                    self.assertEqual(
                        _validate_lifecycle_sections(
                            {
                                "Scope": (
                                    "This section documents inert contraction "
                                    "controls.\n\n"
                                    + control
                                )
                            }
                        ),
                        [],
                    )

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "This section documents a lazy blockquote control.\n\n"
                        "> Example-only prohibition follows:\n"
                        "This PR is blocked from being merged."
                    )
                }
            ),
            [],
        )

        for contradiction in (
            "- This PR is blocked from merging.",
            "* This PR is forbidden to be merged.",
            "1. This branch is not intended to be merged.",
            "- This PR must not merge.",
            "1. This branch cannot be merged.",
        ):
            with self.subTest(list_contradiction=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        unrelated_controls = (
            "The historical branch is blocked from merging.",
            "The prior pull request is forbidden to be merged.",
            "These unrelated changes are prohibited to merge.",
            "The other candidate was blocked from being merged.",
            "The historical commit is blocked from merging.",
            "The previous revision must not be merged.",
            "The unrelated patch is prohibited to merge.",
            f"Commit {'b' * 40} must not be merged.",
            "The historical branch, unlike this PR, is blocked from merging.",
            (
                "The prior pull request, unlike this branch, is forbidden to "
                "be merged."
            ),
        )
        for control in unrelated_controls:
            with self.subTest(control=control):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": control}),
                    [],
                )

        temporary_or_unrelated_controls = (
            "This PR is blocked from merging until Required CI passes.",
            "This branch is forbidden to merge unless required review passes.",
            "This candidate is prohibited from merging before CI succeeds.",
            "This PR is blocked from merging pending Required CI.",
            "This PR is blocked from merging while Required CI is pending.",
            "Until Required CI passes, this PR is blocked from merging.",
            (
                "While Required CI is pending, this branch is forbidden to "
                "merge."
            ),
            "Pending Required CI, this PR is prohibited from being merged.",
            "Previously, this PR was blocked from merging.",
            (
                "Previously approved for integration, this PR was blocked "
                "from merging."
            ),
            (
                "Formerly approved for integration, this PR had been forbidden "
                "to merge."
            ),
            (
                "Earlier in development, this branch was prohibited to be "
                "merged."
            ),
            (
                "Historically during review, this pull request was never "
                "intended to be merged."
            ),
            (
                "Previously, this PR was blocked from merging and remained "
                "prohibited from merging."
            ),
            (
                "Previously, this PR was forbidden to merge and had been "
                "blocked from merging."
            ),
            "This PR is forbidden to merge the unrelated changes.",
        )
        for control in temporary_or_unrelated_controls:
            with self.subTest(control=control):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": control}),
                    [],
                )

        operative_follow_ons = (
            (
                "Pending Required CI, this PR is blocked from merging and this "
                "branch is forbidden to be merged permanently."
            ),
            (
                "Until CI passes, this PR is blocked from merging and this "
                "branch is prohibited to merge permanently."
            ),
            (
                "While Required CI is pending, this PR is blocked from merging "
                "and this branch is forbidden to merge permanently."
            ),
            (
                "Pending Required CI, this PR is blocked from merging, and "
                "this branch is forbidden to be merged permanently."
            ),
            (
                "Until CI passes, this PR is blocked from merging, and this "
                "branch is prohibited to merge permanently."
            ),
            (
                "While Required CI is pending, this PR is blocked from merging, "
                "and this branch is forbidden to merge permanently."
            ),
            (
                "Previously approved for integration, this PR is now blocked "
                "from merging."
            ),
            (
                "Previously intended to merge, this PR is now forbidden to be "
                "merged."
            ),
            (
                "Earlier validation allowed integration, this PR remains "
                "prohibited to merge."
            ),
            (
                "Historically ready, this pull request is now never intended "
                "to be merged."
            ),
            (
                "Previously, this PR was blocked from merging and remains "
                "prohibited from merging."
            ),
            (
                "Previously, this PR was forbidden to merge and is still "
                "blocked from merging."
            ),
            (
                "Previously, this PR was blocked from merging but remains "
                "prohibited from merging."
            ),
            (
                "The historical branch is blocked from merging, but this PR "
                "is forbidden to be merged."
            ),
            (
                'The checker rejects "This branch is blocked from merging", '
                "whereas this PR is prohibited to merge."
            ),
            (
                "The unrelated changes are forbidden to merge. This current "
                "branch is not intended to be merged."
            ),
            (
                "This PR is blocked from merging pending Required CI, but this "
                "branch is forbidden to be merged."
            ),
            (
                "Previously, this PR was blocked from merging, but this branch "
                "is forbidden to be merged."
            ),
            (
                "Until Required CI passes, this PR is blocked from merging; "
                "however, this branch is prohibited to merge."
            ),
        )
        for content in operative_follow_ons:
            with self.subTest(content=content):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": content}),
                )

        for cr_only_boundary in (
            (
                "Pending Required CI, historical notes remain\r\r"
                "This PR is blocked from merging."
            ),
            (
                "Until validation passes, historical notes remain\r \r"
                "This branch is forbidden to be merged."
            ),
            (
                "While Required CI is pending, historical notes remain\r\t\r"
                "These changes are prohibited to merge."
            ),
        ):
            with self.subTest(cr_only_boundary=cr_only_boundary):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": cr_only_boundary}),
                )

        emphasized_contradictions = (
            "This PR is **blocked** from merging.",
            "This PR is __blocked__ from merging.",
            "This PR is *never* intended to be merged.",
            "This PR is _never_ intended to be merged.",
            "This PR must **not** merge.",
            "This PR must __not__ merge.",
            "*> This PR is blocked from merging.*",
            "**> This PR is blocked from merging.**",
            "_> This PR must not merge._",
            "__> This PR is never intended to be merged.__",
            "This PR is\n    blocked from merging.",
            "This PR must\n    not merge.",
            "This PR is not intended\n    to be merged.",
            "This PR is forbidden\n    to merge.",
            "This PR is\n\tblocked from merging.",
        )
        for contradiction in emphasized_contradictions:
            with self.subTest(emphasized_contradiction=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )
            for control in (
                f'The checker rejects the example "{contradiction}"',
                f"The checker rejects `{contradiction}`",
                f"> {contradiction}",
            ):
                with self.subTest(
                    emphasized_contradiction=contradiction,
                    emphasized_inert_control=control,
                ):
                    self.assertEqual(
                        _validate_lifecycle_sections(
                            {
                                "Scope": (
                                    "This section documents inert parser "
                                    "controls.\n\n"
                                    + control
                                )
                            }
                        ),
                        [],
                    )

        for indented_code_control in (
            (
                "True indented code follows after a blank.\n\n"
                "    This PR is blocked from merging."
            ),
            (
                "True tab-indented code follows after a blank.\n\n"
                "\tThis PR must not merge."
            ),
        ):
            with self.subTest(indented_code_control=indented_code_control):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {"Scope": indented_code_control}
                    ),
                    [],
                )

        linked_contradictions = (
            "This [PR](https://example.test/pr) is blocked from merging.",
            (
                "This [branch](https://example.test/branch) is forbidden "
                "to be merged."
            ),
            (
                "These [changes](https://example.test/change) are prohibited "
                "to merge."
            ),
            (
                "The current [revision](https://example.test/rev) must never "
                "merge."
            ),
            (
                "This [PR][target] is blocked from merging.\n\n"
                "[target]: https://example.test/pr"
            ),
            (
                "This [PR][] is blocked from merging.\n\n"
                "[PR]: https://example.test/pr"
            ),
            (
                "This [PR] is blocked from merging.\n\n"
                "[PR]: https://example.test/pr"
            ),
        )
        for contradiction in linked_contradictions:
            with self.subTest(linked_contradiction=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        for linked_control in (
            "This ![PR](https://example.test/pr) is blocked from merging.",
            "![This PR](/img) is blocked from merging.",
            "![This branch](/img) is forbidden to be merged.",
            "![These changes](/img) are prohibited to merge.",
            "![The current revision](/img) must never merge.",
            (
                "![This PR][target] is blocked from merging.\n\n"
                "[target]: /img"
            ),
            (
                "![This PR][] is blocked from merging.\n\n"
                "[This PR]: /img"
            ),
            (
                "![This PR] is blocked from merging.\n\n"
                "[This PR]: /img"
            ),
            "![This PR][missing] is blocked from merging.",
            "![This PR](<broken) is blocked from merging.",
            "[This PR is blocked from merging]: /img",
            "[This branch is forbidden to be merged]: /img",
            "[These changes are prohibited to merge]: /img",
            "[The current revision must never merge]: /img",
            "[This PR]: <is&#32;blocked&#32;from&#32;merging>",
            (
                "[This PR is blocked from merging]:\n"
                "  /img \"multiline reference title\""
            ),
            "This [PR][missing] is blocked from merging.",
            "This [PR](<broken) is blocked from merging.",
            "[This PR][missing] is blocked from merging.",
            "[This branch][missing] is forbidden to be merged.",
            "[These changes](<broken) are prohibited to merge.",
            "[The current revision](<broken) must never merge.",
            r"\[This PR](/img) is blocked from merging.",
            r"\[This branch](/img) is forbidden to be merged.",
            "&#91;These changes&#93;(/img) are prohibited to merge.",
            "&#x5b;The current revision&#x5d;(/img) must never merge.",
            "The checker rejects `This [PR](https://example.test/pr) is blocked.`",
            "> This [PR](https://example.test/pr) is blocked from merging.",
        ):
            with self.subTest(linked_control=linked_control):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "This section documents inert link controls.\n\n"
                                + linked_control
                            )
                        }
                    ),
                    [],
                )

        self.assertIn(
            expected,
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "Malformed definitions remain visible.\n\n"
                        "[This PR is blocked from merging]: broken destination"
                    )
                }
            ),
        )

        for block_boundary in (
            "[Historical example only.\n\nThis PR is blocked from merging.]",
            "[Historical example only.\r\n\r\nThis PR is blocked from merging.]",
            "[Historical example only.\r\rThis PR is blocked from merging.]",
            (
                "[Historical example only.\n### Current status\n"
                "The current revision must never merge.]"
            ),
            (
                "[Historical example only.\n1. This PR is blocked from "
                "merging.]"
            ),
            "[Historical example only.\n---\nThis PR is blocked from merging.]",
        ):
            with self.subTest(bracket_block_boundary=block_boundary):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": block_boundary}),
                )

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "Same-paragraph bracket control remains inert.\n\n"
                        "[Historical example only.\n"
                        "This PR is blocked from merging.]"
                    )
                }
            ),
            [],
        )

        for struck_control in (
            "This PR is ~~blocked~~ from merging.",
            "This PR must ~~not~~ merge.",
            "~~This PR is blocked from merging.~~",
            "~~This PR is forbidden to be merged.~~",
            "This PR ~~is forbidden to merge~~.",
            "~~This PR is **blocked** from merging.~~",
            "~~This PR is blocked\nfrom merging.~~",
            "~~Historical example only.\n2. This PR is blocked from merging.~~",
            "~~Historical example only.\n2) This PR is blocked from merging.~~",
            "~~Historical example only.\n10. This PR is blocked from merging.~~",
            "~~Historical example only.\n+\nThis PR is blocked from merging.~~",
            "~~Historical example only.\n*\nThis PR is blocked from merging.~~",
        ):
            with self.subTest(struck_control=struck_control):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": struck_control}),
                    [],
                )

        for line_ending in ("\n", "\r\n", "\r"):
            for cross_block_strike in (
                (
                    "~~Historical example only."
                    + line_ending * 2
                    + "This PR is blocked from merging.~~"
                ),
                (
                    "~~Historical example only."
                    + line_ending
                    + "### Separate heading"
                    + line_ending
                    + "This PR is forbidden to merge.~~"
                ),
                (
                    "~~Historical example only."
                    + line_ending
                    + "- Separate list item."
                    + line_ending
                    + "This PR is blocked from merging.~~"
                ),
                (
                    "~~Historical example only."
                    + line_ending
                    + "***"
                    + line_ending
                    + "This PR is forbidden to merge.~~"
                ),
                (
                    "~~Historical example only."
                    + line_ending
                    + "---"
                    + line_ending
                    + "This PR is forbidden to merge.~~"
                ),
            ):
                with self.subTest(
                    cross_block_strike=(
                        line_ending.encode().hex(),
                        cross_block_strike,
                    )
                ):
                    self.assertIn(
                        expected,
                        _validate_lifecycle_sections(
                            {"Scope": cross_block_strike}
                        ),
                    )

            lazy_blockquote_strike = (
                "~~Historical example only."
                + line_ending
                + "> Separate quoted block."
                + line_ending
                + "This PR is prohibited to be merged.~~"
            )
            with self.subTest(
                lazy_blockquote_strike=line_ending.encode().hex()
            ):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {"Scope": lazy_blockquote_strike}
                    ),
                    [],
                )

        multiline_emphasis_contradictions = (
            "This PR is **blocked\nfrom merging**.",
            "This PR is *never\nintended to be merged*.",
            "This PR is __blocked\nfrom being merged__.",
            "This PR _must not\nmerge_.",
        )
        for contradiction in multiline_emphasis_contradictions:
            with self.subTest(multiline_emphasis=contradiction):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": contradiction}),
                )

        multiline_emphasis_controls = (
            (
                'The checker rejects "This PR is **blocked\n'
                'from merging**."'
            ),
            "```text\nThis PR is **blocked\nfrom merging**.\n```",
            "> This PR is **blocked\n> from merging**.",
        )
        for control in multiline_emphasis_controls:
            with self.subTest(multiline_emphasis_inert=control):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "This section documents inert multiline "
                                "controls.\n\n"
                                + control
                            )
                        }
                    ),
                    [],
                )

    def test_lifecycle_fresh_review_discourse_boundaries_remain_operative(self) -> None:
        expected = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        fresh_findings = (
            (
                "The checker rejects statements saying this candidate will never "
                "be merged, while this pull request must not merge."
            ),
            (
                'The checker rejects the example "This branch must not merge", '
                "so this pull request must not merge."
            ),
            (
                "The checker rejects historical contradictions while this PR "
                "must not merge."
            ),
            (
                "The policy describes prior wording, whereas this PR must not "
                "merge."
            ),
        )
        for content in fresh_findings:
            with self.subTest(content=content):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": content}),
                )

        markers = (
            "while",
            "whereas",
            "so",
            "therefore",
            "thus",
            "consequently",
            "because",
            "although",
            "though",
            "but",
            "however",
            "yet",
            "then",
            "nevertheless",
            "nonetheless",
        )
        for marker in markers:
            with self.subTest(marker=marker):
                content = (
                    "The checker rejects historical contradictions "
                    f"{marker} this PR must not merge."
                )
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections({"Scope": content}),
                )

    def test_lifecycle_rejects_fresh_review_field_borrowing(self) -> None:
        missing_non_merge = (
            "lifecycle: non-merge branch must state its purpose",
            "lifecycle: non-merge branch must state its exact candidate or workflow SHA",
            "lifecycle: non-merge branch must state retained evidence",
            (
                "lifecycle: non-merge branch must state final disposition or "
                "close/deletion conditions"
            ),
        )
        quoted_record = (
            'The checker documents this example: "Purpose: preserve evidence. '
            f"Exact candidate or workflow SHA: {HEAD_SHA}. "
            "Retained evidence: logs remain attached. "
            'Final disposition: close after review."'
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "preserves evidence."
                ),
                "Non-merge record": quoted_record,
            }
        )
        for expected in missing_non_merge:
            self.assertIn(expected, errors)

        prefixed_record = (
            "This unrestricted prose says Purpose: preserve logs. "
            f"Exact candidate or workflow SHA: {HEAD_SHA}. "
            "Retained evidence: hosted logs. Final disposition: close later."
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This branch is not intended to merge and retains evidence."
                ),
                "Non-merge record": prefixed_record,
            }
        )
        for expected in missing_non_merge:
            self.assertIn(expected, errors)

        quoted_legacy = (
            'The policy documents the example "Legacy registration: #47 '
            "Original branch identity: validation/frozen-candidate. "
            "Original primary issue: #54. "
            f"Immutable candidate SHA: {HEAD_SHA}. "
            "Retained evidence: historical logs remain attached. "
            "Intended disposition: retain until migration closes. "
            'Reason: frozen identity remains."'
        )
        errors = _validate_lifecycle_sections(
            {
                "Primary issue": (
                    "Primary issue #47 registers this frozen legacy candidate."
                ),
                "Lifecycle exception": quoted_legacy,
            },
            head_ref="validation/frozen-candidate",
        )
        self.assertIn(
            "lifecycle: legacy exception must declare 'Legacy registration: #47'",
            errors,
        )

        explanatory_legacy = "\n".join(
            (
                "This explanation merely mentions Legacy registration: #47",
                "Original branch identity: validation/frozen-candidate.",
                "Original primary issue: #54.",
                f"Immutable candidate SHA: {HEAD_SHA}.",
                "Retained evidence: historical logs remain attached.",
                "Intended disposition: retain until migration closes.",
                "Reason: frozen identity remains.",
            )
        )
        errors = _validate_lifecycle_sections(
            {
                "Primary issue": (
                    "Primary issue #47 registers this frozen legacy candidate."
                ),
                "Lifecycle exception": explanatory_legacy,
            },
            head_ref="validation/frozen-candidate",
        )
        self.assertIn(
            "lifecycle: legacy exception must declare 'Legacy registration: #47'",
            errors,
        )

    def test_lifecycle_accepts_fresh_review_quoted_examples(self) -> None:
        merge_intention = (
            "This branch is intended to merge after review. "
            'The checker rejects the example "This branch is not intended '
            'to merge."'
        )
        self.assertEqual(
            _validate_lifecycle_sections({"Merge intention": merge_intention}),
            [],
        )

        descriptive_non_merge = (
            'The checker rejects "This branch is not intended to merge."',
            "The test covers “This PR is non-mergeable.”",
            'The policy forbids the wording "Must not merge this PR."',
            (
                "This scope records a documented parser failure.\n\n"
                "Documentation explains why "
                "`This candidate must remain unmerged` fails."
            ),
            (
                "The parser documents a fenced failure.\n\n"
                "```text\nThis branch is prohibited from being merged.\n```"
            ),
        )
        for content in descriptive_non_merge:
            with self.subTest(content=content):
                self.assertEqual(
                    _validate_lifecycle_sections({"Scope": content}),
                    [],
                )

        errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    'The checker rejects the example "Closes #46." for '
                    "non-merge branches."
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "preserves evidence."
                ),
                "Non-merge record": _non_merge_record(),
            }
        )
        self.assertEqual(errors, [])

        expected_contradiction = (
            "lifecycle: merge-intended branch must not make a "
            "candidate-specific non-merge contradiction"
        )
        self.assertIn(
            expected_contradiction,
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "The policy documents `non-mergeable`, whereas this "
                        "candidate is non-mergeable."
                    )
                }
            ),
        )

        errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    'The test covers "Closes #46"; this non-merge candidate '
                    "Closes #64."
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "preserves evidence."
                ),
                "Non-merge record": _non_merge_record(),
            }
        )
        self.assertIn(
            "lifecycle: non-merge branch must not use 'Closes #<issue>'",
            errors,
        )

    def test_lifecycle_rejects_duplicate_non_merge_fields(self) -> None:
        values = {
            "Purpose": "preserve validation evidence.",
            "Exact candidate or workflow SHA": f"{HEAD_SHA}.",
            "Retained evidence": "hosted logs remain available.",
            "Final disposition": "close after issue review.",
            "Close or deletion conditions": "close after issue review.",
        }
        required = (
            "Purpose",
            "Exact candidate or workflow SHA",
            "Retained evidence",
        )
        for label in (*required, *governance.FINAL_DISPOSITION_FIELD_LABELS):
            with self.subTest(label=label):
                record = [
                    f"{required_label}: {values[required_label]}"
                    for required_label in required
                ]
                disposition_label = (
                    label
                    if label in governance.FINAL_DISPOSITION_FIELD_LABELS
                    else "Final disposition"
                )
                record.append(f"{disposition_label}: {values[disposition_label]}")
                duplicate_value = values[label]
                record.append(f"{label}: {duplicate_value}")
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": "\n".join(record),
                    }
                )
                location = (
                    "disposition metadata"
                    if label in governance.FINAL_DISPOSITION_FIELD_LABELS
                    else "non-merge record"
                )
                self.assertIn(
                    (
                        f"lifecycle: {location} field '{label}' has 2 visible "
                        "canonical occurrences; expected at most one"
                    ),
                    errors,
                )

        for duplicate_sha in (HEAD_SHA, "b" * 40):
            with self.subTest(duplicate_sha=duplicate_sha):
                record = "\n".join(
                    (
                        "Purpose: preserve validation evidence.",
                        f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                        f"Exact candidate or workflow SHA: {duplicate_sha}.",
                        "Retained evidence: hosted logs remain available.",
                        "Final disposition: close after issue review.",
                    )
                )
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": record,
                    }
                )
                conflict_detail = (
                    " with conflicting values" if duplicate_sha != HEAD_SHA else ""
                )
                self.assertIn(
                    (
                        "lifecycle: non-merge record field "
                        "'Exact candidate or workflow SHA' has 2 visible canonical "
                        f"occurrences{conflict_detail}; expected at most one"
                    ),
                    errors,
                )

    def test_lifecycle_parser_collects_every_visible_canonical_occurrence(self) -> None:
        content = "\n".join(
            (
                "Purpose: first visible value.",
                "Purpose:",
                "> Purpose: blockquoted example.",
                "```text",
                "Purpose: fenced example.",
                "```",
                '"Purpose: quoted example."',
                "Purpose: third visible value.",
            )
        )
        reviewable = governance._reviewable_markdown_structure(content)
        fields = governance._parse_lifecycle_fields(
            reviewable,
            allowed_labels=governance.NON_MERGE_FIELD_LABELS,
        )
        self.assertEqual(
            governance._field_values(fields, "Purpose"),
            ["first visible value.", "", "third visible value."],
        )

    def test_closed_list_fence_keeps_later_contract_structure_visible(self) -> None:
        fenced_examples = (
            (
                "- ```text",
                "  Purpose: illustrative only.",
                "  ```",
            ),
            (
                "- Container item.",
                "  ```text",
                "  Purpose: illustrative only.",
                "  ```",
            ),
        )
        for fenced_example in fenced_examples:
            with self.subTest(fenced_example=fenced_example):
                event, contract, _comments = _fixture()
                body = _replace_required_section_content(
                    str(event["pull_request"]["body"]),
                    "Scope",
                    "\n".join(
                        (
                            "Container fenced examples remain inert.",
                            "",
                            *fenced_example,
                        )
                    ),
                )
                _rebound, comments = _rebind_modified_body(event, contract, body)
                self.assertEqual(_validate(event, comments), [])

    def test_lifecycle_rejects_multiple_canonical_labels_on_one_line(self) -> None:
        attacks = (
            (
                "duplicate purpose identical",
                "Purpose: preserve evidence. Purpose: preserve evidence.",
            ),
            (
                "duplicate purpose conflicting",
                "Purpose: preserve evidence. Purpose: destroy evidence.",
            ),
            (
                "duplicate sha identical",
                (
                    f"Exact candidate or workflow SHA: {HEAD_SHA}. "
                    f"Exact candidate or workflow SHA: {HEAD_SHA}."
                ),
            ),
            (
                "duplicate sha conflicting",
                (
                    f"Exact candidate or workflow SHA: {HEAD_SHA}. "
                    f"Exact candidate or workflow SHA: {'b' * 40}."
                ),
            ),
            (
                "different labels",
                (
                    "Purpose: preserve evidence. "
                    "Retained evidence: hosted logs remain available."
                ),
            ),
            (
                "disallowed first label",
                (
                    "Legacy registration: #47. "
                    "Purpose: conflicting purpose."
                ),
            ),
            (
                "disallowed first sha label",
                (
                    f"Immutable candidate SHA: {'b' * 40}. "
                    f"Exact candidate or workflow SHA: {'b' * 40}."
                ),
            ),
            (
                "escaped visible colon",
                "Purpose: preserve evidence. Purpose\\: conflicting purpose.",
            ),
            (
                "entity visible colon",
                "Purpose: preserve evidence. Purpose&#58; conflicting purpose.",
            ),
            (
                "named entity visible colon",
                "Purpose: preserve evidence. Purpose&colon; conflicting purpose.",
            ),
            (
                "encoded label letter",
                "Purpose: preserve evidence. Purpos&#101;: conflicting purpose.",
            ),
            (
                "encoded first decimal colon",
                "Reason&#58; inert. Purpose: conflicting purpose.",
            ),
            (
                "encoded first hexadecimal colon",
                "Reason&#x3a; inert. Purpose: conflicting purpose.",
            ),
            (
                "encoded first named colon",
                "Reason&colon; inert. Purpose: conflicting purpose.",
            ),
            (
                "escaped first colon",
                "Reason\\: inert. Purpose: conflicting purpose.",
            ),
            (
                "emphasis inside visible label",
                "Purpose: preserve evidence. Pur**pose:** conflicting purpose.",
            ),
            (
                "comment inside visible label",
                (
                    "Purpose: preserve evidence. "
                    "Pur<!-- hidden -->pose: conflicting purpose."
                ),
            ),
            (
                "single underscore visible label",
                "Purpose: preserve evidence. _Purpose_: conflicting purpose.",
            ),
            (
                "reference link visible label",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][duplicate]: conflicting purpose.\n\n"
                    "[duplicate]: https://example.invalid"
                ),
            ),
            (
                "shortcut reference visible label",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose]: conflicting purpose.\n\n"
                    "[Purpose]: https://example.invalid"
                ),
            ),
            (
                "multiline reference visible label",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][duplicate]: conflicting purpose.\n\n"
                    "[duplicate]:\n      https://example.invalid"
                ),
            ),
            (
                "multiline shortcut visible label",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose]: conflicting purpose.\n\n"
                    "[Purpose]:\n\thttps://example.invalid"
                ),
            ),
            (
                "entity shortcut visible label",
                (
                    "Purpose: preserve evidence. "
                    "[Purpos&#101;]: conflicting purpose.\n\n"
                    "[Purpos&#101;]: https://example.invalid"
                ),
            ),
            (
                "entity collapsed visible label",
                (
                    "Purpose: preserve evidence. "
                    "[Purpos&#101;][]: conflicting purpose.\n\n"
                    "[Purpos&#101;]: https://example.invalid"
                ),
            ),
        )
        for name, attack in attacks:
            with self.subTest(name=name):
                record = "\n".join(
                    (
                        attack,
                        f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                        "Retained evidence: hosted logs remain available.",
                        "Final disposition: close after issue review.",
                    )
                )
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        cross_section_attacks = (
            (
                "shortcut",
                "Purpose: preserve evidence. [Purpose]: conflicting purpose.",
            ),
            (
                "collapsed case-folded",
                "Purpose: preserve evidence. [Purpose][]: conflicting purpose.",
            ),
            (
                "full multiline case-folded",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][DuP]: conflicting purpose."
                ),
            ),
            (
                "blockquote definition",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][blocked]: conflicting purpose."
                ),
            ),
            (
                "list definition",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][listed]: conflicting purpose."
                ),
            ),
            (
                "blockquote three-line definition",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][threequote]: conflicting purpose."
                ),
            ),
            (
                "list three-line definition",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][threelist]: conflicting purpose."
                ),
            ),
            (
                "mixed-container three-line definition",
                (
                    "Purpose: preserve evidence. "
                    "[Purpose][mixed]: conflicting purpose."
                ),
            ),
        )
        definitions = (
            "Reference definitions below are document-wide.\n\n"
            "### Nested definitions\n"
            "[purpose]: https://example.invalid/purpose\n"
            "[dup]:\n      https://example.invalid/duplicate\n"
            "> [blocked]: https://example.invalid/blocked\n"
            "- [listed]: https://example.invalid/listed\n"
            "> [\n> threequote\n> ]: https://example.invalid/threequote\n"
            "- [\n  threelist\n  ]: https://example.invalid/threelist\n"
            "> - [\n>   mixed\n>   ]: https://example.invalid/mixed"
        )
        for name, attack in cross_section_attacks:
            with self.subTest(cross_section=name):
                record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    attack,
                )
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": definitions,
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        multiline_label_record = _non_merge_record().replace(
            f"Exact candidate or workflow SHA: {HEAD_SHA}.",
            (
                f"Exact candidate or workflow SHA: {HEAD_SHA}. "
                "[Exact candidate or workflow SHA]: conflicting value."
            ),
        )
        multiline_label_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "A multiline document-wide definition follows.\n\n"
                    "[Exact candidate\n"
                    "or workflow\n"
                    "SHA]: https://example.invalid/sha"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": multiline_label_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in multiline_label_errors
            ),
            multiline_label_errors,
        )

        for code_definition in (
            ">\t\t[deep]: https://example.invalid",
            "-\t\t[deep]: https://example.invalid",
            "> \t[deep]: https://example.invalid",
        ):
            with self.subTest(code_definition=code_definition):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve literal unresolved reference "
                        "[Purpose][deep]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Indented container code remains inert.\n\n"
                                + code_definition
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        tab_padding_record = _non_merge_record().replace(
            "Purpose: preserve validation evidence.",
            "Purpose: preserve evidence. [Purpose]: conflicting purpose.",
        )
        tab_padding_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "Reference definitions below are document-wide.\n\n"
                    "-\t  ```text\n"
                    "    [Purpose]: https://example.invalid"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": tab_padding_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in tab_padding_errors
            ),
            tab_padding_errors,
        )

        for malformed_definition in (
            "[Purpose]: not a destination",
            "[Purpose]: <> unexpected tail",
            "[Purpose]: https://example.invalid unexpected tail",
            '[Purpose]: https://example.invalid "unterminated title',
            "[Purpose]: foo\\ bar",
            "[Purpose]: foo\\\tbar",
            "[Purpose]: foo\x7fbar",
            '[Purpose]: /url "title"\vtrailing',
            '[Purpose]: /url "title"\ftrailing',
            '[Purpose]: /url "title"\u0085trailing',
            '[Purpose]: /url "title"\u2028trailing',
            '[Purpose]: /url "title"\u2029trailing',
        ):
            with self.subTest(malformed_definition=malformed_definition):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve unresolved reference "
                        "[Purpose]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Malformed definitions remain inert.\n\n"
                                + malformed_definition
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        trailing_text_record = _non_merge_record().replace(
            "Purpose: preserve validation evidence.",
            (
                "Purpose: preserve unresolved reference "
                "[Purpose][deep]: illustrative only."
            ),
        )
        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "An invalid same-line tail cannot borrow a destination.\n\n"
                        "[deep]: invalid trailing text\n"
                        "https://example.invalid"
                    ),
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": trailing_text_record,
                }
            ),
            [],
        )

        escaped_destination_record = _non_merge_record().replace(
            "Purpose: preserve validation evidence.",
            "Purpose: preserve evidence. [Purpose]: conflicting purpose.",
        )
        escaped_destination_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "Escaped punctuation is valid in a destination.\n\n"
                    "[Purpose]: foo\\(bar\\)"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": escaped_destination_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in escaped_destination_errors
            ),
            escaped_destination_errors,
        )

        angle_tab_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "Angle destinations may contain tabs.\n\n"
                    "[Purpose]: <./foo\tbar>"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": escaped_destination_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in angle_tab_errors
            ),
            angle_tab_errors,
        )

        non_ascii_destination_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "Only ASCII controls are excluded from bare destinations.\n\n"
                    "[Purpose]: foo\u0080bar"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": escaped_destination_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in non_ascii_destination_errors
            ),
            non_ascii_destination_errors,
        )

        for non_alias_label in (
            "Purpose\u00a0",
            "Purpose\u2003",
            "Purpose\u0085",
            "Purpose\u2028",
            "Purpose\u2029",
        ):
            with self.subTest(non_alias_label=non_alias_label):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve unresolved reference "
                        "[Purpose]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Unicode separators remain label characters.\n\n"
                                f"[{non_alias_label}]: /url"
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for multiline_non_alias_definition in (
            "[Purpose\n\u00a0\n]: /url",
            "[Purpose\n\u2003\n]: /url",
        ):
            with self.subTest(
                multiline_non_alias_definition=multiline_non_alias_definition
            ):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve unresolved reference "
                        "[Purpose]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Unicode label characters remain distinct.\n\n"
                                + multiline_non_alias_definition
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for ascii_alias_definition in (
            "[ Purpose ]: /url",
            "[\tPurpose\t]: /url",
            "[Purpose\r]: /url",
            "[Purpose\n]: /url",
            "[Purpose\r\n]: /url",
        ):
            with self.subTest(
                ascii_alias_definition=ascii_alias_definition
            ):
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "CommonMark label whitespace collapses.\n\n"
                            + ascii_alias_definition
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_destination_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        oversized_label = " " * 500 + "Purpose" + " " * 500
        unresolved_record = _non_merge_record().replace(
            "Purpose: preserve validation evidence.",
            (
                "Purpose: preserve unresolved reference "
                "[Purpose]: illustrative only."
            ),
        )
        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "Oversized reference labels remain invalid.\n\n"
                        f"[{oversized_label}]: /url"
                    ),
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": unresolved_record,
                }
            ),
            [],
        )

        maximum_label = " " * 496 + "Purpose" + " " * 496
        maximum_label_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "A 999-character reference label remains valid.\n\n"
                    f"[{maximum_label}]: /url"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": escaped_destination_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in maximum_label_errors
            ),
            maximum_label_errors,
        )

        for line_ending in ("\n", "\r\n", "\r"):
            with self.subTest(
                multiline_label_boundary=line_ending.encode().hex()
            ):
                oversized_multiline_label = (
                    "[Purpose" + line_ending + " " * 992 + "]: /url"
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Oversized multiline labels remain invalid."
                                + line_ending * 2
                                + oversized_multiline_label
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

                maximum_multiline_label = (
                    "[Purpose" + line_ending + " " * 991 + "]: /url"
                )
                maximum_multiline_errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "A 999-character multiline label remains valid."
                            + line_ending * 2
                            + maximum_multiline_label
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_destination_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in maximum_multiline_errors
                    ),
                    maximum_multiline_errors,
                )

        for line_ending in ("\n", "\r\n", "\r"):
            for whitespace in (" ", "\t"):
                with self.subTest(
                    whitespace_only_multiline_label=(
                        line_ending.encode().hex(),
                        whitespace.encode().hex(),
                    )
                ):
                    self.assertEqual(
                        _validate_lifecycle_sections(
                            {
                                "Scope": (
                                    "Whitespace-only labels remain invalid."
                                    + line_ending * 2
                                    + "["
                                    + line_ending
                                    + whitespace
                                    + "]: /url"
                                    + line_ending
                                    + "[Purpose]: /url"
                                ),
                                "Merge intention": (
                                    "This validation branch is not intended "
                                    "to merge and retains test evidence."
                                ),
                                "Non-merge record": unresolved_record,
                            }
                        ),
                        [],
                    )

        valid_bracket_definitions = (
            r"[bad\[label]: /url",
            r"[bad\\\[label]: /url",
            r"[bad\]label]: /url",
            r"[bad\\\]label]: /url",
        )
        for valid_bracket_definition in valid_bracket_definitions:
            with self.subTest(
                valid_bracket_definition=valid_bracket_definition
            ):
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "Escaped brackets remain valid in labels.\n\n"
                            + valid_bracket_definition
                            + "\n[Purpose]: /url"
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_destination_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        for escaped_reference_label in (r"x\[y", r"x\]y"):
            with self.subTest(
                escaped_full_reference_label=escaped_reference_label
            ):
                escaped_reference_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve evidence. "
                        f"[Purpose][{escaped_reference_label}]: "
                        "conflicting purpose."
                    ),
                )
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "Escaped labels resolve in full references.\n\n"
                            f"[{escaped_reference_label}]: /url"
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_reference_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        entity_reference_record = _non_merge_record().replace(
            "Purpose: preserve validation evidence.",
            (
                "Purpose: preserve evidence. "
                "[Purpose][r&#91;ef]: conflicting purpose."
            ),
        )
        entity_reference_errors = _validate_lifecycle_sections(
            {
                "Scope": (
                    "Entity brackets normalize in valid reference labels.\n\n"
                    "[r&#91;ef]: /url"
                ),
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": entity_reference_record,
            }
        )
        self.assertTrue(
            any(
                "expected exactly one canonical field per physical line"
                in error
                for error in entity_reference_errors
            ),
            entity_reference_errors,
        )

        malformed_reference_record = _non_merge_record().replace(
            "Purpose: preserve validation evidence.",
            (
                "Purpose: preserve evidence. "
                "[Purpose][r[ef]: illustrative only."
            ),
        )
        malformed_reference_record = (
            "This record preserves all required evidence.\n"
            + malformed_reference_record
        )
        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Scope": (
                        "Malformed raw brackets remain literal.\n\n"
                        "[r&#91;ef]: /url"
                    ),
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": malformed_reference_record,
                }
            ),
            [],
        )

        invalid_bracket_definitions = (
            "[bad[label]: /url",
            r"[bad\\[label]: /url",
            r"[bad\\]label]: /url",
        )
        for invalid_bracket_definition in invalid_bracket_definitions:
            with self.subTest(
                invalid_bracket_definition=invalid_bracket_definition
            ):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Unescaped brackets keep the paragraph open."
                                "\n\n"
                                + invalid_bracket_definition
                                + "\n[Purpose]: /url"
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for line_ending in ("\n", "\r\n", "\r"):
            for valid_multiline_definition in (
                r"[bad\]" + line_ending + "label]: /url",
                r"[bad\[" + line_ending + "label]: /url",
            ):
                with self.subTest(
                    valid_multiline_bracket_definition=(
                        line_ending.encode().hex(),
                        valid_multiline_definition,
                    )
                ):
                    errors = _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Escaped multiline brackets remain valid."
                                + line_ending * 2
                                + valid_multiline_definition
                                + line_ending
                                + "[Purpose]: /url"
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": escaped_destination_record,
                        }
                    )
                    self.assertTrue(
                        any(
                            "expected exactly one canonical field per physical line"
                            in error
                            for error in errors
                        ),
                        errors,
                    )

            invalid_multiline_definition = (
                "[bad" + line_ending + "[label]: /url"
            )
            with self.subTest(
                invalid_multiline_bracket_definition=(
                    line_ending.encode().hex(),
                    invalid_multiline_definition,
                )
            ):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Unescaped multiline brackets keep paragraphs "
                                "open."
                                + line_ending * 2
                                + invalid_multiline_definition
                                + line_ending
                                + "[Purpose]: /url"
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for interrupting_definition in (
            (
                "Ordinary paragraph remains visible.\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "A blockquote control follows.\n\n"
                "> Ordinary blockquote paragraph remains visible.\n"
                "> [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "0. [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "2. [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "003. [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "14. [Purpose]: https://example.invalid"
            ),
            (
                "A blockquote control follows.\n\n"
                "> Ordinary blockquote paragraph remains visible.\n"
                "> 2. [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "    indented continuation text\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "A blockquote control follows.\n\n"
                "> Ordinary blockquote paragraph remains visible.\n"
                ">     indented continuation text\n"
                "> [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "*\t\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "+   \n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph remains visible.\n"
                "2.   \n"
                "[Purpose]: https://example.invalid"
            ),
        ):
            with self.subTest(
                interrupting_definition=interrupting_definition
            ):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve unresolved reference "
                        "[Purpose]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": interrupting_definition,
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for block_boundary_definition in (
            (
                "Ordinary paragraph ends before a blank line.\n\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "### Reference definitions\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "Reference definitions\n"
                "=====================\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "Reference definitions\n"
                "---------------------\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "Reference definitions\n"
                "-\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "Reference definitions\n"
                "--\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "- Ordinary first list item.\n"
                "- [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph may be interrupted by one.\n"
                "1. [Purpose]: https://example.invalid"
            ),
            (
                "Ordinary paragraph may be interrupted by one.\n"
                "1) [Purpose]: https://example.invalid"
            ),
            (
                "An indented code block follows a blank.\n\n"
                "    literal code\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "An empty bullet item follows.\n\n"
                "-\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "An empty plus item follows.\n\n"
                "+\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "An empty star item follows.\n\n"
                "*\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "An empty ordered item follows.\n\n"
                "1.\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "An empty parenthesized item follows.\n\n"
                "1)\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "A padded empty bullet item follows.\n\n"
                "*\t\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "A padded empty ordered item follows.\n\n"
                "2.   \n"
                "[Purpose]: https://example.invalid"
            ),
        ):
            with self.subTest(
                block_boundary_definition=block_boundary_definition
            ):
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": block_boundary_definition,
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_destination_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        for standalone_non_boundary in (
            "--\n[Purpose]: https://example.invalid",
            "=\n[Purpose]: https://example.invalid",
        ):
            with self.subTest(
                standalone_non_boundary=standalone_non_boundary
            ):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve unresolved reference "
                        "[Purpose]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Standalone paragraph text follows.\n\n"
                                + standalone_non_boundary
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for multiline_title_definition in (
            (
                '[Purpose]: https://example.invalid "multi\n'
                'line title"'
            ),
            (
                "[Purpose]:\n"
                '  https://example.invalid "multi\n'
                '  line title"'
            ),
            '[Purpose]: /url "multi\rline title"',
            '[Purpose]: /url "multi\r\nline title"',
        ):
            with self.subTest(
                multiline_title_definition=multiline_title_definition
            ):
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "Multiline titles keep definitions active.\n\n"
                            + multiline_title_definition
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_destination_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        for tab_title_definition in (
            '[Purpose]: /url "tab\ttitle"',
            "[Purpose]: /url 'tab\ttitle'",
            "[Purpose]: /url (tab\ttitle)",
            '[Purpose]: /url "a\u0001b"',
            "[Purpose]: /url 'a\u0008b'",
            "[Purpose]: /url (a\u001fb)",
            '[Purpose]: /url "a\x7fb"',
            '[Purpose]: /url "a\u0080b"',
        ):
            with self.subTest(tab_title_definition=tab_title_definition):
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "Reference titles may contain tabs.\n\n"
                            + tab_title_definition
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge "
                            "and retains test evidence."
                        ),
                        "Non-merge record": escaped_destination_record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        for interrupted_title_definition in (
            (
                '[Purpose]: https://example.invalid "multi\n\n'
                'line title"'
            ),
            (
                '[Purpose]: https://example.invalid "multi\n'
                'line title" trailing prose'
            ),
            '[Purpose]: /url "title"\u00a0',
            "[Purpose]: /url 'title'\u2003",
            "[Purpose]: /url (title)\u00a0",
        ):
            with self.subTest(
                interrupted_title_definition=interrupted_title_definition
            ):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve unresolved reference "
                        "[Purpose]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "Invalid multiline titles remain inert.\n\n"
                                + interrupted_title_definition
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        for container_fence in (
            (
                "> ```text\n"
                "> unclosed blockquote fence\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "- ```text\n"
                "  unclosed list fence\n\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "> - ```text\n"
                ">   unclosed nested fence\n\n"
                "[Purpose]: https://example.invalid"
            ),
            (
                "- ```text\n"
                "  unclosed bullet fence\n"
                " [Purpose]: https://example.invalid"
            ),
            (
                "1. ```text\n"
                "   unclosed ordered fence\n"
                "  [Purpose]: https://example.invalid"
            ),
            (
                "- ```text\n"
                "  unclosed first item fence\n"
                "- [Purpose]: https://example.invalid"
            ),
            (
                "1. ```text\n"
                "   unclosed first ordered item fence\n"
                "2. [Purpose]: https://example.invalid"
            ),
            (
                "> - ```text\n"
                ">   unclosed nested item fence\n"
                "> - [Purpose]: https://example.invalid"
            ),
        ):
            with self.subTest(container_fence=container_fence):
                record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve evidence. "
                        "[Purpose]: conflicting purpose."
                    ),
                )
                errors = _validate_lifecycle_sections(
                    {
                        "Scope": (
                            "Container fences end with their containers.\n\n"
                            + container_fence
                        ),
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": record,
                    }
                )
                self.assertTrue(
                    any(
                        "expected exactly one canonical field per physical line"
                        in error
                        for error in errors
                    ),
                    errors,
                )

        for fenced_control in (
            (
                "- ```text\n"
                "  literal code\n"
                "  - [deep]: https://example.invalid"
            ),
            (
                "- ```text\n"
                "  literal code\n\n"
                "  [deep]: https://example.invalid"
            ),
            (
                "1. ```text\n"
                "   literal ordered code\n"
                "   - [deep]: https://example.invalid"
            ),
            (
                "1. ```text\n"
                "   literal ordered code\n\n"
                "   [deep]: https://example.invalid"
            ),
            (
                "- - ```text\n"
                "    literal nested list code\n\n"
                "    [deep]: https://example.invalid"
            ),
            (
                "> - ```text\n"
                ">   literal blockquote list code\n"
                ">\n"
                ">   [deep]: https://example.invalid"
            ),
            (
                "> - - ```text\n"
                ">     literal deeply nested code\n"
                ">\n"
                ">     [deep]: https://example.invalid"
            ),
            (
                "> - ```text\n"
                ">   literal nested code\n"
                ">   - [deep]: https://example.invalid"
            ),
        ):
            with self.subTest(fenced_control=fenced_control):
                unresolved_record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    (
                        "Purpose: preserve literal unresolved reference "
                        "[Purpose][deep]: illustrative only."
                    ),
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Scope": (
                                "List-scoped fenced code remains inert.\n\n"
                                + fenced_control
                            ),
                            "Merge intention": (
                                "This validation branch is not intended to "
                                "merge and retains test evidence."
                            ),
                            "Non-merge record": unresolved_record,
                        }
                    ),
                    [],
                )

        safe_values = (
            'Purpose: preserve the quoted label "Purpose: illustrative only."',
            "Purpose: preserve the coded label `Purpose: illustrative only.`",
            (
                "Purpose: preserve the escaped entity label "
                "Purpose\\&colon; illustrative only."
            ),
            (
                "Purpose: preserve the unterminated entity label "
                "Purpose&#58 illustrative only."
            ),
            (
                "Purpose: preserve &quot;Purpose: illustrative only.&quot;"
            ),
            (
                "Purpose: preserve literal escaped emphasis "
                "\\_Purpose\\_: illustrative only."
            ),
            (
                "Purpose: preserve unresolved reference "
                "[Purpose][missing]: illustrative only."
            ),
        )
        for purpose in safe_values:
            with self.subTest(purpose=purpose):
                record = _non_merge_record().replace(
                    "Purpose: preserve validation evidence.",
                    purpose,
                )
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {
                            "Merge intention": (
                                "This validation branch is not intended to merge "
                                "and retains test evidence."
                            ),
                            "Non-merge record": record,
                        }
                    ),
                    [],
                )

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": _non_merge_record(),
                }
            ),
            [],
        )

        invisible_record = "\n".join(
            (
                "Purpose: <!-- hidden -->",
                f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                "Retained evidence: <!-- hidden -->",
                "Final disposition: <!-- hidden -->",
            )
        )
        invisible_errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": invisible_record,
            }
        )
        self.assertIn(
            "lifecycle: non-merge branch must state its purpose",
            invisible_errors,
        )
        self.assertIn(
            "lifecycle: non-merge branch must state retained evidence",
            invisible_errors,
        )
        self.assertIn(
            (
                "lifecycle: non-merge branch must state final disposition or "
                "close/deletion conditions"
            ),
            invisible_errors,
        )

        for invisible in (
            "&ZeroWidthSpace;",
            "&#8203;",
            "&#x200B;",
            "&#xfeff;",
            "&#8288;",
            "&#xfe0f;",
            "&#x034f;",
            "&#x180b;",
            "&#xE0100;",
            "\u200b",
            "\ufe0f",
            "\u034f",
            "\u180b",
            "\U000E0100",
        ):
            with self.subTest(invisible=invisible):
                zero_width_record = "\n".join(
                    (
                        f"Purpose: {invisible}",
                        f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                        f"Retained evidence: {invisible}",
                        f"Final disposition: {invisible}",
                    )
                )
                zero_width_errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": zero_width_record,
                    }
                )
                self.assertIn(
                    "lifecycle: non-merge branch must state its purpose",
                    zero_width_errors,
                )
                self.assertIn(
                    "lifecycle: non-merge branch must state retained evidence",
                    zero_width_errors,
                )
                self.assertIn(
                    (
                        "lifecycle: non-merge branch must state final "
                        "disposition or close/deletion conditions"
                    ),
                    zero_width_errors,
                )

    def test_lifecycle_metadata_comes_only_from_direct_section_body(self) -> None:
        missing_non_merge = (
            "lifecycle: non-merge branch must state its purpose",
            "lifecycle: non-merge branch must state its exact candidate or workflow SHA",
            "lifecycle: non-merge branch must state retained evidence",
            (
                "lifecycle: non-merge branch must state final disposition or "
                "close/deletion conditions"
            ),
        )
        nested_only = f"### Example only, not metadata\n{_non_merge_record()}"
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and retains "
                    "test evidence."
                ),
                "Non-merge record": nested_only,
            }
        )
        for expected in missing_non_merge:
            self.assertIn(expected, errors)

        for unicode_separator in ("\u00a0", "\u2003"):
            with self.subTest(unicode_separator=unicode_separator):
                record = (
                    "Purpose: actual retained evidence.\n\n"
                    "> Quoted example begins.\n"
                    f"{unicode_separator}\n"
                    "Purpose: example only."
                )
                operative = governance._operative_lifecycle_prose(
                    record,
                    mask_list_items=True,
                )
                fields = governance._parse_lifecycle_fields(
                    operative,
                    allowed_labels=governance.NON_MERGE_FIELD_LABELS,
                )
                self.assertEqual(
                    governance._field_values(fields, "Purpose"),
                    ["actual retained evidence."],
                )

        cr_nested_only = (
            "Direct section prose contains no canonical metadata.\r"
            "### Nested examples\r"
            + _non_merge_record().replace("\n", "\r")
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": cr_nested_only,
            }
        )
        for expected in missing_non_merge:
            self.assertIn(expected, errors)

        lazy_blockquote_record = (
            "> Example-only metadata follows:\n"
            + _non_merge_record().replace("\n\n", "\n")
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and retains "
                    "test evidence."
                ),
                "Non-merge record": lazy_blockquote_record,
            }
        )
        for expected in missing_non_merge:
            self.assertIn(expected, errors)

        for marker in ("-", "+", "*", "1.", "1)"):
            with self.subTest(marker=marker):
                lazy_list_record = (
                    f"{marker} Example-only metadata follows:\n"
                    + _non_merge_record().replace("\n\n", "\n")
                )
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": lazy_list_record,
                    }
                )
                for expected in missing_non_merge:
                    self.assertIn(expected, errors)

        partial_direct = "\n".join(
            (
                "Purpose: preserve validation evidence.",
                "### Remaining record",
                f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                "Retained evidence: hosted logs remain available.",
                "Final disposition: close after issue review.",
            )
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and retains "
                    "test evidence."
                ),
                "Non-merge record": partial_direct,
            }
        )
        self.assertNotIn(missing_non_merge[0], errors)
        for expected in missing_non_merge[1:]:
            self.assertIn(expected, errors)

        valid_then_nested = "\n\n".join(
            (
                (
                    "This prose explains the direct record before its canonical "
                    "metadata."
                ),
                _non_merge_record(),
                (
                    "### Example only\n"
                    "Purpose: conflicting nested purpose.\n"
                    f"Exact candidate or workflow SHA: {'b' * 40}.\n"
                    "Retained evidence: nested example only.\n"
                    "Final disposition: delete the example."
                ),
            )
        )
        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": valid_then_nested,
                }
            ),
            [],
        )

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": (
                        _non_merge_record().replace("\n\n", "\n")
                        + "\n***\nNested heading\n---\n"
                        + "Purpose: nested example remains inert."
                    ),
                }
            ),
            [],
        )

        for depth, heading in (
            (3, "Differently named details"),
            (4, "Evidence notes"),
            (5, "Policy controls"),
            (6, "Final example"),
        ):
            with self.subTest(depth=depth):
                content = f"{'#' * depth} {heading}\n{_non_merge_record()}"
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": content,
                    }
                )
                for expected in missing_non_merge:
                    self.assertIn(expected, errors)

        for heading in (
            "# Higher-level boundary",
            "Example only\n------------",
            "Example only\n============",
            "`Example only, not metadata`\n---",
        ):
            with self.subTest(heading=heading):
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": f"{heading}\n{_non_merge_record()}",
                    }
                )
                for expected in missing_non_merge:
                    self.assertIn(expected, errors)

        multiline_setext_record = "\n".join(
            (
                "Purpose: preserve validation evidence.",
                f"Exact candidate or workflow SHA: {HEAD_SHA}.",
                "Retained evidence: hosted logs remain available.",
                "Final disposition: close after issue review.",
                "Nested heading tail",
                "---",
            )
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and retains "
                    "test evidence."
                ),
                "Non-merge record": multiline_setext_record,
            }
        )
        for expected in missing_non_merge:
            self.assertIn(expected, errors)

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": (
                        _non_merge_record()
                        + "\n\n`Example only, not metadata`\n---\n"
                        + "Purpose: nested example remains inert."
                    ),
                }
            ),
            [],
        )

        legacy_record = "\n".join(
            (
                "Legacy registration: #47.",
                "Original branch identity: validation/frozen-candidate.",
                "Original primary issue: #54.",
                f"Immutable candidate SHA: {HEAD_SHA}.",
                "Retained evidence: historical logs remain attached.",
                "Intended disposition: retain until migration closes.",
                "Reason: frozen identity remains.",
            )
        )
        for invisible in (
            "&ZeroWidthSpace;",
            "&#8203;",
            "&#x200B;",
            "&#xfeff;",
            "&#8288;",
            "&#xfe0f;",
            "&#x034f;",
            "&#x180b;",
            "&#xE0100;",
            "\u200b",
            "\ufe0f",
            "\u034f",
            "\u180b",
            "\U000E0100",
        ):
            with self.subTest(legacy_invisible=invisible):
                invisible_legacy_record = (
                    legacy_record.replace(
                        "Retained evidence: historical logs remain attached.",
                        f"Retained evidence: {invisible}",
                    )
                    .replace(
                        "Intended disposition: retain until migration closes.",
                        f"Intended disposition: {invisible}",
                    )
                    .replace(
                        "Reason: frozen identity remains.",
                        f"Reason: {invisible}",
                    )
                )
                invisible_legacy_errors = _validate_lifecycle_sections(
                    {
                        "Primary issue": (
                            "Primary issue #47 registers this frozen legacy "
                            "candidate."
                        ),
                        "Lifecycle exception": invisible_legacy_record,
                    },
                    head_ref="validation/frozen-candidate",
                )
                self.assertIn(
                    "lifecycle: legacy exception must state a reason",
                    invisible_legacy_errors,
                )
                self.assertIn(
                    "lifecycle: legacy exception must state retained evidence",
                    invisible_legacy_errors,
                )
                self.assertIn(
                    (
                        "lifecycle: legacy exception must state intended "
                        "disposition"
                    ),
                    invisible_legacy_errors,
                )
        nested_legacy_errors = _validate_lifecycle_sections(
            {
                "Primary issue": (
                    "Primary issue #47 registers this frozen legacy candidate."
                ),
                "Lifecycle exception": (
                    "### Historical details\n" + legacy_record
                ),
            },
            head_ref="validation/frozen-candidate",
        )
        self.assertIn(
            "lifecycle: legacy exception must declare 'Legacy registration: #47'",
            nested_legacy_errors,
        )

        lazy_legacy_errors = _validate_lifecycle_sections(
            {
                "Primary issue": (
                    "Primary issue #47 registers this frozen legacy candidate."
                ),
                "Lifecycle exception": (
                    "> Example-only legacy metadata follows:\n" + legacy_record
                ),
            },
            head_ref="validation/frozen-candidate",
        )
        self.assertIn(
            "lifecycle: legacy exception must declare 'Legacy registration: #47'",
            lazy_legacy_errors,
        )

        for marker in ("-", "+", "*", "1.", "1)"):
            with self.subTest(legacy_marker=marker):
                lazy_legacy_errors = _validate_lifecycle_sections(
                    {
                        "Primary issue": (
                            "Primary issue #47 registers this frozen legacy "
                            "candidate."
                        ),
                        "Lifecycle exception": (
                            f"{marker} Example-only legacy metadata follows:\n"
                            + legacy_record
                        ),
                    },
                    head_ref="validation/frozen-candidate",
                )
                self.assertIn(
                    (
                        "lifecycle: legacy exception must declare "
                        "'Legacy registration: #47'"
                    ),
                    lazy_legacy_errors,
                )

        multiline_legacy_errors = _validate_lifecycle_sections(
            {
                "Primary issue": (
                    "Primary issue #47 registers this frozen legacy candidate."
                ),
                "Lifecycle exception": (
                    legacy_record
                    + "\nNested heading tail\n---"
                ),
            },
            head_ref="validation/frozen-candidate",
        )
        self.assertIn(
            "lifecycle: legacy exception must declare 'Legacy registration: #47'",
            multiline_legacy_errors,
        )

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Primary issue": (
                        "Primary issue #47 registers this frozen legacy candidate."
                    ),
                    "Lifecycle exception": (
                        legacy_record
                        + "\n\n#### Example only\n"
                        + legacy_record.replace(
                            "Reason: frozen identity remains.",
                            "Reason: nested duplicate remains inert.",
                        )
                    ),
                },
                head_ref="validation/frozen-candidate",
            ),
            [],
        )

        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Primary issue": (
                        "Primary issue #47 registers this frozen legacy candidate."
                    ),
                    "Lifecycle exception": (
                        legacy_record
                        + "\n___\nNested heading\n---\n"
                        + "Reason: nested duplicate remains inert."
                    ),
                },
                head_ref="validation/frozen-candidate",
            ),
            [],
        )

    def test_lifecycle_rejects_duplicate_legacy_fields(self) -> None:
        values = {
            "Legacy registration": "#47.",
            "Original branch identity": "validation/frozen-candidate.",
            "Original primary issue": "#54.",
            "Immutable candidate SHA": f"{HEAD_SHA}.",
            "Retained evidence": "historical logs remain attached.",
            "Intended disposition": "retain until migration closes.",
            "Reason": "frozen identity remains.",
        }
        for label in governance.LEGACY_FIELD_LABELS:
            with self.subTest(label=label):
                exception = [
                    f"{field_label}: {field_value}"
                    for field_label, field_value in values.items()
                ]
                exception.append(f"{label}: {values[label]}")
                errors = _validate_lifecycle_sections(
                    {
                        "Primary issue": (
                            "Primary issue #47 registers this frozen legacy candidate."
                        ),
                        "Lifecycle exception": "\n".join(exception),
                    },
                    head_ref="validation/frozen-candidate",
                )
                self.assertIn(
                    (
                        f"lifecycle: legacy exception field '{label}' has 2 visible "
                        "canonical occurrences; expected at most one"
                    ),
                    errors,
                )

        for duplicate_sha in (HEAD_SHA, "b" * 40):
            with self.subTest(duplicate_sha=duplicate_sha):
                exception = [
                    f"{field_label}: {field_value}"
                    for field_label, field_value in values.items()
                ]
                exception.append(f"Immutable candidate SHA: {duplicate_sha}.")
                errors = _validate_lifecycle_sections(
                    {
                        "Primary issue": (
                            "Primary issue #47 registers this frozen legacy candidate."
                        ),
                        "Lifecycle exception": "\n".join(exception),
                    },
                    head_ref="validation/frozen-candidate",
                )
                conflict_detail = (
                    " with conflicting values" if duplicate_sha != HEAD_SHA else ""
                )
                self.assertIn(
                    (
                        "lifecycle: legacy exception field 'Immutable candidate SHA' "
                        "has 2 visible canonical "
                        f"occurrences{conflict_detail}; expected at most one"
                    ),
                    errors,
                )

    def test_lifecycle_rejects_multiple_disposition_alternatives(self) -> None:
        both_alternatives = "\n".join(
            (
                _non_merge_record(),
                "Close or deletion conditions: delete after issue review.",
            )
        )
        errors = _validate_lifecycle_sections(
            {
                "Merge intention": (
                    "This validation branch is not intended to merge and "
                    "retains test evidence."
                ),
                "Non-merge record": both_alternatives,
            }
        )
        self.assertIn(
            (
                "lifecycle: disposition metadata must declare at most one disposition "
                "alternative: 'Final disposition' or "
                "'Close or deletion conditions'"
            ),
            errors,
        )

        errors = _validate_lifecycle_sections(
            {
                "Rollback or final disposition": "\n".join(
                    (
                        "Final disposition: archive the branch after merge.",
                        (
                            "Close or deletion conditions: close the temporary "
                            "tracking branch after merge."
                        ),
                    )
                )
            }
        )
        self.assertIn(
            (
                "lifecycle: disposition metadata must declare at most one "
                "disposition alternative: 'Final disposition' or "
                "'Close or deletion conditions'"
            ),
            errors,
        )

        for rollback_field, expected in (
            (
                "Final disposition: archive the branch after merge.",
                (
                    "lifecycle: disposition metadata field 'Final disposition' "
                    "has 2 visible canonical occurrences with conflicting values; "
                    "expected at most one"
                ),
            ),
            (
                (
                    "Close or deletion conditions: close the temporary tracking "
                    "branch after merge."
                ),
                (
                    "lifecycle: disposition metadata must declare at most one "
                    "disposition alternative: 'Final disposition' or "
                    "'Close or deletion conditions'"
                ),
            ),
        ):
            with self.subTest(rollback_field=rollback_field):
                errors = _validate_lifecycle_sections(
                    {
                        "Merge intention": (
                            "This validation branch is not intended to merge and "
                            "retains test evidence."
                        ),
                        "Non-merge record": _non_merge_record(),
                        "Rollback or final disposition": rollback_field,
                    }
                )
                self.assertIn(expected, errors)

    def test_lifecycle_duplicate_examples_remain_non_operative(self) -> None:
        record = "\n\n".join(
            (
                _non_merge_record(),
                "> Purpose: quoted example must not count.",
                "```text\nPurpose: fenced example must not count.\n```",
                '"Purpose: quoted prose must not count."',
                "The checker documents Purpose: descriptive prose must not count.",
            )
        )
        self.assertEqual(
            _validate_lifecycle_sections(
                {
                    "Merge intention": (
                        "This validation branch is not intended to merge and "
                        "retains test evidence."
                    ),
                    "Non-merge record": record,
                }
            ),
            [],
        )

    def test_lifecycle_field_labels_require_column_zero_physical_lines(self) -> None:
        values = {
            "Legacy registration": "#47.",
            "Immutable candidate SHA": f"{HEAD_SHA}.",
            "Reason": "frozen identity remains.",
            "Original branch identity": "validation/frozen-candidate.",
            "Original primary issue": "#54.",
            "Retained evidence": "hosted logs remain attached.",
            "Intended disposition": "retain until migration closes.",
            "Purpose": "preserve validation evidence.",
            "Exact candidate or workflow SHA": f"{HEAD_SHA}.",
            "Final disposition": "close after issue review.",
            "Close or deletion conditions": "close after issue review.",
        }
        canonical = "\n".join(
            f"{label}: {value}" for label, value in values.items()
        )
        parsed = governance._parse_lifecycle_fields(canonical)
        self.assertEqual(set(parsed), {label.lower() for label in values})

        for label, value in values.items():
            attacks = (
                f"This explanation merely mentions {label}: {value}",
                f"({label}: {value})",
                f"Example: {label}: {value}",
                f"Policy description: {label}: {value}",
                f'The test documents "{label}: {value}"',
                f"The test documents “{label}: {value}”",
                f"`{label}: {value}`",
                f"```text\n{label}: {value}\n```",
                f"> {label}: {value}",
                f" {label}: {value}",
            )
            for attack in attacks:
                with self.subTest(label=label, attack=attack):
                    reviewable = governance._reviewable_markdown_structure(attack)
                    fields = governance._parse_lifecycle_fields(reviewable)
                    self.assertNotIn(label.lower(), fields)

        complete_records = (
            (
                "non-merge",
                _non_merge_record(),
                governance.NON_MERGE_FIELD_LABELS,
                {
                    "purpose",
                    "exact candidate or workflow sha",
                    "retained evidence",
                    "final disposition",
                },
            ),
            (
                "legacy",
                "\n".join(
                    (
                        "Legacy registration: #47.",
                        "Original branch identity: validation/frozen-candidate.",
                        "Original primary issue: #54.",
                        f"Immutable candidate SHA: {HEAD_SHA}.",
                        "Retained evidence: historical logs remain attached.",
                        "Intended disposition: retain until migration closes.",
                        "Reason: frozen identity remains.",
                    )
                ),
                governance.LEGACY_FIELD_LABELS,
                {
                    "legacy registration",
                    "original branch identity",
                    "original primary issue",
                    "immutable candidate sha",
                    "retained evidence",
                    "intended disposition",
                    "reason",
                },
            ),
        )
        for name, record, allowed_labels, required_keys in complete_records:
            one_line = " ".join(record.splitlines())
            attacks = (
                f'The checker documents "{record}"',
                f"The checker documents “{record}”",
                f"``{record}``",
                f"```text\n{record}\n```",
                "\n".join(f"> {line}" for line in record.splitlines()),
                f"An example would contain {one_line}",
                f"The test case describes {one_line}",
                f"The policy explains {one_line}",
                f"({one_line})",
                one_line,
            )
            for attack in attacks:
                with self.subTest(record=name, attack=attack):
                    reviewable = governance._reviewable_markdown_structure(attack)
                    fields = governance._parse_lifecycle_fields(
                        reviewable,
                        allowed_labels=allowed_labels,
                    )
                    self.assertFalse(required_keys.issubset(fields))

    def test_lifecycle_post_merge_qualification_binds_one_action_and_object(self) -> None:
        accepted = (
            "Final disposition: After this pull request merges, archive the branch.",
            "Final disposition: Archive the branch after this pull request merges.",
            "Final disposition: After merge, delete the source branch.",
            "Final disposition: Close the temporary tracking branch after merge.",
            "Final disposition: After successful integration, preserve these changes.",
            "Final disposition: Retain this candidate upon successful merge.",
            "Final disposition: Archive the historical evidence after merge.",
            "Final disposition: Preserve the other modified objects for audit.",
        )
        for disposition in accepted:
            with self.subTest(accepted=disposition):
                self.assertEqual(
                    _validate_lifecycle_sections(
                        {"Rollback or final disposition": disposition}
                    ),
                    [],
                )

        rejected = (
            "Final disposition: Do not merge this branch, then archive it after merge.",
            (
                "Final disposition: Retain this candidate, and after merge "
                "delete the historical branch."
            ),
            (
                "Final disposition: Archive the historical evidence after merge; "
                "this PR must not merge."
            ),
            (
                "Final disposition: Delete this branch, preserve the logs after merge."
            ),
            (
                "Final disposition: Delete this branch, and after merge, "
                "retain the evidence."
            ),
            (
                "Final disposition: Delete the source branch now. "
                "After merge, retain the evidence."
            ),
            (
                "Final disposition: Close the temporary tracking branch now. "
                "After merge, retain the evidence."
            ),
            (
                "Final disposition: After merge, archive the evidence, "
                "then delete this branch."
            ),
            (
                "Final disposition: Archive the historical branch after merge, "
                "but retain this candidate."
            ),
            (
                "Final disposition: After the historical branch merges, "
                "archive this branch."
            ),
        )
        expected = (
            "lifecycle: merge-intended branch must not declare a "
            "non-merge final disposition"
        )
        for disposition in rejected:
            with self.subTest(rejected=disposition):
                self.assertIn(
                    expected,
                    _validate_lifecycle_sections(
                        {"Rollback or final disposition": disposition}
                    ),
                )

    def test_lifecycle_legacy_registration_requires_exact_field_binding(self) -> None:
        def legacy_errors(registration: str) -> list[str]:
            return _validate_lifecycle_sections(
                {
                    "Primary issue": (
                        "Primary issue #47 registers this frozen legacy candidate."
                    ),
                    "Lifecycle exception": "\n".join(
                        (
                            f"Legacy registration: {registration}",
                            "Original branch identity: validation/frozen-candidate.",
                            "Original primary issue: #54.",
                            f"Immutable candidate SHA: {HEAD_SHA}.",
                            "Retained evidence: historical logs remain attached.",
                            "Intended disposition: retain until migration closes.",
                            "Reason: frozen history retains its original identity.",
                        )
                    ),
                },
                head_ref="validation/frozen-candidate",
            )

        for value in ("#47", "#47.", "#47!", "#47?", "  #47  ", "\t#47.\t"):
            with self.subTest(valid=value):
                self.assertEqual(legacy_errors(value), [])

        invalid = (
            "#48 is wrong; see #47.",
            "#48, superseded by #47.",
            "See #47.",
            "#47 and #48.",
            "The incidental registration appears later as #47.",
            "#47 followed by extra operative text.",
            "#47,",
            "#47;",
            "#47:",
            "(#47)",
            "#047",
            "#47a",
            "x#47",
            "#47. Legacy registration: #47.",
        )
        expected = "lifecycle: legacy exception must declare 'Legacy registration: #47'"
        for value in invalid:
            with self.subTest(invalid=value):
                self.assertIn(expected, legacy_errors(value))

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
            "docs/HANDOFF_TEMPLATE.md",
            "docs/PROJECT_STATE.md",
            "docs/VALIDATION.md",
            "tools/check_governance.py",
            "tools/tests/test_check_governance.py",
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

    def test_repository_foundation_controls_are_high_risk(self) -> None:
        paths = [
            "docs/HANDOFF_TEMPLATE.md",
            "docs/PROJECT_STATE.md",
            "docs/VALIDATION.md",
            "tools/check_governance.py",
            "tools/tests/test_check_governance.py",
        ]
        self.assertEqual(governance.minimum_risk("dev", paths), "high")

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
            "## Rollback or final disposition", "## Removed"
        )
        errors = _validate(event, comments)
        self.assertTrue(any("## Rollback or final disposition" in error for error in errors), errors)

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
                definition_forms[index % len(definition_forms)],
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
        for index, section in enumerate(governance.REQUIRED_SECTIONS):
            padding = section_padding[index % len(section_padding)]
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
        self.assertIn('gh api "repos/$REPOSITORY/issues/$primary_issue"', governance_job)
        self.assertIn("primary issue must be a GitHub issue, not a pull request", governance_job)
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

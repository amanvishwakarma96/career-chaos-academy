#!/usr/bin/env python3
"""Validate a generated Career Chaos Academy scenario JSON file.

This mirrors the Phase 8 review rules used in the Flutter AI Scenario Lab.
Usage:
  python tool/validate_generated_scenario.py path/to/generated.json
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

SUPPORTED_MINI_GAMES = {
    "multiple_select",
    "code_fix",
    "match_pairs",
    "arrange_order",
    "data_cleanup",
    "decision_matrix",
}
SCORE_KEYS = {"skill", "discipline", "ethics", "communication", "chaos"}
HUMOR_SIGNALS = {
    "funny",
    "chaos",
    "dramatic",
    "samosa",
    "meme",
    "wild",
    "oops",
    "panic",
    "boss",
    "manager",
    "client",
    "disaster",
    "confused",
    "comedy",
}


def is_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def issue(kind: str, path: str, message: str) -> str:
    return f"{kind}: {path} - {message}"


def validate_score(value: Any, path: str, issues: list[str]) -> None:
    if not isinstance(value, dict):
        issues.append(issue("ERROR", path, "scoreImpact must be an object."))
        return
    for key in sorted(SCORE_KEYS):
        if not isinstance(value.get(key), (int, float)):
            issues.append(issue("ERROR", f"{path}.{key}", f"Score key {key!r} must be a number."))


def validate_chapter(chapter: Any, path: str, role_name: str, issues: list[str]) -> None:
    if not isinstance(chapter, dict):
        issues.append(issue("ERROR", path, "Chapter must be an object."))
        return

    for key in ["id", "title", "difficulty", "theme", "task", "professionalLearningPoint"]:
        if not is_string(chapter.get(key)):
            issues.append(issue("ERROR", f"{path}.{key}", "Required non-empty string is missing."))

    story = chapter.get("story") or chapter.get("scenario")
    if not is_string(story):
        issues.append(issue("ERROR", f"{path}.story", "Chapter must include story or scenario."))

    combined = " ".join(
        str(chapter.get(key, ""))
        for key in ["title", "theme", "story", "scenario", "task", "professionalLearningPoint"]
    ).lower()
    if not any(signal in combined for signal in HUMOR_SIGNALS):
        issues.append(issue("WARNING", path, "Humor is not obvious."))

    high_stakes_text = f"{role_name} {combined}".lower()
    is_medical = any(word in high_stakes_text for word in ["doctor", "medical", "medicine", "patient", "symptom", "hospital", "diagnosis", "prescription"])
    is_legal = any(word in high_stakes_text for word in ["lawyer", "legal", "court", "contract", "lawsuit", "compliance"])
    is_financial = any(word in high_stakes_text for word in ["finance", "loan", "investment", "credit", "insurance", "tax", "bank"])
    if (is_medical or is_legal or is_financial) and not is_string(chapter.get("safetyDisclaimer")):
        issues.append(issue("ERROR", f"{path}.safetyDisclaimer", "High-stakes content needs a safety disclaimer."))
    if is_medical and re.search(r"\b\d+\s?(mg|ml|tablet|dose|capsule)s?\b", high_stakes_text):
        issues.append(issue("ERROR", path, "Medical content must not give dosage instructions."))
    if is_medical and any(term in high_stakes_text for term in ["prescribe ", "diagnose as ", "stop taking medicine"]):
        issues.append(issue("ERROR", path, "Medical content must not diagnose or prescribe."))
    if is_financial and any(term in high_stakes_text for term in ["guaranteed profit", "risk-free return", "sure shot", "hide income"]):
        issues.append(issue("ERROR", path, "Financial content must avoid guaranteed returns or illegal shortcuts."))
    if is_legal and any(term in high_stakes_text for term in ["you will win", "hide evidence", "fake signature"]):
        issues.append(issue("ERROR", path, "Legal content must avoid legal conclusions or illegal instructions."))

    choices = chapter.get("choices")
    if not isinstance(choices, list) or len(choices) < 2:
        issues.append(issue("ERROR", f"{path}.choices", "Add at least 2 choices. Prefer 3."))
    else:
        for i, choice in enumerate(choices):
            cpath = f"{path}.choices[{i}]"
            if not isinstance(choice, dict):
                issues.append(issue("ERROR", cpath, "Choice must be an object."))
                continue
            if not is_string(choice.get("text")):
                issues.append(issue("ERROR", f"{cpath}.text", "Choice text is required."))
            outcome = choice.get("outcome")
            if not isinstance(outcome, dict):
                issues.append(issue("ERROR", f"{cpath}.outcome", "Outcome must be an object."))
            else:
                for key in ["title", "description", "moralLesson"]:
                    if not is_string(outcome.get(key)):
                        issues.append(issue("ERROR", f"{cpath}.outcome.{key}", "Required non-empty string is missing."))
            validate_score(choice.get("scoreImpact"), f"{cpath}.scoreImpact", issues)

    mini_game = chapter.get("miniGame")
    if mini_game is not None:
        validate_mini_game(mini_game, f"{path}.miniGame", issues)


def validate_mini_game(mini_game: Any, path: str, issues: list[str]) -> None:
    if not isinstance(mini_game, dict):
        issues.append(issue("ERROR", path, "miniGame must be an object."))
        return
    game_type = mini_game.get("type")
    if game_type not in SUPPORTED_MINI_GAMES:
        issues.append(issue("ERROR", f"{path}.type", f"Unsupported mini-game type {game_type!r}."))
        return
    for key in ["id", "title", "instructions", "prompt", "hint", "successMessage", "failureMessage"]:
        if not is_string(mini_game.get(key)):
            issues.append(issue("ERROR", f"{path}.{key}", "Required non-empty string is missing."))
    validate_score(mini_game.get("successScoreImpact"), f"{path}.successScoreImpact", issues)
    validate_score(mini_game.get("failureScoreImpact"), f"{path}.failureScoreImpact", issues)

    if game_type in {"multiple_select", "code_fix", "data_cleanup", "decision_matrix"}:
        options = mini_game.get("options")
        correct = mini_game.get("correctOptionIds")
        if not isinstance(options, list) or not options:
            issues.append(issue("ERROR", f"{path}.options", "This mini-game type needs options."))
        if not isinstance(correct, list) or not correct:
            issues.append(issue("ERROR", f"{path}.correctOptionIds", "Correct ids are required."))
    elif game_type == "match_pairs":
        if not isinstance(mini_game.get("pairs"), list) or not mini_game.get("pairs"):
            issues.append(issue("ERROR", f"{path}.pairs", "match_pairs needs pairs."))
    elif game_type == "arrange_order":
        if not isinstance(mini_game.get("orderItems"), list) or not mini_game.get("orderItems"):
            issues.append(issue("ERROR", f"{path}.orderItems", "arrange_order needs orderItems."))
        if not isinstance(mini_game.get("correctOrderIds"), list) or not mini_game.get("correctOrderIds"):
            issues.append(issue("ERROR", f"{path}.correctOrderIds", "arrange_order needs correctOrderIds."))


def validate_file(path: Path) -> list[str]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [issue("ERROR", "$", f"Invalid JSON: {exc}")]

    issues: list[str] = []
    if not isinstance(data, dict):
        return [issue("ERROR", "$", "Root must be an object.")]

    role = data.get("role")
    if not isinstance(role, dict):
        issues.append(issue("ERROR", "$.role", "Missing role object."))
        role_name = ""
    else:
        role_name = str(role.get("name", ""))
        for key in ["id", "name", "description", "iconKey"]:
            if not is_string(role.get(key)):
                issues.append(issue("ERROR", f"$.role.{key}", "Required non-empty string is missing."))

    chapters = data.get("chapters")
    if not isinstance(chapters, list) or not chapters:
        issues.append(issue("ERROR", "$.chapters", "chapters must be a non-empty list."))
    else:
        for i, chapter in enumerate(chapters):
            validate_chapter(chapter, f"$.chapters[{i}]", role_name, issues)
    return issues


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2
    path = Path(sys.argv[1])
    issues = validate_file(path)
    for item in issues:
        print(item)
    if any(item.startswith("ERROR") for item in issues):
        return 1
    print("PASS: generated scenario is valid for review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

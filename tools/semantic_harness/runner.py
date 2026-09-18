"""Reusable case runner and bounded conflict ledger for semantic tests."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

from .scenario import DEFAULT_SCENARIO, load_scenario, merge
from .worker import LuaSemanticWorker


@dataclass(frozen=True)
class HarnessCase:
    case_id: str
    scenario: dict[str, Any]
    inputs: tuple[str, ...]
    tags: tuple[str, ...] = ()

    @classmethod
    def from_mapping(cls, value: dict[str, Any], *, default_id: str = "case") -> "HarnessCase":
        inputs = value.get("inputs", [])
        if not isinstance(inputs, list) or not all(isinstance(item, str) for item in inputs):
            raise ValueError("case.inputs must be a list of strings")
        tags = value.get("tags", [])
        if not isinstance(tags, list) or not all(isinstance(item, str) for item in tags):
            raise ValueError("case.tags must be a list of strings")
        scenario = value.get("scenario", {})
        if not isinstance(scenario, dict):
            raise ValueError("case.scenario must be an object")
        return cls(
            case_id=str(value.get("id") or default_id),
            scenario=merge(DEFAULT_SCENARIO, scenario),
            inputs=tuple(inputs),
            tags=tuple(tags),
        )


def load_case(path: Path) -> HarnessCase:
    import json

    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("case root must be an object")
    return HarnessCase.from_mapping(value, default_id=path.stem)


def detect_conflicts(turns: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """Find deterministic ordering/duplication problems in bounded turn records."""

    conflicts: list[dict[str, Any]] = []
    previous_sequence = 0
    event_ids: dict[str, int] = {}
    for index, turn in enumerate(turns, start=1):
        sequence = turn.get("result", {}).get("sequence")
        if isinstance(sequence, int):
            if sequence <= previous_sequence:
                conflicts.append(
                    {
                        "kind": "turn_sequence_regression",
                        "turnIndex": index,
                        "previous": previous_sequence,
                        "current": sequence,
                    }
                )
            previous_sequence = max(previous_sequence, sequence)
        relationship_before = turn.get("relationshipBefore", {})
        relationship_after = turn.get("relationshipAfter", {})
        before_revision = relationship_before.get("revision")
        after_revision = relationship_after.get("revision")
        if isinstance(before_revision, int) and isinstance(after_revision, int):
            if after_revision < before_revision:
                conflicts.append(
                    {
                        "kind": "relationship_revision_regression",
                        "turnIndex": index,
                        "before": before_revision,
                        "after": after_revision,
                    }
                )
        for transport in turn.get("transport", []):
            if not isinstance(transport, dict) or transport.get("direction") != "server_to_client":
                continue
            payload = transport.get("payload", {}) if isinstance(transport, dict) else {}
            event_id = payload.get("eventID") if isinstance(payload, dict) else None
            if not isinstance(event_id, str) or not event_id:
                continue
            if event_id in event_ids:
                conflicts.append(
                    {
                        "kind": "duplicate_authoritative_event",
                        "turnIndex": index,
                        "eventID": event_id,
                        "firstTurnIndex": event_ids[event_id],
                    }
                )
            else:
                event_ids[event_id] = index
    return conflicts


@dataclass
class HarnessRun:
    case_id: str
    turns: list[dict[str, Any]] = field(default_factory=list)
    conflicts: list[dict[str, Any]] = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        return {
            "type": "harness_run",
            "caseID": self.case_id,
            "turns": self.turns,
            "conflicts": self.conflicts,
            "ok": not self.conflicts,
        }


def run_case(case: HarnessCase, **worker_kwargs: Any) -> HarnessRun:
    worker = LuaSemanticWorker(case.scenario, **worker_kwargs)
    run = HarnessRun(case_id=case.case_id)
    try:
        for value in case.inputs:
            run.turns.append(worker.input(value))
        run.conflicts = detect_conflicts(run.turns)
    finally:
        worker.close()
    return run


def run_scenario_file(path: Path, inputs: Iterable[str], **worker_kwargs: Any) -> HarnessRun:
    scenario = load_scenario(path)
    return run_case(
        HarnessCase(case_id=path.stem, scenario=scenario, inputs=tuple(inputs)),
        **worker_kwargs,
    )

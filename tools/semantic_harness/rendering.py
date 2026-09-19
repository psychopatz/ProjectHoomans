"""Human-readable JSON rendering shared by the harness clients."""

from __future__ import annotations

import json
from typing import Any


def pretty(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)


def print_result(value: Any, jsonl: bool) -> None:
    if jsonl:
        print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
    else:
        print(pretty(value))

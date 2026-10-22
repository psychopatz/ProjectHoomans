"""Bounded activity events shared by the GUI and command-line harness."""

from __future__ import annotations

from collections import deque
from datetime import datetime
from threading import Lock
from typing import Any


class ActivityLog:
    """Thread-safe bounded event history for one harness session."""

    def __init__(self, capacity: int = 500) -> None:
        self.capacity = max(32, int(capacity))
        self._events: deque[dict[str, Any]] = deque(maxlen=self.capacity)
        self._sequence = 0
        self._lock = Lock()

    def record(self, source: str, event: str, **details: Any) -> dict[str, Any]:
        with self._lock:
            self._sequence += 1
            record = {
                "sequence": self._sequence,
                "timestamp": datetime.now().astimezone().isoformat(
                    timespec="milliseconds"
                ),
                "source": str(source),
                "event": str(event),
                "details": details,
            }
            self._events.append(record)
            return dict(record)

    def snapshot(self, since: int = 0) -> list[dict[str, Any]]:
        with self._lock:
            return [
                dict(record)
                for record in self._events
                if int(record.get("sequence", 0)) > int(since)
            ]

    @property
    def latest_sequence(self) -> int:
        with self._lock:
            return self._sequence

    def clear(self) -> None:
        with self._lock:
            self._events.clear()


def format_activity_event(record: dict[str, Any]) -> str:
    """Render one event without dumping large request or scenario payloads."""

    timestamp = str(record.get("timestamp") or "")
    if "T" in timestamp:
        timestamp = timestamp.split("T", 1)[1]
    timestamp = timestamp.rsplit("+", 1)[0].rsplit("-", 1)[0]
    source = str(record.get("source") or "event").upper()
    event = str(record.get("event") or "activity")
    details = record.get("details") or {}
    if not isinstance(details, dict):
        details = {"detail": details}
    parts: list[str] = []
    for key in (
        "operation",
        "command",
        "requestID",
        "controlID",
        "label",
        "speaker",
        "value",
        "replay",
        "durationMs",
        "pid",
        "message",
    ):
        value = details.get(key)
        if value is not None and value != "":
            rendered = str(value).replace("\n", " ")
            if len(rendered) > 180:
                rendered = rendered[:177] + "..."
            parts.append(f"{key}={rendered}")
    suffix = " · ".join(parts)
    return f"{timestamp}  {source:<8} {event:<16}" + (f" · {suffix}" if suffix else "")

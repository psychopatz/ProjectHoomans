"""Production flow/fact/event authoring operations for the harness worker."""

from __future__ import annotations

from typing import Any, Protocol


class _WorkerRequestHost(Protocol):
    def _request(self, command: str, value: Any = None) -> dict[str, Any]: ...


class WorkerAuthoringOperations:
    """Expose the Lua-owned authoring registries without owning transport."""

    def __init__(self, host: _WorkerRequestHost) -> None:
        self._host = host

    def flow_catalog(self) -> dict[str, Any]:
        """Read normalized production flow definitions from the Lua registry."""

        return self._host._request("FLOW_CATALOG")

    def response_pool_detail(
        self, pool_id: str, *, offset: int = 0, limit: int = 8
    ) -> dict[str, Any]:
        """Inspect loaded Lua variants, never simulate their selection in Python."""
        return self._host._request(
            "RESPONSE_POOL_DETAIL",
            {"poolID": pool_id, "offset": offset, "limit": limit},
        )

    def fact_catalog(self) -> list[dict[str, Any]]:
        """Read typed engine facts exposed to semantic gates and context."""

        return self._host._request("FACT_CATALOG").get("facts", [])

    def event_catalog(self) -> list[dict[str, Any]]:
        """Read bounded engine notification types."""

        return self._host._request("EVENT_CATALOG").get("events", [])

    def validate_flow(self, definition: dict[str, Any]) -> dict[str, Any]:
        """Validate a draft through the production Lua flow registry."""

        return self._host._request("FLOW_VALIDATE", definition)

    def register_flow(self, definition: dict[str, Any]) -> dict[str, Any]:
        """Register a validated draft in this worker's production registry."""

        return self._host._request("FLOW_REGISTER", definition)

    def generate_flows(self) -> dict[str, Any]:
        """Regenerate registered flows from live capability metadata."""

        return self._host._request("FLOW_GENERATE")

    def flow_coverage(self) -> list[dict[str, Any]]:
        """Return the live capability generation classification report."""

        return self._host._request("FLOW_COVERAGE").get("capabilityCoverage", [])

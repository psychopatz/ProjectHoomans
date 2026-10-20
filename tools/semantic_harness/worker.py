"""High-level session API backed by the real Lua semantic worker."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from .config import HarnessConfig
from .process import HarnessError, LuaProcess
from .scenario import validate_scenario


REPOSITORY = Path(__file__).resolve().parents[2]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
LUA_WORKER = Path(__file__).with_name("lua") / "worker.lua"


class LuaSemanticWorker:
    """Own one isolated Lua runtime and exchange structured turn records."""

    def __init__(
        self,
        scenario: dict[str, Any],
        lua_bin: str | None = None,
        repository: Path | None = None,
        core_repository: Path | None = None,
        worker_script: Path | None = None,
        startup_timeout: float = 8.0,
        request_timeout: float = 5.0,
        shutdown_timeout: float = 1.0,
        config: HarnessConfig | None = None,
    ) -> None:
        validate_scenario(scenario)
        self.scenario = scenario
        self.config = config or HarnessConfig.discover(
            repository=repository or REPOSITORY,
            core_repository=core_repository or CORE_REPOSITORY,
            lua_bin=lua_bin,
            worker_script=worker_script or LUA_WORKER,
            startup_timeout=startup_timeout,
            request_timeout=request_timeout,
            shutdown_timeout=shutdown_timeout,
        )
        self.runtime = LuaProcess(self.config)
        try:
            self.runtime.start()
            self.configure(scenario)
        except Exception:
            self.runtime.close()
            raise

    @property
    def process(self) -> Any:
        """Compatibility access for diagnostics; prefer status()."""

        return self.runtime.process

    def status(self) -> dict[str, Any]:
        return self.runtime.status()

    def _request(self, command: str, value: Any = None) -> dict[str, Any]:
        return self.runtime.request(command, value)

    def configure(self, scenario: dict[str, Any]) -> dict[str, Any]:
        validate_scenario(scenario)
        response = self._request("CONFIG", scenario)
        self.scenario = scenario
        return response

    def reset(self) -> dict[str, Any]:
        return self._request("RESET")

    def input(self, text: str) -> dict[str, Any]:
        return self._request("INPUT", str(text))

    def preview(self, text: str) -> dict[str, Any]:
        """Preview a production semantic turn without recording or dispatching it."""

        return self._request("PREVIEW", str(text))

    def set_language(self, language: str) -> dict[str, Any]:
        """Change the production translation manager language in this session."""

        value = str(language or "EN").strip().upper()
        response = self._request("LANGUAGE", value)
        self.scenario.setdefault("runtime", {})["language"] = value
        return response

    def tool_reply(
        self,
        results: list[dict[str, Any]],
        context: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Resolve a production dedicated tool reply through the real catalog."""

        return self._request(
            "TOOL_REPLY",
            {"results": results, "context": context or {}},
        )

    def snapshot(self) -> dict[str, Any]:
        return self._request("SNAPSHOT")

    def replay_quest_request(self, request: dict[str, Any]) -> dict[str, Any]:
        """Replay a captured request through the production server router."""

        return self._request("REPLAY_SEMANTIC_QUEST", request)

    def commitment(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Exercise the production NPC Knowledge commitment boundary."""

        return self._request("COMMITMENT", payload)

    def backstory(
        self,
        identity_seed: int,
        tactical_class: str = "colonist",
        npc_id: str = "harness-backstory-npc",
    ) -> dict[str, Any]:
        """Read a bounded seed-derived backstory projection from production Lua."""

        return self._request(
            "BACKSTORY",
            {
                "identitySeed": identity_seed,
                "tacticalClass": tactical_class,
                "npcID": npc_id,
            },
        )

    def backstory_fact(
        self,
        identity_seed: int,
        kind: str,
        tactical_class: str = "colonist",
        language: str = "EN",
        npc_id: str = "harness-backstory-npc",
    ) -> dict[str, Any]:
        """Resolve one authoritative offline backstory fact in production Lua."""

        return self._request(
            "BACKSTORY_FACT",
            {
                "identitySeed": identity_seed,
                "kind": kind,
                "tacticalClass": tactical_class,
                "language": language,
                "npcID": npc_id,
            },
        )

    def flow_catalog(self) -> dict[str, Any]:
        """Read normalized production flow definitions from the Lua registry."""

        return self._request("FLOW_CATALOG")

    def fact_catalog(self) -> list[dict[str, Any]]:
        """Read typed engine facts exposed to semantic gates and context."""

        return self._request("FACT_CATALOG").get("facts", [])

    def event_catalog(self) -> list[dict[str, Any]]:
        """Read bounded engine notification types."""

        return self._request("EVENT_CATALOG").get("events", [])

    def validate_flow(self, definition: dict[str, Any]) -> dict[str, Any]:
        """Validate a draft through the production Lua flow registry."""

        return self._request("FLOW_VALIDATE", definition)

    def register_flow(self, definition: dict[str, Any]) -> dict[str, Any]:
        """Register a validated draft in this worker's production registry."""

        return self._request("FLOW_REGISTER", definition)

    def generate_flows(self) -> dict[str, Any]:
        """Regenerate registered production flows from live capability metadata."""

        return self._request("FLOW_GENERATE")

    def flow_coverage(self) -> list[dict[str, Any]]:
        """Return the live capability generation classification report."""

        return self._request("FLOW_COVERAGE").get("capabilityCoverage", [])

    def ping(self) -> dict[str, Any]:
        return self._request("PING")

    def capabilities(self) -> dict[str, Any]:
        capabilities = self._request("CAPABILITIES")
        # Keep the capability handshake bounded as the generated production
        # catalog grows. The catalog remains available through the same
        # production FlowEditor seam, but is fetched as its own bounded
        # response instead of being duplicated in CAPABILITIES.
        if "flowCatalog" not in capabilities:
            capabilities["flowCatalog"] = self.flow_catalog()
        return capabilities

    def restart(self) -> dict[str, Any]:
        """Restart the isolated worker and restore the current scenario."""

        self.runtime.close()
        self.runtime.start()
        return self.configure(self.scenario)

    def close(self) -> None:
        self.runtime.close()

    def __enter__(self) -> "LuaSemanticWorker":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

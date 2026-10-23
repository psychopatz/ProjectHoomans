"""High-level session API backed by the real Lua semantic worker."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any

from .config import HarnessConfig
from .item_catalog import search_item_catalog
from .process import HarnessError, LuaProcess
from .scenario import validate_scenario
from .activity import ActivityLog, default_activity_path


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = Path(__file__).resolve().parents[3]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
LUA_WORKER = PACKAGE_ROOT / "lua" / "worker.lua"


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
        activity_log: ActivityLog | None = None,
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
        self.activity_log = activity_log or ActivityLog(
            path=default_activity_path(self.config.repository),
            client="api",
        )
        self.runtime = LuaProcess(self.config, activity_log=self.activity_log)
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

    def suggestion_predicate(self, predicate: dict[str, Any]) -> dict[str, Any]:
        """Evaluate one production suggestion predicate against the public scenario projection."""

        return self._request("SUGGESTION_PREDICATE", {"predicate": predicate})

    def suggestion_click(self, frame: dict[str, Any]) -> dict[str, Any]:
        """Submit one canonical suggestion frame through the production input path."""

        return self._request("SUGGESTION_CLICK", {"frame": frame})

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

    def relationship_proposal(self, npc_id: str | None = None) -> dict[str, Any]:
        """Submit the canonical proposal action to the server-authority seam."""

        payload = {"npcID": npc_id} if npc_id else None
        return self._request("RELATIONSHIP_PROPOSAL", payload)

    def relationship_preview(
        self,
        relationship: dict[str, Any],
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Resolve staged relationship scores without mutating the scenario."""

        payload: dict[str, Any] = {"relationship": dict(relationship)}
        if npc_id:
            payload["npcID"] = npc_id
        return self._request("RELATIONSHIP_PREVIEW", payload)

    def conversation_graph(self) -> dict[str, Any]:
        """Return the developer-only full selected ConversationBlock graph."""

        return self._request("CONVERSATION_GRAPH")

    def persona_catalog(
        self, register_relationship_kind: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        """Return the bounded catalog owned by the production Lua registries."""

        payload = None
        if register_relationship_kind is not None:
            payload = {"registerRelationshipKind": register_relationship_kind}
        return self._request("PERSONA_CATALOG", payload)

    def persona_preview(self, scenario: dict[str, Any]) -> dict[str, Any]:
        """Preview generated NPC personality for a staged scenario."""

        validate_scenario(scenario)
        return self._request("PERSONA_PREVIEW", {"scenario": scenario})

    def simulation_control_catalog(self) -> dict[str, Any]:
        """Return the worker-owned, bounded Semantic Lab control metadata."""

        return self._request("SIMULATION_CONTROL_CATALOG")

    def talk_catalog(self) -> dict[str, Any]:
        """Return the production-owned native Talk target catalog."""

        return self._request("TALK_CATALOG")

    def talk_start(
        self, target_id: str = "current", utterance: str = "hello"
    ) -> dict[str, Any]:
        """Start the native Talk parity projection for one target type."""

        result = self._request(
            "TALK_START",
            {
                "targetID": str(target_id or "current"),
                "utterance": str(utterance or "hello"),
            },
        )
        scenario = result.get("scenario")
        if isinstance(scenario, dict):
            self.scenario = scenario
        return result

    def talk_matrix(
        self,
        target_types: list[str] | None = None,
        text: str = "hello",
        maximum: int = 8,
    ) -> dict[str, Any]:
        """Compare native Talk startup and the first turn across target types."""

        payload: dict[str, Any] = {
            "utterance": str(text or "hello"),
            "maximum": int(maximum),
        }
        if target_types is not None:
            payload["targetIDs"] = [str(value) for value in target_types]
        return self._request("TALK_MATRIX", payload)

    def item_catalog(self, query: str = "", limit: int = 50) -> dict[str, Any]:
        """Search installed Project Zomboid item definitions for the Lab editor."""

        return search_item_catalog(query, limit, self.scenario)

    def context_matrix(
        self,
        scenarios: list[dict[str, Any]],
        text: str = "hello",
        maximum: int = 8,
    ) -> dict[str, Any]:
        """Run bounded scenario A/B rows through this same real Lua worker."""

        original = self.scenario
        rows: list[dict[str, Any]] = []
        try:
            for index, scenario in enumerate(scenarios[: max(1, int(maximum))]):
                validate_scenario(scenario)
                configured = self.configure(scenario)
                turn = self.input(text)
                snapshot = self.snapshot()
                observation = turn.get("observation", {})
                observation = observation if isinstance(observation, dict) else {}
                response = observation.get("response", {})
                response = response if isinstance(response, dict) else {}
                queued = (response.get("queued") or [response])[0]
                queued = queued if isinstance(queued, dict) else response
                suggestions = observation.get("suggestions") or {}
                context = snapshot.get("context") or {}
                actor_context = context.get("actorConversationContext") or {}
                actor_relationship = actor_context.get("relationship") or {}
                speech_style = (
                    context.get("speechStyleContext")
                    or response.get("speechStyleContext")
                    or {}
                )
                flow = observation.get("flow") or {}
                rows.append(
                    {
                        "index": index,
                        "label": scenario.get("runtime", {}).get(
                            "semanticLabMatrixLabel", f"case-{index + 1}"
                        ),
                        "configured": {
                            "accepted": configured.get("ok") is True,
                            "dynamicTradingLoad": configured.get(
                                "dynamicTradingLoad"
                            ),
                        },
                        "context": snapshot.get("context", {}),
                        "npcResponse": queued.get("text") or response.get("text"),
                        "semanticHubChoices": [
                            {
                                "id": candidate.get("id"),
                                "action": candidate.get("action"),
                                "label": (candidate.get("display") or {}).get("label")
                                or candidate.get("labelFallback"),
                                "status": candidate.get("status"),
                            }
                            for candidate in (suggestions.get("candidates") or [])[:24]
                            if isinstance(candidate, dict)
                        ],
                        "speechStyleContext": speech_style,
                        "relationship": {
                            "standing": actor_relationship.get("state")
                            or actor_relationship.get("standing")
                            or "unknown",
                            "bond": deepcopy(
                                actor_relationship.get("bond")
                                or (snapshot.get("simulationProjection") or {})
                                .get("npc", {})
                                .get("bond")
                                or {}
                            ),
                            "approval": actor_relationship.get("approval"),
                            "respect": actor_relationship.get("respect"),
                            "familiarity": actor_relationship.get("familiarity"),
                        },
                        "runtimeGraphPath": {
                            "kind": "semantic_flow" if flow.get("flowId") else "semantic_hub",
                            "flow": flow,
                            "graph": observation.get("conversationGraph")
                            or response.get("conversationGraph"),
                        },
                        "response": {
                            "semanticTemplateID": response.get("templateID"),
                            "renderTemplateID": response.get("renderTemplateID"),
                            "key": queued.get("key") or response.get("templateID"),
                            "text": queued.get("text") or response.get("text"),
                            "fallback": queued.get("fallback") or response.get("fallback"),
                            "translationKey": queued.get("translationKey"),
                            "realizationFamily": queued.get("realizationFamily")
                            or response.get("realizationFamily"),
                            "realizationVariant": queued.get("realizationVariant")
                            or response.get("realizationVariant"),
                            "realizationFallbackReason": queued.get(
                                "realizationFallbackReason"
                            ) or response.get("realizationFallbackReason"),
                            "familyAddress": (queued.get("args") or {}).get(
                                "familyAddress"
                            ),
                        },
                        "suggestions": {
                            "revision": suggestions.get("revision"),
                            "candidateOrder": [
                                row.get("id")
                                for row in (suggestions.get("candidates") or [])[:24]
                            ],
                            "candidates": [
                                {
                                    "id": row.get("id"),
                                    "providerID": row.get("providerID"),
                                    "source": row.get("source"),
                                    "ranking": row.get("ranking"),
                                    "display": row.get("display"),
                                }
                                for row in (suggestions.get("candidates") or [])[:24]
                            ],
                        },
                    }
                )
        finally:
            self.configure(original)
        return {"schema": "semantic.persona.matrix.v1", "rows": rows}

    def capture_baseline(self, text: str) -> dict[str, Any]:
        """Capture a non-mutating production baseline for the current scenario."""

        value = str(text or "").strip()
        if not value:
            raise ValueError("baseline utterance must not be empty")
        preview = self.preview(value)
        return {
            "schema": "semantic.persona.baseline.v1",
            "utterance": value,
            "preview": preview,
        }

    def apply_and_replay(self, text: str) -> dict[str, Any]:
        """Reapply the current scenario and replay one utterance in production Lua."""

        value = str(text or "").strip()
        if not value:
            raise ValueError("replay utterance must not be empty")
        configured = self.configure(self.scenario)
        turn = self.input(value)
        return {
            "schema": "semantic.persona.apply_replay.v1",
            "utterance": value,
            "configured": configured,
            "turn": turn,
        }

    def knowledge_bootstrap(
        self, request_id: str = "harness-knowledge-bootstrap"
    ) -> dict[str, Any]:
        """Hydrate the real player-scoped Knowledge projection after reload."""

        return self._request(
            "KNOWLEDGE_BOOTSTRAP", {"requestID": str(request_id)}
        )

    def knowledge_metrics(
        self, synthetic_npcs: int = 0, facts_per_npc: int = 1
    ) -> dict[str, Any]:
        """Measure serialized production NPC and player Knowledge records."""

        return self._request(
            "KNOWLEDGE_METRICS",
            {
                "syntheticNPCs": int(synthetic_npcs),
                "factsPerNPC": int(facts_per_npc),
            },
        )

    def world_knowledge_inspect(
        self, actor_id: str | None = None, fact_id: str | None = None,
        max_facts: int = 32,
    ) -> dict[str, Any]:
        """Inspect the production World Knowledge ledger and actor explanations."""

        return self._request(
            "WORLD_KNOWLEDGE_INSPECT",
            {
                "actorID": actor_id,
                "factID": fact_id,
                "maxFacts": int(max_facts),
            },
        )

    def world_knowledge_propagate(
        self, from_actor_id: str, to_actor_id: str,
        channel: str = "conversation", authorized: bool = True,
        now: float = 1000,
    ) -> dict[str, Any]:
        """Exercise one authorized production propagation opportunity."""

        return self._request(
            "WORLD_KNOWLEDGE_PROPAGATE",
            {
                "fromActorID": str(from_actor_id),
                "toActorID": str(to_actor_id),
                "channel": str(channel),
                "authorized": bool(authorized),
                "now": float(now),
            },
        )

    def knowledge_discover(
        self, topic_id: str, npc_id: str | None = None
    ) -> dict[str, Any]:
        """Use the production direct-disclosure Knowledge path for a topic."""

        return self._request(
            "KNOWLEDGE_DISCOVER",
            {
                "topicID": str(topic_id),
                "npcID": str(npc_id) if npc_id is not None else None,
            },
        )

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
        # response instead of being duplicated in CAPABILITIES. This is still
        # part of startup, so use the startup budget rather than the shorter
        # interactive request budget when the catalog is under load.
        if "flowCatalog" not in capabilities:
            capabilities["flowCatalog"] = self.runtime.request(
                "FLOW_CATALOG", timeout=self.config.startup_timeout
            )
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

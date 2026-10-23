"""High-level session API backed by the real Lua semantic worker."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any

from .config import HarnessConfig
from .fixture_provider import OfflineEngineFixtureProvider
from .item_catalog import search_item_catalog
from .live_profiler_provider import LiveProfilerProvider
from .process import HarnessError, LuaProcess
from .scenario import load_scenario, validate_scenario
from .save_browser import SavedWorldBrowser
from .save_catalog import SaveCatalog
from .save_import import SaveBackedImporter
from .state import HarnessWorkingWorld, ImportedSourceSnapshot, Provenance
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
        self.source_snapshot = ImportedSourceSnapshot.from_scenario(
            scenario,
            source=Provenance.FIXTURE,
            source_id="fixture:synthetic-scenario",
            mode="developer_test",
        )
        self.working_world = HarnessWorkingWorld(self.source_snapshot)
        self.scenario = self.working_world.data
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
            self.import_source(scenario)
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
        """Apply a working-world draft without replacing the imported source."""

        validate_scenario(scenario)
        response = self._request("CONFIG", scenario)
        self.working_world.replace(scenario)
        self.scenario = self.working_world.data
        return response

    def reset(self) -> dict[str, Any]:
        """Reset the conversation/runtime containers, preserving world edits."""

        response = self._request("RESET")
        self._sync_effective_scenario(response)
        return response

    def import_source(
        self,
        scenario: dict[str, Any],
        *,
        source: Provenance | str = Provenance.FIXTURE,
        source_id: str = "fixture:synthetic-scenario",
        mode: str = "developer_test",
        metadata: dict[str, Any] | None = None,
        provenance: dict[str, Any] | None = None,
        provider_payloads: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Install a new immutable source and derive a fresh working world."""

        validate_scenario(scenario)
        fixture_provider = OfflineEngineFixtureProvider()
        effective_payloads = deepcopy(provider_payloads or {})
        effective_payloads.setdefault(
            fixture_provider.provider_id,
            fixture_provider.project(scenario),
        )
        effective_provenance = deepcopy(provenance or {})
        effective_provenance.setdefault("schema", "semantic.provenance.v1")
        default_source = (
            source.value if isinstance(source, Provenance) else str(source).upper()
        )
        if default_source not in {item.value for item in Provenance}:
            default_source = Provenance.MISSING.value
        effective_provenance.setdefault("defaultSource", default_source)
        effective_paths = effective_provenance.setdefault("paths", {})
        for path, value in fixture_provider.provenance_paths(scenario).items():
            effective_paths.setdefault(path, value)
        snapshot = ImportedSourceSnapshot.from_scenario(
            scenario,
            source=source,
            source_id=source_id,
            mode=mode,
            metadata=metadata,
            provenance=effective_provenance,
            provider_payloads=effective_payloads,
        )
        response = self._request(
            "IMPORT_SOURCE",
            {
                "scenario": snapshot.to_dict()["data"],
                "metadata": snapshot.to_dict()["metadata"],
                "provenance": snapshot.to_dict()["provenance"],
                "providerPayloads": snapshot.to_dict()["providerPayloads"],
            },
        )
        self.source_snapshot = snapshot
        self.working_world = HarnessWorkingWorld(snapshot)
        self._sync_effective_scenario(response, establish_baseline=True)
        return response

    def reload_source(
        self,
        scenario: dict[str, Any] | None = None,
        *,
        path: Path | None = None,
        source: Provenance | str = Provenance.FIXTURE,
        source_id: str | None = None,
        mode: str = "developer_test",
    ) -> dict[str, Any]:
        """Explicitly reread/reinstall a source; reset never calls this path."""

        if path is not None:
            scenario = load_scenario(Path(path))
            source_id = source_id or f"fixture:file:{Path(path).resolve()}"
        if scenario is None:
            scenario = self.source_snapshot.to_dict()["data"]
        return self.import_source(
            scenario,
            source=source,
            source_id=source_id or "fixture:synthetic-scenario",
            mode=mode,
        )

    def reset_turn(self) -> dict[str, Any]:
        return self._request("RESET_TURN")

    def reset_conversation(self) -> dict[str, Any]:
        response = self._request("RESET_CONVERSATION")
        self._sync_effective_scenario(response)
        return response

    def reset_selected_actor(self, actor: str = "npc") -> dict[str, Any]:
        response = self._request("RESET_ACTOR_MUTATIONS", {"actor": str(actor)})
        self._sync_effective_scenario(response)
        return response

    def reset_working_world(self) -> dict[str, Any]:
        """Restore the imported snapshot without rereading its source."""

        response = self._request("RESET_WORLD")
        self.working_world.reset()
        self._sync_effective_scenario(response)
        return response

    def _sync_effective_scenario(
        self, response: dict[str, Any], *, establish_baseline: bool = False
    ) -> None:
        scenario = response.get("scenario") if isinstance(response, dict) else None
        if isinstance(scenario, dict):
            if establish_baseline:
                self.working_world.set_baseline(scenario)
            else:
                self.working_world.replace(scenario)
            self.scenario = self.working_world.data

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
        response = self._request("SNAPSHOT")
        self._sync_effective_scenario(response)
        return response

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

    def save_catalog(self, roots: list[Path] | None = None) -> dict[str, Any]:
        """Discover validated offline saves through PsychopatzCore's reader."""

        return SaveCatalog(
            roots,
            core_repository=self.config.core_repository,
        ).discover()

    def offline_fixture_catalog(self) -> dict[str, Any]:
        """Describe editable engine-only values and their fixture provenance."""

        return OfflineEngineFixtureProvider().catalog(self.scenario)

    def live_profiler_catalog(
        self,
        *,
        enabled: bool = False,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Describe the optional read-only live snapshot provider."""

        return LiveProfilerProvider(
            core_repository=self.config.core_repository,
            snapshot_path=snapshot_path,
            config_path=config_path,
            enabled=enabled,
        ).catalog(npc_id=npc_id)

    def enrich_from_live_profiler(
        self,
        *,
        enabled: bool = False,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        player_id: str | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Explicitly copy live engine values into the isolated source world.

        Only paths owned by ``OfflineEngineFixtureProvider`` are eligible for
        enrichment.  The existing imported source save/fixture is never
        reopened or written; a new immutable in-memory snapshot is installed
        for the detached worker only, with LIVE provenance on each copied
        path.
        """

        provider = LiveProfilerProvider(
            core_repository=self.config.core_repository,
            snapshot_path=snapshot_path,
            config_path=config_path,
            enabled=enabled,
        )
        projection = provider.project(
            operation="GET_SNAPSHOT",
            player_id=player_id,
            npc_id=npc_id,
        )
        enrichment, live_paths = provider.fixture_enrichment(projection)
        if not enrichment:
            return {"ok": False, "liveProfiler": projection, "imported": False}

        def merge_overlay(target: dict[str, Any], overlay: dict[str, Any]) -> None:
            for key, value in overlay.items():
                if isinstance(value, dict) and isinstance(target.get(key), dict):
                    merge_overlay(target[key], value)
                else:
                    target[key] = deepcopy(value)

        source = self.source_snapshot.to_dict()
        enriched_data = deepcopy(source["data"])
        merge_overlay(enriched_data, enrichment)
        metadata = deepcopy(source["metadata"])
        metadata["liveProfiler"] = {
            "providerID": provider.provider_id,
            "snapshotPath": str(provider.snapshot_path),
            "configPath": str(provider.config_path),
            "snapshot": deepcopy(projection.get("snapshot")),
        }
        provenance = deepcopy(source["provenance"])
        provenance.setdefault("schema", "semantic.provenance.v1")
        provenance.setdefault("paths", {}).update(live_paths)
        provider_payloads = deepcopy(source["providerPayloads"])
        provider_payloads[provider.provider_id] = projection
        response = self.import_source(
            enriched_data,
            source=metadata.get("sourceKind", self.source_snapshot.source),
            source_id=str(metadata.get("sourceID") or "live-enriched-source"),
            mode=str(metadata.get("mode") or "offline_save"),
            metadata=metadata,
            provenance=provenance,
            provider_payloads=provider_payloads,
        )
        response["liveProfiler"] = projection
        response["imported"] = True
        response["enrichedPaths"] = sorted(live_paths)
        return response

    def save_browser(self, save_path: Path) -> dict[str, Any]:
        """Return a bounded read-only actor/world projection for one save."""

        return SavedWorldBrowser(
            core_repository=self.config.core_repository,
        ).browse(Path(save_path))

    def import_saved_selection(
        self,
        save_path: Path,
        *,
        player_uuid: str | None = None,
        npc_id: str | None = None,
        engine_fixtures: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Import one saved Player/NPC pair into the detached worker world."""

        selection = SaveBackedImporter(
            core_repository=self.config.core_repository,
        ).load(
            Path(save_path),
            player_uuid=player_uuid,
            npc_id=npc_id,
            engine_fixtures=engine_fixtures,
        )
        return self.import_source(
            selection.scenario,
            source=Provenance.SAVE,
            source_id=selection.metadata["sourceID"],
            mode="offline_save",
            metadata=selection.metadata,
            provenance=selection.provenance,
            provider_payloads=selection.provider_payloads,
        )

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
        save_seed: str | int | None = None,
    ) -> dict[str, Any]:
        """Read a bounded seed-derived backstory projection from production Lua."""

        payload: dict[str, Any] = {
            "identitySeed": identity_seed,
            "tacticalClass": tactical_class,
            "npcID": npc_id,
        }
        if save_seed is not None:
            payload["saveSeed"] = save_seed
        return self._request(
            "BACKSTORY",
            payload,
        )

    def backstory_fact(
        self,
        identity_seed: int,
        kind: str,
        tactical_class: str = "colonist",
        language: str = "EN",
        npc_id: str = "harness-backstory-npc",
        save_seed: str | int | None = None,
    ) -> dict[str, Any]:
        """Resolve one authoritative offline backstory fact in production Lua."""

        payload: dict[str, Any] = {
            "identitySeed": identity_seed,
            "kind": kind,
            "tacticalClass": tactical_class,
            "language": language,
            "npcID": npc_id,
        }
        if save_seed is not None:
            payload["saveSeed"] = save_seed
        return self._request(
            "BACKSTORY_FACT",
            payload,
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
        """Restart the isolated worker from its immutable imported source."""

        self.runtime.close()
        self.runtime.start()
        source = self.source_snapshot.to_dict()
        return self.import_source(
            source["data"],
            source=source["metadata"].get("sourceKind", Provenance.FIXTURE.value),
            source_id=source["metadata"].get("sourceID", "fixture:synthetic-scenario"),
            mode=source["metadata"].get("mode", "developer_test"),
            metadata=source["metadata"],
            provider_payloads=source["providerPayloads"],
        )

    def close(self) -> None:
        self.runtime.close()

    def __enter__(self) -> "LuaSemanticWorker":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

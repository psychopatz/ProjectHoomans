"""High-level session API backed by the real Lua semantic worker."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import replace
from pathlib import Path
from typing import Any

from .config import HarnessConfig
from .fixture_provider import OfflineEngineFixtureProvider
from .item_catalog import search_item_catalog
from .process import HarnessError, LuaProcess
from .scenario import load_scenario, normalize_scenario, validate_scenario
from .state import HarnessWorkingWorld, ImportedSourceSnapshot, Provenance
from .activity import ActivityLog, default_activity_path
from .worker_authoring import WorkerAuthoringOperations
from .worker_conversation import WorkerConversationOperations
from .worker_knowledge import WorkerKnowledgeOperations
from .worker_matrix import WorkerMatrixOperations
from .worker_sources import WorkerSourceOperations


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
        candidate_overlay_root: Path | None = None,
        candidate_overlay_module: str | None = None,
    ) -> None:
        scenario = normalize_scenario(scenario)
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
        if candidate_overlay_root is not None:
            root = Path(candidate_overlay_root).resolve(strict=True)
            if not root.is_dir():
                raise ValueError("candidate overlay must be a directory")
            self.config = replace(
                self.config, candidate_overlay_root=root,
                candidate_overlay_module=candidate_overlay_module
                    or ("PNC/Semantics/SemanticDialogueResponseCatalog/"
                        "PNC_SemanticDialogueResponseCatalog_FlowGreeting"),
            )
        self.activity_log = activity_log or ActivityLog(
            path=default_activity_path(self.config.repository),
            client="api",
        )
        self.runtime = LuaProcess(self.config, activity_log=self.activity_log)
        self._authoring = WorkerAuthoringOperations(self)
        self._conversation = WorkerConversationOperations(self)
        self._knowledge = WorkerKnowledgeOperations(self)
        self._matrix = WorkerMatrixOperations(self)
        self._sources = WorkerSourceOperations(self)
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

        scenario = normalize_scenario(scenario)
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

        scenario = normalize_scenario(scenario)
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
        snapshot_data = snapshot.to_dict()
        wire_provider_payloads = deepcopy(snapshot_data["providerPayloads"])
        project_hoomans = wire_provider_payloads.get("ProjectHoomans")
        raw_registries = (
            project_hoomans.get("rawRegistries")
            if isinstance(project_hoomans, dict)
            else None
        )
        if isinstance(raw_registries, dict) and raw_registries:
            # Faction/community registries are persisted source state, not a
            # Python projection. Install them through a bounded side request
            # so the selected NPC record and registry do not exceed the
            # worker's JSON-lines message limit together.
            raw_registries = deepcopy(raw_registries)
            raw_knowledge = raw_registries.pop("npcKnowledge", None)
            if raw_registries:
                self._request("INSTALL_PRODUCTION_REGISTRIES", raw_registries)
            if isinstance(raw_knowledge, dict):
                # Knowledge is a separate persisted registry and can be much
                # larger than the faction/community transport. Keep the raw
                # record intact while giving it its own bounded request.
                self._request("INSTALL_PRODUCTION_KNOWLEDGE", raw_knowledge)
            project_hoomans.pop("rawRegistries", None)
        project_zomboid = wire_provider_payloads.get("ProjectZomboid")
        item_type_fixture = (
            project_zomboid.get("itemTypeRegistry")
            if isinstance(project_zomboid, dict)
            else None
        )
        if (
            isinstance(item_type_fixture, dict)
            and isinstance(item_type_fixture.get("types"), list)
        ):
            # The engine item registry is a genuine offline PZ fixture. Install
            # it through its own bounded worker request so the raw save record
            # and registry do not compete for the single JSON-line size limit.
            self._request("INSTALL_ENGINE_ITEM_TYPES", item_type_fixture)
            if isinstance(project_zomboid, dict):
                project_zomboid.pop("itemTypeRegistry", None)
        wire_scenario = snapshot_data["data"]
        if str(snapshot_data["metadata"].get("sourceKind")) == "SAVE":
            # The selected NPC's persisted social graph is already carried in
            # ProjectHoomans.rawRecords and is consumed by production Lua.
            # Keep the detached request bounded when raw faction/community
            # registries are transported alongside it; the Python source
            # snapshot above remains complete for provenance and reset.
            wire_scenario = deepcopy(wire_scenario)
            if isinstance(wire_scenario.get("npc"), dict):
                wire_scenario["npc"].pop("social", None)
        response = self._request(
            "IMPORT_SOURCE",
            {
                "scenario": wire_scenario,
                "metadata": snapshot_data["metadata"],
                "provenance": snapshot_data["provenance"],
                "providerPayloads": wire_provider_payloads,
            },
        )
        # Keep provider projections available to the Python/UI read model. Lua
        # only needs the source metadata/provenance for its response, while
        # actor inspectors must be able to explain native SAVE/FIXTURE/LIVE
        # state without rereading or reinterpreting a source.
        if isinstance(response, dict):
            response_source = response.setdefault("sourceSnapshot", {})
            if isinstance(response_source, dict):
                response_source["providerPayloads"] = deepcopy(
                    snapshot.to_dict()["providerPayloads"]
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
        return self._conversation.input(text)

    def preview(self, text: str) -> dict[str, Any]:
        """Preview a production semantic turn without recording or dispatching it."""

        return self._conversation.preview(text)

    def suggestion_predicate(self, predicate: dict[str, Any]) -> dict[str, Any]:
        """Evaluate one production suggestion predicate against the public scenario projection."""

        return self._conversation.suggestion_predicate(predicate)

    def suggestion_click(self, frame: dict[str, Any]) -> dict[str, Any]:
        """Submit one canonical suggestion frame through the production input path."""

        return self._conversation.suggestion_click(frame)

    def set_language(self, language: str) -> dict[str, Any]:
        """Change the production translation manager language in this session."""

        return self._conversation.set_language(language)

    def tool_reply(
        self,
        results: list[dict[str, Any]],
        context: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Resolve a production dedicated tool reply through the real catalog."""

        return self._conversation.tool_reply(results, context)

    def interaction_envelope(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Build a canonical envelope in the production Lua lifecycle."""

        return self._request("INTERACTION_ENVELOPE", payload)

    def interaction_apply(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Apply one semantic interaction through production Lua."""

        return self._request("INTERACTION_APPLY", payload)

    def interaction_npc_speech(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Record NPC semantic speech provenance without rendered transcript."""

        return self._request("INTERACTION_NPC_SPEECH", payload)

    def interaction_close(self, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        return self._request("INTERACTION_CLOSE", payload or {})

    def interaction_resume(self, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        return self._request("INTERACTION_RESUME", payload or {})

    def interaction_compact(self, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        return self._request("INTERACTION_COMPACT", payload or {})

    def interaction_advance_time(self, world_hour: float) -> dict[str, Any]:
        return self._request("INTERACTION_ADVANCE_TIME", {"worldHour": world_hour})

    def interaction_metrics(self) -> dict[str, Any]:
        return self._request("INTERACTION_METRICS")

    def interaction_project(self, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        return self._request("INTERACTION_PROJECT", payload or {})

    def interaction_response_window(
        self, payload: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        """Inspect the bounded production response window, not a transcript."""

        return self._request("INTERACTION_RESPONSE_WINDOW", payload or {})

    def interaction_register_event(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Register one canonical shared event in production Lua."""

        return self._request("INTERACTION_REGISTER_EVENT", payload)

    def interaction_export(self) -> dict[str, Any]:
        """Export the bounded production lifecycle capsule, without text."""

        return self._request("INTERACTION_EXPORT")

    def interaction_import(self, snapshot: dict[str, Any]) -> dict[str, Any]:
        """Import a lifecycle capsule through production Lua validation."""

        return self._request("INTERACTION_IMPORT", {"snapshot": snapshot})

    def snapshot(self) -> dict[str, Any]:
        return self._conversation.snapshot()

    def _mutation_response(self, response: dict[str, Any]) -> dict[str, Any]:
        """Attach the authoritative post-mutation worker projection.

        Production conversation/action responses intentionally stay bounded and
        focus on the turn, action, and tool evidence.  The full simulation
        projection is owned by the worker snapshot, however, and is what the
        Lab workbench and CLI must render after a mutating command.  Merge that
        projection here so every caller observes the same production state
        without teaching Python any Project Hoomans gameplay semantics.
        """

        return self._conversation.mutation_response(response)

    def inspect_actor_state(self) -> dict[str, Any]:
        """Return bounded production actor state after an isolated mutation."""

        return self._conversation.inspect_actor_state()

    def inspect_npc_dossier(self) -> dict[str, Any]:
        """Return the production player-scoped NPC dossier and social history."""

        return self._conversation.inspect_npc_dossier()

    def relationship_proposal(self, npc_id: str | None = None) -> dict[str, Any]:
        """Submit the canonical proposal action to the server-authority seam."""

        return self._conversation.relationship_proposal(npc_id)

    def relationship_preview(
        self,
        relationship: dict[str, Any],
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Resolve staged relationship scores without mutating the scenario."""

        return self._conversation.relationship_preview(relationship, npc_id)

    def apply_runtime_relationship_baseline(
        self,
        relationship: dict[str, Any],
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Apply a production-owned relationship baseline to the working world.

        This command is deliberately separate from ``configure``.  SAVE
        configuration rehydrates from the immutable source; this operation
        asks the production relationship service to mutate only the isolated
        runtime record, which reset can later discard.
        """

        return self._conversation.apply_runtime_relationship_baseline(
            relationship, npc_id
        )

    def conversation_graph(self) -> dict[str, Any]:
        """Return the developer-only full selected ConversationBlock graph."""

        return self._conversation.conversation_graph()

    def conversation_projection(self) -> dict[str, Any]:
        """Return the production-owned native Conversation presentation."""

        return self._conversation.conversation_projection()

    def talk_projection(self) -> dict[str, Any]:
        """Compatibility alias for the production Talk presentation seam."""

        return self._conversation.talk_projection()

    def persona_catalog(
        self, register_relationship_kind: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        """Return the bounded catalog owned by the production Lua registries."""

        return self._conversation.persona_catalog(register_relationship_kind)

    def persona_preview(self, scenario: dict[str, Any]) -> dict[str, Any]:
        """Preview generated NPC personality for a staged scenario."""

        return self._conversation.persona_preview(scenario)

    def simulation_control_catalog(self) -> dict[str, Any]:
        """Return the worker-owned, bounded Semantic Lab control metadata."""

        return self._conversation.simulation_control_catalog()

    def talk_catalog(self) -> dict[str, Any]:
        """Return the production-owned native Talk target catalog."""

        return self._conversation.talk_catalog()

    def talk_start(
        self, target_id: str = "current", utterance: str = "hello"
    ) -> dict[str, Any]:
        """Start the native Talk parity projection for one target type."""

        return self._conversation.talk_start(target_id, utterance)

    def open_conversation(self, target_id: str = "current") -> dict[str, Any]:
        """Open the production Conversation session without submitting speech."""

        return self._conversation.open_conversation(target_id)

    def suspend_conversation(self) -> dict[str, Any]:
        return self._conversation.suspend_conversation()

    def resume_conversation(self) -> dict[str, Any]:
        return self._conversation.resume_conversation()

    def close_conversation(self, reason: str = "conversation_closed") -> dict[str, Any]:
        return self._conversation.close_conversation(reason)

    def conversation_emote(
        self,
        emote_id: str,
        *,
        topic: str | None = None,
        meaningful: bool = False,
    ) -> dict[str, Any]:
        return self._conversation.conversation_emote(
            emote_id, topic=topic, meaningful=meaningful
        )

    def talk_matrix(
        self,
        target_types: list[str] | None = None,
        text: str = "hello",
        maximum: int = 8,
    ) -> dict[str, Any]:
        """Compare native Talk startup and the first turn across target types."""

        return self._conversation.talk_matrix(target_types, text, maximum)

    def item_catalog(self, query: str = "", limit: int = 50) -> dict[str, Any]:
        """Search installed Project Zomboid item definitions for the Lab editor."""

        return self._conversation.item_catalog(query, limit)

    def save_catalog(self, roots: list[Path] | None = None) -> dict[str, Any]:
        return self._sources.save_catalog(roots)

    def offline_fixture_catalog(self) -> dict[str, Any]:
        """Describe editable engine-only values and their fixture provenance."""

        return self._sources.offline_fixture_catalog()

    def live_profiler_catalog(
        self,
        *,
        enabled: bool = False,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        return self._sources.live_profiler_catalog(
            enabled=enabled,
            snapshot_path=snapshot_path,
            config_path=config_path,
            npc_id=npc_id,
        )

    def enrich_from_live_profiler(
        self,
        *,
        enabled: bool = False,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        player_id: str | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        return self._sources.enrich_from_live_profiler(
            enabled=enabled,
            snapshot_path=snapshot_path,
            config_path=config_path,
            player_id=player_id,
            npc_id=npc_id,
        )

    def save_browser(self, save_path: Path) -> dict[str, Any]:
        return self._sources.save_browser(save_path)

    def import_saved_selection(
        self,
        save_path: Path,
        *,
        player_uuid: str | None = None,
        npc_id: str | None = None,
        engine_fixtures: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self._sources.import_saved_selection(
            save_path,
            player_uuid=player_uuid,
            npc_id=npc_id,
            engine_fixtures=engine_fixtures,
        )

    def context_matrix(
        self,
        scenarios: list[dict[str, Any]],
        text: str = "hello",
        maximum: int = 8,
    ) -> dict[str, Any]:
        return self._matrix.context_matrix(scenarios, text, maximum)

    def capture_baseline(self, text: str) -> dict[str, Any]:
        return self._matrix.capture_baseline(text)

    def apply_and_replay(self, text: str) -> dict[str, Any]:
        return self._matrix.apply_and_replay(text)

    def knowledge_bootstrap(
        self, request_id: str = "harness-knowledge-bootstrap"
    ) -> dict[str, Any]:
        return self._knowledge.knowledge_bootstrap(request_id)

    def knowledge_metrics(
        self, synthetic_npcs: int = 0, facts_per_npc: int = 1
    ) -> dict[str, Any]:
        return self._knowledge.knowledge_metrics(synthetic_npcs, facts_per_npc)

    def world_knowledge_inspect(
        self, actor_id: str | None = None, fact_id: str | None = None,
        max_facts: int = 32,
    ) -> dict[str, Any]:
        return self._knowledge.world_knowledge_inspect(actor_id, fact_id, max_facts)

    def world_knowledge_propagate(
        self, from_actor_id: str, to_actor_id: str,
        channel: str = "conversation", authorized: bool = True,
        now: float = 1000,
    ) -> dict[str, Any]:
        return self._knowledge.world_knowledge_propagate(
            from_actor_id, to_actor_id, channel, authorized, now
        )

    def knowledge_discover(
        self, topic_id: str, npc_id: str | None = None
    ) -> dict[str, Any]:
        return self._knowledge.knowledge_discover(topic_id, npc_id)

    def replay_quest_request(self, request: dict[str, Any]) -> dict[str, Any]:
        return self._knowledge.replay_quest_request(request)

    def commitment(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._knowledge.commitment(payload)

    def backstory(
        self,
        identity_seed: int,
        tactical_class: str = "colonist",
        npc_id: str = "harness-backstory-npc",
        save_seed: str | int | None = None,
    ) -> dict[str, Any]:
        return self._knowledge.backstory(
            identity_seed, tactical_class, npc_id, save_seed
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
        return self._knowledge.backstory_fact(
            identity_seed, kind, tactical_class, language, npc_id, save_seed
        )

    def flow_catalog(self) -> dict[str, Any]:
        return self._authoring.flow_catalog()

    def response_key_lookup(self, key: str) -> dict[str, Any]:
        return self._authoring.response_key_lookup(key)

    def response_pool_list(
        self, *, filter: str = "", offset: int = 0, limit: int = 32
    ) -> dict[str, Any]:
        return self._authoring.response_pool_list(
            filter=filter, offset=offset, limit=limit
        )

    def explain_response_selection(
        self, pool_id: str, context: dict[str, Any], salt: str = ""
    ) -> dict[str, Any]:
        return self._authoring.explain_response_selection(pool_id, context, salt)

    def sample_response_selection(
        self, pool_id: str, context: dict[str, Any], salt: str = ""
    ) -> dict[str, Any]:
        return self._authoring.sample_response_selection(pool_id, context, salt)

    def response_pool_detail(
        self, pool_id: str, *, offset: int = 0, limit: int = 8
    ) -> dict[str, Any]:
        return self._authoring.response_pool_detail(
            pool_id, offset=offset, limit=limit
        )

    def fact_catalog(self) -> list[dict[str, Any]]:
        return self._authoring.fact_catalog()

    def event_catalog(self) -> list[dict[str, Any]]:
        return self._authoring.event_catalog()

    def validate_flow(self, definition: dict[str, Any]) -> dict[str, Any]:
        return self._authoring.validate_flow(definition)

    def register_flow(self, definition: dict[str, Any]) -> dict[str, Any]:
        return self._authoring.register_flow(definition)

    def generate_flows(self) -> dict[str, Any]:
        return self._authoring.generate_flows()

    def flow_coverage(self) -> list[dict[str, Any]]:
        return self._authoring.flow_coverage()

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

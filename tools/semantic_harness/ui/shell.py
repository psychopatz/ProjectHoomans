"""Tk adapter for the real-Lua semantic dialogue worker."""

from __future__ import annotations

import argparse
import sys
from copy import deepcopy
from concurrent.futures import Future
from pathlib import Path
from typing import Any, Callable

from ..inspection.conversation_inspector import build_conversation_inspector
from ..inspection.world_knowledge import build_world_knowledge_inspector
from ..codebuilder.service import SemanticLabAuthoringService
from ..studio.block_registry import SemanticBlockRegistryPane
from ..studio.dataset_library import DatasetLibraryPane
from .flow_editor.pane import FlowEditorPane
from .conversation_graph import ConversationGraphPane
from ..studio.interaction_explorer_pane import InteractionExplorerPane
from ..studio.interaction_spec_pane import InteractionSpecPane
from ..inspection.rendering import conversation_first, pretty
from ..inspection.tool_calls import format_tool_call
from ..runtime.config import ConfigurationError
from ..runtime.npc_profiles import (
    PROFILE_IDS,
    apply_npc_profile,
    profile_id,
    profile_label,
)
from ..runtime.scenario import (
    derive_actor_identifier,
    derive_display_name,
    load_scenario,
    merge,
    save_scenario,
)
from .dialogs.catalog_control import CatalogControlField
from .dialogs.settings import (
    collect_scenario_settings,
    open_runtime_settings as show_runtime_settings,
)
from ..inspection.transcript import TranscriptBuffer
from ..runtime.worker import HarnessError, LuaSemanticWorker
from ..runtime.worker_session import WorkerReady, WorkerResult, WorkerSession
from ..runtime.activity import (
    ActivityLog,
    default_activity_path,
    format_activity_event,
)
from ..studio.workflow import SemanticLabWorkflowPane
from .state import load as load_ui_state
from .state import save as save_ui_state
from .state import state_path as ui_state_path
from .workbench import WorkbenchPage


def npc_message_text(message: dict[str, Any]) -> str:
    """Return rendered production text before its English fallback."""

    payload = message.get("payload") or message.get("value") or {}
    if isinstance(payload, str):
        return payload
    return str(payload.get("text") or payload.get("fallback") or "")


def semantic_suggestion_rows(
    suggestions: dict[str, Any], group_id: str | None = None
) -> list[dict[str, Any]]:
    """Build the bounded visual slice from the production projection."""

    # Production Lua owns the privacy/performance bound. The Tk adapter must
    # render every row in the selected group, including capability rows, so
    # the old five-slot prototype cannot silently discard safe choices.
    groups = suggestions.get("groups") or []
    selected = None
    if groups:
        requested = group_id or suggestions.get("currentGroupID")
        selected = next(
            (group for group in groups if group.get("id") == requested),
            None,
        )
        if selected is None:
            selected = groups[0]
    candidates = (
        selected.get("candidates") if selected is not None
        else suggestions.get("candidates")
    ) or []
    capabilities = (
        selected.get("capabilities") if selected is not None
        else suggestions.get("permittedCapabilities")
    ) or []
    rows: list[dict[str, Any]] = []
    for navigation in (
        selected.get("navigation") if selected is not None else []
    ) or []:
        rows.append(
            {
                "id": navigation.get("id"),
                "frame": navigation.get("frame"),
                "display": navigation.get("display") or {},
                "status": "navigation",
                "enabled": True,
                "source": navigation.get("source"),
                "groupID": selected.get("id") if selected else None,
            }
        )
    for candidate in candidates:
        rows.append(
            {
                "id": candidate.get("id"),
                "frame": candidate.get("frame"),
                "display": candidate.get("display") or {},
                "status": "eligible",
                "enabled": candidate.get("enabled", True) is not False,
                "eligibility": candidate.get("eligibility"),
                "source": candidate.get("source"),
                "groupID": selected.get("id") if selected else candidate.get("groupID"),
            }
        )
    for capability in capabilities:
        status = capability.get("status") or "unavailable_unknown"
        rows.append(
            {
                "id": capability.get("id"),
                "action": capability.get("action"),
                "frame": capability.get("frame"),
                "display": capability.get("display") or {},
                "status": status,
                "enabled": status in {"eligible", "selected_for_preflight"},
                "source": capability.get("source"),
                "eligibility": capability.get("eligibility"),
                "groupID": selected.get("id") if selected else capability.get("groupID"),
            }
        )
    return rows


def semantic_suggestion_title(row: dict[str, Any]) -> str:
    display = row.get("display") or {}
    return str(
        display.get("label")
        or display.get("labelFallback")
        or display.get("utterance")
        or display.get("utteranceFallback")
        or row.get("id")
        or row.get("action")
        or "Suggestion"
    )


def semantic_hub_diagnostic_projection(
    suggestions: dict[str, Any],
) -> dict[str, Any]:
    """Project only player-safe hub candidates into the developer inspector."""

    suggestions = suggestions if isinstance(suggestions, dict) else {}
    active_hub = suggestions.get("activeHub")
    if not isinstance(active_hub, dict) or active_hub.get("route") != "semantic_hub":
        return {"activeHub": None, "candidateCount": 0, "candidates": []}
    privacy = suggestions.get("privacy")
    privacy = privacy if isinstance(privacy, dict) else {}
    if (
        privacy.get("playerVisible") is not True
        or privacy.get("privateFieldsInspected") is not False
        or privacy.get("unknownFieldsExposed") is not False
    ):
        return {
            "activeHub": deepcopy(active_hub),
            "candidateCount": 0,
            "candidates": [],
            "diagnosticsHidden": True,
            "reason": "player_safe_projection_unavailable",
        }

    candidates: list[dict[str, Any]] = []

    def public_reason(value: Any) -> str | None:
        reason = str(value or "")
        if not reason:
            return None
        safe_reasons = {
            "candidate_not_eligible": "candidate not eligible in current public context",
            "non_hostile_public_context": "non-hostile public topic",
            "safe_public_weather_context": "safe public weather topic",
            "player_safe_gossip_available": "player-safe gossip context available",
            "safe_gossip_unavailable": "player-safe gossip context unavailable",
            "owned_companion_context": "eligible companion context",
            "owned_companion_required": "eligible companion context required",
            "trusted_close_relationship": "personal avenue permitted by disclosure policy",
        }
        return safe_reasons.get(reason, "contextual eligibility policy")

    for candidate in (suggestions.get("candidates") or [])[:32]:
        if not isinstance(candidate, dict) or candidate.get("visibility") == "private":
            continue
        frame = candidate.get("frame")
        frame = frame if isinstance(frame, dict) else {}
        extensions = frame.get("extensions")
        extensions = extensions if isinstance(extensions, dict) else {}
        display = candidate.get("display")
        display = display if isinstance(display, dict) else {}
        eligibility = candidate.get("eligibility")
        eligibility = eligibility if isinstance(eligibility, dict) else {}
        ranking = candidate.get("ranking")
        ranking = ranking if isinstance(ranking, dict) else {}
        is_eligible = (
            eligibility.get("allowed") is True
            and candidate.get("enabled") is not False
            and eligibility.get("status") not in {"hidden", "denied", "blocked"}
        )
        candidates.append(
            {
                "candidateID": candidate.get("id"),
                "providerID": candidate.get("providerID") or frame.get("providerID"),
                "semanticOwner": candidate.get("semanticOwner"),
                "rank": candidate.get("rank"),
                "rankClass": ranking.get("class") or "UNCLASSIFIED",
                "eligibility": "eligible" if is_eligible else "hidden",
                "eligibilityStatus": eligibility.get("status") or "unknown",
                "hiddenReason": (
                    None
                    if is_eligible
                    else public_reason(
                        candidate.get("hiddenReason")
                        or eligibility.get("reason")
                        or "candidate_not_eligible"
                    )
                ),
                "contextReason": public_reason(
                    candidate.get("contextReason") or eligibility.get("reason")
                ),
                "translationKeys": {
                    "label": display.get("labelKey"),
                    "utterance": display.get("utteranceKey"),
                },
                "resolvedLabel": display.get("label")
                or display.get("labelFallback")
                or candidate.get("id"),
                "resolvedUtterance": display.get("utterance")
                or display.get("utteranceFallback"),
                "semanticDestination": {
                    "route": extensions.get("route"),
                    "hubID": extensions.get("hubID") or active_hub.get("id"),
                    "topic": candidate.get("topic") or extensions.get("topic"),
                    "subject": frame.get("subject"),
                    "speechAct": frame.get("speechAct"),
                },
                "semanticFrame": deepcopy(frame),
            }
        )
    return {
        "activeHub": deepcopy(active_hub),
        "candidateCount": len(candidates),
        "candidates": candidates,
        "privacySafe": True,
    }


class SemanticHarnessApp:
    """Nonblocking Tk adapter over the same session API used by the CLI."""

    def __init__(self, root: Any, arguments: argparse.Namespace) -> None:
        import tkinter as tk
        from tkinter import filedialog, messagebox, ttk
        from tkinter.scrolledtext import ScrolledText

        self.root = root
        self._tk = tk
        self._filedialog = filedialog
        self._messagebox = messagebox
        self._ttk = ttk
        self._ScrolledText = ScrolledText
        self.arguments = arguments
        repository = Path(arguments.repository) if arguments.repository else None
        self.authoring_service = SemanticLabAuthoringService(
            repository=repository,
            runtime_root=repository,
        )
        self.activity_log = ActivityLog(
            path=default_activity_path(
                self.authoring_service.repository,
                getattr(arguments, "activity_log", None),
            ),
            client="gui",
        )
        self._activity_seen_ids: set[str] = set()
        self._activity_after: Any | None = None
        self.ui_state_path = ui_state_path(
            self.authoring_service.repository,
            Path(arguments.scenario).expanduser() if arguments.scenario else None,
            getattr(arguments, "ui_state", None),
        )
        self._ui_state = load_ui_state(self.ui_state_path)
        self.root.title("Project Hoomans Semantic Lab")
        self.root.minsize(1080, 700)
        # Keep the initial window inside a typical desktop work area.  Users
        # can still enlarge it, but a fixed 860px height starts below the
        # fold on common 768px-tall displays.
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        initial_width = min(1320, max(1080, screen_width - 48))
        initial_height = min(860, max(700, screen_height - 96))
        saved_geometry = self._ui_state.get("geometry")
        if isinstance(saved_geometry, str) and saved_geometry:
            self.root.geometry(saved_geometry)
        else:
            self.root.geometry(f"{initial_width}x{initial_height}")
        self.scenario_path = Path(arguments.scenario) if arguments.scenario else None
        self.scenario = load_scenario(self.scenario_path)
        if arguments.language:
            self.scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
        # Keep the executor's startup factory independent of the Tk app. A
        # bound closure over ``self`` would let the worker thread release the
        # entire widget tree during shutdown, which is unsafe for Tk
        # Variables and makes repeated GUI tests nondeterministic.
        startup_scenario = self.scenario
        startup_kwargs = self._worker_kwargs()
        self.session = WorkerSession(
            lambda: LuaSemanticWorker(startup_scenario, **startup_kwargs)
        )
        self.closed = False
        self.busy = False
        # WorkerSession marks its future ready before the Tk callback paints
        # the initial production surface. Keep the UI-facing readiness bit
        # separate so callers cannot submit during that short handoff.
        self._worker_initialized = False
        self._production_catalog: dict[str, Any] | None = None
        self.saved_catalog: dict[str, Any] = {}
        self.saved_world_browser: dict[str, Any] = {}
        self.saved_world_entries: list[dict[str, Any]] = []
        self.saved_world_category_rows: dict[str, list[dict[str, Any]]] = {}
        self.saved_world_save_labels: dict[str, dict[str, Any]] = {}
        self.persona_catalog: dict[str, Any] = {}
        self.simulation_control_catalog: dict[str, Any] = {}
        self.talk_catalog: dict[str, Any] = {}
        self.talk_target_ids_by_label: dict[str, str] = {}
        self.simulation_projection: dict[str, Any] = {}
        self.source_snapshot_projection: dict[str, Any] = {}
        self.working_world_projection: dict[str, Any] = {}
        self.provenance_projection: dict[str, Any] = {}
        self.settings_variables: dict[str, Any] = {}
        self.settings_control_widgets: dict[str, Any] = {}
        self.settings_control_fields: dict[str, Any] = {}
        self.workbench_control_fields: dict[str, CatalogControlField] = {}
        self.workbench_controls: list[dict[str, Any]] = []
        self.workbench_panel_notebooks: dict[str, Any] = {}
        self.workbench_expanded = True
        self.last_test_utterance = ""
        self.workbench_status_var: Any | None = None
        self.relationship_preview_var: Any | None = None
        self.trait_effects_var: Any | None = None
        self.trait_effects_widget: Any | None = None
        self.trait_effects_widgets: dict[str, Any] = {}
        self.player_social_profile_preview: dict[str, Any] = {}
        self.player_trait_conflicts: list[Any] = []
        self.player_trait_fingerprint = ""
        self.auto_replay_var: Any | None = None
        self._relationship_preview_after: Any | None = None
        self._personality_preview_after: Any | None = None
        self._auto_replay_after: Any | None = None
        self._auto_apply_after: Any | None = None
        self._splitter_restore_after: Any | None = None
        self.replay_steps: list[dict[str, Any]] = []
        self._relationship_preview_future: Future[Any] | None = None
        self._personality_preview_future: Future[Any] | None = None
        self.generated_personality_preview: dict[str, Any] = {}
        self._workbench_dirty_ids: set[str] = set()
        self._workbench_profile_pending = False
        self._workbench_initializing = False
        self.last_response: dict[str, Any] = {}
        self.settings_window: Any | None = None
        self._future: Future[Any] | None = None
        self._transcript_buffer = TranscriptBuffer()
        self.baseline_record: dict[str, Any] = {}
        self.activity_log.record(
            "ui",
            "window_start",
            geometry=self.root.geometry(),
            state_path=str(self.ui_state_path),
            activity_path=str(self.activity_log.path or ""),
        )
        self._build_ui()
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        self._set_status("Starting Lua worker…")
        self.root.after(20, self._start_worker)

    def _build_ui(self) -> None:
        ttk = self._ttk
        ScrolledText = self._ScrolledText
        self.main_tabs = ttk.Notebook(self.root)
        self.main_tabs.pack(fill="both", expand=True, padx=6, pady=6)

        studio_tab = ttk.Frame(self.main_tabs, padding=6)
        simulation_tab = ttk.Frame(self.main_tabs, padding=8)
        studio_tab.rowconfigure(0, weight=1)
        studio_tab.columnconfigure(0, weight=1)
        simulation_tab.rowconfigure(0, weight=1)
        simulation_tab.columnconfigure(0, weight=1)
        studio_notebook = ttk.Notebook(studio_tab)
        self.studio_notebook = studio_notebook
        studio_notebook.grid(row=0, column=0, sticky="nsew")
        workflow_tab = ttk.Frame(studio_notebook, padding=8)
        editor_tab = ttk.Frame(studio_notebook, padding=8)
        library_tab = ttk.Frame(studio_notebook, padding=8)
        blocks_tab = ttk.Frame(studio_notebook, padding=8)
        composer_tab = ttk.Frame(studio_notebook, padding=8)
        for panel in (workflow_tab, editor_tab, library_tab, blocks_tab, composer_tab):
            panel.rowconfigure(0, weight=1)
            panel.columnconfigure(0, weight=1)
        studio_notebook.add(workflow_tab, text="Build workflow")
        studio_notebook.add(editor_tab, text="Flow + interactions")
        studio_notebook.add(library_tab, text="Dataset library")
        studio_notebook.add(blocks_tab, text="Block palette")
        studio_notebook.add(composer_tab, text="Interaction composer")
        log_tab = ttk.Frame(self.main_tabs, padding=8)
        log_tab.rowconfigure(1, weight=1)
        log_tab.columnconfigure(0, weight=1)
        self.activity_log_status = self._tk.StringVar(
            value="Shared GUI/CLI activity timeline"
        )
        log_toolbar = ttk.Frame(log_tab)
        log_toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        ttk.Label(
            log_toolbar,
            textvariable=self.activity_log_status,
            anchor="w",
        ).pack(side="left", fill="x", expand=True)
        ttk.Button(
            log_toolbar,
            text="Clear view",
            command=self.clear_activity_log,
        ).pack(side="right")
        self.activity_log_widget = ScrolledText(
            log_tab,
            wrap="none",
            state="disabled",
        )
        self.activity_log_widget.grid(row=1, column=0, sticky="nsew")

        # Keep the primary workflow order stable: Simulation, Studio, Log.
        self.main_tabs.add(simulation_tab, text="Simulation")
        self.main_tabs.add(studio_tab, text="Studio")
        self.main_tabs.add(log_tab, text="Log")
        self.studio_tab = studio_tab
        self.log_tab = log_tab

        container = ttk.Frame(simulation_tab)
        container.pack(fill="both", expand=True)
        container.rowconfigure(0, weight=1)
        container.columnconfigure(0, weight=1)
        self.simulation_panes = ttk.PanedWindow(container, orient="horizontal")
        self.simulation_panes.grid(row=0, column=0, sticky="nsew")
        workflow_pane = ttk.Frame(self.simulation_panes)
        workflow_pane.rowconfigure(0, weight=1)
        workflow_pane.columnconfigure(0, weight=1)
        self.workflow_pane_split = ttk.PanedWindow(
            workflow_pane, orient="vertical"
        )
        self.workflow_pane_split.grid(row=0, column=0, sticky="nsew")
        conversation_pane = ttk.Frame(self.workflow_pane_split)
        conversation_pane.rowconfigure(0, weight=1)
        conversation_pane.columnconfigure(0, weight=1)
        workbench_pane = ttk.Frame(self.workflow_pane_split)
        workbench_pane.rowconfigure(0, weight=1)
        workbench_pane.columnconfigure(0, weight=1)
        self.simulation_panes.add(workflow_pane, weight=3)

        transcript_frame = ttk.LabelFrame(conversation_pane, text="Conversation")
        transcript_frame.grid(row=0, column=0, sticky="nsew")
        transcript_frame.rowconfigure(0, weight=1)
        transcript_frame.columnconfigure(0, weight=1)
        self.transcript = ScrolledText(transcript_frame, wrap="word", state="disabled")
        self.transcript.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        suggestion_frame = ttk.LabelFrame(
            transcript_frame, text="Contextual semantic suggestions"
        )
        suggestion_frame.grid(row=1, column=0, sticky="ew", padx=6, pady=(0, 6))
        # Let the panel size itself to the visible rows.  The old fixed
        # height reserved five button slots even when a topic had one choice,
        # pushing the input and toolbar below the fold at normal window sizes.
        suggestion_frame.grid_propagate(True)
        self.suggestion_frame = suggestion_frame
        for column in range(3):
            suggestion_frame.columnconfigure(column, weight=1)
        self.suggestion_buttons: list[Any] = []
        self.suggestion_buttons_frame = ttk.Frame(suggestion_frame)
        self.suggestion_buttons_frame.grid(
            row=0, column=0, columnspan=3, sticky="ew", padx=3, pady=3
        )
        for column in range(3):
            self.suggestion_buttons_frame.columnconfigure(column, weight=1)
        self.suggestion_rows: list[dict[str, Any]] = []
        self.suggestion_interactive = False
        self.suggestion_projection: dict[str, Any] = {}
        self.suggestion_response: dict[str, Any] = {}
        self.suggestion_revision: Any = None
        self.suggestion_group_ids_by_display: dict[str, str] = {}
        self.suggestion_status = ttk.Label(
            suggestion_frame,
            text="Run a production preview or turn to inspect suggestions.",
        )
        self.suggestion_status.grid(
            row=1, column=0, columnspan=2, sticky="w", padx=4, pady=(0, 2)
        )
        self.suggestion_group_box = self._ttk.Combobox(
            suggestion_frame,
            state="readonly",
            width=24,
        )
        self.suggestion_group_box.grid(
            row=1, column=2, sticky="e", padx=3, pady=(0, 2)
        )
        self.suggestion_group_box.bind(
            "<<ComboboxSelected>>", lambda _: self._on_suggestion_group()
        )

        self.input_var = self._tk.StringVar()
        input_box = ttk.Entry(transcript_frame, textvariable=self.input_var)
        input_box.grid(row=2, column=0, sticky="ew", padx=6, pady=(0, 6))
        input_box.bind("<Return>", lambda _: self.submit())
        input_actions = ttk.Frame(transcript_frame)
        input_actions.grid(row=3, column=0, sticky="ew", padx=6, pady=(0, 6))
        input_actions.columnconfigure(0, weight=1)
        self.preview_button = ttk.Button(
            input_actions, text="Preview", command=self.preview
        )
        self.preview_button.grid(row=0, column=1, sticky="e", padx=(0, 4))
        self.send_button = ttk.Button(input_actions, text="Send", command=self.submit)
        self.send_button.grid(row=0, column=2, sticky="e")

        self.simulation_workbench = ttk.Frame(workbench_pane)
        self.simulation_workbench.grid(
            row=0, column=0, sticky="nsew"
        )
        self.simulation_workbench.columnconfigure(0, weight=1)
        self.simulation_workbench.rowconfigure(1, weight=1)
        workbench_header = ttk.Frame(self.simulation_workbench)
        workbench_header.grid(row=0, column=0, sticky="ew")
        workbench_header.columnconfigure(4, weight=1)
        ttk.Label(
            workbench_header,
            text="Simulation workbench",
            font=("TkDefaultFont", 10, "bold"),
        ).grid(row=0, column=0, sticky="w", padx=(2, 10))
        ttk.Label(workbench_header, text="NPC profile").grid(
            row=0, column=1, sticky="e", padx=(0, 4)
        )
        self.npc_profile_var = self._tk.StringVar(
            value=profile_label(profile_id(self.scenario))
        )
        self.npc_profile_box = ttk.Combobox(
            workbench_header,
            textvariable=self.npc_profile_var,
            values=tuple(profile_label(value) for value in PROFILE_IDS),
            width=22,
            state="readonly",
        )
        self.npc_profile_box.grid(row=0, column=2, sticky="w", padx=(0, 8))
        self.npc_profile_box.bind("<<ComboboxSelected>>", lambda _: self._on_npc_profile())
        self.workbench_toggle_button = ttk.Button(
            workbench_header,
            text="Hide controls",
            command=self.toggle_simulation_workbench,
        )
        self.workbench_toggle_button.grid(row=0, column=5, sticky="e")
        self.workbench_content = ttk.Frame(self.simulation_workbench)
        self.workbench_content.grid(row=1, column=0, sticky="nsew", pady=(3, 0))
        self.workbench_content.columnconfigure(0, weight=1)
        self.workbench_content.rowconfigure(0, weight=1)
        self.workbench_notebook = ttk.Notebook(self.workbench_content)
        self.workbench_notebook.grid(row=0, column=0, sticky="nsew")
        self.workbench_status_var = self._tk.StringVar(
            value="Common context controls · changes apply through the Lua worker."
        )
        workbench_footer = ttk.Frame(self.workbench_content)
        workbench_footer.grid(row=1, column=0, sticky="ew", pady=(3, 0))
        workbench_footer.columnconfigure(0, weight=1)
        workbench_footer.columnconfigure(1, weight=1)
        ttk.Label(
            workbench_footer,
            textvariable=self.workbench_status_var,
            anchor="w",
            justify="left",
            wraplength=620,
        ).grid(row=0, column=0, sticky="ew", pady=(0, 3))
        self.provenance_status_var = self._tk.StringVar(
            value="Source provenance: FIXTURE · isolated working world"
        )
        ttk.Label(
            workbench_footer,
            textvariable=self.provenance_status_var,
            anchor="w",
            justify="left",
            wraplength=620,
        ).grid(row=0, column=1, sticky="ew", padx=(12, 0), pady=(0, 3))
        workbench_actions = ttk.Frame(workbench_footer)
        workbench_actions.grid(row=1, column=0, sticky="ew")
        self.workbench_apply_button = ttk.Button(
            workbench_actions,
            text="Apply",
            command=self.apply_simulation_settings,
        )
        self.workbench_apply_button.grid(row=0, column=0, sticky="w")
        self.replay_button = ttk.Button(
            workbench_actions,
            text="Apply + replay",
            command=self.apply_and_replay,
        )
        self.replay_button.grid(row=0, column=1, sticky="w", padx=(6, 0))
        self.auto_replay_var = self._tk.BooleanVar(value=False)
        self.auto_replay_checkbutton = ttk.Checkbutton(
            workbench_actions,
            text="Auto replay (debounced)",
            variable=self.auto_replay_var,
        )
        self.auto_replay_checkbutton.grid(row=0, column=2, sticky="w", padx=(10, 0))
        workbench_actions.columnconfigure(3, weight=1)

        controls = ttk.Frame(workbench_pane)
        controls.grid(row=1, column=0, sticky="ew", pady=(4, 0))
        controls.columnconfigure(0, weight=1)
        controls.columnconfigure(1, weight=0)
        action_controls = ttk.Frame(controls)
        action_controls.grid(row=0, column=0, columnspan=2, sticky="ew")
        primary_actions = ttk.Frame(action_controls)
        primary_actions.grid(row=0, column=0, sticky="ew")
        primary_actions.columnconfigure(0, weight=1)
        primary_actions.columnconfigure(1, weight=1)
        primary_actions.columnconfigure(2, weight=1)
        primary_actions.columnconfigure(3, weight=1)
        secondary_actions = ttk.Frame(action_controls)
        secondary_actions.grid(row=1, column=0, sticky="ew", pady=(4, 0))
        runtime_controls = ttk.Frame(controls)
        runtime_controls.grid(row=1, column=0, sticky="ew", pady=(4, 0))
        status_controls = ttk.Frame(controls)
        status_controls.grid(row=1, column=1, sticky="e", padx=(8, 0), pady=(4, 0))
        self.reset_button = ttk.Button(primary_actions, text="Reset", command=self.reset)
        self.reset_button.grid(row=0, column=0, sticky="ew", padx=(0, 3))
        self.load_button = ttk.Button(primary_actions, text="Load scenario", command=self.load)
        self.load_button.grid(row=0, column=1, sticky="ew", padx=3)
        self.settings_button = ttk.Button(
            primary_actions, text="Simulation settings…", command=self.open_runtime_settings
        )
        self.settings_button.grid(row=0, column=2, sticky="ew", padx=3)
        self.save_button = ttk.Button(primary_actions, text="Save scenario", command=self.save)
        self.save_button.grid(row=0, column=3, sticky="ew", padx=(3, 0))
        saved_world = ttk.LabelFrame(
            controls,
            text="Saved world · read-only source",
            padding=(4, 3),
        )
        saved_world.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(5, 0))
        saved_world.columnconfigure(1, weight=1)
        saved_world.columnconfigure(4, weight=1)
        saved_world.columnconfigure(7, weight=1)
        self.saved_world_save_var = self._tk.StringVar(value="")
        self.saved_world_player_var = self._tk.StringVar(value="")
        self.saved_world_category_var = self._tk.StringVar(value="All NPCs")
        self.saved_world_npc_var = self._tk.StringVar(value="")
        ttk.Label(saved_world, text="Save").grid(row=0, column=0, padx=(0, 4))
        self.saved_world_save_box = ttk.Combobox(
            saved_world,
            textvariable=self.saved_world_save_var,
            state="disabled",
            width=34,
        )
        self.saved_world_save_box.grid(row=0, column=1, sticky="ew", padx=(0, 5))
        self.saved_world_discover_button = ttk.Button(
            saved_world,
            text="Discover saves",
            command=self._discover_saved_worlds,
        )
        self.saved_world_discover_button.grid(row=0, column=2, padx=(0, 8))
        ttk.Label(saved_world, text="Player").grid(row=0, column=3, padx=(0, 4))
        self.saved_world_player_box = ttk.Combobox(
            saved_world,
            textvariable=self.saved_world_player_var,
            state="disabled",
            width=20,
        )
        self.saved_world_player_box.grid(row=0, column=4, sticky="ew", padx=(0, 5))
        ttk.Label(saved_world, text="NPC group").grid(row=0, column=5, padx=(0, 4))
        self.saved_world_category_box = ttk.Combobox(
            saved_world,
            textvariable=self.saved_world_category_var,
            state="disabled",
            width=16,
        )
        self.saved_world_category_box.grid(row=0, column=6, padx=(0, 5))
        self.saved_world_category_box.bind(
            "<<ComboboxSelected>>", lambda _: self._on_saved_world_category()
        )
        ttk.Label(saved_world, text="NPC").grid(row=0, column=7, padx=(0, 4))
        self.saved_world_npc_box = ttk.Combobox(
            saved_world,
            textvariable=self.saved_world_npc_var,
            state="disabled",
            width=24,
        )
        self.saved_world_npc_box.grid(row=0, column=8, sticky="ew", padx=(0, 5))
        self.saved_world_inspect_button = ttk.Button(
            saved_world,
            text="Inspect",
            command=self._inspect_saved_world,
        )
        self.saved_world_inspect_button.grid(row=0, column=9, padx=(0, 4))
        self.saved_world_import_button = ttk.Button(
            saved_world,
            text="Import target",
            command=self._import_saved_world_target,
        )
        self.saved_world_import_button.grid(row=0, column=10)
        self.saved_world_status_var = self._tk.StringVar(
            value="Discover saves to browse persisted Players, NPCs, factions, and communities."
        )
        ttk.Label(
            saved_world,
            textvariable=self.saved_world_status_var,
            anchor="w",
        ).grid(row=1, column=0, columnspan=11, sticky="ew", pady=(3, 0))
        self.language_var = self._tk.StringVar(
            value=self.scenario.get("runtime", {}).get("language", "EN")
        )
        self.language_box: Any | None = None
        self.compare_utterance_var = self._tk.StringVar(value="hello")
        self.matrix_dimension_var = self._tk.StringVar(value="persona")
        self.talk_utterance_var = self._tk.StringVar(
            value=str(self._ui_state.get("talk_utterance") or "hello")
        )
        self.talk_target_var = self._tk.StringVar(value="Current target")
        self.status_var = self._tk.StringVar(value="Starting…")
        self.status_label = ttk.Label(status_controls, textvariable=self.status_var)
        self.status_label.pack(anchor="e")

        right = ttk.LabelFrame(self.simulation_panes, text="Semantic trace")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self.simulation_panes.add(right, weight=2)
        self.workflow_pane_split.add(conversation_pane, weight=3)
        self.workflow_pane_split.add(workbench_pane, weight=2)
        self.trace_tabs = ttk.Notebook(right)
        self.trace_tabs.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        dialogue_graph_frame = ttk.Frame(self.trace_tabs)
        dialogue_graph_frame.rowconfigure(0, weight=1)
        dialogue_graph_frame.columnconfigure(0, weight=1)
        self.dialogue_graph_pane = ConversationGraphPane(
            dialogue_graph_frame, self._tk, ttk,
            on_click=self.click_graph_frame,
            on_diagnostics=self.show_conversation_graph_diagnostics,
        )
        self.trace_tabs.add(dialogue_graph_frame, text="Dialogue graph")
        self.dialogue_graph_frame = dialogue_graph_frame

        hub_diagnostics_frame = ttk.Frame(self.trace_tabs)
        hub_diagnostics_frame.rowconfigure(0, weight=1)
        hub_diagnostics_frame.columnconfigure(0, weight=1)
        self.hub_diagnostics = ScrolledText(
            hub_diagnostics_frame, wrap="none", state="disabled"
        )
        self.hub_diagnostics.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(hub_diagnostics_frame, text="Hub diagnostics")
        self.hub_diagnostics_frame = hub_diagnostics_frame

        dialogue_diagnostics_frame = ttk.Frame(self.trace_tabs)
        dialogue_diagnostics_frame.rowconfigure(0, weight=1)
        dialogue_diagnostics_frame.columnconfigure(0, weight=1)
        self.dialogue_diagnostics = ScrolledText(
            dialogue_diagnostics_frame, wrap="none", state="disabled"
        )
        self.dialogue_diagnostics.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(
            dialogue_diagnostics_frame, text="Dialogue diagnostics"
        )
        self.dialogue_diagnostics_frame = dialogue_diagnostics_frame

        compare_frame = ttk.Frame(self.trace_tabs, padding=6)
        compare_frame.rowconfigure(1, weight=1)
        compare_frame.columnconfigure(0, weight=1)
        compare_controls = ttk.Frame(compare_frame)
        compare_controls.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        compare_controls.columnconfigure(1, weight=1)
        ttk.Label(
            compare_controls,
            text="Run the same utterance through current, low, and high production contexts.",
        ).grid(row=0, column=0, columnspan=4, sticky="w", pady=(0, 6))
        ttk.Label(compare_controls, text="Utterance").grid(
            row=1, column=0, sticky="w", padx=(0, 6)
        )
        self.compare_utterance_box = ttk.Entry(
            compare_controls, textvariable=self.compare_utterance_var
        )
        self.compare_utterance_box.grid(row=1, column=1, columnspan=3, sticky="ew")
        ttk.Label(compare_controls, text="Compare by").grid(
            row=2, column=0, sticky="w", padx=(0, 6), pady=(6, 0)
        )
        self.matrix_dimension_box = ttk.Combobox(
            compare_controls,
            textvariable=self.matrix_dimension_var,
            values=("persona", "approval", "respect", "familiarity", "bond", "language"),
            width=16,
            state="readonly",
        )
        self.matrix_dimension_box.grid(row=2, column=1, sticky="w", pady=(6, 0))
        self.capture_baseline_button = ttk.Button(
            compare_controls, text="Capture baseline", command=self.capture_baseline
        )
        self.capture_baseline_button.grid(row=2, column=2, sticky="w", padx=(8, 0), pady=(6, 0))
        self.persona_matrix_button = ttk.Button(
            compare_controls, text="Run comparison", command=self.inspect_persona_matrix
        )
        self.persona_matrix_button.grid(row=2, column=3, sticky="w", padx=(8, 0), pady=(6, 0))
        self.compare_output = ScrolledText(compare_frame, wrap="none", state="disabled")
        self.compare_output.grid(row=1, column=0, sticky="nsew")
        self.trace_tabs.add(compare_frame, text="Compare")
        self.compare_frame = compare_frame

        talk_frame = ttk.Frame(self.trace_tabs, padding=6)
        talk_frame.rowconfigure(2, weight=1)
        talk_frame.columnconfigure(0, weight=1)
        talk_controls = ttk.Frame(talk_frame)
        talk_controls.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        talk_controls.columnconfigure(0, weight=1)
        self.talk_utterance_box = ttk.Entry(
            talk_controls, textvariable=self.talk_utterance_var
        )
        self.talk_utterance_box.grid(row=0, column=0, sticky="ew", padx=(0, 6))
        self.talk_target_box = ttk.Combobox(
            talk_controls,
            textvariable=self.talk_target_var,
            values=("Current target",),
            width=14,
            state="readonly",
        )
        self.talk_target_box.grid(row=0, column=1, sticky="w")
        self.talk_start_button = ttk.Button(
            talk_controls, text="Start", command=self.start_talk_parity
        )
        self.talk_start_button.grid(row=0, column=2, sticky="w", padx=(6, 0))
        self.talk_matrix_button = ttk.Button(
            talk_controls, text="All types", command=self.run_talk_matrix
        )
        self.talk_matrix_button.grid(row=0, column=3, sticky="w", padx=(6, 0))
        self.talk_choices_frame = ttk.LabelFrame(
            talk_frame, text="Current Talk choices"
        )
        self.talk_choices_frame.grid(
            row=1, column=0, sticky="ew", pady=(0, 6)
        )
        for column in range(3):
            self.talk_choices_frame.columnconfigure(column, weight=1)
        self.talk_choice_buttons: list[Any] = []
        self.talk_output = ScrolledText(talk_frame, wrap="none", state="disabled")
        self.talk_output.grid(row=2, column=0, sticky="nsew")
        self.trace_tabs.add(talk_frame, text="Talk parity")
        self.talk_parity_frame = talk_frame

        diagnostics_frame = ttk.Frame(self.trace_tabs, padding=6)
        diagnostics_frame.columnconfigure(0, weight=1)
        ttk.Label(
            diagnostics_frame,
            text="Worker and maintenance diagnostics",
            font=("TkDefaultFont", 10, "bold"),
        ).grid(row=0, column=0, sticky="w")
        diagnostics_actions = ttk.Frame(diagnostics_frame)
        diagnostics_actions.grid(row=1, column=0, sticky="w", pady=(6, 6))
        self.snapshot_button = ttk.Button(
            diagnostics_actions, text="Snapshot", command=self.show_snapshot
        )
        self.snapshot_button.pack(side="left")
        self.restart_button = ttk.Button(
            diagnostics_actions, text="Restart worker", command=self.restart
        )
        self.restart_button.pack(side="left", padx=(6, 0))
        ttk.Label(
            diagnostics_frame,
            text="Raw worker records remain available in the Raw worker record tab.",
        ).grid(row=2, column=0, sticky="w")
        self.trace_tabs.add(diagnostics_frame, text="Diagnostics / Worker")
        self.diagnostics_frame = diagnostics_frame

        conversation_frame = ttk.Frame(self.trace_tabs)
        conversation_frame.rowconfigure(0, weight=1)
        conversation_frame.columnconfigure(0, weight=1)
        self.inspector = ScrolledText(
            conversation_frame, wrap="word", state="disabled"
        )
        self.inspector.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(conversation_frame, text="Conversation understanding")

        authority_frame = ttk.Frame(self.trace_tabs)
        authority_frame.rowconfigure(0, weight=1)
        authority_frame.columnconfigure(0, weight=1)
        self.authority = ScrolledText(
            authority_frame, wrap="word", state="disabled"
        )
        self.authority.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(authority_frame, text="Command authority")

        raw_frame = ttk.Frame(self.trace_tabs)
        raw_frame.rowconfigure(0, weight=1)
        raw_frame.columnconfigure(0, weight=1)
        self.trace = ScrolledText(raw_frame, wrap="none", state="disabled")
        self.trace.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(raw_frame, text="Raw worker record")

        suggestion_trace_frame = ttk.Frame(self.trace_tabs)
        suggestion_trace_frame.rowconfigure(0, weight=1)
        suggestion_trace_frame.columnconfigure(0, weight=1)
        self.suggestion_inspector = ScrolledText(
            suggestion_trace_frame, wrap="none", state="disabled"
        )
        self.suggestion_inspector.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(suggestion_trace_frame, text="Suggestions + predicates")

        provenance_frame = ttk.Frame(self.trace_tabs)
        provenance_frame.rowconfigure(0, weight=1)
        provenance_frame.columnconfigure(0, weight=1)
        self.provenance_inspector = ScrolledText(
            provenance_frame, wrap="none", state="disabled"
        )
        self.provenance_inspector.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(provenance_frame, text="Provenance")

        world_knowledge_frame = ttk.Frame(self.trace_tabs)
        self.world_knowledge_frame = world_knowledge_frame
        world_knowledge_frame.rowconfigure(1, weight=1)
        world_knowledge_frame.columnconfigure(0, weight=1)
        world_knowledge_toolbar = ttk.Frame(world_knowledge_frame)
        world_knowledge_toolbar.grid(row=0, column=0, sticky="ew", padx=6, pady=(6, 0))
        self.world_knowledge_button = ttk.Button(
            world_knowledge_toolbar,
            text="Refresh world knowledge",
            command=self.inspect_world_knowledge,
        )
        self.world_knowledge_button.pack(side="left")
        self.world_knowledge_inspector = ScrolledText(
            world_knowledge_frame, wrap="none", state="disabled"
        )
        self.world_knowledge_inspector.grid(row=1, column=0, sticky="nsew", padx=6, pady=6)
        self.trace_tabs.add(world_knowledge_frame, text="World Knowledge")

        editor_notebook = ttk.Notebook(editor_tab)
        editor_notebook.grid(row=0, column=0, sticky="nsew")
        flow_frame = ttk.Frame(editor_notebook)
        flow_frame.rowconfigure(0, weight=1)
        flow_frame.columnconfigure(0, weight=1)
        interaction_frame = ttk.Frame(editor_notebook)
        interaction_frame.rowconfigure(0, weight=1)
        interaction_frame.columnconfigure(0, weight=1)
        editor_notebook.add(interaction_frame, text="Interaction explorer")
        editor_notebook.add(flow_frame, text="Flow graph")
        self.flow_editor = FlowEditorPane(
            flow_frame,
            self._tk,
            ttk,
            ScrolledText,
            self._filedialog,
            self._messagebox,
            on_refresh=self.refresh_flow_catalog,
            on_validate=self.validate_flow_draft,
            on_register=self.register_flow_draft,
            on_compile_source=self.compile_semantic_source,
            on_generate_source=self.generate_semantic_source,
            on_review_dataset=self.review_dialogue_source,
            on_generate_dataset=self.generate_dialogue_source,
        )
        self.interaction_explorer = InteractionExplorerPane(
            interaction_frame,
            self._tk,
            ttk,
            ScrolledText,
            self.authoring_service,
            on_open_flow=self.flow_editor.select_flow,
        )
        self.interaction_composer = InteractionSpecPane(
            composer_tab,
            self._tk,
            ttk,
            ScrolledText,
            self._messagebox,
            on_preview=self.preview_interaction_spec,
            on_generate=self.generate_interaction_spec,
            on_inspect=self.inspect_live_worker,
        )
        self.dataset_library = DatasetLibraryPane(
            library_tab,
            self._tk,
            ttk,
            ScrolledText,
            self._messagebox,
            self.authoring_service,
        )
        self.block_registry = SemanticBlockRegistryPane(
            blocks_tab,
            self._tk,
            ttk,
            ScrolledText,
            self.authoring_service,
            on_refresh=self.refresh_flow_catalog,
        )
        self.workflow_pane = SemanticLabWorkflowPane(
            workflow_tab,
            self._tk,
            ttk,
            ScrolledText,
            self._messagebox,
            self.authoring_service,
            on_generate=self.generate_workflow,
            on_inspect=self.inspect_live_worker,
        )
        self.simulation_tab = simulation_tab
        self.main_tabs.bind(
            "<<NotebookTabChanged>>",
            lambda _event: self._on_main_tab_changed(),
        )
        self._restore_ui_state()
        self._schedule_activity_poll()
        self._append("SYSTEM", "Window ready. Starting the isolated Lua worker…")
        self._set_controls(False)

    def _set_controls(self, enabled: bool) -> None:
        state = "normal" if enabled and not self.busy else "disabled"
        for button in (
            self.send_button,
            self.reset_button,
            self.load_button,
            self.settings_button,
            self.preview_button,
            self.save_button,
            self.snapshot_button,
            self.persona_matrix_button,
            self.capture_baseline_button,
            self.talk_start_button,
            self.talk_matrix_button,
            self.workbench_apply_button,
            self.replay_button,
            self.world_knowledge_button,
            self.saved_world_discover_button,
            self.saved_world_inspect_button,
            self.saved_world_import_button,
        ):
            button.configure(state=state)
        if hasattr(self, "saved_world_save_box"):
            combo_state = "readonly" if enabled and not self.busy else "disabled"
            self.saved_world_save_box.configure(
                state=combo_state if self.saved_world_entries else "disabled"
            )
            browser_state = (
                combo_state if self.saved_world_browser else "disabled"
            )
            self.saved_world_player_box.configure(state=browser_state)
            self.saved_world_category_box.configure(state=browser_state)
            self.saved_world_npc_box.configure(state=browser_state)
        if hasattr(self, "proposal_button"):
            self.proposal_button.configure(state=state)
        if hasattr(self, "auto_replay_checkbutton"):
            self.auto_replay_checkbutton.configure(state=state)
        if self.language_box is not None:
            self.language_box.configure(
                state="readonly" if enabled and not self.busy else "disabled"
            )
        if hasattr(self, "compare_utterance_box"):
            self.compare_utterance_box.configure(
                state="normal" if enabled and not self.busy else "disabled"
            )
        if hasattr(self, "talk_target_box"):
            self.talk_target_box.configure(
                state="readonly" if enabled and not self.busy else "disabled"
            )
        if hasattr(self, "talk_utterance_box"):
            self.talk_utterance_box.configure(
                state="normal" if enabled and not self.busy else "disabled"
            )
        self.npc_profile_box.configure(
            state="readonly" if enabled and not self.busy else "disabled"
        )
        for field in self.workbench_control_fields.values():
            field.set_enabled(enabled and not self.busy)
        if enabled and not self.busy:
            self._update_generated_personality_controls()
        self.matrix_dimension_box.configure(
            state="readonly" if enabled and not self.busy else "disabled"
        )
        self.restart_button.configure(
            state="normal" if self.session.ready and not self.busy else "disabled"
        )
        self.flow_editor.set_enabled(enabled and not self.busy)
        self.interaction_explorer.set_enabled(enabled and not self.busy)
        self.interaction_composer.set_enabled(enabled and not self.busy)
        self.workflow_pane.set_enabled(enabled and not self.busy)
        self._refresh_suggestion_controls(enabled and not self.busy)

    def _refresh_workbench_feedback(self, message: str | None = None) -> None:
        """Make staged edits visible before they are sent to the worker."""

        if self.workbench_status_var is None:
            return
        pending_labels = self._pending_control_labels()
        pending = len(pending_labels)
        self.workbench_apply_button.configure(
            text="Apply" if pending == 0 else f"Apply ({pending} pending)"
        )
        self.replay_button.configure(
            text=(
                f"Replay macro ({len(self.replay_steps)})"
                if pending == 0 and self.replay_steps
                else "Apply + replay"
                if pending == 0
                else f"Apply + replay ({pending} pending)"
            )
        )
        if message is not None:
            self.workbench_status_var.set(message)
        elif pending:
            summary = ", ".join(pending_labels[:5])
            if len(pending_labels) > 5:
                summary += f", +{len(pending_labels) - 5} more"
            self.workbench_status_var.set(
                f"Pending: {summary or 'review draft'} · Apply to commit"
            )
        else:
            self.workbench_status_var.set(
                "Auto-apply enabled · edits commit through the Lua worker."
            )

    def _pending_control_labels(self) -> list[str]:
        labels: list[str] = []
        for control in self.workbench_controls:
            control_id = str(control.get("id") or "")
            if (
                control_id not in self._workbench_dirty_ids
                or control.get("derivedFrom")
            ):
                continue
            label = str(control.get("label") or control_id)
            if control.get("derivedFrom"):
                label = f"{label} (derived)"
            labels.append(label)
        if self._workbench_profile_pending:
            labels.insert(0, "NPC profile")
        return labels

    def _clear_workbench_pending(self) -> None:
        self._workbench_dirty_ids.clear()
        self._workbench_profile_pending = False
        for field in self.workbench_control_fields.values():
            field.dirty = False
        self._refresh_workbench_feedback()

    def _schedule_workbench_auto_apply(self) -> None:
        """Debounce direct edits into the existing worker configure boundary."""

        if self.closed or not self.worker_ready:
            return
        if self._auto_apply_after is not None:
            try:
                self.root.after_cancel(self._auto_apply_after)
            except self._tk.TclError:
                pass
            self._auto_apply_after = None
        if not self._pending_control_labels():
            return
        self._auto_apply_after = self.root.after(
            300, self._apply_pending_workbench_changes
        )

    def _apply_pending_workbench_changes(self) -> None:
        self._auto_apply_after = None
        if self.closed or not self.worker_ready:
            return
        if self.busy:
            self._auto_apply_after = self.root.after(
                250, self._apply_pending_workbench_changes
            )
            return
        self.apply_simulation_settings(automatic=True)

    def _on_workbench_field_dirty(self, field: CatalogControlField) -> None:
        """Track a direct edit and refresh derived actor presentation fields."""

        control_id = str(field.control.get("id") or "")
        if (
            not control_id
            or self.workbench_control_fields.get(control_id) is not field
        ):
            return
        if self._workbench_initializing:
            return
        self._workbench_dirty_ids.add(control_id)
        self.activity_log.record(
            "ui",
            "staged_change",
            controlID=control_id,
            label=str(field.control.get("label") or control_id),
            value=str(field.get_value())[:180],
        )
        if control_id in {
            "player.forename", "player.surname",
            "npc.forename", "npc.surname",
        }:
            self._sync_derived_identity_fields(control_id.split(".", 1)[0])
        if control_id in {"persona.traits", "player.traits"}:
            self._render_trait_effects()
            self._schedule_personality_preview()
        self._refresh_workbench_feedback()
        self._schedule_workbench_auto_apply()

    def _sync_derived_identity_fields(self, actor: str) -> None:
        """Keep IDs and player display text readable while names are edited."""

        prefix = "player" if actor == "player" else "npc"
        forename_field = self.workbench_control_fields.get(f"{prefix}.forename")
        surname_field = self.workbench_control_fields.get(f"{prefix}.surname")
        if forename_field is None or surname_field is None:
            return
        forename = forename_field.get_value()
        surname = surname_field.get_value()
        if prefix == "player":
            derived = {
                "player.characterUUID": derive_actor_identifier(
                    "char", forename, surname
                ),
                "player.displayName": derive_display_name(forename, surname),
            }
        else:
            derived = {
                "npc.npcID": derive_actor_identifier("npc", forename, surname),
            }
        for control_id, value in derived.items():
            field = self.workbench_control_fields.get(control_id)
            if field is not None:
                field.set_value(value)
                self._workbench_dirty_ids.add(control_id)
                self.activity_log.record(
                    "ui",
                    "derived_change",
                    controlID=control_id,
                    label=str(field.control.get("label") or control_id),
                    value=str(value)[:180],
                )

    @staticmethod
    def _format_trait_effect_value(value: Any) -> str:
        if isinstance(value, bool):
            return "yes" if value else "no"
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            return f"{value:+.2f}"
        return str(value)

    def _flatten_trait_effects(
        self, value: Any, prefix: str = ""
    ) -> list[str]:
        if not isinstance(value, dict):
            return [
                f"{prefix}: {self._format_trait_effect_value(value)}"
                if prefix
                else self._format_trait_effect_value(value)
            ]
        lines: list[str] = []
        for key in sorted(value, key=str):
            label = str(key).replace("_", " ")
            child_prefix = f"{prefix} · {label}" if prefix else label
            lines.extend(self._flatten_trait_effects(value[key], child_prefix))
        return lines

    def _write_trait_effects(self, actor: str, lines: list[str]) -> None:
        rendered = "\n".join(lines)
        widget = self.trait_effects_widgets.get(actor)
        if widget is not None:
            widget.configure(state="normal")
            widget.delete("1.0", "end")
            widget.insert("1.0", rendered)
            widget.configure(state="disabled")

    def _render_trait_effects(self) -> None:
        npc_field = self.workbench_control_fields.get("persona.traits")
        selected_npc = npc_field.get_value() if npc_field is not None else []
        selected_npc = selected_npc if isinstance(selected_npc, list) else []
        definitions = {
            str(row.get("id")): row
            for row in self.persona_catalog.get("traits", [])
            if isinstance(row, dict) and row.get("id")
        }
        for definition in tuple(definitions.values()):
            for alias in definition.get("aliases") or []:
                definitions.setdefault(str(alias), definition)
        npc_lines = ["Production registry effects"]
        if not selected_npc:
            npc_lines.append("Select a registered trait to inspect its effects.")
        for trait_id in selected_npc[:8]:
            definition = definitions.get(str(trait_id))
            if not definition:
                npc_lines.append(f"{trait_id}: definition unavailable")
                continue
            label = str(definition.get("label") or trait_id)
            source = str(definition.get("source") or "production")
            npc_lines.append(f"{label} · source: {source}")
            effects = definition.get("effects")
            npc_lines.extend(
                f"  {line}"
                for line in self._flatten_trait_effects(effects, "effects")
            )
            speech = definition.get("speechStyle")
            if speech:
                npc_lines.extend(
                    f"  {line}"
                    for line in self._flatten_trait_effects(speech, "speech style")
                )
        if self.generated_personality_preview and selected_npc:
            values = self.generated_personality_preview
            shown = (
                "compassion",
                "sociability",
                "forgiveness",
                "bravery",
                "aggression",
            )
            preview = " · ".join(
                f"{key} {self._format_trait_effect_value(values[key])}"
                for key in shown
                if key in values
            )
            if preview:
                npc_lines.append(f"Generated personality preview: {preview}")
        self._write_trait_effects("npc", npc_lines)

        player_field = self.workbench_control_fields.get("player.traits")
        selected_player = player_field.get_value() if player_field is not None else []
        selected_player = selected_player if isinstance(selected_player, list) else []
        player_projection = self.simulation_projection.get("player", {})
        if not isinstance(player_projection, dict):
            player_projection = {}
        player_profile = self.player_social_profile_preview or (
            player_projection.get("socialProfile")
            or self.persona_catalog.get("playerSocialProfile", {})
        )
        player_lines = ["Production-derived social profile"]
        if not selected_player:
            player_lines.append("Select registered player traits to preview their effects.")
        for key in (
            "orientation",
            "romanceStyle",
            "jealousyStyle",
            "socialStyle",
            "foodPreference",
        ):
            player_lines.append(f"{key}: {player_profile.get(key, 'unknown')}")
        if self.player_trait_fingerprint:
            player_lines.append(f"trait fingerprint: {self.player_trait_fingerprint}")
        if self.player_trait_conflicts:
            player_lines.append(
                "trait conflicts: "
                + ", ".join(str(item) for item in self.player_trait_conflicts[:4])
            )
        self._write_trait_effects("player", player_lines)

    def _schedule_personality_preview(self) -> None:
        if self._personality_preview_after is not None:
            try:
                self.root.after_cancel(self._personality_preview_after)
            except self._tk.TclError:
                pass
        self._personality_preview_after = self.root.after(
            120, self._request_personality_preview
        )

    def _request_personality_preview(self) -> None:
        self._personality_preview_after = None
        if self.closed or not self.worker_ready or self.busy:
            return
        if self._personality_preview_future is not None:
            if not self._personality_preview_future.done():
                self._personality_preview_after = self.root.after(
                    120, self._request_personality_preview
                )
                return
        try:
            staged = self._collect_workbench_scenario()
        except (TypeError, ValueError, self._tk.TclError):
            return
        try:
            future = self.session.submit(
                lambda worker: worker.persona_preview(staged)
            )
        except (HarnessError, RuntimeError):
            return
        self._personality_preview_future = future
        self._poll_personality_preview(future)

    def _poll_personality_preview(self, future: Future[Any]) -> None:
        if self.closed:
            return
        if not future.done():
            self.root.after(25, self._poll_personality_preview, future)
            return
        try:
            result = future.result()
            value = result.value if hasattr(result, "value") else result
        except (HarnessError, ConfigurationError, OSError, ValueError):
            return
        preview = value.get("personality") if isinstance(value, dict) else None
        self.generated_personality_preview = (
            dict(preview) if isinstance(preview, dict) else {}
        )
        if isinstance(value, dict):
            player_profile = value.get("playerSocialProfile")
            self.player_social_profile_preview = (
                dict(player_profile) if isinstance(player_profile, dict) else {}
            )
            conflicts = value.get("playerTraitConflicts")
            self.player_trait_conflicts = (
                list(conflicts) if isinstance(conflicts, list) else []
            )
            self.player_trait_fingerprint = str(
                value.get("playerTraitFingerprint") or ""
            )
            for control in self.workbench_controls:
                control_id = str(control.get("id") or "")
                if not control_id.startswith("player.socialProfile."):
                    continue
                field = self.workbench_control_fields.get(control_id)
                if field is not None:
                    field.set_value(self._scenario_control_value(control, self.scenario))
        self._update_generated_personality_controls()
        self._render_trait_effects()

    def _ensure_suggestion_buttons(self, count: int) -> None:
        while len(self.suggestion_buttons) < count:
            index = len(self.suggestion_buttons)
            button = self._ttk.Button(
                self.suggestion_buttons_frame,
                text="",
                command=lambda index=index: self.click_suggestion(index),
            )
            button.grid(
                row=index // 3,
                column=index % 3,
                sticky="ew",
                padx=3,
                pady=3,
            )
            self.suggestion_buttons.append(button)

    def _refresh_suggestion_controls(self, enabled: bool) -> None:
        for index, button in enumerate(self.suggestion_buttons):
            row = self.suggestion_rows[index] if index < len(self.suggestion_rows) else None
            if row:
                button.grid()
            else:
                # The production projection is bounded, but empty capacity is
                # not a player-facing choice.  Hide unused slots rather than
                # presenting a wall of disabled blank buttons.
                button.grid_remove()
            button.configure(
                state=(
                    "normal"
                    if enabled
                    and self.suggestion_interactive
                    and row
                    and row.get("enabled") is True
                    else "disabled"
                )
            )

    @property
    def worker_ready(self) -> bool:
        return self.session.ready and self._worker_initialized

    def _set_status(self, value: str) -> None:
        if hasattr(self, "status_var"):
            self.status_var.set(value)

    def _restore_ui_state(self) -> None:
        """Restore non-scenario UI state after the widget tree exists."""

        def restore() -> None:
            try:
                saved_window_state = self._ui_state.get("window_state")
                if saved_window_state in {"normal", "zoomed"}:
                    self.root.state(saved_window_state)
                main_index = int(self._ui_state.get("main_tab", 0))
                tabs = self.main_tabs.tabs()
                if tabs:
                    self.main_tabs.select(tabs[min(max(main_index, 0), len(tabs) - 1)])
                studio_index = int(self._ui_state.get("studio_tab", 0))
                studio_tabs = self.studio_notebook.tabs()
                if studio_tabs:
                    self.studio_notebook.select(
                        studio_tabs[min(max(studio_index, 0), len(studio_tabs) - 1)]
                    )
                trace_index = int(self._ui_state.get("trace_tab", 0))
                trace_tabs = self.trace_tabs.tabs()
                if trace_tabs:
                    self.trace_tabs.select(
                        trace_tabs[min(max(trace_index, 0), len(trace_tabs) - 1)]
                    )
                self._restore_splitters()
                workbench_tabs = self.workbench_notebook.tabs()
                if workbench_tabs:
                    workbench_index = int(self._ui_state.get("workbench_panel", 0))
                    self.workbench_notebook.select(
                        workbench_tabs[
                            min(max(workbench_index, 0), len(workbench_tabs) - 1)
                        ]
                    )
                self._restore_workbench_tabs()
            except (self._tk.TclError, TypeError, ValueError):
                pass

        self.root.after_idle(restore)

    def _restore_splitters(self) -> None:
        if self.closed or self.main_tabs.select() != str(self.simulation_tab):
            return
        simulation_width = max(1, self.simulation_panes.winfo_width())
        workflow_height = max(1, self.workflow_pane_split.winfo_height())
        if simulation_width <= 10 or workflow_height <= 10:
            self._schedule_splitter_restore(100)
            return
        simulation_value = self._ui_state.get("simulation_sash")
        if simulation_value is None:
            simulation_value = min(
                max(620, int(simulation_width * 0.60)),
                max(420, simulation_width - 420),
            )
        else:
            simulation_value = min(
                max(620, int(simulation_value)),
                max(620, simulation_width - 420),
            )
        workflow_value = self._ui_state.get("workflow_sash")
        if workflow_value is None:
            workflow_value = min(
                max(240, int(workflow_height * 0.50)),
                max(240, workflow_height - 260),
            )
        else:
            workflow_value = min(
                max(240, int(workflow_value)),
                max(240, workflow_height - 260),
            )
        try:
            self.workflow_pane_split.sashpos(0, int(workflow_value))
        except (self._tk.TclError, TypeError, ValueError):
            pass
        try:
            self.simulation_panes.sashpos(0, int(simulation_value))
        except (self._tk.TclError, TypeError, ValueError):
            pass

    def _schedule_splitter_restore(self, delay_ms: int = 250) -> None:
        if self.closed:
            return
        if self._splitter_restore_after is not None:
            try:
                self.root.after_cancel(self._splitter_restore_after)
            except self._tk.TclError:
                pass
        self._splitter_restore_after = self.root.after(
            delay_ms, self._restore_splitters
        )

    def _on_main_tab_changed(self) -> None:
        if self.closed or self.main_tabs.select() != str(self.simulation_tab):
            return
        self._schedule_splitter_restore()

    def _restore_workbench_tabs(self) -> None:
        selections = self._ui_state.get("workbench_tabs") or {}
        if not isinstance(selections, dict):
            return
        for panel_name, notebook in self.workbench_panel_notebooks.items():
            selected = selections.get(panel_name)
            tabs = notebook.tabs()
            if selected is None or not tabs:
                continue
            try:
                notebook.select(tabs[min(max(int(selected), 0), len(tabs) - 1)])
            except (TypeError, ValueError, self._tk.TclError):
                continue

    def _save_ui_state(self) -> None:
        try:
            state = dict(self._ui_state)
            state["geometry"] = self.root.geometry()
            state["window_state"] = self.root.state()
            state["main_tab"] = self.main_tabs.index(self.main_tabs.select())
            state["studio_tab"] = self.studio_notebook.index(
                self.studio_notebook.select()
            )
            state["trace_tab"] = self.trace_tabs.index(self.trace_tabs.select())
            selected_talk = self.talk_target_ids_by_label.get(
                self.talk_target_var.get(), "current"
            )
            state["talk_target"] = selected_talk
            state["talk_utterance"] = self.talk_utterance_var.get()
            if self.simulation_panes.winfo_width() > 10:
                state["simulation_sash"] = self.simulation_panes.sashpos(0)
            if self.workflow_pane_split.winfo_height() > 10:
                state["workflow_sash"] = self.workflow_pane_split.sashpos(0)
            if self.workbench_notebook.tabs():
                state["workbench_panel"] = self.workbench_notebook.index(
                    self.workbench_notebook.select()
                )
            state["workbench_tabs"] = {
                panel_name: notebook.index(notebook.select())
                for panel_name, notebook in self.workbench_panel_notebooks.items()
                if notebook.tabs()
            }
            save_ui_state(self.ui_state_path, state)
        except (OSError, self._tk.TclError, TypeError, ValueError):
            self.activity_log.record(
                "ui", "state_save_error", message="could not save window state"
            )

    def _append(self, speaker: str, text: str) -> None:
        self.activity_log.record(
            "ui",
            "conversation",
            speaker=str(speaker),
            message=str(text)[:240],
        )
        entry, removed_chars = self._transcript_buffer.append(speaker, text)
        self.transcript.configure(state="normal")
        if removed_chars:
            self.transcript.delete("1.0", f"1.0 + {removed_chars} chars")
        self.transcript.insert("end", entry)
        self.transcript.see("end")
        self.transcript.configure(state="disabled")

    def _set_text(self, widget: Any, value: str) -> None:
        if widget is getattr(self, "transcript", None):
            self._transcript_buffer.clear()
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("end", value)
        widget.configure(state="disabled")

    def _schedule_activity_poll(self) -> None:
        if self.closed:
            return
        if self._activity_after is not None:
            try:
                self.root.after_cancel(self._activity_after)
            except self._tk.TclError:
                pass
        self._activity_after = self.root.after(150, self._poll_activity_log)

    def _poll_activity_log(self) -> None:
        if self._activity_after is not None:
            try:
                self.root.after_cancel(self._activity_after)
            except self._tk.TclError:
                pass
        self._activity_after = None
        if self.closed:
            return
        records = self.activity_log.new_shared_events(self._activity_seen_ids)
        if records:
            self.activity_log_widget.configure(state="normal")
            for record in records:
                self.activity_log_widget.insert(
                    "end", format_activity_event(record) + "\n"
                )
                event_id = str(record.get("eventID") or "")
                if event_id:
                    self._activity_seen_ids.add(event_id)
            self.activity_log_widget.see("end")
            self.activity_log_widget.configure(state="disabled")
            self.activity_log_status.set(
                f"{len(self._activity_seen_ids)} shown · shared GUI/CLI/agent timeline"
            )
        self._schedule_activity_poll()

    def clear_activity_log(self) -> None:
        self._activity_seen_ids.update(
            str(record.get("eventID") or "")
            for record in self.activity_log.shared_snapshot()
            if record.get("eventID")
        )
        self.activity_log.clear()
        self.activity_log_widget.configure(state="normal")
        self.activity_log_widget.delete("1.0", "end")
        self.activity_log_widget.configure(state="disabled")
        self.activity_log_status.set("Activity view cleared · shared history retained")

    def _worker_kwargs(self) -> dict[str, Any]:
        return {
            "lua_bin": self.arguments.lua,
            "repository": Path(self.arguments.repository) if self.arguments.repository else None,
            "core_repository": Path(self.arguments.core_repository) if self.arguments.core_repository else None,
            "startup_timeout": self.arguments.startup_timeout,
            "request_timeout": self.arguments.timeout,
            "shutdown_timeout": self.arguments.shutdown_timeout,
            "activity_log": self.activity_log,
        }

    def _start_worker(self) -> None:
        if self.closed:
            return
        self._future = self.session.start()
        self._poll_future(self._future, self._worker_ready)

    def _poll_future(self, future: Future[Any], callback: Callable[[Any], None]) -> None:
        if self.closed:
            return
        if not future.done():
            self.root.after(25, self._poll_future, future, callback)
            return
        self.busy = False
        try:
            result = future.result()
        except (HarnessError, ConfigurationError, OSError, ValueError) as error:
            self._set_status("Worker failed")
            self._set_controls(False)
            self._set_text(self.trace, str(error))
            self._messagebox.showerror("Semantic harness startup/error", str(error))
            return
        callback(result)

    def _worker_ready(self, result: WorkerReady) -> None:
        self._worker_initialized = True
        self._workbench_initializing = True
        self.persona_catalog = result.capabilities.get("personaCatalog") or {}
        self.simulation_control_catalog = (
            result.capabilities.get("simulationControlCatalog") or {}
        )
        self.talk_catalog = result.capabilities.get("talkCatalog") or {}
        self._set_talk_catalog()
        self._update_simulation_projection(result.capabilities)
        self._build_simulation_workbench()
        self._set_status(f"Ready · Lua PID {result.status.get('pid')}")
        self._set_controls(True)
        self._clear_workbench_pending()
        self._workbench_initializing = False
        self._append("SYSTEM", "Lua worker ready. Production semantic modules are loaded.")
        initial_suggestions = result.capabilities.get("suggestions") or {}
        if initial_suggestions:
            self._render_suggestions(
                {"type": "turn", "accepted": True}, initial_suggestions
            )
        capabilities = result.capabilities or {}
        flow_catalog = capabilities.get("flowCatalog", {})
        self._set_text(
            self.inspector,
            pretty({
                "state": "ready",
                "worker": result.status,
                "flows": flow_catalog.get("flowCount", 0),
                "engineFacts": len(flow_catalog.get("factCatalog", [])),
                "engineEvents": len(flow_catalog.get("eventCatalog", [])),
                "commands": len(flow_catalog.get("commandCatalog", [])),
                "hint": "Use the Flow editor tab to build and validate production branches.",
            }),
        )
        self._set_text(self.trace, pretty(capabilities))
        self.flow_editor.set_catalog(flow_catalog)
        self.interaction_explorer.set_catalog(flow_catalog)
        self.interaction_composer.set_production_catalog(flow_catalog)
        self.block_registry.set_catalog(flow_catalog)
        self._production_catalog = flow_catalog
        self.workflow_pane.set_production_catalog(flow_catalog)

    def _set_talk_catalog(self) -> None:
        """Populate the Talk parity selector from the production catalog."""

        rows = self.talk_catalog.get("targets", [])
        if not isinstance(rows, list):
            rows = []
        labels: list[str] = []
        self.talk_target_ids_by_label = {}
        for row in rows:
            if not isinstance(row, dict):
                continue
            target_id = str(row.get("id") or "")
            label = str(row.get("label") or target_id)
            if not target_id or label in self.talk_target_ids_by_label:
                continue
            labels.append(label)
            self.talk_target_ids_by_label[label] = target_id
        if not labels:
            labels = ["Current target"]
            self.talk_target_ids_by_label[labels[0]] = "current"
        self.talk_target_box.configure(values=tuple(labels))
        wanted = str(self._ui_state.get("talk_target") or "current")
        selected = next(
            (
                label
                for label, target_id in self.talk_target_ids_by_label.items()
                if target_id == wanted
            ),
            labels[0],
        )
        self.talk_target_var.set(selected)

    def _discover_saved_worlds(self) -> None:
        """Discover validated offline saves without starting Project Zomboid."""

        def finish(result: dict[str, Any]) -> None:
            self.saved_catalog = result if isinstance(result, dict) else {}
            entries = self.saved_catalog.get("saves") or []
            self.saved_world_entries = [
                entry for entry in entries if isinstance(entry, dict)
            ]
            self.saved_world_save_labels = {}
            labels: list[str] = []
            for entry in self.saved_world_entries:
                label = (
                    f"{entry.get('saveName') or 'save'} · "
                    f"{entry.get('mode') or 'unknown mode'} · "
                    f"{entry.get('path') or ''}"
                )
                labels.append(label)
                self.saved_world_save_labels[label] = entry
            self.saved_world_save_box.configure(values=tuple(labels))
            if labels:
                self.saved_world_save_var.set(labels[0])
                self.saved_world_status_var.set(
                    f"{len(labels)} validated save(s); choose one and Inspect."
                )
            else:
                rejected = len(self.saved_catalog.get("rejected") or [])
                self.saved_world_save_var.set("")
                self.saved_world_status_var.set(
                    f"No compatible saves found ({rejected} rejected)."
                )
            self._set_controls(True)

        self._start_operation(lambda worker: worker.save_catalog(), finish)

    def _selected_saved_world_entry(self) -> dict[str, Any] | None:
        return self.saved_world_save_labels.get(self.saved_world_save_var.get())

    def _inspect_saved_world(self) -> None:
        entry = self._selected_saved_world_entry()
        if entry is None:
            self.saved_world_status_var.set("Discover and select a compatible save first.")
            return
        save_path = str(entry.get("path") or "")
        if not save_path:
            self.saved_world_status_var.set("Selected save has no readable path.")
            return

        def finish(result: dict[str, Any]) -> None:
            self.saved_world_browser = result if isinstance(result, dict) else {}
            players = self.saved_world_browser.get("players") or []
            self.saved_world_category_rows = {
                str(key): value
                for key, value in (self.saved_world_browser.get("categories") or {}).items()
                if isinstance(value, list)
            }
            player_labels = [
                str(row.get("label") or row.get("id"))
                for row in players
                if isinstance(row, dict)
            ]
            self.saved_world_player_labels = {
                str(row.get("label") or row.get("id")): row
                for row in players
                if isinstance(row, dict)
            }
            self.saved_world_player_box.configure(values=tuple(player_labels))
            if player_labels:
                self.saved_world_player_var.set(player_labels[0])
            category_labels = sorted(self.saved_world_category_rows)
            self.saved_world_category_box.configure(values=tuple(category_labels))
            if category_labels:
                preferred = (
                    "All NPCs" if "All NPCs" in category_labels else category_labels[0]
                )
                self.saved_world_category_var.set(preferred)
            self._on_saved_world_category()
            counts = self.saved_world_browser.get("counts") or {}
            self.saved_world_status_var.set(
                "Browsed save: "
                f"{counts.get('players', 0)} player(s), "
                f"{counts.get('npcs', 0)} NPC(s), "
                f"{counts.get('factions', 0)} faction(s), "
                f"{counts.get('communities', 0)} community reference(s)."
            )
            self._set_controls(True)

        self._start_operation(
            lambda worker: worker.save_browser(Path(save_path)), finish
        )

    def _on_saved_world_category(self) -> None:
        rows = self.saved_world_category_rows.get(
            self.saved_world_category_var.get(), []
        )
        self.saved_world_npc_labels = {
            str(row.get("label") or row.get("id")): row
            for row in rows
            if isinstance(row, dict)
        }
        labels = list(self.saved_world_npc_labels)
        self.saved_world_npc_box.configure(values=tuple(labels))
        self.saved_world_npc_var.set(labels[0] if labels else "")

    def _import_saved_world_target(self) -> None:
        entry = self._selected_saved_world_entry()
        player = getattr(self, "saved_world_player_labels", {}).get(
            self.saved_world_player_var.get()
        )
        npc = getattr(self, "saved_world_npc_labels", {}).get(
            self.saved_world_npc_var.get()
        )
        if entry is None or not player or not npc:
            self.saved_world_status_var.set(
                "Inspect a save, then choose both a Player and an NPC target."
            )
            return

        def finish(result: dict[str, Any]) -> None:
            scenario = result.get("scenario") if isinstance(result, dict) else None
            if isinstance(scenario, dict):
                self.scenario = scenario
                self._sync_workbench_from_scenario(scenario)
            self._update_simulation_projection(result)
            source = (result.get("sourceSnapshot") or {}).get("metadata", {})
            self.saved_world_status_var.set(
                "Imported saved target: "
                f"{player.get('label')} → {npc.get('label')} · "
                f"source {source.get('sourceKind', 'SAVE')}"
            )
            self._set_text(self.trace, pretty(result))
            self._append(
                "SYSTEM",
                f"Imported saved target {npc.get('label')} from read-only source save.",
            )

        self._start_operation(
            lambda worker: worker.import_saved_selection(
                Path(str(entry.get("path"))),
                player_uuid=str(player.get("uuid") or player.get("id")),
                npc_id=str(npc.get("id")),
            ),
            finish,
        )

    def _selected_talk_target(self) -> str:
        return self.talk_target_ids_by_label.get(
            self.talk_target_var.get(), "current"
        )

    def _talk_utterance(self) -> str:
        return (
            self.talk_utterance_var.get().strip()
            or self.input_var.get().strip()
            or self.last_test_utterance.strip()
            or "hello"
        )

    def _render_talk_choices(self, choices: Any) -> None:
        """Render the worker's production choice surface without reclassifying it."""

        if not isinstance(choices, list):
            choices = []
        for button in self.talk_choice_buttons:
            button.destroy()
        self.talk_choice_buttons = []
        visible = [
            choice for choice in choices
            if isinstance(choice, dict) and isinstance(choice.get("frame"), dict)
        ]
        if not visible:
            label = self._ttk.Label(
                self.talk_choices_frame,
                text="Start Talk to load the production landing choices.",
            )
            label.grid(row=0, column=0, columnspan=3, sticky="w", padx=6, pady=4)
            self.talk_choice_buttons.append(label)
            return
        for index, choice in enumerate(visible):
            frame = choice["frame"]
            text = str(
                choice.get("text")
                or choice.get("label")
                or frame.get("labelFallback")
                or frame.get("textFallback")
                or choice.get("id")
                or "choice"
            )
            button = self._ttk.Button(
                self.talk_choices_frame,
                text=text,
                command=lambda selected=frame: self._click_talk_choice(selected),
            )
            button.grid(
                row=index // 3,
                column=index % 3,
                sticky="ew",
                padx=3,
                pady=3,
            )
            if choice.get("enabled") is False:
                button.configure(state="disabled")
            self.talk_choice_buttons.append(button)

    def _click_talk_choice(self, frame: dict[str, Any]) -> None:
        if not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            scenario = response.get("scenario")
            if isinstance(scenario, dict):
                self.scenario = scenario
                self._sync_workbench_from_scenario(scenario)
            if response.get("accepted") is not True:
                self._append(
                    "SYSTEM",
                    f"Talk choice rejected: {response.get('reason') or 'unknown'}",
                )
            self._show_response(response)
            observation = response.get("observation") or {}
            self._render_talk_choices(observation.get("choices") or [])
            self._set_text(
                self.talk_output,
                "Talk choice\n\n" + pretty(response),
            )

        self._start_operation(
            lambda worker: worker.suggestion_click(frame), finish
        )

    def start_talk_parity(self) -> None:
        """Start one production Talk target and show its opening evidence."""

        if not self.session.ready or self.busy:
            return
        target_id = self._selected_talk_target()
        utterance = self._talk_utterance()
        self.activity_log.record(
            "ui", "talk_start_requested", target=target_id, utterance=utterance
        )

        def finish(result: dict[str, Any]) -> None:
            scenario = result.get("scenario")
            if isinstance(scenario, dict):
                self.scenario = scenario
                self._sync_workbench_from_scenario(scenario)
            start = result.get("start") or {}
            opening = start.get("opening") or {}
            for message in opening.get("messages") or []:
                if isinstance(message, dict) and message.get("speaker") == "npc":
                    self._append("NPC", npc_message_text(message))
            turn = result.get("turn") or {}
            if isinstance(turn, dict):
                self._show_response(turn)
            observation = result.get("observation") or {}
            self._render_talk_choices(
                observation.get("choices") or opening.get("choices") or []
            )
            self._set_text(self.talk_output, self._format_talk_start(result))
            self.trace_tabs.select(self.talk_parity_frame)
            target = (result.get("start") or {}).get("target") or {}
            self._append(
                "SYSTEM",
                f"Talk parity started: {target.get('label') or target_id} · "
                f"route {target.get('route') or 'unknown'}",
            )
            self.activity_log.record(
                "ui",
                "talk_start_completed",
                target=target_id,
                route=target.get("route"),
            )

        self._start_operation(
            lambda worker: worker.talk_start(target_id, utterance), finish
        )

    def run_talk_matrix(self) -> None:
        """Compare the native Talk start across the normal production types."""

        if not self.session.ready or self.busy:
            return
        utterance = self._talk_utterance()
        self.activity_log.record(
            "ui", "talk_matrix_requested", utterance=utterance
        )

        def finish(result: dict[str, Any]) -> None:
            self._set_text(self.talk_output, self._format_talk_matrix(result))
            self.trace_tabs.select(self.talk_parity_frame)
            rows = result.get("rows") if isinstance(result, dict) else []
            self._append(
                "SYSTEM",
                f"Talk parity comparison completed: {len(rows) if isinstance(rows, list) else 0} target types.",
            )
            self.activity_log.record(
                "ui",
                "talk_matrix_completed",
                rowCount=len(rows) if isinstance(rows, list) else 0,
            )

        self._start_operation(
            lambda worker: worker.talk_matrix(text=utterance), finish
        )

    def _format_talk_start(self, result: dict[str, Any]) -> str:
        start = result.get("start") or {}
        target = start.get("target") or {}
        opening = start.get("opening") or {}
        choices = opening.get("choices") or []
        lines = [
            "Native Talk parity",
            "",
            f"Target: {target.get('label') or 'unknown'}",
            f"Production target type: {target.get('targetType') or 'unknown'}",
            f"Tactical class: {target.get('tacticalClass') or 'unknown'}",
            f"Audience: {target.get('audience') or 'unknown'}",
            f"Route: {target.get('route') or 'unknown'}",
            f"Route reason: {target.get('routeReason') or 'unknown'}",
            f"Availability: {(target.get('availability') or {}).get('reason') or 'available'}",
            f"Hostile: {'yes' if target.get('hostile') else 'no'}",
            f"Hostile inline integration: {'available' if target.get('hostileInlineAvailable') else 'not loaded in worker'}",
            f"Relationship ID: {target.get('relationshipID') or 'unknown'}",
            f"Trader overlay: {'enabled' if ((start.get('integration') or {}).get('traderOverlay') or {}).get('enabled') else 'disabled'}",
            "",
            f"Opening node: {opening.get('nodeID') or 'unknown'}",
            "Opening flavor:",
        ]
        opening_messages = opening.get("messages") or []
        for message in opening_messages:
            if isinstance(message, dict) and message.get("speaker") == "npc":
                lines.append(f"  NPC: {npc_message_text(message)}")
        if not opening_messages:
            lines.append("  —")
        lines.append(
            "Opening choices:",
        )
        for choice in choices:
            if isinstance(choice, dict):
                status = "available" if choice.get("enabled") else "locked"
                lines.append(
                    f"  - {choice.get('id') or 'unknown'} [{status}] "
                    f"{choice.get('text') or choice.get('textKey') or ''}"
                )
        observation = result.get("observation") or {}
        lines.extend(
            (
                "",
                f"First response: {observation.get('npcResponse') or '—'}",
                f"Graph: {(observation.get('runtimeGraphPath') or {}).get('kind') or '—'}",
                "",
                "Production evidence:",
                pretty({
                    "schema": result.get("schema"),
                    "start": start,
                    "observation": observation,
                }),
            )
        )
        return "\n".join(lines)

    def _format_talk_matrix(self, result: dict[str, Any]) -> str:
        rows = result.get("rows") if isinstance(result, dict) else None
        if not isinstance(rows, list) or not rows:
            return pretty(result)
        lines = [
            f"Talk parity · {result.get('schema', 'production matrix')}",
            f"First utterance: {result.get('utterance') or 'hello'}",
            "",
            "Target | Production type | Audience | Route | Availability | Provider | NPC response | Graph",
            "-------|------------------|----------|-------|--------------|----------|---------------|------",
        ]
        for row in rows:
            if not isinstance(row, dict):
                continue
            target = row.get("target") or {}
            graph = row.get("runtimeGraphPath") or {}
            availability = target.get("availability") or {}
            integration = row.get("integration") or {}
            trader = integration.get("traderOverlay") or {}
            lines.append(
                " | ".join(
                    (
                        str(target.get("label") or row.get("label") or "unknown"),
                        str(target.get("targetType") or "unknown"),
                        str(target.get("audience") or "unknown"),
                        str(target.get("route") or "unknown"),
                        str(availability.get("reason") or "available"),
                        "trader" if trader.get("enabled") else "—",
                        str(row.get("npcResponse") or "—").replace("\n", " ")[:72],
                        str(graph.get("kind") or "—"),
                    )
                )
            )
            choices = row.get("semanticHubChoices") or []
            if choices:
                lines.append(
                    "  choices: "
                    + ", ".join(
                        str(item.get("label") or item.get("id"))
                        for item in choices[:6]
                        if isinstance(item, dict)
                    )
                )
        lines.extend(("", "Production evidence:", pretty(result)))
        return "\n".join(lines)

    def _scenario_control_value(self, control: dict[str, Any], scenario: dict[str, Any]) -> Any:
        control_id = str(control.get("id") or "")
        if control_id == "relationship.state":
            projected_relationship = self.simulation_projection.get("relationship", {})
            if isinstance(projected_relationship, dict) and projected_relationship.get("standing"):
                return projected_relationship.get("standing")
            response = self.last_response if isinstance(self.last_response, dict) else {}
            context = response.get("contextAfter") or response.get("context") or {}
            actor = context.get("actorConversationContext", {}) if isinstance(context, dict) else {}
            relationship = actor.get("relationship", {}) if isinstance(actor, dict) else {}
            return relationship.get("state", "unknown")
        if control_id == "relationship.bond":
            relationship_projection = self.simulation_projection.get("relationship", {})
            if isinstance(relationship_projection, dict):
                projected_bond = relationship_projection.get("bond")
                if isinstance(projected_bond, dict):
                    return projected_bond.get("kind") or projected_bond.get("class") or "none"
            bond = self.simulation_projection.get("npc", {}).get("bond", {})
            if isinstance(bond, dict):
                return bond.get("kind") or bond.get("class") or "none"
            return control.get("currentValue", "none")
        if control_id == "relationship.friendBondProgress":
            relationship = self.simulation_projection.get("relationship", {})
            if not isinstance(relationship, dict):
                relationship = {}
            thresholds = relationship.get("friendBondThresholds") or {
                "approval": 80,
                "respect": 50,
                "familiarity": 60,
            }
            return (
                f"Approval {relationship.get('approval', 0)} / {thresholds.get('approval', 80)} · "
                f"Respect {relationship.get('respect', 0)} / {thresholds.get('respect', 50)} · "
                f"Familiarity {relationship.get('familiarity', 0)} / {thresholds.get('familiarity', 60)}"
            )
        if control_id in {
            "relationship.romanceCompatibility",
            "relationship.proposalThreshold",
            "relationship.proposalCooldown",
            "relationship.proposalAvailable",
        }:
            proposal = self.simulation_projection.get("relationship", {})
            if not isinstance(proposal, dict):
                proposal = {}
            if control_id == "relationship.romanceCompatibility":
                return "compatible" if proposal.get("compatible") is True else "incompatible"
            if control_id == "relationship.proposalThreshold":
                thresholds = proposal.get("thresholds") or {}
                return (
                    f"Approval {thresholds.get('approval', 85)} · "
                    f"Respect {thresholds.get('respect', 60)} · "
                    f"Familiarity {thresholds.get('familiarity', 80)}"
                )
            if control_id == "relationship.proposalCooldown":
                return f"{float(proposal.get('cooldownRemaining') or 0):.1f}h"
            return "yes" if proposal.get("eligible") is True else "no"
        if control_id == "npc.personalityMode":
            response = self.last_response if isinstance(self.last_response, dict) else {}
            context = response.get("contextAfter") or response.get("context") or {}
            if isinstance(context, dict) and context.get("npcPersonalityMode"):
                return context.get("npcPersonalityMode")
            return control.get("currentValue", "generated")
        if control_id.startswith("player.socialProfile."):
            key = control_id.rsplit(".", 1)[-1]
            if self.player_social_profile_preview:
                return self.player_social_profile_preview.get(
                    key, control.get("currentValue", "unknown")
                )
            projection = self.simulation_projection.get("player", {})
            profile = projection.get("socialProfile") or self.persona_catalog.get("playerSocialProfile", {})
            response = self.last_response if isinstance(self.last_response, dict) else {}
            context = response.get("contextAfter") or response.get("context") or {}
            if isinstance(context, dict):
                profile = context.get("playerSocialProfile") or profile
            return profile.get(key, control.get("currentValue", "unknown"))
        if control_id == "persona.socialStyle" or control_id.startswith("persona.personality."):
            key = "socialStyle" if control_id == "persona.socialStyle" else control_id.rsplit(".", 1)[-1]
            projection = self.simulation_projection.get("npc", {})
            profile = projection.get("personality") or self.persona_catalog.get("npcPersonality", {})
            response = self.last_response if isinstance(self.last_response, dict) else {}
            context = response.get("contextAfter") or response.get("context") or {}
            if isinstance(context, dict):
                profile = context.get("npcPersonality") or profile
            if key in profile:
                return profile[key]
        if control.get("path") is None:
            return control.get("currentValue")
        value: Any = scenario
        path = control.get("path")
        if isinstance(path, str):
            for segment in path.split("."):
                if not isinstance(value, dict):
                    value = None
                    break
                value = value.get(segment)
        if control_id in {"persona.bondKind", "npc.role"}:
            return value or "none"
        return value

    def _build_simulation_workbench(self) -> None:
        for tab_id in self.workbench_notebook.tabs():
            self.workbench_notebook.forget(tab_id)
        self.workbench_control_fields = {}
        self.workbench_panel_notebooks = {}
        self.trait_effects_var = None
        self.trait_effects_widget = None
        self.trait_effects_widgets = {}
        catalog_controls = self.simulation_control_catalog.get("controls", [])
        if not isinstance(catalog_controls, list):
            catalog_controls = []
        control_limit = min(
            int(self.simulation_control_catalog.get("maxControls", 64) or 64),
            96,
        )
        self.workbench_controls = [
            control
            for control in catalog_controls[:control_limit]
            if (
                isinstance(control, dict)
                and control.get("workbench") is True
                and control.get("workbenchVisible", True) is not False
            )
        ]
        panel_names = ("NPC Target", "Player", "Relationship", "World")
        actor_tabs = ("Overview", "Needs", "Personality & Traits")
        pages: dict[tuple[str, str], WorkbenchPage] = {}
        page_controls: dict[tuple[str, str], list[dict[str, Any]]] = {}

        def page_layout(panel_name: str, tab_name: str) -> str:
            if panel_name in {"NPC Target", "Player"}:
                if tab_name == "Needs":
                    return "stacked"
                if tab_name == "Personality & Traits":
                    return "personality"
                return "two_column"
            return "stacked"

        def section_order(control: dict[str, Any]) -> tuple[int, str]:
            panel_name = str(control.get("workbenchPanel") or "World")
            tab_name = str(control.get("workbenchTab") or "Overview")
            section = str(control.get("workbenchSection") or "")
            if tab_name == "Personality & Traits":
                priority = {
                    "Traits": 0,
                    "Registered traits": 0,
                    "Personality source": 1,
                    "Derived social profile": 2,
                    "Generated personality": 3,
                }
                return priority.get(section, 10), section
            return 0, section

        for panel_name in panel_names:
            panel = self._ttk.Frame(self.workbench_notebook, padding=(6, 2))
            panel.rowconfigure(0, weight=1)
            panel.columnconfigure(0, weight=1)
            self.workbench_notebook.add(panel, text=panel_name)
            if panel_name in {"NPC Target", "Player"}:
                notebook = self._ttk.Notebook(panel)
                notebook.grid(row=0, column=0, sticky="nsew")
                self.workbench_panel_notebooks[panel_name] = notebook
                for tab_name in actor_tabs:
                    page = WorkbenchPage(
                        notebook,
                        self._tk,
                        self._ttk,
                        self._ScrolledText,
                        self,
                        layout=page_layout(panel_name, tab_name),
                    )
                    page.frame.grid(row=0, column=0, sticky="nsew")
                    notebook.add(page.frame, text=tab_name)
                    pages[(panel_name, tab_name)] = page
            else:
                page = WorkbenchPage(
                    panel,
                    self._tk,
                    self._ttk,
                    self._ScrolledText,
                    self,
                    layout=page_layout(panel_name, "Overview"),
                )
                page.frame.grid(row=0, column=0, sticky="nsew")
                pages[(panel_name, "Overview")] = page

        for control in self.workbench_controls:
            panel_name = str(control.get("workbenchPanel") or "World")
            if panel_name not in panel_names:
                panel_name = "World"
            tab_name = str(control.get("workbenchTab") or "Overview")
            if (panel_name, tab_name) not in pages:
                tab_name = "Overview"
            page_controls.setdefault((panel_name, tab_name), []).append(control)

        for page_key, controls in page_controls.items():
            controls.sort(key=section_order)
            page = pages[page_key]
            for control in controls:
                page.add_section(control.get("workbenchSection"))
                field = page.add_control(
                    control,
                    self._scenario_control_value(control, self.scenario),
                )
                control_id = str(control["id"])
                if control_id == "runtime.language":
                    field.variable = self.language_var
                    field.widget.configure(textvariable=self.language_var)
                    self.language_box = field.widget
                self.workbench_control_fields[control_id] = field
                if control_id in {"persona.traits", "player.traits"}:
                    actor = "npc" if control_id == "persona.traits" else "player"
                    title = (
                        "Production trait effects"
                        if actor == "npc"
                        else "Production-derived social profile"
                    )
                    effects_widget = page.add_summary(title, height=4)
                    self.trait_effects_widgets[actor] = effects_widget
                    if actor == "npc":
                        self.trait_effects_widget = effects_widget
            page.finish()
        relationship_page = pages.get(("Relationship", "Overview"))
        if relationship_page is not None:
            self.proposal_button = self._ttk.Button(
                relationship_page.content,
                text="Propose relationship",
                command=self.propose_relationship,
            )
            relationship_page.add_widget(
                self.proposal_button,
                columnspan=4,
                sticky="w",
                pady=(8, 3),
            )
            self.relationship_preview_var = self._tk.StringVar(
                value="Live preview: waiting for production resolver"
            )
            preview_label = self._ttk.Label(
                relationship_page.content,
                textvariable=self.relationship_preview_var,
                justify="left",
                wraplength=560,
            )
            relationship_page.add_widget(
                preview_label,
                columnspan=4,
                sticky="w",
                pady=(2, 6),
            )
            relationship_page.finish()
        override_field = self.workbench_control_fields.get("npc.personalityOverride")
        if override_field is not None and override_field.variable is not None:
            override_field.variable.trace_add(
                "write", self._update_generated_personality_controls
            )
        for key in ("approval", "respect", "familiarity"):
            field = self.workbench_control_fields.get(f"relationship.{key}")
            if field is not None and field.variable is not None:
                field.variable.trace_add("write", self._on_relationship_slider_changed)
        self._update_generated_personality_controls()
        self._render_trait_effects()
        if not self.workbench_controls:
            empty = self._ttk.Frame(self.workbench_notebook, padding=8)
            self._ttk.Label(
                empty,
                text="The Lua worker did not declare any quick simulation controls.",
            ).grid(row=0, column=0, sticky="w")
            self.workbench_notebook.add(empty, text="Context")
        self._set_relationship_preview_from_projection()
        self._set_controls(self.session.ready)
        self._clear_workbench_pending()
        self.root.after_idle(self._restore_workbench_tabs)
        self.root.after_idle(self._restore_ui_state)
        self._schedule_splitter_restore()

    def _update_generated_personality_controls(self, *_args: Any) -> None:
        override_field = self.workbench_control_fields.get("npc.personalityOverride")
        enabled = bool(override_field and override_field.get_value())
        for control in self.workbench_controls:
            if not control.get("requiresOverride"):
                continue
            field = self.workbench_control_fields.get(str(control.get("id") or ""))
            if field is not None:
                field.set_enabled(enabled)
                control_id = str(control.get("id") or "")
                preview_key = (
                    "socialStyle"
                    if control_id == "persona.socialStyle"
                    else control_id.rsplit(".", 1)[-1]
                )
                if not enabled and preview_key in self.generated_personality_preview:
                    field.set_value(
                        self.generated_personality_preview[preview_key]
                    )

    def toggle_simulation_workbench(self) -> None:
        self.workbench_expanded = not self.workbench_expanded
        if self.workbench_expanded:
            self.workbench_content.grid()
            self.workbench_toggle_button.configure(text="Hide controls")
        else:
            self.workbench_content.grid_remove()
            self.workbench_toggle_button.configure(text="Show controls")

    def _selected_npc_profile(self) -> str:
        selected_label = self.npc_profile_var.get()
        return next(
            (value for value in PROFILE_IDS if profile_label(value) == selected_label),
            "custom",
        )

    def _sync_workbench_from_scenario(
        self, scenario: dict[str, Any], *, clear_pending: bool = True
    ) -> None:
        self.npc_profile_var.set(profile_label(profile_id(scenario)))
        self.language_var.set(scenario.get("runtime", {}).get("language", "EN"))
        for control in self.workbench_controls:
            control_id = str(control.get("id") or "")
            field = self.workbench_control_fields.get(control_id)
            if field is not None:
                field.set_value(self._scenario_control_value(control, scenario))
                field.dirty = False
        self.generated_personality_preview = {}
        self.player_social_profile_preview = {}
        self.player_trait_conflicts = []
        self.player_trait_fingerprint = ""
        self._update_generated_personality_controls()
        self._render_trait_effects()
        if clear_pending:
            self._clear_workbench_pending()

    def _collect_workbench_scenario(self) -> dict[str, Any]:
        selected_profile = self._selected_npc_profile()
        draft = deepcopy(self.scenario)
        if selected_profile != profile_id(draft):
            draft = apply_npc_profile(draft, selected_profile)
        values: dict[str, Any] = {}
        override_field = self.workbench_control_fields.get("npc.personalityOverride")
        personality_override = bool(
            override_field and override_field.get_value()
        )
        for control in self.workbench_controls:
            control_id = str(control.get("id") or "")
            field = self.workbench_control_fields.get(control_id)
            if field is None or field.kind == "read_only":
                continue
            if control.get("requiresOverride") and not personality_override:
                continue
            current = self._scenario_control_value(control, draft)
            if field.initial is None and current is None and not field.dirty:
                continue
            values[control_id] = field.get_value()
        return collect_scenario_settings(draft, values, self.simulation_control_catalog)

    def _on_npc_profile(self) -> None:
        """Stage a preset in the shared workbench draft; Apply owns the change."""

        selected = self._selected_npc_profile()
        try:
            staged = apply_npc_profile(self.scenario, selected)
        except ValueError as error:
            self._messagebox.showerror("NPC profile", str(error))
            self.npc_profile_var.set(profile_label(profile_id(self.scenario)))
            return
        self._sync_workbench_from_scenario(staged, clear_pending=False)
        self._workbench_profile_pending = True
        self.activity_log.record(
            "ui",
            "profile_staged",
            label=profile_label(selected),
        )
        self._refresh_workbench_feedback(
            f"{profile_label(selected)} staged · applying automatically…"
        )
        self._schedule_workbench_auto_apply()

    def _record_replay_step(self, step: dict[str, Any]) -> None:
        """Keep a bounded, canonical interaction macro for later replay."""

        if not isinstance(step, dict):
            return
        recorded = deepcopy(step)
        recorded.pop("requestRevision", None)
        self.replay_steps.append(recorded)
        self.replay_steps = self.replay_steps[-32:]
        self.activity_log.record(
            "ui",
            "replay_step_recorded",
            index=len(self.replay_steps),
            kind=str(recorded.get("kind") or "unknown"),
            candidateID=str(recorded.get("candidateID") or ""),
            text=str(recorded.get("text") or "")[:180],
        )
        self._refresh_workbench_feedback(
            f"Recorded replay step {len(self.replay_steps)}."
        )

    @staticmethod
    def _replay_projection_frame(
        worker: LuaSemanticWorker,
        step: dict[str, Any],
    ) -> dict[str, Any] | None:
        """Resolve a recorded choice against the worker's current revision."""

        snapshot = worker.snapshot()
        suggestions = snapshot.get("suggestions") or {}
        candidate_id = str(step.get("candidateID") or "")
        for group in suggestions.get("groups", []) or []:
            if not isinstance(group, dict):
                continue
            for collection_name in ("navigation", "candidates", "capabilities"):
                for row in group.get(collection_name, []) or []:
                    if not isinstance(row, dict) or str(row.get("id") or "") != candidate_id:
                        continue
                    frame = row.get("frame")
                    if isinstance(frame, dict):
                        return deepcopy(frame)
        frame = step.get("frame")
        if not isinstance(frame, dict):
            return None
        frame = deepcopy(frame)
        revision = suggestions.get("revision")
        if revision is not None:
            frame["requestRevision"] = revision
        return frame

    @classmethod
    def _replay_step(
        cls, worker: LuaSemanticWorker, step: dict[str, Any]
    ) -> dict[str, Any]:
        kind = str(step.get("kind") or "input")
        if kind == "input":
            return worker.input(str(step.get("text") or ""))
        frame = cls._replay_projection_frame(worker, step)
        if frame is not None:
            return worker.suggestion_click(frame)
        return worker.input(str(step.get("text") or ""))

    def apply_simulation_settings(
        self, replay: bool = False, *, automatic: bool = False
    ) -> None:
        """Apply the catalog-backed draft, optionally replaying a real utterance."""

        if not self.session.ready or self.busy:
            if automatic and not self.busy:
                self._schedule_workbench_auto_apply()
            return
        current_text = self.input_var.get().strip()
        value = current_text or self.last_test_utterance.strip()
        steps = deepcopy(self.replay_steps)
        if replay and current_text:
            if not steps or steps[-1].get("text") != current_text:
                steps.append({"kind": "input", "text": current_text})
        if replay and not steps and value:
            steps = [{"kind": "input", "text": value}]
        if replay and not steps:
            self.workbench_status_var.set("Record a dialogue step before replaying.")
            return
        try:
            updated = self._collect_workbench_scenario()
        except (TypeError, ValueError, self._tk.TclError) as error:
            self._messagebox.showerror("Simulation workbench", str(error))
            return
        self.activity_log.record(
            "ui",
            "apply_started",
            replay=replay,
            automatic=automatic,
            pending=", ".join(self._pending_control_labels()),
        )

        def operation(worker: LuaSemanticWorker) -> dict[str, Any]:
            configured = worker.configure(updated)
            if not replay:
                # CONFIG resets the production conversation view. Fetch that
                # same view once so automatic edits cannot leave stale
                # suggestions, graph nodes, or projection text on screen.
                return {"configured": configured, "snapshot": worker.snapshot()}
            step_results: list[dict[str, Any]] = []
            for step in steps:
                response = self._replay_step(worker, step)
                step_results.append({"step": step, "response": response})
                if response.get("accepted") is not True:
                    break
            return {
                "configured": configured,
                "steps": step_results,
                "snapshot": worker.snapshot(),
            }

        def finish(result: dict[str, Any]) -> None:
            final_snapshot = result.get("snapshot") or {}
            effective_scenario = (
                final_snapshot.get("scenario")
                if isinstance(final_snapshot, dict)
                and isinstance(final_snapshot.get("scenario"), dict)
                else updated
            )
            self.scenario = effective_scenario
            configured = result.get("configured") or {}
            rendered_state = final_snapshot if isinstance(final_snapshot, dict) else configured
            self._update_simulation_projection(rendered_state)
            self._sync_workbench_from_scenario(effective_scenario)
            if replay:
                response = {}
                self._set_text(self.transcript, "")
                self._append(
                    "SYSTEM",
                    f"Replaying {len(result.get('steps') or [])} recorded dialogue steps.",
                )
                for item in result.get("steps") or []:
                    step = item.get("step") or {}
                    step_response = item.get("response") or {}
                    response = step_response
                    if step_response.get("accepted") is not True:
                        self._append(
                            "SYSTEM",
                            f"Replay step rejected: {step_response.get('reason') or 'unknown'}",
                        )
                        break
                    step_kind = str(step.get("kind") or "input")
                    frame_kind = str(
                        (step.get("frame") or {}).get("kind") or ""
                    )
                    if step_kind == "input" or frame_kind not in {
                        "semantic_back_click_frame",
                        "semantic_group_click_frame",
                    }:
                        text = str(
                            step.get("text")
                            or step.get("label")
                            or step.get("candidateID")
                            or "choice"
                        )
                        self.last_test_utterance = text
                        self._append("PLAYER", text)
                    elif frame_kind == "semantic_back_click_frame":
                        for message in step_response.get(
                            "transcriptMessages", []
                        ):
                            if message.get("speaker") == "player":
                                self._append(
                                    "PLAYER",
                                    str(message.get("value") or ""),
                                )
                    for message in step_response.get("messages", []):
                        if message.get("speaker") == "npc":
                            self._append("NPC", npc_message_text(message))
                    for call in step_response.get("toolCalls", []):
                        self._append("TOOL/ACTION", format_tool_call(call))
                self.input_var.set("")
                self._show_response(response)
                self._append(
                    "SYSTEM",
                    f"Applied simulation context and replayed {len(result.get('steps') or [])} steps.",
                )
                self._refresh_workbench_feedback(
                    "Applied and replayed through the Lua worker."
                )
            else:
                response = rendered_state
                # The worker reset is authoritative, so clear the old visual
                # conversation and render the returned production snapshot.
                self._set_text(self.transcript, "")
                self._show_response(response)
                message = (
                    "Auto-applied staged changes through the Lua worker."
                    if automatic
                    else "Applied simulation workbench settings to the Lua worker."
                )
                self._append("SYSTEM", message)
                self._refresh_workbench_feedback(
                    "Auto-applied staged changes through the Lua worker."
                    if automatic
                    else "Applied to the Lua worker."
                )
            self.activity_log.record(
                "ui",
                "apply_completed",
                replay=replay,
                automatic=automatic,
                message="simulation settings applied",
            )

        self._refresh_workbench_feedback(
            "Applying staged changes through the Lua worker…"
        )
        self._start_operation(operation, finish)

    def _start_operation(
        self,
        operation: Callable[[LuaSemanticWorker], Any],
        callback: Callable[[Any], None],
    ) -> bool:
        if self.closed or not self.session.ready or self.busy:
            return False
        self.busy = True
        self._set_status("Working…")
        self._set_controls(False)
        self._future = self.session.submit(operation)
        self._poll_future(self._future, self._operation_finished(callback))
        return True

    def _operation_finished(self, callback: Callable[[Any], None]) -> Callable[[Any], None]:
        def finish(result: WorkerResult[Any]) -> None:
            self._set_controls(True)
            self._set_status(f"Ready · Lua PID {result.status.get('pid')}")
            callback(result.value)

        return finish

    def _show_operation_error(self, error: Exception) -> None:
        self.busy = False
        self._set_controls(self.session.ready)
        self._set_status("Worker error")
        self._set_text(self.trace, str(error))
        self._messagebox.showerror("Harness error", str(error))

    @staticmethod
    def _provenance_value(value: Any, depth: int = 2) -> Any:
        """Keep the provenance inspector readable for large saved records."""

        if isinstance(value, dict):
            if depth <= 0:
                return {"keys": len(value)}
            keys = sorted(value, key=lambda item: str(item).casefold())
            output = {
                str(key): SemanticHarnessApp._provenance_value(
                    value[key], depth - 1
                )
                for key in keys[:12]
            }
            if len(keys) > 12:
                output["_omittedKeys"] = len(keys) - 12
            return output
        if isinstance(value, list):
            if depth <= 0:
                return {"count": len(value)}
            return {
                "count": len(value),
                "sample": [
                    SemanticHarnessApp._provenance_value(item, depth - 1)
                    for item in value[:3]
                ],
            }
        return deepcopy(value)

    @staticmethod
    def _value_at_path(value: Any, path: str) -> Any:
        current = value
        for segment in path.split("."):
            if not isinstance(current, dict):
                return None
            current = current.get(segment)
        return current

    def _update_source_provenance(self, response: dict[str, Any]) -> None:
        if not isinstance(response, dict):
            return
        source = response.get("sourceSnapshot")
        working = response.get("workingWorld")
        if isinstance(source, dict):
            self.source_snapshot_projection = deepcopy(source)
        if isinstance(working, dict):
            self.working_world_projection = deepcopy(working)
        source = self.source_snapshot_projection
        working = self.working_world_projection
        if not isinstance(source, dict) or not isinstance(working, dict):
            return
        source_data = source.get("data") if isinstance(source.get("data"), dict) else {}
        effective = response.get("scenario")
        if not isinstance(effective, dict):
            effective = working.get("effective")
        if not isinstance(effective, dict):
            effective = {}
        metadata = source.get("metadata") if isinstance(source.get("metadata"), dict) else {}
        provenance = source.get("provenance") if isinstance(source.get("provenance"), dict) else {}
        path_sources = provenance.get("paths") if isinstance(provenance.get("paths"), dict) else {}
        patches = working.get("patches") if isinstance(working.get("patches"), list) else []
        patch_sources = {
            str(patch.get("path")): patch
            for patch in patches
            if isinstance(patch, dict) and patch.get("path")
        }
        important_paths = (
            "npc.relationship.baselineApproval",
            "npc.relationship.baselineRespect",
            "npc.relationship.approval",
            "npc.relationship.respect",
            "npc.relationship.familiarity",
            "npc.relationship.state",
            "npc.relationship.previousState",
            "npc.relationship.bond",
            "npc.relationship.memories",
            "npc.relationship.cooldowns",
            "npc.relationship.interactionJournal",
            "npc.relationship.interactionRevision",
            "npc.relationship.revision",
            "world.weather",
            "world.timeOfDay",
            "world.temperature",
            "world.season",
            "player.needs",
            "npc.needs",
            "player.inventory.revision",
            "npc.inventory.revision",
        )
        fields: dict[str, Any] = {}
        for path in important_paths:
            imported = self._value_at_path(source_data, path)
            current = self._value_at_path(effective, path)
            patch = patch_sources.get(path)
            source_info = path_sources.get(path)
            source_info = source_info if isinstance(source_info, dict) else {}
            origin = (
                str(patch.get("source"))
                if patch is not None
                else str(source_info.get("source") or metadata.get("sourceKind") or "MISSING")
            )
            fields[path] = {
                "imported": self._provenance_value(imported),
                "effective": self._provenance_value(current),
                "source": origin,
                "baseSource": str(
                    patch.get("baseSource")
                    if patch is not None
                    else source_info.get("source")
                    or metadata.get("sourceKind")
                    or "MISSING"
                ),
                "provider": source_info.get("provider"),
            }
        self.provenance_projection = {
            "schema": "semantic.ui.provenance_projection.v1",
            "source": {
                "kind": metadata.get("sourceKind", "MISSING"),
                "id": metadata.get("sourceID"),
                "mode": metadata.get("mode"),
                "immutable": source.get("immutable") is True
                or metadata.get("immutable") is True,
            },
            "workingWorld": {
                "schema": working.get("schema"),
                "sourceSnapshotID": working.get("sourceSnapshotID"),
                "resetCount": working.get("resetCount", 0),
                "patchCount": len(patches),
            },
            "fields": fields,
        }
        simulation = response.get("simulationProjection")
        projected_relationship = (
            simulation.get("relationship")
            if isinstance(simulation, dict)
            else None
        )
        if isinstance(projected_relationship, dict):
            self.provenance_projection["relationshipAuthority"] = {
                "authority": "PNC.RelationshipGraph + PNC.RelationshipPresentation",
                "record": self._provenance_value(
                    projected_relationship.get("record")
                ),
                "graph": self._provenance_value(
                    projected_relationship.get("productionGraph")
                ),
                "presentation": self._provenance_value(
                    projected_relationship.get("productionPresentation")
                ),
            }
        if getattr(self, "provenance_status_var", None) is not None:
            self.provenance_status_var.set(
                f"Source: {metadata.get('sourceKind', 'MISSING')} · "
                f"working overrides: {len(patches)} · immutable source snapshot"
            )
        if hasattr(self, "provenance_inspector"):
            self._set_text(self.provenance_inspector, pretty(self.provenance_projection))

    def _update_simulation_projection(self, response: dict[str, Any]) -> None:
        self._update_source_provenance(response)
        projection = response.get("simulationProjection") if isinstance(response, dict) else None
        if isinstance(projection, dict):
            self.simulation_projection = projection
            npc_projection = projection.get("npc", {})
            bond = npc_projection.get("bond") if isinstance(npc_projection, dict) else None
            if isinstance(bond, dict):
                self.scenario.setdefault("npc", {}).setdefault("relationship", {})[
                    "bond"
                ] = deepcopy(bond)
            for control_id in (
                "relationship.state",
                "relationship.bond",
                "relationship.friendBondProgress",
                "relationship.romanceCompatibility",
                "relationship.proposalThreshold",
                "relationship.proposalCooldown",
                "relationship.proposalAvailable",
            ):
                field = self.workbench_control_fields.get(control_id)
                control = next(
                    (item for item in self.workbench_controls if item.get("id") == control_id),
                    None,
                )
                if field is not None and control is not None:
                    field.set_value(self._scenario_control_value(control, self.scenario))
            self._set_relationship_preview_from_projection()
            self._update_generated_personality_controls()

    def _set_relationship_preview_from_projection(self) -> None:
        if self.relationship_preview_var is None:
            return
        proposal = self.simulation_projection.get("relationship", {})
        if not isinstance(proposal, dict):
            proposal = {}
        standing = str(proposal.get("standing") or "unknown").upper()
        reason = str(proposal.get("reason") or "production resolver")
        bond = proposal.get("bond") or {}
        bond_class = bond.get("class") if isinstance(bond, dict) else "none"
        self.relationship_preview_var.set(
            f"Live preview: {standing} · {reason} · durable bond: {bond_class or 'none'}"
        )

    def _on_relationship_slider_changed(self, *_args: Any) -> None:
        if self.closed or not self.worker_ready or self.busy:
            return
        # The field dirty callback already coalesces this edit into the one
        # production CONFIG boundary. A second preview request used to race
        # that CONFIG and made slider edits look stale while adding latency.
        self._schedule_workbench_auto_apply()
        if self.auto_replay_var is not None and self.auto_replay_var.get():
            if self._auto_replay_after is not None:
                try:
                    self.root.after_cancel(self._auto_replay_after)
                except self._tk.TclError:
                    pass
            self._auto_replay_after = self.root.after(
                650, self.apply_and_replay
            )

    def _request_relationship_preview(self) -> None:
        self._relationship_preview_after = None
        if self.closed or not self.worker_ready or self.busy:
            return
        if self._relationship_preview_future is not None:
            if not self._relationship_preview_future.done():
                self._relationship_preview_after = self.root.after(
                    140, self._request_relationship_preview
                )
                return
        values = {}
        for key in ("approval", "respect", "familiarity"):
            field = self.workbench_control_fields.get(f"relationship.{key}")
            if field is not None:
                values[key] = field.get_value()
        try:
            future = self.session.submit(
                lambda worker: worker.relationship_preview(values)
            )
        except (HarnessError, RuntimeError):
            return
        self._relationship_preview_future = future
        self._poll_relationship_preview(future)

    def _poll_relationship_preview(self, future: Future[Any]) -> None:
        if self.closed:
            return
        if not future.done():
            self.root.after(25, self._poll_relationship_preview, future)
            return
        try:
            result = future.result()
            value = result.value if hasattr(result, "value") else result
        except (HarnessError, ConfigurationError, OSError, ValueError) as error:
            self._set_text(self.trace, str(error))
            return
        preview = value if isinstance(value, dict) else {}
        if self.relationship_preview_var is not None:
            standing = str(preview.get("standing") or "unknown").upper()
            reason = str(preview.get("reason") or "production resolver")
            bond = preview.get("bond") or {}
            bond_class = bond.get("class") if isinstance(bond, dict) else "none"
            self.relationship_preview_var.set(
                f"Live preview: {standing} · {reason} · durable bond: {bond_class or 'none'}"
            )
        self._set_relationship_preview_fields(preview)

    def _set_relationship_preview_fields(self, preview: dict[str, Any]) -> None:
        relationship = {
            "approval": preview.get("approval"),
            "respect": preview.get("respect"),
            "familiarity": preview.get("familiarity"),
        }
        proposal = preview.get("proposal") or {}
        if isinstance(proposal, dict):
            proposal = dict(proposal)
            proposal["compatible"] = proposal.get("compatible")
            proposal["bond"] = preview.get("bond")
        projection = dict(self.simulation_projection)
        projection["relationship"] = {
            **(projection.get("relationship") or {}),
            **relationship,
            "standing": preview.get("standing"),
            "reason": preview.get("reason"),
            "bond": preview.get("bond"),
            "compatible": proposal.get("compatible") if isinstance(proposal, dict) else None,
            "eligible": proposal.get("eligible") if isinstance(proposal, dict) else None,
            "cooldownRemaining": proposal.get("cooldownRemaining") if isinstance(proposal, dict) else 0,
            "thresholds": proposal.get("thresholds") if isinstance(proposal, dict) else {},
        }
        self.simulation_projection = projection
        try:
            for control_id in (
                "relationship.state",
                "relationship.bond",
                "relationship.friendBondProgress",
                "relationship.romanceCompatibility",
                "relationship.proposalThreshold",
                "relationship.proposalCooldown",
                "relationship.proposalAvailable",
            ):
                field = self.workbench_control_fields.get(control_id)
                control = next(
                    (item for item in self.workbench_controls if item.get("id") == control_id),
                    None,
                )
                if field is not None and control is not None:
                    field.set_value(self._scenario_control_value(control, self.scenario))
        finally:
            self.simulation_projection = projection

    def _show_response(self, response: dict[str, Any]) -> None:
        self.last_response = response if isinstance(response, dict) else {}
        self._update_simulation_projection(self.last_response)
        relationship_field = self.workbench_control_fields.get("relationship.state")
        if relationship_field is not None:
            relationship_control = next(
                (
                    control for control in self.workbench_controls
                    if control.get("id") == "relationship.state"
                ),
                None,
            )
            if relationship_control is not None:
                relationship_field.set_value(
                    self._scenario_control_value(relationship_control, self.scenario)
                )
        inspector_record = dict(self.last_response)
        inspector_record["personaCatalog"] = self.persona_catalog
        view = build_conversation_inspector(inspector_record)
        self._set_text(self.inspector, conversation_first(view))
        self._set_text(self.authority, pretty(view.get("commandAuthority", {})))
        self._set_text(self.trace, pretty(response))
        observation = response.get("observation") or {}
        conversation_graph = observation.get("conversationGraph")
        if conversation_graph is None:
            conversation_graph = response.get("conversationGraph")
        if isinstance(conversation_graph, dict):
            self.dialogue_graph_pane.set_graph(conversation_graph)
        self.suggestion_frame.configure(
            text=(
                "Current player choices"
                if observation.get("conversationBlock")
                or response.get("conversationBlock")
                else "Contextual semantic suggestions"
            )
        )
        suggestions = (
            observation.get("suggestions")
            or response.get("suggestions")
            or {}
        )
        hub_diagnostics = semantic_hub_diagnostic_projection(suggestions)
        self._set_text(self.hub_diagnostics, pretty(hub_diagnostics))
        self._render_suggestions(response, suggestions)
        if isinstance(conversation_graph, dict):
            self.trace_tabs.select(self.dialogue_graph_frame)
        elif hub_diagnostics.get("activeHub") is not None:
            self.trace_tabs.select(self.hub_diagnostics_frame)

    def _on_suggestion_group(self) -> None:
        if not self.suggestion_projection:
            return
        selected_display = self.suggestion_group_box.get()
        selected_id = self.suggestion_group_ids_by_display.get(selected_display)
        group = next(
            (
                item
                for item in self.suggestion_projection.get("groups", [])
                if item.get("id") == selected_id
            ),
            None,
        )
        frame = group and group.get("frame")
        if (
            isinstance(frame, dict)
            and self.session.ready
            and not self.busy
        ):
            def finish(response: dict[str, Any]) -> None:
                if response.get("accepted") is not True:
                    self._append(
                        "SYSTEM",
                        f"Topic selection rejected: "
                        f"{response.get('reason') or 'unknown'}",
                    )
                self._show_response(response)

            self._start_operation(
                lambda worker: worker.suggestion_click(frame), finish
            )
            return
        self._render_suggestions(
            self.suggestion_response, self.suggestion_projection
        )

    def _render_suggestions(
        self, response: dict[str, Any], suggestions: dict[str, Any]
    ) -> None:
        self.suggestion_projection = suggestions
        self.suggestion_response = response
        groups = suggestions.get("groups") or []
        group_ids: list[str] = []
        group_display_by_id: dict[str, str] = {}
        self.suggestion_group_ids_by_display = {}
        for group in groups:
            group_id = str(group.get("id") or "")
            if not group_id:
                continue
            display = str(group.get("label") or group_id)
            if display in self.suggestion_group_ids_by_display:
                display = f"{display} [{group_id}]"
            group_ids.append(group_id)
            group_display_by_id[group_id] = display
            self.suggestion_group_ids_by_display[display] = group_id
        group_displays = [group_display_by_id[group_id] for group_id in group_ids]
        self.suggestion_group_box.configure(values=group_displays)
        if len(group_displays) <= 1:
            self.suggestion_group_box.grid_remove()
        else:
            self.suggestion_group_box.grid(
                row=1, column=2, sticky="e", padx=3, pady=(0, 2)
            )
        revision = suggestions.get("revision")
        selected_group_id = (
            suggestions.get("currentGroupID")
            if self.suggestion_revision != revision
            else self.suggestion_group_ids_by_display.get(
                self.suggestion_group_box.get(),
                suggestions.get("currentGroupID"),
            )
        )
        if selected_group_id not in group_ids:
            selected_group_id = suggestions.get("currentGroupID") or (
                group_ids[0] if group_ids else ""
            )
        self.suggestion_group_box.set(group_display_by_id.get(selected_group_id, ""))
        self.suggestion_revision = revision
        self.suggestion_rows = semantic_suggestion_rows(
            suggestions, selected_group_id or None
        )
        self._ensure_suggestion_buttons(len(self.suggestion_rows))
        self.suggestion_interactive = (
            response.get("type") in {"turn", "semantic_click"}
            and response.get("accepted") is True
        )
        for index, button in enumerate(self.suggestion_buttons):
            row = self.suggestion_rows[index] if index < len(self.suggestion_rows) else None
            if row:
                button.configure(text=semantic_suggestion_title(row))
                button.grid()
            else:
                button.configure(text="")
                button.grid_remove()
        revision = suggestions.get("revision", "—")
        trace_count = len(suggestions.get("predicateTrace") or [])
        self.suggestion_status.configure(
            text=(
                f"{self.suggestion_group_box.get() or 'Suggestions'} · "
                f"Revision {revision} · {len(self.suggestion_rows)} visible · "
                f"{trace_count} bounded predicate trace rows"
            )
        )
        self._set_text(
            self.suggestion_inspector,
            pretty(
                {
                    "projection": suggestions,
                    "visualRows": [
                        {
                            "id": row.get("id"),
                            "action": row.get("action"),
                            "label": semantic_suggestion_title(row),
                            "status": row.get("status"),
                            "enabled": row.get("enabled"),
                            "source": row.get("source"),
                            "eligibility": row.get("eligibility"),
                        }
                        for row in self.suggestion_rows
                    ],
                }
            ),
        )
        self._refresh_suggestion_controls(self.session.ready and not self.busy)

    def submit(self) -> None:
        value = self.input_var.get().strip()
        if not value or not self.session.ready or self.busy:
            return
        self.input_var.set("")
        self.last_test_utterance = value
        self.compare_utterance_var.set(value)

        def finish(response: dict[str, Any]) -> None:
            self._append("PLAYER", value)
            for message in response.get("messages", []):
                if message.get("speaker") == "npc":
                    self._append("NPC", npc_message_text(message))
            for call in response.get("toolCalls", []):
                self._append("TOOL/ACTION", format_tool_call(call))
            if response.get("accepted") is True:
                self._record_replay_step({"kind": "input", "text": value})
            self._show_response(response)

        self._start_operation(lambda worker: worker.input(value), finish)

    def click_suggestion(self, index: int) -> None:
        if not self.session.ready or self.busy or not self.suggestion_interactive:
            return
        if index < 0 or index >= len(self.suggestion_rows):
            return
        row = self.suggestion_rows[index]
        frame = row.get("frame")
        if not isinstance(frame, dict) or row.get("enabled") is not True:
            return
        label = semantic_suggestion_title(row)

        def finish(response: dict[str, Any]) -> None:
            if response.get("accepted") is True:
                utterance = (row.get("display") or {}).get("utterance") or label
                self.last_test_utterance = str(utterance)
                presentation_only = str(
                    frame.get("kind") or ""
                ) in {"semantic_back_click_frame", "semantic_group_click_frame"}
                if not presentation_only:
                    self._append("PLAYER", str(utterance))
                for message in response.get("messages", []):
                    if message.get("speaker") == "npc":
                        self._append("NPC", npc_message_text(message))
                for call in response.get("toolCalls", []):
                    self._append("TOOL/ACTION", format_tool_call(call))
                self._append("SYSTEM", f"Clicked semantic suggestion: {label}")
                self._record_replay_step(
                    {
                        "kind": "suggestion_click",
                        "candidateID": frame.get("candidateID") or row.get("id"),
                        "label": label,
                        "text": str(utterance),
                        "frame": deepcopy(frame),
                    }
                )
            else:
                self._append(
                    "SYSTEM",
                    f"Suggestion rejected: {response.get('reason') or 'unknown'}",
                )
            self._show_response(response)

        self._start_operation(lambda worker: worker.suggestion_click(frame), finish)

    def click_graph_frame(self, frame: dict[str, Any]) -> bool:
        """Submit a live graph edge through the exact suggestion-click lane."""

        if not self.session.ready or self.busy or not isinstance(frame, dict):
            return False
        label = str(frame.get("textFallback") or frame.get("candidateID") or "choice")

        def finish(response: dict[str, Any]) -> None:
            if response.get("accepted") is True:
                self.last_test_utterance = label
                self._append("PLAYER", label)
                for message in response.get("messages", []):
                    if message.get("speaker") == "npc":
                        self._append("NPC", npc_message_text(message))
                for call in response.get("toolCalls", []):
                    self._append("TOOL/ACTION", format_tool_call(call))
                self._record_replay_step(
                    {
                        "kind": "suggestion_click",
                        "candidateID": frame.get("candidateID"),
                        "label": label,
                        "text": label,
                        "frame": deepcopy(frame),
                    }
                )
            else:
                self._append(
                    "SYSTEM",
                    f"Graph choice rejected: {response.get('reason') or 'unknown'}",
                )
            self._show_response(response)

        return self._start_operation(
            lambda worker: worker.suggestion_click(frame), finish
        )

    def show_conversation_graph_diagnostics(
        self, diagnostics: dict[str, Any]
    ) -> None:
        self._set_text(self.dialogue_diagnostics, pretty(diagnostics))
        self.trace_tabs.select(self.dialogue_diagnostics_frame)

    def preview(self) -> None:
        """Inspect a production decision without recording or dispatching it."""

        value = self.input_var.get().strip()
        if not value or not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._show_response(response)
            self._append("SYSTEM", f"Preview only; no state or action mutation: {value}")

        self._start_operation(lambda worker: worker.preview(value), finish)

    def reset(self) -> None:
        if not self.session.ready:
            return

        def finish(response: dict[str, Any]) -> None:
            self.replay_steps.clear()
            self._set_text(self.transcript, "")
            self._set_text(self.inspector, "")
            self._set_text(self.authority, "")
            self._set_text(self.trace, "")
            self._set_text(self.suggestion_inspector, "")
            self._set_text(self.world_knowledge_inspector, "")
            self._set_text(self.dialogue_diagnostics, "")
            self._set_text(self.compare_output, "")
            self.dialogue_graph_pane.clear_graph()
            self._set_text(
                self.hub_diagnostics,
                pretty(semantic_hub_diagnostic_projection({})),
            )
            self.suggestion_rows = []
            self.suggestion_interactive = False
            self._refresh_workbench_feedback("Scenario reset; replay macro cleared.")
            self.compare_utterance_var.set("hello")
            self._render_suggestions(
                {"type": "turn", "accepted": True},
                response.get("suggestions") or {},
            )
            self._append("SYSTEM", "Scenario reset.")

        self._start_operation(lambda worker: worker.reset(), finish)

    def load(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Load semantic scenario",
            filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
        )
        if not filename or not self.session.ready or self.busy:
            return
        try:
            scenario = load_scenario(Path(filename))
        except (OSError, ValueError) as error:
            self._messagebox.showerror("Scenario error", str(error))
            return

        def finish(response: dict[str, Any]) -> None:
            self.scenario = scenario
            self.scenario_path = Path(filename)
            self.replay_steps.clear()
            self._sync_workbench_from_scenario(scenario)
            self._refresh_workbench_feedback("Scenario loaded; replay macro cleared.")
            self._set_text(self.transcript, "")
            self._show_response(response)
            self._append("SYSTEM", f"Loaded {filename}")

        self._start_operation(lambda worker: worker.configure(scenario), finish)

    def save(self) -> None:
        """Persist the current in-memory scenario to its JSON scenario store."""

        if self.busy:
            return
        filename = self.scenario_path
        if filename is None:
            selected = self._filedialog.asksaveasfilename(
                title="Save semantic scenario",
                defaultextension=".json",
                filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
            )
            if not selected:
                return
            filename = Path(selected)
        try:
            save_scenario(filename, self.scenario)
        except (OSError, TypeError, ValueError) as error:
            self._messagebox.showerror("Scenario save error", str(error))
            return
        self.scenario_path = filename
        self._set_status(f"Saved scenario · {filename.name}")
        self._append("SYSTEM", f"Saved mock runtime scenario to {filename}")

    def open_runtime_settings(self) -> None:
        show_runtime_settings(self)

    def show_snapshot(self) -> None:
        if not self.session.ready:
            return
        self._start_operation(
            lambda worker: worker.snapshot(),
            self._show_response,
        )

    def propose_relationship(self) -> None:
        """Submit the one canonical relationship proposal action."""

        if not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._show_response(response)
            proposal = response.get("proposal") or {}
            if response.get("accepted") is True:
                message = "NPC accepted the relationship proposal."
            elif response.get("reason"):
                message = f"Relationship proposal: {response['reason']}"
            else:
                message = "NPC rejected the relationship proposal."
            self._append("SYSTEM", message)
            self.workbench_status_var.set(message)

        self._start_operation(
            lambda worker: worker.relationship_proposal(),
            finish,
        )

    def capture_baseline(self) -> None:
        """Capture the current utterance through the production preview path."""

        value = self._comparison_utterance()
        if not value or not self.session.ready or self.busy:
            return

        def finish(result: dict[str, Any]) -> None:
            self.baseline_record = result
            self._show_response(result.get("preview") or {})
            self._set_text(self.compare_output, pretty(result))
            self._append("SYSTEM", f"Captured production baseline: {value}")

        self._start_operation(lambda worker: worker.capture_baseline(value), finish)

    def apply_and_replay(self) -> None:
        """Apply the current workbench draft, then replay the latest utterance."""

        self.apply_simulation_settings(replay=True)

    def _comparison_utterance(self) -> str:
        """Return the explicit Compare utterance or the current test input."""

        return (
            self.input_var.get().strip()
            or self.compare_utterance_var.get().strip()
            or self.last_test_utterance.strip()
            or "hello"
        )

    def inspect_persona_matrix(self) -> None:
        """Run a small production-backed persona A/B matrix in one worker."""

        if not self.session.ready or self.busy:
            return
        base = deepcopy(self.scenario)
        dimension = self.matrix_dimension_var.get() or "persona"
        rows = [
            merge(
                base,
                {"runtime": {"semanticLabMatrixLabel": f"A / baseline · {dimension}"}},
            )
        ]

        def add_relationship_variants(field: str, values: tuple[tuple[str, int], ...]) -> None:
            rows.extend(
                merge(
                    base,
                    {
                        "runtime": {
                            "semanticLabMatrixLabel": f"{label} · {dimension}"
                        },
                        "npc": {"relationship": {field: value}},
                    },
                )
                for label, value in values
            )

        if dimension == "approval":
            add_relationship_variants("approval", (("B / low", -80), ("C / high", 80)))
        elif dimension == "respect":
            add_relationship_variants("respect", (("B / low", -60), ("C / high", 70)))
        elif dimension == "familiarity":
            add_relationship_variants("familiarity", (("B / low", 5), ("C / high", 100)))
        elif dimension == "bond":
            for label, relationship in (
                ("B / mother", {"relationshipKind": "mother"}),
                ("C / lover", {"relationshipKind": "lover"}),
            ):
                rows.append(
                    merge(
                        base,
                        {
                            "runtime": {
                                "semanticLabMatrixLabel": f"{label} · {dimension}"
                            },
                            "npc": {"startingRelationship": relationship},
                        },
                    )
                )
        elif dimension == "language":
            for label, language in (("B / EN", "EN"), ("C / TL", "TL")):
                rows.append(
                    merge(
                        base,
                        {
                            "runtime": {
                                "semanticLabMatrixLabel": f"{label} · {dimension}",
                                "language": language,
                            }
                        },
                    )
                )
        else:
            rows.extend(
                [
                    merge(
                        base,
                        {
                            "runtime": {"semanticLabMatrixLabel": "B / warm · persona"},
                            "npc": {
                                "traits": ["pnc_friendly"],
                                "personality": {
                                    "socialStyle": "friendly",
                                    "compassion": 0.9,
                                    "sociability": 0.9,
                                    "aggression": 0.1,
                                },
                            },
                        },
                    ),
                    merge(
                        base,
                        {
                            "runtime": {"semanticLabMatrixLabel": "C / guarded · persona"},
                            "npc": {
                                "traits": ["pnc_reserved"],
                                "personality": {
                                    "socialStyle": "withdrawn",
                                    "compassion": 0.1,
                                    "sociability": 0.2,
                                    "aggression": 0.9,
                                },
                            },
                        },
                    ),
                ]
            )

        value = self._comparison_utterance()
        self.compare_utterance_var.set(value)

        def finish(result: dict[str, Any]) -> None:
            self._set_text(self.compare_output, self._format_compare_result(result))
            self.trace_tabs.select(self.compare_frame)
            self._append(
                "SYSTEM",
                f"Comparison by {dimension} completed through the real Lua worker: {value}",
            )

        self._start_operation(
            lambda worker: worker.context_matrix(rows, text=value, maximum=3),
            finish,
        )

    def _format_compare_result(self, result: dict[str, Any]) -> str:
        """Render the bounded matrix as an understandable A/B/C comparison."""

        rows = result.get("rows") if isinstance(result, dict) else None
        if not isinstance(rows, list) or not rows:
            return pretty(result)
        lines = [
            f"Compare · {result.get('schema', 'production matrix')}",
            "",
            "Case | NPC response | Standing | Durable bond | Speech style | Graph",
            "-----|---------------|----------|--------------|--------------|------",
        ]
        for index, row in enumerate(rows):
            if not isinstance(row, dict):
                continue
            relationship = row.get("relationship") or {}
            bond = relationship.get("bond") or {}
            speech = row.get("speechStyleContext") or {}
            graph = row.get("runtimeGraphPath") or {}
            label = row.get("label") or chr(ord("A") + index)
            response = str(row.get("npcResponse") or "").replace("\n", " ")
            style = str(speech.get("variant") or speech.get("schema") or "—")
            graph_kind = str(graph.get("kind") or "—")
            lines.append(
                " | ".join(
                    (
                        str(label),
                        response[:80],
                        str(relationship.get("standing") or "unknown"),
                        str(bond.get("class") or "none"),
                        style,
                        graph_kind,
                    )
                )
            )
            choices = row.get("semanticHubChoices") or []
            lines.append(
                f"  choices: {', '.join(str(item.get('label') or item.get('id')) for item in choices[:4] if isinstance(item, dict)) or 'none'}"
            )
        lines.extend(("", "Full production evidence:", pretty(result)))
        return "\n".join(lines)

    def inspect_world_knowledge(self) -> None:
        """Render bounded World Knowledge evidence from the live Lua worker."""

        if not self.session.ready or self.busy:
            return
        npc = self.scenario.get("npc", {})
        actor_id = npc.get("coreActorID") or npc.get("actorID")

        def finish(response: dict[str, Any]) -> None:
            view = build_world_knowledge_inspector(response)
            self._set_text(self.world_knowledge_inspector, pretty(view))
            self.trace_tabs.select(self.world_knowledge_frame)
            self._append(
                "SYSTEM",
                "World Knowledge inspection refreshed from the production Lua worker.",
            )

        self._start_operation(
            lambda worker: worker.world_knowledge_inspect(actor_id=actor_id),
            finish,
        )

    def refresh_flow_catalog(self) -> None:
        if not self.session.ready or self.busy:
            return
        self._start_operation(
            lambda worker: worker.flow_catalog(),
            self._flow_catalog_finished,
        )

    def _flow_catalog_finished(self, response: dict[str, Any]) -> None:
        self.flow_editor.set_catalog(response)
        self.interaction_explorer.set_catalog(response)
        self.interaction_composer.set_production_catalog(response)
        self.block_registry.set_catalog(response)
        self._production_catalog = response
        self.workflow_pane.set_production_catalog(response)
        self._append(
            "SYSTEM",
            f"Loaded {response.get('flowCount', 0)} normalized production flows.",
        )

    def validate_flow_draft(self, definition: dict[str, Any]) -> None:
        if not self.session.ready or self.busy:
            return
        self._start_operation(
            lambda worker: worker.validate_flow(definition),
            self.flow_editor.show_validation,
        )

    def register_flow_draft(self, definition: dict[str, Any]) -> None:
        if not self.session.ready or self.busy:
            return
        self._start_operation(
            lambda worker: worker.register_flow(definition),
            self.flow_editor.show_registration,
        )

    def compile_semantic_source(self, source_path: Path) -> None:
        """Preview canonical source offline; do not mutate the Lua worker."""
        report = self.authoring_service.preview_semantic_source(source_path)
        self.flow_editor.show_source_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is True:
            self._append(
                "SYSTEM",
                f"Compiler preview valid; no files written: {source_path.name}",
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid source"
            self._append("SYSTEM", f"Compiler preview rejected: {message}")

    def review_dialogue_source(self, source_path: Path) -> None:
        """Review the canonical dialogue dataset through the existing Code Builder."""
        report = self.authoring_service.preview_dialogue_source(source_path)
        self.flow_editor.show_dataset_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        review = report.get("candidateReview") or {}
        summary = review.get("summary") or {}
        collisions = review.get("collisions") or []
        artifact_diffs = report.get("artifactDiffs") or []
        changed = sum(
            1 for row in artifact_diffs
            if isinstance(row, dict) and row.get("status") != "unchanged"
        )
        if report.get("ok") is True:
            self._append(
                "SYSTEM",
                f"Dataset review valid; {summary.get('approved', 0)} approved, "
                f"{summary.get('rejected', 0)} rejected, {len(collisions)} collisions, "
                f"{changed} artifact diffs; "
                "no files written.",
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid dataset"
            self._append("SYSTEM", f"Dataset review rejected: {message}")

    def generate_dialogue_source(self, source_path: Path) -> None:
        """Write approved dialogue artifacts through the existing Code Builder writer."""
        report = self.authoring_service.generate_dialogue_source(source_path)
        self.flow_editor.show_dataset_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "generation failed"
            self._append("SYSTEM", f"Dialogue generation rejected: {message}")
            return
        writes = report.get("writes") or []
        self._append(
            "SYSTEM",
            f"Generated {len(writes)} dialogue artifacts; restarting Lua worker.",
        )
        self.restart()

    def generate_semantic_source(self, source_path: Path) -> None:
        """Generate approved artifacts, then restart the existing worker."""
        report = self.authoring_service.generate_semantic_source(source_path)
        self.flow_editor.show_source_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "generation failed"
            self._append("SYSTEM", f"Source generation rejected: {message}")
            return
        self._append(
            "SYSTEM",
            f"Generated {len(report.get('writes', []))} files; restarting Lua worker.",
        )
        self.restart()

    def preview_interaction_spec(self, spec: dict[str, Any]) -> dict[str, Any]:
        """Preview a configured Studio interaction through the embedded builder."""

        report = self.authoring_service.preview_interaction_spec(
            spec,
            production_catalog=self._production_catalog,
        )
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        return report

    def generate_interaction_spec(self, spec: dict[str, Any]) -> None:
        """Write an approved InteractionSpec, then restart the real Lua worker."""

        report = self.authoring_service.generate_interaction_spec(
            spec,
            approved=True,
            production_catalog=self._production_catalog,
        )
        self.interaction_composer.show_generation(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "generation failed"
            self._append("SYSTEM", f"Interaction generation rejected: {message}")
            return
        self._append(
            "SYSTEM",
            f"Generated {len(report.get('writes', []))} interaction artifacts; restarting Lua worker.",
        )
        self.restart()

    def generate_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        interaction_spec: dict[str, Any] | None = None,
    ) -> None:
        """Generate the approved in-app workflow through the shared service."""
        report = self.authoring_service.generate_workflow(
            source_id,
            block_ids,
            approved=True,
            production_catalog=self._production_catalog,
            interaction_spec=interaction_spec,
        )
        self.workflow_pane.show_generation(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "workflow generation failed"
            self._append("SYSTEM", f"Workflow generation rejected: {message}")
            return
        self._append(
            "SYSTEM",
            f"Generated {len(report.get('writes', []))} artifacts; restarting Lua worker.",
        )
        self.restart()

    def set_language(self) -> None:
        if not self.session.ready or self.busy:
            return
        selected = self.language_var.get().strip().upper()

        def finish(response: dict[str, Any]) -> None:
            self.scenario.setdefault("runtime", {})["language"] = selected
            self._set_status(f"Ready · language {response.get('language', selected)}")
            self._show_response(response)
            self._append("SYSTEM", f"Production translation language set to {selected}.")

        self._start_operation(lambda worker: worker.set_language(selected), finish)

    def inspect_live_worker(self) -> None:
        """Return to the real-worker conversation surface after a build."""
        self.main_tabs.select(self.simulation_tab)
        self._append("SYSTEM", "Live worker inspection is ready in the Simulation tab.")

    def restart(self) -> None:
        if not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._show_response(response)
            self._append("SYSTEM", "Lua worker restarted and the scenario was restored.")

        self._start_operation(lambda worker: worker.restart(), finish)

    def close(self) -> None:
        if self.closed:
            return
        self.closed = True
        self.activity_log.record("ui", "window_close")
        self._save_ui_state()
        for after_id in (
            self._relationship_preview_after,
            self._personality_preview_after,
            self._auto_replay_after,
            self._auto_apply_after,
            self._splitter_restore_after,
            self._activity_after,
        ):
            if after_id is not None:
                try:
                    self.root.after_cancel(after_id)
                except self._tk.TclError:
                    pass
        # Controls are disabled while a request is active. Preserve the
        # session's nonblocking close contract for an explicit close during
        # in-flight work, while draining the idle session before Tk teardown.
        self.session.close(wait=not self.busy)
        self.root.destroy()


def run_gui(arguments: argparse.Namespace) -> int:
    try:
        import tkinter as tk
    except ImportError as error:
        print(f"semantic harness GUI unavailable: install Tk or use --no-gui ({error})", file=sys.stderr)
        return 2
    try:
        root = tk.Tk()
    except tk.TclError as error:
        print(f"semantic harness GUI unavailable: {error}; use --no-gui or run with a display", file=sys.stderr)
        return 2
    try:
        SemanticHarnessApp(root, arguments)
        root.mainloop()
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness GUI error: {error}", file=sys.stderr)
        try:
            root.destroy()
        except tk.TclError:
            pass
        return 2
    return 0

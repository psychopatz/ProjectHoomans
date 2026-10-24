"""Build the semantic harness Studio editor panes."""

from __future__ import annotations

from typing import Any

from ..studio.block_registry import SemanticBlockRegistryPane
from ..studio.dataset_library import DatasetLibraryPane
from ..studio.interaction_explorer_pane import InteractionExplorerPane
from ..studio.interaction_spec_pane import InteractionSpecPane
from ..studio.workflow import SemanticLabWorkflowPane
from .flow_editor.pane import FlowEditorPane


def build_studio_editors(
    app: Any,
    *,
    workflow_tab: Any,
    editor_tab: Any,
    library_tab: Any,
    blocks_tab: Any,
    composer_tab: Any,
    ttk: Any,
    scrolled_text: Any,
) -> None:
    """Create Studio panes and connect them to the shell's callbacks."""

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
    app.flow_editor = FlowEditorPane(
        flow_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._filedialog,
        app._messagebox,
        on_refresh=app.refresh_flow_catalog,
        on_validate=app.validate_flow_draft,
        on_register=app.register_flow_draft,
        on_compile_source=app.compile_semantic_source,
        on_generate_source=app.generate_semantic_source,
        on_review_dataset=app.review_dialogue_source,
        on_generate_dataset=app.generate_dialogue_source,
    )
    app.interaction_explorer = InteractionExplorerPane(
        interaction_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
        on_open_flow=app.flow_editor.select_flow,
    )
    app.interaction_composer = InteractionSpecPane(
        composer_tab,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        on_preview=app.preview_interaction_spec,
        on_generate=app.generate_interaction_spec,
        on_inspect=app.inspect_live_worker,
    )
    app.dataset_library = DatasetLibraryPane(
        library_tab,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
    )
    app.block_registry = SemanticBlockRegistryPane(
        blocks_tab,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
        on_refresh=app.refresh_flow_catalog,
    )
    app.workflow_pane = SemanticLabWorkflowPane(
        workflow_tab,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
        on_generate=app.generate_workflow,
        on_inspect=app.inspect_live_worker,
    )

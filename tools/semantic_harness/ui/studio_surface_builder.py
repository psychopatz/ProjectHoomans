"""Build the semantic harness Studio editor panes."""

from __future__ import annotations

from typing import Any

from ..studio.block_registry import SemanticBlockRegistryPane
from ..studio.conversation_explorer_pane import ConversationExplorerPane
from ..studio.conversation_authoring_pane import ConversationAuthoringPane
from ..studio.dataset_library import DatasetLibraryPane
from ..studio.dialogue_content_pane import DialogueContentPane
from ..studio.interaction_explorer_pane import InteractionExplorerPane
from ..studio.interaction_spec_pane import InteractionSpecPane
from ..studio.source_explorer_pane import CanonicalSourceExplorerPane
from ..studio.workflow import SemanticLabWorkflowPane
from .flow_editor.pane import FlowEditorPane


def build_studio_editors(
    app: Any,
    *,
    explore_tab: Any,
    dialogue_content_tab: Any,
    review_tab: Any,
    developer_tools_parent: Any,
    ttk: Any,
    scrolled_text: Any,
) -> None:
    """Create the three Studio homes without taking runtime ownership.

    Explore is read-only and combines the bounded Conversation and source
    projections. Dialogue Content owns bounded wording edits. Review owns
    candidate-source evidence. Developer Tools contains structural authoring
    and narrow route diagnostics. All worker callbacks remain the existing
    shell/services; this function only changes their navigation home.
    """

    explore_notebook = ttk.Notebook(explore_tab)
    explore_notebook.grid(row=0, column=0, sticky="nsew")
    explore_tab.rowconfigure(0, weight=1)
    explore_tab.columnconfigure(0, weight=1)
    app.studio_explore_notebook = explore_notebook

    response_frame = ttk.Frame(explore_notebook, padding=6)
    source_frame = ttk.Frame(explore_notebook, padding=6)
    for panel in (response_frame, source_frame):
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
    explore_notebook.add(response_frame, text="Conversation")
    explore_notebook.add(source_frame, text="Sources")

    app.observatory = ConversationExplorerPane(
        response_frame, app._tk, ttk, scrolled_text,
        run_worker=app._start_background_operation,
        repository=app.authoring_service.repository,
        filedialog=app._filedialog,
        review_parent=review_tab,
        authoring_service=app.authoring_service,
        on_select_item=lambda content_id: app.open_conversation_editor(content_id),
    )
    app.source_explorer = CanonicalSourceExplorerPane(
        source_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
    )
    app.explore_source_frame = source_frame

    app.dialogue_content = DialogueContentPane(
        dialogue_content_tab,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
        on_preview_simulation=lambda _report: app.main_tabs.select(0),
        on_send_review=lambda report: (
            app.observatory.show_dialogue_content_review(report),
            app.studio_notebook.select(review_tab),
        ),
    )

    advanced_notebook = ttk.Notebook(developer_tools_parent)
    advanced_notebook.grid(row=0, column=0, sticky="nsew")
    developer_tools_parent.rowconfigure(0, weight=1)
    developer_tools_parent.columnconfigure(0, weight=1)
    app.advanced_notebook = advanced_notebook

    flow_frame = ttk.Frame(advanced_notebook)
    flow_frame.rowconfigure(0, weight=1)
    flow_frame.columnconfigure(0, weight=1)
    library_frame = ttk.Frame(advanced_notebook)
    blocks_frame = ttk.Frame(advanced_notebook)
    composer_frame = ttk.Frame(advanced_notebook)
    workflow_frame = ttk.Frame(advanced_notebook)
    route_frame = ttk.Frame(advanced_notebook)
    conversation_authoring_frame = ttk.Frame(advanced_notebook)
    for panel in (library_frame, blocks_frame, composer_frame, workflow_frame, route_frame, conversation_authoring_frame):
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
    advanced_notebook.add(flow_frame, text="Flow editor")
    advanced_notebook.add(library_frame, text="Canonical source editor")
    advanced_notebook.add(blocks_frame, text="Block contracts")
    advanced_notebook.add(composer_frame, text="Interaction composer")
    advanced_notebook.add(workflow_frame, text="Legacy build workflow")
    advanced_notebook.add(route_frame, text="Route diagnostics")
    advanced_notebook.add(conversation_authoring_frame, text="Conversation authoring")
    app.flow_editor_frame = flow_frame
    app.library_tab = library_frame
    app.blocks_tab = blocks_frame
    app.composer_tab = composer_frame
    app.workflow_tab = workflow_frame
    app.route_tab = route_frame
    app.conversation_authoring_tab = conversation_authoring_frame
    # Compatibility for callers that used the former nested editor notebook.
    app.editor_notebook = advanced_notebook

    app.conversation_authoring = ConversationAuthoringPane(
        conversation_authoring_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
        on_preview_simulation=lambda _report: app.main_tabs.select(0),
        on_send_review=lambda report: (
            app.observatory.show_dialogue_content_review(report),
            app.studio_notebook.select(review_tab),
        ),
    )
    app.open_conversation_editor = lambda content_id: (
        app.main_tabs.select(1),
        developer_tools_parent.grid(),
        advanced_notebook.select(conversation_authoring_frame),
        app.conversation_authoring.select_content(content_id),
    )

    app.interaction_explorer = InteractionExplorerPane(
        route_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
        on_open_flow=lambda flow_id: app.flow_editor.select_flow(flow_id),
    )

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
    app.interaction_composer = InteractionSpecPane(
        composer_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        on_preview=app.preview_interaction_spec,
        on_generate=app.generate_interaction_spec,
        on_inspect=app.inspect_live_worker,
    )
    app.dataset_library = DatasetLibraryPane(
        library_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
    )
    app.block_registry = SemanticBlockRegistryPane(
        blocks_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
        on_refresh=app.refresh_flow_catalog,
    )
    app.workflow_pane = SemanticLabWorkflowPane(
        workflow_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
        on_generate=app.generate_workflow,
        on_inspect=app.inspect_live_worker,
    )

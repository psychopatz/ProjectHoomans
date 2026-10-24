"""Build the simulation conversation transcript and input controls."""

from __future__ import annotations

from typing import Any


def build_conversation_panel(
    app: Any, conversation_pane: Any, ttk: Any, scrolled_text: Any
) -> None:
    """Create transcript, semantic suggestions, and input controls."""

    transcript_frame = ttk.LabelFrame(conversation_pane, text="Conversation")
    transcript_frame.grid(row=0, column=0, sticky="nsew")
    transcript_frame.rowconfigure(0, weight=1)
    transcript_frame.columnconfigure(0, weight=1)
    app.transcript = scrolled_text(transcript_frame, wrap="word", state="disabled")
    app.transcript.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

    suggestion_frame = ttk.LabelFrame(
        transcript_frame, text="Contextual semantic suggestions"
    )
    suggestion_frame.grid(row=1, column=0, sticky="ew", padx=6, pady=(0, 6))
    # Let the panel size itself to the visible rows.  The old fixed
    # height reserved five button slots even when a topic had one choice,
    # pushing the input and toolbar below the fold at normal window sizes.
    suggestion_frame.grid_propagate(True)
    app.suggestion_frame = suggestion_frame
    for column in range(3):
        suggestion_frame.columnconfigure(column, weight=1)
    app.suggestion_buttons: list[Any] = []
    app.suggestion_buttons_frame = ttk.Frame(suggestion_frame)
    app.suggestion_buttons_frame.grid(
        row=0, column=0, columnspan=3, sticky="ew", padx=3, pady=3
    )
    for column in range(3):
        app.suggestion_buttons_frame.columnconfigure(column, weight=1)
    app.suggestion_rows: list[dict[str, Any]] = []
    app.suggestion_interactive = False
    app.suggestion_projection: dict[str, Any] = {}
    app.suggestion_response: dict[str, Any] = {}
    app.suggestion_revision: Any = None
    app.suggestion_group_ids_by_display: dict[str, str] = {}
    app.suggestion_status = ttk.Label(
        suggestion_frame,
        text="Run a production preview or turn to inspect suggestions.",
    )
    app.suggestion_status.grid(
        row=1, column=0, columnspan=2, sticky="w", padx=4, pady=(0, 2)
    )
    app.suggestion_group_box = ttk.Combobox(
        suggestion_frame,
        state="readonly",
        width=24,
    )
    app.suggestion_group_box.grid(
        row=1, column=2, sticky="e", padx=3, pady=(0, 2)
    )
    app.suggestion_group_box.bind(
        "<<ComboboxSelected>>", lambda _: app._on_suggestion_group()
    )

    app.input_var = app._tk.StringVar()
    input_box = ttk.Entry(transcript_frame, textvariable=app.input_var)
    input_box.grid(row=2, column=0, sticky="ew", padx=6, pady=(0, 6))
    input_box.bind("<Return>", lambda _: app.submit())
    input_actions = ttk.Frame(transcript_frame)
    input_actions.grid(row=3, column=0, sticky="ew", padx=6, pady=(0, 6))
    input_actions.columnconfigure(0, weight=1)
    app.preview_button = ttk.Button(
        input_actions, text="Preview", command=app.preview
    )
    app.preview_button.grid(row=0, column=1, sticky="e", padx=(0, 4))
    app.send_button = ttk.Button(input_actions, text="Send", command=app.submit)
    app.send_button.grid(row=0, column=2, sticky="e")


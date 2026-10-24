"""Render bounded semantic suggestion groups and rows."""

from __future__ import annotations

from typing import Any

from ..inspection.rendering import pretty
from .suggestion_projection import semantic_suggestion_rows, semantic_suggestion_title

def render_suggestions(
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
    override_id = getattr(self, "suggestion_group_override_id", None)
    display_group_id = suggestions.get("currentGroupID")
    conversation_graph = (
        (response.get("observation") or {}).get("conversationGraph")
        if isinstance(response, dict)
        else None
    )
    if (
        override_id is None
        and isinstance(conversation_graph, dict)
        and "conversation_branch" in group_ids
    ):
        display_group_id = "conversation_branch"
    selected_group_id = (
        display_group_id
        if self.suggestion_revision != revision
        else self.suggestion_group_ids_by_display.get(
            self.suggestion_group_box.get(),
            suggestions.get("currentGroupID"),
        )
    )
    if selected_group_id not in group_ids:
        selected_group_id = display_group_id or (
            group_ids[0] if group_ids else ""
        )
    self.suggestion_group_box.set(group_display_by_id.get(selected_group_id, ""))
    self.suggestion_revision = revision
    if override_id not in group_ids:
        override_id = None
        self.suggestion_group_override_id = None
    self.suggestion_rows = semantic_suggestion_rows(
        suggestions,
        override_id,
        use_global_candidates=override_id is None,
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


__all__ = ["render_suggestions"]

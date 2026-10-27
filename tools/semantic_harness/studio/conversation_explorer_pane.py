"""Derived Conversation explorer for the normal Semantic Lab Studio.

This pane is a projection over the existing production response query and
Dialogue Content authoring service.  It owns no semantic registry and makes
no eligibility or gameplay decisions.  Response pools stay bounded by the
serialized worker page; content rows are bounded to the same page for the
current filter.  Detail tabs only expose the already-authoritative sources.
"""

from __future__ import annotations

import json
from typing import Any

from .observatory_pane import SemanticObservatoryPane
from .semantic_tree import build_semantic_tree, filter_semantic_tree


class ConversationExplorerPane(SemanticObservatoryPane):
    """Combine bounded response, content, and navigation identity in one tree."""

    _CONTENT_PAGE_SIZE = 64
    _DETAIL_TABS = ("Overview", "Wording", "Route", "Conditions", "Follow-ups", "Sources")

    def __init__(
        self,
        *args: Any,
        authoring_service: Any,
        on_select_item: Any | None = None,
        **kwargs: Any,
    ) -> None:
        self._authoring_service = authoring_service
        self._on_select_item = on_select_item
        self._scrolled_text = args[3]
        self._content_rows: dict[str, dict[str, Any]] = {}
        self._content_error = ""
        super().__init__(*args, **kwargs)

        first_tab = self.tabs.tabs()[0]
        self.tabs.tab(first_tab, text="Overview")
        self.views["Overview"] = self.views["Explore"]
        for label in self._DETAIL_TABS[1:]:
            frame = self._ttk.Frame(self.tabs, padding=6)
            frame.rowconfigure(0, weight=1)
            frame.columnconfigure(0, weight=1)
            viewer = self._scrolled_text(frame, wrap="word", state="disabled", height=14)
            viewer.grid(row=0, column=0, sticky="nsew")
            self.tabs.add(frame, text=label)
            self.views[label] = viewer

        self._display(
            "Overview",
            "Conversation explorer · bounded semantic/content/navigation projection.\n"
            "Select a branch or item for wording, route, conditions, follow-ups, and sources.\n"
            "Eligibility and effects remain production-owned.",
        )

    @staticmethod
    def _semantic_id(row: dict[str, Any]) -> str:
        return str(row.get("canonicalID") or row.get("semanticTemplateID") or row.get("id") or "")

    def _load_content_page(self) -> list[dict[str, Any]]:
        try:
            query = self.filter_var.get().strip().casefold()
            rows = self._authoring_service.list_dialogue_content()
            if query:
                rows = [
                    row for row in rows
                    if query in json.dumps(row, ensure_ascii=False, sort_keys=True).casefold()
                ]
            rows = rows[: self._CONTENT_PAGE_SIZE]
            self._content_error = ""
        except (OSError, TypeError, ValueError, KeyError) as error:
            self._content_error = str(error)[:240]
            rows = []

        projected: list[dict[str, Any]] = []
        self._content_rows = {}
        for row in rows:
            if not isinstance(row, dict):
                continue
            semantic_id = str(row.get("semanticTemplateID") or row.get("id") or "")
            if semantic_id.startswith("phrase."):
                semantic_id = semantic_id[len("phrase."):]
            if not semantic_id:
                continue
            projected_row = dict(row)
            projected_row.update({
                "kind": "content",
                "id": "content:" + semantic_id,
                "canonicalID": semantic_id,
            })
            self._content_rows[projected_row["id"]] = projected_row
            projected.append(projected_row)
        return projected

    def _on_list(self, result: dict[str, Any]) -> None:
        if result.get("ok") is False or result.get("catalogError"):
            super()._on_list(result)
            return
        content_rows = self._load_content_page()
        pools = [pool for pool in result.get("pools", []) if isinstance(pool, dict)]
        combined = pools + content_rows
        super()._on_list({
            **result,
            "pools": combined,
            "total": int(result.get("total", len(pools))) + len(content_rows),
        })
        suffix = f"; content load failed: {self._content_error}" if self._content_error else ""
        self.status_var.set(
            f"{len(pools)} response pools + {len(content_rows)} content items"
            f" / {result.get('total', len(pools))} pools{suffix}"
        )

    def _render_pool_tree(self, rows: list[dict[str, Any]]) -> None:
        query = self.filter_var.get().strip()
        tree = filter_semantic_tree(
            build_semantic_tree(rows, id_getter=self._semantic_id),
            query,
        )
        self._pool_rows = {
            str(row.get("id")): row for row in rows if isinstance(row, dict)
        }
        self.pools.delete(*self.pools.get_children())

        def insert(node: dict[str, Any], parent: str = "") -> None:
            children = node.get("children", {}) or {}
            for key in sorted(children, key=str.casefold):
                child = children[key]
                branch_id = "branch:" + str(child.get("key", key))
                self.pools.insert(
                    parent,
                    "end",
                    iid=branch_id,
                    text=f"{child.get('label', key)} ({child.get('count', 0)})",
                    values=(f"{child.get('count', 0)} items", child.get("key", key)),
                    open=(not query or branch_id[len("branch:"):] in tree.get("expanded", set())),
                )
                insert(child, branch_id)
            for item in sorted(
                node.get("items", []) or [],
                key=lambda value: self._semantic_id(value).casefold(),
            ):
                row_id = str(item.get("id", ""))
                prefix = "content:" if item.get("kind") == "content" else "pool:"
                iid = prefix + row_id if not row_id.startswith(prefix) else row_id
                label = self._semantic_id(item) or row_id
                if item.get("kind") == "content":
                    label = "Content · " + label
                else:
                    label = "Response · " + label
                variants = item.get("variantCount")
                if variants is None:
                    styles = item.get("styles")
                    if isinstance(styles, dict):
                        variants = sum(
                            len(phrases) for phrases in styles.values()
                            if isinstance(phrases, list)
                        )
                    elif isinstance(styles, list):
                        variants = len(styles)
                    else:
                        variants = 1 if item.get("kind") == "content" else 0
                self.pools.insert(
                    parent,
                    "end",
                    iid=iid,
                    text=label,
                    values=(variants, self._semantic_id(item)),
                )

        insert(tree)

    def _selected(self, _event: Any = None) -> None:
        selection = self.pools.selection()
        if not selection:
            return
        iid = selection[0]
        if iid.startswith("branch:"):
            self._show_branch(iid[len("branch:"):])
            return
        if iid.startswith("content:"):
            self._show_content(self._content_rows.get(iid))
            return
        super()._selected(_event)

    def _show_branch(self, key: str) -> None:
        descendants = [
            row for row in self._pool_rows.values()
            if self._semantic_id(row) == key or self._semantic_id(row).startswith(key + ".")
        ]
        self._display(
            "Overview",
            f"Conversation branch: {key.rsplit('.', 1)[-1].replace('_', ' ').title()}\n"
            f"Canonical branch ID: {key}\n"
            f"Bounded descendants: {len(descendants)}\n\n"
            "Select a response or content item for its bounded detail.",
        )

    def _show_content(self, item: dict[str, Any] | None) -> None:
        if not item:
            return
        try:
            detail = self._authoring_service.load_dialogue_content(
                str(item.get("id", "")).removeprefix("content:")
            )
        except (OSError, TypeError, ValueError, KeyError) as error:
            self._display("Overview", f"Content detail unavailable: {error}")
            return
        semantic_id = str(detail.get("semanticTemplateID") or detail.get("id") or "")
        self._display(
            "Overview",
            "Conversation content\n\n"
            f"Canonical ID: {semantic_id}\n"
            f"Concept: {detail.get('canonicalConcept', 'UNKNOWN')}\n"
            f"Kind: {detail.get('kind', 'UNKNOWN')}\n"
            "Meaning: selected by the production ResponseCatalog.\n"
            "Eligibility/effects: production-owned.",
        )
        wording: list[str] = []
        for style, phrases in (detail.get("styles") or {}).items():
            wording.append(f"Style: {style}")
            for phrase in phrases if isinstance(phrases, list) else []:
                wording.append(json.dumps(phrase.get("translations", {}), ensure_ascii=False, sort_keys=True))
        self._display("Wording", "\n".join(wording) or "Player-facing labels/utterances are in this content item.")
        self._display("Route", f"Semantic destination: {semantic_id}\nNavigation route: {detail.get('route', 'ResponseCatalog')}")
        self._display("Conditions", "Eligibility and permissions are not editable here; inspect the production provider/authority.")
        self._display("Follow-ups", "Follow-up offers are owned by the selected ResponsePlan and lifecycle context.")
        self._display(
            "Sources",
            f"Source path: {detail.get('sourcePath', 'UNKNOWN')}\n"
            f"Source fingerprint: {detail.get('sourceFingerprint', 'UNKNOWN')}\n"
            f"Owner: {detail.get('verifiedOwner', 'UNKNOWN')}",
        )
        if self._on_select_item:
            self._on_select_item(semantic_id)

    def _on_detail(self, result: dict[str, Any]) -> None:
        super()._on_detail(result)
        pool_id = str(result.get("poolID", "UNKNOWN"))
        variants = result.get("variants", []) or []
        self._display(
            "Wording",
            "\n".join(
                f"{variant.get('id', 'UNKNOWN')} → {variant.get('templateID', 'UNKNOWN')}"
                for variant in variants
            ) or "Wording is supplied lazily by Dialogue Content.",
        )
        self._display(
            "Route",
            f"ResponseCatalog pool: {pool_id}\n"
            f"Plan summaries: {json.dumps([v.get('planSummary', {}) for v in variants], indent=2, sort_keys=True)}",
        )
        self._display(
            "Conditions",
            "\n".join(
                f"{variant.get('id', 'UNKNOWN')}: {variant.get('when') or 'none'}"
                for variant in variants
            ) or "No bounded conditions returned.",
        )
        self._display(
            "Follow-ups",
            "\n".join(
                f"{variant.get('id', 'UNKNOWN')}: {variant.get('planSummary', {}).get('offerCount', 0)} offers"
                for variant in variants
            ) or "No follow-up plan detail returned.",
        )
        self._display(
            "Sources",
            f"Pool: {pool_id}\nSource: {result.get('sourcePath', 'UNKNOWN')}\n"
            f"Registry revision: {result.get('registryRevision', 'UNKNOWN')}\n"
            f"Content marker: {result.get('contentFingerprint', 'UNKNOWN')}",
        )


__all__ = ["ConversationExplorerPane"]

"""Read-only save-backed actor, faction, and community browser."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .state_providers import SemanticStateCatalog, StateProviderError


class SaveBrowserError(ValueError):
    """A save cannot be projected into the bounded world browser."""


@dataclass(frozen=True)
class SavedWorldBrowser:
    """Project persisted world actors without mutating or materializing PZ."""

    core_repository: Path

    def __post_init__(self) -> None:
        object.__setattr__(self, "core_repository", Path(self.core_repository))

    def browse(self, save_path: Path) -> dict[str, Any]:
        save_path = Path(save_path).expanduser().resolve()
        try:
            state_catalog = SemanticStateCatalog(
                core_repository=self.core_repository,
            ).load(save_path)
        except StateProviderError as error:
            raise SaveBrowserError(str(error)) from error
        providers = state_catalog["providers"]
        hoomans = providers["projecthoomans"]["projection"]
        trading = providers["dynamictrading"]["projection"]
        actors = deepcopy(hoomans.get("actors") or [])
        provider_rows = {
            str(row.get("id")): row
            for row in trading.get("knownActors") or []
            if isinstance(row, dict)
        }
        for actor in actors:
            provider_row = provider_rows.get(str(actor.get("id")))
            actor["isTrader"] = provider_row is not None
            if provider_row is not None:
                actor["provider"] = provider_row.get("provider")

        categories: dict[str, list[dict[str, Any]]] = {
            "All NPCs": actors,
            "Companions": [actor for actor in actors if actor["isFollower"]],
            "Colonists": [
                actor
                for actor in actors
                if actor.get("factionID") or actor.get("communityID")
            ],
            "Followers": [actor for actor in actors if actor["isFollower"]],
            "Neutral NPCs": [
                actor for actor in actors if not actor["isHostile"]
            ],
            "Hostile NPCs": [actor for actor in actors if actor["isHostile"]],
            "Known Traders": [actor for actor in actors if actor["isTrader"]],
        }
        communities = deepcopy(hoomans.get("communities") or [])
        if not communities:
            derived: dict[str, dict[str, Any]] = {}
            for actor in actors:
                community_id = actor.get("communityID")
                if not community_id:
                    continue
                row = derived.setdefault(
                    str(community_id),
                    {
                        "id": str(community_id),
                        "label": str(community_id),
                        "memberIDs": [],
                        "source": "DERIVED",
                        "baseSource": "SAVE",
                    },
                )
                row["memberIDs"].append(actor["id"])
            for row in derived.values():
                row["memberIDs"] = sorted(set(row["memberIDs"]))
            communities = sorted(derived.values(), key=lambda item: item["id"])
        raw = state_catalog["raw"]

        return {
            "schema": "semantic.save_browser.v1",
            "schemaVersion": 1,
            "source": "SAVE",
            "sourceID": raw["sourceID"],
            "savePath": str(save_path),
            "saveName": raw["saveName"],
            "worldVersion": raw["worldVersion"],
            "providers": providers,
            "players": hoomans.get("players") or [],
            "categories": categories,
            "factions": hoomans.get("factions") or [],
            "communities": communities,
            "providerActors": trading.get("knownActors") or [],
            "counts": {
                "players": len(hoomans.get("players") or []),
                "npcs": len(actors),
                "factions": len(hoomans.get("factions") or []),
                "communities": len(communities),
                "providerActors": len(trading.get("knownActors") or []),
            },
        }


__all__ = ["SaveBrowserError", "SavedWorldBrowser"]

"""Read-only save-backed actor, faction, and community browser."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .save_catalog import SaveCatalog, SaveCatalogError, _load_core_reader
from .save_import import _as_dict, _first_name


class SaveBrowserError(ValueError):
    """A save cannot be projected into the bounded world browser."""


@dataclass(frozen=True)
class SavedWorldBrowser:
    """Project persisted world actors without mutating or materializing PZ."""

    core_repository: Path

    def __post_init__(self) -> None:
        object.__setattr__(self, "core_repository", Path(self.core_repository))

    @staticmethod
    def _read_path(reader: Any, table: str, path: str) -> Any:
        try:
            report = reader.inspect(
                table=table,
                path=path,
                chunk_size=None,
                max_depth=24,
                max_items=100_000,
                max_nodes=100_000,
                max_string=16_384,
            )
        except Exception as error:
            raise SaveBrowserError(
                f"could not read saved projection {table}.{path}: {error}"
            ) from error
        if report.get("truncated"):
            raise SaveBrowserError(
                f"saved projection {table}.{path} exceeded bounded limits"
            )
        value = report.get("data")
        if isinstance(value, dict):
            path_key = path.rsplit(".", 1)[-1]
            if path_key in value and len(value) == 1:
                return value[path_key]
        return value

    @staticmethod
    def _actor(
        table: str,
        identity: dict[str, Any],
        affiliation: dict[str, Any],
        hostility: dict[str, Any],
        order_spec: dict[str, Any],
        generation: dict[str, Any],
    ) -> dict[str, Any]:
        actor_id = table[len("PNC_"):] if table.startswith("PNC_") else table
        forename, surname, display_name = _first_name(identity)
        hostility_mode = str(hostility.get("mode") or "unknown")
        order_kind = str(order_spec.get("kind") or "")
        faction_id = affiliation.get("factionID")
        community_id = affiliation.get("communityID")
        trader = (
            str(generation.get("source") or "").lower() == "dynamic_trading"
            or str(affiliation.get("originArchetypeID") or "").lower()
            == "trader"
        )
        follower = order_kind == "follow" or hostility_mode == "defend_owner"
        hostile = bool(hostility.get("attackPlayers")) or hostility_mode in {
            "hostile",
            "aggressive",
            "attack",
        }
        return {
            "id": actor_id,
            "table": table,
            "label": display_name,
            "forename": forename,
            "surname": surname,
            "identity": deepcopy(identity),
            "affiliation": deepcopy(affiliation),
            "hostility": deepcopy(hostility),
            "order": deepcopy(order_spec),
            "generation": deepcopy(generation),
            "factionID": faction_id,
            "communityID": community_id,
            "hostilityMode": hostility_mode,
            "orderKind": order_kind,
            "isFollower": follower,
            "isHostile": hostile,
            "isTrader": trader,
            "source": "SAVE",
        }

    def browse(self, save_path: Path) -> dict[str, Any]:
        save_path = Path(save_path).expanduser().resolve()
        catalog = SaveCatalog(core_repository=self.core_repository)
        try:
            entry = catalog.inspect(save_path)
        except SaveCatalogError as error:
            raise SaveBrowserError(str(error)) from error

        Reader, _reader_error = _load_core_reader(self.core_repository)
        try:
            with Reader(save_path) as reader:
                player_data = self._read_path(
                    reader, "PNC_PlayerCharacters", "byUUID"
                )
                if not isinstance(player_data, dict):
                    raise SaveBrowserError(
                        "PNC_PlayerCharacters.byUUID is not an object"
                    )
                players: list[dict[str, Any]] = []
                for uuid, value in sorted(player_data.items()):
                    record = _as_dict(value)
                    label = str(
                        record.get("displayName")
                        or " ".join(
                            part
                            for part in (
                                record.get("forename"),
                                record.get("surname"),
                            )
                            if part
                        )
                        or uuid
                    )
                    account_key = str(
                        record.get("accountKey")
                        or record.get("accountIdentity")
                        or ""
                    ).strip()
                    players.append(
                        {
                            "id": str(uuid),
                            "uuid": str(record.get("uuid") or uuid),
                            "label": label,
                            "status": str(record.get("status") or "unknown"),
                            "accountKey": account_key,
                            "entityKey": (
                                f"player:{account_key}:{uuid}"
                                if account_key
                                else None
                            ),
                            "source": "SAVE",
                        }
                    )

                actors: list[dict[str, Any]] = []
                for table in entry.npc_tables:
                    identity = _as_dict(
                        self._read_path(reader, table, "identity")
                    )
                    affiliation = _as_dict(
                        self._read_path(reader, table, "affiliation")
                    )
                    hostility = _as_dict(
                        self._read_path(reader, table, "hostility")
                    )
                    order_spec = _as_dict(
                        self._read_path(reader, table, "orderSpec")
                    )
                    generation = _as_dict(
                        self._read_path(reader, table, "generation")
                    )
                    actors.append(
                        self._actor(
                            table,
                            identity,
                            affiliation,
                            hostility,
                            order_spec,
                            generation,
                        )
                    )

                factions: list[dict[str, Any]] = []
                table_names = {item.name for item in reader.index}
                if "PNC_Factions" in table_names:
                    by_id = self._read_path(reader, "PNC_Factions", "byID")
                    for faction_id, value in sorted(_as_dict(by_id).items()):
                        record = _as_dict(value)
                        factions.append(
                            {
                                "id": str(record.get("id") or faction_id),
                                "label": str(
                                    record.get("name") or faction_id
                                ),
                                "status": str(
                                    record.get("status") or "unknown"
                                ),
                                "archetypeID": record.get("archetypeID"),
                                "ownerPlayerKey": record.get("ownerPlayerKey"),
                                "memberIDs": sorted(
                                    str(member)
                                    for member in _as_dict(
                                        record.get("memberIDs")
                                    )
                                ),
                                "source": "SAVE",
                            }
                        )
        except SaveBrowserError:
            raise
        except Exception as error:
            raise SaveBrowserError(
                f"could not browse save: {save_path}: {error}"
            ) from error

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
        communities: dict[str, dict[str, Any]] = {}
        for actor in actors:
            community_id = actor.get("communityID")
            if not community_id:
                continue
            row = communities.setdefault(
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
        for row in communities.values():
            row["memberIDs"] = sorted(set(row["memberIDs"]))

        return {
            "schema": "semantic.save_browser.v1",
            "schemaVersion": 1,
            "source": "SAVE",
            "sourceID": entry.source_id,
            "savePath": str(save_path),
            "saveName": entry.save_name,
            "worldVersion": entry.world_version,
            "players": players,
            "categories": categories,
            "factions": factions,
            "communities": sorted(
                communities.values(), key=lambda item: item["id"]
            ),
            "providerActors": categories["Known Traders"],
            "counts": {
                "players": len(players),
                "npcs": len(actors),
                "factions": len(factions),
                "communities": len(communities),
                "providerActors": len(categories["Known Traders"]),
            },
        }


__all__ = ["SaveBrowserError", "SavedWorldBrowser"]

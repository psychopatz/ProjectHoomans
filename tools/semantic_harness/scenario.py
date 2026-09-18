"""Scenario loading and safe conversion for the Lua semantic worker."""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any


DEFAULT_SCENARIO: dict[str, Any] = {
    "player": {
        "characterUUID": "char_patrick",
        "forename": "Patrick",
        "surname": "Patz",
        "displayName": "Patrick Patz",
        "inventory": {
            "revision": 1,
            "items": [
                {
                    "itemID": "player_apple_1",
                    "fullType": "Base.Apple",
                    "displayName": "Apple",
                    "stack": 1,
                    "marketSense": {
                        "primary": "FoodFruit",
                        "category": "Food",
                        "subcategory": "fruit",
                        "leaf": "apple",
                        "tags": ["food", "foodfruit", "fruit"],
                        "expandedTags": ["food", "foodfruit"],
                        "capabilities": {"edible": True},
                        "price": 5,
                    },
                },
                {
                    "itemID": "player_bandage_1",
                    "fullType": "Base.Bandage",
                    "displayName": "Bandage",
                    "stack": 2,
                    "marketSense": {
                        "primary": "FirstAid",
                        "category": "Medicine",
                        "tags": ["firstaid", "medical"],
                        "capabilities": {"medical": True},
                        "price": 4,
                    },
                },
            ],
            "containers": [],
        },
    },
    "npc": {
        "npcID": "npc_mara",
        "forename": "Mara",
        "surname": "Vale",
        "identityState": "unknown",
        "traits": ["reserved"],
        "relationship": {
            "approval": 0,
            "respect": 0,
            "familiarity": 0,
            "revision": 1,
            "identityTrust": "unknown",
        },
        "inventory": {
            "revision": 1,
            "items": [
                {
                    "itemID": "npc_sardines_1",
                    "fullType": "Base.CannedSardines",
                    "displayName": "Canned Sardines",
                    "stack": 2,
                    "marketSense": {
                        "primary": "FoodSeafood",
                        "category": "Food",
                        "subcategory": "seafood",
                        "leaf": "sardines",
                        "tags": ["food", "foodseafood", "seafood"],
                        "expandedTags": ["food", "foodseafood"],
                        "capabilities": {"edible": True},
                        "price": 8,
                    },
                },
            ],
            "containers": [],
        },
    },
    "world": {
        "hunger": 0.2,
        "thirst": 0.4,
        "fatigue": 0.1,
        "stress": 0.0,
        "boredom": 0.0,
        "panic": 0.0,
        "weather": "clear",
        "timeOfDay": 13.5,
        "worldAgeHours": 49.5,
    },
    "conversation": {
        "topic": "greeting",
        "token": "harness-lease",
    },
    "runtime": {
        "mode": "singleplayer",
        "language": "EN",
        "llmEnabled": False,
        "providerAvailable": False,
        "nativeTranslations": {},
        "commandResponses": {
            "follow": {"accepted": True, "reason": "network_queued"},
            "stay": {"accepted": True, "reason": "network_queued"},
            "camp": {
                "accepted": True,
                "reason": "network_queued",
                "details": {
                    "siteLabel": "safehouse",
                    "siteScope": "room",
                },
            },
        },
    },
}


def merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Recursively merge an authored scenario over the safe defaults."""

    output: dict[str, Any] = deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(output.get(key), dict):
            output[key] = merge(output[key], value)
        else:
            output[key] = deepcopy(value)
    return output


def load_scenario(path: Path | None = None) -> dict[str, Any]:
    if path is None:
        return merge({}, DEFAULT_SCENARIO)
    with path.open("r", encoding="utf-8") as handle:
        authored = json.load(handle)
    if not isinstance(authored, dict):
        raise ValueError("scenario root must be a JSON object")
    return merge(DEFAULT_SCENARIO, authored)


def save_scenario(path: Path, scenario: dict[str, Any]) -> Path:
    """Validate and atomically persist a complete scenario JSON document."""

    validate_scenario(scenario)
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    try:
        with temporary.open("w", encoding="utf-8") as handle:
            json.dump(scenario, handle, indent=2, ensure_ascii=False, sort_keys=True)
            handle.write("\n")
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()
    return path


def validate_scenario(scenario: dict[str, Any]) -> None:
    if not isinstance(scenario, dict):
        raise ValueError("scenario root must be a JSON object")
    required = ("player", "npc", "world", "conversation", "runtime")
    missing = [key for key in required if not isinstance(scenario.get(key), dict)]
    if missing:
        raise ValueError("scenario sections must be objects: " + ", ".join(missing))
    player = scenario["player"]
    npc = scenario["npc"]
    if not str(player.get("characterUUID", "")):
        raise ValueError("player.characterUUID is required")
    if not str(npc.get("npcID", "")):
        raise ValueError("npc.npcID is required")
    for owner in (player, npc):
        inventory = owner.get("inventory")
        if inventory is not None and not isinstance(inventory, dict):
            raise ValueError("actor.inventory must be an object")
        if isinstance(inventory, dict):
            if inventory.get("items") is not None and not isinstance(
                inventory.get("items"), (list, dict)
            ):
                raise ValueError("actor.inventory.items must be an array or object")
            if inventory.get("containers") is not None and not isinstance(
                inventory.get("containers"), (list, dict)
            ):
                raise ValueError("actor.inventory.containers must be an array or object")

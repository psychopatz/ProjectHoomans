"""Scenario loading and safe conversion for the Lua semantic worker."""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
import re
from typing import Any


DEFAULT_SCENARIO: dict[str, Any] = {
    "player": {
        "characterUUID": "char_patrick",
        "forename": "Patrick",
        "surname": "Patz",
        "displayName": "Patrick Patz",
        "gender": "male",
        "needs": {
            "hunger": 0.2,
            "thirst": 0.4,
            "fatigue": 0.1,
            "stress": 0.0,
            "boredom": 0.0,
            "panic": 0.0,
        },
        "traits": [],
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
        "healthState": "healthy",
        "activeBehavior": "idle",
        "gender": "female",
        "identitySeed": "npc_mara",
        "archetype": "General",
        "needs": {
            "hunger": 0.2,
            "thirst": 0.4,
            "fatigue": 0.1,
            "stress": 0.0,
            "boredom": 0.0,
            "panic": 0.0,
        },
        "orderKind": "idle",
        "followState": {"mode": "idle"},
        "actorAuthority": {
            "companion": True,
            "owned": True,
            "eligible": True,
        },
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
        "seedString": "semantic-harness-default-save",
        "hunger": 0.2,
        "thirst": 0.4,
        "fatigue": 0.1,
        "stress": 0.0,
        "boredom": 0.0,
        "panic": 0.0,
        "weather": "clear",
        "timeOfDay": 13.5,
        "worldAgeHours": 49.5,
        "zombieKills": 0,
        "weatherTransition": None,
    },
    "baseEstablished": True,
    "conversation": {
        "topic": "greeting",
        "token": "harness-lease",
    },
    "runtime": {
        "mode": "singleplayer",
        "language": "EN",
        "llmEnabled": False,
        "providerAvailable": False,
        "semanticDialogueEnabled": True,
        "semanticLabProfile": "companion",
        "availableMods": {},
        "nativeTranslations": {},
        "semanticCognitionResponses": {},
        "commandResponses": {
            "follow": {
                "accepted": True,
                "reason": "network_queued",
                "state": {
                    "npc": {
                        "activeBehavior": "following",
                        "orderKind": "follow",
                        "followState": {"mode": "following"},
                    }
                },
            },
            "stay": {
                "accepted": True,
                "reason": "network_queued",
                "state": {
                    "npc": {
                        "activeBehavior": "idle",
                        "orderKind": "idle",
                        "followState": {"mode": "staying"},
                    }
                },
            },
            "camp": {
                "accepted": True,
                "reason": "network_queued",
                "details": {
                    "siteLabel": "safehouse",
                    "siteScope": "room",
                },
            },
        },
        "taskResponses": {
            "WAIT_AT": {
                "accepted": True,
                "reason": "network_queued",
                "details": {
                    "status": "admitted",
                    "planID": "mock-plan-wait-at",
                    "targetID": "campfire@mock",
                },
            },
        },
        "questResponses": {
            "offer": {"accepted": True, "status": "available", "reason": "available"},
            "accept": {"accepted": True, "status": "accepted", "reason": "accepted"},
            "status": {"accepted": True, "status": "active", "reason": "status_returned"},
            "turn_in": {"accepted": True, "status": "rewarded", "reason": "rewarded"},
        },
    },
}


def derive_display_name(forename: Any, surname: Any) -> str:
    """Return the harness display name owned by the actor's name fields."""

    return " ".join(
        part.strip()
        for part in (str(forename or ""), str(surname or ""))
        if part.strip()
    )


def derive_actor_identifier(prefix: str, forename: Any, surname: Any) -> str:
    """Build a stable, readable harness identifier from an actor's name."""

    name = derive_display_name(forename, surname).lower()
    slug = re.sub(r"[^a-z0-9]+", "_", name).strip("_")
    return f"{prefix}_{slug or 'actor'}"


def merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Recursively merge an authored scenario over the safe defaults."""

    output: dict[str, Any] = deepcopy(base)
    replace_empty_objects = {"needs", "conditionStats", "personality", "identity"}
    for key, value in override.items():
        if (
            isinstance(value, dict)
            and not (not value and key in replace_empty_objects)
            and isinstance(output.get(key), dict)
        ):
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
    for owner_name, owner in (("player", player), ("npc", npc)):
        traits = owner.get("traits")
        if traits is not None and not isinstance(traits, (list, dict)):
            raise ValueError(f"{owner_name}.traits must be an array or object")
        gender = owner.get("gender")
        if gender is not None and not isinstance(gender, (str, bool)):
            raise ValueError(f"{owner_name}.gender must be a string or boolean")
    for field in ("identitySeed", "archetype"):
        value = npc.get(field)
        if value is not None and not isinstance(value, (str, int, float)):
            raise ValueError(f"npc.{field} must be scalar or null")
    # Nullable state fields permit deliberately unknown NPC facts. Legacy
    # scenarios without explicit NPC needs still use world-level values.
    for field in ("healthState", "activeBehavior"):
        value = npc.get(field)
        if value is not None and not isinstance(value, str):
            raise ValueError(f"npc.{field} must be a string or null")
    for field in ("needs", "conditionStats"):
        value = npc.get(field)
        if value is not None and not isinstance(value, dict):
            raise ValueError(f"npc.{field} must be an object or null")
    player_needs = player.get("needs")
    if player_needs is not None and not isinstance(player_needs, dict):
        raise ValueError("player.needs must be an object or null")
    for owner_name, owner_needs in (("player", player_needs), ("npc", npc.get("needs"))):
        if not isinstance(owner_needs, dict):
            continue
        for need_name, need_value in owner_needs.items():
            if not isinstance(need_name, str):
                raise ValueError(f"{owner_name}.needs keys must be strings")
            if not isinstance(need_value, (int, float)) or isinstance(need_value, bool):
                raise ValueError(f"{owner_name}.needs.{need_name} must be numeric")
            if need_value < 0 or need_value > 1:
                raise ValueError(f"{owner_name}.needs.{need_name} must be between 0 and 1")
    actor_authority = npc.get("actorAuthority")
    if actor_authority is not None and not isinstance(actor_authority, dict):
        raise ValueError("npc.actorAuthority must be an object or null")
    starting_relationship = npc.get("startingRelationship")
    if starting_relationship is not None and not isinstance(
        starting_relationship, dict
    ):
        raise ValueError("npc.startingRelationship must be an object or null")
    if isinstance(starting_relationship, dict):
        kind = starting_relationship.get("kind")
        if kind is not None and not isinstance(kind, str):
            raise ValueError("npc.startingRelationship.kind must be a string")
    runtime = scenario["runtime"]
    profile = runtime.get("semanticLabProfile")
    if profile is not None and not isinstance(profile, str):
        raise ValueError("runtime.semanticLabProfile must be a string or null")
    semantic_dialogue_enabled = runtime.get("semanticDialogueEnabled")
    if semantic_dialogue_enabled is not None and not isinstance(
        semantic_dialogue_enabled, bool
    ):
        raise ValueError(
            "runtime.semanticDialogueEnabled must be a boolean or null"
        )
    available_mods = runtime.get("availableMods")
    if available_mods == []:
        available_mods = {}
    if available_mods is not None and not isinstance(available_mods, dict):
        raise ValueError("runtime.availableMods must be an object or null")
    if isinstance(available_mods, dict):
        for mod_id, enabled in available_mods.items():
            if not isinstance(mod_id, str) or not isinstance(enabled, bool):
                raise ValueError("runtime.availableMods must map strings to booleans")
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

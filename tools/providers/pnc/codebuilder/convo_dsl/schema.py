"""Unified typed context schema shared between .convo DSL and Lua ResponseCatalog."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class FieldSpec:
    lua_key: str
    value_type: str  # "string" | "bool" | "number"
    allowed_values: tuple[str, ...] | None = None


# Maps compact DSL predicate names -> canonical ResponseCatalog_Core.CONDITION_FIELDS keys.
CONTEXT_SCHEMA: dict[str, FieldSpec] = {
    # Role / beat routing
    "role": FieldSpec("combatReactionRole", "string"),
    "event.type": FieldSpec("eventType", "string"),
    "event.horde_phase": FieldSpec("hordePhase", "string"),
    "topic": FieldSpec("topic", "string"),
    "intent": FieldSpec("intent", "string"),
    "subject": FieldSpec("subject", "string"),
    "action": FieldSpec("action", "string"),

    # Speaker (actor.*)
    "actor.style": FieldSpec(
        "speakerStyle",
        "string",
        ("neutral", "supportive", "brave", "aggressive", "shaken", "cold", "exhausted", "tactical", "hostile"),
    ),
    "actor.injured": FieldSpec("speakerInjured", "bool"),
    "actor.social_style": FieldSpec("socialStyle", "string", ("friendly", "protective", "warm", "neutral", "guarded", "withdrawn", "hostile")),
    "actor.health": FieldSpec("healthState", "string"),
    "actor.activity": FieldSpec("activity", "string"),
    "actor.busy": FieldSpec("busy", "bool"),
    "actor.role": FieldSpec(
        "actorRole",
        "string",
        ("colonist", "companion", "trader", "guard", "looter", "bandit", "survivor"),
    ),
    "actor.age_band": FieldSpec("actorAgeBand", "string", ("youth", "adult", "elder")),
    "rel.bond": FieldSpec(
        "relBond",
        "string",
        ("lover", "spouse", "parent", "child", "sibling", "family", "friend", "rival", "stranger"),
    ),

    # Partner (partner.*)
    "partner.style": FieldSpec(
        "partnerStyle",
        "string",
        ("neutral", "supportive", "brave", "aggressive", "shaken", "cold", "exhausted", "tactical", "hostile"),
    ),

    # Shared physical state (any.*)
    "any.injured": FieldSpec("anyInjured", "bool"),
    "any.exhausted": FieldSpec("anyExhausted", "bool"),

    # Relationship (rel.*)
    "rel.tier": FieldSpec(
        "relationshipTier",
        "string",
        ("hostile", "wary", "stranger", "acquaintance", "friendly", "trusted", "ally"),
    ),
    "rel.state": FieldSpec("relationshipState", "string"),
    "rel.identity_trust": FieldSpec(
        "identityTrust",
        "string",
        ("unknown", "claimed", "trusted", "distrusted", "untrustworthy"),
    ),
    "rel.cross_group": FieldSpec("isCrossGroup", "bool"),

    # Environment (env.*)
    "env.night_or_dusk": FieldSpec("isNightOrDusk", "bool"),
    "env.time_band": FieldSpec("timeBand", "string"),
    "env.raining": FieldSpec("raining", "bool"),
    "env.foggy": FieldSpec("foggy", "bool"),
    "env.snowing": FieldSpec("snowing", "bool"),
    "env.indoors": FieldSpec("indoors", "bool"),

    # Player input tone & register (player.*)
    "player.tone": FieldSpec("playerTone", "string", ("neutral", "polite", "urgent", "hostile", "casual", "skeptical")),
    "player.rude": FieldSpec("playerRude", "bool"),
    "player.shouting": FieldSpec("playerShouting", "bool"),
    "player.polite": FieldSpec("playerPolite", "bool"),

    # Directed memories (mem.*)
    "mem.has_any": FieldSpec("memHasAny", "bool"),
    "mem.saved_me": FieldSpec("memSavedMe", "bool"),
    "mem.fought_together": FieldSpec("memFoughtTogether", "bool"),
    "mem.treated_me": FieldSpec("memTreatedMe", "bool"),
    "mem.betrayed": FieldSpec("memBetrayed", "bool"),

    # World utilities & scoped world events (world.*)
    "world.power_off": FieldSpec("worldPowerOff", "bool"),
    "world.water_off": FieldSpec("worldWaterOff", "bool"),
    "world.has_event": FieldSpec("worldHasEvent", "bool"),
    "world.food_crisis": FieldSpec("worldFoodCrisis", "bool"),
    "world.raider_surge": FieldSpec("worldRaiderSurge", "bool"),
    "world.event_type": FieldSpec("worldEventType", "string"),

    # NPC knowledge & place (know.*, place.*)
    "know.has_gossip": FieldSpec("knowHasGossip", "bool"),
    "place.in_settlement": FieldSpec("placeInSettlement", "bool"),

    # Live NPC posture, job & current action (state.*)
    "state.posture": FieldSpec("statePosture", "string", ("standing", "sitting", "sleeping", "resting", "crouching")),
    "state.job": FieldSpec("stateJob", "string"),
    "state.order_kind": FieldSpec("stateOrderKind", "string", ("none", "follow", "stay", "guard", "camp", "patrol")),
    "state.already_following": FieldSpec("stateAlreadyFollowing", "bool"),
    "state.sitting": FieldSpec("stateSitting", "bool"),
    "state.sleeping": FieldSpec("stateSleeping", "bool"),
    "state.working": FieldSpec("stateWorking", "bool"),

    # NPC mood & emotional state (mood.*)
    "mood.primary": FieldSpec(
        "moodPrimary",
        "string",
        ("calm", "cheerful", "bored", "unhappy", "hungry", "tired", "stressed", "in_pain", "panicked", "annoyed", "fed_up"),
    ),
    "mood.panicked": FieldSpec("moodPanicked", "bool"),
    "mood.in_pain": FieldSpec("moodInPain", "bool"),
    "mood.stressed": FieldSpec("moodStressed", "bool"),
    "mood.tired": FieldSpec("moodTired", "bool"),
    "mood.unhappy": FieldSpec("moodUnhappy", "bool"),
    "mood.bored": FieldSpec("moodBored", "bool"),
    "mood.hungry": FieldSpec("moodHungry", "bool"),
    "mood.cheerful": FieldSpec("moodCheerful", "bool"),

    # Conversation patience, annoyance & command redundancy (npc.*, convo.*, command.*)
    "npc.annoyance": FieldSpec("npcAnnoyance", "string", ("calm", "mild", "annoyed", "fed_up")),
    "npc.annoyed": FieldSpec("npcAnnoyed", "bool"),
    "npc.fed_up": FieldSpec("npcFedUp", "bool"),
    "convo.repeat_count": FieldSpec("convoRepeatCount", "number"),
    "command.redundant": FieldSpec("commandRedundant", "bool"),

    # Multi-party group & shared conversational floor (group.*, floor.*)
    "group.size": FieldSpec("groupSize", "number"),
    "group.broadcast": FieldSpec("groupBroadcast", "bool"),
    "floor.speaker_is_npc": FieldSpec("floorSpeakerIsNPC", "bool"),
    "floor.interjection_kind": FieldSpec(
        "floorInterjectionKind",
        "string",
        ("calm_down", "back_up", "concern", "chime_in", "disagree"),
    ),
    "floor.side_with_speaker": FieldSpec("floorSideWithSpeaker", "bool"),
    "floor.speaker_annoyed": FieldSpec("floorSpeakerAnnoyed", "bool"),
    "floor.speaker_injured": FieldSpec("floorSpeakerInjured", "bool"),

    # Needs, emotions & conversation state (need.*, emotion.*, convo.*, memory.*)
    "need.type": FieldSpec("needType", "string"),
    "need.urgency": FieldSpec("needUrgency", "string"),
    "emotion.type": FieldSpec("emotionType", "string"),
    "emotion.urgency": FieldSpec("emotionUrgency", "string"),
    "social.hostility_count": FieldSpec("hostilityCount", "number"),
    "social.insult_count": FieldSpec("insultCount", "number"),
    "social.role": FieldSpec("socialRole", "string"),
    "social.greeting_state": FieldSpec("greetingState", "string"),
    "social.farewell_speaker": FieldSpec("farewellSpeaker", "string"),
    "memory.available": FieldSpec("memoryAvailable", "bool"),
    "convo.pending_request": FieldSpec("hasPendingRequest", "bool"),
    "convo.prev_topic": FieldSpec("previousTopic", "string"),
    "convo.prev_action": FieldSpec("previousAction", "string"),
    "convo.last_intent": FieldSpec("lastIntent", "string"),
    "convo.last_speech_act": FieldSpec("lastSpeechAct", "string"),
    "state.value": FieldSpec("stateValue", "string"),

    # Combat, conflict, loot & medical (combat.*, conflict.*, downed.*, loot.*, medical.*)
    "combat.style": FieldSpec("combatReactionStyle", "string"),
    "combat.mood": FieldSpec("combatReactionMood", "string"),
    "combat.pressure": FieldSpec("combatPressure", "string"),
    "combat.weapon_family": FieldSpec("combatWeaponFamily", "string"),
    "combat.weapon_named": FieldSpec("combatWeaponNamed", "bool"),
    "combat.skill_band": FieldSpec("combatSkillBand", "string"),
    "combat.hit_zone": FieldSpec("combatHitZone", "string"),
    "combat.wound_type": FieldSpec("combatWoundType", "string"),
    "combat.attack_type": FieldSpec("combatAttackType", "string"),
    "combat.killer_kind": FieldSpec("killerActorKind", "string"),
    "conflict.assault_kind": FieldSpec("assaultKind", "string"),
    "conflict.push_tier": FieldSpec("friendlyPushTier", "string"),
    "downed.audience": FieldSpec("downedAudience", "string"),
    "downed.need": FieldSpec("downedNeed", "string"),
    "downed.threat": FieldSpec("downedThreat", "string"),
    "loot.category": FieldSpec("lootCategory", "string"),
    "medical.bandage_required": FieldSpec("medicalBandageRequired", "bool"),
    "medical.bandage_status": FieldSpec("medicalBandageStatus", "string"),
    "medical.supply_status": FieldSpec("medicalSupplyRequestStatus", "string"),
    "medical.saliva_transmissible": FieldSpec("salivaTransmissible", "bool"),
    "medical.is_bitten": FieldSpec("isBitten", "bool"),
    "medical.open_wounds": FieldSpec("hasOpenWounds", "bool"),
    "medical.knox_exposure": FieldSpec("knoxExposure", "string"),

    # Mod compatibility & milestones (alife.*, dog.*, milestone.*, command.*)
    "alife.kind": FieldSpec("projectALifeKind", "string"),
    "alife.stance": FieldSpec("projectALifeStance", "string"),
    "alife.conflict_direction": FieldSpec("projectALifeConflictDirection", "string"),
    "alife.conflict_damage": FieldSpec("projectALifeConflictDamage", "string"),
    "dog.sex": FieldSpec("companionDogSex", "string"),
    "dog.fed": FieldSpec("companionDogFed", "bool"),
    "milestone.stage": FieldSpec("milestoneStage", "string"),
    "epistemic.provenance": FieldSpec("epistemicProvenance", "string"),
    "leader.grief": FieldSpec("leaderGrief", "string"),
    "leader.succession": FieldSpec("leaderSuccession", "string"),
    "corpse.revenge": FieldSpec("corpseRevenge", "string"),
    "command.id": FieldSpec("commandID", "string"),
    "command.reason": FieldSpec("commandReason", "string"),
    "command.outcome": FieldSpec("commandOutcome", "string"),

    # Descriptive full-name predicate aliases
    "relationship.bond": FieldSpec("relBond", "string", ("lover", "spouse", "parent", "child", "sibling", "family", "friend", "rival", "stranger")),
    "relationship.tier": FieldSpec("relationshipTier", "string", ("hostile", "wary", "stranger", "acquaintance", "friendly", "trusted", "ally")),
    "relationship.state": FieldSpec("relationshipState", "string"),
    "relationship.identity_trust": FieldSpec("identityTrust", "string", ("unknown", "claimed", "trusted", "distrusted", "untrustworthy")),
    "relationship.cross_group": FieldSpec("isCrossGroup", "bool"),
    "environment.night_or_dusk": FieldSpec("isNightOrDusk", "bool"),
    "environment.time_band": FieldSpec("timeBand", "string"),
    "environment.raining": FieldSpec("raining", "bool"),
    "environment.foggy": FieldSpec("foggy", "bool"),
    "environment.snowing": FieldSpec("snowing", "bool"),
    "environment.indoors": FieldSpec("indoors", "bool"),
    "memory.has_any": FieldSpec("memHasAny", "bool"),
    "memory.saved_me": FieldSpec("memSavedMe", "bool"),
    "memory.fought_together": FieldSpec("memFoughtTogether", "bool"),
    "memory.treated_me": FieldSpec("memTreatedMe", "bool"),
    "memory.betrayed": FieldSpec("memBetrayed", "bool"),
    "knowledge.has_gossip": FieldSpec("knowHasGossip", "bool"),
    "conversation.repeat_count": FieldSpec("convoRepeatCount", "number"),
    "conversation.pending_request": FieldSpec("hasPendingRequest", "bool"),
    "conversation.previous_topic": FieldSpec("previousTopic", "string"),
    "conversation.previous_action": FieldSpec("previousAction", "string"),
    "conversation.last_intent": FieldSpec("lastIntent", "string"),
    "conversation.last_speech_act": FieldSpec("lastSpeechAct", "string"),
}


def resolve_predicate(raw_expr: str, source_file: str, line_no: int) -> tuple[str, Any]:
    """Parse and validate a single predicate like `actor.style=shaken` or `env.night_or_dusk`."""
    expr = raw_expr.strip()
    if not expr:
        raise ValueError(f"{source_file}:{line_no}: empty predicate")

    negated = False
    if expr.startswith("!"):
        negated = True
        expr = expr[1:].strip()

    if "=" in expr:
        if negated:
            raise ValueError(f"{source_file}:{line_no}: cannot negate key=value predicate '{raw_expr}'")
        key, raw_val = expr.split("=", 1)
        key = key.strip()
        raw_val = raw_val.strip().strip('"').strip("'")
    else:
        key = expr
        raw_val = "false" if negated else "true"

    spec = CONTEXT_SCHEMA.get(key)
    if spec is None:
        known = ", ".join(sorted(CONTEXT_SCHEMA.keys()))
        raise ValueError(
            f"{source_file}:{line_no}: unknown context predicate '{key}'. Valid predicates: {known}"
        )

    if spec.value_type == "bool":
        lowered = raw_val.lower()
        if lowered not in ("true", "false"):
            raise ValueError(f"{source_file}:{line_no}: predicate '{key}' expects boolean, got '{raw_val}'")
        return spec.lua_key, (lowered == "true")

    # Support OR-list syntax: `rel.state=Friend|Trusted|Ally` -> ["Friend", "Trusted", "Ally"]
    parts = [p.strip().strip('"').strip("'") for p in raw_val.split("|")] if "|" in raw_val else [raw_val]

    if spec.value_type == "number":
        parsed_nums: list[int | float] = []
        for p in parts:
            try:
                num = float(p)
                parsed_nums.append(int(num) if num.is_integer() else num)
            except ValueError as exc:
                raise ValueError(f"{source_file}:{line_no}: predicate '{key}' expects number, got '{p}'") from exc
        return spec.lua_key, (parsed_nums if len(parsed_nums) > 1 else parsed_nums[0])

    if spec.allowed_values is not None:
        for p in parts:
            if p not in spec.allowed_values:
                allowed = ", ".join(spec.allowed_values)
                raise ValueError(
                    f"{source_file}:{line_no}: invalid value '{p}' for '{key}'. Allowed: {allowed}"
                )
    return spec.lua_key, (parts if len(parts) > 1 else parts[0])

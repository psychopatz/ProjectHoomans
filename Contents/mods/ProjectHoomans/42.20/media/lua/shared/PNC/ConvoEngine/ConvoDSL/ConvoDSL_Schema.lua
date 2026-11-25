-- Unified typed context schema for runtime .convo DSL parsing.
-- Maps compact DSL predicate names -> ResponseCatalog_Core.CONDITION_FIELDS keys.
-- Kahlua2 / Lua 5.1 safe, zero external dependencies.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Schema = {}

local function setOf(list)
    local out = {}
    for i = 1, #list do
        out[list[i]] = true
    end
    return out
end

local STYLES = setOf({
    "neutral", "supportive", "brave", "aggressive", "shaken",
    "cold", "exhausted", "tactical", "hostile",
})
local SOCIAL_STYLES = setOf({
    "friendly", "protective", "warm", "neutral", "guarded", "withdrawn", "hostile",
})
local ACTOR_ROLES = setOf({
    "colonist", "companion", "trader", "guard", "looter", "bandit", "survivor",
})
local AGE_BANDS = setOf({ "youth", "adult", "elder" })
local REL_BONDS = setOf({
    "lover", "spouse", "parent", "child", "sibling", "family", "friend", "rival", "stranger",
})
local REL_TIERS = setOf({
    "hostile", "wary", "stranger", "acquaintance", "friendly", "trusted", "ally",
})
local IDENTITY_TRUST = setOf({
    "unknown", "claimed", "trusted", "distrusted", "untrustworthy",
})
local PLAYER_TONES = setOf({
    "neutral", "polite", "urgent", "hostile", "casual", "skeptical",
})
local POSTURES = setOf({ "standing", "sitting", "sleeping", "resting", "crouching" })
local ORDER_KINDS = setOf({ "none", "follow", "stay", "guard", "camp", "patrol" })
local MOOD_PRIMARIES = setOf({
    "calm", "cheerful", "bored", "unhappy", "hungry", "tired",
    "stressed", "in_pain", "panicked", "annoyed", "fed_up",
})
local ANNOYANCE_LEVELS = setOf({ "calm", "mild", "annoyed", "fed_up" })
local INTERJECTION_KINDS = setOf({ "calm_down", "back_up", "concern", "chime_in", "disagree" })

local function spec(luaKey, valueType, allowed)
    return { luaKey = luaKey, valueType = valueType, allowed = allowed }
end

Schema.FIELDS = {
    -- Role / beat routing
    ["role"] = spec("combatReactionRole", "string"),
    ["event.type"] = spec("eventType", "string"),
    ["event.horde_phase"] = spec("hordePhase", "string"),
    ["topic"] = spec("topic", "string"),
    ["intent"] = spec("intent", "string"),
    ["subject"] = spec("subject", "string"),
    ["action"] = spec("action", "string"),

    -- Speaker (actor.*)
    ["actor.style"] = spec("speakerStyle", "string", STYLES),
    ["actor.injured"] = spec("speakerInjured", "bool"),
    ["actor.social_style"] = spec("socialStyle", "string", SOCIAL_STYLES),
    ["actor.health"] = spec("healthState", "string"),
    ["actor.activity"] = spec("activity", "string"),
    ["actor.busy"] = spec("busy", "bool"),
    ["actor.role"] = spec("actorRole", "string", ACTOR_ROLES),
    ["actor.age_band"] = spec("actorAgeBand", "string", AGE_BANDS),
    ["rel.bond"] = spec("relBond", "string", REL_BONDS),

    -- Partner (partner.*)
    ["partner.style"] = spec("partnerStyle", "string", STYLES),

    -- Shared physical state (any.*)
    ["any.injured"] = spec("anyInjured", "bool"),
    ["any.exhausted"] = spec("anyExhausted", "bool"),

    -- Relationship (rel.*)
    ["rel.tier"] = spec("relationshipTier", "string", REL_TIERS),
    ["rel.state"] = spec("relationshipState", "string"),
    ["rel.identity_trust"] = spec("identityTrust", "string", IDENTITY_TRUST),
    ["rel.cross_group"] = spec("isCrossGroup", "bool"),

    -- Environment (env.*)
    ["env.night_or_dusk"] = spec("isNightOrDusk", "bool"),
    ["env.time_band"] = spec("timeBand", "string"),
    ["env.raining"] = spec("raining", "bool"),
    ["env.foggy"] = spec("foggy", "bool"),
    ["env.snowing"] = spec("snowing", "bool"),
    ["env.indoors"] = spec("indoors", "bool"),

    -- Player input tone & register (player.*)
    ["player.tone"] = spec("playerTone", "string", PLAYER_TONES),
    ["player.rude"] = spec("playerRude", "bool"),
    ["player.shouting"] = spec("playerShouting", "bool"),
    ["player.polite"] = spec("playerPolite", "bool"),

    -- Directed memories (mem.*)
    ["mem.has_any"] = spec("memHasAny", "bool"),
    ["mem.saved_me"] = spec("memSavedMe", "bool"),
    ["mem.fought_together"] = spec("memFoughtTogether", "bool"),
    ["mem.treated_me"] = spec("memTreatedMe", "bool"),
    ["mem.betrayed"] = spec("memBetrayed", "bool"),

    -- World utilities & scoped world events (world.*)
    ["world.power_off"] = spec("worldPowerOff", "bool"),
    ["world.water_off"] = spec("worldWaterOff", "bool"),
    ["world.has_event"] = spec("worldHasEvent", "bool"),
    ["world.food_crisis"] = spec("worldFoodCrisis", "bool"),
    ["world.raider_surge"] = spec("worldRaiderSurge", "bool"),
    ["world.event_type"] = spec("worldEventType", "string"),

    -- NPC knowledge & place (know.*, place.*)
    ["know.has_gossip"] = spec("knowHasGossip", "bool"),
    ["place.in_settlement"] = spec("placeInSettlement", "bool"),

    -- Live NPC posture, job & current action (state.*)
    ["state.posture"] = spec("statePosture", "string", POSTURES),
    ["state.job"] = spec("stateJob", "string"),
    ["state.order_kind"] = spec("stateOrderKind", "string", ORDER_KINDS),
    ["state.already_following"] = spec("stateAlreadyFollowing", "bool"),
    ["state.sitting"] = spec("stateSitting", "bool"),
    ["state.sleeping"] = spec("stateSleeping", "bool"),
    ["state.working"] = spec("stateWorking", "bool"),

    -- NPC mood & emotional state (mood.*)
    ["mood.primary"] = spec("moodPrimary", "string", MOOD_PRIMARIES),
    ["mood.panicked"] = spec("moodPanicked", "bool"),
    ["mood.in_pain"] = spec("moodInPain", "bool"),
    ["mood.stressed"] = spec("moodStressed", "bool"),
    ["mood.tired"] = spec("moodTired", "bool"),
    ["mood.unhappy"] = spec("moodUnhappy", "bool"),
    ["mood.bored"] = spec("moodBored", "bool"),
    ["mood.hungry"] = spec("moodHungry", "bool"),
    ["mood.cheerful"] = spec("moodCheerful", "bool"),

    -- Conversation patience, annoyance & command redundancy
    ["npc.annoyance"] = spec("npcAnnoyance", "string", ANNOYANCE_LEVELS),
    ["npc.annoyed"] = spec("npcAnnoyed", "bool"),
    ["npc.fed_up"] = spec("npcFedUp", "bool"),
    ["convo.repeat_count"] = spec("convoRepeatCount", "number"),
    ["command.redundant"] = spec("commandRedundant", "bool"),

    -- Multi-party group & shared conversational floor
    ["group.size"] = spec("groupSize", "number"),
    ["group.broadcast"] = spec("groupBroadcast", "bool"),
    ["floor.speaker_is_npc"] = spec("floorSpeakerIsNPC", "bool"),
    ["floor.interjection_kind"] = spec("floorInterjectionKind", "string", INTERJECTION_KINDS),
    ["floor.side_with_speaker"] = spec("floorSideWithSpeaker", "bool"),
    ["floor.speaker_annoyed"] = spec("floorSpeakerAnnoyed", "bool"),
    ["floor.speaker_injured"] = spec("floorSpeakerInjured", "bool"),

    -- Needs, emotions & conversation state
    ["need.type"] = spec("needType", "string"),
    ["need.urgency"] = spec("needUrgency", "string"),
    ["emotion.type"] = spec("emotionType", "string"),
    ["emotion.urgency"] = spec("emotionUrgency", "string"),
    ["social.hostility_count"] = spec("hostilityCount", "number"),
    ["social.insult_count"] = spec("insultCount", "number"),
    ["social.role"] = spec("socialRole", "string"),
    ["social.greeting_state"] = spec("greetingState", "string"),
    ["social.farewell_speaker"] = spec("farewellSpeaker", "string"),
    ["memory.available"] = spec("memoryAvailable", "bool"),
    ["convo.pending_request"] = spec("hasPendingRequest", "bool"),
    ["convo.prev_topic"] = spec("previousTopic", "string"),
    ["convo.prev_action"] = spec("previousAction", "string"),
    ["convo.last_intent"] = spec("lastIntent", "string"),
    ["convo.last_speech_act"] = spec("lastSpeechAct", "string"),
    ["state.value"] = spec("stateValue", "string"),

    -- Combat, conflict, loot & medical
    ["combat.style"] = spec("combatReactionStyle", "string"),
    ["combat.mood"] = spec("combatReactionMood", "string"),
    ["combat.pressure"] = spec("combatPressure", "string"),
    ["combat.weapon_family"] = spec("combatWeaponFamily", "string"),
    ["combat.weapon_named"] = spec("combatWeaponNamed", "bool"),
    ["combat.skill_band"] = spec("combatSkillBand", "string"),
    ["combat.hit_zone"] = spec("combatHitZone", "string"),
    ["combat.wound_type"] = spec("combatWoundType", "string"),
    ["combat.attack_type"] = spec("combatAttackType", "string"),
    ["combat.killer_kind"] = spec("killerActorKind", "string"),
    ["conflict.assault_kind"] = spec("assaultKind", "string"),
    ["conflict.push_tier"] = spec("friendlyPushTier", "string"),
    ["downed.audience"] = spec("downedAudience", "string"),
    ["downed.need"] = spec("downedNeed", "string"),
    ["downed.threat"] = spec("downedThreat", "string"),
    ["loot.category"] = spec("lootCategory", "string"),
    ["medical.bandage_required"] = spec("medicalBandageRequired", "bool"),
    ["medical.bandage_status"] = spec("medicalBandageStatus", "string"),
    ["medical.supply_status"] = spec("medicalSupplyRequestStatus", "string"),
    ["medical.saliva_transmissible"] = spec("salivaTransmissible", "bool"),
    ["medical.is_bitten"] = spec("isBitten", "bool"),
    ["medical.open_wounds"] = spec("hasOpenWounds", "bool"),
    ["medical.knox_exposure"] = spec("knoxExposure", "string"),

    -- Mod compatibility & milestones
    ["alife.kind"] = spec("projectALifeKind", "string"),
    ["alife.stance"] = spec("projectALifeStance", "string"),
    ["alife.conflict_direction"] = spec("projectALifeConflictDirection", "string"),
    ["alife.conflict_damage"] = spec("projectALifeConflictDamage", "string"),
    ["dog.sex"] = spec("companionDogSex", "string"),
    ["dog.fed"] = spec("companionDogFed", "bool"),
    ["milestone.stage"] = spec("milestoneStage", "string"),
    ["epistemic.provenance"] = spec("epistemicProvenance", "string"),
    ["leader.grief"] = spec("leaderGrief", "string"),
    ["leader.succession"] = spec("leaderSuccession", "string"),
    ["corpse.revenge"] = spec("corpseRevenge", "string"),
    ["command.id"] = spec("commandID", "string"),
    ["command.reason"] = spec("commandReason", "string"),
    ["command.outcome"] = spec("commandOutcome", "string"),

    -- Descriptive full-name predicate aliases (preferred over short prefixes)
    ["relationship.bond"] = spec("relBond", "string", REL_BONDS),
    ["relationship.tier"] = spec("relationshipTier", "string", REL_TIERS),
    ["relationship.state"] = spec("relationshipState", "string"),
    ["relationship.identity_trust"] = spec("identityTrust", "string", IDENTITY_TRUST),
    ["relationship.cross_group"] = spec("isCrossGroup", "bool"),

    ["environment.night_or_dusk"] = spec("isNightOrDusk", "bool"),
    ["environment.time_band"] = spec("timeBand", "string"),
    ["environment.raining"] = spec("raining", "bool"),
    ["environment.foggy"] = spec("foggy", "bool"),
    ["environment.snowing"] = spec("snowing", "bool"),
    ["environment.indoors"] = spec("indoors", "bool"),

    ["memory.has_any"] = spec("memHasAny", "bool"),
    ["memory.saved_me"] = spec("memSavedMe", "bool"),
    ["memory.fought_together"] = spec("memFoughtTogether", "bool"),
    ["memory.treated_me"] = spec("memTreatedMe", "bool"),
    ["memory.betrayed"] = spec("memBetrayed", "bool"),

    ["knowledge.has_gossip"] = spec("knowHasGossip", "bool"),

    ["conversation.repeat_count"] = spec("convoRepeatCount", "number"),
    ["conversation.pending_request"] = spec("hasPendingRequest", "bool"),
    ["conversation.previous_topic"] = spec("previousTopic", "string"),
    ["conversation.previous_action"] = spec("previousAction", "string"),
    ["conversation.last_intent"] = spec("lastIntent", "string"),
    ["conversation.last_speech_act"] = spec("lastSpeechAct", "string"),
}

local function trim(s)
    return string.match(tostring(s or ""), "^%s*(.-)%s*$") or ""
end

local function stripOuterQuotes(s)
    s = trim(s)
    local len = #s
    if len >= 2 then
        local first = string.sub(s, 1, 1)
        local last = string.sub(s, len, len)
        if (first == '"' and last == '"') or (first == "'" and last == "'") then
            return string.sub(s, 2, len - 1)
        end
    end
    return s
end

function Schema.ResolvePredicate(rawExpr, sourceFile, lineNo)
    local expr = trim(rawExpr)
    if expr == "" then
        return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo) .. ": empty predicate"
    end

    local negated = false
    if string.sub(expr, 1, 1) == "!" then
        negated = true
        expr = trim(string.sub(expr, 2))
    end

    local eqPos = string.find(expr, "=", 1, true)
    local key, rawVal
    if eqPos then
        if negated then
            return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                .. ": cannot negate key=value predicate '" .. tostring(rawExpr) .. "'"
        end
        key = trim(string.sub(expr, 1, eqPos - 1))
        rawVal = stripOuterQuotes(string.sub(expr, eqPos + 1))
    else
        key = expr
        rawVal = negated and "false" or "true"
    end

    local fieldSpec = Schema.FIELDS[key]
    if not fieldSpec then
        return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
            .. ": unknown context predicate '" .. tostring(key) .. "'"
    end

    if fieldSpec.valueType == "bool" then
        local lowered = string.lower(rawVal)
        if lowered ~= "true" and lowered ~= "false" then
            return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                .. ": predicate '" .. key .. "' expects boolean, got '" .. rawVal .. "'"
        end
        return fieldSpec.luaKey, (lowered == "true"), nil
    end

    local parts = {}
    if string.find(rawVal, "|", 1, true) then
        local pos = 1
        while true do
            local bar = string.find(rawVal, "|", pos, true)
            if not bar then
                parts[#parts + 1] = stripOuterQuotes(string.sub(rawVal, pos))
                break
            end
            parts[#parts + 1] = stripOuterQuotes(string.sub(rawVal, pos, bar - 1))
            pos = bar + 1
        end
    else
        parts[1] = rawVal
    end

    if fieldSpec.valueType == "number" then
        local nums = {}
        for i = 1, #parts do
            local n = tonumber(parts[i])
            if n == nil then
                return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                    .. ": predicate '" .. key .. "' expects number, got '" .. parts[i] .. "'"
            end
            nums[i] = n
        end
        return fieldSpec.luaKey, (#nums > 1 and nums or nums[1]), nil
    end

    if fieldSpec.allowed then
        for i = 1, #parts do
            if not fieldSpec.allowed[parts[i]] then
                return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                    .. ": invalid value '" .. parts[i] .. "' for '" .. key .. "'"
            end
        end
    end

    return fieldSpec.luaKey, (#parts > 1 and parts or parts[1]), nil
end

return Schema

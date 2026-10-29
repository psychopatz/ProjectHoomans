-- Bounded authoritative projection of a combat event for semantic speech.
-- This is runtime presentation context only; it owns no combat effects or
-- durable memory.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Moment = PNC.Semantics.CombatMoment or {}
PNC.Semantics.CombatMoment = Moment

Moment.VERSION = 1
Moment.SCHEMA = "semantic.combat.moment.v1"

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return tonumber(fallback) or 0 end
    return value
end

local function text(value, limit)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    limit = math.max(1, tonumber(limit) or 96)
    if #value > limit then value = string.sub(value, 1, limit) end
    return value
end

local function defaultPriority(kind, exceptional)
    kind = tostring(kind or "")
    if kind == "tactical_prompt" then return 100 end
    if kind == "combat_warning" or kind == "horde_warning" then return 80 end
    if kind == "injury" or kind == "downed" then return 70 end
    if kind == "kill" then return exceptional == true and 44 or 24 end
    return 20
end

local function urgency(priority)
    priority = tonumber(priority) or 0
    if priority >= 90 then return "critical" end
    if priority >= 65 then return "urgent" end
    if priority >= 40 then return "notable" end
    return "ordinary"
end

function Moment.Build(spec)
    spec = type(spec) == "table" and spec or {}
    local kind = text(spec.kind, 48) or "combat"
    local priority = math.max(
        0,
        math.floor(number(
            spec.priority,
            defaultPriority(kind, spec.exceptional)
        ))
    )
    return {
        schemaVersion = Moment.VERSION,
        schema = Moment.SCHEMA,
        authoritative = spec.authoritative ~= false,
        kind = kind,
        eventType = text(spec.eventType, 64),
        actorKind = text(spec.actorKind, 32),
        actorID = text(spec.actorID, 96),
        targetKind = text(spec.targetKind, 32),
        targetID = text(spec.targetID, 96),
        outcome = text(spec.outcome, 32),
        attackType = text(spec.attackType, 32),
        attackKind = text(spec.attackKind, 48),
        weaponFullType = text(spec.weaponFullType, 128),
        weaponDisplayName = text(spec.weaponDisplayName, 96),
        weaponFamily = text(spec.weaponFamily, 48),
        weaponSkill = text(spec.weaponSkill, 48),
        weaponSkillLevel = spec.weaponSkillLevel ~= nil
            and math.max(0, math.floor(number(spec.weaponSkillLevel, 0)))
            or nil,
        partID = text(spec.partID or spec.partId, 48),
        woundType = text(spec.woundType, 48),
        pressureBand = text(spec.pressureBand, 48),
        nearbyCount = spec.nearbyCount ~= nil
            and math.max(0, math.floor(number(spec.nearbyCount, 0)))
            or nil,
        healthState = text(spec.healthState, 32),
        reactionMood = text(spec.reactionMood, 32),
        reactionStyle = text(spec.reactionStyle, 32),
        relationshipState = text(spec.relationshipState, 32),
        relationshipTier = text(spec.relationshipTier, 32),
        encounterID = text(spec.encounterID, 128),
        encounterIntent = text(spec.encounterIntent, 32),
        burstCount = math.max(1, math.floor(number(spec.burstCount, 1))),
        priority = priority,
        urgency = text(spec.urgency, 24) or urgency(priority),
        presentationClass = text(spec.presentationClass, 32) or "BARK",
        source = text(spec.source, 64),
        occurredAt = number(spec.occurredAt, 0),
        llmEligible = false,
        memoryEligible = false,
    }
end

function Moment.WithSpeaker(moment, spec)
    local merged = {}
    for key, value in pairs(type(moment) == "table" and moment or {}) do
        merged[key] = value
    end
    for key, value in pairs(type(spec) == "table" and spec or {}) do
        merged[key] = value
    end
    merged.schema = nil
    merged.schemaVersion = nil
    return Moment.Build(merged)
end

function Moment.Snapshot(moment)
    if type(moment) ~= "table" then return nil end
    return Moment.Build(moment)
end

return Moment

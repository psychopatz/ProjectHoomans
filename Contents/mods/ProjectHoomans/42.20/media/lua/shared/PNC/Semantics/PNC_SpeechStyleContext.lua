-- Transient, deterministic speech-style projection.
--
-- Style is presentation-only. It never creates a semantic action, changes a
-- response plan, or authorizes a gameplay effect. Gender and private Social
-- Profile fields are intentionally absent from every calculation here.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Style = PNC.Semantics.SpeechStyleContext or {}
PNC.Semantics.SpeechStyleContext = Style

Style.VERSION = 1
Style.SCHEMA = "speech.style.context.v1"

local ActorContext = PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"

local DIMENSIONS = {
    "warmth", "formality", "directness", "verbosity", "hostility",
    "openness", "deference",
}

local function clamp(value)
    value = tonumber(value) or 0.5
    if value < 0 then value = 0 end
    if value > 1 then value = 1 end
    return math.floor(value * 1000 + 0.5) / 1000
end

local function add(values, field, delta)
    values[field] = (values[field] or 0.5) + (tonumber(delta) or 0)
end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return fallback end
    return value
end

local function normalizedSigned(value)
    return math.max(0, math.min(1, (number(value, 0) + 100) / 200))
end

local function applyTrait(values, trait)
    trait = string.lower(tostring(trait or ""))
    if trait == "friendly" or trait == "pnc_friendly"
        or trait == "kind" or trait == "protective"
    then
        add(values, "warmth", 0.16)
        add(values, "openness", 0.14)
        add(values, "deference", -0.04)
    elseif trait == "reserved" or trait == "pnc_reserved"
        or trait == "withdrawn" or trait == "pnc_withdrawn"
        or trait == "guarded" or trait == "suspicious"
    then
        add(values, "warmth", -0.07)
        add(values, "verbosity", -0.16)
        add(values, "openness", -0.20)
        add(values, "directness", 0.06)
    elseif trait == "aggressive" or trait == "hostile" then
        add(values, "hostility", 0.22)
        add(values, "directness", 0.16)
        add(values, "openness", -0.10)
        add(values, "verbosity", -0.08)
    end
end

local function variant(values)
    -- Reserve guarded speech for defensive/high-hostility contexts. A lone
    -- reserved trait remains compatible with the neutral opening contract;
    -- relationship or situational pressure must reinforce the guarded mode.
    if values.hostility >= 0.68
        or values.openness <= 0.25 and values.hostility >= 0.55
    then
        return "guarded"
    end
    if values.verbosity <= 0.32 or values.directness >= 0.76 then
        return "terse"
    end
    if values.warmth >= 0.67 and values.openness >= 0.55 then
        return "warm"
    end
    return "neutral"
end

function Style.Resolve(source)
    local context = type(source) == "table" and source or {}
    local actor = context.actorConversationContext
    if type(actor) ~= "table" then actor = ActorContext.Build(context) end
    local personality = actor.personality or {}
    local relationship = actor.relationship or {}
    local roles = actor.roles or {}
    local situation = actor.situation or {}
    local values = {}
    local provenance = {
        personality = {},
        relationship = {},
        traits = {},
        roles = {},
        situation = {},
    }
    for index = 1, #DIMENSIONS do values[DIMENSIONS[index]] = 0.5 end

    add(values, "warmth", (number(personality.compassion, 0.5) - 0.5) * 0.30)
    add(values, "warmth", (number(personality.sociability, 0.5) - 0.5) * 0.22)
    add(values, "openness", (number(personality.sociability, 0.5) - 0.5) * 0.30)
    add(values, "formality", (number(personality.materialism, 0.5) - 0.5) * 0.04)
    add(values, "directness", (number(personality.aggression, 0.5) - 0.5) * 0.18)
    add(values, "hostility", (number(personality.aggression, 0.5) - 0.5) * 0.24)
    add(values, "deference", (number(personality.loyalty, 0.5) - 0.5) * 0.16)
    add(values, "verbosity", (number(personality.sociability, 0.5) - 0.5) * 0.22)
    provenance.personality[#provenance.personality + 1] = "social_profile"

    add(values, "warmth", (normalizedSigned(relationship.approval) - 0.5) * 0.28)
    add(values, "deference", (normalizedSigned(relationship.respect) - 0.5) * 0.18)
    add(values, "openness", (number(relationship.familiarity, 0) / 100 - 0.5) * 0.28)
    if relationship.state == "friend" then
        add(values, "warmth", 0.12)
        add(values, "openness", 0.10)
        provenance.relationship[#provenance.relationship + 1] = "friend_state"
    elseif relationship.state == "rival" then
        add(values, "hostility", 0.13)
        add(values, "openness", -0.10)
        provenance.relationship[#provenance.relationship + 1] = "rival_state"
    elseif relationship.state == "enemy" then
        add(values, "hostility", 0.28)
        add(values, "openness", -0.22)
        add(values, "directness", 0.12)
        provenance.relationship[#provenance.relationship + 1] = "enemy_state"
    end
    if relationship.identityTrust == "trusted" then
        add(values, "openness", 0.12)
        provenance.relationship[#provenance.relationship + 1] = "trusted"
    elseif relationship.identityTrust == "untrustworthy" then
        add(values, "openness", -0.20)
        add(values, "hostility", 0.10)
        provenance.relationship[#provenance.relationship + 1] = "untrustworthy"
    end

    for index = 1, #(actor.traits or {}) do
        applyTrait(values, actor.traits[index])
        provenance.traits[#provenance.traits + 1] = actor.traits[index]
    end

    if roles.hostile then
        add(values, "hostility", 0.30)
        add(values, "directness", 0.18)
        add(values, "verbosity", -0.10)
        provenance.roles[#provenance.roles + 1] = "hostile_role"
    end
    if roles.trader then
        add(values, "formality", 0.08)
        add(values, "deference", 0.04)
        provenance.roles[#provenance.roles + 1] = "trader_role"
    end
    if roles.companion then
        add(values, "warmth", 0.04)
        provenance.roles[#provenance.roles + 1] = "companion_role"
    end

    if situation.activeBehavior == "busy"
        or situation.activeBehavior == "searching"
        or situation.activeBehavior == "fleeing"
    then
        add(values, "verbosity", -0.16)
        add(values, "directness", 0.08)
        provenance.situation[#provenance.situation + 1] = "busy_behavior"
    end
    if situation.inCombat then
        add(values, "hostility", 0.28)
        add(values, "directness", 0.22)
        add(values, "verbosity", -0.20)
        provenance.situation[#provenance.situation + 1] = "combat"
    end
    if situation.healthState == "critical" or situation.healthState == "injured"
        or situation.healthState == "wounded"
    then
        add(values, "verbosity", -0.06)
        provenance.situation[#provenance.situation + 1] = "health_pressure"
    end

    for index = 1, #DIMENSIONS do
        values[DIMENSIONS[index]] = clamp(values[DIMENSIONS[index]])
    end
    return {
        schemaVersion = Style.VERSION,
        schema = Style.SCHEMA,
        variant = variant(values),
        dimensions = values,
        provenance = provenance,
        revisions = actor.revisions,
        privacy = {
            genderUsed = false,
            privateProfileFieldsUsed = false,
            semanticMeaningChanged = false,
        },
    }
end

function Style.PublicView(value)
    value = type(value) == "table" and value or {}
    return {
        schemaVersion = value.schemaVersion,
        schema = value.schema,
        variant = value.variant or "neutral",
        revisions = value.revisions,
        privacy = {
            genderUsed = false,
            privateProfileFieldsUsed = false,
            semanticMeaningChanged = false,
        },
    }
end

return Style

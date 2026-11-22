-- Transient, deterministic speech-style projection.
--
-- Style is presentation-only. It never creates a semantic action, changes a
-- response plan, or authorizes a gameplay effect. Gender and private Social
-- Profile fields are intentionally absent from every calculation here.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Style = PNC.ConvoEngine.SpeechStyleContext or {}
PNC.ConvoEngine.SpeechStyleContext = Style

Style.VERSION = 1
Style.SCHEMA = "speech.style.context.v1"

local ActorContext = PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"

local function resolveDispositionProjection()
    local dp = PNC and PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if type(dp) == "table" and type(dp.Resolve) == "function" then
        return dp
    end
    if type(require) == "function" then
        local ok, loaded = pcall(require, "PNC/ConvoEngine/DispositionProjection")
        if ok and type(loaded) == "table" and type(loaded.Resolve) == "function" then
            return loaded
        end
    end
    return nil
end

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
    local bond = actor.bond or {}
    local roles = actor.roles or {}
    local situation = actor.situation or {}
    local values = {}
    local provenance = {
        personality = {},
        relationship = {},
        traits = {},
        temporaryDemeanor = {},
        roles = {},
        situation = {},
        bond = {},
    }
    for index = 1, #DIMENSIONS do values[DIMENSIONS[index]] = 0.5 end

    local DP = resolveDispositionProjection()
    local proj = type(context.dispositionProjection) == "table"
        and context.dispositionProjection
        or nil
    if not proj and DP then
        local record = type(context.npcRecord) == "table" and context.npcRecord
            or (type(context.actor) == "table" and context.actor or actor)
        proj = DP.Resolve(record, {
            personality = type(context.npcPersonality) == "table"
                and context.npcPersonality or personality,
            traits = actor.traits or context.npcTraits,
            playerTraits = context.playerTraits,
            condition = context.condition
                or (type(context.npcRecord) == "table"
                    and context.npcRecord.conditionStats)
                or nil,
            temporaryDemeanor = context.temporaryDemeanor
                or actor.temporaryDemeanor,
            relationshipState = relationship.state,
            isHostile = roles.hostile == true,
            tactical = roles.role == "guard" or roles.role == "soldier"
                or roles.role == "scout",
            identitySeed = context.identitySeed,
        })
    end

    local effective = personality
    if proj and type(proj.effectiveDisposition) == "table" then
        if DP and type(DP.ToUnitDisposition) == "function" then
            effective = DP.ToUnitDisposition(proj.effectiveDisposition)
        else
            local e = proj.effectiveDisposition
            effective = {
                compassion = number(e.compassion, 50) / 100,
                sociability = number(e.sociability, 50) / 100,
                materialism = number(e.materialism, 50) / 100,
                aggression = number(e.aggression, 50) / 100,
                loyalty = number(e.loyalty, 50) / 100,
                forgiveness = number(e.forgiveness, 50) / 100,
                bravery = number(e.bravery, 50) / 100,
            }
        end
        provenance.personality[#provenance.personality + 1] =
            "disposition_projection"
        if proj.derivedFromTraits == true
            and type(proj.appliedTraits) == "table"
        then
            for index = 1, #proj.appliedTraits do
                provenance.traits[#provenance.traits + 1] =
                    tostring(proj.appliedTraits[index])
            end
        end
        if type(proj.temporaryDemeanor) == "table" then
            for axis, delta in pairs(proj.temporaryDemeanor) do
                if (tonumber(delta) or 0) ~= 0 then
                    provenance.temporaryDemeanor[#provenance.temporaryDemeanor + 1] =
                        tostring(axis)
                end
            end
            table.sort(provenance.temporaryDemeanor)
        end
    else
        provenance.personality[#provenance.personality + 1] = "social_profile"
    end

    add(values, "warmth", (number(effective.compassion, 0.5) - 0.5) * 0.30)
    add(values, "warmth", (number(effective.sociability, 0.5) - 0.5) * 0.22)
    add(values, "openness", (number(effective.sociability, 0.5) - 0.5) * 0.30)
    add(values, "formality", (number(effective.materialism, 0.5) - 0.5) * 0.14)
    add(values, "directness", (number(effective.aggression, 0.5) - 0.5) * 0.18)
    add(values, "hostility", (number(effective.aggression, 0.5) - 0.5) * 0.24)
    add(values, "deference", (number(effective.loyalty, 0.5) - 0.5) * 0.16)
    add(values, "verbosity", (number(effective.sociability, 0.5) - 0.5) * 0.22)
    add(values, "warmth", (number(effective.forgiveness, 0.5) - 0.5) * 0.22)
    add(values, "openness", (number(effective.forgiveness, 0.5) - 0.5) * 0.18)
    add(values, "hostility", (number(effective.forgiveness, 0.5) - 0.5) * -0.10)
    add(values, "directness", (number(effective.bravery, 0.5) - 0.5) * 0.16)
    add(values, "deference", (number(effective.bravery, 0.5) - 0.5) * -0.05)
    local socialStyle = string.lower(tostring(personality.socialStyle or ""))
    if socialStyle == "friendly" or socialStyle == "protective" then
        add(values, "warmth", 0.14)
        add(values, "openness", 0.10)
        add(values, "verbosity", 0.06)
        provenance.personality[#provenance.personality + 1] = "social_style_friendly"
    elseif socialStyle == "withdrawn" or socialStyle == "reserved" then
        add(values, "warmth", -0.08)
        add(values, "openness", -0.18)
        add(values, "verbosity", -0.10)
        add(values, "directness", 0.04)
        provenance.personality[#provenance.personality + 1] = "social_style_withdrawn"
    end

    local approval = normalizedSigned(relationship.approval)
    local respect = normalizedSigned(relationship.respect)
    add(values, "warmth", (approval - 0.5) * 0.28)
    add(values, "deference", (respect - 0.5) * 0.18)
    add(values, "openness", (number(relationship.familiarity, 0) / 100 - 0.5) * 0.28)
    -- Standing can remain unknown while raw approval/respect are already
    -- strongly negative. Preserve that signal for speech tone instead of
    -- making the NPC sound neutral until the familiarity threshold is met.
    local negativeApproval = math.max(0, 0.5 - approval)
    local negativeRespect = math.max(0, 0.5 - respect)
    if negativeApproval > 0 or negativeRespect > 0 then
        add(values, "hostility", negativeApproval * 0.46
            + negativeRespect * 0.28)
        add(values, "directness", negativeApproval * 0.18
            + negativeRespect * 0.12)
        add(values, "openness", -negativeApproval * 0.12
            - negativeRespect * 0.08)
        provenance.relationship[#provenance.relationship + 1] =
            "negative_standing_pressure"
    end
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

    if bond.class == "family" then
        add(values, "warmth", 0.08)
        add(values, "openness", 0.05)
        provenance.bond[#provenance.bond + 1] = "family_bond"
    elseif bond.class == "lover" then
        add(values, "warmth", 0.10)
        add(values, "openness", 0.08)
        add(values, "deference", -0.02)
        provenance.bond[#provenance.bond + 1] = "lover_bond"
    elseif bond.class == "friend" then
        add(values, "warmth", 0.04)
        add(values, "openness", 0.04)
        provenance.bond[#provenance.bond + 1] = "friend_bond"
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
    local resolvedVariant = variant(values)
    return {
        schemaVersion = Style.VERSION,
        schema = Style.SCHEMA,
        variant = resolvedVariant,
        styleProfile = proj and proj.styleProfile or nil,
        baseDisposition = proj and proj.baseDisposition or nil,
        temporaryDemeanor = proj and proj.temporaryDemeanor or nil,
        effectiveDisposition = proj and proj.effectiveDisposition or nil,
        reason = resolvedVariant == "guarded"
            and "hostile_or_defensive_context"
            or "actor_context_style_resolution",
        dimensions = values,
        bond = {
            class = bond.class,
            kind = bond.kind,
            term = bond.term,
        },
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
        dimensions = value.dimensions,
        provenance = value.provenance,
        reason = value.variant == "guarded"
            and "hostile_or_defensive_context"
            or "actor_context_style_resolution",
        revisions = value.revisions,
        bond = {
            class = value.bond and value.bond.class or nil,
            kind = value.bond and value.bond.kind or nil,
            term = value.bond and value.bond.term or nil,
        },
        privacy = {
            genderUsed = false,
            privateProfileFieldsUsed = false,
            semanticMeaningChanged = false,
        },
    }
end

return Style

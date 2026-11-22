-- Actor-neutral responder projection for semantic affordances.
--
-- The generated affordance provider historically served player UI choices.
-- This projection keeps that player contract stable while allowing the same
-- semantic frontier to be requested for an explicit NPC/scene responder.
local Responder = {}

local DispositionProjection = PNC and PNC.ConvoEngine
    and PNC.ConvoEngine.DispositionProjection
    or require "PNC/ConvoEngine/DispositionProjection"

local function copyShallow(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = item end
    return output
end

local function traitListHas(traits, trait)
    if type(traits) ~= "table" then return false end
    if traits[trait] == true then return true end
    for key, value in pairs(traits) do
        if type(key) == "string" and value == true
            and tostring(key) == trait
        then
            return true
        end
        if tostring(value) == trait then return true end
        if type(value) == "table"
            and tostring(value.id or value.type or value.name or "") == trait
        then
            return true
        end
    end
    return false
end

function Responder.Project(context)
    context = type(context) == "table" and context or {}
    local explicit = type(context.affordanceResponder) == "table"
        and context.affordanceResponder or nil
    local player = type(context.player) == "table" and context.player or {}
    local legacyPlayer = explicit == nil
    local source = explicit or {}

    local actorID = tostring(
        source.actorID or source.id or source.ref
        or context.playerID or context.playerUUID
        or (legacyPlayer and "player" or "")
    )
    local turnSpeaker = tostring(
        source.turnSpeaker or source.speaker
        or source.actorID or source.id or source.ref
        or (legacyPlayer and "player" or actorID)
    )
    local name = tostring(
        source.name or source.displayName
        or context.playerName or player.name or player.displayName or ""
    )
    local traits = source.traits
        or context.playerTraits
        or player.traits
        or {}

    local visibility = tostring(
        source.visibility or context.affordanceVisibility
        or (legacyPlayer and "player" or "semantic")
    )

    local recipient
    if type(context.affordanceRecipient) == "table" then
        recipient = copyShallow(context.affordanceRecipient)
    elseif context.affordanceRecipientRef ~= nil then
        recipient = {
            kind = "conversation_actor",
            ref = tostring(context.affordanceRecipientRef),
        }
    elseif legacyPlayer then
        recipient = {
            kind = "conversation_actor",
            ref = "npc",
        }
    end

    local aliases = {}
    aliases[turnSpeaker] = true
    if actorID ~= "" then aliases[actorID] = true end
    if type(source.speakerAliases) == "table" then
        for _, alias in pairs(source.speakerAliases) do
            aliases[tostring(alias)] = true
        end
    end
    if legacyPlayer then aliases.player = true end

    local actorInput = {
        id = actorID,
        identitySeed = source.identitySeed or source.seed
            or player.identitySeed or context.identitySeed,
        personality = source.personality or context.responderPersonality
            or player.personality or context.playerPersonality,
        socialProfile = source.socialProfile or player.socialProfile,
        social = source.social or player.social,
        disposition = source.disposition or player.disposition,
        baseDisposition = source.baseDisposition,
        temporaryDemeanor = source.temporaryDemeanor
            or player.temporaryDemeanor,
        condition = source.condition or source.conditionStats
            or player.condition or player.conditionStats,
        runtime = source.runtime or player.runtime,
        traits = traits,
    }
    local resolveOpts = {
        temporaryDemeanor = context.temporaryDemeanor,
        condition = context.condition or context.conditionStats,
        traits = traits,
    }
    if type(source.effectiveDisposition) == "table" then
        resolveOpts.baseDisposition = source.effectiveDisposition
        if type(context.condition) ~= "table"
            and type(context.conditionStats) ~= "table"
        then
            resolveOpts.condition = {}
            actorInput.condition = {}
        end
    end
    local resolvedDisposition = DispositionProjection.Resolve(
        actorInput,
        resolveOpts
    )

    return {
        actorID = actorID,
        turnSpeaker = turnSpeaker,
        name = name,
        traits = traits,
        visibility = visibility,
        recipient = recipient,
        legacyPlayer = legacyPlayer,
        speakerAliases = aliases,
        baseDisposition = resolvedDisposition.baseDisposition,
        temporaryDemeanor = resolvedDisposition.temporaryDemeanor,
        effectiveDisposition = resolvedDisposition.effectiveDisposition,
        dispositionStyle = resolvedDisposition.styleProfile,
        dispositionProjection = resolvedDisposition,
    }
end

function Responder.Disposition(context)
    return Responder.Project(context).dispositionProjection
end

function Responder.EffectiveDisposition(context)
    return Responder.Project(context).effectiveDisposition
end

function Responder.DispositionReason(context, kind, fallbackTraits)
    local projected = Responder.Project(context)
    local disp = projected.dispositionProjection
    if type(disp) == "table" and disp.derivedFromTraits == true
        and type(fallbackTraits) == "table"
    then
        for _, trait in ipairs(fallbackTraits) do
            if traitListHas(projected.traits, trait) then
                return Responder.TraitReason(context, trait)
            end
        end
    end
    local prefix = projected.legacyPlayer
        and "player_disposition:" or "responder_disposition:"
    return prefix .. tostring(kind or "effective")
end

function Responder.HasTrait(context, trait)
    local projected = Responder.Project(context)
    return traitListHas(projected.traits, trait)
end

function Responder.HasAnyTrait(context, values)
    for _, trait in ipairs(values or {}) do
        if Responder.HasTrait(context, trait) then return trait end
    end
    return nil
end

function Responder.Name(context)
    return Responder.Project(context).name
end

function Responder.Speaker(context)
    return Responder.Project(context).turnSpeaker
end

function Responder.Visibility(context)
    return Responder.Project(context).visibility
end

function Responder.RecipientTarget(context)
    return Responder.Project(context).recipient
end

function Responder.TraitReason(context, trait)
    local projected = Responder.Project(context)
    local prefix = projected.legacyPlayer
        and "player_trait:" or "responder_trait:"
    return prefix .. tostring(trait or "")
end

function Responder.MatchesTurnSpeaker(context, speaker)
    local projected = Responder.Project(context)
    return projected.speakerAliases[tostring(speaker or "")] == true
end

return Responder

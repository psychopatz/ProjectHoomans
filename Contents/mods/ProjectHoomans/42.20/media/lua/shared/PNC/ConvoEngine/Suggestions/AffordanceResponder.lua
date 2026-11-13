-- Actor-neutral responder projection for semantic affordances.
--
-- The generated affordance provider historically served player UI choices.
-- This projection keeps that player contract stable while allowing the same
-- semantic frontier to be requested for an explicit NPC/scene responder.
local Responder = {}

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

    return {
        actorID = actorID,
        turnSpeaker = turnSpeaker,
        name = name,
        traits = traits,
        visibility = visibility,
        recipient = recipient,
        legacyPlayer = legacyPlayer,
        speakerAliases = aliases,
    }
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

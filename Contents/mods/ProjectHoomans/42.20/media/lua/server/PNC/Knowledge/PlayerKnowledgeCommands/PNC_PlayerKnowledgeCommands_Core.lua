if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Commands = PNC.PlayerKnowledgeCommands
local H = Commands.Internal
local Network = PNC.Network
local Core = PNC.Core

function Commands.GetDiagnostics(characterUUID)
    local value = Commands.Diagnostics[tostring(characterUUID or "")]
    return value and Core.DeepCopy(value) or nil
end

function H.SafeID(value)
    value = tostring(value or "")
    if value == "" or #value > 128 or string.find(value, "%c") then return nil end
    return value
end

function H.ContextFor(player, reason)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "player_context_unavailable"
    end
    return PNC.PlayerContext.Resolve(player, reason)
end

function H.FactFromSnapshot(snapshot, descriptorID)
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if descriptor.descriptorID == descriptorID then return descriptor end
        end
    end
    return nil
end

function H.SanitizeSnapshot(snapshot)
    local safe = Core.DeepCopy(snapshot or {})
    local nameFact = H.FactFromSnapshot(safe, "identity.name")
    local archetypeFact = H.FactFromSnapshot(safe, "identity.archetype")
    local factionFact = H.FactFromSnapshot(safe, "faction.identity")
    safe.identity = type(safe.identity) == "table" and safe.identity or {}
    safe.identity.displayName = nameFact and tostring(nameFact.value) or nil
    safe.identity.archetypeLabel = archetypeFact
        and safe.identity.archetypeLabel or nil
    if not factionFact then
        safe.identity.factionName = nil
        safe.identity.factionRole = nil
        safe.knownFaction = nil
    end
    return safe, nameFact
end

-- Shared metadata/presence policy for automatic population creation.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationIdentity = PNC.PopulationIdentity or {}

local Identity = PNC.PopulationIdentity

function Identity.FactionName(archetypeID, seed)
    local generator = PNC.FactionNameGenerator
    if not generator or not generator.GenerateFactionName then
        return "Survivor " .. tostring(archetypeID)
    end
    local used = {}
    for _, faction in ipairs(PNC.Factions.List()) do used[faction.name] = true end
    for attempt = 1, 32 do
        local name = generator.GenerateFactionName(archetypeID,
            tostring(seed) .. ":POPULATION:" .. tostring(attempt))
        if not used[name] then return name end
    end
    return "New " .. generator.GenerateFactionName(archetypeID,
        tostring(seed) .. ":POPULATION:FALLBACK")
end

function Identity.FactionTags(archetypeID, creationKind)
    local tags = { populationGenerated = true }
    if creationKind == "MOBILE_GROUP" then
        tags.mobileGroup = true
        tags.mobilePathMode = "random"
    elseif archetypeID == "settler" then
        tags.settlementType = "friendly"
    elseif archetypeID == "looter" then
        tags.settlementType = "looter_toll"
        tags.territorialToll = true
    end
    return tags
end

function Identity.PresenceSpec()
    -- The canonical Directors decide whether the site is loaded. Offscreen
    -- records start abstract, but remain eligible for normal range-enter
    -- materialization instead of being permanently force-abstracted.
    return { presenceMode = "auto", allowLive = true }
end

return Identity

-- ProjectHoomans-only policy applied after Core SurvivorWorld generation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationHoomansPolicy = PNC.PopulationHoomansPolicy or {}

local Policy = PNC.PopulationHoomansPolicy

function Policy.FactionTags(archetypeID, creationKind)
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

function Policy.PresenceSpec()
    -- Physical presence is adopter policy. Canonical identity, membership and
    -- generation metadata have already been planned by Core at this point.
    return { presenceMode = "auto", allowLive = true }
end

return Policy

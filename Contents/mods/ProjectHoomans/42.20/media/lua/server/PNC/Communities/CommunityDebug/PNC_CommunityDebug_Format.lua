if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityDebug = PNC.CommunityDebug or {}
PNC.CommunityDebugInternal = PNC.CommunityDebugInternal or {}

local Debug = PNC.CommunityDebug
local H = PNC.CommunityDebugInternal
local Communities = PNC.Communities
local CommunityMath = PNC.CommunityMath
local Constants = PNC.CommunityConstants
local Core = PNC.Core

function Debug.FormatCommunity(communityID)
    local community, reason = Communities.Get(communityID)
    if not community then
        return "Community Debug\nStatus: " .. tostring(reason)
    end
    return table.concat({
        "Community Debug",
        "ID: " .. community.id,
        "Name: " .. community.name,
        "Faction: " .. community.factionID,
        "Mode/status: " .. community.mode
            .. "/" .. community.status,
        "Population: "
            .. tostring(community.currentPopulation)
            .. "/" .. tostring(
                community.populationCapacity
            ),
        "Security: " .. tostring(community.security),
        "Morale: " .. tostring(community.morale),
        "Revision: " .. tostring(community.revision),
    }, "\n")
end

return Debug


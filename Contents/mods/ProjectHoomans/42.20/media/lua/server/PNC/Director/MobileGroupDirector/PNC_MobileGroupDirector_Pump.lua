if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local CommunityConstants = PNC.CommunityConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const

function Director.Pump(now)
    now = tonumber(now) or (Core.Now and Core.Now()) or 0
    if Director.LastPumpAt
        and now - Director.LastPumpAt < H.PumpIntervalMs
    then
        return 0
    end
    Director.LastPumpAt = now
    local at = H.WorldAge()
    local factionIDs = {}
    for factionID, faction in pairs(
        Factions.Registry and Factions.Registry.byID or {}
    ) do
        local strategicallyOwned = PNC.AbstractGroups
            and PNC.AbstractGroups.FindByFactionID
            and PNC.AbstractGroups.FindByFactionID(factionID) ~= nil
        if not strategicallyOwned and faction.status == "active"
            and Factions.IsMobileGroup(faction)
            and at >= (tonumber(faction.mobile.nextMoveAt) or 0)
        then
            factionIDs[#factionIDs + 1] = factionID
        end
    end
    table.sort(factionIDs)
    local moved = 0
    for _, factionID in ipairs(factionIDs) do
        local ok = Director.RelocateFaction(factionID, at, false)
        if ok then moved = moved + 1 end
    end
    return moved
end

return Director


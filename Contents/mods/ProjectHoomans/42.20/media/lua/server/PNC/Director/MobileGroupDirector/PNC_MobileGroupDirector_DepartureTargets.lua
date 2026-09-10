if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local H = PNC.MobileGroupDirectorInternal
local Factions = PNC.Factions

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function distanceSq(origin, target)
    local dx = finite(target.x, 0) - finite(origin.x, 0)
    local dy = finite(target.y, 0) - finite(origin.y, 0)
    return dx * dx + dy * dy
end

local function hasPlayerMembers(faction)
    for _, present in pairs(faction and faction.playerMemberKeys or {}) do
        if present == true then return true end
    end
    return false
end

local function isPlayerOwnedFaction(faction)
    return faction ~= nil
        and (hasPlayerMembers(faction)
            or faction.ownerPlayerKey ~= nil)
end

local function hasPlayerBase(factionID)
    local repository = PNC.SettlementRepository
    if not repository or not repository.State then return false end
    for _, base in pairs(repository.State.bases or {}) do
        if base and base.id and tostring(base.factionId or "")
            == tostring(factionID or "")
        then
            return true
        end
    end
    return false
end

function H.PlayerBaseCount()
    local repository = PNC.SettlementRepository
    if not repository or not repository.State then return 0 end
    local count = 0
    for _, base in pairs(repository.State.bases or {}) do
        local owner = base and base.factionId and Factions.Get
            and Factions.Get(base.factionId) or nil
        if base and base.id and isPlayerOwnedFaction(owner) then
            count = count + 1
        end
    end
    return count
end

local function locationForSite(site)
    local locations = PNC.AbstractLocations
    if not locations or not locations.RegisterSite then return nil end
    local location = locations.RegisterSite(site, {
        type = "SETTLEMENT",
        tags = { SETTLEMENT = true, FRIENDLY = true,
            SAFE = true, FOOD = true, WATER = true },
    })
    return type(location) == "table" and location or nil
end

local function targetFromLocation(location, kind, ids)
    if not location then return nil end
    ids = type(ids) == "table" and ids or {}
    return {
        kind = kind,
        locationID = location.id,
        x = location.x,
        y = location.y,
        z = location.z,
        radius = 16,
        siteID = ids.siteID,
        communityID = ids.communityID,
        baseID = ids.baseID,
        factionID = ids.factionID,
        zoneID = ids.zoneID,
    }
end

local function addCommunityTargets(output, faction)
    local communities = PNC.Communities
    if not communities or not communities.ListSites
        or not communities.Get
    then
        return
    end
    for _, site in ipairs(communities.ListSites() or {}) do
        if site.occupantCommunityID
            and not (faction.mobile.site
                and faction.mobile.site.id == site.id)
        then
            local community = communities.Get(site.occupantCommunityID)
            local ownerFactionID = community and community.factionID or nil
            local ownerFaction = ownerFactionID and Factions.Get
                and Factions.Get(ownerFactionID) or nil
            if ownerFaction and ownerFaction.id ~= faction.id then
                local playerOwned = isPlayerOwnedFaction(ownerFaction)
                local eligible = not playerOwned
                    or hasPlayerBase(ownerFaction.id)
                if eligible then
                    local location = locationForSite(site)
                    local kind = playerOwned
                        and "player_colony" or "ai_settlement"
                    local target = targetFromLocation(location, kind, {
                        siteID = site.id,
                        communityID = site.occupantCommunityID,
                        factionID = ownerFaction.id,
                    })
                    if target then
                        target.distanceSq = distanceSq(
                            faction.mobile.site.home,
                            target
                        )
                        output[#output + 1] = target
                    end
                end
            end
        end
    end
end

local function addPlayerBaseTargets(output, faction)
    local repository = PNC.SettlementRepository
    local baseService = PNC.BaseService
    local locations = PNC.AbstractLocations
    if not repository or not repository.State
        or not baseService or not baseService.BuildSnapshot
    then
        return
    end
    for _, base in pairs(repository.State.bases or {}) do
        local ownerFaction = base.factionId and Factions.Get
            and Factions.Get(base.factionId) or nil
        if ownerFaction and ownerFaction.id ~= faction.id
            and isPlayerOwnedFaction(ownerFaction)
        then
            local snapshot = baseService.BuildSnapshot(base)
            local bounds = snapshot and snapshot.geometry
                and snapshot.geometry.bounds or nil
            if bounds then
                local targetX = (bounds.minX + bounds.maxX) / 2
                local targetY = (bounds.minY + bounds.maxY) / 2
                local location = locations and locations.Register
                    and locations.Register({
                        id = "aloc_mobile_player_base_"
                            .. tostring(base.id),
                        type = "SETTLEMENT",
                        x = targetX, y = targetY,
                        z = bounds.minZ or 0,
                        tags = { SETTLEMENT = true, FRIENDLY = true,
                            SAFE = true },
                    }) or nil
                local target = targetFromLocation(location,
                    "player_colony", {
                        baseID = base.id,
                        factionID = ownerFaction.id,
                        zoneID = base.baseZoneId,
                    })
                if target then
                    target.radius = math.max(8, math.min(32,
                        math.sqrt(((bounds.maxX - bounds.minX) / 2) ^ 2
                            + ((bounds.maxY - bounds.minY) / 2) ^ 2)))
                    target.distanceSq = distanceSq(
                        faction.mobile.site.home,
                        target
                    )
                    output[#output + 1] = target
                end
            end
        end
    end
end

function H.ResolveSettlementDepartureTarget(faction)
    local output = {}
    addCommunityTargets(output, faction)
    addPlayerBaseTargets(output, faction)
    local hostile = faction.archetypeID == "looter"
    table.sort(output, function(left, right)
        local leftPriority = left.kind == (hostile
            and "player_colony" or "ai_settlement") and 0 or 1
        local rightPriority = right.kind == (hostile
            and "player_colony" or "ai_settlement") and 0 or 1
        if leftPriority ~= rightPriority then
            return leftPriority < rightPriority
        end
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return tostring(left.locationID) < tostring(right.locationID)
    end)
    return output[1]
end

return H

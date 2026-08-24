if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local H = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Core = PNC.Core

function H.FactionName(factionID, fallback)
    local faction = factionID and PNC.Factions and PNC.Factions.Get
        and PNC.Factions.Get(factionID) or nil
    return tostring(faction and faction.name
        or fallback or "Unknown signal")
end

function H.FactionArchetype(factionID)
    local faction = factionID and PNC.Factions and PNC.Factions.Get
        and PNC.Factions.Get(factionID) or nil
    return faction and faction.archetypeID or nil
end

function H.SettlementEntity(community)
    local base = community and PNC.BaseService
        and PNC.BaseService.GetForColony
        and PNC.BaseService.GetForColony(community.id) or nil
    local baseSnapshot = base and PNC.BaseService.BuildSnapshot
        and PNC.BaseService.BuildSnapshot(base) or nil
    local bounds = baseSnapshot and baseSnapshot.geometry
        and baseSnapshot.geometry.bounds or nil
    local site = community and community.site
    local home = site and site.home or community and community.home
    if not community or community.status ~= "active" or not base or not bounds
    then
        return nil
    end
    local x = (tonumber(bounds.minX) + tonumber(bounds.maxX)) / 2
    local y = (tonumber(bounds.minY) + tonumber(bounds.maxY)) / 2
    return {
        entityID = tostring(community.id),
        kind = Types.KIND_SETTLEMENT,
        name = tostring(community.name or "Survivor settlement"),
        factionID = community.factionID,
        archetypeID = H.FactionArchetype(community.factionID),
        x = x,
        y = y,
        z = tonumber(bounds.minZ) or home and tonumber(home.z) or 0,
        population = tonumber(community.currentPopulation) or 0,
    }
end

function H.MobileGroupEntity(group)
    local location = group and group.location
    if not group or not location
        or not tonumber(location.x) or not tonumber(location.y)
    then
        return nil
    end
    return {
        entityID = tostring(group.id),
        kind = Types.KIND_MOBILE_GROUP,
        name = H.FactionName(group.factionId,
            group.groupType or "Mobile group"),
        factionID = group.factionId,
        archetypeID = H.FactionArchetype(group.factionId),
        groupType = group.groupType,
        x = tonumber(location.x),
        y = tonumber(location.y),
        z = tonumber(location.z) or 0,
        population = #(group.memberIds or {}),
    }
end

function Discovery.ListWorldEntities()
    local output = {}
    local communities = PNC.Communities and PNC.Communities.List
        and PNC.Communities.List() or {}
    for _, community in ipairs(communities) do
        local entity = H.SettlementEntity(community)
        if entity then output[#output + 1] = entity end
    end
    local groups = PNC.AbstractGroups and PNC.AbstractGroups.List
        and PNC.AbstractGroups.List() or {}
    for _, group in ipairs(groups) do
        local entity = H.MobileGroupEntity(group)
        if entity then output[#output + 1] = entity end
    end
    table.sort(output, function(left, right)
        if left.kind ~= right.kind then return left.kind < right.kind end
        return left.entityID < right.entityID
    end)
    return output
end

function Discovery.InvalidateWorldEntityCache()
    Discovery.WorldEntityCache.list = nil
    Discovery.WorldEntityCache.builtAt = 0
end

function Discovery.GetCachedWorldEntities(now)
    local cache = Discovery.WorldEntityCache
    now = tonumber(now) or Core.Now()
    if cache.list and now - (tonumber(cache.builtAt) or 0)
        < Discovery.WORLD_ENTITY_CACHE_MS
    then
        return cache.list
    end
    cache.list = Discovery.ListWorldEntities()
    cache.builtAt = now
    return cache.list
end

function Discovery.ResolveEntity(kind, entityID)
    kind = tostring(kind or "")
    entityID = tostring(entityID or "")
    if not Types.IsKind(kind) then return nil end
    for _, candidate in ipairs(Discovery.ListWorldEntities()) do
        if candidate.kind == kind and candidate.entityID == entityID then
            return candidate
        end
    end
    return nil
end

return Discovery

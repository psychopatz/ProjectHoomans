-- Strategic entity resolution, phase mutation, and client projection.

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

local function factionName(factionID, fallback)
    local faction = factionID and PNC.Factions and PNC.Factions.Get
        and PNC.Factions.Get(factionID) or nil
    return tostring(faction and faction.name or fallback or "Unknown signal")
end

local function settlementEntity(community)
    local site = community and community.site
    local home = site and site.home or community and community.home
    if not community or community.status ~= "active"
        or not home or not tonumber(home.x) or not tonumber(home.y)
    then return nil end
    return {
        entityID = tostring(community.id),
        kind = Types.KIND_SETTLEMENT,
        name = tostring(community.name or "Survivor settlement"),
        factionID = community.factionID,
        x = tonumber(home.x), y = tonumber(home.y),
        z = tonumber(home.z) or 0,
        population = tonumber(community.currentPopulation) or 0,
    }
end

local function mobileGroupEntity(group)
    local location = group and group.location
    if not group or not location
        or not tonumber(location.x) or not tonumber(location.y)
    then return nil end
    return {
        entityID = tostring(group.id),
        kind = Types.KIND_MOBILE_GROUP,
        name = factionName(group.factionId, group.groupType or "Mobile group"),
        factionID = group.factionId,
        groupType = group.groupType,
        x = tonumber(location.x), y = tonumber(location.y),
        z = tonumber(location.z) or 0,
        population = #(group.memberIds or {}),
    }
end

function Discovery.ListWorldEntities()
    local output = {}
    for _, community in ipairs(PNC.Communities
        and PNC.Communities.List and PNC.Communities.List() or {})
    do
        local entity = settlementEntity(community)
        if entity then output[#output + 1] = entity end
    end
    for _, group in ipairs(PNC.AbstractGroups
        and PNC.AbstractGroups.List and PNC.AbstractGroups.List() or {})
    do
        local entity = mobileGroupEntity(group)
        if entity then output[#output + 1] = entity end
    end
    table.sort(output, function(left, right)
        if left.kind ~= right.kind then return left.kind < right.kind end
        return left.entityID < right.entityID
    end)
    return output
end

function Discovery.ResolveEntity(kind, entityID)
    kind = tostring(kind or "")
    entityID = tostring(entityID or "")
    if kind == Types.KIND_SETTLEMENT then
        local community = PNC.Communities and PNC.Communities.Get
            and PNC.Communities.Get(entityID) or nil
        return settlementEntity(community)
    end
    if kind == Types.KIND_MOBILE_GROUP then
        local group = PNC.AbstractGroups and PNC.AbstractGroups.Get
            and PNC.AbstractGroups.Get(entityID) or nil
        return mobileGroupEntity(group)
    end
    return nil
end

function Discovery.SetPhase(player, kind, entityID, phase, source)
    if not Types.IsKind(kind) then return nil, "invalid_kind" end
    local entity = Discovery.ResolveEntity(kind, entityID)
    if not entity then return nil, "entity_not_found" end
    local record, uuid = Internal.PlayerRecord(player, true)
    if not record then return nil, uuid end
    local entries = record.entities[kind]
    local current = entries[entity.entityID]
    local nextPhase = Types.ClampPhase(phase)
    if current and Types.ClampPhase(current.phase) >= nextPhase then
        return current, "unchanged"
    end
    local at = Internal.WorldHour()
    current = current or {
        entityID = entity.entityID,
        kind = kind,
        discoveredAt = at,
    }
    current.phase = nextPhase
    current.source = tostring(source or "unknown")
    current.updatedAt = at
    current.x, current.y, current.z = entity.x, entity.y, entity.z
    entries[entity.entityID] = current
    record.revision = (tonumber(record.revision) or 0) + 1
    Discovery.Registry.revision =
        (tonumber(Discovery.Registry.revision) or 0) + 1
    Discovery.Dirty = true
    Discovery.Save()
    return current, "advanced"
end

local function approximateCoordinate(value, entityID, axis)
    local hash = axis == "x" and 17 or 31
    local token = tostring(entityID or "") .. axis
    for index = 1, #token do
        hash = (hash * 33 + string.byte(token, index)) % 9973
    end
    return tonumber(value) + ((hash % 161) - 80)
end

function Discovery.BuildSnapshot(player, result)
    local record, uuid = Internal.PlayerRecord(player, true)
    if not record then
        return { state = "error", reason = uuid, entities = {} }
    end
    local entities = {}
    for _, kind in ipairs({
        Types.KIND_SETTLEMENT,
        Types.KIND_MOBILE_GROUP,
    }) do
        for entityID, entry in pairs(record.entities[kind] or {}) do
            local current = Discovery.ResolveEntity(kind, entityID)
            local phase = Types.ClampPhase(entry.phase)
            local x = current and current.x or entry.x
            local y = current and current.y or entry.y
            if phase == Types.PHASE_RUMORED then
                x = approximateCoordinate(x, entityID, "x")
                y = approximateCoordinate(y, entityID, "y")
            end
            entities[#entities + 1] = {
                entityID = entityID,
                kind = kind,
                phase = phase,
                phaseName = Types.PhaseName(phase),
                source = entry.source,
                discoveredAt = entry.discoveredAt,
                updatedAt = entry.updatedAt,
                name = phase >= Types.PHASE_CONTACTED
                    and current and current.name
                    or kind == Types.KIND_SETTLEMENT
                        and "Unknown settlement" or "Unknown mobile signal",
                factionID = phase >= Types.PHASE_CONTACTED
                    and current and current.factionID or nil,
                groupType = phase >= Types.PHASE_LOCATED
                    and current and current.groupType or nil,
                population = phase >= Types.PHASE_CONTACTED
                    and current and current.population or nil,
                x = x, y = y,
                z = current and current.z or entry.z or 0,
                approximate = phase == Types.PHASE_RUMORED,
            }
        end
    end
    table.sort(entities, function(left, right)
        if left.kind ~= right.kind then return left.kind < right.kind end
        return left.entityID < right.entityID
    end)
    return {
        state = "known",
        characterUUID = uuid,
        revision = tonumber(record.revision) or 0,
        entities = entities,
        result = result,
        radioCooldownHours = Discovery.RADIO_COOLDOWN_HOURS,
        lastRadioScanAt = tonumber(record.lastRadioScanAt) or 0,
        serverWorldHour = Internal.WorldHour(),
    }
end

function Internal.DistanceSquared(player, entity)
    local dx = (tonumber(player:getX()) or 0) - entity.x
    local dy = (tonumber(player:getY()) or 0) - entity.y
    return dx * dx + dy * dy
end

return Discovery

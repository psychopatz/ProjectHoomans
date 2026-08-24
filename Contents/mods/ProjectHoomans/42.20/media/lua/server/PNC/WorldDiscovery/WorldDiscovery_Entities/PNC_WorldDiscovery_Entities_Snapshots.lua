if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

function Internal.ApproximateCoordinate(value, entityID, axis)
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
    local currentByKind = { settlement = {}, mobile_group = {} }
    for _, current in ipairs(Discovery.ListWorldEntities()) do
        currentByKind[current.kind][current.entityID] = current
    end
    for _, kind in ipairs({
        Types.KIND_SETTLEMENT,
        Types.KIND_MOBILE_GROUP,
    }) do
        for entityID, entry in pairs(record.entities[kind] or {}) do
            local current = currentByKind[kind][entityID]
            local phase = Types.ClampPhase(entry.phase)
            local x = current and current.x or entry.x
            local y = current and current.y or entry.y
            if phase == Types.PHASE_RUMORED then
                x = Internal.ApproximateCoordinate(x, entityID, "x")
                y = Internal.ApproximateCoordinate(y, entityID, "y")
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
                x = x,
                y = y,
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

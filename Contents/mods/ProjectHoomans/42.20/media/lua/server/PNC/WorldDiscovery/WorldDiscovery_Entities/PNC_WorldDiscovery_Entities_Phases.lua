if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

function Discovery.SetResolvedPhase(player, entity, phase, source, deferSave)
    if not entity or not Types.IsKind(entity.kind) then
        return nil, "invalid_entity"
    end
    local record, uuid = Internal.PlayerRecord(player, true)
    if not record then return nil, uuid end
    local kind = entity.kind
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
    if deferSave ~= true then Discovery.Save() end
    return current, "advanced"
end

function Discovery.SetPhase(player, kind, entityID, phase, source, deferSave)
    if not Types.IsKind(kind) then return nil, "invalid_kind" end
    local entity = Discovery.ResolveEntity(kind, entityID)
    if not entity then return nil, "entity_not_found" end
    return Discovery.SetResolvedPhase(
        player, entity, phase, source, deferSave)
end

local function setArrivalState(
    player, entity, arrivalState, presenceStatus, source, deferSave
)
    if not entity or not Types.IsKind(entity.kind) then
        return nil, "invalid_entity"
    end
    local record, uuid = Internal.PlayerRecord(player, true)
    if not record then return nil, uuid end
    local kind = entity.kind
    local entries = record.entities[kind]
    local current = entries[entity.entityID]
    local at = Internal.WorldHour()
    local nextState = Types.ArrivalState(arrivalState)
    local nextPresence = Types.PresenceStatus(presenceStatus)
    local changed = false
    if not current then
        current = {
            entityID = entity.entityID,
            kind = kind,
            phase = Types.PHASE_LOCATED,
            source = tostring(source or "unknown"),
            discoveredAt = at,
            updatedAt = at,
            x = entity.x,
            y = entity.y,
            z = entity.z,
            arrivalState = Types.ARRIVAL_UNCHECKED,
            searchedAt = 0,
            contactedAt = 0,
            presenceStatus = Types.PRESENCE_UNKNOWN,
        }
        entries[entity.entityID] = current
        changed = true
    end
    if nextState == Types.ARRIVAL_CONTACTED
        or current.arrivalState ~= Types.ARRIVAL_CONTACTED
            and nextState == Types.ARRIVAL_SEARCHED
                and current.arrivalState ~= Types.ARRIVAL_SEARCHED
    then
        if current.arrivalState ~= nextState then
            current.arrivalState = nextState
            changed = true
        end
    end
    if nextState == Types.ARRIVAL_SEARCHED
        and (tonumber(current.searchedAt) or 0) <= 0
    then
        current.searchedAt = at
        changed = true
    elseif nextState == Types.ARRIVAL_CONTACTED
        and (tonumber(current.contactedAt) or 0) <= 0
    then
        current.contactedAt = at
        current.searchedAt = (tonumber(current.searchedAt) or 0) > 0
            and current.searchedAt or at
        changed = true
    end
    if presenceStatus ~= nil
        and current.presenceStatus ~= nextPresence
    then
        -- A later successful encounter is allowed to improve an earlier
        -- failed/unknown search, but a transient failed probe must not erase
        -- a confirmed presence.
        if current.presenceStatus ~= Types.PRESENCE_PRESENT
            or nextPresence == Types.PRESENCE_PRESENT
        then
            current.presenceStatus = nextPresence
            changed = true
        end
    end
    if changed then
        current.source = tostring(source or current.source or "unknown")
        current.updatedAt = at
        current.x, current.y, current.z = entity.x, entity.y, entity.z
        record.revision = (tonumber(record.revision) or 0) + 1
        Discovery.Registry.revision =
            (tonumber(Discovery.Registry.revision) or 0) + 1
        Discovery.Dirty = true
        if deferSave ~= true then Discovery.Save() end
        return current, "advanced"
    end
    return current, "unchanged"
end

function Discovery.MarkArrived(
    player, entity, presenceStatus, source, deferSave
)
    return setArrivalState(
        player,
        entity,
        Types.ARRIVAL_SEARCHED,
        presenceStatus,
        source or "traversal",
        deferSave
    )
end

function Discovery.MarkContacted(player, entity, source, deferSave)
    return setArrivalState(
        player,
        entity,
        Types.ARRIVAL_CONTACTED,
        Types.PRESENCE_PRESENT,
        source or "conversation",
        deferSave
    )
end

return Discovery

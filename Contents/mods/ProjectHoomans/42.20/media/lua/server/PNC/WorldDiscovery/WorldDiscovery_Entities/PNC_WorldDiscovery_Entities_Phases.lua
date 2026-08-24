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

return Discovery

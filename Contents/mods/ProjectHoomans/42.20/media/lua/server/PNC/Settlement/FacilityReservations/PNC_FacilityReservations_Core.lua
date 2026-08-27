if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Reservations = PNC.FacilityReservations
local H = Reservations.Internal

function H.IsExclusiveComponent(component)
    return component and (component.kind == "anchor"
        or component.role == "growing.plot")
end

function H.IsExclusiveResource(resource)
    return resource and resource.exclusive ~= false
end

function H.HasEntries(source)
    for _, _ in pairs(type(source) == "table" and source or {}) do
        return true
    end
    return false
end

function H.Now()
    return PNC.Core.Now()
end

function H.HasActivityCapacity(facilityId, purpose)
    local facility = PNC.SettlementRepository.GetFacility(facilityId)
    local activityKey = tostring(facilityId) .. ":"
        .. tostring(purpose or "activity")
    local activityLimit
    if PNC.FacilityResources and PNC.FacilityResources.GetCapacity then
        activityLimit = select(1, PNC.FacilityResources.GetCapacity(
            facility, purpose))
    else
        local level = facility and PNC.FacilityDefinitions.GetLevel(
            facility.definitionId, facility.level) or nil
        activityLimit = level and level.activityLimits
            and level.activityLimits[purpose]
            and level.activityLimits[purpose].maxConcurrent
    end
    return not activityLimit
        or (tonumber(Reservations.ByActivity[activityKey]) or 0)
            < activityLimit
end

function Reservations.Release(id, reason)
    local reservation = Reservations.ByID[tostring(id or "")]
    if not reservation then return false, "RESERVATION_NOT_FOUND" end
    Reservations.ByID[reservation.id] = nil
    if reservation.componentId and reservation.componentId ~= ""
        and Reservations.ByComponent[reservation.componentId] == reservation.id
    then
        Reservations.ByComponent[reservation.componentId] = nil
    end
    if reservation.resourceKey and reservation.resourceKey ~= ""
        and Reservations.ByResource[reservation.resourceKey] == reservation.id
    then
        Reservations.ByResource[reservation.resourceKey] = nil
    end
    local activityKey = tostring(reservation.facilityId) .. ":"
        .. reservation.purpose
    Reservations.ByActivity[activityKey] = math.max(0,
        (tonumber(Reservations.ByActivity[activityKey]) or 1) - 1)
    if Reservations.ByActivity[activityKey] == 0 then
        Reservations.ByActivity[activityKey] = nil
    end
    local npc = Reservations.ByNPC[reservation.npcId]
    if npc then
        npc[reservation.id] = nil
        if not H.HasEntries(npc) then
            Reservations.ByNPC[reservation.npcId] = nil
        end
    end
    reservation.state = reason == "complete" and "COMPLETED" or "RELEASED"
    reservation.releaseReason = reason
    if PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.MarkDirty
    then
        PNC.Tasking.Commands.MarkDirty(reservation.npcId,
            "FACILITY_SLOT_RELEASED")
    end
    return true, reservation
end

function Reservations.Expire(at)
    at = tonumber(at) or H.Now()
    local count = 0
    for id, reservation in pairs(Reservations.ByID) do
        if reservation.expiresAt <= at then
            Reservations.Release(id, "expired")
            count = count + 1
        end
    end
    return count
end

function Reservations.Reserve(facilityId, componentId, npcId, purpose,
    ttlMs, metadata)
    Reservations.Expire()
    componentId, npcId = tostring(componentId or ""), tostring(npcId or "")
    local component = PNC.SettlementRepository.GetComponent(componentId)
    if not component or component.facilityId ~= facilityId then
        return false, "COMPONENT_NOT_FOUND"
    end
    if H.IsExclusiveComponent(component)
        and Reservations.ByComponent[componentId]
    then
        return false, "COMPONENT_RESERVED"
    end
    local activityKey = facilityId .. ":" .. tostring(purpose or "activity")
    if not H.HasActivityCapacity(facilityId, purpose) then
        return false, "NO_ACTIVITY_CAPACITY"
    end
    local id = PNC.Core.GenerateID("facility_reservation")
    local reservation = {
        id = id,
        facilityId = facilityId,
        componentId = componentId,
        npcId = npcId,
        purpose = tostring(purpose or "activity"),
        state = "RESERVED",
        workOrderId = type(metadata) == "table" and metadata.workOrderId
            or nil,
        createdAt = H.Now(),
        expiresAt = H.Now() + math.max(1000,
            math.floor(tonumber(ttlMs) or Reservations.DEFAULT_TTL_MS)),
    }
    Reservations.ByID[id] = reservation
    if H.IsExclusiveComponent(component) then
        Reservations.ByComponent[componentId] = id
    end
    Reservations.ByActivity[activityKey] =
        (tonumber(Reservations.ByActivity[activityKey]) or 0) + 1
    local npc = Reservations.ByNPC[npcId]
    if not npc then
        npc = {}
        Reservations.ByNPC[npcId] = npc
    end
    npc[id] = true
    return true, reservation
end

function Reservations.ReserveResource(facilityId, resource, npcId, purpose,
    ttlMs, metadata)
    Reservations.Expire()
    if type(resource) ~= "table" then
        return false, "RESOURCE_NOT_FOUND"
    end
    local resourceKey = tostring(resource.resourceKey or "")
    if resourceKey == "" then return false, "RESOURCE_KEY_REQUIRED" end
    if Reservations.ByResource[resourceKey]
        and H.IsExclusiveResource(resource)
    then
        return false, "RESOURCE_RESERVED"
    end
    if not H.HasActivityCapacity(facilityId, purpose) then
        return false, "NO_ACTIVITY_CAPACITY"
    end
    local id = PNC.Core.GenerateID("facility_reservation")
    local reservation = {
        id = id,
        facilityId = facilityId,
        componentId = "",
        resourceKey = resourceKey,
        resourceKind = tostring(resource.resourceKind or ""),
        resource = PNC.FacilityResources
            and PNC.FacilityResources.CopyDescriptor
            and PNC.FacilityResources.CopyDescriptor(resource) or resource,
        npcId = tostring(npcId or ""),
        purpose = tostring(purpose or "activity"),
        state = "RESERVED",
        workOrderId = type(metadata) == "table" and metadata.workOrderId
            or nil,
        createdAt = H.Now(),
        expiresAt = H.Now() + math.max(1000,
            math.floor(tonumber(ttlMs) or Reservations.DEFAULT_TTL_MS)),
    }
    Reservations.ByID[id] = reservation
    if H.IsExclusiveResource(resource) then
        Reservations.ByResource[resourceKey] = id
    end
    local activityKey = tostring(facilityId) .. ":" .. reservation.purpose
    Reservations.ByActivity[activityKey] =
        (tonumber(Reservations.ByActivity[activityKey]) or 0) + 1
    local npc = Reservations.ByNPC[reservation.npcId]
    if not npc then npc = {}; Reservations.ByNPC[reservation.npcId] = npc end
    npc[id] = true
    return true, reservation
end

function Reservations.ReleaseResource(resourceKey)
    local id = Reservations.ByResource[tostring(resourceKey or "")]
    return id and Reservations.Release(id, "resource_removed")
        or false, id and "RESOURCE_NOT_RESERVED" or "RESOURCE_NOT_FOUND"
end

function Reservations.Start(id, ttlMs)
    local reservation = Reservations.ByID[tostring(id or "")]
    if not reservation then return false, "RESERVATION_NOT_FOUND" end
    reservation.state = "ACTIVE"
    reservation.expiresAt = H.Now() + math.max(1000,
        math.floor(tonumber(ttlMs) or Reservations.DEFAULT_TTL_MS))
    return true, reservation
end

function Reservations.Complete(id)
    return Reservations.Release(id, "complete")
end

function Reservations.ReleaseComponent(componentId)
    local id = Reservations.ByComponent[tostring(componentId or "")]
    local reservation = id and Reservations.ByID[id] or nil
    local result, details = id
        and Reservations.Release(id, "component_removed") or false, nil
    if reservation and PNC.Tasking and PNC.Tasking.Commands then
        PNC.Tasking.Commands.MarkDirty(reservation.npcId,
            "FACILITY_COMPONENT_REMOVED")
    end
    return result, details
end

function Reservations.ReleaseNPC(npcId, reason)
    local bucket = Reservations.ByNPC[tostring(npcId or "")]
    local ids = {}
    for id, _ in pairs(bucket or {}) do ids[#ids + 1] = id end
    for index = 1, #ids do
        Reservations.Release(ids[index], reason or "npc_unavailable")
    end
    return #ids
end

return Reservations

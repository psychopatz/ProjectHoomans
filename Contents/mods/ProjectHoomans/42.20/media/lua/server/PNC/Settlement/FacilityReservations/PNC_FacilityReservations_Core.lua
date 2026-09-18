if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Reservations = PNC.FacilityReservations
local H = Reservations.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

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

local function isSeatingReservation(reservation, purpose)
    return reservation and (
        tostring(reservation.resourceKind or "") == "seating_surface"
        or tostring(reservation.resourceKind or "") == "floor_seating"
        or tostring(purpose or reservation.purpose or "")
            == "ambient_roam_seat"
    )
end

local function isSleepResource(resource)
    local surface = tostring(resource and resource.sleepSurface or "")
    return resource and (
        tostring(resource.resourceKind or "") == "sleep_surface"
        or surface == "bed" or surface == "sofa"
    ) and (surface == "bed" or surface == "sofa")
end

local function sleepCapacity(resource, metadata)
    local explicit = tonumber(metadata and metadata.sleepCapacity)
        or tonumber(resource and (resource.sleepCapacity
            or resource.bedCapacity))
    if explicit and explicit >= 1 then
        return math.min(2, math.floor(explicit))
    end
    if tostring(resource and resource.sleepSurface or "") == "sofa" then
        return 1
    end
    local width = tonumber(resource and (resource.gridWidth
        or resource.sleepGridWidth)) or 1
    local height = tonumber(resource and (resource.gridHeight
        or resource.sleepGridHeight)) or 1
    return math.max(width, height) >= 2 and 2 or 1
end

local function sleepSlotKey(resourceKey, slotId)
    if tostring(slotId or "") == "" then return nil end
    return tostring(resourceKey or "") .. ":" .. tostring(slotId)
end

local function sleepReservationCount(resourceKey, excludeId)
    local count = 0
    local prefix = tostring(resourceKey or "") .. ":"
    for slotKey, id in pairs(Reservations.ByResourceSlot or {}) do
        if string.sub(tostring(slotKey), 1, #prefix) == prefix
            and tostring(id) ~= tostring(excludeId or "")
        then
            count = count + 1
        end
    end
    return count
end

local function auditReservation(eventName, reservation, reason)
    if not Diagnostics or Diagnostics.SeatingAuditEnabled ~= true
        or not Diagnostics.LogSeatingAudit
        or not isSeatingReservation(reservation)
    then
        return
    end
    Diagnostics.LogSeatingAudit(eventName, {
        "npc=" .. tostring(reservation.npcId or ""),
        "reservationId=" .. tostring(reservation.id or ""),
        "facilityId=" .. tostring(reservation.facilityId or ""),
        "resourceKey=" .. tostring(reservation.resourceKey or ""),
        "resourceKind=" .. tostring(reservation.resourceKind or ""),
        "purpose=" .. tostring(reservation.purpose or ""),
        "state=" .. tostring(reservation.state or ""),
        "expiresAt=" .. tostring(reservation.expiresAt or ""),
        "reason=" .. tostring(reason or ""),
    })
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
    auditReservation("seat_reservation_released", reservation, reason)
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
    if reservation.resourceSlotKey
        and Reservations.ByResourceSlot[reservation.resourceSlotKey]
            == reservation.id
    then
        Reservations.ByResourceSlot[reservation.resourceSlotKey] = nil
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
    if PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        PNC.Tasking.Events.Emit("FACILITY_SLOT_RELEASED", {
            npcId = reservation.npcId, source = "FacilityReservations",
            entityId = reservation.id,
        })
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
    local reservationPurpose = tostring(purpose or "activity")
    local sleep = isSleepResource(resource)
        and (reservationPurpose == "sleep"
            or reservationPurpose == "ambient_roam_sleep")
    local slotId = sleep and type(metadata) == "table"
        and (metadata.sleepSlotId or metadata.slotId) or nil
    local slotKey = sleep and sleepSlotKey(resourceKey, slotId) or nil
    local capacity = sleep and sleepCapacity(resource, metadata) or nil
    if resourceKey == "" then return false, "RESOURCE_KEY_REQUIRED" end
    if sleep and slotKey then
        if Reservations.ByResource[resourceKey]
            and H.IsExclusiveResource(resource)
        then
            return false, "RESOURCE_RESERVED"
        end
        if Reservations.ByResourceSlot[slotKey] then
            return false, "RESOURCE_SLOT_RESERVED"
        end
        if sleepReservationCount(resourceKey) >= capacity then
            return false, "RESOURCE_CAPACITY_REACHED"
        end
    elseif Reservations.ByResource[resourceKey]
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
        resourceSlotId = slotId and tostring(slotId) or nil,
        resourceSlotKey = slotKey,
        resourceCapacity = capacity,
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
    if slotKey then
        Reservations.ByResourceSlot[slotKey] = id
    elseif H.IsExclusiveResource(resource) then
        Reservations.ByResource[resourceKey] = id
    end
    local activityKey = tostring(facilityId) .. ":" .. reservation.purpose
    Reservations.ByActivity[activityKey] =
        (tonumber(Reservations.ByActivity[activityKey]) or 0) + 1
    local npc = Reservations.ByNPC[reservation.npcId]
    if not npc then npc = {}; Reservations.ByNPC[reservation.npcId] = npc end
    npc[id] = true
    auditReservation("seat_reservation_acquired", reservation)
    return true, reservation
end

function Reservations.ReleaseResource(resourceKey)
    local key = tostring(resourceKey or "")
    local ids = {}
    local legacy = Reservations.ByResource[key]
    if legacy then ids[#ids + 1] = legacy end
    local prefix = key .. ":"
    for slotKey, id in pairs(Reservations.ByResourceSlot or {}) do
        if string.sub(tostring(slotKey), 1, #prefix) == prefix then
            ids[#ids + 1] = id
        end
    end
    if #ids == 0 then return false, "RESOURCE_NOT_FOUND" end
    for index = 1, #ids do
        Reservations.Release(ids[index], "resource_removed")
    end
    return true, "RESOURCE_RELEASED"
end

function Reservations.IsResourceAvailable(resource, slotId, excludeId)
    local key = tostring(resource and resource.resourceKey or "")
    if key == "" then return false end
    Reservations.Expire()
    local legacy = Reservations.ByResource[key]
    if legacy and tostring(legacy) ~= tostring(excludeId or "") then
        return false
    end
    if isSleepResource(resource) then
        local slotKey = sleepSlotKey(key, slotId)
        if slotKey then
            local owner = Reservations.ByResourceSlot[slotKey]
            return not owner or tostring(owner) == tostring(excludeId or "")
        end
        return sleepReservationCount(key, excludeId)
            < sleepCapacity(resource)
    end
    return legacy == nil or tostring(legacy) == tostring(excludeId or "")
end

function Reservations.Start(id, ttlMs)
    local reservation = Reservations.ByID[tostring(id or "")]
    if not reservation then return false, "RESERVATION_NOT_FOUND" end
    reservation.state = "ACTIVE"
    reservation.expiresAt = H.Now() + math.max(1000,
        math.floor(tonumber(ttlMs) or Reservations.DEFAULT_TTL_MS))
    auditReservation("seat_reservation_renewed", reservation)
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
    if reservation and PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit then
        PNC.Tasking.Events.Emit("FACILITY_COMPONENT_REMOVED", {
            npcId = reservation.npcId, source = "FacilityReservations",
            entityId = reservation.id,
        })
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

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityReservations = PNC.FacilityReservations or {}

local Reservations = PNC.FacilityReservations

local function hasEntries(source)
    for _, _ in pairs(type(source) == "table" and source or {}) do
        return true
    end
    return false
end
Reservations.ByID = Reservations.ByID or {}
Reservations.ByComponent = Reservations.ByComponent or {}
Reservations.ByNPC = Reservations.ByNPC or {}
Reservations.ByActivity = Reservations.ByActivity or {}
Reservations.DEFAULT_TTL_MS = 30000

local function now() return PNC.Core.Now() end

function Reservations.Release(id, reason)
    local reservation = Reservations.ByID[tostring(id or "")]
    if not reservation then return false, "RESERVATION_NOT_FOUND" end
    Reservations.ByID[reservation.id] = nil
    if Reservations.ByComponent[reservation.componentId] == reservation.id then
        Reservations.ByComponent[reservation.componentId] = nil
    end
    local activityKey = reservation.facilityId .. ":" .. reservation.purpose
    Reservations.ByActivity[activityKey] = math.max(0,
        (tonumber(Reservations.ByActivity[activityKey]) or 1) - 1)
    if Reservations.ByActivity[activityKey] == 0 then Reservations.ByActivity[activityKey] = nil end
    local npc = Reservations.ByNPC[reservation.npcId]
    if npc then
        npc[reservation.id] = nil
        if not hasEntries(npc) then
            Reservations.ByNPC[reservation.npcId] = nil
        end
    end
    reservation.state = reason == "complete" and "COMPLETED" or "RELEASED"
    reservation.releaseReason = reason
    if PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.MarkDirty
    then PNC.Tasking.Commands.MarkDirty(reservation.npcId,
        "FACILITY_SLOT_RELEASED") end
    return true, reservation
end

function Reservations.Expire(at)
    at = tonumber(at) or now()
    local count = 0
    for id, reservation in pairs(Reservations.ByID) do
        if reservation.expiresAt <= at then Reservations.Release(id, "expired"); count = count + 1 end
    end
    return count
end

function Reservations.Reserve(facilityId, componentId, npcId, purpose, ttlMs, metadata)
    Reservations.Expire()
    componentId, npcId = tostring(componentId or ""), tostring(npcId or "")
    local component = PNC.SettlementRepository.GetComponent(componentId)
    if not component or component.facilityId ~= facilityId then return false, "COMPONENT_NOT_FOUND" end
    if component.kind == "anchor" and Reservations.ByComponent[componentId] then
        return false, "COMPONENT_RESERVED"
    end
    local facility = PNC.SettlementRepository.GetFacility(facilityId)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    local activityKey = facilityId .. ":" .. tostring(purpose or "activity")
    local activityLimit = level and level.activityLimits
        and level.activityLimits[purpose] and level.activityLimits[purpose].maxConcurrent
    if activityLimit and (tonumber(Reservations.ByActivity[activityKey]) or 0) >= activityLimit then
        return false, "NO_ACTIVITY_CAPACITY"
    end
    local id = PNC.Core.GenerateID("facility_reservation")
    local reservation = { id = id, facilityId = facilityId, componentId = componentId,
        npcId = npcId, purpose = tostring(purpose or "activity"), state = "RESERVED",
        workOrderId = type(metadata) == "table" and metadata.workOrderId or nil,
        createdAt = now(), expiresAt = now() + math.max(1000,
            math.floor(tonumber(ttlMs) or Reservations.DEFAULT_TTL_MS)) }
    Reservations.ByID[id] = reservation
    if component.kind == "anchor" then Reservations.ByComponent[componentId] = id end
    Reservations.ByActivity[activityKey] =
        (tonumber(Reservations.ByActivity[activityKey]) or 0) + 1
    local npc = Reservations.ByNPC[npcId]
    if not npc then npc = {}; Reservations.ByNPC[npcId] = npc end
    npc[id] = true
    return true, reservation
end

function Reservations.Start(id, ttlMs)
    local reservation = Reservations.ByID[tostring(id or "")]
    if not reservation then return false, "RESERVATION_NOT_FOUND" end
    reservation.state = "ACTIVE"
    reservation.expiresAt = now() + math.max(1000,
        math.floor(tonumber(ttlMs) or Reservations.DEFAULT_TTL_MS))
    return true, reservation
end

function Reservations.Complete(id) return Reservations.Release(id, "complete") end

function Reservations.ReleaseComponent(componentId)
    local id = Reservations.ByComponent[tostring(componentId or "")]
    local reservation = id and Reservations.ByID[id] or nil
    local result, details = id and Reservations.Release(id, "component_removed")
        or false, nil
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
    for index = 1, #ids do Reservations.Release(ids[index], reason or "npc_unavailable") end
    return #ids
end

local function componentForCapability(facility, capability)
    local jobDefinition = PNC.FacilityJobDefinitions
        and PNC.FacilityJobDefinitions.Get(capability) or nil
    local preferredRole = jobDefinition and jobDefinition.role or capability
    local fallback
    for componentId, _ in pairs(facility.componentIds or {}) do
        local component = PNC.SettlementRepository.GetComponent(componentId)
        if component and (component.kind ~= "anchor"
            or not Reservations.ByComponent[componentId])
        then
            if component.role == preferredRole then return component end
            fallback = fallback or component
        end
    end
    return fallback
end

local function capabilityForComponent(facility, component)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    for _, capability in ipairs(level and level.capabilities or {}) do
        local definition = PNC.FacilityJobDefinitions
            and PNC.FacilityJobDefinitions.Get(capability) or nil
        if definition and definition.role == component.role then
            return capability
        end
    end
    return nil
end

function PNC.FacilityService.GetActivityCapability(facilityOrId,
    componentId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or PNC.SettlementRepository.GetFacility(facilityOrId)
    local component = componentId and PNC.SettlementRepository.GetComponent(
        componentId) or nil
    if not facility or not component
        or component.facilityId ~= facility.id
    then return nil end
    return capabilityForComponent(facility, component)
end

function Reservations.HasCapacity(facility, capability)
    if not facility or not componentForCapability(facility, capability) then
        return false
    end
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local limit = level and level.activityLimits
        and level.activityLimits[capability]
        and level.activityLimits[capability].maxConcurrent
    local key = facility.id .. ":" .. tostring(capability)
    return not limit or (tonumber(Reservations.ByActivity[key]) or 0) < limit
end

local function regionTarget(component)
    local zKeys = {}
    local z
    local level
    local yKeys
    local y
    local spans
    for z, _ in pairs(component and component.region
        and component.region.levels or {})
    do zKeys[#zKeys + 1] = z end
    table.sort(zKeys)
    local zIndex
    local yIndex
    for zIndex = 1, #zKeys do
        z = zKeys[zIndex]
        level = component.region.levels[z]
        yKeys = {}
        for y, _ in pairs(level.rows or {}) do yKeys[#yKeys + 1] = y end
        table.sort(yKeys)
        for yIndex = 1, #yKeys do
            y = yKeys[yIndex]
            spans = level.rows[y]
            if spans and spans[1] ~= nil then
                return { x = spans[1] + 0.5, y = y + 0.5, z = z }
            end
        end
    end
    return nil
end

function PNC.FacilityService.AcquireActivity(baseId, npcId, capability, options)
    options = type(options) == "table" and options or {}
    local facilities = PNC.FacilityService.ListByCapability(baseId, capability)
    local requested = options.componentId and PNC.SettlementRepository
        .GetComponent(options.componentId) or nil
    for index = 1, #facilities do
        local facility = facilities[index]
        local targetValid = options.abstract == true
            or PNC.FacilityService.RevalidateTargets(facility)
        local component
        if options.componentId and requested
            and requested.facilityId == facility.id
            and (requested.kind ~= "anchor"
                or not Reservations.ByComponent[requested.id])
        then
            component = requested
        elseif not options.componentId then
            component = componentForCapability(facility, capability)
        end
        if targetValid and component then
            local ok, reservation = Reservations.Reserve(facility.id, component.id,
                npcId, capability, options.ttlMs, options)
            if ok then
                local targets = PNC.FacilityInteractionTargets
                    and PNC.FacilityInteractionTargets.Resolve(component) or {}
                local target = targets[1]
                    or component.kind == "region" and regionTarget(component)
                return { ok = true, reservationId = reservation.id,
                    facilityId = facility.id, componentId = component.id,
                    role = component.role,
                    target = target, targets = targets,
                    abstract = options.abstract == true }
            end
        end
    end
    return { ok = false, reason = "NO_ACTIVITY_CAPACITY" }
end

return Reservations

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Reservations = PNC.FacilityReservations
local H = Reservations.Internal

function H.RegionTarget(component)
    local zKeys = {}
    local z
    local level
    local yKeys
    local y
    local spans
    for z, _ in pairs(component and component.region
        and component.region.levels or {})
    do
        zKeys[#zKeys + 1] = z
    end
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

function PNC.FacilityService.AcquireActivity(baseId, npcId, capability,
    options)
    options = type(options) == "table" and options or {}
    local facilities = PNC.FacilityService.ListByCapability(baseId, capability)
    local requested = options.componentId and PNC.SettlementRepository
        .GetComponent(options.componentId) or nil
    for index = 1, #facilities do
        local facility = facilities[index]
        local targetValid = options.abstract == true
            or options.deferWorldValidation == true
            or PNC.FacilityService.RevalidateTargets(facility)
        local component
        if options.componentId and requested
            and requested.facilityId == facility.id
            and (not H.IsExclusiveComponent(requested)
                or not Reservations.ByComponent[requested.id])
        then
            component = requested
        elseif not options.componentId then
            component = H.ComponentForCapability(facility, capability)
        end
        if targetValid and component then
            local ok, reservation = Reservations.Reserve(facility.id,
                component.id, npcId, capability, options.ttlMs, options)
            if ok then
                local targets = PNC.FacilityInteractionTargets
                    and PNC.FacilityInteractionTargets.Resolve(component) or {}
                local target = targets[1]
                    or component.kind == "region" and H.RegionTarget(component)
                return {
                    ok = true,
                    reservationId = reservation.id,
                    facilityId = facility.id,
                    componentId = component.id,
                    role = component.role,
                    target = target,
                    targets = targets,
                    abstract = options.abstract == true,
                }
            end
        end
    end
    return { ok = false, reason = "NO_ACTIVITY_CAPACITY" }
end

return Reservations

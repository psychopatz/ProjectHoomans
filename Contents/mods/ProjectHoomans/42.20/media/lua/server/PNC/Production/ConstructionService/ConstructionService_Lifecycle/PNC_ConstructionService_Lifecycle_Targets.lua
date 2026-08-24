if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}
PNC.ConstructionService.Internal =
    PNC.ConstructionService.Internal or {}

local Service = PNC.ConstructionService
local Internal = Service.Internal
Internal.LifecycleInternal = Internal.LifecycleInternal or {}
local H = Internal.LifecycleInternal

function H.PointFromRegion(region)
    for z, spans in pairs(type(region) == "table" and region.levels or {}) do
        for _, span in ipairs(spans or {}) do
            local x1 = tonumber(span.x1 or span.x)
            local y = tonumber(span.y)
            if x1 and y then return { x = x1, y = y, z = tonumber(z) or 0 } end
        end
    end
    return nil
end

function Internal.ResolveTarget(order)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    local change = order.payload and order.payload.change or {}
    local component = change.action == "remove"
        and PNC.SettlementRepository.GetComponent(change.componentId)
        or change.component
    if change.action == "replace_role" then
        local anchor = change.anchors and change.anchors[1]
        component = anchor and { kind = "anchor", role = change.role,
            x = anchor.x, y = anchor.y, z = anchor.z } or nil
    end
    if component and component.kind == "anchor"
        and component.x ~= nil and component.y ~= nil
    then
        return { ok = true, componentId = component.id
                or "construction:" .. tostring(facility and facility.id),
            facilityId = facility and facility.id, target = {
                x = component.x, y = component.y, z = component.z,
                componentId = component.id, role = component.role,
            } }
    elseif component and component.kind == "region" and component.region then
        local point = H.PointFromRegion(component.region)
        if point then
            return { ok = true, componentId = component.id
                    or "construction:" .. tostring(facility and facility.id),
                facilityId = facility and facility.id,
                target = { x = point.x, y = point.y, z = point.z,
                    componentId = component.id, role = component.role } }
        end
    end
    local point, reason = PNC.FacilityService.ResolveWorkTarget(facility)
    if not point then return { ok = false, reason = reason } end
    return { ok = true, componentId = "construction:" .. facility.id,
        facilityId = facility.id, target = point }
end

return Service


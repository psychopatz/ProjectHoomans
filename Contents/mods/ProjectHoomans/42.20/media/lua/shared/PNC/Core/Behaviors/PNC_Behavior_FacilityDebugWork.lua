-- Debug-only facility routing order. It deliberately uses the production
-- navigation path so a manual test exercises the same movement stack as jobs.

PNC = PNC or {}
PNC.BehaviorFacilityDebugWork = PNC.BehaviorFacilityDebugWork or {}

local Work = PNC.BehaviorFacilityDebugWork
local KIND = "facility_debug_work"
local JOB = "FacilityDebugWork"

local function normalize(_, spec)
    return {
        kind = KIND,
        facilityId = tostring(spec.facilityId or ""),
        facilityName = tostring(spec.facilityName or spec.facilityId or "Facility"),
        componentId = tostring(spec.componentId or ""),
        role = tostring(spec.role or "work"),
        x = tonumber(spec.x) or 0,
        y = tonumber(spec.y) or 0,
        z = tonumber(spec.z) or 0,
    }
end

function Work.Tick(record, zombie)
    local order = record.orderSpec or {}
    local runtime = record.runtime and record.runtime.facilityDebugWork or nil
    if order.kind ~= KIND or not runtime then return false end
    local distance = PNC.Core.Distance(record.x, record.y, order.x, order.y)
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.distance = distance
    if distance <= 0.75 and math.abs((tonumber(record.z) or 0) - order.z) < 0.5 then
        runtime.phase = "WORKING"
        PNC.BehaviorCommon.ClearCombatTarget(record, "facility_debug_working", zombie)
        PNC.BehaviorCommon.HaltMovement(record, zombie, "facility_debug_working")
        if zombie and PNC.Animation then PNC.Animation.Apply(zombie, record, "Idle") end
        return true
    end
    runtime.phase = "TRAVELLING"
    PNC.BehaviorCommon.ClearCombatTarget(record, "facility_debug_travel", zombie)
    PNC.BehaviorCommon.MoveRecord(record, zombie, order.x, order.y, order.z,
        "walk", 0.7, "facility_debug_work")
    return true
end

PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
PNC.JobSystem.RegisterOrder(KIND, JOB)
PNC.BehaviorRegistry.Register(JOB, Work.Tick)

return Work

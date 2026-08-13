if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementDebug = PNC.SettlementDebug or {}

local Debug = PNC.SettlementDebug
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"

function Debug.BuildSnapshot(baseId)
    local base = PNC.BaseService.Get(baseId)
    if not base then return nil, "BASE_NOT_FOUND" end
    local output = {
        base = PNC.BaseService.BuildSnapshot(base), facilities = {},
        components = {}, stockpileNodes = {}, runtime = {
            spatialIndex = Zones.debugStats(), reservations = {},
            interactionTargetCache = {},
        },
    }
    for facilityId, _ in pairs(base.facilityIds or {}) do
        local facility = PNC.FacilityService.BuildSnapshot(facilityId)
        if facility then
            output.facilities[#output.facilities + 1] = facility
            for _, component in ipairs(facility.components or {}) do
                local reservationId = PNC.FacilityReservations.ByComponent[component.id]
                component.reservationId = reservationId
                output.components[#output.components + 1] = component
            end
        end
    end
    for nodeId, _ in pairs(base.stockpileNodeIds or {}) do
        local node = PNC.SettlementRepository.GetStockpileNode(nodeId)
        if node then output.stockpileNodes[#output.stockpileNodes + 1] = PNC.Core.DeepCopy(node) end
    end
    for id, reservation in pairs(PNC.FacilityReservations.ByID) do
        output.runtime.reservations[id] = PNC.Core.DeepCopy(reservation)
    end
    for id, cached in pairs(PNC.FacilityInteractionTargets.Cache) do
        output.runtime.interactionTargetCache[id] = PNC.Core.DeepCopy(cached)
    end
    return output
end

return Debug

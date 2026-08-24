if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

local Service = PNC.FacilityService
local Internal = Service.Internal
local Repository = PNC.SettlementRepository
local Validation = PNC.FacilityValidationService
local Definitions = PNC.FacilityDefinitions
local Costs = PNC.FacilityCostService
local EventsBus = PsychopatzCore and PsychopatzCore.Events


function Service.BuildSnapshot(facility)
    if type(facility) ~= "table" then facility = Repository.GetFacility(facility) end
    if not facility then return nil end
    local output = PNC.Core.DeepCopy(facility)
    output.components = {}
    output.pendingComponents = {}
    output.farming = PNC.FarmingService and PNC.FarmingService.BuildFacilitySnapshot
        and PNC.FarmingService.BuildFacilitySnapshot(facility) or nil
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    output.capabilities = PNC.Core.DeepCopy(level and level.capabilities or {})
    output.workstations = PNC.Core.DeepCopy(level and level.workstations or {})
    for id, _ in pairs(facility.componentIds) do
        local component = Repository.GetComponent(id)
        if component then
            local snapshot = PNC.Core.DeepCopy(component)
            if output.farming and component.role == "growing.plot" then
                for _, plot in ipairs(output.farming.plots or {}) do
                    if tostring(plot.id) == tostring(component.id) then
                        snapshot.width, snapshot.height = plot.width, plot.height
                        snapshot.status = plot.status
                        snapshot.diagnostics = plot.diagnostics
                        break
                    end
                end
            end
            output.components[#output.components + 1] = snapshot
        end
    end
    for _, order in pairs(PNC.WorkRepository
        and PNC.WorkRepository.State and PNC.WorkRepository.State.byId or {}) do
        local payload = order.payload or {}
        local change = payload.change or {}
        if order.operation == "RECONSTRUCT"
            and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED"
            and tostring(payload.facilityId or "") == tostring(facility.id)
            and (change.action == "set" and change.component
                or change.action == "replace_role"
                    and type(change.anchors) == "table")
        then
            if change.action == "set" then
                local pending = PNC.Core.DeepCopy(change.component)
                pending.pending = true
                output.pendingComponents[#output.pendingComponents + 1] = pending
            else
                for pendingIndex, anchor in ipairs(change.anchors) do
                    output.pendingComponents[#output.pendingComponents + 1] = {
                        schemaVersion = 1,
                        id = "pending:" .. tostring(order.id) .. ":"
                            .. tostring(pendingIndex),
                        facilityId = facility.id,
                        kind = "anchor",
                        role = change.role,
                        x = anchor.x, y = anchor.y, z = anchor.z,
                        pending = true,
                    }
                end
            end
        end
    end
    for _, station in pairs(output.workstations or {}) do
        local componentId
        for index = 1, #output.components do
            if output.components[index].role == station.role then
                componentId = output.components[index].id; break
            end
        end
        station.componentId = componentId
        station.workOrderId = componentId and PNC.WorkService
            and PNC.WorkService.ClaimsByStation[componentId] or nil
    end
    return output
end


return Service

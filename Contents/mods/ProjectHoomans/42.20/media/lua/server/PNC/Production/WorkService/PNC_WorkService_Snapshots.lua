if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local terminal = Internal.terminal
local copy = Internal.copy

local function provisionItemFullType(payload)
    if type(payload) ~= "table" then return nil end
    local direct = tostring(payload.activityItemFullType or "")
    if direct ~= "" then return direct end
    for index = 1, #(payload.selected or {}) do
        local selected = payload.selected[index]
        local descriptor = selected and selected.descriptor or {}
        local fullType = tostring(descriptor.fullType or "")
        if fullType ~= "" then return fullType end
    end
    return nil
end

function Service.Queries.BuildTaskSnapshot(colonyId)
    local output = {}
    for _, order in ipairs(Service.Queries.List(colonyId)) do
        if not terminal(order) then
            local worker = order.workerId and PNC.Registry
                and PNC.Registry.Get and PNC.Registry.Get(order.workerId) or nil
            local payload = order.payload or {}
            local facilityId = order.facilityId or payload.facilityId
            local facility = facilityId and PNC.SettlementRepository
                and PNC.SettlementRepository.GetFacility(facilityId) or nil
            local activityItemFullType
            if order.operation == "PROVISION_PICKUP" then
                activityItemFullType = provisionItemFullType(payload)
            end
            local required = math.max(1, tonumber(order.requiredWork) or 1)
            local progress = math.max(0, math.min(required,
                tonumber(order.progress) or 0))
            local refundPercent
            if (order.operation == "CONSTRUCT"
                or order.operation == "RECONSTRUCT")
                and PNC.ConstructionService
                and PNC.ConstructionService.Queries
                and PNC.ConstructionService.Queries.GetCancellationRefund
            then
                local refund = PNC.ConstructionService.Queries
                    .GetCancellationRefund(order)
                refundPercent = refund and refund.percent or nil
            end
            output[#output + 1] = {
                id = order.id,
                operation = order.operation,
                status = order.status,
                manual = order.manual == true,
                blockedReason = order.blockedReason,
                progress = progress,
                requiredWork = required,
                percent = math.floor((progress / required) * 100 + 0.5),
                priority = order.priority,
                workerId = order.workerId,
                workerName = worker and tostring(worker.name or worker.id) or nil,
                executionMode = order.executionMode,
                baseId = order.baseId,
                facilityId = facilityId,
                facilityDefinitionId = facility and facility.definitionId or nil,
                stationId = order.stationId,
                productionSkillId = order.productionSkillId,
                recipeId = order.recipeId,
                quantity = order.quantity,
                technologyId = payload.technologyId,
                specimenFullType = payload.specimenFullType,
                activityItemFullType = activityItemFullType,
                objectInfoName = payload.blueprint
                    and payload.blueprint.objectInfoName or nil,
                buildDisplayName = payload.blueprint
                    and PNC.BuildRecipeCatalog
                    and PNC.BuildRecipeCatalog.Get(
                        payload.blueprint.objectInfoName)
                    and PNC.BuildRecipeCatalog.Get(
                        payload.blueprint.objectInfoName).displayName or nil,
                blueprint = payload.blueprint
                    and copy(payload.blueprint) or nil,
                funded = order.funded == true
                    or payload.input and payload.input.funded == true,
                projectLifecycle = order.projectLifecycle,
                recipeRevision = order.recipeRevision
                    or payload.recipeRevision,
                refundPercent = refundPercent,
                createdAt = order.createdAt,
                updatedAt = order.updatedAt,
                lastProgressAt = order.lastProgressAt,
                retryAt = order.retryAt,
                phase = order.completionStarted == true and "ATOMIC_COMMIT"
                    or order.status,
            }
        end
    end
    return output
end
function Service.Queries.Diagnostics()
    local output = { queuedOrders = 0, activeOrders = 0, blockedOrders = 0,
        stationClaims = {}, workerClaims = {} }
    for _, order in pairs(Repository.State.byId) do
        if order.status == Status.QUEUED or order.status == Status.WAITING_FOR_WORKER then
            output.queuedOrders = output.queuedOrders + 1
        elseif order.status == Status.BLOCKED then
            output.blockedOrders = output.blockedOrders + 1
        elseif not terminal(order) and order.status ~= Status.PAUSED then
            output.activeOrders = output.activeOrders + 1
        end
    end
    for key, value in pairs(Service.ClaimsByStation) do output.stationClaims[key] = value end
    for key, value in pairs(Service.ClaimsByWorker) do output.workerClaims[key] = value end
    return output
end

function Service.BuildActionInformation(record)
    local orderId = record and record.runtime and record.runtime.workOrderId
    local order = orderId and Repository.Get(orderId) or nil
    if not order or terminal(order) then
        if PNC.HomeDutyService
            and PNC.HomeDutyService.IsReturningHome(record)
        then
            local progress = PNC.Travel and PNC.Travel.Service
                and PNC.Travel.Service.GetProgress(record) or nil
            return {
                kind = "return_home",
                state = progress and progress.state or "en_route",
                percent = math.floor(math.max(0, math.min(1,
                    tonumber(progress and progress.percent) or 0)) * 100 + 0.5),
                baseId = record.runtime and record.runtime.homeBaseId or nil,
            }
        end
        if record and record.orderSpec
            and record.orderSpec.kind == "colony_home"
        then
            return { kind = "at_home", baseId = record.orderSpec.baseId }
        end
        return nil
    end
    local required = math.max(1, tonumber(order.requiredWork) or 1)
    local progress = math.max(0, math.min(required,
        tonumber(order.progress) or 0))
    local payload = order.payload or {}
    local blueprint = payload.blueprint or {}
    local buildDescriptor
    if order.operation == "BUILD_OBJECT" and PNC.BuildRecipeCatalog
        and PNC.BuildRecipeCatalog.Get
    then
        buildDescriptor = PNC.BuildRecipeCatalog.Get(
            blueprint.objectInfoName)
    end
    local facilityId = payload.facilityId
    local facility = facilityId and PNC.SettlementRepository
        and PNC.SettlementRepository.GetFacility(facilityId) or nil
    local activityItemFullType
    if order.operation == "PROVISION_PICKUP" then
        activityItemFullType = provisionItemFullType(payload)
    end
    local lumber = order.operation == "LUMBER" and record.runtime
        and record.runtime.lumber or nil
    return {
        kind = "work_order",
        manual = order.manual == true,
        workOrderId = order.id,
        operation = order.operation,
        status = order.status,
        phase = lumber and lumber.phase
            or record.orderSpec and record.orderSpec.phase or nil,
        waitingFor = lumber and lumber.waitingFor or nil,
        waitingReason = lumber and lumber.waitingReason or nil,
        toolDiagnostic = lumber and PNC.Core.DeepCopy(lumber.tool) or nil,
        progress = progress,
        requiredWork = required,
        percent = math.floor((progress / required) * 100 + 0.5),
        facilityId = facilityId,
        facilityDefinitionId = facility and facility.definitionId or nil,
        recipeId = order.recipeId,
        productionSkillId = order.productionSkillId,
        quantity = order.quantity,
        technologyId = payload.technologyId,
        specimenFullType = payload.specimenFullType,
        activityItemFullType = activityItemFullType,
        objectInfoName = blueprint.objectInfoName,
        buildDisplayName = buildDescriptor and buildDescriptor.displayName
            or blueprint.objectInfoName,
    }
end

return Service

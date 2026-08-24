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

function Internal.ConstructionRequirements(order)
    local payload = order and order.payload or {}
    if type(payload.requirements) == "table" then
        return PNC.Core.DeepCopy(payload.requirements)
    end
    local facility = PNC.SettlementRepository.GetFacility(payload.facilityId)
    local definition = facility and PNC.FacilityDefinitions.Get(
        facility.definitionId) or nil
    local change = payload.change or {}
    local kind = payload.materialKind or (order.operation == "CONSTRUCT"
        and "build" or change.action)
    if not definition then return {} end
    local revision = tonumber(order.recipeRevision)
        or tonumber(payload.recipeRevision)
    if kind == "set" or kind == "replace_role" then
        return Internal.RequirementsFromCosts(Internal.ComponentCostsFor(
            facility, payload.materialRole or change.role
                or change.component and change.component.role, revision),
            payload.materialCount or (kind == "replace_role"
                and math.max(1, #(change.anchors or {})) or 1))
    end
    if kind == "upgrade" or kind == "reinforce" or kind == "build" then
        return Internal.RequirementsFromCosts(
            Internal.DefinitionCosts(definition, kind, revision), 1)
    end
    return {}
end

function Internal.CancellationRefund(order)
    if not order or (order.operation ~= "CONSTRUCT"
        and order.operation ~= "RECONSTRUCT")
    then return { percent = 0, products = {} } end
    local payload = order.payload or {}
    local input = payload.input or {}
    -- Reserved or worker-staged inputs have not been consumed. Cancelling the
    -- input transaction releases/returns them directly, so depositing a
    -- percentage here would duplicate materials.
    if input.consume == true and input.committed ~= true then
        return { percent = 100, products = {},
            recipeRevision = tonumber(order.recipeRevision)
                or tonumber(payload.recipeRevision) or 1 }
    end
    if order.operation == "RECONSTRUCT"
        and (payload.change and payload.change.action) == "remove"
    then return { percent = 0, products = {} } end
    local required = math.max(1, tonumber(order.requiredWork) or 1)
    local progress = math.max(0, math.min(required,
        tonumber(order.progress) or 0))
    local remaining = math.max(0, (required - progress) / required)
    local multiplier = PNC.Sandbox
        and PNC.Sandbox.ConstructionCancellationRefundMultiplier
        and PNC.Sandbox.ConstructionCancellationRefundMultiplier() or 1
    local percent = math.max(0, math.min(100,
        math.floor(remaining * multiplier * 100 + 0.5)))
    local products = {}
    for _, cost in ipairs(Internal.ConstructionRequirements(order)) do
        local fullType = cost.fullType or cost.itemTypes and cost.itemTypes[1]
        local quantity = math.floor((tonumber(cost.amount) or 0)
            * remaining * multiplier + 0.000001)
        if fullType and quantity > 0 then
            products[#products + 1] = { fullType = fullType, quantity = quantity }
        end
    end
    return { percent = percent, products = products,
        recipeRevision = tonumber(order.recipeRevision)
            or tonumber(payload.recipeRevision) or 1 }
end

return Service


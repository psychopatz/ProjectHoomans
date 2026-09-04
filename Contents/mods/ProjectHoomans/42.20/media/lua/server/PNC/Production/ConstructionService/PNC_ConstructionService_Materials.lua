if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ConstructionService
local Internal = Service.Internal

function Internal.RequirementsFromCosts(costs, count)
    local output = {}
    count = math.max(1, math.floor(tonumber(count) or 1))
    for _, cost in ipairs(costs or {}) do
        local fullType = cost.fullType or cost.itemType
            or cost.itemTypes and cost.itemTypes[1]
        if fullType and tostring(fullType) ~= "" then
            output[#output + 1] = {
                itemTypes = { tostring(fullType) },
                amount = math.max(1, math.floor(
                    (tonumber(cost.amount or cost.quantity) or 1) * count)),
                consumed = cost.consumed ~= false,
            }
        end
    end
    return output
end

-- A retained recipe input (for example a hammer) is reserved for the
-- project but is not collected into the worker's inventory. Keep the exact
-- type chosen by the reservation available to the activity snapshot so the
-- client can present the same tool instead of guessing from recipe options.
function Internal.ActivityItemFullType(requirements, reservation)
    local reserved = reservation and reservation.requirements or nil
    for index, requirement in ipairs(requirements or {}) do
        if requirement and requirement.consumed == false then
            local selected = reserved and reserved[index]
                and reserved[index].selectedType or nil
            selected = tostring(selected or "")
            if selected ~= "" then return selected end
        end
    end
    return nil
end

function Internal.RecipeRevisionFor(definition, facility, kind)
    local level = PNC.FacilityDefinitions and PNC.FacilityDefinitions.GetLevel
        and PNC.FacilityDefinitions.GetLevel(
            facility and facility.definitionId, facility and facility.level)
        or nil
    local revisions = level and level.recipeRevisions
        or definition and definition.recipeRevisions
    local revision = revisions and revisions[kind]
        or level and level.recipeRevision
        or definition and definition.recipeRevision
    return math.max(1, math.floor(tonumber(revision) or 1))
end

function Internal.DefinitionCosts(definition, kind, requestedRevision)
    if not definition then return {{ fullType = "Base.Money", amount = 1 }} end
    local revisions = definition.recipeRevisions
    local revision = requestedRevision or definition.recipeRevision or 1
    local revised = revisions and revisions[revision]
    if not revised and revisions and type(revisions[kind]) == "table" then
        revised = revisions[kind][revision]
    end
    local costs = revised and revised[kind]
    if not costs then
        costs = kind == "upgrade" and definition.upgradeCosts
            or kind == "reinforce" and definition.reinforceCosts
            or definition.buildCosts or definition.buildCost
    end
    return costs or {{ fullType = "Base.Money", amount = 1 }}
end

function Internal.ComponentCostsFor(facility, role, requestedRevision)
    local definitions = PNC.FacilityDefinitions
    local definition = definitions and definitions.Get
        and definitions.Get(facility and facility.definitionId) or nil
    local level = definitions and definitions.GetLevel
        and definitions.GetLevel(facility and facility.definitionId,
            facility and facility.level) or nil
    local revisions = level and level.recipeRevisions
        or definition and definition.recipeRevisions
    local revised = revisions and revisions[requestedRevision]
    if not revised and revisions and type(revisions.components) == "table" then
        revised = revisions.components[requestedRevision]
    end
    if not revised and revisions and type(revisions.componentCosts) == "table"
        and type(revisions.componentCosts[requestedRevision]) == "table"
    then revised = revisions.componentCosts[requestedRevision] end
    local revisedCosts = revised and (revised.componentCosts
        or revised.components or revised)
    revisedCosts = revisedCosts and revisedCosts[tostring(role or "")]
    if revisedCosts then return revisedCosts end
    return definitions and definitions.GetComponentCosts
        and definitions.GetComponentCosts(facility.definitionId,
            facility.level, role)
        or {{ fullType = "Base.Money", amount = 1 }}
end

function Internal.ComponentBuildWork(facility, role)
    local definitions = PNC.FacilityDefinitions
    if definitions and definitions.GetComponentBuildWork then
        return definitions.GetComponentBuildWork(
            facility.definitionId, facility.level, role)
    end
    return 40
end

function Internal.ContextFor(player, facility)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    if not facility or tostring(context.base.id) ~= tostring(facility.baseId) then
        return nil, "FACILITY_FORBIDDEN"
    end
    return context
end

function Internal.BuildRequirements(definition)
    return Internal.RequirementsFromCosts(definition and
        (definition.buildCosts or definition.buildCost) or {}, 1)
end

return Internal

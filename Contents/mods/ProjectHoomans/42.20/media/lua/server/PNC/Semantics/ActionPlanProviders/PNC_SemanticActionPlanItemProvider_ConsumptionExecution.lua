-- Authoritative EAT, DRINK, and CONSUME execution.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Provider = PNC.Semantics.ActionPlanItemProvider
local Support = Provider.ConsumptionSupport
local Supply = PNC.NPCSupplyService

local function selectionHasCapability(selection, wanted)
    return type(selection) == "table"
        and type(selection.classification) == "table"
        and Support.HasCapability(selection.classification.capabilities, wanted)
end

local function resolve(plan, step, record)
    local selection, reason = Support.Select(record, step)
    Support.Audit("semantic.consumption.resolve", plan, step, {
        status = selection and "resolved" or "failed",
        reason = reason,
        itemID = selection and selection.itemID,
        fullType = selection and selection.fullType,
        capability = Support.Parameters(step).capability,
    })
    return selection, reason
end

local function execute(plan, step, record)
    local assignment = step and step.assignment
    local args = Support.Parameters(step)
    local selection, reason = Support.Select(record, step, assignment)
    local resourceKind = string.upper(tostring(args.resourceKind or "FOOD"))
    local required = math.max(0.001, tonumber(args.required) or 1)
    local ok
    local effect
    if resourceKind ~= "FOOD" and resourceKind ~= "HYDRATION"
        and resourceKind ~= "AUTO"
    then resourceKind = "FOOD" end
    if not selection then
        Support.Audit("semantic.consumption.commit", plan, step, {
            status = "failed", reason = reason, resourceKind = resourceKind,
        })
        return { blocked = true, reason = reason or "item_not_found" }
    end
    if resourceKind == "AUTO" then
        resourceKind = selectionHasCapability(selection, "drinkable")
            and "HYDRATION" or "FOOD"
    end
    if not Supply or type(Supply.ConsumePersonalItem) ~= "function" then
        return { blocked = true, reason = "personal_consumption_unavailable" }
    end
    ok, reason, effect = Supply.ConsumePersonalItem(
        record, selection.itemID, required, resourceKind)
    Support.Audit("semantic.consumption.commit", plan, step, {
        status = ok == true and "completed" or "failed",
        reason = reason, itemID = selection.itemID,
        fullType = selection.fullType, resourceKind = resourceKind,
    })
    if ok ~= true then
        return { blocked = true, reason = reason or "item_consume_failed" }
    end
    return {
        complete = true,
        result = {
            itemID = selection.itemID,
            fullType = selection.fullType,
            resourceKind = resourceKind,
            effect = Support.PrimitiveEffect(effect),
        },
    }
end

Provider.Consume = Provider.Consume or {}
function Provider.Consume.Resolve(plan, step, record)
    return resolve(plan, step, record)
end
function Provider.Consume.Start(plan, step, record)
    return execute(plan, step, record)
end
function Provider.Consume.Tick(plan, step, record)
    return execute(plan, step, record)
end

return Provider.Consume

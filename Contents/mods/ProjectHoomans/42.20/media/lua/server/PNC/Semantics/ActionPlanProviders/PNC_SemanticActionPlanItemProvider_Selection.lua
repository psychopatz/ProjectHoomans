if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Provider = PNC.Semantics.ActionPlanItemProvider
local Selector = Provider.ItemSelector

local function parameters(step)
    return step and type(step.parameters) == "table"
        and step.parameters or {}
end

local function objectOf(step)
    local args = parameters(step)
    return type(args.object) == "table" and args.object or args
end

local function selectorRequest(step)
    local args = parameters(step)
    local object = objectOf(step)
    local request = {
        itemID = object.itemID,
        fullType = object.fullType,
        category = object.category,
        primary = object.primary,
        capabilities = object.capabilities,
        concept = object.concept,
        text = object.text or object.value,
        quantity = object.quantity or args.quantity,
    }
    request.tags = object.tags
    return request
end

Provider.ItemRequest = selectorRequest

function Provider.Selection.Resolve(_, step, record)
    if not Selector or type(Selector.Find) ~= "function" then
        return nil, "item_selector_unavailable"
    end
    return Selector.Find(record, selectorRequest(step), {
        maxItems = 256,
    })
end

function Provider.Selection.Start(_, step)
    if type(step and step.assignment) ~= "table" then
        return { blocked = true, reason = "item_selection_missing" }
    end
    return { complete = true, result = step.assignment }
end

function Provider.Selection.Tick(_, step)
    return Provider.Selection.Start(nil, step)
end

return Provider.Selection

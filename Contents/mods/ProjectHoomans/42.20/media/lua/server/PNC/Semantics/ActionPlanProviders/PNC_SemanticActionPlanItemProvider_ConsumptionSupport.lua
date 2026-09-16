-- Shared, side-effect-free helpers for consumption and refill providers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Provider = PNC.Semantics.ActionPlanItemProvider
local Selector = Provider.ItemSelector
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local Support = Provider.ConsumptionSupport or {}
Provider.ConsumptionSupport = Support

function Support.Parameters(step)
    return step and type(step.parameters) == "table"
        and step.parameters or {}
end

function Support.Object(step)
    local args = Support.Parameters(step)
    return type(args.object) == "table" and args.object or args
end

function Support.HasCapability(value, wanted)
    wanted = string.lower(tostring(wanted or ""))
    if wanted == "" or type(value) ~= "table" then return false end
    if value[wanted] == true or value[string.upper(wanted)] == true then
        return true
    end
    for index = 1, #value do
        if string.lower(tostring(value[index] or "")) == wanted then
            return true
        end
    end
    return false
end

function Support.AddCapability(request, capability)
    capability = string.lower(tostring(capability or ""))
    if capability == "" then return end
    local values = request.capabilities
    if type(values) ~= "table" then
        request.capabilities = { capability }
        return
    end
    if not Support.HasCapability(values, capability) then
        values[#values + 1] = capability
    end
end

local function mergeCapabilities(request, values)
    if type(values) ~= "table" then return end
    for index = 1, #values do
        Support.AddCapability(request, values[index])
    end
    for key, enabled in pairs(values) do
        if type(key) ~= "number" and enabled == true then
            Support.AddCapability(request, key)
        end
    end
end

function Support.SelectorRequest(step)
    local args = Support.Parameters(step)
    local object = Support.Object(step)
    local request = type(Provider.ItemRequest) == "function"
        and Provider.ItemRequest(step) or {}
    local capability = args.capability or args.requiredCapability
    -- Keep both the compact selector filters and the richer contextual
    -- MarketSense capabilities when older callers provide both fields.
    mergeCapabilities(request, object.semanticCapabilities)
    Support.AddCapability(request, capability)
    return request
end

function Support.Select(record, step, assignment)
    if not Selector or type(Selector.Find) ~= "function" then
        return nil, "item_selector_unavailable"
    end
    local request = Support.SelectorRequest(step)
    if type(assignment) == "table" and assignment.itemID then
        request.itemID = tostring(assignment.itemID)
    end
    return Selector.Find(record, request, { maxItems = 256 })
end

function Support.Audit(eventName, plan, step, data)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then return false end
    local payload = {
        planID = plan and plan.planID,
        requestID = plan and plan.requestID,
        npcID = plan and plan.npcID,
        stepID = step and step.id,
        action = step and step.action,
    }
    for key, value in pairs(type(data) == "table" and data or {}) do
        if type(value) ~= "table" and type(value) ~= "function" then
            payload[key] = value
        end
    end
    return Diagnostics.Record(eventName, payload, {
        requestID = plan and plan.requestID,
    })
end

function Support.PrimitiveEffect(effect)
    if type(effect) ~= "table" then return nil end
    return {
        hunger = tonumber(effect.hunger) or 0,
        thirst = tonumber(effect.thirst) or 0,
        calories = tonumber(effect.calories) or 0,
        consumedFraction = tonumber(effect.consumedFraction) or 1,
        fullType = effect.fullType,
    }
end

return Support

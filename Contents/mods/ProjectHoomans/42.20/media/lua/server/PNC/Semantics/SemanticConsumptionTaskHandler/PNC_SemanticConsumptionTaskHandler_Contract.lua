-- Request contract and domain validation for consumption task plans.
-- This spoke does not submit plans or inspect live world state.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Handler = PNC.Semantics.ConsumptionTaskHandler
local Internal = Handler.Internal or {}
Handler.Internal = Internal

Internal.Actions = {
    EAT = true,
    DRINK = true,
    REFILL = true,
    CONSUME = true,
}

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function normalized(value)
    return string.upper(tostring(value or ""))
end

local function safePart(value, fallback)
    local result = text(value) or fallback or "unknown"
    result = string.gsub(result, "[^%w_%.:%-]", "_")
    return string.sub(result, 1, 48)
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    for key, child in pairs(value) do
        if type(key) ~= "function" and type(child) ~= "function" then
            output[key] = copyValue(child, depth + 1)
        end
    end
    return output
end

local function hasCapability(value, wanted)
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

local function objectHasCapability(object, capability)
    return type(object) == "table"
        and (hasCapability(object.capabilities, capability)
            or hasCapability(object.semanticCapabilities, capability))
end

local function npcIDFor(request, context)
    context = type(context) == "table" and context or {}
    local recipient = request and request.recipient
    local actor = request and request.actor
    return text(context.npcID or context.targetID
        or recipient and (recipient.id or recipient.entityID)
        or actor and actor.id)
end

local function requestIDFor(request, npcID)
    local requestID = text(request and request.requestID)
    if requestID then return requestID end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    return "generated:" .. tostring(npcID) .. ":" .. tostring(now)
end

local function objectFor(request, action)
    local input = request and request.object
    local object
    local capability = action == "DRINK" and "drinkable"
        or action == "REFILL" and "refillable"
        or action == "CONSUME" and "consumable"
        or "edible"
    if input ~= nil and type(input) ~= "table" then
        return nil, "item_invalid"
    end
    object = copyValue(type(input) == "table" and input or {})
    -- A failed discourse reference is not permission to choose an arbitrary
    -- item. Only an omitted object from a bare action is implicit.
    if object.reference and object.implicit ~= true then
        return nil, "item_reference_unresolved"
    end
    -- Carry the action constraint into the queued selection step even when
    -- the object came from a literal phrase or contextual MarketSense data.
    object.capabilities = type(object.capabilities) == "table"
        and object.capabilities or {}
    if not hasCapability(object.capabilities, capability) then
        object.capabilities[#object.capabilities + 1] = capability
    end
    return object, nil, capability
end

local function resourceKindFor(action, object)
    if action == "DRINK" then return "HYDRATION" end
    if action == "EAT" then return "FOOD" end
    if action == "CONSUME"
        and (objectHasCapability(object, "drinkable")
            or normalized(object and (object.concept or object.category))
                == "WATER")
    then
        return "HYDRATION"
    end
    -- CONSUME is intentionally open-ended. The provider uses the selected
    -- item's authoritative MarketSense capabilities to choose the lane.
    if action == "CONSUME" then return "AUTO" end
    return "FOOD"
end

local function requiredFor(request)
    local modifiers = request and request.modifiers or {}
    local extensions = request and request.extensions or {}
    local value = modifiers.required or modifiers.amount
        or extensions and (extensions.required or extensions.amount)
    value = tonumber(value)
    if value == nil then return 1 end
    return math.max(0.001, math.min(100, value))
end

Internal.Text = text
Internal.Normalized = normalized
Internal.SafePart = safePart
Internal.CopyValue = copyValue
Internal.NPCIDFor = npcIDFor
Internal.RequestIDFor = requestIDFor
Internal.ObjectFor = objectFor
Internal.ResourceKindFor = resourceKindFor
Internal.RequiredFor = requiredFor

return Handler

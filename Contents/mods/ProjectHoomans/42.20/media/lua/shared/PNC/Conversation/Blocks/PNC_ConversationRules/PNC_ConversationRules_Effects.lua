local Rules = PNC.Conversation.Rules
local Registry = PNC.Conversation.Registry

local function validateEffect(handler, context, effect)
    local called
    local valid
    local reason
    if handler.builtin == true then
        return handler.validate(context, effect)
    end
    called, valid, reason = pcall(handler.validate, context, effect)
    if not called then return false, "effect_handler_error" end
    return valid, reason
end

function Rules.ValidateEffects(effects, context)
    local effect
    local handler
    local valid
    local reason
    for _, effect in ipairs(effects or {}) do
        handler = Registry.effectHandlers[effect.type]
        if not handler then return false, "unknown_effect" end
        valid, reason = validateEffect(handler, context, effect)
        if valid ~= true then
            return false, reason or "effect_rejected"
        end
    end
    return true
end

local function applyEffect(handler, context, effect)
    local called
    local applied
    local reason
    local result
    if handler.builtin == true then
        return handler.apply(context, effect)
    end
    called, applied, reason, result =
        pcall(handler.apply, context, effect)
    if not called then return false, "effect_handler_error" end
    return applied, reason, result
end

function Rules.ApplyEffects(effects, context)
    local results = {}
    local effect
    local handler
    local applied
    local reason
    local result
    for _, effect in ipairs(effects or {}) do
        handler = Registry.effectHandlers[effect.type]
        applied, reason, result = applyEffect(handler, context, effect)
        if applied ~= true then
            return false, reason or "effect_failed", result
        end
        results[#results + 1] = {
            type = effect.type,
            result = result,
        }
    end
    return true, "applied", results
end

local function simulateEffect(handler, context, effect)
    local ok
    local result
    if handler.builtin == true then
        return handler.simulate(context or {}, effect)
    end
    ok, result = pcall(handler.simulate, context or {}, effect)
    if not ok then return { error = "effect_handler_error" } end
    return result
end

function Rules.SimulateEffects(effects, context)
    local output = {}
    local effect
    local handler
    for _, effect in ipairs(effects or {}) do
        handler = Registry.effectHandlers[effect.type]
        if handler and handler.simulate then
            output[#output + 1] = simulateEffect(
                handler,
                context,
                effect
            )
        end
    end
    return output
end

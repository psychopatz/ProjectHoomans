if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Server = PNC.Server or {}
PNC.Server.Internal = PNC.Server.Internal or {}

local H = PNC.Server.Internal

H.SafePhaseDiagnostics = H.SafePhaseDiagnostics or {
    totalFailures = 0,
    byStage = {},
    recentFailures = {},
}

local function describeContext(context)
    if type(context) ~= "table" then
        return tostring(context or "")
    end
    local parts = {}
    if context.npcId ~= nil then
        parts[#parts + 1] = "npc=" .. tostring(context.npcId)
    end
    if context.ruleId ~= nil then
        parts[#parts + 1] = "rule=" .. tostring(context.ruleId)
    end
    if context.orderId ~= nil then
        parts[#parts + 1] = "order=" .. tostring(context.orderId)
    end
    if context.leaseId ~= nil then
        parts[#parts + 1] = "lease=" .. tostring(context.leaseId)
    end
    return table.concat(parts, " ")
end

local function logFailure(stage, context, message)
    local text = "server phase failed stage=" .. tostring(stage or "unknown")
        .. " context=" .. describeContext(context)
        .. " error=" .. tostring(message or "unknown")
    if PNC.Core and PNC.Core.LogWarn then
        local ok = pcall(PNC.Core.LogWarn, text)
        if ok then return end
    end
    print("[PNC][WARN] " .. text)
end

-- A server phase failure is isolated and recorded so later phases and NPCs
-- can still receive their update. This is deliberately small and synchronous:
-- it is a containment boundary, not a second scheduler.
function H.SafePhase(stage, callback, context, ...)
    local diagnostics = H.SafePhaseDiagnostics
    if type(callback) ~= "function" then
        diagnostics.totalFailures = diagnostics.totalFailures + 1
        local key = tostring(stage or "unknown")
        diagnostics.byStage[key] = (diagnostics.byStage[key] or 0) + 1
        local failure = {
            stage = key,
            context = describeContext(context),
            error = "CALLBACK_UNAVAILABLE",
        }
        diagnostics.lastFailure = failure
        diagnostics.recentFailures[#diagnostics.recentFailures + 1] = failure
        while #diagnostics.recentFailures > 32 do
            table.remove(diagnostics.recentFailures, 1)
        end
        logFailure(stage, context, "CALLBACK_UNAVAILABLE")
        return false, nil, "CALLBACK_UNAVAILABLE"
    end

    local ok, first, second, third, fourth = pcall(callback, ...)
    if not ok then
        diagnostics.totalFailures = diagnostics.totalFailures + 1
        local key = tostring(stage or "unknown")
        diagnostics.byStage[key] = (diagnostics.byStage[key] or 0) + 1
        local failure = {
            stage = key,
            context = describeContext(context),
            error = tostring(first),
        }
        diagnostics.lastFailure = failure
        diagnostics.recentFailures[#diagnostics.recentFailures + 1] = failure
        while #diagnostics.recentFailures > 32 do
            table.remove(diagnostics.recentFailures, 1)
        end
        logFailure(stage, context, first)
        return false, nil, tostring(first)
    end
    return true, first, second, third, fourth
end

return H

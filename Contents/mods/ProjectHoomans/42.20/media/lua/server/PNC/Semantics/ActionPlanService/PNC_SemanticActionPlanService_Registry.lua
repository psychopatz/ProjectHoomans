-- Provider registry and bounded active-plan indexes.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Plan = PNC.Semantics.ActionPlan
    or require "PNC/Semantics/PNC_SemanticActionPlan"
local Service = PNC.Semantics.ActionPlanService or {}
PNC.Semantics.ActionPlanService = Service

Service.VERSION = 1
Service.Providers = Service.Providers or {}
Service.ByNPC = Service.ByNPC or {}
Service.ByID = Service.ByID or {}
-- Runtime-only context is intentionally separate from the persisted plan.
-- It may contain a live player/Java object, but it must never cross the
-- persistence or network boundary.
Service.RuntimeByID = Service.RuntimeByID or {}
Service.Active = Service.Active or {}
Service.ActiveIndex = Service.ActiveIndex or {}
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}
Service.Internal = Service.Internal or {}
Service.MAX_ACTIVE_PLANS_PER_PUMP = 16
Service.PUMP_INTERVAL_MS = 250
Service.RECONCILE_INTERVAL_MS = 5000
Service.NextPumpAt = Service.NextPumpAt or 0
Service.NextReconcileAt = Service.NextReconcileAt or 0
Service.ActiveCursor = Service.ActiveCursor or 0

local function key(value)
    return tostring(value or "")
end

local function action(value)
    value = string.upper(key(value))
    return string.gsub(value, "[%s%-]+", "_")
end

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function terminal(plan)
    return plan and (plan.state == "COMPLETED"
        or plan.state == "FAILED" or plan.state == "CANCELLED")
end

local function runtimeContext(context)
    if type(context) ~= "table" then return nil end

    local output = {}
    if context.player ~= nil then output.player = context.player end
    if context.body ~= nil then output.body = context.body end

    local token = context.conversationToken or context.token
    if token ~= nil and tostring(token) ~= "" then
        output.conversationToken = string.sub(tostring(token), 1, 128)
    end

    local scope = context.scope
    if scope ~= nil and tostring(scope) ~= "" then
        output.scope = string.sub(tostring(scope), 1, 32)
    end

    local playerContainer = context.playerContainer
    if playerContainer ~= nil and tostring(playerContainer) ~= "" then
        output.playerContainer = string.sub(tostring(playerContainer), 1, 64)
    end

    if output.player == nil and output.body == nil
        and output.conversationToken == nil
    then
        return nil
    end
    return output
end

function Service.SetRuntimeContext(planID, context)
    local id = key(planID)
    local runtime
    if id == "" then return false, "plan_id_required" end
    runtime = runtimeContext(context)
    if not runtime then
        Service.RuntimeByID[id] = nil
        return false, "runtime_context_empty"
    end
    Service.RuntimeByID[id] = runtime
    return true, runtime
end

function Service.GetRuntimeContext(planID)
    return Service.RuntimeByID[key(planID)]
end

function Service.ClearRuntimeContext(planID)
    local id = key(planID)
    if id == "" or not Service.RuntimeByID[id] then return false end
    Service.RuntimeByID[id] = nil
    return true
end

local function emit(eventType, plan, cause, extra)
    local events = PNC.Tasking and PNC.Tasking.Events
    if not events or type(events.Emit) ~= "function" then return end
    local payload = {
        planID = plan.planID,
        stepID = plan.steps[plan.currentStep]
            and plan.steps[plan.currentStep].id or nil,
        state = plan.state,
        currentStep = plan.currentStep,
        cause = cause,
    }
    for field, value in pairs(type(extra) == "table" and extra or {}) do
        payload[field] = value
    end
    events.Emit(eventType, {
        npcId = plan.npcID,
        entityId = plan.planID,
        source = "SemanticActionPlanService",
        payload = payload,
    }, { enqueue = false })
end

local function markDirty(plan)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(plan.npcID) or nil
    if record and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "semantic_action_plan")
    end
    return record
end

local function removeActive(planID)
    local index = Service.ActiveIndex[planID]
    if not index then
        for cursor = #Service.Active, 1, -1 do
            if Service.Active[cursor] == planID then index = cursor; break end
        end
    end
    if not index then return false end
    local last = #Service.Active
    local moved = Service.Active[last]
    if index ~= last then
        Service.Active[index] = moved
        Service.ActiveIndex[moved] = index
    end
    Service.Active[last] = nil
    Service.ActiveIndex[planID] = nil
    return true
end

local function addActive(plan)
    if terminal(plan) or Service.ActiveIndex[plan.planID] then return end
    Service.Active[#Service.Active + 1] = plan.planID
    Service.ActiveIndex[plan.planID] = #Service.Active
end

local function replaceIndexes(plan, previous)
    if previous and previous.planID ~= plan.planID then
        Service.ByID[previous.planID] = nil
        removeActive(previous.planID)
        Service.ClearRuntimeContext(previous.planID)
    end
    Service.ByNPC[plan.npcID] = plan
    Service.ByID[plan.planID] = plan
    addActive(plan)
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return false, nil, "callback_unavailable"
    end
    local ok, first, second, third = pcall(callback, ...)
    if not ok then return false, nil, tostring(first) end
    return true, first, second, third
end

function Service.RegisterProvider(actionID, provider)
    actionID = action(actionID)
    if actionID == "" or type(provider) ~= "table"
        or type(provider.Resolve) ~= "function"
        or type(provider.Start) ~= "function"
        or type(provider.Tick) ~= "function"
    then
        return false, "invalid_action_plan_provider"
    end
    if Service.Providers[actionID] then
        return false, "action_plan_provider_already_registered"
    end
    Service.Providers[actionID] = provider
    return true, provider
end

function Service.UnregisterProvider(actionID)
    actionID = action(actionID)
    if not Service.Providers[actionID] then return false end
    Service.Providers[actionID] = nil
    return true
end

function Service.GetProvider(actionID)
    return Service.Providers[action(actionID)]
end

Service.Internal.Plan = Plan
Service.Internal.Key = key
Service.Internal.Now = now
Service.Internal.Terminal = terminal
Service.Internal.AddActive = addActive
Service.Internal.RemoveActive = removeActive
Service.Internal.MarkDirty = markDirty
Service.Internal.Emit = emit
Service.Internal.SafeCall = safeCall
Service.Internal.ReplaceIndexes = replaceIndexes
Service.Internal.RuntimeContext = runtimeContext

return Service

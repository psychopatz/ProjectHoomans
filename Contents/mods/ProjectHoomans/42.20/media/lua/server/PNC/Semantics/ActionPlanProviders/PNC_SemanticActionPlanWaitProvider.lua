-- Deterministic dwell/guard step for semantic action plans.
-- It deliberately does not create a second behavior scheduler: ownership is
-- held by ActionPlanService while the existing behavior coordinator yields.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.ActionPlanService
local Provider = {}
local DEFAULT_DURATION_MS = 30000
local MAX_DURATION_MS = 86400000

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function boundedDuration(value)
    value = tonumber(value)
    if value == nil then return DEFAULT_DURATION_MS end
    return math.max(0, math.min(MAX_DURATION_MS, math.floor(value)))
end

local function clearOwnership(record)
    if record then
        record.activeJob = nil
        record.activeBehavior = nil
    end
end

function Provider.Resolve(_, step, record)
    if not record or record.alive == false then
        return nil, "npc_unavailable"
    end
    local parameters = step and type(step.parameters) == "table"
        and step.parameters or {}
    return {
        durationMs = boundedDuration(parameters.durationMs
            or parameters.duration),
    }
end

function Provider.Start(_, step, record)
    local assignment = step and step.assignment
    if type(assignment) ~= "table" then
        return { blocked = true, reason = "wait_assignment_missing" }
    end
    assignment.startedAt = now()
    record.activeJob = "SemanticActionPlan"
    record.activeBehavior = "SemanticActionPlan:WAIT"
    return { state = "WAITING" }
end

function Provider.Tick(_, step, record)
    local assignment = step and step.assignment
    local startedAt
    local duration
    if type(assignment) ~= "table" then
        return { blocked = true, reason = "wait_assignment_missing" }
    end
    startedAt = tonumber(assignment.startedAt)
    if not startedAt then
        assignment.startedAt = now()
        startedAt = assignment.startedAt
    end
    duration = boundedDuration(assignment.durationMs)
    if now() - startedAt >= duration then
        clearOwnership(record)
        return { complete = true, result = {
            durationMs = duration,
        } }
    end
    record.activeJob = "SemanticActionPlan"
    record.activeBehavior = "SemanticActionPlan:WAIT"
    return { state = "WAITING" }
end

function Provider.Cancel(_, _, record)
    clearOwnership(record)
    return true
end

if Service and type(Service.RegisterProvider) == "function" then
    Service.RegisterProvider("WAIT", Provider)
end

return Provider

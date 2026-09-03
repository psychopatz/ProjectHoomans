if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskPriority = PNC.TaskPriority or {}

local Priority = PNC.TaskPriority
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
Priority.ORDER = { "HARD_EMERGENCY", "CRITICAL_NEED", "FORCED_ORDER",
    "NORMAL_NEED", "HIGH_WORK", "NORMAL_WORK", "OPTIONAL", "IDLE" }
Priority.RANK = Priority.RANK or {}
for index, band in ipairs(Priority.ORDER) do
    Priority.RANK[band] = #Priority.ORDER - index + 1
end
Priority.SAME_BAND_MARGIN = 0.08
Priority.NON_INTERRUPTIBLE = { ATOMIC_COMMIT = true, COMPLETING = true }

local function band(value)
    return Priority.RANK[tostring(value or "")] or 0
end

local function score(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function workPriority(value)
    if value == nil then return nil end
    return WorkPolicy.NormalizePriority(value)
end

function Priority.Compare(first, second)
    local firstBand, secondBand = band(first and first.precedence),
        band(second and second.precedence)
    if firstBand ~= secondBand then return firstBand > secondBand and 1 or -1 end
    local firstWork, secondWork = workPriority(first and first.workPriority),
        workPriority(second and second.workPriority)
    if firstWork ~= nil and secondWork ~= nil and firstWork ~= secondWork then
        return firstWork < secondWork and 1 or -1
    end
    local firstScore = score(first and (first.urgency or first.score))
    local secondScore = score(second and (second.urgency or second.score))
    if firstScore ~= secondScore then return firstScore > secondScore and 1 or -1 end
    local firstAge = tonumber(first and first.createdAt) or math.huge
    local secondAge = tonumber(second and second.createdAt) or math.huge
    if firstAge ~= secondAge then return firstAge < secondAge and 1 or -1 end
    local firstId, secondId = tostring(first and first.taskId or ""),
        tostring(second and second.taskId or "")
    if firstId == secondId then return 0 end
    return firstId < secondId and 1 or -1
end

function Priority.CanPreempt(current, challenger)
    if not current then return true, "NO_CURRENT_TASK" end
    if Priority.NON_INTERRUPTIBLE[tostring(current.phase or "")] then
        return false, "CURRENT_TASK_ATOMIC"
    end
    local currentBand = band(current.precedence)
    local challengerBand = band(challenger and challenger.precedence)
    if challengerBand > currentBand then return true, "HIGHER_PRECEDENCE" end
    if challengerBand < currentBand then return false, "LOWER_PRECEDENCE" end
    local currentWork = workPriority(current.workPriority)
    local challengerWork = workPriority(challenger and challenger.workPriority)
    if currentWork ~= nil and challengerWork ~= nil
        and challengerWork ~= currentWork
    then
        return challengerWork < currentWork, challengerWork < currentWork
            and "HIGHER_WORK_PRIORITY" or "LOWER_WORK_PRIORITY"
    end
    local improvement = score(challenger and (challenger.urgency
        or challenger.score)) - score(current.urgency or current.score)
    if improvement >= Priority.SAME_BAND_MARGIN then
        return true, "SAME_BAND_MARGIN"
    end
    return false, "CURRENT_TASK_STICKY"
end

return Priority

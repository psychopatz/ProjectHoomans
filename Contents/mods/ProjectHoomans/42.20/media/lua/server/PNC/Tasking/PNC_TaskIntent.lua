if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskIntent = PNC.TaskIntent or {}

local Intent = PNC.TaskIntent
local Policy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
local REQUIRED = { "taskId", "npcId", "kind", "sourceDomain",
    "sourceRef", "precedence", "capability" }

function Intent.Normalize(candidate)
    if type(candidate) ~= "table" then return nil, "INVALID_TASK_INTENT" end
    local output = {}
    for _, key in ipairs(REQUIRED) do
        local value = tostring(candidate[key] or "")
        if value == "" then return nil, "TASK_INTENT_" .. string.upper(key) end
        output[key] = value
    end
    if not PNC.TaskPriority.RANK[output.precedence] then
        return nil, "INVALID_PRECEDENCE"
    end
    output.urgency = math.max(0, math.min(1,
        tonumber(candidate.urgency or candidate.score) or 0))
    if candidate.workPriority ~= nil then
        output.workPriority = math.max(Policy.MIN_PRIORITY,
            math.min(Policy.MAX_PRIORITY,
                math.floor(tonumber(candidate.workPriority)
                    or Policy.DEFAULT_PRIORITY)))
    end
    output.interruptPolicy = tostring(candidate.interruptPolicy or "NORMAL")
    output.revision = math.max(1, math.floor(tonumber(candidate.revision) or 1))
    output.createdAt = tonumber(candidate.createdAt) or PNC.Core.Now()
    return output
end

return Intent

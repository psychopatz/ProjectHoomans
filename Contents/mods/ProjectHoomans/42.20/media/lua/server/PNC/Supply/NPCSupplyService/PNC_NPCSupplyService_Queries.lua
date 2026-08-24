-- NPC supply retry and diagnostic queries.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}
local Service = PNC.NPCSupplyService
local Internal = Service.Internal
local runtime = Internal.Runtime
local worldHour = Internal.WorldHour

function Service.ClearRetry(record, kind)
    if not record then return false end
    local state = runtime(record, string.upper(tostring(kind or "FOOD")))
    state.nextRetry = 0
    return true
end

function Service.GetDebugState(record)
    local root = record and record.runtime and record.runtime.supply or nil
    return root and PNC.Core.DeepCopy(root) or { byKind = {} }
end

function Service.HasRecentNeedRequest(record, kind, withinHours)
    local root = record and record.runtime and record.runtime.supply
    local state = root and root.byKind
        and root.byKind[string.upper(tostring(kind or ""))] or nil
    local request = state and state.request or nil
    if not request or request.purpose ~= "NEED" then return false end
    return worldHour() - (tonumber(state.lastAttemptAt) or -math.huge)
        <= math.max(0, tonumber(withinHours) or 0)
end

return Service

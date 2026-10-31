-- Traversal/presence handoff helpers kept separate from core presence policy.

local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function withinDistance(nearest, distance)
    distance = tonumber(distance) or 0
    if not nearest or not nearest.distSq then return false end
    return nearest.distSq <= (distance * distance)
end

-- One bounded audit helper is shared by presence, body, and pathing modules.
-- It performs no body reads or string assembly while the channel is disabled.
function Presence.LogTraversal(record, eventName, body, extra)
    local navigation
    local fields
    if not Diagnostics
        or not Diagnostics.IsPresenceTraversalAuditEnabled
        or Diagnostics.IsPresenceTraversalAuditEnabled() ~= true
        or not Diagnostics.LogPresenceTraversal
    then
        return false
    end
    navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    fields = {
        "npc=" .. tostring(record and record.id or "nil"),
        "name=" .. tostring(record and record.name or "nil"),
        "presence=" .. tostring(record and record.presenceState or "nil"),
        "bodyLease=" .. tostring(record and record.runtime
            and record.runtime.bodyLease or "nil"),
        "presenceRevision=" .. tostring(record
            and record.presenceRevision or "nil"),
        "recordPos=" .. tostring(record and record.x or "nil") .. ","
            .. tostring(record and record.y or "nil") .. ","
            .. tostring(record and record.z or "nil"),
        "nearestDistSq=" .. tostring(record and record.runtime
            and record.runtime.nearestPlayerDistSq or "nil"),
        "provider=" .. tostring(navigation and navigation.provider or "nil"),
        "owner=" .. tostring(navigation and navigation.ownerMode or "nil"),
        "nativeActive=" .. tostring(navigation
            and navigation.nativeActive == true),
        "requestRevision=" .. tostring(navigation
            and navigation.requestRevision or "nil"),
        "at=" .. tostring(Core and Core.Now and Core.Now() or 0),
    }
    if body then
        fields[#fields + 1] = "bodyPos=" .. tostring(body.getX
            and body:getX() or "nil") .. "," .. tostring(body.getY
            and body:getY() or "nil") .. "," .. tostring(body.getZ
            and body:getZ() or "nil")
        fields[#fields + 1] = "action=" .. tostring(body.getActionStateName
            and body:getActionStateName() or "nil")
        fields[#fields + 1] = "path2=" .. tostring(body.getPath2
            and body:getPath2() ~= nil or false)
        fields[#fields + 1] = "moving=" .. tostring(body.isMoving
            and body:isMoving() == true or false)
    end
    for _, field in ipairs(extra or {}) do
        fields[#fields + 1] = tostring(field)
    end
    return Diagnostics.LogPresenceTraversal(eventName, fields)
end

function Presence.RequestTraversalHandoff(record, reason)
    local nearest
    local runtime
    local now
    if not record or record.presenceState ~= Const.PRESENCE_LIVE then
        return false
    end
    nearest = Internal.FindNearestPlayer and Internal.FindNearestPlayer(record)
        or nil
    if nearest and withinDistance(nearest, Const.MATERIALIZE_DISTANCE) then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    if runtime.presenceHandoffRequested == true then return false end
    now = Core and Core.Now and Core.Now() or 0
    runtime.presenceHandoffRequested = true
    runtime.presenceHandoffReason = tostring(reason or "movement_stall")
    runtime.presenceHandoffAt = now
    runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", now)
    end
    Presence.LogTraversal(record, "handoff_requested", nil, {
        "reason=" .. tostring(reason or "movement_stall"),
    })
    return true
end

function Presence.ClearTraversalHandoff(record, reason)
    local runtime = record and record.runtime or nil
    if not runtime or runtime.presenceHandoffRequested ~= true then
        return false
    end
    runtime.presenceHandoffRequested = nil
    runtime.presenceHandoffReason = nil
    runtime.presenceHandoffAt = nil
    runtime.presenceHandoffClearReason = reason
    return true
end

return Presence

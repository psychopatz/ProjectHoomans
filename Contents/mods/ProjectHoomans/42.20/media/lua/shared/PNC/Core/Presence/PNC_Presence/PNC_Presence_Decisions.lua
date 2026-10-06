local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon
local Diagnostics = PNC.PerformanceScalingDiagnostics

-- A live journey that the embodied movement lane cannot serve asks for the
-- elapsed-time abstract lane instead. Resolved lazily so Presence keeps no
-- load-order dependency on Travel.
local function travelHandoffRequired(record)
    local journey = record and record.travel
    local model
    if not journey then return false end
    model = PNC.Travel and PNC.Travel.Model
    if not model or type(model.LiveHandoffRequired) ~= "function" then
        return false
    end
    return model.LiveHandoffRequired(journey) == true
end

local function withinDistance(nearest, distance)
    distance = tonumber(distance) or 0
    if not nearest or not nearest.distSq then return false end
    return nearest.distSq <= (distance * distance)
end

-- One bounded audit helper is shared by presence, body, and pathing modules.
-- It performs no body reads or string assembly while the channel is disabled.
function Internal.LogTraversal(record, eventName, body, extra)
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
        -- Keep a visible NPC embodied. The live watchdog will continue its
        -- bounded local fallback and expose the blocked state to the player.
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    if runtime.presenceHandoffRequested == true then return false end
    now = Core and Core.Now and Core.Now() or 0
    runtime.presenceHandoffRequested = true
    runtime.presenceHandoffReason = tostring(
        reason or "movement_stall"
    )
    runtime.presenceHandoffAt = now
    runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", now)
    end
    Internal.LogTraversal(record, "handoff_requested", nil, {
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

function Presence.ShouldMaterialize(record, nearest)
    nearest = nearest or Internal.FindNearestPlayer(record)
    if record.alive == false
        or record.presenceState == Const.PRESENCE_CORPSE
    then
        return false
    end
    if record.runtime and record.runtime.forceAbstract then return false end
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.IsStartupBodyCleanupComplete
        and not PNC.BodyLifecycle.IsStartupBodyCleanupComplete()
    then
        return false
    end
    -- Vehicle passengers intentionally have no IsoZombie body until exit.
    if record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        return false
    end
    if record.runtime
        and Core.Now() < (tonumber(record.runtime.materializeRetryAt) or 0)
    then
        return false
    end
    if record.runtime and record.runtime.presenceHandoffRequested == true
        and not withinDistance(nearest, Const.MATERIALIZE_DISTANCE)
    then
        return false
    end
    if record.runtime and record.runtime.forceLive then
        if travelHandoffRequired(record)
            and not withinDistance(nearest, Const.MATERIALIZE_DISTANCE)
        then
            -- A forced-live record keeps its body while a player can see it.
            -- With nobody near, a journey that cannot be walked stays on the
            -- abstract lane instead of thrashing the body every presence pass.
            return false
        end
        return true
    end
    if travelHandoffRequired(record)
        and not withinDistance(nearest, Const.MATERIALIZE_DISTANCE)
    then
        return false
    end
    return nearest and nearest.distSq
        <= (Const.MATERIALIZE_DISTANCE * Const.MATERIALIZE_DISTANCE)
        or false
end

function Presence.ShouldAbstract(record, nearest)
    local handoff
    nearest = nearest or Internal.FindNearestPlayer(record)
    if record.presenceState ~= Const.PRESENCE_LIVE then return false end
    -- A shell that already left the loaded world cannot be kept or recovered.
    -- Presence must release the lease before forceLive/target exceptions can
    -- hold a record paired with a body that no longer exists; otherwise the
    -- engine's anonymous population copy becomes a permanent husk.
    if PNC.BodyLifecycle and PNC.BodyLifecycle.IsRecordBodyLost
        and PNC.BodyLifecycle.IsRecordBodyLost(record) == true
    then
        return true
    end
    if record.runtime and record.runtime.presenceHandoffRequested == true
        and not withinDistance(nearest, Const.MATERIALIZE_DISTANCE)
    then
        return true
    end
    handoff = travelHandoffRequired(record)
    -- forceLive keeps an NPC embodied for gameplay, but it must not bind it to
    -- a movement lane that cannot serve its journey.
    if record.runtime and record.runtime.forceLive and not handoff then
        return false
    end
    if record.runtime and record.runtime.forceAbstract then return true end
    if record.runtime and record.runtime.target
        and not (Common
            and Common.IsActiveFollowCombatTarget
            and Common.IsActiveFollowCombatTarget(record, Core.Now()))
    then
        return false
    end
    if handoff then
        -- Keep the body while a player is close enough to see it; hand the
        -- journey to the abstract lane beyond that.
        return (not nearest) or nearest.distSq
            >= (Const.MATERIALIZE_DISTANCE * Const.MATERIALIZE_DISTANCE)
    end
    return (not nearest) or nearest.distSq
        >= (Const.ABSTRACT_DISTANCE * Const.ABSTRACT_DISTANCE)
end

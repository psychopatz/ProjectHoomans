local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const

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
    if record.runtime and record.runtime.forceLive then return true end
    return nearest and nearest.distSq
        <= (Const.MATERIALIZE_DISTANCE * Const.MATERIALIZE_DISTANCE)
        or false
end

function Presence.ShouldAbstract(record, nearest)
    nearest = nearest or Internal.FindNearestPlayer(record)
    if record.presenceState ~= Const.PRESENCE_LIVE then return false end
    if record.runtime and record.runtime.forceLive then return false end
    if record.runtime and record.runtime.forceAbstract then return true end
    if record.runtime and record.runtime.target then return false end
    return (not nearest) or nearest.distSq
        >= (Const.ABSTRACT_DISTANCE * Const.ABSTRACT_DISTANCE)
end

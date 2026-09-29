local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon

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

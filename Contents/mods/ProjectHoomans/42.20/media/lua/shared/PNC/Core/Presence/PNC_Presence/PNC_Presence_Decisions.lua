local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon

if not Presence.IsOutsideLiveBodyEnvelope then
    require "PNC/Core/Presence/PNC_Presence/PNC_Presence_LiveBodySafety"
end
if not Presence.RequestTraversalHandoff then
    require "PNC/Core/Presence/PNC_Presence/PNC_Presence_TraversalHandoff"
end

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
    local runtime
    local explicitLiveRequest
    nearest = nearest or Internal.FindNearestPlayer(record)
    if record.alive == false
        or record.presenceState == Const.PRESENCE_CORPSE
    then
        return false, "dead_or_corpse"
    end
    runtime = record.runtime or {}
    -- A vehicle passenger is intentionally bodyless. This guard must remain
    -- before every force-live override: disembarking and follow handoffs may
    -- request a body, but a passenger must stay represented by the vehicle
    -- reservation until the vehicle service releases it.
    if runtime.vehiclePassenger
        and runtime.vehiclePassenger.active == true
    then
        return false, "vehicle_passenger"
    end
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.IsStartupBodyCleanupComplete
        and not PNC.BodyLifecycle.IsStartupBodyCleanupComplete()
    then
        return false, "startup_gate"
    end
    if Core.Now() < (tonumber(runtime.materializeRetryAt) or 0)
    then
        return false, "retry_backoff"
    end
    explicitLiveRequest = runtime.forceLive == true
        or runtime.abstractFollowMaterializeRequested == true
    -- `abstract` is the normal unloaded state. The legacy forceAbstract flag
    -- was also written by directors for initial placement, so treating it as
    -- a permanent proximity veto strands those NPCs forever. Only an explicit
    -- hardAbstract lock may block normal range-enter materialization. The
    -- vehicle-passenger guard above deliberately remains absolute.
    if runtime.hardAbstract == true and not explicitLiveRequest then
        return false, "hard_abstract"
    end
    if runtime.presenceHandoffRequested == true
        and not withinDistance(nearest, Const.MATERIALIZE_DISTANCE)
    then
        return false, "presence_handoff_out_of_range"
    end
    if runtime.forceLive == true then
        -- forceLive is an embodiment preference, not permission to create an
        -- IsoZombie in unloaded world space. Abstract followers, debug spawns,
        -- incapacitation and director requests all have to wait until a player
        -- owns the materialization radius.
        if not withinDistance(nearest, Const.MATERIALIZE_DISTANCE) then
            return false, travelHandoffRequired(record)
                and "travel_handoff_out_of_range"
                or "explicit_live_out_of_range"
        end
        return true, "explicit_live"
    end
    if travelHandoffRequired(record)
        and not withinDistance(nearest, Const.MATERIALIZE_DISTANCE)
    then
        return false, "travel_handoff_out_of_range"
    end
    if nearest and nearest.distSq
        <= (Const.MATERIALIZE_DISTANCE * Const.MATERIALIZE_DISTANCE)
    then
        return true, "within_materialize_distance"
    end
    return false, "outside_materialize_distance"
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
    -- This hard fence must run before forceLive and target exceptions. Those
    -- flags used to keep companions/hostiles embodied hundreds of tiles behind
    -- all players; PZ then virtualized the carrier during chunk unload and the
    -- old body later resurfaced as an ordinary zombie husk.
    if Presence.IsOutsideLiveBodyEnvelope(record, nearest) then
        return true
    end
    handoff = travelHandoffRequired(record)
    -- forceLive keeps an NPC embodied only inside the safe live envelope.
    if record.runtime and record.runtime.forceLive and not handoff then
        return false
    end
    if record.runtime and record.runtime.hardAbstract then return true end
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

-- Durable restart proof captured when a live carrier is detached.
--
-- This module owns the transition from ephemeral live-body identity into the
-- compact persistence hint used by restart/late-stream reconciliation.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Internal = PNC.BodyLifecycle.Internal
local Const = PNC.Const

function Internal.CaptureDetachedBodyHint(record)
    local runtime
    local previous
    local instanceID
    local populationID
    local onlineID
    local lease
    local x
    local y
    local z
    local wasLive

    if not record then return nil end

    runtime = record.runtime or {}
    record.runtime = runtime
    previous = runtime.startupBodyHint
    wasLive = record.alive ~= false
        and record.presenceState == Const.PRESENCE_LIVE

    instanceID = record.liveBodyInstanceID
        or runtime.lastLiveBodyInstanceID
        or previous and previous.instanceID or nil
    populationID = record.liveBodyPopulationID
        or runtime.lastLiveBodyPopulationID
        or previous and previous.populationId or nil
    onlineID = record.liveBodyOnlineID
        or runtime.lastLiveBodyOnlineID
        or previous and previous.onlineID or nil
    lease = runtime.bodyLease
        or runtime.lastLiveBodyLease
        or previous and previous.lease or nil
    x = record.x
    y = record.y
    z = record.z
    if x == nil and previous then x = previous.x end
    if y == nil and previous then y = previous.y end
    if z == nil and previous then z = previous.z end

    runtime.lastLiveBodyInstanceID = instanceID
    runtime.lastLiveBodyPopulationID = populationID
    runtime.lastLiveBodyOnlineID = onlineID
    runtime.lastLiveBodyLease = lease
    runtime.lastLiveBodyX = x
    runtime.lastLiveBodyY = y
    runtime.lastLiveBodyZ = z

    if instanceID ~= nil or populationID ~= nil
        or wasLive == true
    then
        runtime.startupBodyHint = {
            instanceID = instanceID,
            onlineID = onlineID,
            lease = lease,
            populationId = populationID,
            x = x,
            y = y,
            z = z,
            -- Lifecycle admission proof only. Actual anonymous adoption still
            -- requires the stricter uniqueness/radius/sex reconciliation.
            wasLive = wasLive == true,
        }
    elseif previous and previous.wasLive == true then
        -- Corpse/death detaches must not inherit an older live-restart flag.
        previous.wasLive = false
    end

    return runtime.startupBodyHint
end

return Internal

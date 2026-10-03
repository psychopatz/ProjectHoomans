-- Puppet Opera ownership heartbeat for provider reservations.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Override = PNC.PuppetOpera.Override or {}

local Override = PNC.PuppetOpera.Override
local Internal = Override.Internal or {}
local OVERRIDE_KEY = Internal.OverrideKey

-- Provider behavior is paused while an Opera session owns the actor. Its
-- reservations still need an owner-scoped heartbeat so they do not expire.
function Override.Maintain(session, actor, at)
    local record = actor and actor.record or nil
    local runtime = record and record.runtime or nil
    local state = runtime and runtime[OVERRIDE_KEY] or nil
    local timestamp = tonumber(at) or Internal.Now()
    local reservations
    local ids
    local id
    local renewed
    local details
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_override_arguments_invalid"
    end
    if not state
        or tostring(state.sessionId or "")
            ~= tostring(session.sessionId or "")
    then
        return false, "npc_override_not_owned"
    end
    if timestamp < (tonumber(state.nextReservationRenewAt) or 0) then
        return true
    end

    state.lastHeartbeatAt = timestamp
    state.nextReservationRenewAt = timestamp + Internal.OwnerHeartbeatMS
    reservations = PNC.FacilityReservations
    if not reservations or not reservations.Start then return true end
    ids = Internal.CollectReservationIDs(record)
    for id in pairs(ids) do
        renewed, details = reservations.Start(
            id,
            Internal.OwnerReservationTTLMS
        )
        if renewed ~= true then
            state.reservationLost = true
            state.reservationLostID = id
            state.reservationLostReason = tostring(details or "renew_failed")
            return false, "puppet_opera_reservation_lost:" .. id
        end
    end
    state.lastReservationRenewAt = timestamp
    state.reservationLost = nil
    state.reservationLostID = nil
    state.reservationLostReason = nil
    return true
end

return Override

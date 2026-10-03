if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.AmbientVisitService
if not Service then return end
local Internal = Service.Internal or {}
local number = Internal.number
local worldHours = Internal.worldHours
local mobileShelterKey = Internal.mobileShelterKey
local leaseFor = Internal.leaseFor
local MobileSites = Internal.MobileSites
local Const = Internal.Const

-- Convert the already-selected mobile shelter target into one semantic room
-- lease after the actor reaches it. This is deliberately called from the
-- arrival edge, never from the world scheduler, so room discovery is paid
-- once per target and the result is shared by the group.
function Service.TryStartMobileShelter(record, zombie, order, at)
    local runtime
    local state
    local key
    local current
    local site
    local reason
    local started
    if type(order) ~= "table"
        or tostring(order.kind or "") ~= tostring(Const.ORDER_ROAM or "roam")
        or tostring(order.roamMode or "") ~= "shelter"
        or order.ambientMobile ~= true
        or tostring(order.ambientObjective or "") ~= "shelter"
    then
        return false, "not_mobile_shelter_order"
    end
    current = worldHours(at)
    if Service.IsActive(record, current) then
        return true, "mobile_shelter_active"
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    key = mobileShelterKey(order)
    state = runtime.ambientMobileShelter or {}
    if state.key ~= key then
        state = { key = key }
        runtime.ambientMobileShelter = state
    end
    if current < number(state.retryAt, 0) then
        return false, state.reason or "mobile_shelter_retry_deferred"
    end
    site, reason = MobileSites.resolve(record, zombie, order, current)
    if not site then
        state.reason = reason or "mobile_shelter_room_missing"
        state.retryAt = current + Service.MOBILE_SHELTER_RETRY_HOURS
        state.lastAttemptAt = current
        return false, state.reason
    end
    started, reason = Service.Begin(record, site, {
        authorized = true,
        accessClass = "ai_faction_ambient",
        purpose = "mobile_night_shelter",
        sourceID = key,
        durationHours = Service.MOBILE_SHELTER_DURATION_HOURS,
        at = current,
        roamModes = { shelter = true },
    })
    if not started then
        state.reason = reason or "mobile_shelter_lease_failed"
        state.retryAt = current + Service.MOBILE_SHELTER_RETRY_HOURS
        state.lastAttemptAt = current
        return false, state.reason
    end
    runtime.ambientMobileShelter = nil
    return true, reason or "mobile_shelter_started"
end

function Service.ReleaseMobileShelter(recordOrID, reason, at)
    local lease = leaseFor(recordOrID)
    if not lease or lease.purpose ~= "mobile_night_shelter" then
        return false, "mobile_shelter_missing"
    end
    return Service.Release(recordOrID,
        reason or "mobile_shelter_released", at)
end

return Service

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.AmbientVisitService
if not Service then return end
local Internal = Service.Internal or {}
local number = Internal.number
local worldHours = Internal.worldHours
local leaseFor = Internal.leaseFor
local orderIsLease = Internal.orderIsLease
local liveBody = Internal.liveBody
local blockedRuntime = Internal.blockedRuntime
local isAuthority = Internal.isAuthority
local Const = Internal.Const

function Service.Get(recordOrID)
    local lease = leaseFor(recordOrID)
    return lease
end

function Service.IsActive(recordOrID, at)
    local lease = leaseFor(recordOrID)
    if not lease or lease.status ~= "active" then return false end
    return number(lease.expiresAt, 0) > worldHours(at)
end

function Service.IsOrderProtected(record, at)
    local lease = leaseFor(record)
    return Service.IsActive(record, at) and orderIsLease(record, lease)
end

function Service.CanUseAmbient(record, at)
    local lease = leaseFor(record)
    return Service.IsActive(record, at)
        and lease.noNeeds == true
        and lease.noItemEffects == true
end

function Service.IsEligible(record, options)
    local order
    local mode
    local actorControl
    options = type(options) == "table" and options or {}
    if not isAuthority() then return false, "not_authority" end
    if not record or record.alive == false then
        return false, "record_invalid" end
    if record.presenceState
        and tostring(record.presenceState)
            ~= tostring(Const.PRESENCE_LIVE or "live")
        and options.allowAbstract ~= true
    then
        return false, "visitor_not_live" end
    if options.requireMaterialized ~= false and not liveBody(record) then
        return false, "visitor_not_materialized" end
    order = record.orderSpec or {}
    if tostring(order.kind or "") ~= tostring(Const.ORDER_ROAM or "roam") then
        return false, "visitor_order_not_roam" end
    mode = tostring(order.roamMode or "area")
    if options.roamModes and not options.roamModes[mode] then
        return false, "visitor_roam_mode_not_allowed" end
    if record.recruited == true or record.ownerUsername ~= nil
        or record.ownerOnlineID ~= nil or record.colonyOwned == true
    then
        return false, "visitor_player_owned" end
    if record.hostility and (
        record.hostility.attackPlayers == true
            or record.hostility.attackNPCs == true)
    then
        return false, "visitor_hostile" end
    actorControl = PNC.ActorControl
    if actorControl and actorControl.IsPuppetOwned
        and actorControl.IsPuppetOwned(record)
    then
        return false, "visitor_actor_owned" end
    if blockedRuntime(record) then return false, "visitor_busy" end
    return true, "eligible"
end

return Service

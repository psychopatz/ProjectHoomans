if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.AmbientVisitService
if not Service then return end
local Internal = Service.Internal or {}
local number = Internal.number
local text = Internal.text
local worldHours = Internal.worldHours
local primitiveCopy = Internal.primitiveCopy
local activeCount = Internal.activeCount
local leaseFor = Internal.leaseFor
local orderIsLease = Internal.orderIsLease
local liveBody = Internal.liveBody
local notify = Internal.notify
local setOrder = Internal.setOrder
local Const = Internal.Const

function Service.Release(recordOrID, reason, at)
    local lease
    local record
    local id
    local body
    local current
    local ownsOrder
    local restored = false
    lease, record = leaseFor(recordOrID)
    if not lease then return false, "ambient_visit_missing" end
    id = tostring(lease.npcID or "")
    if not record and PNC.Registry and PNC.Registry.Get then
        record = PNC.Registry.Get(id)
    end
    body = record and liveBody(record) or nil
    if record and record.runtime and record.runtime.roamAmbient
        and PNC.RoamAmbient and PNC.RoamAmbient.Stop
    then
        pcall(PNC.RoamAmbient.Stop, record, body,
            reason or "ambient_visit_released", "movement")
    end
    current = record and record.orderSpec or nil
    ownsOrder = orderIsLease(record, lease)
    if record and record.runtime then record.runtime.ambientVisit = nil end
    if record and ownsOrder then
        if lease.previousOrder then
            restored = setOrder(record, primitiveCopy(lease.previousOrder))
        else
            restored = setOrder(record, {
                kind = Const.ORDER_GUARD or "guard",
                x = current and current.x or record.x,
                y = current and current.y or record.y,
                z = current and current.z or record.z,
            })
        end
    end
    lease.status = "released"
    lease.releasedAt = worldHours(at)
    lease.releaseReason = text(reason, "ambient_visit_released", 64)
    Service.Runtime.leases[lease.id] = nil
    if Service.Runtime.byNPC[id] == lease.id then
        Service.Runtime.byNPC[id] = nil
    end
    if record then notify(record, "ambient_visit_released") end
    return true, restored and "ambient_visit_released"
        or "ambient_visit_released_order_changed"
end

function Service.Pump(at, budget)
    local expired = {}
    local processed = 0
    local current = worldHours(at)
    budget = math.max(1, math.floor(number(budget, Service.PUMP_BUDGET)))
    for leaseID, lease in pairs(Service.Runtime.leases) do
        if processed >= budget then break end
        if lease and lease.status == "active" then
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(lease.npcID) or nil
            local hostile = record and record.hostility
                and (record.hostility.attackPlayers == true
                    or record.hostility.attackNPCs == true)
            local invalid = not record or record.alive == false
                or hostile or not orderIsLease(record, lease)
            if current >= number(lease.expiresAt, math.huge)
                or invalid
            then
                expired[#expired + 1] = {
                    id = leaseID,
                    reason = current >= number(lease.expiresAt, math.huge)
                        and "ambient_visit_expired"
                        or "ambient_visit_invalidated",
                }
            end
            processed = processed + 1
        end
    end
    for index = 1, #expired do
        Service.Release(expired[index].id, expired[index].reason, current)
    end
    return #expired
end

function Service.ActiveCount()
    return activeCount()
end

return Service

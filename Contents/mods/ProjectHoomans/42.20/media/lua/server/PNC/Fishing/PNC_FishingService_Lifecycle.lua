-- Fishing lease start, restoration, and cancellation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local Const = PNC.Const or {}
local H = Service.Internal

function Service.StartJob(lease)
    local job = Service.GetJob(lease and lease.npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = job and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(job.npcId) or nil
    if not job or not zone or not record then return false, "fishing_npc_not_found" end
    if not Service.ValidateZone(zone) then return false, "fishing_zone_invalid" end
    if not Service.IsNearby(record, zone) then return false, "fishing_npc_not_nearby" end
    local spot, spotReason = H.ReserveFishingSpot(zone, job, record)
    if not spot then return false, spotReason end
    if job.previousOrderCaptured ~= true then
        local current = type(record.orderSpec) == "table" and record.orderSpec or nil
        if current and tostring(current.kind or "") == tostring(Const.ORDER_FISHING or "fishing")
            and tostring(current.fishingJobId or "") == tostring(job.id)
        then job.previousOrder = nil
        else job.previousOrder = H.Copy(current) end
        job.previousOrderCaptured = true
    end
    Service.Runtime.previousOrders[job.npcId] = H.Copy(job.previousOrder)
    job.leaseId, job.executionMode = lease.leaseId, tostring(lease.executionMode or "ABSTRACT")
    job.lastProgressAt = H.Now()
    job.state, job.phase = "READY", "WAITING"
    job.revision = (tonumber(job.revision) or 0) + 1
    H.UpdateFishingRuntime(record, job, zone, "WAITING")
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_FISHING or "fishing", fishingJobId = job.id,
            zoneId = zone.id, spotId = job.spotId,
            standX = spot.standX, standY = spot.standY, standZ = spot.standZ,
            waterX = spot.waterX, waterY = spot.waterY, waterZ = spot.waterZ,
        })
    end
    H.MarkDirty()
    return true
end

function Service.RestoreOrder(npcId)
    npcId = tostring(npcId or "")
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    local job = Service.GetJob(npcId)
    local previous = Service.Runtime.previousOrders[npcId]
    if previous == nil and job and job.previousOrderCaptured == true then previous = job.previousOrder end
    local current = record and type(record.orderSpec) == "table" and record.orderSpec or nil
    local owns = current and tostring(current.kind or "") == tostring(Const.ORDER_FISHING or "fishing")
        and job and tostring(current.fishingJobId or "") == tostring(job.id)
    if record and owns and PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, previous)
    end
    Service.Runtime.previousOrders[npcId] = nil
    if job then job.previousOrder, job.previousOrderCaptured = nil, nil end
    if record and record.runtime then record.runtime.fishing = nil end
end

function Service.CancelJob(npcId, reason)
    local job = Service.GetJob(npcId)
    if not job then return true end
    local zone = Service.GetZone(job.zoneId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    if record and body and record.runtime and record.runtime.animationScene
        and record.runtime.animationScene.id == "fishing.cast"
        and PNC.AnimationScenes and PNC.AnimationScenes.Stop
    then pcall(PNC.AnimationScenes.Stop, record, body, reason or "fishing_stopped") end
    H.ReleaseFishingSpot(job, zone)
    if zone then zone.workers[tostring(npcId)] = nil end
    job.active, job.leaseId = false, nil
    job.state, job.phase = "CANCELLED", tostring(reason or "cancelled")
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.RestoreOrder(npcId)
    H.MarkDirty()
    return true
end

return Service

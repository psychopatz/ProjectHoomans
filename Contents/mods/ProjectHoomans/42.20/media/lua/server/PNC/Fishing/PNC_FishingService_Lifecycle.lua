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
    local executionMode = tostring(lease and lease.executionMode or "ABSTRACT")
    local live = executionMode == "LIVE"
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(job and job.npcId) or nil
    local nearby
    if not job or not zone or not record then return false, "fishing_npc_not_found" end
    if PNC.HomeDutyService and PNC.HomeDutyService.IsCamped
        and PNC.HomeDutyService.IsCamped(record) == true
    then return false, "NPC_CAMPED" end
    if not Service.ValidateZone(zone) then return false, "fishing_zone_invalid" end
    -- Set this before reserving so abstract jobs do not consume an exclusive
    -- live stand claim during the initial lease handoff.
    job.leaseId, job.executionMode = lease.leaseId, executionMode
    local tool = H.ResolveFishingTool(record, job.activityItemID)
    local spot, spotReason = H.ReserveFishingSpot(zone, job, record)
    if not spot then return false, spotReason end
    job.activityItemID = tool.itemID
    job.activityItemFullType = tool.fullType
    job.toolReady = tool.ready == true
    job.toolReason = tool.reason
    job.recordPrimaryID = tool.recordPrimaryID
    job.recordPrimary = tool.recordPrimary
    job.nativePrimary = tool.nativePrimary
    nearby = tool.ready and Service.IsNearby(record, zone, nil, spot, body)
        or false
    if job.previousOrderCaptured ~= true then
        local current = type(record.orderSpec) == "table" and record.orderSpec or nil
        if current and tostring(current.kind or "") == tostring(Const.ORDER_FISHING or "fishing")
            and tostring(current.fishingJobId or "") == tostring(job.id)
        then job.previousOrder = nil
        else job.previousOrder = H.Copy(current) end
        job.previousOrderCaptured = true
    end
    Service.Runtime.previousOrders[job.npcId] = H.Copy(job.previousOrder)
    job.lastProgressAt = H.Now()
    job.state = "READY"
    job.lastReason = "fishing_tool_check"
    if not tool.ready then
        -- TOOL_CHECK is observable and deliberately carries no work
        -- progress. The specific tool reason remains in toolReason.
        job.state, job.phase = "READY", "TOOL_CHECK"
        job.lastReason = tool.reason or "fishing_tool_missing"
        job.lastFailureReason = job.lastReason
    elseif live and not nearby then
        job.state, job.phase = "READY", "TRAVEL"
        job.lastReason = "traveling"
    else
        -- A valid abstract worker can check its tool and begin simulation on
        -- the next execution tick without requiring a loaded body/chunk.
        job.state, job.phase = "READY", "TOOL_CHECK"
    end
    job.revision = (tonumber(job.revision) or 0) + 1
    H.UpdateFishingRuntime(record, job, zone, job.phase)
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_FISHING or "fishing", fishingJobId = job.id,
            zoneId = zone.id, spotId = job.spotId,
            standX = spot.standX, standY = spot.standY, standZ = spot.standZ,
            waterX = spot.waterX, waterY = spot.waterY, waterZ = spot.waterZ,
        })
    end
    H.MarkDirty()
    if Service.FishingDiagnostics
        and Service.FishingDiagnostics.RecordTransition
    then
        Service.FishingDiagnostics.RecordTransition(record, job, body,
            job.lastReason or job.phase, {
                event = "start", phase = job.phase,
                toolID = job.activityItemID,
                tool = job.activityItemFullType,
                recordPrimary = job.recordPrimary,
                nativePrimary = job.nativePrimary,
                handReady = tool.ready,
                handReason = tool.reason,
                claim = "reserved",
            })
    end
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
    then PNC.AnimationScenes.Stop(record, body, reason or "fishing_stopped") end
    H.ReleaseFishingSpot(job, zone)
    if zone then zone.workers[tostring(npcId)] = nil end
    job.active, job.leaseId = false, nil
    job.state, job.phase = "CANCELLED", tostring(reason or "cancelled")
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.RestoreOrder(npcId)
    H.MarkDirty()
    if Service.FishingDiagnostics
        and Service.FishingDiagnostics.RecordTransition
    then
        Service.FishingDiagnostics.RecordTransition(record, job, body,
            reason or "cancelled", { event = "cancel" })
    end
    return true
end

return Service

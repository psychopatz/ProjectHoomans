-- Lumber job lifecycle, order restoration, and travel-to-zone guidance.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local Const = Internal.Const
local copy = Internal.Copy
local now = Internal.Now
local markDirty = Internal.MarkDirty
local zoneBounds = Internal.ZoneBounds

function Service.CancelWorkOrder(npcId, reason)
    local job = Service.GetJob(npcId)
    local adapter = PNC.LumberWorkAdapter
    if not job or not job.workOrderId or not adapter
        or not adapter.CancelOrder
    then return false end
    return adapter.CancelOrder(job, reason or "lumber_job_cancelled")
end

function Service.ValidateJob(npcId, jobId)
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    return job ~= nil and tostring(job.id) == tostring(jobId or "")
        and job.active == true and zone ~= nil and zone.enabled == true
        and zone.workers[tostring(npcId)] == true
end

function Service.StartJob(lease)
    local job = Service.GetJob(lease and lease.npcId)
    local record = job and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(job.npcId) or nil
    if not job or not record then return false, "npc_not_found" end
    local currentOrder = type(record.orderSpec) == "table"
        and record.orderSpec or nil
    local currentKind = currentOrder and tostring(currentOrder.kind or "") or ""
    if job.previousOrderCaptured ~= true then
        if currentKind == tostring(Const.ORDER_LUMBER or "lumber")
            and tostring(currentOrder.lumberJobId or "") == tostring(job.id)
        then
            -- A resumed job may already have its lumber order persisted on
            -- the NPC record. Do not mistake that order for the order we
            -- must restore.
            job.previousOrder = nil
        else
            job.previousOrder = copy(currentOrder)
        end
        job.previousOrderCaptured = true
    end
    Service.Runtime.previousOrders[job.npcId] = copy(job.previousOrder)
    job.leaseId = lease.leaseId
    job.executionMode = tostring(lease.executionMode or "ABSTRACT")
    job.state, job.phase = "READY", "WAITING"
    job.revision = (tonumber(job.revision) or 0) + 1
    record.runtime = record.runtime or {}
    record.runtime.lumberJobId = job.id
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_LUMBER or "lumber",
            lumberJobId = job.id, zoneId = job.zoneId,
        })
    end
    markDirty()
    return true
end

function Service.RestoreOrder(npcId)
    npcId = tostring(npcId or "")
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local job = Service.GetJob(npcId)
    local previous = Service.Runtime.previousOrders[npcId]
    if previous == nil and job and job.previousOrderCaptured == true then
        previous = job.previousOrder
    end
    local current = record and type(record.orderSpec) == "table"
        and record.orderSpec or nil
    local ownsCurrentOrder = current
        and tostring(current.kind or "")
            == tostring(Const.ORDER_LUMBER or "lumber")
        and job
        and tostring(current.lumberJobId or "") == tostring(job.id)
    if record and ownsCurrentOrder and PNC.OrderSystem
        and PNC.OrderSystem.SetOrder
    then
        -- SetOrder(nil) is supported and normalizes to the NPC's guard order.
        PNC.OrderSystem.SetOrder(record, previous)
    end
    Service.Runtime.previousOrders[npcId] = nil
    if job then
        job.previousOrder = nil
        job.previousOrderCaptured = nil
        markDirty()
    end
    if record and record.runtime then
        record.runtime.lumberJobId = nil
        record.runtime.lumber = nil
    end
end

function Service.CancelJob(npcId, reason)
    local job = Service.GetJob(npcId)
    if not job then return true end
    if job.workOrderId and PNC.LumberWorkAdapter
        and PNC.LumberWorkAdapter.CancelOrder
    then
        PNC.LumberWorkAdapter.CancelOrder(job, reason or "job_cancelled")
    end
    Service.ReleaseTree(job.targetKey, reason or "job_cancelled")
    job.targetKey = nil
    job.leaseId = nil
    job.active = false
    job.state, job.phase = "CANCELLED", "CANCELLED"
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.RestoreOrder(npcId)
    markDirty()
    return true
end

local function updateRuntime(record, job, tree)
    record.runtime = record.runtime or {}
    record.runtime.lumber = {
        jobId = job.id, zoneId = job.zoneId,
        treeKey = tree and tree.key or job.targetKey,
        treeX = tree and tree.x or nil, treeY = tree and tree.y or nil,
        treeZ = tree and tree.z or nil,
        approachX = job.approach and job.approach.x or nil,
        approachY = job.approach and job.approach.y or nil,
        approachZ = job.approach and job.approach.z or nil,
        phase = job.phase, state = job.state,
        activityItemFullType = job.activityItemFullType,
        remainingWork = tree and tree.remainingWork or nil,
        maxWork = tree and tree.maxWork or nil,
    }
end

local function zoneCenter(zone)
    local bounds = zoneBounds(zone)
    if not bounds then return nil end
    return {
        x = (bounds.minX + bounds.maxX) / 2 + 0.5,
        y = (bounds.minY + bounds.maxY) / 2 + 0.5,
        z = (bounds.minZ + bounds.maxZ) / 2,
    }
end

local function guideToZone(job, zone, record, body)
    local center = zoneCenter(zone)
    if not center then return false, "zone_center_missing" end
    if body then
        local bx = body.getX and body:getX() or record.x
        local by = body.getY and body:getY() or record.y
        local bz = body.getZ and body:getZ() or record.z
        local distance = math.abs((tonumber(bx) or 0) - center.x)
            + math.abs((tonumber(by) or 0) - center.y)
        if distance > 2
            or math.abs((tonumber(bz) or 0) - center.z) > 0.6
        then
            job.state, job.phase = "TRAVELING", "TRAVEL"
            if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
                PNC.BehaviorCommon.MoveRecord(record, body,
                    center.x, center.y, center.z, "walk", 0.7,
                    "lumber_zone")
            end
            updateRuntime(record, job, nil)
            return true, "traveling_to_zone"
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(record, body, "lumber_zone")
        end
        job.state, job.phase = "DISCOVERING", "DISCOVERING"
        updateRuntime(record, job, nil)
        return true, "at_zone"
    end

    if job.zoneArrived == true then
        job.state, job.phase = "DISCOVERING", "DISCOVERING"
        updateRuntime(record, job, nil)
        return true, "at_zone"
    end

    local travel = PNC.Travel and PNC.Travel.Service
    local journey = travel and travel.Get and travel.Get(record) or nil
    if job.zoneTravelId and journey
        and tostring(journey.journeyId) == tostring(job.zoneTravelId)
    then
        if journey.state == "arrived" then
            job.zoneArrived = true
            job.zoneTravelId = nil
            if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
                PNC.OrderSystem.SetOrder(record, {
                    kind = Const.ORDER_LUMBER or "lumber",
                    lumberJobId = job.id, zoneId = job.zoneId,
                })
            end
        else
            job.state, job.phase = "TRAVELING", "TRAVEL"
            updateRuntime(record, job, nil)
            return true, "traveling_to_zone"
        end
    elseif travel and type(travel.Start) == "function" then
        local started = travel.Start(record, {
            destination = center, routeProvider = "direct",
            speedProfile = "walk", visibility = "all", arrivalAction = false,
            ownerMod = "ProjectHoomans", ownerRef = "lumber_zone",
            metadata = { lumberZoneId = tostring(zone.id) },
        })
        if started then
            job.zoneTravelId = started.journeyId
            job.state, job.phase = "TRAVELING", "TRAVEL"
            updateRuntime(record, job, nil)
            return true, "traveling_to_zone"
        end
    end
    job.state, job.phase = "DISCOVERING", "DISCOVERING"
    updateRuntime(record, job, nil)
    return true, "at_zone"
end


Internal.UpdateRuntime = updateRuntime
Internal.GuideToZone = guideToZone

return Service

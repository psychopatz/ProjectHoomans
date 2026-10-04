-- Fishing fatigue, inventory delivery, and work-point attempts.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local Fishing = PNC.Fishing
local Const = PNC.Const or {}
local H = Service.Internal

local function isTired(record)
    local fatigue
    if PNC.IndividualNeeds and PNC.IndividualNeeds.Get then
        fatigue = tonumber(PNC.IndividualNeeds.Get(record, "fatigue"))
    end
    fatigue = fatigue or tonumber(record and record.fatigue)
    return fatigue ~= nil and fatigue >= (tonumber(Const.FISHING_FATIGUE_STOP) or 0.70)
end

local function canAccept(record, spec)
    if not PNC.Inventory or type(PNC.Inventory.CanAccept) ~= "function" then return true end
    local accepted, reason = PNC.Inventory.CanAccept(record, { spec }, "root")
    return accepted == true, reason or "fishing_inventory_full"
end

local function addCatch(record, spec)
    if not PNC.Inventory or type(PNC.Inventory.AddItems) ~= "function" then
        return false, "fishing_inventory_unavailable"
    end
    local added, reason = PNC.Inventory.AddItems(record, { spec },
        "root", "fishing_catch")
    return added == true, reason or "fishing_inventory_full"
end

local function distanceToSpot(record, body, spot)
    if not spot then return 9999 end
    local x = body and body.getX and body:getX() or record and record.x
    local y = body and body.getY and body:getY() or record and record.y
    local dx = (tonumber(x) or 0) - (tonumber(spot.standX) or 0)
    local dy = (tonumber(y) or 0) - (tonumber(spot.standY) or 0)
    return math.sqrt((dx * dx) + (dy * dy))
end

function Service.TickJob(lease)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local live = tostring(lease and lease.executionMode
        or job and job.executionMode or "ABSTRACT") == "LIVE"
    local body = live and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    local function finish(ok, complete, reason, details)
        if Service.FishingDiagnostics
            and Service.FishingDiagnostics.RecordTransition
        then
            Service.FishingDiagnostics.RecordTransition(record, job, body,
                reason, details)
        end
        return ok, complete, reason
    end
    if not job or not zone or not record or job.active ~= true then
        return false, false, "fishing_job_unavailable"
    end
    if not Service.ValidateZone(zone) then
        return finish(false, false, "fishing_zone_invalid")
    end
    if isTired(record) then
        return finish(false, false, "fishing_npc_tired")
    end

    local tool = H.ResolveFishingTool(record, job.activityItemID)
    local ensureReason
    if not tool.ready and PNC.WorkItemService
        and type(PNC.WorkItemService.Ensure) == "function"
    then
        local ensured, reason, report = PNC.WorkItemService.Ensure(
            record, "FISHING", body, {
                owner = "work:FISHING", priority = "WORK",
                applyHands = body ~= nil,
                forceHeld = body ~= nil,
            })
        ensureReason = reason
        if report and report.selected then
            job.activityItemID = report.selected.itemID
            job.activityItemFullType = report.selected.fullType
        end
        if ensured or report then
            tool = H.ResolveFishingTool(record, job.activityItemID)
        end
    end
    job.activityItemID = tool.itemID or job.activityItemID
    job.activityItemFullType = tool.fullType
    job.toolReady = tool.ready == true
    job.toolReason = tool.reason or ensureReason
    job.recordPrimaryID = tool.recordPrimaryID
    job.recordPrimary = tool.recordPrimary
    job.nativePrimary = tool.nativePrimary
    if not tool.ready then
        job.state, job.phase = "READY", "TOOL_CHECK"
        job.lastReason = job.toolReason or "fishing_tool_missing"
        job.lastFailureReason = job.lastReason
        job.lastProgressAt = H.Now()
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        return finish(true, false, job.lastReason, {
            event = "tool_wait", toolID = job.activityItemID,
            tool = job.activityItemFullType,
            recordPrimary = job.recordPrimary,
            nativePrimary = job.nativePrimary,
            handReady = tool.ready, handReason = tool.reason,
        })
    end
    if not H.RenewFishingSpot(job, zone) then
        local reclaimed = H.ReserveFishingSpot(zone, job, record)
        if not reclaimed then
            job.state, job.phase = "WAITING", "WAITING_FOR_SPOT"
            job.lastReason = "fishing_spot_unavailable"
            job.lastFailureReason = job.lastReason
            job.lastProgressAt = H.Now()
            H.UpdateFishingRuntime(record, job, zone, job.phase)
            H.MarkDirty()
            return finish(true, false, job.lastReason, { event = "spot_wait" })
        end
    end
    local at = H.Now()
    if live and not Service.IsNearby(record, zone, nil, job.spot, body) then
        local distance = distanceToSpot(record, body, job.spot)
        local travel = job.travel or {}
        if tostring(travel.spotId or "") ~= tostring(job.spotId or "") then
            travel.spotId = job.spotId
            travel.lastDistance = distance
            travel.lastProgressAt = at
        elseif not travel.lastDistance
            or distance < tonumber(travel.lastDistance) - 0.15
        then
            travel.lastProgressAt = at
        end
        travel.lastDistance = distance
        job.travel = travel
        if at - (tonumber(travel.lastProgressAt) or at) >= 12000 then
            local failedSpot = tostring(job.spotId or "")
            job.failedSpots = job.failedSpots or {}
            job.failedSpots[failedSpot] = true
            if H.ReleaseFishingSpot then H.ReleaseFishingSpot(job, zone) end
            local replacement = H.ReserveFishingSpot(zone, job, record)
            if replacement and tostring(replacement.id) ~= failedSpot then
                job.state, job.phase = "READY", "TRAVEL"
                job.lastReason = "fishing_spot_rerouted"
                job.travel = nil
                job.lastProgressAt = at
                H.UpdateFishingRuntime(record, job, zone, job.phase)
                H.MarkDirty()
                return finish(true, false, job.lastReason, {
                    event = "travel_reroute", distance = distance,
                })
            end
            job.state, job.phase = "WAITING", "WAITING_FOR_SPOT"
            job.lastReason = "fishing_spot_unreachable"
            job.lastFailureReason = job.lastReason
            job.lastProgressAt = at
            H.UpdateFishingRuntime(record, job, zone, job.phase)
            H.MarkDirty()
            return finish(true, false, job.lastReason, {
                event = "travel_stalled", distance = distance,
            })
        end
        job.state, job.phase = "READY", "TRAVEL"
        job.lastReason = "traveling"
        job.lastProgressAt = at
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        return finish(true, false, "traveling", {
            event = "travel", toolID = job.activityItemID,
            tool = job.activityItemFullType,
            recordPrimary = job.recordPrimary,
            nativePrimary = job.nativePrimary,
            distance = distance,
        })
    end

    job.travel = nil
    job.failedSpots = nil

    -- The previous live phase can remain TRAVEL after the body enters the
    -- interaction radius. Promote it before the shared behavior evaluates
    -- its scene gate; otherwise the NPC halts at the shoreline forever while
    -- the nameplate reports a zero-progress waiting state.
    local enteredWorking = job.phase ~= "WORKING"
    local wasOutputWaiting = job.phase == "WAITING_FOR_OUTPUT"
    if enteredWorking then
        job.state, job.phase = "WORKING", "WORKING"
        job.lastReason = "fishing_work_started"
        -- A live arrival and an output wait are hard progress boundaries.
        -- Never award elapsed time spent travelling or blocked on storage.
        if live or wasOutputWaiting then job.lastProgressAt = at end
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        if live and Service.FishingDiagnostics
            and Service.FishingDiagnostics.RecordTransition
        then
            Service.FishingDiagnostics.RecordTransition(record, job, body,
                job.lastReason, {
                    event = "work_start",
                    distance = distanceToSpot(record, body, job.spot),
                    toolID = job.activityItemID,
                    tool = job.activityItemFullType,
                    recordPrimary = job.recordPrimary,
                    nativePrimary = job.nativePrimary,
                    handReady = job.toolReady,
                })
        end
    end

    local preview = Fishing.SelectLoot(record, zone, (job.attemptIndex or 0) + 1)
    if preview and not canAccept(record, preview) then
        job.state, job.phase = "WAITING", "WAITING_FOR_OUTPUT"
        job.lastReason = "fishing_inventory_full"
        job.lastFailureReason = job.lastReason
        job.lastProgressAt = H.Now()
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        return finish(true, false, "fishing_inventory_full", {
            event = "output_wait" })
    end

    local elapsed = math.max(0, math.min(Service.MAX_ELAPSED_MS,
        at - (tonumber(job.lastProgressAt) or at)))
    job.lastProgressAt = at
    local required = Fishing.RequiredWorkPoints(zone)
    job.requiredWorkPoints = required
    job.workPoints = math.max(0, tonumber(job.workPoints) or 0)
        + (elapsed / 1000) * Fishing.WorkPointsPerSecond(zone)
    local attempts = 0
    while job.workPoints >= required and attempts < 4 do
        job.workPoints = job.workPoints - required
        job.attemptIndex = (tonumber(job.attemptIndex) or 0) + 1
        job.state, job.phase = "WORKING", "ATTEMPT"
        job.lastReason = "fishing_attempt"
        H.UpdateFishingRuntime(record, job, zone, job.phase)
        H.MarkDirty()
        if Service.FishingDiagnostics
            and Service.FishingDiagnostics.RecordTransition
        then
            Service.FishingDiagnostics.RecordTransition(record, job, body,
                job.lastReason, {
                    event = "attempt_start",
                    toolID = job.activityItemID,
                    tool = job.activityItemFullType,
                    recordPrimary = job.recordPrimary,
                    nativePrimary = job.nativePrimary,
                    handReady = job.toolReady,
                    distance = distanceToSpot(record, body, job.spot),
                })
        end
        job.lastRoll = Fishing.RollAttempt(record, zone, job.attemptIndex)
        job.lastAttemptChance = job.lastRoll.chance
        job.lastAttemptRoll = job.lastRoll.roll
        job.lastAttemptSuccess = job.lastRoll.success == true
        job.lastAttemptAt = at
        if job.lastRoll.success then
            local spec = Fishing.SelectLoot(record, zone, job.attemptIndex)
            if not spec then
                job.lastFailureReason = "fishing_loot_missing"
                if Service.FishingDiagnostics
                    and Service.FishingDiagnostics.RecordAttempt
                then
                    Service.FishingDiagnostics.RecordAttempt(record, job, body,
                        job.lastRoll, {
                            reason = "fishing_loot_missing",
                            output = "rejected",
                            outputReason = "fishing_loot_missing",
                        })
                end
                return finish(false, false, "fishing_loot_missing")
            end
            job.state, job.phase = "WORKING", "OUTPUT"
            job.lastReason = "fishing_output"
            H.UpdateFishingRuntime(record, job, zone, job.phase)
            H.MarkDirty()
            if Service.FishingDiagnostics
                and Service.FishingDiagnostics.RecordTransition
            then
                Service.FishingDiagnostics.RecordTransition(record, job, body,
                    job.lastReason, {
                        event = "output_start",
                        toolID = job.activityItemID,
                        tool = job.activityItemFullType,
                        chance = job.lastAttemptChance,
                        roll = job.lastAttemptRoll,
                        success = job.lastAttemptSuccess,
                        itemType = spec.type,
                    })
            end
            if not canAccept(record, spec) then
                job.lastFailureReason = "fishing_inventory_full"
                if Service.FishingDiagnostics
                    and Service.FishingDiagnostics.RecordAttempt
                then
                    Service.FishingDiagnostics.RecordAttempt(record, job, body,
                        job.lastRoll, {
                            reason = "output_rejected",
                            itemType = spec.type,
                            output = "rejected",
                            outputReason = "fishing_inventory_full",
                        })
                end
                job.workPoints = job.workPoints + required
                job.attemptIndex = math.max(0,
                    (tonumber(job.attemptIndex) or 1) - 1)
                job.state, job.phase = "WAITING", "WAITING_FOR_OUTPUT"
                job.lastReason = "fishing_inventory_full"
                H.UpdateFishingRuntime(record, job, zone, job.phase)
                H.MarkDirty()
                return finish(true, false, "fishing_inventory_full", {
                    event = "output_wait" })
            end
            local added, addReason = addCatch(record, spec)
            if not added then
                job.lastFailureReason = addReason or "fishing_inventory_full"
                if Service.FishingDiagnostics
                    and Service.FishingDiagnostics.RecordAttempt
                then
                    Service.FishingDiagnostics.RecordAttempt(record, job, body,
                        job.lastRoll, {
                            reason = "output_rejected",
                            itemType = spec.type,
                            output = "rejected",
                            outputReason = addReason or "fishing_inventory_full",
                        })
                end
                job.workPoints = job.workPoints + required
                job.attemptIndex = math.max(0,
                    (tonumber(job.attemptIndex) or 1) - 1)
                job.state, job.phase = "WAITING", "WAITING_FOR_OUTPUT"
                job.lastReason = addReason or "fishing_inventory_full"
                H.UpdateFishingRuntime(record, job, zone, job.phase)
                H.MarkDirty()
                return finish(true, false, job.lastReason, {
                    event = "output_wait" })
            end
            if Service.FishingDiagnostics
                and Service.FishingDiagnostics.RecordAttempt
            then
                Service.FishingDiagnostics.RecordAttempt(record, job, body,
                    job.lastRoll, {
                        reason = "catch_committed",
                        itemType = spec.type,
                        output = "accepted",
                        outputReason = "fishing_catch",
                    })
            end
            job.catches = (tonumber(job.catches) or 0) + 1
            if PNC.Skills and PNC.Skills.AddXP then
                PNC.Skills.AddXP(record, "Fishing", 4)
            end
            if PNC.Tasking and PNC.Tasking.Events and PNC.Tasking.Events.Emit then
                PNC.Tasking.Events.Emit("FISHING_CATCH", {
                    npcId = npcId, source = "FishingService", entityId = job.id,
                    payload = { itemType = spec.type, attempt = job.attemptIndex },
                })
            end
            if Service.FishingDiagnostics
                and Service.FishingDiagnostics.RecordTransition
            then
                Service.FishingDiagnostics.RecordTransition(record, job, body,
                    "catch", { event = "catch", toolID = job.activityItemID,
                    tool = job.activityItemFullType })
            end
        else
            job.lastFailureReason = "roll_missed"
            if Service.FishingDiagnostics
                and Service.FishingDiagnostics.RecordAttempt
            then
                Service.FishingDiagnostics.RecordAttempt(record, job, body,
                    job.lastRoll, {
                        reason = "no_catch", output = "none",
                        outputReason = "roll_missed",
                    })
            end
        end
        attempts = attempts + 1
    end
    job.state, job.phase = "WORKING", "WORKING"
    job.lastReason = nil
    H.UpdateFishingRuntime(record, job, zone, "WORKING")
    H.MarkDirty()
    local outcome = job.lastRoll and (job.lastRoll.success and "catch" or "no_catch") or "working"
    return finish(true, false, outcome, {
        toolID = job.activityItemID, tool = job.activityItemFullType,
        recordPrimary = job.recordPrimary,
        nativePrimary = job.nativePrimary,
    })
end

function Service.GetSnapshot(zoneId)
    local zone = Service.GetZone(zoneId)
    if not zone then return nil end
    local workers = {}
    for npcId, _ in pairs(zone.workers or {}) do
        local job = Service.GetJob(npcId)
        workers[#workers + 1] = { npcId = npcId, jobId = job and job.id or nil,
            state = job and job.state or "MISSING", phase = job and job.phase or "MISSING",
            spotId = job and job.spotId or nil, catches = job and job.catches or 0 }
    end
    return {
        id = zone.id, revision = zone.revision, enabled = zone.enabled,
        valid = zone.valid, bounds = H.Copy(zone.bounds),
        geometry = H.Copy(zone.geometry),
        waterCount = zone.waterCount, landCount = zone.landCount,
        spotCount = #(zone.fishingSpots or {}),
        fishingSpots = H.Copy(zone.fishingSpots),
        unloadedTiles = zone.unloadedTiles or 0, workers = workers,
    }
end

return Service

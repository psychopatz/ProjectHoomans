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
        local ok, value = pcall(PNC.IndividualNeeds.Get, record, "fatigue")
        if ok then fatigue = tonumber(value) end
    end
    fatigue = fatigue or tonumber(record and record.fatigue)
    return fatigue ~= nil and fatigue >= (tonumber(Const.FISHING_FATIGUE_STOP) or 0.70)
end

local function canAccept(record, spec)
    if not PNC.Inventory or type(PNC.Inventory.CanAccept) ~= "function" then return true end
    local ok, accepted, reason = pcall(PNC.Inventory.CanAccept, record, { spec }, "root")
    if not ok then return false, "fishing_inventory_unavailable" end
    return accepted == true, reason or "fishing_inventory_full"
end

local function addCatch(record, spec)
    if not PNC.Inventory or type(PNC.Inventory.AddItems) ~= "function" then
        return false, "fishing_inventory_unavailable"
    end
    local ok, added, reason = pcall(PNC.Inventory.AddItems, record, { spec },
        "root", "fishing_catch")
    if not ok then return false, "fishing_inventory_add_failed" end
    return added == true, reason or "fishing_inventory_full"
end

function Service.TickJob(lease)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not zone or not record or job.active ~= true then
        return false, false, "fishing_job_unavailable"
    end
    if not Service.ValidateZone(zone) then return false, false, "fishing_zone_invalid" end
    if isTired(record) then return false, false, "fishing_npc_tired" end
    if not Service.IsNearby(record, zone) then return false, false, "fishing_npc_not_nearby" end
    if not H.RenewFishingSpot(job, zone) then
        return false, false, "fishing_spot_lost"
    end

    local preview = Fishing.SelectLoot(record, zone, (job.attemptIndex or 0) + 1)
    if preview and not canAccept(record, preview) then
        return false, false, "fishing_inventory_full"
    end

    local at = H.Now()
    local elapsed = math.max(0, math.min(Service.MAX_ELAPSED_MS,
        at - (tonumber(job.lastProgressAt) or at)))
    job.lastProgressAt = at
    local required = Fishing.RequiredWorkPoints(zone)
    job.workPoints = math.max(0, tonumber(job.workPoints) or 0)
        + (elapsed / 1000) * Fishing.WorkPointsPerSecond(zone)
    local attempts = 0
    while job.workPoints >= required and attempts < 4 do
        job.workPoints = job.workPoints - required
        job.attemptIndex = (tonumber(job.attemptIndex) or 0) + 1
        job.lastRoll = Fishing.RollAttempt(record, zone, job.attemptIndex)
        if job.lastRoll.success then
            local spec = Fishing.SelectLoot(record, zone, job.attemptIndex)
            if not spec then return false, false, "fishing_loot_missing" end
            if not canAccept(record, spec) then
                return false, false, "fishing_inventory_full"
            end
            local added, addReason = addCatch(record, spec)
            if not added then return false, false, addReason end
            job.catches = (tonumber(job.catches) or 0) + 1
            if PNC.Skills and PNC.Skills.AddXP then
                pcall(PNC.Skills.AddXP, record, "Fishing", 4)
            end
            if PNC.Tasking and PNC.Tasking.Events and PNC.Tasking.Events.Emit then
                PNC.Tasking.Events.Emit("FISHING_CATCH", {
                    npcId = npcId, source = "FishingService", entityId = job.id,
                    payload = { itemType = spec.type, attempt = job.attemptIndex },
                })
            end
        end
        attempts = attempts + 1
    end
    job.state, job.phase = "WORKING", "WORKING"
    H.UpdateFishingRuntime(record, job, zone, "WORKING")
    H.MarkDirty()
    local result = job.lastRoll and (job.lastRoll.success and "catch" or "no_catch") or "working"
    return true, false, result
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

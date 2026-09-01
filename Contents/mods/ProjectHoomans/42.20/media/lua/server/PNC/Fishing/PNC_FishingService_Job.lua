-- Fishing assignment state and per-spot reservations.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local H = Service.Internal

Service.Runtime.spotClaims = Service.Runtime.spotClaims or {}
Service.Runtime.previousOrders = Service.Runtime.previousOrders or {}

local function distanceSq(record, x, y)
    local rx, ry = tonumber(record and record.x) or 0, tonumber(record and record.y) or 0
    local dx, dy = rx - x, ry - y
    return dx * dx + dy * dy
end

local function claimKey(zone, spot)
    return tostring(zone.id) .. ":" .. tostring(spot.id)
end

local function chooseAvailableSpot(zone, record, npcId)
    local selected
    local selectedDistance
    local at = H.Now()
    for _, spot in ipairs(zone.fishingSpots or {}) do
        local key = claimKey(zone, spot)
        local claim = Service.Runtime.spotClaims[key]
        if claim and at >= (tonumber(claim.expiresAt) or 0) then
            Service.Runtime.spotClaims[key], claim = nil, nil
        end
        if not claim or tostring(claim.npcId) == tostring(npcId) then
            local value = distanceSq(record, spot.standX, spot.standY)
            if not selected or value < selectedDistance
                or (value == selectedDistance and tostring(spot.id) < tostring(selected.id))
            then selected, selectedDistance = spot, value end
        end
    end
    return selected
end

local function reserveSpot(zone, job, record)
    local spot
    for _, candidate in ipairs(zone.fishingSpots or {}) do
        if tostring(candidate.id) == tostring(job.spotId or "") then
            spot = candidate
            break
        end
    end
    spot = spot or chooseAvailableSpot(zone, record, job.npcId)
    if not spot then return nil, "fishing_spot_unavailable" end
    if distanceSq(record, spot.standX, spot.standY)
        > Service.ACTIVATION_RADIUS * Service.ACTIVATION_RADIUS
    then return nil, "fishing_npc_not_nearby" end
    Service.Runtime.spotClaims[claimKey(zone, spot)] = {
        npcId = job.npcId, expiresAt = H.Now() + Service.CLAIM_TTL_MS,
    }
    job.spotId, job.spot = spot.id, H.Copy(spot)
    return spot
end

local function releaseSpot(job, zone)
    if job and zone and job.spotId then
        local key = tostring(zone.id) .. ":" .. tostring(job.spotId)
        local claim = Service.Runtime.spotClaims[key]
        if not claim or tostring(claim.npcId) == tostring(job.npcId) then
            Service.Runtime.spotClaims[key] = nil
        end
    end
    if job then job.spotId, job.spot = nil, nil end
end

local function renewSpot(job, zone)
    if not job or not zone or not job.spotId then return false end
    local claim = Service.Runtime.spotClaims[
        tostring(zone.id) .. ":" .. tostring(job.spotId)
    ]
    if not claim or tostring(claim.npcId) ~= tostring(job.npcId) then
        return false
    end
    claim.expiresAt = H.Now() + Service.CLAIM_TTL_MS
    return true
end

function Service.AssignWorker(zoneId, npcId)
    local zone = Service.GetZone(zoneId)
    npcId = tostring(npcId or "")
    if not zone then return false, "fishing_zone_not_found" end
    if npcId == "" then return false, "fishing_npc_required" end
    local current = Service.GetJob(npcId)
    if current and current.zoneId ~= zone.id then
        Service.CancelJob(npcId, "fishing_worker_reassigned")
        local previous = Service.GetZone(current.zoneId)
        if previous then previous.workers[npcId] = nil end
    end
    local count = 0
    for _, _ in pairs(zone.workers) do count = count + 1 end
    if not zone.workers[npcId] and count >= Service.MAX_WORKERS_PER_ZONE then
        return false, "fishing_zone_worker_limit"
    end
    zone.workers[npcId] = true
    local job = current and current.zoneId == zone.id and current or {
        id = H.MakeID("fishing_job"), npcId = npcId, zoneId = zone.id,
        state = "READY", phase = "WAITING", workPoints = 0, attemptIndex = 0,
        catches = 0, revision = 1,
    }
    job.active, job.zoneId, job.npcId = true, zone.id, npcId
    job.revision = (tonumber(job.revision) or 0) + 1
    if job.state == "CANCELLED" then job.state, job.phase = "READY", "WAITING" end
    Service.Data.jobs[npcId] = job
    zone.revision = (tonumber(zone.revision) or 0) + 1
    H.MarkDirty()
    if PNC.Tasking and PNC.Tasking.Events and PNC.Tasking.Events.Emit then
        PNC.Tasking.Events.Emit("FISHING_JOB_AVAILABLE", {
            npcId = npcId, source = "FishingService", entityId = job.id,
        })
    end
    return true, job
end

function Service.ValidateJob(npcId, jobId)
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    return job ~= nil and tostring(job.id) == tostring(jobId or "")
        and job.active == true and zone ~= nil and zone.enabled == true
        and zone.workers[tostring(npcId)] == true and Service.ValidateZone(zone)
end

local function updateRuntime(record, job, zone, phase)
    record.runtime = record.runtime or {}
    local spot = job.spot or {}
    record.runtime.fishing = {
        jobId = job.id, zoneId = zone.id, spotId = job.spotId,
        phase = phase or job.phase, state = job.state,
        standX = spot.standX, standY = spot.standY, standZ = spot.standZ,
        waterX = spot.waterX, waterY = spot.waterY, waterZ = spot.waterZ,
        workPoints = tonumber(job.workPoints) or 0,
        requiredWorkPoints = PNC.Fishing.RequiredWorkPoints(zone),
        attemptIndex = tonumber(job.attemptIndex) or 0,
        catches = tonumber(job.catches) or 0, lastRoll = H.Copy(job.lastRoll),
    }
end

H.ReleaseFishingSpot = releaseSpot
H.ReserveFishingSpot = reserveSpot
H.RenewFishingSpot = renewSpot
H.UpdateFishingRuntime = updateRuntime

return Service

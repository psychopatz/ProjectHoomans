-- Fishing assignment state and per-spot reservations.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local H = Service.Internal

Service.Runtime.spotClaims = Service.Runtime.spotClaims or {}
Service.Runtime.previousOrders = Service.Runtime.previousOrders or {}

local FISHING_TOOL_TYPES = {
    ["Base.FishingRod"] = true,
    ["Base.CraftedFishingRod"] = true,
}

if PNC.WorkItemService and PNC.WorkItemService.RegisterValidator then
    PNC.WorkItemService.RegisterValidator("fishing_tool", function(_, item)
        local fullType = tostring(item and (item.fullType or item.type) or "")
        if not FISHING_TOOL_TYPES[fullType] then
            return false, "tool_cannot_fish"
        end
        if tonumber(item and item.cond) and tonumber(item.cond) <= 0 then
            return false, "fishing_tool_broken"
        end
        return true
    end)
end

local function itemFullType(item)
    local fullType = tostring(item and (item.fullType or item.type) or "")
    if fullType ~= "" then return fullType end
    if item and type(item.getFullType) == "function" then
        local value = tostring(item:getFullType() or "")
        if value ~= "" then return value end
    end
    return nil
end

local function usableFishingItem(item)
    local fullType = itemFullType(item)
    if not fullType or not FISHING_TOOL_TYPES[fullType] then
        return false, fullType
    end
    if type(item and item.isBroken) == "function"
        and item:isBroken() == true
    then
        return false, fullType
    end
    if tonumber(item and item.cond) and tonumber(item.cond) <= 0 then
        return false, fullType
    end
    return true, fullType
end

local function sortedItemIDs(items)
    local ids = {}
    for itemID, _ in pairs(items or {}) do
        ids[#ids + 1] = itemID
    end
    table.sort(ids, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return ids
end

local function nativePrimaryFullType(body)
    if not body or type(body.getPrimaryHandItem) ~= "function" then
        return nil
    end
    local item = body:getPrimaryHandItem()
    local usable, fullType = usableFishingItem(item)
    return usable and fullType or itemFullType(item)
end

local function nativePresentationReady(body, fullType)
    if not body then return true end
    -- Dedicated/network servers apply the authoritative hand selection via
    -- replica variables; their server-side Java hand is not the visual hand
    -- shown by the client. Requiring that native hand to match would make a
    -- valid record-level rod appear permanently unequipped on the server.
    if type(isServer) == "function" and isServer() == true then return true end
    return nativePrimaryFullType(body) == fullType
end

local function inventoryFishingItem(record, preferredID)
    local inventory = record and record.inventory
    local items = inventory and inventory.items
    if type(items) ~= "table" then return nil, nil end

    local function inspect(itemID)
        local item = itemID and items[itemID] or nil
        local usable, fullType = usableFishingItem(item)
        if not usable then return nil end
        item.id = item.id or itemID
        return item, fullType
    end

    local item, fullType = inspect(preferredID)
    if item then return item, fullType end

    local primaryID = inventory.equipped and inventory.equipped.primary
    item, fullType = inspect(primaryID)
    if item then return item, fullType end

    for _, itemID in ipairs(sortedItemIDs(items)) do
        if tostring(itemID) ~= tostring(preferredID or "")
            and tostring(itemID) ~= tostring(primaryID or "")
        then
            item, fullType = inspect(itemID)
            if item then return item, fullType end
        end
    end
    return nil, nil
end

local function resolveFishingTool(record, preferredID)
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record and record.id) or nil
    local inventory = record and record.inventory
    local primaryID = inventory and inventory.equipped
        and inventory.equipped.primary or nil
    local primaryItem = inventory and inventory.items
        and inventory.items[primaryID] or nil
    local primaryType = itemFullType(primaryItem)
    local item, fullType = inventoryFishingItem(record, preferredID)
    local nativeType = nativePrimaryFullType(body)
    local configuredType = tostring(record and record.equipment
        and record.equipment.primaryFullType or "")

    if item then
        local itemID = tostring(item.id or "")
        local recordReady = itemID ~= ""
            and tostring(primaryID or "") == itemID
        local nativeReady = nativePresentationReady(body, fullType)
        local reason
        if not recordReady then
            reason = "fishing_tool_not_equipped"
        elseif not nativeReady then
            reason = "fishing_tool_not_presented"
        end
        return {
            itemID = item.id, fullType = fullType,
            recordPrimaryID = primaryID, recordPrimary = primaryType,
            nativePrimary = nativeType, configuredPrimary = configuredType,
            recordReady = recordReady, nativeReady = nativeReady,
            ready = recordReady and nativeReady, reason = reason,
        }
    end

    if nativeType and FISHING_TOOL_TYPES[nativeType] then
        return {
            itemID = nil, fullType = nativeType,
            recordPrimaryID = primaryID, recordPrimary = primaryType,
            nativePrimary = nativeType, configuredPrimary = configuredType,
            recordReady = false, nativeReady = true, ready = false,
            reason = "fishing_tool_not_in_record_inventory",
        }
    end

    local hasCanonicalInventory = type(inventory and inventory.items) == "table"
    if FISHING_TOOL_TYPES[configuredType] and body == nil
        and not hasCanonicalInventory
    then
        return {
            itemID = nil, fullType = configuredType,
            recordPrimaryID = primaryID, recordPrimary = primaryType,
            nativePrimary = nativeType, configuredPrimary = configuredType,
            recordReady = true, nativeReady = true, ready = true,
        }
    end

    return {
        itemID = nil, fullType = nil,
        recordPrimaryID = primaryID, recordPrimary = primaryType,
        nativePrimary = nativeType, configuredPrimary = configuredType,
        recordReady = false, nativeReady = body == nil, ready = false,
        reason = "fishing_tool_missing",
    }
end

local function fishingToolFullType(record, preferredID)
    local resolved = resolveFishingTool(record, preferredID)
    if resolved.ready then return resolved.fullType end
    return nil
end

local function distanceSq(record, x, y)
    local rx, ry = tonumber(record and record.x) or 0, tonumber(record and record.y) or 0
    local dx, dy = rx - x, ry - y
    return dx * dx + dy * dy
end

local function claimKey(zone, spot)
    return tostring(zone.id) .. ":" .. tostring(spot.id)
end

local function chooseAvailableSpot(zone, record, npcId, excluded)
    local selected
    local selectedDistance
    local at = H.Now()
    for _, spot in ipairs(zone.fishingSpots or {}) do
        local key = claimKey(zone, spot)
        local claim = Service.Runtime.spotClaims[key]
        if claim and at >= (tonumber(claim.expiresAt) or 0) then
            Service.Runtime.spotClaims[key], claim = nil, nil
        end
        if (not excluded or excluded[tostring(spot.id)] ~= true)
            and (not claim or tostring(claim.npcId) == tostring(npcId))
        then
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
    spot = spot or chooseAvailableSpot(
        zone, record, job.npcId, job.failedSpots)
    if not spot then return nil, "fishing_spot_unavailable" end
    Service.Runtime.spotClaims[claimKey(zone, spot)] = {
        npcId = job.npcId, expiresAt = H.Now() + Service.CLAIM_TTL_MS,
    }
    job.spotId, job.spot = spot.id, H.Copy(spot)
    job.spotClaimNeedsRebind = nil
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
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if record and PNC.HomeDutyService
        and PNC.HomeDutyService.IsCamped
        and PNC.HomeDutyService.IsCamped(record) == true
    then return false, "NPC_CAMPED" end
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
    local previousRuntime = record.runtime or {}
    local previousAnimation = previousRuntime.fishingAnimationRequest
    local activeLease
    local diagnostics = Service.FishingDiagnostics
    if diagnostics and diagnostics.IsEnabled and diagnostics.IsEnabled()
        and PNC.Equipment
        and type(PNC.Equipment.GetActivePrimaryLease) == "function"
    then
        activeLease = PNC.Equipment.GetActivePrimaryLease(record)
    end
    record.runtime = record.runtime or {}
    local spot = job.spot or {}
    record.runtime.fishing = {
        jobId = job.id, zoneId = zone.id, spotId = job.spotId,
        phase = phase or job.phase, state = job.state,
        standX = spot.standX, standY = spot.standY, standZ = spot.standZ,
        waterX = spot.waterX, waterY = spot.waterY, waterZ = spot.waterZ,
        workPoints = tonumber(job.workPoints) or 0,
        requiredWorkPoints = tonumber(job.requiredWorkPoints)
            or PNC.Fishing.RequiredWorkPoints(zone),
        attemptIndex = tonumber(job.attemptIndex) or 0,
        catches = tonumber(job.catches) or 0, lastRoll = H.Copy(job.lastRoll),
        lastAttemptChance = job.lastAttemptChance,
        lastAttemptRoll = job.lastAttemptRoll,
        lastAttemptSuccess = job.lastAttemptSuccess,
        lastAttemptAt = job.lastAttemptAt,
        activityItemID = job.activityItemID,
        activityItemFullType = job.activityItemFullType,
        toolReady = job.toolReady == true,
        toolReason = job.toolReason,
        recordPrimaryID = job.recordPrimaryID,
        recordPrimary = job.recordPrimary,
        nativePrimary = job.nativePrimary,
        executionMode = job.executionMode,
        lastReason = job.lastReason,
        lastFailureReason = job.lastFailureReason,
        leaseOwner = activeLease and activeLease.owner or nil,
        leasePriority = activeLease and activeLease.priority or nil,
        animationScene = previousAnimation and previousAnimation.scene
            or previousRuntime.animationScene
            and previousRuntime.animationScene.id or nil,
        animationRequest = previousAnimation and previousAnimation.ok or nil,
        animationReason = previousAnimation and previousAnimation.reason or nil,
        actionPropAttach = previousRuntime.actionPropAttach,
        waitingFor = phase == "TOOL_CHECK" and not job.toolReady
            and "primary_tool"
            or phase == "WAITING_FOR_TOOL" and "primary_tool"
            or phase == "WAITING_FOR_OUTPUT" and "output"
            or phase == "WAITING_FOR_SPOT" and "fishing_spot" or nil,
        waitingReason = job.lastReason,
    }
end

H.ReleaseFishingSpot = releaseSpot
H.ReserveFishingSpot = reserveSpot
H.RenewFishingSpot = renewSpot
H.UpdateFishingRuntime = updateRuntime
H.FishingToolFullType = fishingToolFullType
H.ResolveFishingTool = resolveFishingTool

return Service

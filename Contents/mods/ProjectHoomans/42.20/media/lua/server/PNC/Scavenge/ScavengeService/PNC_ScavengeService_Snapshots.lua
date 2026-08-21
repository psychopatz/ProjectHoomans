if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local Const = PNC.Const
local Policy = PNC.ScavengePolicy
local copy = Internal.Copy
local ownerMatches = Internal.OwnerMatches
local forEachWorker = Internal.ForEachWorker

local function publicEntry(entry)
    return {
        entryId = entry.entryId,
        sourceToken = entry.sourceToken,
        sourceType = entry.sourceType,
        sourceLabel = entry.sourceLabel,
        fullType = entry.fullType,
        displayName = entry.displayName,
        category = entry.category,
        quantity = entry.quantity,
        x = entry.x, y = entry.y, z = entry.z,
        distanceSq = entry.distanceSq,
        autoGrab = entry.autoGrab == true,
        status = entry.status,
        failureReason = entry.failureReason,
        assignedNpcId = entry.assignedNpcId,
        discoveredByNpcId = entry.discoveredByNpcId,
    }
end

function Service.BuildSnapshot(session)
    if not session then return nil end
    local manifest = {}
    for index = 1, #session.manifest do
        manifest[index] = publicEntry(session.manifest[index])
    end
    local scavengers = {}
    local totalUsed, totalMax = 0, 0
    local taskPhase
    local currentSourceToken
    forEachWorker(session, function(npcId)
        local worker = session.workers and session.workers[npcId] or nil
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcId) or nil
        local encumbrance = record and PNC.Inventory.GetEncumbranceState(record)
            or nil
        local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
            and PNC.TaskLeaseService.ForNPC(npcId) or nil
        if lease and not taskPhase then taskPhase = lease.phase end
        local currentSource = worker and worker.currentSource or nil
        if currentSource and not currentSourceToken then
            currentSourceToken = currentSource.sourceToken
        end
        totalUsed = totalUsed + (tonumber(encumbrance
            and encumbrance.usedWeight) or 0)
        totalMax = totalMax + (tonumber(encumbrance
            and encumbrance.maxWeight) or 0)
        scavengers[#scavengers + 1] = {
            npcId = npcId,
            npcName = tostring(record and record.name or npcId),
            phase = worker and worker.phase or "IDLE",
            waitReason = worker and worker.waitReason or nil,
            currentSource = currentSource and {
                sourceToken = currentSource.sourceToken,
                sourceType = currentSource.sourceType,
                sourceLabel = currentSource.sourceLabel or currentSource.label,
                x = currentSource.x, y = currentSource.y, z = currentSource.z,
            } or nil,
            carry = encumbrance and copy(encumbrance) or nil,
        }
    end)
    local queue = {}
    for index, group in ipairs(session.queue or {}) do
        queue[index] = { sourceToken = group.sourceToken,
            sourceType = group.sourceType,
            entryCount = #(group.entries or {}), distanceSq = group.distanceSq }
    end
    local progress = 0
    if session.candidateCount > 0 then
        progress = math.floor((session.processedCount / session.candidateCount)
            * 100 + 0.5)
    elseif session.state == "WAITING_FOR_SELECTION"
        or session.state == "COMPLETED"
    then
        progress = 100
    end
    return {
        sessionId = session.id,
        revision = session.revision,
        npcId = session.npcId,
        npcName = session.npcName,
        npcIds = copy(session.npcIds or { session.npcId }),
        scavengers = scavengers,
        state = session.state,
        phase = session.phase,
        runActive = session.runActive == true,
        progress = progress,
        candidateCount = session.candidateCount,
        searchedCount = session.searchedCount,
        processedCount = session.processedCount,
        unreachableCount = session.unreachableCount,
        invalidCount = session.invalidCount,
        sourceCounts = copy(session.sourceCounts),
        sourcePolicy = copy(session.sourcePolicy),
        manifest = manifest,
        activity = copy(session.activity),
        queueCount = session.queueCount or 0,
        queue = queue,
        queueIndex = session.queueIndex,
        currentSourceToken = currentSourceToken,
        nextCandidateIndex = session.nextCandidateIndex,
        taskPhase = taskPhase,
        collectedCount = session.collectedCount or 0,
        unavailableCount = session.unavailableCount or 0,
        truncated = session.truncated == true,
        lastFailure = session.lastFailure,
        carry = totalMax > 0 and {
            usedWeight = totalUsed,
            maxWeight = totalMax,
            ratio = totalUsed / totalMax,
            level = totalUsed > totalMax and "encumbered" or "normal",
        } or nil,
        policy = Policy and Policy.Snapshot(session.ownerPlayer) or nil,
    }
end

return Service

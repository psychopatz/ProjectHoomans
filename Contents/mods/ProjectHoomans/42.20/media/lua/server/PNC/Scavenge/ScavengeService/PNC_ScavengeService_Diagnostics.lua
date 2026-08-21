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

local function publicDebugSource(source, index, status)
    if not source then return nil end
    return {
        index = index,
        status = status,
        sourceToken = source.sourceToken,
        sourceType = source.sourceType,
        sourceLabel = source.sourceLabel or source.label,
        x = source.x, y = source.y, z = source.z,
        distanceSq = source.approximateDistanceSq or source.distanceSq,
        valid = WorldLoot.IsSourceValid(source.sourceToken) == true,
    }
end

function Service.BuildSessionDiagnostics(session)
    if not session then return nil end
    local now = PNC.Core.Now()
    local workers = {}
    forEachWorker(session, function(npcId)
        local worker = session.workers and session.workers[npcId] or {}
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcId) or nil
        local body = record and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcId) or nil
        local runtime = record and record.runtime or {}
        local lane = runtime.pathing or {}
        local intent = runtime.moveIntent or {}
        local source = worker.currentSource
        local sourceDebug = publicDebugSource(source, nil, "CURRENT")
        local x = body and body.getX and body:getX() or record and record.x
        local y = body and body.getY and body:getY() or record and record.y
        if sourceDebug and x and y and sourceDebug.x and sourceDebug.y then
            local dx, dy = x - sourceDebug.x, y - sourceDebug.y
            sourceDebug.workerDistanceSq = dx * dx + dy * dy
        end
        workers[#workers + 1] = {
            npcId = npcId,
            npcName = tostring(record and record.name or npcId),
            workerPhase = worker.phase or "IDLE",
            waitReason = worker.waitReason,
            currentKind = worker.currentKind,
            currentSource = sourceDebug,
            lastMovement = worker.lastMovement,
            lastMovementAgeMs = worker.lastMovementAt
                and math.max(0, now - worker.lastMovementAt) or nil,
            lastFailure = worker.lastFailure,
            approachFailures = tonumber(worker.approachFailures) or 0,
            directRecovery = worker.useDirectRecovery == true,
            leasePhase = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
                and PNC.TaskLeaseService.ForNPC(npcId)
                and PNC.TaskLeaseService.ForNPC(npcId).phase or nil,
            path = {
                phase = lane.phase,
                reason = lane.blockReason or lane.cancelReason,
                intentReason = lane.intentReason,
                requestedByJob = lane.requestedByJob,
                goalX = lane.goal and lane.goal.x,
                goalY = lane.goal and lane.goal.y,
            },
            moveIntent = {
                kind = intent.kind,
                reason = intent.reason,
                x = intent.x, y = intent.y, z = intent.z,
                ageMs = intent.updatedAt
                    and math.max(0, now - intent.updatedAt) or nil,
            },
        }
    end)
    local pending = {}
    local first = math.max(1, tonumber(session.nextCandidateIndex) or 1)
    local last = math.min(tonumber(session.candidateCount) or 0, first + 7)
    for index = first, last do
        pending[#pending + 1] = publicDebugSource(
            session.candidates[index], index, index == first and "NEXT" or "PENDING")
    end
    return {
        sessionId = session.id,
        state = session.state,
        phase = session.phase,
        processedCount = session.processedCount,
        candidateCount = session.candidateCount,
        nextCandidateIndex = session.nextCandidateIndex,
        workers = workers,
        pendingSources = pending,
    }
end

function Service.SendSnapshot(session, player)
    if not session then return false end
    player = player or session.ownerPlayer
    if not player or not ownerMatches(session, player) then return false end
    local payload = Service.BuildSnapshot(session)
    if isServer and isServer() == true and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_SCAVENGE_STATE,
            payload)
    elseif PNC.Client and PNC.Client.Internal
        and PNC.Client.Internal.ApplyScavengeSnapshot
    then
        PNC.Client.Internal.ApplyScavengeSnapshot(payload)
    end
    return true
end

function Service.GetSession(sessionId)
    return Service.Sessions[tostring(sessionId or "")]
end

function Service.CanAccessSession(player, sessionId)
    local session = Service.GetSession(sessionId)
    return session ~= nil and ownerMatches(session, player)
end

function Service.GetSearchStatus(sessionId)
    local session = Service.GetSession(sessionId)
    return session and Service.BuildSnapshot(session) or nil
end

function Service.GetLootManifest(sessionId)
    local snapshot = Service.GetSearchStatus(sessionId)
    return snapshot and snapshot.manifest or nil
end

function Service.GetCollectionStatus(sessionId)
    return Service.GetSearchStatus(sessionId)
end

function Service.GetAutoGrabPolicy(player)
    return Policy.GetAutoGrab(player)
end

function Service.GetSearchPreferences(player)
    return Policy.GetPreferences(player)
end

function Service.GetDiagnostics()
    local activeSearches, activeCollections = 0, 0
    for _, session in pairs(Service.Sessions) do
        if session.state == "DISCOVERING"
            or session.state == "TRAVELING_TO_SEARCH_SOURCE"
            or session.state == "SEARCHING_SOURCE"
        then activeSearches = activeSearches + 1 end
        if session.state == "COLLECTION_QUEUED"
            or session.state == "TRAVELING_TO_LOOT_SOURCE"
            or session.state == "COLLECTING"
            or session.state == "ATOMIC_TRANSFER"
        then activeCollections = activeCollections + 1 end
    end
    return {
        activeSearchSessions = activeSearches,
        activeCollectionSessions = activeCollections,
        counters = copy(Service.Diagnostics.counters),
        timings = copy(Service.Diagnostics.timings),
        worldLoot = WorldLoot.GetDiagnostics(),
        lastFailure = copy(Service.Diagnostics.lastFailure),
    }
end

return Service

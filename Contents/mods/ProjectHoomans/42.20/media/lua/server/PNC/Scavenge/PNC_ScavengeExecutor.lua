if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local InventoryConstants = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
require "PNC/Core/Behaviors/PNC_Behavior_Common"

PNC = PNC or {}
PNC.ScavengeExecutor = PNC.ScavengeExecutor or {}

local Executor = PNC.ScavengeExecutor
local Service = PNC.ScavengeService
local Const = PNC.Const
local Common = PNC.BehaviorCommon

local function sessionForNPC(npcId)
    return Service.Internal.SessionForNPC(npcId)
end

local function liveRecord(npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
    local body = record and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if not record or not body then return nil, nil, "npc_not_live" end
    return record, body
end

local function resetPath(record, body, reason)
    if PNC.PathService and PNC.PathService.Commands
        and PNC.PathService.Commands.Reset
    then
        PNC.PathService.Commands.Reset(record, body, reason or "scavenge")
    elseif PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(body, record)
    end
end

local function laneBlocked(record)
    local lane = record and record.runtime and record.runtime.pathing or nil
    return lane and lane.phase == "blocked",
        lane and (lane.blockReason or lane.cancelReason) or nil
end

local function approachKey(value)
    return string.format("%.2f:%.2f:%d", tonumber(value.x) or 0,
        tonumber(value.y) or 0, math.floor(tonumber(value.z) or 0))
end

local function approachLocation(session, source, location, record, excluded)
    session.approachBySource = session.approachBySource or {}
    local cacheKey = tostring(source.sourceToken) .. "\31"
        .. tostring(record and record.id or "npc")
    local cached = session.approachBySource[cacheKey]
    if cached and not (excluded and excluded[approachKey(cached)]) then
        return cached
    end
    local baseX, baseY = tonumber(location.x), tonumber(location.y)
    local baseZ = tonumber(location.z) or 0
    if not baseX or not baseY then return nil, "source_location_invalid" end
    local checker = PNC.PathService and PNC.PathService.Internal
        and PNC.PathService.Internal.isSquareWalkable or nil
    local exactSquare = source.sourceType == "floor"
        or source.sourceType == "corpse"
    -- Containers occupy their source square. Target an adjacent interaction
    -- tile so native pathing does not run forever against the container while
    -- trying to reach its otherwise-valid square center.
    local offsets = exactSquare and { { 0, 0 } }
        or { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
            { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
    local best, bestDistance
    for _, offset in ipairs(offsets) do
        local x, y = baseX + offset[1], baseY + offset[2]
        local walkable = not checker or checker(x, y, baseZ) == true
        local candidate = { x = x + 0.5, y = y + 0.5, z = baseZ }
        if walkable and not (excluded and excluded[approachKey(candidate)]) then
            local dx = x - (tonumber(record.x) or x)
            local dy = y - (tonumber(record.y) or y)
            local distance = dx * dx + dy * dy
            if not best or distance < bestDistance then
                best = candidate
                bestDistance = distance
            end
        end
    end
    if not best then return nil, "source_interaction_unreachable" end
    session.approachBySource[cacheKey] = best
    return best
end

local function withinInteractionRadius(record, body, location, sourceType)
    local x = body and body.getX and body:getX() or tonumber(record.x)
    local y = body and body.getY and body:getY() or tonumber(record.y)
    local z = body and body.getZ and body:getZ() or tonumber(record.z)
    local targetX = tonumber(location.x)
    local targetY = tonumber(location.y)
    local targetZ = tonumber(location.z) or 0
    if not x or not y or not z or not targetX or not targetY
        or math.floor(z) ~= math.floor(targetZ)
    then return false end
    local dx = x - (targetX + 0.5)
    local dy = y - (targetY + 0.5)
    local radius = sourceType == "container" and 1.85 or 1.35
    return dx * dx + dy * dy <= radius * radius
end

local function completeLease(lease, reason)
    if lease and PNC.TaskLeaseService.Get(lease.leaseId) then
        PNC.Tasking.Commands.Complete(lease.leaseId, reason)
    end
end

local function destinationStore(record, body)
    local container = body and body.getInventory and body:getInventory() or nil
    if not container then return nil, "npc_inventory_unavailable" end
    local physical, reason = CoreInventory.wrapPhysicalInventory(container, {
        recursive = false, syncOnMutation = true,
    })
    if not physical then return nil, reason end
    local destination = { physical = physical }

    function destination:add(itemRecord, quantity)
        local fullType = CoreInventory.getItemFullType(
            itemRecord and itemRecord[InventoryConstants.TYPE_ID])
        if not fullType then return false, "item_type_unknown" end
        local canAccept, acceptReason = PNC.Inventory.CanAccept(record, {
            { type = fullType, stack = tonumber(quantity)
                or tonumber(itemRecord[InventoryConstants.QUANTITY]) or 1 },
        })
        if not canAccept then return false, acceptReason end
        local ok, added = physical:add(itemRecord, quantity)
        if not ok then return false, added end
        local captured, captureReason = PNC.Inventory.CaptureLooseInventory(
            record, body)
        if not captured then
            for index = #added, 1, -1 do
                physical:_nativeRemove(added[index])
            end
            PNC.Inventory.CaptureLooseInventory(record, body)
            return false, captureReason or "npc_inventory_capture_failed"
        end
        return true, added
    end

    function destination:_nativeRemove(item)
        local removed = physical:_nativeRemove(item)
        PNC.Inventory.CaptureLooseInventory(record, body)
        return removed
    end

    return destination
end

local LOOT_SCENE_DURATION_MS = 650

local function workerFor(session, npcId)
    npcId = tostring(npcId or "")
    session.workers = session.workers or {}
    session.workers[npcId] = session.workers[npcId]
        or { npcId = npcId, phase = "READY" }
    return session.workers[npcId]
end

local function setWorkerPhase(session, worker, phase, leasePhase)
    worker.phase = phase
    if leasePhase then
        PNC.Tasking.Commands.SetPhase(worker.npcId, leasePhase)
    end
    session.phase = phase
end

local function itemWeight(entry)
    local internal = PNC.Inventory and PNC.Inventory.Internal or nil
    local weight = internal and internal.getItemWeight
        and internal.getItemWeight(entry.fullType) or 0.1
    return math.max(0, tonumber(weight) or 0.1)
        * math.max(1, tonumber(entry.quantity) or 1)
end

local function canCarryEntry(record, entry)
    local encumbrance = PNC.Inventory.GetEncumbranceState(record)
    if not encumbrance then return false, "carry_state_unavailable" end
    local used = tonumber(encumbrance.usedWeight) or 0
    local maximum = tonumber(encumbrance.maxWeight) or 0
    if tonumber(encumbrance.ratio) > 1 or maximum <= 0 then
        return false, "npc_encumbered"
    end
    if used + itemWeight(entry) > maximum then
        return false, "no_free_capacity"
    end
    return PNC.Inventory.CanAccept(record, {
        { type = entry.fullType, stack = tonumber(entry.quantity) or 1 },
    })
end

local function queuedEntries(session)
    local output = {}
    for _, group in ipairs(session.queue or {}) do
        for _, entry in ipairs(group.entries or {}) do
            if entry.status == "QUEUED" then
                output[#output + 1] = { group = group, entry = entry }
            end
        end
    end
    return output
end

local function teamCanClaim(session, entry)
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        local failed = entry.failedWorkers
            and entry.failedWorkers[tostring(npcId)]
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcId) or nil
        if not failed and record and canCarryEntry(record, entry) == true then
            return true
        end
    end
    return false
end

local function claimQueuedEntry(session, worker, record)
    for _, candidate in ipairs(queuedEntries(session)) do
        local entry = candidate.entry
        local failed = entry.failedWorkers and entry.failedWorkers[worker.npcId]
        if not entry.assignedNpcId and not failed
            and canCarryEntry(record, entry) == true
        then
            entry.assignedNpcId = worker.npcId
            worker.currentKind = "loot"
            worker.currentSource = {
                sourceToken = candidate.group.sourceToken,
                sourceType = candidate.group.sourceType,
                sourceLabel = candidate.group.sourceLabel,
                x = candidate.group.x, y = candidate.group.y,
                z = candidate.group.z,
            }
            worker.currentGroup = candidate.group
            worker.currentEntry = entry
            return true
        end
    end
    return false
end

local function claimSearchSource(session, worker)
    local source = session.candidates[session.nextCandidateIndex or 1]
    if not source then
        session.searchComplete = true
        return false
    end
    session.nextCandidateIndex = (session.nextCandidateIndex or 1) + 1
    session.searchClaims = session.searchClaims or {}
    session.searchClaims[source.sourceToken] = worker.npcId
    worker.currentKind = "search"
    worker.currentSource = source
    return true
end

local function beginLootScene(session, worker, record, body)
    local sceneId = "scavenge.loot"
    local scenes = PNC.AnimationScenes
    local requested, result
    if scenes and scenes.RequestFromPool then
        requested, result = scenes.RequestFromPool(
            record, body, "scavenge.loot", {
                reason = worker.currentKind == "search"
                    and "scavenge_search" or "scavenge_take",
            })
        if requested and type(result) == "table" and result.id then
            sceneId = tostring(result.id)
        end
    elseif scenes and scenes.Request then
        scenes.Request(record, body, sceneId, {
            reason = worker.currentKind == "search"
                and "scavenge_search" or "scavenge_take",
        })
    end
    worker.actionUntil = PNC.Core.Now() + LOOT_SCENE_DURATION_MS
    worker.actionScene = sceneId
    setWorkerPhase(session, worker,
        worker.currentKind == "search" and "SEARCHING_SOURCE" or "LOOTING",
        "WORKING")
    Service.Internal.Activity(session,
        worker.currentKind == "search" and "SEARCHING" or "TAKING",
        worker.currentEntry or {
            entryId = worker.currentSource.sourceToken,
            sourceType = worker.currentSource.sourceType,
        }, sceneId)
end

local function clearWorkerAction(worker)
    worker.currentKind = nil
    worker.currentSource = nil
    worker.currentGroup = nil
    worker.currentEntry = nil
    worker.actionUntil = nil
    worker.actionScene = nil
end

local function combatOwnsWorker(record)
    local runtime = record and record.runtime or nil
    local now = PNC.Core.Now()
    return runtime ~= nil and (
        runtime.target ~= nil
        or runtime.attackAction ~= nil
        or runtime.recentThreat ~= nil
        or runtime.zombieAttacker ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
    )
end

local function finishSearchAction(session, worker)
    local source = worker.currentSource
    local ok, countOrReason = Service.AppendSourceItems(
        session, source, worker.npcId)
    session.processedCount = session.processedCount + 1
    session.searchClaims[source.sourceToken] = nil
    if ok then
        session.searchedCount = session.searchedCount + 1
        Service.Internal.Activity(session, "SOURCE_SEARCHED", {
            entryId = source.sourceToken, sourceType = source.sourceType,
        }, tostring(countOrReason or 0))
        Service.Internal.Increment("SourcesSearched")
    else
        session.invalidCount = session.invalidCount + 1
        Service.Internal.Activity(session, "SOURCE_INVALID", {
            entryId = source.sourceToken, sourceType = source.sourceType,
        }, countOrReason)
        Service.Internal.Increment("InvalidSources")
    end
    clearWorkerAction(worker)
    Service.Internal.Touch(session, "SourceSearched", {
        sourceToken = source.sourceToken,
        itemCount = ok and countOrReason or 0,
        reason = ok and nil or countOrReason,
    }, true)
end

local function transferWorkerEntry(session, worker, record, body)
    local entry, group = worker.currentEntry, worker.currentGroup
    if not entry or entry.status ~= "QUEUED" then
        clearWorkerAction(worker)
        return true
    end
    local canCarry, reason = canCarryEntry(record, entry)
    if not canCarry then
        entry.failedWorkers = entry.failedWorkers or {}
        entry.failedWorkers[worker.npcId] = true
        entry.assignedNpcId = nil
        clearWorkerAction(worker)
        return false, reason
    end
    local destination
    destination, reason = destinationStore(record, body)
    if not destination then
        entry.failedWorkers = entry.failedWorkers or {}
        entry.failedWorkers[worker.npcId] = true
        entry.assignedNpcId = nil
        clearWorkerAction(worker)
        return false, reason
    end
    setWorkerPhase(session, worker, "ATOMIC_TRANSFER", "ATOMIC_COMMIT")
    local ok, result = WorldLoot.Transfer({
        sourceToken = group.sourceToken,
        itemToken = entry.itemToken,
        reservationToken = entry.reservationToken,
        destination = destination,
        owner = session.id,
    })
    entry.reservationToken = nil
    entry.assignedNpcId = nil
    if ok then
        entry.status = "COLLECTED"
        entry.failureReason = nil
        session.collectedCount = session.collectedCount + 1
        Service.Internal.Activity(session, "COLLECTED", entry, worker.npcId)
        Service.Internal.Increment("ItemsCollected")
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "inventory")
        end
        if PNC.Network and PNC.Network.BroadcastRecord then
            PNC.Network.BroadcastRecord(record, "scavenge_collect")
        end
    else
        entry.status = "UNAVAILABLE"
        entry.failureReason = tostring(result or "transfer_failed")
        session.unavailableCount = session.unavailableCount + 1
        Service.Internal.Activity(session, "UNAVAILABLE", entry,
            entry.failureReason)
        Service.Internal.Increment("TransferFailures")
    end
    session.queueCount = math.max(0,
        (tonumber(session.queueCount) or 0) - 1)
    clearWorkerAction(worker)
    Service.Internal.Touch(session,
        ok and "ItemCollected" or "ItemUnavailable", {
            entryId = entry.entryId,
            npcId = worker.npcId,
            reason = ok and nil or entry.failureReason,
        }, true)
    return ok
end

local function noAssignedQueue(session)
    for _, candidate in ipairs(queuedEntries(session)) do
        if candidate.entry.assignedNpcId then return false end
    end
    return true
end

local function queuedTeamCapacity(session)
    for _, candidate in ipairs(queuedEntries(session)) do
        if candidate.entry.assignedNpcId
            or teamCanClaim(session, candidate.entry)
        then return true end
    end
    return false
end

local function pauseTeamForCapacity(session)
    if session.state == "PAUSED_CAPACITY" then return end
    Service.Internal.ReleaseReservations(session, "capacity_pause")
    for _, entry in ipairs(session.manifest or {}) do
        if entry.status == "QUEUED" then
            entry.status = "AVAILABLE"
            entry.assignedNpcId = nil
            entry.failureReason = "no_team_capacity"
        end
    end
    session.queue = nil
    session.queueCount = 0
    session.state = "PAUSED_CAPACITY"
    session.phase = "PAUSED_CAPACITY"
    session.runActive = false
    Service.Internal.Activity(session, "PAUSED_CAPACITY", nil,
        "team_capacity_reached")
    Service.Internal.Touch(session, "CollectionPaused", {
        reason = "team_capacity_reached",
    }, true)
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_CAPACITY_PAUSE")
        Service.Internal.RestorePreviousOrder(session, npcId)
    end
end

local function allWorkersIdle(session)
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        local worker = workerFor(session, npcId)
        if worker.phase ~= "IDLE" then return false end
    end
    return true
end

local function settleIdleSession(session)
    if not allWorkersIdle(session) then return end
    session.searchComplete = session.nextCandidateIndex > session.candidateCount
    session.state = "WAITING_FOR_SELECTION"
    session.phase = "WAITING_FOR_SELECTION"
    session.runActive = false
    Service.Internal.Activity(session, "SEARCH_COMPLETE", nil,
        session.truncated and "results_truncated" or nil)
    Service.Internal.Touch(session, "SearchCompleted", {
        count = #session.manifest,
        truncated = session.truncated == true,
    }, true)
end

local function finishWorker(session, worker, lease)
    clearWorkerAction(worker)
    worker.phase = "IDLE"
    Service.Internal.RestorePreviousOrder(session, worker.npcId)
    completeLease(lease, "SCAVENGE_WORKER_IDLE")
    settleIdleSession(session)
end

local function failWorkerSource(session, worker, reason)
    local source = worker.currentSource
    if worker.currentKind == "loot" and worker.currentEntry then
        local entry = worker.currentEntry
        entry.failedWorkers = entry.failedWorkers or {}
        entry.failedWorkers[worker.npcId] = true
        entry.assignedNpcId = nil
        if not teamCanClaim(session, entry) then
            entry.status = "AVAILABLE"
            if entry.reservationToken then
                WorldLoot.ReleaseReservation(entry.reservationToken,
                    "no_team_capacity")
                entry.reservationToken = nil
            end
        end
    elseif source then
        session.processedCount = session.processedCount + 1
        session.unreachableCount = session.unreachableCount + 1
        session.searchClaims[source.sourceToken] = nil
        Service.Internal.Increment("UnreachableSources")
    end
    Service.Internal.Activity(session, "SOURCE_SKIPPED", {
        entryId = source and source.sourceToken,
        sourceType = source and source.sourceType,
    }, reason)
    clearWorkerAction(worker)
    Service.Internal.Touch(session, "SourceSkipped", {
        sourceToken = source and source.sourceToken,
        npcId = worker.npcId, reason = reason,
    }, true)
end

local function retryWorkerApproach(session, worker, record, body,
    source, approach, reason)
    local excluded = worker.failedApproaches[source.sourceToken] or {}
    worker.failedApproaches[source.sourceToken] = excluded
    excluded[approachKey(approach)] = true
    local cacheKey = tostring(source.sourceToken) .. "\31"
        .. tostring(record.id or "npc")
    session.approachBySource[cacheKey] = nil
    worker.approachFailures = (tonumber(worker.approachFailures) or 0) + 1
    resetPath(record, body, "scavenge_retry_interaction_tile")
    if worker.approachFailures < 4 then return nil, "approach_retry" end
    return false, reason or "path_blocked"
end

local function arriveWorker(session, worker, record, body)
    local source = worker.currentSource
    if not source or not WorldLoot.IsSourceValid(source.sourceToken) then
        return false, "source_invalid"
    end
    local location, reason = WorldLoot.GetSourceLocation(source.sourceToken)
    if not location then return false, reason or "source_location_unavailable" end
    if withinInteractionRadius(record, body, location, source.sourceType) then
        resetPath(record, body, "scavenge_interaction_radius")
        worker.approachFailures = nil
        return true
    end
    worker.failedApproaches = worker.failedApproaches or {}
    local excluded = worker.failedApproaches[source.sourceToken]
    local approach
    approach, reason = approachLocation(
        session, source, location, record, excluded)
    if not approach then return false, reason end
    local blocked, blockReason = laneBlocked(record)
    if blocked then
        return retryWorkerApproach(session, worker, record, body,
            source, approach, blockReason)
    end
    setWorkerPhase(session, worker,
        worker.currentKind == "loot" and "TRAVELING_TO_LOOT_SOURCE"
            or "TRAVELING_TO_SEARCH_SOURCE", "TRAVEL")
    local stopDistance = source.sourceType == "container" and 0.8 or 0.65
    local ok, movement = Common.MoveRecord(record, body,
        approach.x, approach.y, approach.z, "walk", stopDistance,
        worker.currentKind == "loot" and "scavenge_loot"
            or "scavenge_search", nil)
    if not ok then
        local failure = tostring(movement or "path_request_failed")
        if failure == "native_progress_timeout"
            or failure == "native_path_unreachable"
            or failure == "native_no_goal_progress"
        then
            return retryWorkerApproach(session, worker, record, body,
                source, approach, failure)
        end
        return false, failure
    end
    if movement == "arrived" then
        resetPath(record, body, "scavenge_arrived")
        worker.approachFailures = nil
        return true
    end
    return nil, movement
end

local function tickWorker(session, lease, record, body)
    local worker = workerFor(session, lease.npcId)
    if combatOwnsWorker(record) then
        if worker.actionUntil then
            worker.actionUntil = nil
            worker.actionScene = nil
            if PNC.AnimationScenes and PNC.AnimationScenes.Interrupt then
                PNC.AnimationScenes.Interrupt(record, body, "combat")
            end
        end
        setWorkerPhase(session, worker, "INTERRUPTED_COMBAT", "WAITING")
        return true
    elseif worker.phase == "INTERRUPTED_COMBAT" then
        worker.phase = "READY"
    end
    if worker.actionUntil then
        if PNC.Core.Now() < worker.actionUntil then return true end
        if worker.currentKind == "search" then
            finishSearchAction(session, worker)
        else
            transferWorkerEntry(session, worker, record, body)
        end
        worker.phase = "READY"
        return true
    end
    if worker.currentSource then
        local arrived, reason = arriveWorker(session, worker, record, body)
        if arrived == nil then return true end
        if arrived ~= true then
            failWorkerSource(session, worker, reason)
            worker.phase = "READY"
            return true
        end
        beginLootScene(session, worker, record, body)
        return true
    end
    local queued = queuedEntries(session)
    if #queued > 0 then
        if claimQueuedEntry(session, worker, record) then return true end
        setWorkerPhase(session, worker, "WAITING_FOR_CAPACITY", "WAITING")
        if noAssignedQueue(session) and not queuedTeamCapacity(session) then
            pauseTeamForCapacity(session)
        end
        return true
    end
    if claimSearchSource(session, worker) then
        session.state = "DISCOVERING"
        worker.phase = "READY"
        return true
    end
    finishWorker(session, worker, lease)
    return true
end

function Executor.GetCandidates(npcId)
    local session = sessionForNPC(npcId)
    local worker = session and workerFor(session, npcId) or nil
    if not session or session.runActive ~= true or not worker then return {} end
    return {{
        taskId = "scavenge_task:" .. session.id .. ":" .. tostring(npcId),
        npcId = tostring(npcId),
        kind = "SCAVENGE",
        sourceDomain = "scavenge",
        sourceRef = session.id,
        -- Needs remain survival primitives during a player-directed run.
        -- HIGH_WORK keeps scavenging preferred over ordinary work while both
        -- NORMAL_NEED and CRITICAL_NEED can temporarily preempt it.
        precedence = "HIGH_WORK",
        urgency = 0.75,
        capability = "SCAVENGE",
        interruptPolicy = "NORMAL",
        revision = session.revision,
        createdAt = session.createdAt,
    }}
end

function Executor.Validate(intent)
    local session = Service.GetSession(intent and intent.sourceRef)
    return session ~= nil and session.runActive == true
        and session.workers
        and session.workers[tostring(intent.npcId)] ~= nil
end

function Executor.Assign(intent)
    local session = Service.GetSession(intent and intent.sourceRef)
    if not session then return nil, "session_not_found" end
    return { executionMode = "LIVE", resourceKey = session.id,
        resourceKind = "WORLD_LOOT_SESSION" }
end

function Executor.Start(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    local record = session and PNC.Registry.Get(lease.npcId) or nil
    if not session or not record then return false, "session_or_npc_unavailable" end
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local worker = workerFor(session, lease.npcId)
    worker.leaseId = lease.leaseId
    worker.phase = "READY"
    resetPath(record, body, "scavenge_start")
    PNC.OrderSystem.SetOrder(record, {
        kind = Const.ORDER_SCAVENGE, sessionId = session.id,
    })
    PNC.Tasking.Commands.SetPhase(lease.npcId, "ASSIGNED")
    return true
end

function Executor.CanContinue(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    return session ~= nil and session.runActive == true
        and session.workers
        and session.workers[tostring(lease.npcId)] ~= nil
end

function Executor.Tick(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    if not session then
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            "SCAVENGE_SESSION_MISSING")
        return false
    end
    local record, body, reason = liveRecord(lease.npcId)
    if not record then
        session.state, session.phase = "FAILED", "FAILED"
        session.lastFailure = reason
        Service.Internal.ReleaseReservations(session, reason)
        WorldLoot.ReleaseSession(session.worldLootSessionId)
        session.worldLootReleased = true
        Service.Internal.Touch(session, "ScavengeFailed", { reason = reason }, true)
        completeLease(lease, "SCAVENGE_NPC_NOT_LIVE")
        return false
    end
    return tickWorker(session, lease, record, body)
end

function Executor.Cancel(lease, reason)
    local session = Service.GetSession(lease and lease.sourceRef)
    if not session then return true end
    local worker = workerFor(session, lease.npcId)
    if worker.currentEntry and worker.currentEntry.status == "QUEUED" then
        worker.currentEntry.assignedNpcId = nil
    end
    clearWorkerAction(worker)
    worker.leaseId = nil
    worker.phase = "IDLE"
    Service.Internal.RestorePreviousOrder(session, worker.npcId)
    return true
end

function Executor.Complete(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    if session then
        local worker = workerFor(session, lease.npcId)
        worker.leaseId = nil
        worker.phase = "IDLE"
        Service.Internal.RestorePreviousOrder(session, worker.npcId)
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(Const.ORDER_SCAVENGE,
        function(_, spec)
            return { kind = Const.ORDER_SCAVENGE,
                sessionId = tostring(spec.sessionId or "") }
        end)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(Const.ORDER_SCAVENGE, "Scavenge")
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register("Scavenge", function(record, body, _, now)
        local companion = PNC.BehaviorCompanion
        local internal = companion and companion.Internal or nil
        local runtime = record and record.runtime or nil
        if not internal or not record or not body then return true end
        if runtime and (runtime.recentThreat or runtime.zombieAttacker
            or runtime.target and runtime.target.immediateSelfDefense == true)
            and internal.TryRespondToImmediateThreat
            and internal.TryRespondToImmediateThreat(record, body)
        then return true end
        now = tonumber(now) or PNC.Core.Now()
        if internal.ShouldScanFollowThreat
            and internal.ShouldScanFollowThreat(record, now, true)
            and internal.TryRespondToThreat
            and internal.TryRespondToThreat(record, body, {
                x = record.x, y = record.y,
                radius = tonumber(Const.FOLLOW_COMBAT_LEASH_DISTANCE) or 5.5,
            })
        then return true end
        return true
    end)
end
PNC.Tasking.Commands.RegisterProvider("scavenge", Executor)

return Executor

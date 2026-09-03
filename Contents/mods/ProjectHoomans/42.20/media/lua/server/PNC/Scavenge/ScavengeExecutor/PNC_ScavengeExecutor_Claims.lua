if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.ScavengeExecutor
local Internal = Executor.Internal
local Service = PNC.ScavengeService
local Const = PNC.Const
local LOOT_SCENE_DURATION_MS = Internal.LOOT_SCENE_DURATION_MS

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
            worker.lastFailure = nil
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
    worker.lastFailure = nil
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
    worker.actionStartedAt = PNC.Core.Now()
    worker.actionUntil = worker.actionStartedAt + LOOT_SCENE_DURATION_MS
    worker.actionScene = sceneId
    setWorkerPhase(session, worker,
        worker.currentKind == "search" and "SEARCHING_SOURCE" or "LOOTING",
        "WORKING")
    Service.Internal.Activity(session,
        worker.currentKind == "search" and "SEARCHING" or "TAKING",
        worker.currentEntry or {
            entryId = worker.currentSource.sourceToken,
            sourceType = worker.currentSource.sourceType,
            sourceLabel = worker.currentSource.sourceLabel
                or worker.currentSource.label,
        }, {
            npcId = worker.npcId,
            sceneId = sceneId,
            sourceLabel = worker.currentSource.sourceLabel
                or worker.currentSource.label,
        })
end

local function clearWorkerAction(worker)
    worker.currentKind = nil
    worker.currentSource = nil
    worker.currentGroup = nil
    worker.currentEntry = nil
    worker.actionUntil = nil
    worker.actionStartedAt = nil
    worker.actionScene = nil
end

local function combatBlockReason(record)
    local runtime = record and record.runtime or nil
    local now = PNC.Core.Now()
    if not runtime then return nil end
    if runtime.target ~= nil then return "combat_target" end
    if runtime.attackAction ~= nil then return "attack_action" end
    if now < (tonumber(runtime.inCombatUntil) or 0) then
        return "combat_hold"
    end
    local recent = runtime.recentThreat
    if recent and now <= (tonumber(recent.expiresAt) or 0) then
        return "recent_threat"
    end
    local observed = runtime.zombieAttacker
    local observedAge = observed
        and now - (tonumber(observed.observedAt) or 0) or math.huge
    if observed and observedAge <= (tonumber(Const.ZOMBIE_ATTACKER_OBSERVATION_MS)
        or 1500)
    then return "zombie_attacker" end
    return nil
end

Internal.WorkerFor = workerFor
Internal.SetWorkerPhase = setWorkerPhase
Internal.ItemWeight = itemWeight
Internal.CanCarryEntry = canCarryEntry
Internal.QueuedEntries = queuedEntries
Internal.TeamCanClaim = teamCanClaim
Internal.ClaimQueuedEntry = claimQueuedEntry
Internal.ClaimSearchSource = claimSearchSource
Internal.BeginLootScene = beginLootScene
Internal.ClearWorkerAction = clearWorkerAction
Internal.CombatBlockReason = combatBlockReason

return Executor

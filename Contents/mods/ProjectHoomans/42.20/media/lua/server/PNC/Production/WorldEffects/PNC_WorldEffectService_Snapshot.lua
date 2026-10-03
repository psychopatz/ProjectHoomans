-- Bounded world-effect diagnostics snapshots.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.WorldEffectService
local Internal = Service.Internal
local now = Internal.Now
local copy = Internal.Copy
local effectsFor = Internal.EffectsFor
local ownerIDFor = Internal.OwnerIDFor
local pointsFor = Internal.PointsFor
local listProviderOwners = Internal.ListProviderOwners

local function endpointSnapshot(point)
    local loaded, reason = Service.IsPointLoaded(point.x, point.y, point.z)
    return {
        role = point.role, x = point.x, y = point.y, z = point.z,
        loaded = loaded, loadReason = reason,
    }
end

local function debugRow(providerID, provider, owner, effect)
    local ownerID = ownerIDFor(providerID, provider, owner)
    local points = pointsFor(providerID, provider, owner, effect)
    local endpoints = {}
    for _, point in ipairs(points) do
        endpoints[#endpoints + 1] = endpointSnapshot(point)
    end
    local workerID = effect.workerID or owner.workerId or owner.npcId
    local worker = workerID and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerID) or nil
    local required
    local progress
    local debugRemaining
    local debugMaximum
    local effectKind = tostring(effect.kind or "")
    if effectKind == "LUMBER_OUTPUT" then
        required = math.max(1, tonumber(effect.totalQuantity)
            or tonumber(effect.quantity) or 1)
        progress = 0
        for _, item in ipairs(effect.items or {}) do
            if item.delivered then
                progress = progress + math.max(1,
                    math.floor(tonumber(item.quantity) or 1))
            end
        end
        progress = math.min(required, progress)
    elseif tostring(providerID or "") == "LUMBER"
        and (effectKind == "TREE_REMOVE" or effectKind == "LUMBER_WORK")
    then
        required = math.max(1, tonumber(effect.requiredWork)
            or tonumber(effect.maxWork) or tonumber(owner.maxWork) or 1)
        local remaining = tonumber(effect.remainingWork)
            or tonumber(owner.remainingWork)
        progress = tonumber(effect.progress)
        if progress == nil and remaining ~= nil then
            progress = required - math.max(0, math.min(required, remaining))
        end
        progress = math.max(0, math.min(required, progress or 0))
        debugRemaining = effect.remainingWork
            or (effectKind == "TREE_REMOVE" and owner.remainingWork or nil)
        debugMaximum = effect.maxWork
            or (effectKind == "TREE_REMOVE" and owner.maxWork or nil)
    else
        required = math.max(1, tonumber(owner.requiredWork) or 1)
        progress = math.max(0, math.min(required,
            tonumber(owner.progress) or 0))
    end
    return {
        effectId = tostring(effect.id or effect.effectId or ""),
        providerID = tostring(providerID), ownerID = ownerID,
        operation = owner.operation or effect.operation,
        kind = effect.kind, state = effect.state or "PENDING",
        orderStatus = owner.status, workerID = workerID,
        workerName = worker and (worker.name or worker.fullName
            or worker.displayName) or nil,
        progress = progress, requiredWork = required,
        percent = math.floor(progress / required * 100 + 0.5),
        priority = owner.priority, createdAt = effect.createdAt,
        updatedAt = effect.updatedAt, appliedAt = effect.appliedAt,
        attempts = tonumber(effect.attempts) or 0,
        nextRetryAt = effect.nextRetryAt,
        waitReason = effect.waitReason, lastReason = effect.lastReason,
        lastAttemptAt = effect.lastAttemptAt,
        phase = effect.phase,
        treeKey = effect.treeKey,
        destinationNodeId = effect.destinationNodeId,
        destinationStorageId = effect.destinationStorageId,
        sourceMode = effect.sourceMode,
        activityItemFullType = effect.activityItemFullType,
        deliveryMode = effect.deliveryMode,
        lootSource = effect.lootSource,
        pickupState = effect.pickupState,
        remainingWork = debugRemaining,
        maxWork = debugMaximum,
        debugOnly = effect.debugOnly == true,
        quantity = effect.quantity,
        actualQuantity = effect.actualQuantity or effect.totalQuantity,
        expectedLogYield = effect.expectedLogYield,
        items = copy(effect.items),
        endpoints = endpoints,
        identity = copy(effect.identity or {
            haulToken = effect.haulToken,
            deathMarkerId = effect.deathMarkerId,
            treeKey = effect.treeKey,
            signature = effect.signature,
        }),
    }
end

function Service.BuildSnapshot(options)
    options = type(options) == "table" and options or {}
    local requestedState = options.state and tostring(options.state) or nil
    local requestedKind = options.kind and tostring(options.kind) or nil
    local limit = math.max(1, math.min(500,
        math.floor(tonumber(options.limit) or 100)))
    local rows, matched, summary = {}, 0, {
        total = 0, pending = 0, applied = 0, conflict = 0, failed = 0,
        cancelled = 0,
    }
    for providerID, provider in pairs(Service.Providers) do
        for _, owner in ipairs(listProviderOwners(provider)) do
            for _, effect in ipairs(effectsFor(provider, owner)) do
                if type(effect) == "table" then
                    local state = tostring(effect.state or "PENDING")
                    summary.total = summary.total + 1
                    summary[string.lower(state)] =
                        (summary[string.lower(state)] or 0) + 1
                    local kindMatches = not requestedKind
                        or requestedKind == tostring(effect.kind or "")
                    if requestedKind == "LUMBER" then
                        kindMatches = tostring(providerID) == "LUMBER"
                    end
                    if (not requestedState or requestedState == "ALL"
                        or requestedState == state)
                        and kindMatches
                    then
                        matched = matched + 1
                        rows[#rows + 1] = debugRow(providerID, provider,
                            owner, effect)
                    end
                end
            end
        end
    end
    table.sort(rows, function(left, right)
        local leftPending = left.state == "PENDING" and 0 or 1
        local rightPending = right.state == "PENDING" and 0 or 1
        if leftPending ~= rightPending then return leftPending < rightPending end
        return tostring(left.effectId) < tostring(right.effectId)
    end)
    while #rows > limit do rows[#rows] = nil end
    -- Husk lifecycle diagnostics ride the same on-demand snapshot, so the debug
    -- window shows them in singleplayer (host builds it directly) and in
    -- multiplayer (the authority builds it and the client renders the payload)
    -- without a second command. Opt-in via `includeHusks` because this builder
    -- also feeds gameplay payloads, which must not pay for the census. Bounded
    -- and pcall-guarded: a debug payload must never fail because of an optional
    -- subsystem.
    local husks
    if options.includeHusks == true
        and PNC.BodyLifecycle
        and type(PNC.BodyLifecycle.BuildHuskDebugSnapshot) == "function"
    then
        local ok, snapshot = pcall(PNC.BodyLifecycle.BuildHuskDebugSnapshot, {
            entryLimit = 12,
            outfitLimit = 6,
        })
        if ok then husks = snapshot end
    end
    return {
        schemaVersion = Service.SCHEMA_VERSION, serverTime = now(),
        summary = summary, rows = rows, truncated = matched > #rows,
        filter = { state = requestedState or "PENDING", kind = requestedKind },
        husks = husks,
    }
end

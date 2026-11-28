local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local ServerState = Network.ServerState
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

Network.Metrics = Network.Metrics or {
    presenceDeltas = 0,
    combatDamageDeltas = 0,
    combatStateDeltas = 0,
    healthWoundsDeltas = 0,
    equipmentDeltas = 0,
    fullSnapshots = 0,
    repairSnapshots = 0,
    fallbackSnapshots = 0,
}

local REPAIR_EVENTS = {
    repair = true,
    gap_repair = true,
    reconnect = true,
    unsupported_delta = true,
    missing_baseline = true,
    incarnation_mismatch = true,
}

local MICRO_ROSTER_SKIP_EVENTS = {
    tick = true,
    materialize = true,
    interest_enter = true,
    attack_start = true,
    attack_hit = true,
    attack_finish = true,
    reload_finished = true,
    weapon_restore_ranged = true,
    weapon_fallback_melee = true,
    weapon_fallback_shove = true,
    animation_scene = true,
    animation_scene_debug = true,
    body_online_id = true,
    position_recovery = true,
    grounded_recovery = true,
}

local function hasHostedLocalPlayer()
    local count
    local i
    if type(getNumActivePlayers) ~= "function"
        or type(getSpecificPlayer) ~= "function"
    then
        return false
    end
    count = tonumber(getNumActivePlayers()) or 0
    for i = 0, count - 1 do
        if getSpecificPlayer(i) then return true end
    end
    return false
end

local function recordPayloadDiagnostics(eventName, deltaKind)
    local eventKey = tostring(eventName or "unknown")
    local metrics = Network.Metrics
    if eventKey == "" then eventKey = "unknown" end
    local kind = tostring(deltaKind or "full")
    if metrics then
        if kind == "presence" then
            metrics.presenceDeltas = (tonumber(metrics.presenceDeltas) or 0) + 1
        elseif kind == "combat_damage" then
            metrics.combatDamageDeltas =
                (tonumber(metrics.combatDamageDeltas) or 0) + 1
        elseif kind == "combat_state" then
            metrics.combatStateDeltas =
                (tonumber(metrics.combatStateDeltas) or 0) + 1
        elseif kind == "health_wounds" then
            metrics.healthWoundsDeltas =
                (tonumber(metrics.healthWoundsDeltas) or 0) + 1
        elseif kind == "equipment" then
            metrics.equipmentDeltas =
                (tonumber(metrics.equipmentDeltas) or 0) + 1
        else
            metrics.fullSnapshots = (tonumber(metrics.fullSnapshots) or 0) + 1
            if REPAIR_EVENTS[eventKey] then
                metrics.repairSnapshots =
                    (tonumber(metrics.repairSnapshots) or 0) + 1
            end
        end
    end
    if not ScalingDiagnostics
        or type(ScalingDiagnostics.Increment) ~= "function"
        or ScalingDiagnostics.Enabled == false
    then
        return
    end
    if kind == "presence" then
        ScalingDiagnostics.Increment("Network.PayloadBuild.PresenceDelta")
    elseif kind == "combat_damage" then
        ScalingDiagnostics.Increment(
            "Network.PayloadBuild.CombatDamageDelta"
        )
    elseif kind == "combat_state" then
        ScalingDiagnostics.Increment("Network.PayloadBuild.CombatStateDelta")
    elseif kind == "health_wounds" then
        ScalingDiagnostics.Increment("Network.PayloadBuild.HealthWoundsDelta")
    elseif kind == "equipment" then
        ScalingDiagnostics.Increment("Network.PayloadBuild.EquipmentDelta")
    else
        ScalingDiagnostics.Increment("Network.PayloadBuild.FullSnapshot")
    end
    ScalingDiagnostics.Increment(
        "Network.PayloadBuild.Event." .. eventKey
    )
end

function Network.QueueRosterSnapshot(id, snapshot, removed, reason)
    if id == nil then return false end
    if removed ~= true and type(snapshot) ~= "table" then return false end
    id = tostring(id)
    ServerState.rosterRevision = (tonumber(ServerState.rosterRevision) or 0) + 1
    ServerState.hasRosterDeltas = true
    ServerState.rosterDeltas[id] = {
        id = id,
        removed = removed == true,
        reason = reason,
        revision = ServerState.rosterRevision,
        snapshot = snapshot,
    }
    return true
end

local function queueDeferredRoster(record, reason, includeTravelRoute)
    local id = record and record.id or nil
    if id == nil then
        return false
    end
    id = tostring(id)
    ServerState.rosterRevision = (tonumber(ServerState.rosterRevision) or 0) + 1
    -- Periodic roster state is coalesced by NPC id until the next flush. Keep
    -- the authoritative record here and materialize only the latest state at
    -- flush time; never let this server-only reference enter the payload.
    ServerState.hasRosterDeltas = true
    ServerState.rosterDeltas[id] = {
        id = id,
        removed = false,
        reason = reason,
        revision = ServerState.rosterRevision,
        record = record,
        deferred = true,
        includeTravelRoute = includeTravelRoute ~= false,
    }
    return true
end

function Network.QueueRosterDelta(record, removed, reason, includeTravelRoute)
    if removed == true then
        local id = type(record) == "table" and record.id or record
        return Network.QueueRosterSnapshot(id, nil, true, reason)
    end
    if type(record) ~= "table" then return false end
    return queueDeferredRoster(record, reason, includeTravelRoute)
end

function Network.QueuePeriodicRoster(record, now)
    local runtime
    local signature
    if not record or not record.id then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    now = tonumber(now) or Core.Now()
    signature = table.concat({
        tostring(math.floor(tonumber(record.x) or 0)),
        tostring(math.floor(tonumber(record.y) or 0)),
        tostring(math.floor(tonumber(record.z) or 0)),
        tostring(record.presenceState or ""),
        tostring(record.health and record.health.state or ""),
        tostring(record.orderSpec and record.orderSpec.kind or ""),
        tostring(record.travel and record.travel.state or ""),
        tostring(record.travel and record.travel.revision or 0),
    }, ":")
    if runtime.rosterSignature == signature then
        return false
    end
    if now - (tonumber(runtime.lastRosterQueuedAt) or 0) < Const.ROSTER_DELTA_INTERVAL_MS then
        return false
    end
    runtime.rosterSignature = signature
    runtime.lastRosterQueuedAt = now
    return queueDeferredRoster(record, "periodic", false)
end

local function collectVisibleIDs(player, state)
    local Spatial = PNC.SpatialIndex
    local candidates = Spatial and Spatial.QueryNPCs
        and Spatial.QueryNPCs(
            player:getX(),
            player:getY(),
            Const.INTEREST_LEAVE_DISTANCE
        )
        or {}
    local nextIDs = {}
    local i
    local record
    local distance
    for i = 1, #candidates do
        record = candidates[i]
        if record and record.id and record.alive ~= false then
            distance = Core.Distance(
                player:getX(),
                player:getY(),
                record.x,
                record.y
            )
            if (
                state.ids[record.id]
                    and distance <= Const.INTEREST_LEAVE_DISTANCE
            ) or distance <= Const.INTEREST_ENTER_DISTANCE
            then
                nextIDs[record.id] = true
                if not state.ids[record.id] then
                    local enterSnapshot = Network.BuildSnapshot(
                        record,
                        nil,
                        Internal.UsesLeanRosterPortraits(player)
                    )
                    if type(Network.StampDomainMetadata) == "function" then
                        Network.StampDomainMetadata(
                            record,
                            enterSnapshot,
                            "full",
                            false
                        )
                    end
                    recordPayloadDiagnostics("interest_enter", "full")
                    Internal.SendToPlayer(
                        player,
                        Const.CMD_SYNC_RECORD,
                        {
                            event = "interest_enter",
                            directoryRevision = ServerState.rosterRevision,
                            snapshot = enterSnapshot,
                        }
                    )
                end
            end
        end
    end
    return nextIDs
end

local function sendInterestExits(player, previousIDs, nextIDs)
    local id
    local record
    for id in pairs(previousIDs) do
        if not nextIDs[id] then
            record = PNC.Registry
                and PNC.Registry.Get
                and PNC.Registry.Get(id)
                or nil
            if record then
                Internal.SendToPlayer(
                    player,
                    Const.CMD_SYNC_RECORD,
                    {
                        event = "interest_exit",
                        directoryRevision = ServerState.rosterRevision,
                        snapshot = Network.BuildRosterSnapshot(record, true,
                            Internal.UsesLeanRosterPortraits(player)),
                    }
                )
            end
        end
    end
end

local function refreshPlayerInterest(player, seenPlayers)
    local key = Internal.PlayerKey(player)
    local state = ServerState.interests[key] or { ids = {} }
    local nextIDs = collectVisibleIDs(player, state)
    state.player = player
    seenPlayers[key] = true
    sendInterestExits(player, state.ids, nextIDs)
    state.ids = nextIDs
    ServerState.interests[key] = state
end

function Network.RefreshInterestSets(now)
    local seenPlayers = {}
    local key
    now = tonumber(now) or Core.Now()
    if not isServer
        or not isServer()
        or now - (tonumber(ServerState.lastInterestRefreshAt) or 0)
            < Const.INTEREST_REFRESH_MS
    then
        return
    end
    ServerState.lastInterestRefreshAt = now
    Core.ForEachPlayer(function(player)
        refreshPlayerInterest(player, seenPlayers)
    end)
    for key in pairs(ServerState.interests) do
        if not seenPlayers[key] then
            ServerState.interests[key] = nil
        end
    end
    Internal.PruneRosterPortraitCapabilities(ServerState.interests)
end

local function buildRosterDelta(entries, leanPortrait)
    local output = {}
    local registry = PNC.Registry
    local records = registry and registry.Data
    for _, queued in pairs(entries) do
        local entry = queued
        if queued.deferred == true then
            local snapshot
            local record = records and records[queued.id]
                or registry and registry.RuntimeViews and registry.RuntimeViews[queued.id]
            if not records or record == queued.record then
                snapshot = Network.BuildRosterSnapshot(
                    queued.record, queued.includeTravelRoute ~= false, leanPortrait)
            end
            entry = snapshot and {
                id = queued.id,
                removed = false,
                reason = queued.reason,
                revision = queued.revision,
                snapshot = snapshot,
            }
        end
        if entry then output[#output + 1] = entry end
    end
    return { directoryRevision = ServerState.rosterRevision, entries = output }
end

function Network.FlushRosterDeltas(now, force)
    now = tonumber(now) or Core.Now()
    if not force and now - (tonumber(ServerState.lastRosterFlushAt) or 0)
        < Const.ROSTER_DELTA_INTERVAL_MS
    then
        return 0
    end
    Internal.FlushPortraitInvalidations()
    local entries = ServerState.rosterDeltas
    ServerState.rosterDeltas = {}
    ServerState.lastRosterFlushAt = now
    if not ServerState.hasRosterDeltas then return 0 end
    ServerState.hasRosterDeltas = false

    local legacy, lean
    local function getPayload(usesLean)
        if usesLean then
            lean = lean or buildRosterDelta(entries, true)
            return lean
        end
        legacy = legacy or buildRosterDelta(entries, false)
        return legacy
    end
    local serverMode = isServer and isServer() == true
    if serverMode then
        Core.ForEachPlayer(function(player)
            local payload = getPayload(Internal.UsesLeanRosterPortraits(player))
            if #payload.entries > 0 then
                Internal.SendToPlayer(player, Const.CMD_ROSTER_DELTA, payload)
            end
        end)
    end
    -- Keep local startup/host notifications on the same unified lean payload path.
    if triggerEvent and ((not serverMode) or hasHostedLocalPlayer()) then
        local payload = getPayload(true)
        if #payload.entries > 0 then
            triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_ROSTER_DELTA, payload)
        end
    end
    local payload = legacy or lean
    return payload and #payload.entries or 0
end

function Internal.QueueBroadcastRoster(record, eventName)
    local key = tostring(eventName or "")
    if not MICRO_ROSTER_SKIP_EVENTS[key] then
        -- BroadcastRecord immediately builds the detailed payload. Defer the
        -- separate compact roster snapshot until the coalesced roster flush
        -- instead of constructing both snapshots back-to-back.
        return queueDeferredRoster(record, eventName, false)
    end
    return false
end

function Internal.CollectRecordRecipients(record)
    local recipients = {}
    local state
    if isServer and isServer() then
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[record.id] then
                recipients[#recipients + 1] = state.player
            end
        end
    end
    return recipients
end

function Internal.BuildRecordPayload(record, eventName, leanPortrait, forceFull)
    local deltaKind = "full"
    if forceFull ~= true then
        if type(Network.ResolveEventDeltaKind) == "function" then
            deltaKind = Network.ResolveEventDeltaKind(eventName)
        elseif eventName == "tick" then
            deltaKind = "presence"
        elseif eventName == "combat_damage" then
            deltaKind = "combat_damage"
        end
    end

    local snapshot
    if type(Network.BuildDomainDelta) == "function" then
        snapshot = Network.BuildDomainDelta(record, deltaKind, leanPortrait)
    elseif deltaKind == "presence"
        and type(Network.BuildPresenceDelta) == "function"
    then
        snapshot = Network.BuildPresenceDelta(record)
    elseif deltaKind == "combat_damage"
        and type(Network.BuildCombatDamageDelta) == "function"
    then
        snapshot = Network.BuildCombatDamageDelta(record)
    else
        deltaKind = "full"
        snapshot = Network.BuildSnapshot(record, nil, leanPortrait)
    end

    recordPayloadDiagnostics(eventName, snapshot and snapshot.deltaKind or deltaKind)
    return {
        event = eventName or "update",
        directoryRevision = ServerState.rosterRevision,
        snapshot = snapshot,
    }
end

function Internal.SendRecordPayload(recipients, payload)
    if isServer and isServer() then
        local i
        for i = 1, #recipients do
            Internal.SendToPlayer(recipients[i], Const.CMD_SYNC_RECORD, payload)
        end
        return #recipients
    end
    triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_SYNC_RECORD, payload)
    return 1
end

function Network.InstallServerProfilerWrappers(wrap)
    if type(wrap) ~= "function" then return end
    wrap(Internal, "QueueBroadcastRoster",
        "Network.BroadcastRecord.QueueRoster")
    wrap(Internal, "CollectRecordRecipients",
        "Network.BroadcastRecord.FindRecipients")
    wrap(Internal, "BuildRecordPayload",
        "Network.BroadcastRecord.BuildPayload")
    wrap(Internal, "SendRecordPayload",
        "Network.BroadcastRecord.SendPayload")
end

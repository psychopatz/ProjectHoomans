-- Client lifecycle start/heartbeat support; close has its own public operation.
local Lifecycle = PNC.Conversation.Lifecycle
local H = Lifecycle.Internal
local Safety = H.Safety
local Scene = H.Scene
local isNetworkClient = H.IsNetworkClient
local send = H.Send

local NAMEPLATE_UNAVAILABLE_GRACE_MS = 3000

local function currentTime()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
end

local function isNameplateConversation(spec)
    return spec and spec.context
        and spec.context.nameplateConversation == true
end

local function isHostileConversation(spec)
    local context = spec and spec.context or {}
    local entry = context.entry or {}
    local snapshot = entry.snapshot or {}
    local entryRecord = entry.record or {}
    local hostility = snapshot.hostility or entryRecord.hostility or {}
    if hostility.attackPlayers == true then return true end
    local _, _, record = Safety.ResolveActors(spec)
    return record and record.hostility
        and record.hostility.attackPlayers == true or false
end

local function requestNameplateFallback(view, spec, reason)
    if isNameplateConversation(spec) or not isHostileConversation(spec) then
        return false
    end
    local integration = PNC.PBrainZ
    if not integration or not integration.RequestInlineFallback then
        return false
    end
    local context = spec and spec.context or {}
    local entry = context.entry or {
        id = spec and spec.npcID,
        zombie = spec and spec.character,
    }
    return integration.RequestInlineFallback(entry, reason, view) == true
end

local function refresh(state, spec)
    local player, zombie, record = Safety.ResolveActors(spec)
    if isNetworkClient() then
        return send(Scene.CMD_BEGIN, state)
    end
    if not Scene or type(Scene.Begin) ~= "function" then
        return false, "conversation_scene_unavailable"
    end
    -- Keep the authoritative rejection reason. A boolean `and/or` return
    -- expression would discard Scene.Begin's second return value in Lua,
    -- turning an expired lease into an opaque generic failure.
    return Scene.Begin(
        record,
        zombie,
        player,
        state.token,
        {
            maximumDistance = Safety.GetMaximumDistance(),
            dangerRadius = Safety.GetDangerRadius(),
            enforceDistance = state.enforceDistance == true
                and state.started ~= true,
            guardThreats = state.guardThreats ~= false,
            allowHostileParley = state.allowHostileParley == true,
        }
    )
end

local function refreshNow(view, spec, state)
    if not state then return false, "conversation_not_ready" end
    local renewed, reason = refresh(state, spec)
    if renewed ~= true then
        return false, reason or "conversation_lease_unavailable"
    end
    state.lastHeartbeatAt = currentTime()
    return true
end

local function logAvailability(state, spec, reason)
    if not Safety or not Safety.DescribeAvailability then return end
    local details = Safety.DescribeAvailability(spec)
    local signature = table.concat({
        tostring(reason or "available"),
        tostring(details.liveBodyPresent),
        tostring(details.liveBodyAlive),
        tostring(details.registryBodyPresent),
        tostring(details.presenceBodyPresent),
        tostring(details.presenceBodyAlive),
        tostring(details.cachedBodyPresent),
        tostring(details.snapshotPresent),
        tostring(details.snapshotAlive),
        tostring(details.snapshotPosition),
        tostring(details.snapshotConversation),
        tostring(details.networkClient),
        tostring(details.presenceState),
        tostring(details.recordAlive),
        tostring(details.bodyLease),
        tostring(details.presenceRevision),
    }, "|")
    if state and state.lastAvailabilitySignature == signature then
        return
    end
    if state then state.lastAvailabilitySignature = signature end
    if not PNC.Core or not PNC.Core.LogInfo then return end
    PNC.Core.LogInfo(table.concat({
        "Inline availability",
        "npc=" .. tostring(details.npcID),
        "reason=" .. tostring(reason or "available"),
        "liveBody=" .. tostring(details.liveBodyPresent),
        "liveAlive=" .. tostring(details.liveBodyAlive),
        "registryBody=" .. tostring(details.registryBodyPresent),
        "presenceBody=" .. tostring(details.presenceBodyPresent),
        "presenceAlive=" .. tostring(details.presenceBodyAlive),
        "cachedBody=" .. tostring(details.cachedBodyPresent),
        "snapshot=" .. tostring(details.snapshotPresent),
        "snapshotAlive=" .. tostring(details.snapshotAlive),
        "snapshotPosition=" .. tostring(details.snapshotPosition),
        "snapshotAllowed=" .. tostring(details.snapshotConversation),
        "networkClient=" .. tostring(details.networkClient),
        "presence=" .. tostring(details.presenceState),
        "recordAlive=" .. tostring(details.recordAlive),
        "bodyLease=" .. tostring(details.bodyLease),
        "presenceRevision=" .. tostring(details.presenceRevision),
    }, " "))
end

Lifecycle.Internal.CurrentTime = currentTime
Lifecycle.Internal.IsNameplateConversation = isNameplateConversation
Lifecycle.Internal.RequestNameplateFallback = requestNameplateFallback
Lifecycle.Internal.Refresh = refresh
Lifecycle.Internal.RefreshNow = refreshNow
Lifecycle.Internal.LogAvailability = logAvailability
Lifecycle.Internal.NameplateUnavailableGraceMs = NAMEPLATE_UNAVAILABLE_GRACE_MS


return Lifecycle

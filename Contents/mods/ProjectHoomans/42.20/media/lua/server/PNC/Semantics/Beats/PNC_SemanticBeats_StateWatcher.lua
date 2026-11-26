-- Consolidated, actor-agnostic State-Mutation & Remediation Watcher.
-- Tracks problem onset -> arming (with anti-flicker hysteresis) -> remediation
-- relief beats across world, group (player-led OR AI-controlled), and individual
-- NPC scopes on the existing CheckEnvironment cadence (zero per-tick polling).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local MAX_WATCHERS = 32
local MAX_STATE_ENTRIES = 64
local DEFAULT_MIN_ACTIVE_MS = 10000
local DEFAULT_REMEDIATE_WINDOW_MS = 600000
local DEFAULT_ONSET_COOLDOWN_MS = 120000
local DEFAULT_REMEDIATE_COOLDOWN_MS = 120000
local GROUP_SEARCH_RADIUS = 18

local watchers = {}
local watcherOrder = {}
local states = {}
local stateOrder = {}
local transitionCount = 0

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function auditEnabled()
    return type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
end

local function getOrCreateState(key)
    local entry = states[key]
    if entry ~= nil then return entry end
    while #stateOrder >= MAX_STATE_ENTRIES do
        local oldest = table.remove(stateOrder, 1)
        states[oldest] = nil
    end
    stateOrder[#stateOrder + 1] = key
    entry = {
        active = false,
        activeSinceAt = 0,
        armed = false,
        armedAt = 0,
        variantKey = nil,
        lastOnsetAt = -math.huge,
        lastRemediateAt = -math.huge,
    }
    states[key] = entry
    return entry
end

function Beats.RegisterStateWatcher(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table" or type(spec.sample) ~= "function" then
        return false
    end
    if not watchers[id] then
        if #watcherOrder >= MAX_WATCHERS then return false end
        watcherOrder[#watcherOrder + 1] = id
    end
    watchers[id] = {
        id = id,
        scope = tostring(spec.scope or "group"), -- "world" | "group" | "actor"
        priority = tonumber(spec.priority) or 30,
        minActiveMs = tonumber(spec.minActiveMs) or DEFAULT_MIN_ACTIVE_MS,
        onsetDelayMs = tonumber(spec.onsetDelayMs) or 0,
        remediateWindowMs = tonumber(spec.remediateWindowMs) or DEFAULT_REMEDIATE_WINDOW_MS,
        onsetCooldownMs = tonumber(spec.onsetCooldownMs) or DEFAULT_ONSET_COOLDOWN_MS,
        remediateCooldownMs = tonumber(spec.remediateCooldownMs) or DEFAULT_REMEDIATE_COOLDOWN_MS,
        sample = spec.sample,
        onset = type(spec.onset) == "table" and spec.onset or nil,
        remediate = type(spec.remediate) == "table" and spec.remediate or nil,
    }
    return true
end

function Beats.UnregisterStateWatcher(id)
    id = tostring(id or "")
    if not watchers[id] then return false end
    watchers[id] = nil
    for i = #watcherOrder, 1, -1 do
        if watcherOrder[i] == id then table.remove(watcherOrder, i) end
    end
    return true
end

function Beats.ListStateWatchers()
    local out = {}
    for i = 1, #watcherOrder do out[i] = watcherOrder[i] end
    return out
end

Beats.RegisterHook("environment.state_watcher", {
    eventTypes = { "environment.state_watcher" },
    priority = 32,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local poolID = tostring(payload.poolID or "")
        local rolePrefix = tostring(payload.rolePrefix or "")
        if poolID == "" or rolePrefix == "" then return nil end
        local a = payload.anchor or payload.speaker
        if type(a) ~= "table" or a.alive == false then return nil end
        local b = payload.partner or payload.addressee
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "watcher:" .. tostring(payload.watcherID or "state") .. ":" .. tostring(payload.phase or "ev"),
            family = "state_watcher_" .. tostring(payload.watcherID or "state") .. "_" .. tostring(payload.phase or "ev"),
            poolID = poolID,
            eventType = tostring(payload.eventType or "world_state_watcher_beat"),
            domain = tostring(payload.domain or "weather"),
            channel = tostring(payload.channel or "weather"),
            topic = tostring(payload.topic or "weather"),
            openAct = tostring(payload.openAct or "REACT"),
            replyAct = tostring(payload.replyAct or "AGREE"),
            openRole = rolePrefix .. "_open",
            replyRole = rolePrefix .. "_reply",
            chimeRole = rolePrefix .. "_chime",
            third = payload.third,
            openingDelayMs = payload.openingDelayMs,
            priority = tonumber(payload.priority) or 32,
            delayMs = 1000,
            chimeDelayMs = 2250,
        })
    end,
})

local function recordStoryMomentIfConfigured(phaseSpec, groupKey, speaker, now)
    if type(phaseSpec) ~= "table" or not phaseSpec.storyKind then return end
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if Dir and type(Dir.RecordStoryMoment) == "function" and groupKey then
        Dir.RecordStoryMoment(groupKey, {
            kind = tostring(phaseSpec.storyKind),
            topic = tostring(phaseSpec.storyTopic or "weather_talk"),
            actorID = speaker and speaker.id or nil,
            salience = tonumber(phaseSpec.storySalience) or 56,
        }, now)
    end
end

local function emitWatcherBeat(watcher, phase, phaseSpec, variantKey, group, actor, now)
    if type(phaseSpec) ~= "table" or not phaseSpec.poolID then return false, "no_spec" end
    local rolePrefix = tostring(phaseSpec.rolePrefix or variantKey or "")
    if rolePrefix == "" then return false, "no_role_prefix" end

    local basePayload = {
        watcherID = watcher.id,
        phase = phase,
        poolID = phaseSpec.poolID,
        rolePrefix = rolePrefix,
        eventType = phaseSpec.eventType or "world_state_watcher_beat",
        domain = phaseSpec.domain or "weather",
        channel = phaseSpec.channel or "weather",
        topic = phaseSpec.topic or "weather",
        openAct = phaseSpec.act or (phase == "onset" and "SUGGEST" or "REACT"),
        replyAct = phaseSpec.replyAct or "AGREE",
        priority = tonumber(phaseSpec.priority) or watcher.priority,
        usePlayerProximity = true,
    }

    local ok, reason
    local speaker = actor
    if type(group) == "table" and type(group.members) == "table" and #group.members > 0 then
        local a = actor or group.members[1]
        local b, c = nil, nil
        for i = 1, #group.members do
            local m = group.members[i]
            if m ~= a then
                if not b then b = m
                elseif not c then c = m break end
            end
        end
        speaker = a
        basePayload.anchor = a
        basePayload.speaker = a
        basePayload.partner = b
        basePayload.third = c
        ok, reason = Beats.Emit("environment.state_watcher", basePayload, now)
        if ok then
            recordStoryMomentIfConfigured(phaseSpec, group.key, speaker, now)
        end
        return ok == true, reason
    end

    ok, reason = Beats.EmitForNearbyGroups("environment.state_watcher", basePayload, now, GROUP_SEARCH_RADIUS, 2)
    if ok then
        recordStoryMomentIfConfigured(phaseSpec, "world:nearby", speaker, now)
    end
    return ok == true, reason
end

local function logTransition(watcherID, scopeKey, phase, variantKey, dwellMs, decision, reason)
    transitionCount = transitionCount + 1
    if not auditEnabled() then return end
    Beats.AuditLog("watcher_transition", {
        "id=" .. tostring(watcherID),
        "scopeKey=" .. tostring(scopeKey),
        "phase=" .. tostring(phase),
        "variant=" .. tostring(variantKey or "nil"),
        "dwellMs=" .. tostring(math.floor(tonumber(dwellMs) or 0)),
        "decision=" .. tostring(decision),
        "reason=" .. tostring(reason or "ok"),
    })
end

local function evaluateOne(watcher, stateKey, scopeKey, sampleCtx, group, actor, now)
    local okSample, isActive, variantKey, sampleReason = pcall(watcher.sample, sampleCtx, now)
    if not okSample then return false end
    isActive = isActive == true

    local entry = states[stateKey]
    -- Zero-allocation steady-state fast path when inactive and never tracked.
    if not isActive and (entry == nil or (not entry.active and not entry.armed)) then
        return false
    end

    entry = getOrCreateState(stateKey)

    if isActive then
        if not entry.active then
            entry.active = true
            entry.activeSinceAt = now
            entry.variantKey = variantKey or entry.variantKey
        elseif variantKey ~= nil then
            entry.variantKey = variantKey
        end

        local dwellMs = math.max(0, now - (tonumber(entry.activeSinceAt) or now))
        local emitted = false

        -- Optional onset beat (e.g. "We're soaking wet—can't we duck inside?")
        if watcher.onset ~= nil
            and dwellMs >= watcher.onsetDelayMs
            and now >= (entry.lastOnsetAt + watcher.onsetCooldownMs)
        then
            local okEmit, emitReason = emitWatcherBeat(
                watcher, "onset", watcher.onset, entry.variantKey, group, actor, now
            )
            if okEmit then
                entry.lastOnsetAt = now
                entry.armed = true
                entry.armedAt = now
                emitted = true
            end
            logTransition(
                watcher.id, scopeKey, "onset", entry.variantKey, dwellMs,
                okEmit and "emit" or "skip", okEmit and (sampleReason or "ok") or (emitReason or "blocked")
            )
        end

        -- Arm remediation passively once dwell hysteresis is satisfied.
        if not entry.armed and dwellMs >= watcher.minActiveMs then
            entry.armed = true
            entry.armedAt = now
            logTransition(watcher.id, scopeKey, "armed", entry.variantKey, dwellMs, "arm", sampleReason or "hysteresis_met")
        end

        return emitted
    end

    -- Problem cleared (was active -> now inactive)
    local prevVariant = entry.variantKey
    local dwellMs = entry.active and math.max(0, now - (tonumber(entry.activeSinceAt) or now)) or 0
    entry.active = false

    if not entry.armed then
        if dwellMs > 0 then
            logTransition(watcher.id, scopeKey, "cleared_unarmed", prevVariant, dwellMs, "skip", "below_hysteresis")
        end
        return false
    end

    local armedAge = now - (tonumber(entry.armedAt) or now)
    entry.armed = false

    if armedAge > watcher.remediateWindowMs then
        logTransition(watcher.id, scopeKey, "expired", prevVariant, dwellMs, "skip", "window_expired")
        return false
    end
    if watcher.remediate == nil then
        return false
    end
    if now < (entry.lastRemediateAt + watcher.remediateCooldownMs) then
        logTransition(
            watcher.id, scopeKey, "remediated", prevVariant, dwellMs, "skip",
            "cooldown:" .. tostring(math.floor(entry.lastRemediateAt + watcher.remediateCooldownMs - now)) .. "ms"
        )
        return false
    end

    local okRem, remReason = emitWatcherBeat(
        watcher, "remediated", watcher.remediate, prevVariant, group, actor, now
    )
    if okRem then
        entry.lastRemediateAt = now
    end
    logTransition(
        watcher.id, scopeKey, "remediated", prevVariant, dwellMs,
        okRem and "emit" or "skip", okRem and (sampleReason or "cleared") or (remReason or "blocked")
    )
    return okRem
end

function Beats.CheckStateWatchers(now)
    if #watcherOrder == 0 then return false end
    now = nowMs(now)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local env = (BC and type(BC.GetWorldWeather) == "function") and BC.GetWorldWeather(now) or {}
    local util = (BC and type(BC.GetWorldUtilities) == "function") and BC.GetWorldUtilities(now) or {}
    local groups = type(Beats.FindCalmGroupsNearPlayer) == "function"
        and Beats.FindCalmGroupsNearPlayer(now, 3, GROUP_SEARCH_RADIUS) or {}

    local groupExposureByKey = {}
    local anyEmitted = false

    for i = 1, #watcherOrder do
        local watcher = watchers[watcherOrder[i]]
        if watcher then
            if watcher.scope == "world" then
                local ctx = { env = env, util = util, now = now }
                if evaluateOne(watcher, watcher.id, "world", ctx, nil, nil, now) then
                    anyEmitted = true
                end
            elseif watcher.scope == "group" then
                for gi = 1, #groups do
                    local g = groups[gi]
                    local gKey = tostring(g.key or ("group:" .. tostring(gi)))
                    local exp = groupExposureByKey[gKey]
                    if exp == nil and BC and type(BC.GetGroupExposure) == "function" then
                        exp = BC.GetGroupExposure(g, env, now)
                        groupExposureByKey[gKey] = exp
                    end
                    local ctx = { env = env, util = util, exposure = exp or {}, group = g, now = now }
                    if evaluateOne(watcher, watcher.id .. "|" .. gKey, gKey, ctx, g, nil, now) then
                        anyEmitted = true
                    end
                end
            elseif watcher.scope == "actor" then
                for gi = 1, #groups do
                    local g = groups[gi]
                    local members = type(g.members) == "table" and g.members or {}
                    for mi = 1, #members do
                        local m = members[mi]
                        if type(m) == "table" and m.id ~= nil then
                            local st = (BC and type(BC.ResolveActorStats) == "function")
                                and BC.ResolveActorStats(m, { inCombat = false }, now) or {}
                            local ctx = { env = env, util = util, group = g, actor = m, stats = st, now = now }
                            local aKey = tostring(m.id)
                            if evaluateOne(watcher, watcher.id .. "|" .. aKey, aKey, ctx, g, m, now) then
                                anyEmitted = true
                            end
                        end
                    end
                end
            end
        end
    end

    return anyEmitted
end

function Beats.GetStateWatcherAuditState()
    local armedList = {}
    local activeList = {}
    for k, entry in pairs(states) do
        if entry.armed then armedList[#armedList + 1] = k end
        if entry.active then activeList[#activeList + 1] = k end
    end
    table.sort(armedList)
    table.sort(activeList)
    return {
        registeredCount = #watcherOrder,
        trackedEntries = #stateOrder,
        transitionCount = transitionCount,
        armedCount = #armedList,
        activeCount = #activeList,
        armed = #armedList > 0 and table.concat(armedList, ",") or "none",
        active = #activeList > 0 and table.concat(activeList, ",") or "none",
    }
end

function Beats.ResetStateWatcherRuntime()
    states = {}
    stateOrder = {}
    transitionCount = 0
end

return Beats

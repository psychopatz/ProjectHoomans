-- Extensible beat hook registry and threaded NPC conversation runner.
-- Transient beats only: never acts as an interactive scene engine or transcript store.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticBeatContext"
require "PNC/Semantics/PNC_SemanticAudienceContext"
require "PNC/Semantics/PNC_ConversationDirector"
local Transport = require "PNC/Semantics/PNC_SemanticSpeechTransport"

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

Beats.VERSION = 2
Beats.PendingTurns = Beats.PendingTurns or {}
Beats.PendingCount = tonumber(Beats.PendingCount) or #Beats.PendingTurns
Beats.NextDueAt = Beats.NextDueAt
Beats.NextEnvCheckAt = tonumber(Beats.NextEnvCheckAt) or 0
Beats.NextFloorAt = tonumber(Beats.NextFloorAt) or 0
Beats.FLOOR_GAP_MS = 1650
Beats.URGENT_PRIORITY = 60
Beats.LastWeather = Beats.LastWeather
Beats._seq = tonumber(Beats._seq) or 0
Beats.ActiveThreads = Beats.ActiveThreads or {}

local MAX_Q, MAX_THREADS = 32, 32
local hooks, hookCooldowns, threadOrder = {}, {}, {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function livePresenceValue()
    return tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
end

local function isActorAvailable(actor, registeredAtStart, reg)
    if type(actor) ~= "table" or actor.id == nil then return false, nil end
    local latest = (reg and type(reg.Get) == "function") and reg.Get(actor.id) or nil
    if registeredAtStart == true and latest == nil then
        return false, nil
    end
    local rec = latest or actor
    if rec.alive == false or rec.departed == true or rec.removed == true then
        return false, nil
    end
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= livePresenceValue() then
        return false, nil
    end
    return true, rec
end

local function syncMeta()
    local list, minDue = Beats.PendingTurns, nil
    for i = 1, #list do
        local d = tonumber(list[i].dueAt)
        if d and (minDue == nil or d < minDue) then minDue = d end
    end
    Beats.PendingCount, Beats.NextDueAt = #list, minDue
end

local function removeOrder(id)
    for i = #threadOrder, 1, -1 do
        if threadOrder[i] == id then
            table.remove(threadOrder, i)
            return
        end
    end
end

local function purgeTurnsForThread(tid)
    local list, rem, removed = Beats.PendingTurns, {}, 0
    for i = 1, #list do
        if list[i].threadID == tid then
            removed = removed + 1
        else
            rem[#rem + 1] = list[i]
        end
    end
    Beats.PendingTurns = rem
    return removed
end

local function registerThread(tid, now, expiresAt, participants)
    if not Beats.ActiveThreads[tid] then
        while #threadOrder >= MAX_THREADS do
            local oldest = table.remove(threadOrder, 1)
            Beats.ActiveThreads[oldest] = nil
            purgeTurnsForThread(oldest)
        end
        threadOrder[#threadOrder + 1] = tid
    end
    Beats.ActiveThreads[tid] = {
        threadID = tid,
        createdAt = now,
        expiresAt = expiresAt,
        participants = participants,
        status = "active",
    }
end

local function pruneCompletedThreads(now)
    local hasPending = {}
    for i = 1, #Beats.PendingTurns do
        hasPending[Beats.PendingTurns[i].threadID] = true
    end
    for i = #threadOrder, 1, -1 do
        local tid = threadOrder[i]
        local t = Beats.ActiveThreads[tid]
        if not t or (now >= (t.expiresAt or math.huge)) or not hasPending[tid] then
            Beats.ActiveThreads[tid] = nil
            table.remove(threadOrder, i)
        end
    end
end

function Beats.RegisterHook(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table" or type(spec.evaluate) ~= "function" then return false end
    local sub = {}
    for _, ev in ipairs(type(spec.eventTypes) == "table" and spec.eventTypes or { "*" }) do
        sub[tostring(ev)] = true
    end
    hooks[id] = {
        id = id,
        eventTypes = sub,
        priority = tonumber(spec.priority) or 50,
        cooldownMs = math.max(0, tonumber(spec.cooldownMs) or 0),
        evaluate = spec.evaluate,
    }
    return true
end

function Beats.UnregisterHook(id)
    id = tostring(id or "")
    if not hooks[id] then return false end
    hooks[id], hookCooldowns[id] = nil, nil
    return true
end

function Beats.ListHooks()
    local out = {}
    for id in pairs(hooks) do out[#out + 1] = id end
    table.sort(out)
    return out
end

function Beats.GetHookAuditEntries(at)
    local now = nowMs(at)
    local out = {}
    for id, h in pairs(hooks) do
        local untilAt = tonumber(hookCooldowns[id]) or 0
        out[#out + 1] = {
            id = id,
            priority = h.priority,
            cooldownMs = h.cooldownMs,
            cooldownRemainingMs = math.max(0, untilAt - now),
        }
    end
    table.sort(out, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.id < b.id
    end)
    return out
end

local function turnTokens(turn, ctx)
    local sp, addr = turn.speaker, turn.addressee or turn.speaker
    local S = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    local toks
    if turn.desc ~= nil and S and type(S.BuildRichSpeechTokens) == "function" then
        toks = S.BuildRichSpeechTokens(sp, addr, turn.desc, ctx and ctx.now or 0, nil, { skipLocation = true })
    else
        local addrName = Transport.FirstTokenName(addr and (addr.name or addr.fullName)) or "friend"
        toks = { ["addressee.name"] = addrName }
    end
    if type(ctx and ctx.tokens) == "table" then
        for k, v in pairs(ctx.tokens) do toks[k] = v end
    end
    if type(turn.tokens) == "table" then
        for k, v in pairs(turn.tokens) do toks[k] = v end
    end
    return toks
end

local function deliverTurn(t, tid, now, ctx)
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    if type(t) ~= "table" or type(t.speaker) ~= "table" then
        if audit then
            Beats.AuditLog("turn_drop", {
                "threadID=" .. tostring(tid or ""),
                "reason=invalid_turn_or_speaker",
            })
        end
        return false
    end
    local okSpeaker, sp = isActorAvailable(t.speaker, false, nil)
    if not okSpeaker then
        if audit then
            Beats.AuditLog("turn_drop", {
                "threadID=" .. tostring(tid or ""),
                "speaker=" .. tostring(t.speaker.id or ""),
                "alive=" .. tostring(t.speaker.alive),
                "presence=" .. tostring(t.speaker.presenceState or "nil"),
                "reason=speaker_unavailable",
            })
        end
        return false
    end
    local ev = t.eventType or "social_beat"
    local act = t.act or "REACT"
    local domain = t.domain or t.topic or "social"
    local topic = t.topic or domain
    local channel = t.channel or domain
    local ref = t.eventRef or tid
    local lineText, res = Transport.ResolveLine(sp, {
        eventType = ev,
        eventID = ref,
        act = act,
        topic = topic,
        domain = domain,
        poolID = t.poolID,
        role = t.role,
        templateID = t.templateID,
        fallback = t.fallback,
        realizationID = t.realizationID,
        addressee = t.addressee,
        addresseeName = t.addresseeName,
        tokens = turnTokens(t, ctx),
        context = t.context,
        inCombat = t.inCombat == true,
    })
    if not lineText then
        if audit then
            Beats.AuditLog("turn_drop", {
                "threadID=" .. tostring(tid or ""),
                "speaker=" .. tostring(sp.id or ""),
                "eventType=" .. tostring(ev),
                "poolID=" .. tostring(t.poolID or "nil"),
                "role=" .. tostring(t.role or "nil"),
                "act=" .. tostring(act),
                "reason=resolve_line_nil",
            })
        end
        return false
    end
    if t.barkId and PNC.SecondaryChannel and PNC.SecondaryChannel.RequestBark then
        PNC.SecondaryChannel.RequestBark(sp, t.barkId, now)
    end
    local lane = (t.lane == "scene") and "scene" or "beat"
    local deliveredCtx = {}
    if type(t.context) == "table" then
        for k, v in pairs(t.context) do deliveredCtx[k] = v end
    end
    deliveredCtx.eventType = ev
    deliveredCtx.eventRef = ref
    deliveredCtx.threadID = tid
    deliveredCtx.lane = lane
    deliveredCtx.domain = domain
    deliveredCtx.topic = topic
    if deliveredCtx.transient == nil then deliveredCtx.transient = (lane ~= "scene") end

    local sent = Transport.Deliver(sp, now, {
        eventType = ev,
        speechEventID = t.realizationID or (res and res.realizationID) or ("semantic.beat." .. tostring(t.role or "line")),
        realizationID = t.realizationID or (res and res.realizationID),
        responsePlanID = t.responsePlanID,
        poolID = t.poolID,
        flowID = t.flowID,
        act = act,
        domain = domain,
        topic = topic,
        channel = channel,
        lane = lane,
        family = t.family or "semantic_beat",
        threadID = tid,
        sceneID = t.sceneID,
        priority = tonumber(t.priority) or 30,
        priorityHoldMs = tonumber(t.priorityHoldMs) or 500,
        holdMs = tonumber(t.holdMs) or 1800,
        ttlMs = t.ttlMs,
        cooldownMs = tonumber(t.cooldownMs) or 1500,
        familyCooldownMs = tonumber(t.familyCooldownMs) or 1500,
        clientCooldowns = t.clientCooldowns,
        tts = t.tts ~= false,
        streamKey = t.streamKey or ("beat:" .. tostring(sp.id)),
        eventRef = ref,
        text = lineText,
        presentationClass = t.presentationClass or (res and res.presentationClass) or "BARK",
        offerIDs = t.offerIDs,
        factRefs = t.factRefs,
        observerOnly = t.observerOnly,
        recipientKind = t.recipientKind,
        semanticEventFacts = t.semanticEventFacts,
        meaningful = t.meaningful == true,
        context = deliveredCtx,
    })
    local okSent = (tonumber(sent) or 0) > 0
    if audit then
        Beats.AuditLog(okSent and "turn_delivered" or "turn_drop", {
            "threadID=" .. tostring(tid or ""),
            "speaker=" .. tostring(sp.id or ""),
            "eventType=" .. tostring(ev),
            "poolID=" .. tostring(t.poolID or "nil"),
            "role=" .. tostring(t.role or "nil"),
            "sent=" .. tostring(tonumber(sent) or 0),
            okSent and ("line=" .. tostring(string.sub(tostring(lineText), 1, 80))) or "reason=transport_sent_zero",
        })
    end
    if okSent and type(t.onDelivered) == "function" then
        pcall(t.onDelivered, t, tid, now, ctx)
    end
    return okSent
end

function Beats.NotifyExternalSpeech(now, holdMs)
    now = nowMs(now)
    local gap = math.max(900, math.min(2400, tonumber(holdMs) or 1500))
    local untilAt = now + gap
    if untilAt > (tonumber(Beats.NextFloorAt) or 0) then
        Beats.NextFloorAt = untilAt
    end
    return Beats.NextFloorAt
end

function Beats.ReserveSpeechFloor(desiredAt, priority, holdMs, interrupt)
    local desired = tonumber(desiredAt) or nowMs(nil)
    local pri = tonumber(priority) or 30
    local gap = math.max(Beats.FLOOR_GAP_MS, math.min(2400, tonumber(holdMs) or 1800))
    local floorAt = tonumber(Beats.NextFloorAt) or 0
    if interrupt == true or pri >= Beats.URGENT_PRIORITY then
        local untilAt = desired + math.max(900, math.min(2000, tonumber(holdMs) or 1400))
        if untilAt > floorAt then Beats.NextFloorAt = untilAt end
        return desired, 0
    end
    local slot = desired >= floorAt and desired or floorAt
    Beats.NextFloorAt = slot + gap
    return slot, slot - desired
end

function Beats.StartThread(plan, now, ctx)
    if type(plan) ~= "table" then return nil end
    now = nowMs(now)
    Beats._seq = Beats._seq + 1
    local tid = tostring(plan.threadID or ("beat:" .. tostring(plan.eventRef or Beats._seq)))
    local reg = PNC.Registry
    local hasRegGet = reg and type(reg.Get) == "function"
    local participants = {}
    local maxExpires = now + (tonumber(plan.ttlMs) or 14000)
    local queuedReplies = 0
    local openingDelay = (type(plan.opening) == "table" and tonumber(plan.opening.delayMs) or 0)
    if openingDelay < 0 then openingDelay = 0 end
    local ok = false
    local anchorTime = now + openingDelay
    if type(plan.opening) == "table" then
        if type(plan.opening.speaker) == "table" and plan.opening.speaker.id ~= nil then
            participants[tostring(plan.opening.speaker.id)] = plan.opening.speaker
        end
        if type(plan.opening.addressee) == "table" and plan.opening.addressee.id ~= nil then
            participants[tostring(plan.opening.addressee.id)] = plan.opening.addressee
        end
        local slot, deferredMs = Beats.ReserveSpeechFloor(
            anchorTime,
            plan.opening.priority,
            plan.opening.holdMs or 1800,
            plan.opening.interrupt == true
        )
        anchorTime = slot
        if deferredMs > 0 and type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true then
            Beats.AuditLog("floor_deferred", {
                "threadID=" .. tid,
                "speaker=" .. tostring(plan.opening.speaker and plan.opening.speaker.id or ""),
                "deferredMs=" .. tostring(math.floor(deferredMs)),
            })
        end
        if slot > now and type(plan.opening.speaker) == "table" and plan.opening.speaker.id ~= nil then
            while #Beats.PendingTurns >= MAX_Q do table.remove(Beats.PendingTurns, 1) end
            local expAt = slot + (tonumber(plan.opening.ttlMs) or 10000)
            if expAt > maxExpires then maxExpires = expAt end
            Beats.PendingTurns[#Beats.PendingTurns + 1] = {
                turn = plan.opening,
                threadID = tid,
                family = plan.family or plan.opening.family,
                dueAt = slot,
                expiresAt = expAt,
                speakerRegistered = hasRegGet and reg.Get(plan.opening.speaker.id) ~= nil or false,
                addresseeRegistered = (type(plan.opening.addressee) == "table" and plan.opening.addressee.id ~= nil and hasRegGet)
                    and (reg.Get(plan.opening.addressee.id) ~= nil) or false,
                ctx = ctx,
            }
            queuedReplies = queuedReplies + 1
            ok = true
        else
            ok = deliverTurn(plan.opening, tid, now, ctx)
        end
    end
    for _, r in ipairs(type(plan.replies) == "table" and plan.replies or {}) do
        if type(r) == "table" and type(r.speaker) == "table" and r.speaker.id ~= nil then
            while #Beats.PendingTurns >= MAX_Q do table.remove(Beats.PendingTurns, 1) end
            local replyDue = anchorTime + (tonumber(r.delayMs) or 1200)
            local replyEnd = replyDue + Beats.FLOOR_GAP_MS
            if replyEnd > (tonumber(Beats.NextFloorAt) or 0) then
                Beats.NextFloorAt = replyEnd
            end
            local expAt = replyDue + (tonumber(r.ttlMs) or 10000)
            if expAt > maxExpires then maxExpires = expAt end
            participants[tostring(r.speaker.id)] = r.speaker
            if type(r.addressee) == "table" and r.addressee.id ~= nil then
                participants[tostring(r.addressee.id)] = r.addressee
            end
            Beats.PendingTurns[#Beats.PendingTurns + 1] = {
                turn = r,
                threadID = tid,
                family = plan.family or r.family,
                dueAt = replyDue,
                expiresAt = expAt,
                speakerRegistered = hasRegGet and reg.Get(r.speaker.id) ~= nil or false,
                addresseeRegistered = (type(r.addressee) == "table" and r.addressee.id ~= nil and hasRegGet)
                    and (reg.Get(r.addressee.id) ~= nil) or false,
                ctx = ctx,
            }
            queuedReplies = queuedReplies + 1
        end
    end
    if queuedReplies > 0 then
        registerThread(tid, now, maxExpires, participants)
    end
    syncMeta()
    return tid, ok
end

function Beats.CancelThread(threadID)
    local tid = tostring(threadID or "")
    if tid == "" then return 0 end
    local removed = purgeTurnsForThread(tid)
    local hadThread = Beats.ActiveThreads[tid] ~= nil
    Beats.ActiveThreads[tid] = nil
    removeOrder(tid)
    syncMeta()
    return (removed > 0 or hadThread) and math.max(removed, 1) or 0
end

function Beats.OnActorUnavailable(actorID)
    local id = tostring(actorID or "")
    if id == "" then return 0 end
    local list, rem, removed = Beats.PendingTurns, {}, 0
    for i = 1, #list do
        local e = list[i]
        local spId = e.turn and e.turn.speaker and e.turn.speaker.id
        local adId = e.turn and e.turn.addressee and e.turn.addressee.id
        if tostring(spId or "") == id or tostring(adId or "") == id then
            removed = removed + 1
        else
            rem[#rem + 1] = e
        end
    end
    Beats.PendingTurns = rem
    pruneCompletedThreads(nowMs(nil))
    syncMeta()
    return removed
end

function Beats.HandoffToScene(threadID, spec)
    local tid = tostring(threadID or "")
    if tid == "" then return nil, "thread_id_required" end
    spec = type(spec) == "table" and spec or {}

    local thread = Beats.ActiveThreads[tid]
    local cancelled = Beats.CancelThread(tid)

    local runtime = spec.runtime or (PNC.ConvoEngine and PNC.ConvoEngine.InteractionSceneRuntime)
    if type(runtime) ~= "table" or type(runtime.Open) ~= "function" then
        return nil, "scene_runtime_unavailable"
    end

    local participants = spec.participants
    if type(participants) ~= "table" and thread and type(thread.participants) == "table" then
        participants = {}
        for pid, actor in pairs(thread.participants) do
            participants[#participants + 1] = { id = pid, actor = actor, kind = "npc" }
        end
    end

    local requestedID = spec.sceneID or spec.id
    if requestedID ~= nil and tostring(requestedID) == tid then
        requestedID = "scene:handoff:" .. tid
    end

    local openSpec = {}
    for k, v in pairs(spec) do
        if k ~= "runtime" and k ~= "sceneID" then
            openSpec[k] = v
        end
    end
    openSpec.id = requestedID
    openSpec.participants = participants

    local scene, sceneIDOrErr
    if type(runtime.scheduler) == "table" then
        scene, sceneIDOrErr = runtime:Open(openSpec)
    else
        scene, sceneIDOrErr = runtime.Open(openSpec)
    end
    if not scene then
        return nil, sceneIDOrErr
    end
    return scene, scene.id, {
        threadID = tid,
        sceneID = scene.id,
        cancelledTurns = cancelled,
    }
end

function Beats.GetThreadSnapshot()
    local active = {}
    for i = 1, #threadOrder do
        local tid = threadOrder[i]
        local t = Beats.ActiveThreads[tid]
        if t then
            active[#active + 1] = {
                threadID = tid,
                createdAt = t.createdAt,
                expiresAt = t.expiresAt,
                status = t.status,
            }
        end
    end
    return {
        pendingCount = #Beats.PendingTurns,
        activeThreadCount = #active,
        threads = active,
    }
end

function Beats.Emit(eventName, payload, now)
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    eventName = tostring(eventName or "")
    if eventName == "" then return false, "invalid_event" end
    now, payload = nowMs(now), type(payload) == "table" and payload or {}
    local m = {}
    local cdBlocked = audit and {} or nil
    for _, h in pairs(hooks) do
        if h.eventTypes[eventName] or h.eventTypes["*"] then
            local untilAt = tonumber(hookCooldowns[h.id]) or 0
            if now >= untilAt then
                m[#m + 1] = h
            elseif cdBlocked then
                cdBlocked[#cdBlocked + 1] = tostring(h.id) .. ":" .. tostring(math.floor(untilAt - now)) .. "ms"
            end
        end
    end
    if #m == 0 then
        if audit then
            Beats.AuditLog("emit_rejected", {
                "eventName=" .. eventName,
                "reason=no_matching_hook",
                "cooldownBlocked=" .. (#cdBlocked > 0 and table.concat(cdBlocked, ",") or "none"),
                "anchor=" .. tostring(payload.anchor and payload.anchor.id or payload.speaker and payload.speaker.id or "nil"),
                "partner=" .. tostring(payload.partner and payload.partner.id or payload.addressee and payload.addressee.id or "nil"),
            })
        end
        return false, "no_matching_hook"
    end
    table.sort(m, function(a, b) return a.priority ~= b.priority and a.priority > b.priority or a.id < b.id end)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local ctx = BC and BC.Build and BC.Build(payload.anchor or payload.speaker, payload.partner or payload.addressee, {
        now = now,
        inCombat = payload.inCombat == true,
        partnerKey = payload.partnerKey,
        addresseeIsPlayer = payload.addresseeIsPlayer == true,
        earnedDelta = payload.earnedDelta,
    }) or { now = now, actor = {}, partner = {}, relationship = {}, env = payload.env or {}, tokens = {} }
    for i = 1, #m do
        local h = m[i]
        local ok, plan = pcall(h.evaluate, eventName, payload, ctx)
        if ok and type(plan) == "table" and (plan.opening or plan.replies) then
            hookCooldowns[h.id] = now + h.cooldownMs
            local tid, openOk = Beats.StartThread(plan, now, ctx)
            if audit then
                Beats.AuditLog("emit_selected", {
                    "eventName=" .. eventName,
                    "hook=" .. tostring(h.id),
                    "threadID=" .. tostring(tid or "nil"),
                    "openingDelivered=" .. tostring(openOk == true),
                    "replyCount=" .. tostring(type(plan.replies) == "table" and #plan.replies or 0),
                    "cooldownMs=" .. tostring(h.cooldownMs),
                })
            end
            return tid ~= nil, tid
        elseif audit then
            Beats.AuditLog("emit_hook_skip", {
                "eventName=" .. eventName,
                "hook=" .. tostring(h.id),
                "ok=" .. tostring(ok == true),
                "detail=" .. tostring(ok and "returned_nil_plan" or plan),
            })
        end
    end
    if audit then
        Beats.AuditLog("emit_rejected", {
            "eventName=" .. eventName,
            "reason=no_beat_selected",
            "matchedHooks=" .. tostring(#m),
        })
    end
    return false, "no_beat_selected"
end

function Beats.Pump(now)
    now = nowMs(now)
    local fired = 0
    if (tonumber(Beats.PendingCount) or 0) > 0 then
        local reg, rem = PNC.Registry, {}
        for i = 1, #Beats.PendingTurns do
            local e = Beats.PendingTurns[i]
            local threadActive = (Beats.ActiveThreads[e.threadID] == nil)
                or (Beats.ActiveThreads[e.threadID].status == "active"
                    and now < (Beats.ActiveThreads[e.threadID].expiresAt or math.huge))
            local spOk, resolvedSpeaker = isActorAvailable(e.turn.speaker, e.speakerRegistered, reg)
            local addrOk = (type(e.turn.addressee) ~= "table")
                or e.turn.addresseeIsPlayer == true
                or e.turn.addressee.isPlayer == true
                or isActorAvailable(e.turn.addressee, e.addresseeRegistered, reg)
            if threadActive and spOk and addrOk and now < (e.expiresAt or math.huge) then
                if now < e.dueAt then
                    rem[#rem + 1] = e
                else
                    e.turn.speaker = resolvedSpeaker
                    if deliverTurn(e.turn, e.threadID, now, e.ctx) then
                        fired = fired + 1
                    end
                end
            end
        end
        Beats.PendingTurns = rem
        if fired == 0 and #rem == 0 and (tonumber(Beats.NextFloorAt) or 0) > now then
            Beats.NextFloorAt = now
        end
        pruneCompletedThreads(now)
        syncMeta()
    elseif #threadOrder > 0 then
        pruneCompletedThreads(now)
    end
    if Beats.CheckEnvironment and now >= (tonumber(Beats.NextEnvCheckAt) or 0) then
        Beats.CheckEnvironment(now)
    end
    return fired
end

function Beats.ResetRuntime()
    Beats.PendingTurns, Beats.PendingCount, Beats.NextDueAt = {}, 0, nil
    Beats.NextEnvCheckAt, Beats.NextFloorAt, Beats.LastWeather, hookCooldowns = 0, 0, nil, {}
    Beats.ActiveThreads, threadOrder = {}, {}
    Transport.ResetRuntime()
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if BC and type(BC.ResetRuntime) == "function" then BC.ResetRuntime() end
    local Aud = PNC.Semantics and PNC.Semantics.AudienceContext or nil
    if Aud and type(Aud.ResetRuntime) == "function" then Aud.ResetRuntime() end
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if Dir and type(Dir.ResetRuntime) == "function" then Dir.ResetRuntime() end
    if type(Beats.ResetHouseAlarmRuntime) == "function" then Beats.ResetHouseAlarmRuntime() end
    if type(Beats.ResetUtilitiesRuntime) == "function" then Beats.ResetUtilitiesRuntime() end
    if type(Beats.ResetWorldObjectRuntime) == "function" then Beats.ResetWorldObjectRuntime() end
    if type(Beats.ResetTelevisionRuntime) == "function" then Beats.ResetTelevisionRuntime() end
    if type(Beats.ResetCombatAssistRuntime) == "function" then Beats.ResetCombatAssistRuntime() end
    if type(Beats.ResetGroupBanterRuntime) == "function" then Beats.ResetGroupBanterRuntime() end
    if type(Beats.ResetAuditRuntime) == "function" then Beats.ResetAuditRuntime() end
end

require "PNC/Semantics/PNC_SemanticDialogueBeats_Environment"
require "PNC/Semantics/Beats/PNC_SemanticBeats_HouseAlarm"
require "PNC/Semantics/Beats/PNC_SemanticBeats_Utilities"
require "PNC/Semantics/Beats/PNC_SemanticBeats_WorldObjects"
require "PNC/Semantics/Beats/PNC_SemanticBeats_Television"
require "PNC/Semantics/Beats/PNC_SemanticBeats_SkillLevelUp"
require "PNC/Semantics/Beats/PNC_SemanticBeats_CombatAssist"
require "PNC/Semantics/Beats/PNC_SemanticBeats_NightCamp"
require "PNC/Semantics/Beats/PNC_SemanticBeats_MedicalRescue"
require "PNC/Semantics/Beats/PNC_SemanticBeats_GroupBanter"
require "PNC/Semantics/Beats/PNC_BroadcastRules_StoriesAndOpenBand"
require "PNC/Semantics/Beats/PNC_SemanticBeats_Audit"

return Beats

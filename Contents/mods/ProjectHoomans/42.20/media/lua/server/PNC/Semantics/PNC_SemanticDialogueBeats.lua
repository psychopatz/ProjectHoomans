-- Extensible beat hook registry and threaded NPC conversation runner.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticBeatContext"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Delivery"

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

Beats.VERSION = 1
Beats.PendingTurns = Beats.PendingTurns or {}
Beats.PendingCount = tonumber(Beats.PendingCount) or #Beats.PendingTurns
Beats.NextDueAt = Beats.NextDueAt
Beats.NextEnvCheckAt = tonumber(Beats.NextEnvCheckAt) or 0
Beats.LastWeather = Beats.LastWeather
Beats._seq = tonumber(Beats._seq) or 0

local MAX_Q, hooks, hookCooldowns = 32, {}, {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function syncMeta()
    local list, minDue = Beats.PendingTurns, nil
    for i = 1, #list do
        local d = tonumber(list[i].dueAt)
        if d and (minDue == nil or d < minDue) then minDue = d end
    end
    Beats.PendingCount, Beats.NextDueAt = #list, minDue
end

function Beats.RegisterHook(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table" or type(spec.evaluate) ~= "function" then return false end
    local sub = {}
    for _, ev in ipairs(type(spec.eventTypes) == "table" and spec.eventTypes or { "*" }) do sub[tostring(ev)] = true end
    hooks[id] = {
        id = id, eventTypes = sub, priority = tonumber(spec.priority) or 50,
        cooldownMs = math.max(0, tonumber(spec.cooldownMs) or 0), evaluate = spec.evaluate,
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

local function turnTokens(turn, ctx)
    local S = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    local sp, addr = turn.speaker, turn.addressee or turn.speaker
    local desc = turn.desc or { semanticClass = "human_hostile", enemyType = "hostile" }
    local toks = (S and S.BuildRichSpeechTokens)
        and S.BuildRichSpeechTokens(sp, addr, desc, ctx and ctx.now or 0, nil, { skipLocation = true })
        or { ["addressee.name"] = tostring(addr and (addr.name or addr.fullName) or "friend") }
    if type(ctx and ctx.tokens) == "table" then for k, v in pairs(ctx.tokens) do toks[k] = v end end
    if type(turn.tokens) == "table" then for k, v in pairs(turn.tokens) do toks[k] = v end end
    return toks
end

local function deliverTurn(t, tid, now, ctx)
    local S = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    if not S or type(t) ~= "table" or type(t.speaker) ~= "table" or t.speaker.alive == false then return false end
    if type(S.ResolveSemanticLine) ~= "function" or type(S.DeliverBark) ~= "function" then return false end
    local ev, act, tCls, ref = t.eventType or "combat_ally_warn_callout", t.act or "WARN", t.threatClass or "human_hostile", t.eventRef or tid
    local lineText, res = S.ResolveSemanticLine(t.speaker, ev, act, tCls, ref, nil, turnTokens(t, ctx), { replyRole = t.role })
    if not lineText then return false end
    if t.barkId and PNC.SecondaryChannel and PNC.SecondaryChannel.RequestBark then
        PNC.SecondaryChannel.RequestBark(t.speaker, t.barkId, now)
    end
    local sent = S.DeliverBark(t.speaker, now, {
        eventType = ev, speechEventID = res and res.realizationID or ("semantic.beat." .. tostring(t.role or "line")),
        act = act, family = t.family or "semantic_beat", threadID = tid,
        priority = tonumber(t.priority) or 30, priorityHoldMs = tonumber(t.priorityHoldMs) or 500,
        holdMs = tonumber(t.holdMs) or 700, cooldownMs = tonumber(t.cooldownMs) or 1500,
        familyCooldownMs = tonumber(t.familyCooldownMs) or 1500, clientCooldowns = t.clientCooldowns,
        maxSpeakers = 1, streamKey = "beat:" .. tostring(t.speaker.id), eventRef = ref,
        text = lineText,
        presentationClass = res and res.presentationClass or "BARK",
        context = { eventType = ev, eventRef = ref, threadID = tid, transient = true },
    })
    return (tonumber(sent) or 0) > 0
end

function Beats.StartThread(plan, now, ctx)
    if type(plan) ~= "table" then return nil end
    now = nowMs(now)
    Beats._seq = Beats._seq + 1
    local tid = tostring(plan.threadID or ("beat:" .. tostring(plan.eventRef or Beats._seq)))
    local ok = type(plan.opening) == "table" and deliverTurn(plan.opening, tid, now, ctx) or false
    for _, r in ipairs(type(plan.replies) == "table" and plan.replies or {}) do
        if type(r) == "table" and type(r.speaker) == "table" then
            while #Beats.PendingTurns >= MAX_Q do table.remove(Beats.PendingTurns, 1) end
            Beats.PendingTurns[#Beats.PendingTurns + 1] = {
                turn = r, threadID = tid, family = plan.family or r.family,
                dueAt = now + (tonumber(r.delayMs) or 800), expiresAt = now + (tonumber(r.ttlMs) or 6000), ctx = ctx,
            }
        end
    end
    syncMeta()
    return tid, ok
end

function Beats.Emit(eventName, payload, now)
    eventName = tostring(eventName or "")
    if eventName == "" then return false, "invalid_event" end
    now, payload = nowMs(now), type(payload) == "table" and payload or {}
    local m = {}
    for _, h in pairs(hooks) do
        if (h.eventTypes[eventName] or h.eventTypes["*"]) and now >= (tonumber(hookCooldowns[h.id]) or 0) then m[#m + 1] = h end
    end
    if #m == 0 then return false, "no_matching_hook" end
    table.sort(m, function(a, b) return a.priority ~= b.priority and a.priority > b.priority or a.id < b.id end)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local ctx = BC and BC.Build and BC.Build(payload.anchor or payload.speaker, payload.partner or payload.addressee, { now = now, inCombat = payload.inCombat == true })
        or { now = now, actor = {}, env = payload.env or {}, tokens = {} }
    for i = 1, #m do
        local h = m[i]
        local ok, plan = pcall(h.evaluate, eventName, payload, ctx)
        if ok and type(plan) == "table" and (plan.opening or plan.replies) then
            hookCooldowns[h.id] = now + h.cooldownMs
            local tid = Beats.StartThread(plan, now, ctx)
            return tid ~= nil, tid
        end
    end
    return false, "no_beat_selected"
end

function Beats.Pump(now)
    now = nowMs(now)
    local fired = 0
    if (tonumber(Beats.PendingCount) or 0) > 0 and (Beats.NextDueAt == nil or now >= tonumber(Beats.NextDueAt)) then
        local reg, rem = PNC.Registry, {}
        for i = 1, #Beats.PendingTurns do
            local e = Beats.PendingTurns[i]
            if now < e.dueAt then rem[#rem + 1] = e
            elseif now < (e.expiresAt or math.huge) then
                local sp = e.turn.speaker
                e.turn.speaker = (reg and reg.Get and sp.id and reg.Get(sp.id)) or sp
                if deliverTurn(e.turn, e.threadID, now, e.ctx) then fired = fired + 1 end
            end
        end
        Beats.PendingTurns = rem
        syncMeta()
    end
    if Beats.CheckEnvironment and now >= (tonumber(Beats.NextEnvCheckAt) or 0) then Beats.CheckEnvironment(now) end
    return fired
end

function Beats.ResetRuntime()
    Beats.PendingTurns, Beats.PendingCount, Beats.NextDueAt = {}, 0, nil
    Beats.NextEnvCheckAt, Beats.LastWeather, hookCooldowns = 0, nil, {}
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if BC and type(BC.ResetRuntime) == "function" then BC.ResetRuntime() end
end

require "PNC/Semantics/PNC_SemanticDialogueBeats_Environment"

return Beats

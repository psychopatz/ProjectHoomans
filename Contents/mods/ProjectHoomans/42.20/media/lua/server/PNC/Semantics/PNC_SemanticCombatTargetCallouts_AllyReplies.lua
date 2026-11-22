if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Delivery"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_AllyReplies_Dispatch"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

S.PendingReplies = S.PendingReplies or {}
S.PendingReplyCount = tonumber(S.PendingReplyCount) or #S.PendingReplies
S.NextReplyDueAt = S.NextReplyDueAt

local MAX_Q, MAX_R = 32, 3
local ROLES = { "lead", "wingman", "anchor" }

local function syncMeta()
    local list, minDue = S.PendingReplies, nil
    for i = 1, #list do
        local d = tonumber(list[i].dueAt)
        if d and (minDue == nil or d < minDue) then minDue = d end
    end
    S.PendingReplyCount, S.NextReplyDueAt = #list, minDue
end

local function pushPendingReply(entry)
    while #S.PendingReplies >= MAX_Q do table.remove(S.PendingReplies, 1) end
    S.PendingReplies[#S.PendingReplies + 1] = entry
end

local function replyDelay(idx, id)
    local s, h = tostring(id or ""), 0
    for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100000 end
    if idx == 1 then return 500 + (h % 201) end
    if idx == 2 then return 1150 + (h % 251) end
    return 1850 + (h % 251)
end

function S.EnqueueCustomReply(spec)
    if type(spec) ~= "table" or type(spec.speaker) ~= "table" or spec.speaker.id == nil then return 0 end
    local sp, addr, now = spec.speaker, spec.addressee, S.Finite(spec.now) or 0
    local ref = spec.eventRef or ("sit:" .. tostring(sp.id))
    pushPendingReply({
        allyId = tostring(sp.id), allyRecord = sp, callerRecord = addr, addresseeRecord = addr,
        callerId = tostring(addr and addr.id or ""), callerName = tostring(addr and (addr.name or addr.fullName) or ""),
        desc = spec.desc, threatClass = spec.threatClass or "human_hostile", canEngage = spec.canEngage ~= false,
        skipLOSCheck = spec.skipLOSCheck ~= false, skipLocation = true, role = spec.role, wave = spec.wave,
        topic = spec.topic, extraContext = spec.extraContext,
        extraTokens = spec.extraTokens, barkOpts = spec.barkOpts, threadID = spec.threadID or ref,
        eventType = spec.eventType or "combat_ally_warn_reply_engaging", act = spec.act or "ACK",
        barkId = spec.barkId or "bark.alert_hey", eventRef = ref,
        dueAt = now + (tonumber(spec.delayMs) or 650), expiresAt = now + (tonumber(spec.ttlMs) or 6000),
    })
    syncMeta()
    return 1
end

function S.EnqueueAllyReplies(caller, wr, now, eventRef)
    local notified = type(wr) == "table" and wr.notified or nil
    if type(notified) ~= "table" or #notified == 0 then return 0 end
    local w = {
        callerId = tostring(caller and caller.id or ""),
        callerName = tostring(caller and (caller.name or caller.fullName) or ""),
        leadSpoke = false, wingmanSpoke = false,
    }
    local queued, refPrefix = 0, tostring(eventRef or "") .. ":reply:"
    for idx = 1, math.min(MAX_R, #notified) do
        local item = notified[idx]
        local ally = type(item) == "table" and item.record or nil
        if type(ally) == "table" and ally.id ~= nil and ally.alive ~= false then
            local eng = item.canEngage == true
            pushPendingReply({
                allyId = tostring(ally.id), allyRecord = ally, callerRecord = caller,
                callerId = w.callerId, callerName = w.callerName, desc = wr.descriptor, canEngage = eng,
                role = ROLES[idx] or "wingman", wave = w, threadID = eventRef,
                eventType = eng and "combat_ally_warn_reply_alerted" or "combat_ally_warn_reply_defensive",
                act = eng and "ACK" or "REACT", barkId = eng and "bark.alert_hey" or "bark.whisper_check",
                eventRef = refPrefix .. tostring(ally.id),
                dueAt = now + replyDelay(idx, ally.id), expiresAt = now + 6000,
            })
            queued = queued + 1
        end
    end
    syncMeta()
    return queued
end

function S.PumpPendingReplies(now)
    if (tonumber(S.PendingReplyCount) or 0) <= 0 then return 0 end
    now = S.Finite(now) or (PNC.Core and PNC.Core.Now and S.Finite(PNC.Core.Now())) or 0
    if S.NextReplyDueAt ~= nil and now < S.NextReplyDueAt then return 0 end
    local reg, perc, sec, rem, fired = PNC.Registry, PNC.Perception, PNC.SecondaryChannel, {}, 0
    for i = 1, #S.PendingReplies do
        local e = S.PendingReplies[i]
        if now < e.dueAt then rem[#rem + 1] = e
        elseif now < (e.expiresAt or math.huge) then
            local rec = (reg and type(reg.Get) == "function" and reg.Get(e.allyId)) or e.allyRecord
            if type(rec) == "table" and rec.alive ~= false then
                S.DispatchPendingReply(e, rec, now, reg, perc, sec)
                fired = fired + 1
            end
        end
    end
    S.PendingReplies = rem
    syncMeta()
    return fired
end

function S.CancelPendingRepliesForThread(threadID)
    local tid = tostring(threadID or "")
    if tid == "" or (tonumber(S.PendingReplyCount) or 0) <= 0 then return 0 end
    local rem, cancelled = {}, 0
    for i = 1, #S.PendingReplies do
        local e = S.PendingReplies[i]
        if tostring(e.threadID or "") == tid or tostring(e.eventRef or "") == tid then
            cancelled = cancelled + 1
        else
            rem[#rem + 1] = e
        end
    end
    S.PendingReplies = rem
    syncMeta()
    return cancelled
end

function S.ResetRuntime()
    S.PendingReplies, S.PendingReplyCount, S.NextReplyDueAt = {}, 0, nil
    if type(S.ResetStaminaCallouts) == "function" then S.ResetStaminaCallouts() end
    if type(S.ResetWoundCallouts) == "function" then S.ResetWoundCallouts() end
end

return S

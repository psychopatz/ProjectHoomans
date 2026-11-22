if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Delivery"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

S.PendingReplies = S.PendingReplies or {}
S.PendingReplyCount = tonumber(S.PendingReplyCount) or #S.PendingReplies
S.NextReplyDueAt = S.NextReplyDueAt

local MAX_PENDING_REPLIES, MAX_REPLIES_PER_WARNING = 32, 3
local ROLE_BY_IDX = { "lead", "wingman", "anchor" }

local function syncQueueMeta()
    local list, minDue = S.PendingReplies, nil
    for i = 1, #list do
        local d = tonumber(list[i].dueAt)
        if d and (minDue == nil or d < minDue) then minDue = d end
    end
    S.PendingReplyCount, S.NextReplyDueAt = #list, minDue
end

local function pushPendingReply(entry)
    while #S.PendingReplies >= MAX_PENDING_REPLIES do table.remove(S.PendingReplies, 1) end
    S.PendingReplies[#S.PendingReplies + 1] = entry
end

local function replyDelay(idx, id)
    local s, h = tostring(id or ""), 0
    for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100000 end
    if idx == 1 then return 500 + (h % 201) end
    if idx == 2 then return 1150 + (h % 251) end
    return 1850 + (h % 251)
end

local function hasReplyLOS(rec, desc, now, perc)
    local rt = rec.runtime
    if type(rt) == "table" and now < (tonumber(rt.allyThreatAlertCheckAt) or 0) then
        return rt.allyThreatAlertVisible == true
    end
    if not perc or not perc.CanAllyEngageThreat then return false end
    local _, obj = perc.CanAllyEngageThreat(rec, desc)
    local losObj = (desc.kind == "foreign_npc" and type(obj) == "table") and obj.worldObject or obj
    local vis = losObj ~= nil and perc.CanSeeWorldObject ~= nil and perc.CanSeeWorldObject(rec, losObj) == true
    if type(rt) == "table" then rt.allyThreatAlertCheckAt, rt.allyThreatAlertVisible = now + 250, vis == true end
    return vis
end

local function resolveWaveRole(entry, callerRec)
    local w, role, addr = entry.wave, entry.role or "lead", entry.addresseeRecord or callerRec
    if role == "wingman" and w and entry.canEngage then
        if not w.leadSpoke then role = "lead"
        elseif w.leadName then addr = { id = w.leadId, name = w.leadName } end
    elseif role == "anchor" and w then
        if w.wingmanSpoke and w.wingmanName then addr = { id = w.wingmanId, name = w.wingmanName }
        elseif w.leadSpoke and w.leadName then addr = { id = w.leadId, name = w.leadName } end
    end
    return role, addr
end

local function dispatchReply(e, rec, now, reg, perc, sec)
    local ev, act, bark = e.eventType, e.act, e.barkId
    if e.skipLOSCheck ~= true and e.canEngage and e.desc then
        ev = hasReplyLOS(rec, e.desc, now, perc) and "combat_ally_warn_reply_engaging" or "combat_ally_warn_reply_alerted"
        act, bark = "ACK", "bark.alert_hey"
    end
    if sec and sec.RequestBark then sec.RequestBark(rec, bark, now) end
    local callerRec = e.callerRecord or (reg and reg.Get and reg.Get(e.callerId)) or { id = e.callerId, name = e.callerName }
    local role, addr = resolveWaveRole(e, callerRec)
    local skipLoc = e.skipLocation == true or role == "wingman" or (role == "anchor" and e.canEngage)
    local toks = S.BuildRichSpeechTokens
        and S.BuildRichSpeechTokens(rec, addr, e.desc, now, S.ResolveAllyWarnTone(rec, nil), { skipLocation = skipLoc }) or nil
    if toks and type(e.extraTokens) == "table" then
        for k, v in pairs(e.extraTokens) do toks[k] = v end
    end
    local tCls = (e.desc and e.desc.semanticClass) or e.threatClass or "human_hostile"
    local text, res = S.ResolveSemanticLine(rec, ev, act, tCls, e.eventRef, nil, toks, { replyRole = role })
    if not text then return end
    local sent = S.SendReplyBark(rec, now, ev, act, e.eventRef, text, res, toks, e.barkOpts)
    local w = e.wave
    if w and (tonumber(sent) or 0) > 0 then
        local rName = tostring(rec.name or rec.fullName or "")
        if role == "lead" then w.leadSpoke, w.leadId, w.leadName = true, tostring(rec.id), rName
        elseif role == "wingman" then w.wingmanSpoke, w.wingmanId, w.wingmanName = true, tostring(rec.id), rName end
    end
end

function S.EnqueueCustomReply(spec)
    if type(spec) ~= "table" or type(spec.speaker) ~= "table" or spec.speaker.id == nil then return 0 end
    local sp, addr, now = spec.speaker, spec.addressee, S.Finite(spec.now) or 0
    pushPendingReply({
        allyId = tostring(sp.id), allyRecord = sp, callerRecord = addr, addresseeRecord = addr,
        callerId = tostring(addr and addr.id or ""), callerName = tostring(addr and (addr.name or addr.fullName) or ""),
        desc = spec.desc, threatClass = spec.threatClass or "human_hostile", canEngage = spec.canEngage ~= false,
        skipLOSCheck = true, skipLocation = true, role = spec.role, wave = spec.wave,
        extraTokens = spec.extraTokens, barkOpts = spec.barkOpts,
        eventType = spec.eventType or "combat_ally_warn_reply_engaging", act = spec.act or "ACK",
        barkId = spec.barkId or "bark.alert_hey", eventRef = spec.eventRef or ("sit:" .. tostring(sp.id)),
        dueAt = now + (tonumber(spec.delayMs) or 650), expiresAt = now + (tonumber(spec.ttlMs) or 6000),
    })
    syncQueueMeta()
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
    for idx = 1, math.min(MAX_REPLIES_PER_WARNING, #notified) do
        local item = notified[idx]
        local ally = type(item) == "table" and item.record or nil
        if type(ally) == "table" and ally.id ~= nil and ally.alive ~= false then
            local eng = item.canEngage == true
            pushPendingReply({
                allyId = tostring(ally.id), allyRecord = ally, callerRecord = caller,
                callerId = w.callerId, callerName = w.callerName, desc = wr.descriptor, canEngage = eng,
                role = ROLE_BY_IDX[idx] or "wingman", wave = w,
                eventType = eng and "combat_ally_warn_reply_alerted" or "combat_ally_warn_reply_defensive",
                act = eng and "ACK" or "REACT", barkId = eng and "bark.alert_hey" or "bark.whisper_check",
                eventRef = refPrefix .. tostring(ally.id),
                dueAt = now + replyDelay(idx, ally.id), expiresAt = now + 6000,
            })
            queued = queued + 1
        end
    end
    syncQueueMeta()
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
                dispatchReply(e, rec, now, reg, perc, sec)
                fired = fired + 1
            end
        end
    end
    S.PendingReplies = rem
    syncQueueMeta()
    return fired
end

function S.ResetRuntime() S.PendingReplies, S.PendingReplyCount, S.NextReplyDueAt = {}, 0, nil end

return S

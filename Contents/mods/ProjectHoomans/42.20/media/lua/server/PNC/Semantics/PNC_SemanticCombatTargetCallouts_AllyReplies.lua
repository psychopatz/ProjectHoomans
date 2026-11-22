if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Delivery"

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

Service.PendingReplies = Service.PendingReplies or {}
Service.PendingReplyCount = tonumber(Service.PendingReplyCount) or #Service.PendingReplies
Service.NextReplyDueAt = Service.NextReplyDueAt

local MAX_PENDING_REPLIES, MAX_REPLIES_PER_WARNING = 32, 3
local ROLE_BY_IDX = { "lead", "wingman", "anchor" }
local cachedProfileMod

local function syncQueueMeta()
    local list, minDue = Service.PendingReplies, nil
    for i = 1, #list do
        local d = tonumber(list[i].dueAt)
        if d and (minDue == nil or d < minDue) then minDue = d end
    end
    Service.PendingReplyCount, Service.NextReplyDueAt = #list, minDue
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
    local w, role, addr = entry.wave, entry.role or "lead", callerRec
    if role == "wingman" and w and entry.canEngage then
        if not w.leadSpoke then role = "lead"
        elseif w.leadName then addr = { id = w.leadId, name = w.leadName } end
    elseif role == "anchor" and w then
        if w.wingmanSpoke and w.wingmanName then addr = { id = w.wingmanId, name = w.wingmanName }
        elseif w.leadSpoke and w.leadName then addr = { id = w.leadId, name = w.leadName } end
    end
    return role, addr
end

local function dispatchReply(entry, rec, now, reg, perc, sec)
    local ev, act, bark = entry.eventType, entry.act, entry.barkId
    if entry.canEngage and entry.desc then
        ev = hasReplyLOS(rec, entry.desc, now, perc)
            and "combat_ally_warn_reply_engaging" or "combat_ally_warn_reply_alerted"
        act, bark = "ACK", "bark.alert_hey"
    end
    if sec and type(sec.RequestBark) == "function" then sec.RequestBark(rec, bark, now) end
    local profile = cachedProfileMod and cachedProfileMod.Build and cachedProfileMod.Build(rec, "", {
        role = "ally", actorKind = "npc", inCombat = true,
    }) or {}
    local tone = Service.ResolveAllyWarnTone(rec, profile)
    local callerRec = entry.callerRecord or (reg and reg.Get and reg.Get(entry.callerId))
        or { id = entry.callerId, name = entry.callerName }
    local role, addr = resolveWaveRole(entry, callerRec)
    local skipLoc = (role == "wingman") or (role == "anchor" and entry.canEngage)
    local toks = Service.BuildRichSpeechTokens
        and Service.BuildRichSpeechTokens(rec, addr, entry.desc, now, tone, { skipLocation = skipLoc }) or nil
    local tCls = entry.desc and entry.desc.semanticClass or "human_hostile"
    local text, res = Service.ResolveSemanticLine(
        rec, ev, act, tCls, entry.eventRef, profile, toks, { replyRole = role }
    )
    if not text then return end
    local sent = Service.SendReplyBark(rec, now, ev, act, entry.eventRef, text, res, toks)
    local w = entry.wave
    if w and (tonumber(sent) or 0) > 0 then
        local rName = tostring(rec.name or rec.fullName or "")
        if role == "lead" then w.leadSpoke, w.leadId, w.leadName = true, tostring(rec.id), rName
        elseif role == "wingman" then w.wingmanSpoke, w.wingmanId, w.wingmanName = true, tostring(rec.id), rName end
    end
end

function Service.EnqueueAllyReplies(caller, warningResult, now, eventRef)
    local notified = type(warningResult) == "table" and warningResult.notified or nil
    if type(notified) ~= "table" or #notified == 0 then return 0 end
    local w = {
        callerId = tostring(caller and caller.id or ""),
        callerName = tostring(caller and (caller.name or caller.fullName) or ""),
        leadSpoke = false, wingmanSpoke = false,
    }
    local queued, count = 0, math.min(MAX_REPLIES_PER_WARNING, #notified)
    for idx = 1, count do
        local item = notified[idx]
        local ally = type(item) == "table" and item.record or nil
        if type(ally) == "table" and ally.id ~= nil and ally.alive ~= false then
            while #Service.PendingReplies >= MAX_PENDING_REPLIES do table.remove(Service.PendingReplies, 1) end
            local engage = item.canEngage == true
            Service.PendingReplies[#Service.PendingReplies + 1] = {
                allyId = tostring(ally.id), allyRecord = ally, callerRecord = caller,
                callerId = w.callerId, callerName = w.callerName,
                teamKey = tostring(warningResult.teamKey or w.callerId or "team"),
                desc = warningResult.descriptor, canEngage = engage,
                role = ROLE_BY_IDX[idx] or "wingman", wave = w,
                eventType = engage and "combat_ally_warn_reply_alerted" or "combat_ally_warn_reply_defensive",
                act = engage and "ACK" or "REACT",
                barkId = engage and "bark.alert_hey" or "bark.whisper_check",
                eventRef = tostring(eventRef or "") .. ":reply:" .. tostring(ally.id),
                dueAt = now + replyDelay(idx, ally.id), expiresAt = now + 6000,
            }
            queued = queued + 1
        end
    end
    syncQueueMeta()
    return queued
end

function Service.PumpPendingReplies(now)
    if (tonumber(Service.PendingReplyCount) or 0) <= 0 then return 0 end
    now = Service.Finite(now) or (PNC.Core and PNC.Core.Now and Service.Finite(PNC.Core.Now())) or 0
    if Service.NextReplyDueAt ~= nil and now < Service.NextReplyDueAt then return 0 end
    local reg, perc, sec = PNC.Registry, PNC.Perception, PNC.SecondaryChannel
    cachedProfileMod = cachedProfileMod or PNC.Semantics.CombatReactionProfile
        or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"
    local remaining, fired = {}, 0
    for i = 1, #Service.PendingReplies do
        local entry = Service.PendingReplies[i]
        if now < entry.dueAt then
            remaining[#remaining + 1] = entry
        elseif now < (entry.expiresAt or math.huge) then
            local rec = (reg and type(reg.Get) == "function" and reg.Get(entry.allyId)) or entry.allyRecord
            if type(rec) == "table" and rec.alive ~= false then
                dispatchReply(entry, rec, now, reg, perc, sec)
                fired = fired + 1
            end
        end
    end
    Service.PendingReplies = remaining
    syncQueueMeta()
    return fired
end

function Service.ResetRuntime()
    Service.PendingReplies, Service.PendingReplyCount, Service.NextReplyDueAt = {}, 0, nil
end

return Service

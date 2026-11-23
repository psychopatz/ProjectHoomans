-- Dispatch and wave role helpers for pending ally replies.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Delivery"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

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

function S.DispatchPendingReply(e, rec, now, reg, perc, sec)
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
    local text, res = S.ResolveSemanticLine(rec, ev, act, tCls, e.eventRef, nil, toks, {
        replyRole = role,
        topic = e.topic,
        context = e.extraContext,
    })
    if not text then return end
    local sent = S.SendReplyBark(rec, now, ev, act, e.eventRef, text, res, toks, e.barkOpts, e.threadID)
    if (tonumber(sent) or 0) <= 0 then return end
    if e.onDelivered then e.onDelivered(rec, now) end
    local w = e.wave
    if w then
        local rName = tostring(rec.name or rec.fullName or "")
        if role == "lead" then w.leadSpoke, w.leadId, w.leadName = true, tostring(rec.id), rName
        elseif role == "wingman" then w.wingmanSpoke, w.wingmanId, w.wingmanName = true, tostring(rec.id), rName end
    end
end

return S

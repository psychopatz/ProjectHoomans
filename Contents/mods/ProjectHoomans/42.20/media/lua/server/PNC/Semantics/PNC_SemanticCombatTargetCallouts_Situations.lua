if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_SituationQuery"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local SIT_BARK_OPTS = I.SituationBarkOpts

function I.EmitSituationCallout(speaker, addr, desc, role, now, ref, extraTokens)
    local tone = S.ResolveAllyWarnTone(speaker, nil)
    local toks = S.BuildRichSpeechTokens
        and S.BuildRichSpeechTokens(speaker, addr, desc, now, tone, { skipLocation = true }) or {}
    if type(extraTokens) == "table" then
        for k, v in pairs(extraTokens) do toks[k] = v end
    end
    local tCls = desc and desc.semanticClass or "human_hostile"
    local text, res = S.ResolveSemanticLine(
        speaker, "combat_ally_warn_callout", "WARN", tCls, ref, nil, toks, { replyRole = role }
    )
    if not text then return false end
    local sec = PNC.SecondaryChannel
    if sec and type(sec.RequestBark) == "function" then sec.RequestBark(speaker, "bark.alert_hey", now) end
    local sent = S.DeliverBark(speaker, now, {
        eventType = "combat_ally_warn_callout",
        speechEventID = res and res.realizationID or ("semantic.combat." .. tostring(role)),
        act = "WARN", family = SIT_BARK_OPTS.family, cooldownMs = SIT_BARK_OPTS.cooldownMs,
        familyCooldownMs = SIT_BARK_OPTS.familyCooldownMs, priority = SIT_BARK_OPTS.priority,
        priorityHoldMs = SIT_BARK_OPTS.priorityHoldMs, ttlMs = SIT_BARK_OPTS.ttlMs,
        interrupt = role == "blindside",
        clientCooldowns = SIT_BARK_OPTS.clientCooldowns, threadID = ref,
        streamKey = "ally-warn-sit:" .. tostring(speaker.id),
        eventRef = ref, text = text, presentationClass = res and res.presentationClass or "BARK",
        context = { eventType = "combat_ally_warn_callout", eventRef = ref, threadID = ref, transient = true },
    })
    return (tonumber(sent) or 0) > 0
end

local function turnToward(ally, tx, ty, now)
    local ax, ay = tonumber(ally.x) or tx, tonumber(ally.y) or ty
    local dx, dy = tx - ax, ty - ay
    local len = math.sqrt((dx * dx) + (dy * dy))
    ally.runtime = type(ally.runtime) == "table" and ally.runtime or {}
    if len > 0.05 then ally.runtime.facingDirX, ally.runtime.facingDirY = dx / len, dy / len end
    local sec = PNC.SecondaryChannel
    if sec and sec.SetAlertLevel then sec.SetAlertLevel(ally, "tense") end
    if sec and sec.RequestGaze then sec.RequestGaze(ally, tx, ty, 3500, now) end
end

function S.TryEmitBlindsideWarning(caller, ally, desc, now, ref)
    if type(caller) ~= "table" or type(ally) ~= "table" or type(desc) ~= "table" then return false end
    now = I.SituationNow(now)
    local perc = PNC.Perception
    local teamKey = perc and perc.GetTeamKey and perc.GetTeamKey(caller) or nil
    local sk = perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) or nil
    if sk and (now - (tonumber(sk.lastBeatAt) or 0)) < 6000 then return false end
    if perc and perc.MarkSkirmishBeat then perc.MarkSkirmishBeat(teamKey, "blindside", now) end
    turnToward(ally, tonumber(desc.x) or 0, tonumber(desc.y) or 0, now)
    ref = tostring(ref or ("blindside:" .. tostring(caller.id)))
    local spoke = I.EmitSituationCallout(caller, ally, desc, "blindside", now, ref)
    if spoke and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = ally, addressee = caller, desc = desc, role = "blindside_reply",
            now = now, delayMs = 600, eventRef = ref .. ":b_reply", threadID = ref, barkOpts = SIT_BARK_OPTS,
        })
    end
    return spoke
end

function S.TryEmitLastStragglerBeat(caller, ally, desc, now, ref)
    if type(caller) ~= "table" or type(desc) ~= "table" then return false end
    now = I.SituationNow(now)
    local perc = PNC.Perception
    local teamKey = perc and perc.GetTeamKey and perc.GetTeamKey(caller) or nil
    local sk = perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) or nil
    if not sk or sk.lastOneSpoken or (tonumber(sk.initialCount) or 1) < 3 or (tonumber(desc.enemyCount) or 1) ~= 1 then
        return false
    end
    local addr = ally or I.FindSquadmates(caller, 16)[1]
    if not addr then return false end
    if perc and perc.MarkSkirmishBeat then perc.MarkSkirmishBeat(teamKey, "last_one", now) end
    ref = tostring(ref or ("lastone:" .. tostring(caller.id)))
    local spoke = I.EmitSituationCallout(caller, addr, desc, "last_one", now, ref)
    if spoke and S.EnqueueCustomReply then
        S.EnqueueCustomReply({
            speaker = addr, addressee = caller, desc = desc, role = "last_one_reply",
            now = now, delayMs = 650, eventRef = ref .. ":l_reply", threadID = ref, barkOpts = SIT_BARK_OPTS,
        })
    end
    return spoke
end

function S.HandleSkirmishActive(record, warningResult, now, ref)
    if warningResult.blindsideAlly then
        local ok = S.TryEmitBlindsideWarning(record, warningResult.blindsideAlly, warningResult.descriptor, now, ref)
        return ok, ok and "blindside_warning" or "skirmish_already_active"
    end
    if warningResult.lastOneReady then
        local ok = S.TryEmitLastStragglerBeat(record, warningResult.notifiedAlly, warningResult.descriptor, now, ref)
        return ok, ok and "last_straggler" or "skirmish_already_active"
    end
    if type(S.OnFightingWhileInjured) == "function" then
        local okInj, reasonInj = S.OnFightingWhileInjured(record, warningResult.descriptor, now, { threadID = ref })
        if okInj then return true, reasonInj end
    end
    return false, "skirmish_already_active"
end

return S

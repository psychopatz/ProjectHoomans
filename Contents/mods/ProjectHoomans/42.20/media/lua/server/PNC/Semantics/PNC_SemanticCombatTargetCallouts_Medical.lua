if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Situations"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local function inspectInjuryAndBandages(rec)
    if type(rec) ~= "table" or rec.alive == false then return false, false, false end
    local h = type(rec.health) == "table" and rec.health or nil
    local body = h and type(h.body) == "table" and h.body or nil
    local rate = tonumber((body and body.bleedingRate) or (h and h.bleedingRate)) or 0
    local open = tonumber((body and body.openWoundCount) or (h and h.openWoundCount)) or 0
    local bleeding = (rate > 0) or (open > 0) or (h and h.bleeding == true) or false
    if not bleeding and type(rec.wounds) == "table"
        and PNC.NPCWounds and type(PNC.NPCWounds.BuildStatusSummary) == "function"
    then
        local st = PNC.NPCWounds.BuildStatusSummary(rec)
        bleeding = st and (st.bleeding == true or (tonumber(st.openWoundCount) or 0) > 0) or false
    end
    local hState = tostring(h and h.state or "")
    local cur, mx = tonumber(h and h.current), tonumber(h and h.max)
    local injured = bleeding or hState == "injured" or hState == "wounded" or hState == "critical"
        or (cur ~= nil and mx ~= nil and mx > 0 and cur < mx * 0.92)
    local tr, hasB = PNC.Treatment, false
    if tr then
        if type(tr.HasNPCBandage) == "function" then hasB = tr.HasNPCBandage(rec) == true
        elseif type(tr.GetNPCBandagePlan) == "function" then
            hasB = tr.GetNPCBandagePlan(rec, { consumeItem = true }) ~= nil
        end
    end
    return injured == true, bleeding == true, hasB == true
end

local function queueSitReply(sp, addr, desc, role, now, delayMs, ref, canEngage, threadId)
    if not S.EnqueueCustomReply then return end
    S.EnqueueCustomReply({
        speaker = sp, addressee = addr, desc = desc, role = role,
        canEngage = canEngage ~= false, now = now, delayMs = delayMs,
        eventRef = ref, threadID = threadId, barkOpts = I.SituationBarkOpts,
    })
end

function S.OnAllyBandagingUnderThreat(actor, patient, now)
    if type(actor) ~= "table" or actor.alive == false or actor.id == nil then return false end
    now = I.SituationNow(now)
    actor.runtime = type(actor.runtime) == "table" and actor.runtime or {}
    if now - (tonumber(actor.runtime.lastBandageCalloutAt) or -99999) < 8000 then return false end
    local mates = I.FindSquadmates(actor, 14)
    if #mates == 0 then return false end
    local perc = PNC.Perception
    local teamKey = perc and perc.GetTeamKey and perc.GetTeamKey(actor) or nil
    local underThreat = (perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) ~= nil)
        or type(actor.runtime.target) == "table"
    local coverAlly = nil
    for i = 1, #mates do
        local m = mates[i]
        if type(m.runtime) == "table" and type(m.runtime.target) == "table" then underThreat = true end
        if not coverAlly and tostring(m.attackType or "auto") ~= "none" then coverAlly = m end
    end
    if not underThreat or not coverAlly then return false end
    actor.runtime.lastBandageCalloutAt = now
    local isSelf = (patient == nil or patient == actor or tostring(patient.id or "") == tostring(actor.id))
    local role = isSelf and "bandaging_self" or "bandaging_ally"
    local pName = not isSelf and (S.FirstTokenName and S.FirstTokenName(patient.name or patient.fullName)
        or tostring(patient.name or "friend")) or nil
    local desc = { semanticClass = "human_hostile", enemyType = "hostile", x = actor.x, y = actor.y, z = actor.z }
    local ref = "bandage:" .. tostring(actor.id) .. ":" .. tostring(math.floor(now))
    local spoke = I.EmitSituationCallout(actor, coverAlly, desc, role, now, ref, pName and { ["target.name"] = pName } or nil)
    if spoke then queueSitReply(coverAlly, actor, desc, "cover_bandage", now, 600, ref .. ":cover", true, ref) end
    return spoke
end

function S.OnTargetCleared(record, previousTarget, reason, now)
    if type(record) ~= "table" or record.alive == false or record.id == nil or previousTarget == nil then return false end
    now = I.SituationNow(now)
    local perc = PNC.Perception
    local teamKey = perc and perc.GetTeamKey and perc.GetTeamKey(record) or nil
    local sk = perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) or nil
    if not sk or sk.checkinSpoken then return false end
    local mates = I.FindSquadmates(record, 14)
    if #mates == 0 then return false end
    for i = 1, #mates do
        local rt = mates[i].runtime
        if type(rt) == "table" and type(rt.target) == "table" then return false end
    end
    local injAlly, injHasB, medic, checker = nil, false, nil, nil
    for i = 1, #mates do
        local inj, _, hasB = inspectInjuryAndBandages(mates[i])
        if inj and not injAlly then injAlly, injHasB = mates[i], hasB
        elseif hasB and not medic then medic = mates[i] end
    end
    local selfInj, _, selfHasB = inspectInjuryAndBandages(record)
    if injAlly then checker = record
    elseif selfInj then injAlly, injHasB, checker = record, selfHasB, mates[1] end

    local desc = { semanticClass = "human_hostile", enemyType = "hostile", x = record.x, y = record.y, z = record.z }
    local ref = "checkin:" .. tostring(record.id) .. ":" .. tostring(math.floor(now))
    if injAlly and checker then
        if perc and perc.MarkSkirmishBeat then perc.MarkSkirmishBeat(teamKey, "checkin", now) end
        if not I.EmitSituationCallout(checker, injAlly, desc, "checkin_injured", now, ref) then return false end
        local injCanEngage = injAlly.attackType ~= "none"
        if injHasB then
            queueSitReply(injAlly, checker, desc, "injured_has_bandage", now, 650, ref .. ":hasb", injCanEngage, ref)
        else
            queueSitReply(injAlly, checker, desc, "injured_no_bandage", now, 650, ref .. ":nob", injCanEngage, ref)
            local _, _, checkerHasB = inspectInjuryAndBandages(checker)
            local helper = checkerHasB and checker or medic
            queueSitReply(helper or checker, injAlly, desc, helper and "medic_has_bandage" or "medic_no_bandage", now, 1450, ref .. ":med", true, ref)
        end
        return true
    elseif (tonumber(sk.initialCount) or 1) >= 3 then
        if perc and perc.MarkSkirmishBeat then perc.MarkSkirmishBeat(teamKey, "checkin", now) end
        if not I.EmitSituationCallout(record, mates[1], desc, "checkin_clear", now, ref) then return false end
        queueSitReply(mates[1], record, desc, "checkin_ok", now, 650, ref .. ":ok1", mates[1].attackType ~= "none", ref)
        if mates[2] then queueSitReply(mates[2], mates[1], desc, "checkin_ok", now, 1350, ref .. ":ok2", mates[2].attackType ~= "none", ref) end
        return true
    end
    return false
end

return S

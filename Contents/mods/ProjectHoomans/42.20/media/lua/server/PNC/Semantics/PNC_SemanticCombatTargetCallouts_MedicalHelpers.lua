-- Shared injury/bandage inspection and post-skirmish check-in target selection helpers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.Semantics.CombatTargetCalloutsInternal = I

function I.InspectInjuryAndBandages(rec)
    if type(rec) ~= "table" or rec.alive == false then return false, false, false end
    local wounds = PNC.NPCWounds
    local proj = wounds and type(wounds.GetOrBuildProjection) == "function" and wounds.GetOrBuildProjection(rec) or nil
    local h = type(rec.health) == "table" and rec.health or nil
    local bleeding = proj and ((proj.bleedingRate or 0) > 0 or (proj.openWoundCount or 0) > 0)
        or (h and h.bleeding == true) or false
    if not proj and type(rec.wounds) == "table" and wounds and type(wounds.BuildStatusSummary) == "function" then
        local st = wounds.BuildStatusSummary(rec)
        bleeding = st and (st.bleeding == true or (tonumber(st.openWoundCount) or 0) > 0) or false
    end
    local hState = tostring(h and h.state or "")
    local cur, mx = tonumber(h and h.current), tonumber(h and h.max)
    local injured = (proj and proj.injured == true) or bleeding or hState == "injured" or hState == "wounded"
        or hState == "critical" or (cur ~= nil and mx ~= nil and mx > 0 and cur < mx * 0.92)
    local tr = PNC.Treatment
    local hasB = tr and ((type(tr.HasNPCBandage) == "function" and tr.HasNPCBandage(rec) == true)
        or (type(tr.GetNPCBandagePlan) == "function" and tr.GetNPCBandagePlan(rec, { consumeItem = true }) ~= nil)) or false
    return injured == true, bleeding == true, hasB == true
end

function I.FindCheckinTarget(record, mates)
    for i = 1, #mates do
        local rt = mates[i].runtime
        if type(rt) == "table" and type(rt.target) == "table" then return nil end
    end
    local injAlly, injHasB, medic, checker = nil, false, nil, nil
    for i = 1, #mates do
        local inj, _, hasB = I.InspectInjuryAndBandages(mates[i])
        if inj and not injAlly then injAlly, injHasB = mates[i], hasB elseif hasB and not medic then medic = mates[i] end
    end
    local selfInj, _, selfHasB = I.InspectInjuryAndBandages(record)
    if injAlly then checker = record elseif selfInj then injAlly, injHasB, checker = record, selfHasB, mates[1] end
    return injAlly, injHasB, medic, checker
end

return I

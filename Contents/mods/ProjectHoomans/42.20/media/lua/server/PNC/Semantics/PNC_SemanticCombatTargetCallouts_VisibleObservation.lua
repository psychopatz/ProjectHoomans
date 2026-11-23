-- Non-colonist and survivor visible-condition observation Beat (combat.injury.visible_observation)
-- with epistemic truthfulness (observerCanInferOnly vs medic/inspector/witness epistemic authority).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WitnessGating"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_SituationQuery"

local TriageOffers = require "PNC/ConvoEngine/Dialogue/InjuryTriageOffers"
local ObservationScene = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_ObservationScene"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local OBS_OPTS = {
    family = "combat_injury_visible_observation",
    priority = 68, priorityHoldMs = 600, cooldownMs = 1500, familyCooldownMs = 1500, ttlMs = 9000,
    topic = "combat_injury",
    clientCooldowns = { familyMs = 1200, speakerMs = 1400, ambientMs = 350, mergeWindowMs = 0 },
}

local function epistemicPolicy(obs, _inj, opts)
    local sk = type(obs.skills) == "table" and obs.skills or nil
    local fa = sk and (tonumber(sk.FirstAid) or tonumber(sk.Doctor) or 0) or 0
    local isMed = fa >= 2 or tostring(obs.role or obs.tacticalRole or "") == "medic"
    local canDiag = opts and (opts.inspected == true or opts.toldByInjured == true)
    return { isMedic = isMed, firstAidLevel = fa, observerCanInferOnly = not canDiag, canStatePreciseDiagnosis = canDiag == true }
end
S.ResolveObserverEpistemicPolicy = epistemicPolicy

function S.ResolveVisibleObservationVariant(_obs, _inj, prof, delta, ep)
    local sel = prof.selectedWound or prof
    local exposed = sel.bandaged ~= true
    local med = ep and ep.isMedic == true
    local phys = prof.physiology or {}
    local bleeding = sel.bleedingBand or prof.bleedingBand
    if bleeding == "heavy" or bleeding == "critical" then return "heavy_bleeding" end
    if sel.bandaged and sel.bandageDirty then return "dirty_bandage" end
    if exposed and sel.woundType == "bite" then return "visible_bite" end
    if (exposed or (ep and ep.canStatePreciseDiagnosis)) and sel.ordinaryInfection == true then
        return med and ep.canStatePreciseDiagnosis and "medic_infection_assessment" or "suspected_infection"
    end
    if phys.feverBand == "feverish" or phys.feverBand == "high_fever" then return "feverish_weak" end
    if sel.locomotionImpaired == true then return "limp_mobility" end
    if delta and delta.newSinceLastObservation and (exposed or sel.bandaged) then
        return (prof.woundCountBand == "multiple" or prof.woundCountBand == "extensive")
            and "multiple_wounds_escalation" or "new_wound_noticed"
    end
    if exposed and (sel.bleeding or sel.woundType == "scratch" or sel.woundType == "laceration"
        or sel.woundType == "deep_wound") then return med and "medic_triage_offer" or "open_wound" end
    if sel.bandaged or sel.splinted then return "default" end
end

local VISIBLE_CLAIMS = {
    heavy_bleeding = { clauses = { { claims = { "bleeding" } } } },
    dirty_bandage = { clauses = { { claims = { "bandaged", "bandageDirty" } } } },
    limp_mobility = { clauses = { { claims = { "locomotionImpaired" } } } },
    feverish_weak = { clauses = { { claims = { "fever" } } } },
    medic_infection_assessment = { clauses = { { claims = { "ordinaryInfection" } } } },
}

local OPEN_OBSERVATION_ROLES = {
    supportive = "observer_supportive", clinical = "observer_clinical", protective = "observer_protective",
    dismissive = "observer_dismissive", hostile = "observer_hostile",
}

function S.OnVisibleConditionObserved(obs, inj, now, opts)
    if type(obs) ~= "table" or obs.alive == false or obs.id == nil then return false, "invalid_observer" end
    if type(inj) ~= "table" or inj.alive == false or inj.id == nil then return false, "invalid_injured" end
    local prof = S.ClassifyActorWoundProfile(inj)
    if obs.id == inj.id then return false, "same_actor" end
    if not prof then return false, "target_not_injured" end
    now = I.SituationNow(now)
    local ok, gateR, delta = S.EvaluateWitnessObservationGate(obs, inj, prof, now, opts)
    if not ok then return false, gateR, delta end

    local ep = epistemicPolicy(obs, inj, opts)
    local variant = S.ResolveVisibleObservationVariant(obs, inj, prof, delta, ep)
    if not variant then return false, "condition_not_visible" end
    if not I.CanSeeInjury(obs, inj) then return false, "no_line_of_sight" end
    local openWound = variant == "open_wound" or variant == "medic_triage_offer"
    if openWound then
        local aid = require "PNC/Semantics/PNC_SemanticInjuryAid"
        variant = OPEN_OBSERVATION_ROLES[aid.ObserverPolicy(obs, inj)] or variant
    end
    local addrName = (S.FirstTokenName and S.FirstTokenName(inj.name or inj.fullName)) or tostring(inj.name or "survivor")
    local toks = { ["addressee.name"] = addrName, ["slot.wound.part"] = prof.partToken, ["slot.wound.label"] = prof.woundLabel }
    local ref = "vis-obs:" .. tostring(obs.id) .. ":" .. tostring(inj.id) .. ":" .. tostring(math.floor(now))
    local ctx = {
        combatReactionRole = variant, combatWoundType = prof.effectiveWoundTier,
        woundPartRegion = prof.bodyRegion, woundSeverityBand = prof.physicalSeverityBand,
        woundPatchState = prof.patchState, woundCountBand = prof.woundCountBand,
        newSinceLastObservation = delta and delta.newSinceLastObservation == true,
        observationChangeReason = gateR, observerCanInferOnly = ep.observerCanInferOnly,
        canStatePreciseDiagnosis = ep.canStatePreciseDiagnosis,
        flowID = "combat.injury.triage_exchange", injuryProfile = prof,
        selectedWound = prof.selectedWound, observedTargetID = tostring(inj.id),
    }
    local text, res = S.ResolveSemanticLine(
        obs, "combat_injury_visible_observation", "WARN",
        "human_hostile", ref, nil, toks, { replyRole = variant, topic = "combat_injury", inCombat = false, poolID = "semantic.combat.injury.visible_observation", context = ctx,
            utteranceEvidence = VISIBLE_CLAIMS[variant] }
    )
    if not text then return false, "observation_realization_unavailable" end

    local facts = { [ref] = {
        eventRef = ref, authoritative = true, disclosure = "player",
        summary = text, happened = text, observation = variant,
    } }
    local presentation = {
        eventType = "combat_injury_visible_observation", eventRef = ref, threadID = ref, transient = true,
    }

    local interactive = variant == "heavy_bleeding" or (openWound and variant ~= "observer_hostile")
        or variant == "dirty_bandage" or variant == "suspected_infection"
    local active = obs.runtime and obs.runtime.activeInjuryObservation
    if active and now < active.untilAt then interactive = false end
    local offerIDs = interactive and TriageOffers.IDs(TriageOffers.INITIAL_NODE) or nil
    interactive = offerIDs and #offerIDs > 0
    local sent = S.DeliverBark(obs, now, {
        eventType = "combat_injury_visible_observation",
        speechEventID = res and res.realizationID or ("semantic.combat.injury.visible_observation." .. variant),
        act = "WARN", topic = "combat_injury", family = OBS_OPTS.family,
        cooldownMs = OBS_OPTS.cooldownMs, familyCooldownMs = OBS_OPTS.familyCooldownMs,
        priority = OBS_OPTS.priority, priorityHoldMs = OBS_OPTS.priorityHoldMs, ttlMs = OBS_OPTS.ttlMs,
        responsePlanID = interactive and TriageOffers.PlanID(TriageOffers.INITIAL_NODE) or (res and res.responsePlanID),
        realizationID = res and res.realizationID or ("semantic.combat.injury.visible_observation." .. variant),
        poolID = res and res.poolID, realizationFamily = res and res.realizationFamily,
        flowID = TriageOffers.FLOW_ID, observerOnly = not interactive, recipientKind = "player",
        offerIDs = offerIDs, factRefs = { ref }, semanticEventFacts = facts,
        lightweightBark = not interactive, clientCooldowns = OBS_OPTS.clientCooldowns,
        threadID = ref, streamKey = "vis-obs:" .. tostring(obs.id) .. ":" .. tostring(inj.id),
        eventRef = ref, text = text, presentationClass = res and res.presentationClass or "BARK", context = presentation,
    })
    if (tonumber(sent) or 0) <= 0 then return false, "observation_not_delivered" end
    S.RecordWitnessObservation(obs, inj, prof, now, opts)
    if interactive then ObservationScene.Bind(obs, inj, ref, prof.partId, now) end
    return true, variant, { text = text, variant = variant, changeReason = gateR, deltaFacts = delta, epistemic = ep }
end

local function mayHaveVisibleWound(actor)
    local body = actor.health and actor.health.body
    return body and ((tonumber(body.openWoundCount) or 0) > 0 or (tonumber(body.patchedWoundCount) or 0) > 0
        or (tonumber(body.bandagedWoundCount) or 0) > 0 or (tonumber(body.bleedingRate) or 0) > 0)
end

function S.OnInjuryEncounterCellChanged(actor, now)
    local injured = mayHaveVisibleWound(actor)
    local neighbors = I.FindInjuryEncounterNeighbors(actor, 6)
    for i = 1, math.min(4, #neighbors) do
        local other = neighbors[i].record
        if injured and S.OnVisibleConditionObserved(other, actor, now) then return true end
        if mayHaveVisibleWound(other) and S.OnVisibleConditionObserved(actor, other, now) then return true end
    end
    return false
end

return S

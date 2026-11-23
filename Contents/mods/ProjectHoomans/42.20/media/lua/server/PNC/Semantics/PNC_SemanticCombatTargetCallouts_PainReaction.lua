-- Immediate atomic pain-reaction Beat (combat.injury.pain_reaction) and escalation-aware cooldown policy.
-- Fires immediately on newly received wounds even when no conversational addressee is available,
-- consuming selected-wound truth, numeric disposition/panic, and wound count escalation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundProfile"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_PainPolicy"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local PAIN_BARK_OPTS = {
    family = "combat_injury_pain",
    priority = 76,
    priorityHoldMs = 0,
    cooldownMs = 1800,
    familyCooldownMs = 1800,
    ttlMs = 7000,
    topic = "combat_injury",
    clientCooldowns = { familyMs = 700, speakerMs = 900, ambientMs = 200, mergeWindowMs = 0 },
}

function S.EmitImmediatePainReaction(record, hitSpec, profile, now, opts)
    if type(record) ~= "table" or record.alive == false or record.id == nil then return false, "invalid_target" end
    profile = type(profile) == "table" and profile or S.ClassifyActorWoundProfile(record, hitSpec)
    if not profile then return false, "no_wound_profile" end
    now = I.SituationNow(now)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}

    local eligible, preemptReason = true, "forced"
    if not (opts and opts.ignoreCooldown == true) then
        eligible, preemptReason = S.ShouldPreemptWoundCooldown(record, profile, now, 2500)
    end
    if not eligible then return false, preemptReason end

    local isPreempt = preemptReason ~= "cooldown_expired" and preemptReason ~= "first_wound"
    local variant = S.ResolvePainReactionVariant(record, profile)
    local addrName = (S.FirstTokenName and S.FirstTokenName(record.name or record.fullName))
        or tostring(record.name or "survivor")
    local toks = {
        ["addressee.name"] = addrName,
        ["slot.wound.part"] = profile.partToken,
        ["slot.wound.label"] = profile.woundLabel,
    }
    local ref = "pain:" .. tostring(record.id) .. ":" .. tostring(math.floor(now)) .. ":" .. tostring(profile.injuryRevision or 1)
    local ctx = {
        combatReactionRole = variant,
        combatWoundType = profile.effectiveWoundTier,
        woundPartRegion = profile.bodyRegion,
        woundSeverityBand = profile.physicalSeverityBand,
        woundPatchState = profile.patchState,
        injuryProfile = profile,
        selectedWound = profile.selectedWound,
        preemptReason = preemptReason,
    }
    local text, res = S.ResolveSemanticLine(
        record, "combat_injury_pain_reaction", "REACT",
        "human_hostile", ref, nil, toks, { replyRole = variant, topic = "combat_injury", context = ctx }
    )
    if not text then return false, "pain_realization_unavailable" end

    local facts = {
        [ref] = {
            eventRef = ref,
            authoritative = true,
            disclosure = "player",
            summary = profile.woundLabel .. " on " .. profile.partToken,
            happened = profile.woundLabel .. " on " .. profile.partToken,
            woundType = profile.woundType,
            effectiveWoundTier = profile.effectiveWoundTier,
            bodyRegion = profile.bodyRegion,
            partId = profile.partId,
            severityBand = profile.severityBand,
            patchState = profile.patchState,
            salivaTransmissible = profile.salivaTransmissible,
        },
    }
    ctx.responsePlan = res and res.responsePlan or nil
    ctx.responsePlanID = res and res.responsePlanID or nil
    ctx.realizationID = res and res.realizationID or nil
    ctx.flowID = "combat.injury.triage_exchange"
    ctx.eventType = "combat_injury_pain_reaction"
    ctx.eventRef = ref
    ctx.threadID = ref
    ctx.transient = true

    local cdMs = isPreempt and 0 or PAIN_BARK_OPTS.cooldownMs
    local streamKey = isPreempt
        and ("combat-pain:" .. tostring(record.id) .. ":" .. tostring(variant) .. ":" .. tostring(profile.injuryRevision or 1))
        or ("combat-pain:" .. tostring(record.id))
    local sent = S.DeliverBark(record, now, {
        eventType = "combat_injury_pain_reaction",
        speechEventID = res and res.realizationID or ("semantic.combat.injury.pain_reaction." .. variant),
        act = "REACT",
        topic = "combat_injury",
        family = isPreempt and ("combat_injury_pain_" .. variant) or PAIN_BARK_OPTS.family,
        cooldownMs = cdMs,
        familyCooldownMs = cdMs,
        priority = (profile.isBite or profile.woundType == "bullet") and 82 or PAIN_BARK_OPTS.priority,
        priorityHoldMs = PAIN_BARK_OPTS.priorityHoldMs,
        ttlMs = PAIN_BARK_OPTS.ttlMs,
        responsePlanID = res and res.responsePlanID or nil,
        realizationID = res and res.realizationID or nil,
        poolID = res and res.poolID or nil,
        realizationFamily = res and res.realizationFamily or nil,
        flowID = "combat.injury.triage_exchange",
        observerOnly = false,
        recipientKind = "player",
        offerIDs = res and res.offerIDs or nil,
        factRefs = { ref },
        semanticEventFacts = facts,
        lightweightBark = true,
        interrupt = isPreempt or profile.isBite == true or profile.physicalSeverityBand == "critical",
        clientCooldowns = PAIN_BARK_OPTS.clientCooldowns,
        threadID = ref,
        streamKey = streamKey,
        eventRef = ref,
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
    })

    local sel = type(profile.selectedWound) == "table" and profile.selectedWound or profile
    record.runtime.lastPainBeatAt = now
    record.runtime.lastPainBeatPriority = profile.woundTierPriority
    record.runtime.lastPainBeatSeverityRank = S.SeverityRank(sel.physicalSeverity or profile.physicalSeverityBand)
    record.runtime.lastPainBeatRegion = tostring(sel.bodyRegion or profile.bodyRegion or "torso")
    record.runtime.lastPainBeatVariant = variant
    record.runtime.lastPainBeatText = text
    return true, variant, { sent = sent, text = text, variant = variant, preemptReason = preemptReason }
end

return S

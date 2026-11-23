-- Wound dialogue delivery and staggered ally reaction enqueueing.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundRoles"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_InjuryScene"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local WoundComposition = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundComposition"

local WOUND_BARK_OPTS = {
    family = "combat_wound_beat",
    priority = 72,
    priorityHoldMs = 900,
    cooldownMs = 1000,
    familyCooldownMs = 1000,
    ttlMs = 9000,
    topic = "combat_injury",
    clientCooldowns = { familyMs = 1200, speakerMs = 1400, ambientMs = 350, mergeWindowMs = 0 },
}

local function buildWoundTokens(addr, profile)
    local addrName = (S.FirstTokenName and S.FirstTokenName(addr and (addr.name or addr.fullName)))
        or tostring(addr and addr.name or "friend")
    return {
        ["addressee.name"] = addrName,
        ["slot.wound.part"] = profile.partToken,
        ["slot.wound.label"] = profile.woundLabel,
    }
end

function I.EmitWoundDialogue(record, evType, roleVariant, profile, hitDesc, now, pri, ref, opts)
    local mates = I.FindNearbyInjuryObservers(record, 14)
    local responders = I.SelectWoundResponders(mates, record, profile, now, { witnessedHit = evType == "combat_wound_received_beat" })
    local playerAddr = I.FindNearbyPlayerAddressee(record, 14)
    local addressee = (responders[1] and responders[1].ally) or mates[1] or playerAddr
    if not addressee then return false, "no_audience" end
    if opts and opts.skipReplies == true then responders = {} end
    local pBand = #mates == 0 and "solo" or (#mates == 1 and "duo" or "squad")
    local pCount = math.min(4, 1 + (#mates > 0 and #mates or (playerAddr and 1 or 0)))
    local toks = buildWoundTokens(addressee, profile)
    local ctx = {
        combatReactionRole = roleVariant,
        combatWoundType = profile.effectiveWoundTier,
        woundPartRegion = profile.bodyRegion,
        woundSeverityBand = profile.severityBand,
        woundPatchState = profile.patchState,
        salivaTransmissible = profile.salivaTransmissible,
        participantBand = pBand,
        participantCount = pCount,
        flowID = "combat.injury.triage_exchange",
        injuryProfile = profile,
    }
    local text, res = S.ResolveSemanticLine(
        record, evType, evType == "combat_wound_received_beat" and "REACT" or "WARN",
        "human_hostile", ref, nil, toks, { replyRole = roleVariant, topic = "combat_injury", context = ctx }
    )
    if evType == "combat_fighting_injured_callout" then
        local composed = WoundComposition.Realize(profile, { styleVariant = S.ResolveAllyWarnTone(record, nil) })
        if composed then
            text = composed.text
            ctx.utteranceEvidence = { clauses = composed.clauses, relations = composed.relations }
        end
    end
    if not text then return false, "semantic_realization_unavailable" end

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
            participantCount = pCount,
            participantBand = pBand,
        },
    }
    ctx.responsePlan = res and res.responsePlan or nil
    ctx.responsePlanID = res and res.responsePlanID or nil
    ctx.realizationID = res and res.realizationID or nil
    ctx.biteConflictFacts = record.runtime and record.runtime.biteConflictFacts or nil
    ctx.biteExecutionThreat = record.runtime and (record.runtime.biteConflictFacts or record.runtime.biteExecutionThreat) or nil
    ctx.eventType = evType
    ctx.eventRef = ref
    ctx.threadID = ref
    ctx.transient = true
    local sec = PNC.SecondaryChannel
    if sec and type(sec.RequestBark) == "function" then sec.RequestBark(record, "bark.alert_hey", now) end
    local isPreempt = opts and opts.isPreempt == true
    local cdMs = isPreempt and 0 or WOUND_BARK_OPTS.cooldownMs
    local familyName = isPreempt
        and ("combat_wound_beat_" .. tostring(profile.effectiveWoundTier))
        or WOUND_BARK_OPTS.family
    local streamKey = isPreempt
        and ("combat-wound:" .. tostring(record.id) .. ":" .. tostring(profile.effectiveWoundTier))
        or ("combat-wound:" .. tostring(record.id))
    local sent = S.DeliverBark(record, now, {
        eventType = evType,
        speechEventID = res and res.realizationID or ("semantic." .. evType),
        act = evType == "combat_wound_received_beat" and "REACT" or "WARN",
        topic = "combat_injury",
        family = familyName,
        cooldownMs = cdMs,
        familyCooldownMs = cdMs,
        priority = pri,
        priorityHoldMs = 900,
        ttlMs = 9000,
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
        interrupt = isPreempt or profile.isBite == true or profile.severityBand == "critical",
        clientCooldowns = WOUND_BARK_OPTS.clientCooldowns,
        threadID = ref,
        streamKey = streamKey,
        eventRef = ref,
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
    })
    if (tonumber(sent) or 0) <= 0 then return false, "no_audience" end
    if type(S.RecordHighSalienceInjuryMemory) == "function" then
        S.RecordHighSalienceInjuryMemory(record, {
            profile = profile,
            eventRef = ref,
            provenance = "experienced",
            now = now,
        })
    end
    if S.EnqueueCustomReply and #responders > 0 then
        local replyOpts = {
            family = WOUND_BARK_OPTS.family,
            priority = math.max(tonumber(pri) or 72, WOUND_BARK_OPTS.priority),
            priorityHoldMs = 500,
            cooldownMs = 500,
            familyCooldownMs = 500,
            ttlMs = WOUND_BARK_OPTS.ttlMs,
            topic = "combat_injury",
            clientCooldowns = WOUND_BARK_OPTS.clientCooldowns,
        }
        for idx, entry in ipairs(responders) do
            S.EnqueueCustomReply({
                speaker = entry.ally,
                skipLOSCheck = true,
                onDelivered = function(observer, at)
                    observer.runtime = observer.runtime or {}
                    observer.runtime.lastWoundReactionAt = at
                    S.RecordWitnessObservation(observer, record, profile, at)
                end,
                addressee = record,
                desc = hitDesc,
                role = entry.role,
                eventType = "combat_wound_ally_reaction",
                act = "REACT",
                topic = "combat_injury",
                canEngage = tostring(entry.ally.attackType or "auto") ~= "none",
                now = now,
                delayMs = idx == 1 and 650 or 1350,
                eventRef = ref .. ":ally" .. tostring(idx),
                threadID = ref,
                extraTokens = buildWoundTokens(record, profile),
                extraContext = {
                    injuryProfile = profile,
                    participantBand = pBand,
                    participantCount = pCount,
                    flowID = "combat.injury.triage_exchange",
                    biteConflictFacts = record.runtime and record.runtime.biteConflictFacts or nil,
                    biteExecutionThreat = record.runtime and (record.runtime.biteConflictFacts or record.runtime.biteExecutionThreat) or nil,
                },
                barkOpts = replyOpts,
            })
        end
    end
    return true, roleVariant
end

return S

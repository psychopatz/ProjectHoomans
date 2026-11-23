-- Combat adopter for the domain-neutral semantic speech transport.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Transport = require "PNC/Semantics/PNC_SemanticSpeechTransport"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Context"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S
local banter

S.Finite = Transport.Finite
S.FormatTokens = Transport.FormatTokens

local function cds(f, s, a)
    return Transport.DefaultCooldowns(f, s, a)
end

local function combatArbiter()
    banter = banter or (PNC.ConvoEngine and PNC.ConvoEngine.CombatBanterArbiter)
        or require "PNC/ConvoEngine/CombatBanterArbiter"
    return banter
end

function S.ValidateInjuryLine(text, profile, evidence, knowledge)
    local wounds = PNC.NPCWounds
    if not text or not profile or not profile.selectedWound or not wounds then return text end
    local valid, reason, detail
    if evidence and wounds.ValidateInjuryClaims then
        valid, reason, detail = wounds.ValidateInjuryClaims(evidence, profile)
    elseif wounds.ValidateRealizationAgainstSelectedWound then
        valid, reason = wounds.ValidateRealizationAgainstSelectedWound(text, profile)
    end
    if S.InjuryEvidenceListener then
        S.InjuryEvidenceListener({
            utteranceEvidence = evidence,
            authoritativeTruth = {
                source = "selected_wound_projection", selectedWound = profile.selectedWound,
                physiology = profile.physiology, knowledgeStatus = knowledge,
            },
            realizationDiagnostics = reason, diagnosticDetail = detail, text = text,
        })
    end
    if valid == false then return nil end
    return text
end

function S.ResolveSemanticLine(rec, evType, act, tClass, ref, profile, tokens, extra)
    if type(rec) ~= "table" or rec.id == nil then return nil, nil end
    local ex = type(extra) == "table" and extra or nil
    local context = {
        semanticThreatClass = tClass,
        combatReactionStyle = S.ResolveAllyWarnTone(rec, profile),
        combatReactionRole = ex and ex.replyRole or nil,
        inCombat = (ex and ex.inCombat ~= nil) and (ex.inCombat == true) or true,
    }
    if ex and type(ex.context) == "table" then
        for k, v in pairs(ex.context) do
            context[k] = v
        end
    end
    local text, resolved = Transport.ResolveLine(rec, {
        eventType = evType,
        eventID = ref,
        act = act,
        topic = (ex and ex.topic) or "combat",
        poolID = ex and ex.poolID or nil,
        tokens = tokens,
        context = context,
        inCombat = context.inCombat,
    })
    return S.ValidateInjuryLine(text, context.injuryProfile, ex and ex.utteranceEvidence,
        context.observerCanInferOnly == nil and "experienced"
            or (context.observerCanInferOnly and "inferred" or "known")), resolved
end

function S.DeliverBark(rec, now, opts)
    opts = type(opts) == "table" and opts or {}
    local arbiter = combatArbiter()
    local npcId = tostring(rec and rec.id or "")
    local ref = opts.eventRef
    local pres = opts.presentationClass or "BARK"
    local fam = opts.family or S.FAMILY
    local pri = opts.priority or 62
    local cd = opts.cooldownMs or S.COOLDOWN_MS or 5000
    local famCd = opts.familyCooldownMs or cd
    local ev = opts.eventType
    local tid = opts.threadID or ref

    return Transport.Deliver(rec, now, {
        eventType = ev,
        speechEventID = opts.speechEventID,
        act = opts.act or "WARN",
        domain = opts.domain or "combat",
        topic = opts.topic or "combat",
        channel = opts.channel or "combat",
        lane = opts.lane or "beat",
        family = fam,
        eventRef = ref,
        threadID = tid,
        sceneID = opts.sceneID,
        text = opts.text,
        responsePlanID = opts.responsePlanID or (opts.context and opts.context.responsePlanID),
        realizationID = opts.realizationID or (opts.context and opts.context.realizationID),
        poolID = opts.poolID or (opts.context and opts.context.poolID),
        realizationFamily = opts.realizationFamily or (opts.context and opts.context.realizationFamily),
        flowID = opts.flowID or (opts.context and opts.context.flowID),
        observerOnly = opts.observerOnly,
        recipientKind = opts.recipientKind,
        lightweightBark = opts.lightweightBark,
        audienceFilter = opts.audienceFilter,
        factRefs = opts.factRefs,
        offerIDs = opts.offerIDs,
        semanticEventFacts = opts.semanticEventFacts,
        priority = pri,
        priorityHoldMs = opts.priorityHoldMs or 700,
        holdMs = opts.holdMs,
        ttlMs = opts.ttlMs or 9000,
        cooldownMs = cd,
        familyCooldownMs = famCd,
        clientCooldowns = opts.clientCooldowns or cds(2500, 2500, 700),
        interrupt = opts.interrupt == true,
        tts = opts.tts ~= false,
        witnessRadius = tonumber(S.WITNESS_RADIUS) or 12,
        streamKey = opts.streamKey or ("combat-target:" .. npcId),
        presentationClass = pres,
        context = opts.context or {
            eventType = ev,
            eventRef = ref,
            threadID = tid,
            presentationClass = pres,
            transient = true,
        },
        preDeliver = function(speaker, aud, at)
            if arbiter and arbiter.Reserve then
                return arbiter.Reserve({
                    streamKey = opts.streamKey or ("combat-target:" .. tostring(speaker.id)),
                    now = at,
                    cooldownMs = cd,
                    maxSpeakers = opts.maxSpeakers or 1,
                    speakerID = tostring(speaker.id),
                    audienceKey = aud,
                    family = fam,
                    familyCooldownMs = famCd,
                    priorityHoldMs = opts.priorityHoldMs or 700,
                    priority = pri,
                }) == true
            end
            return true
        end,
        postDeliver = function(ok, speaker, aud, at)
            if arbiter and arbiter.RecordPresentation then
                arbiter.RecordPresentation({
                    accepted = ok,
                    reason = ok and "presentation_sent" or "presentation_transport_refused",
                    at = at,
                    speakerID = tostring(speaker.id),
                    audienceKey = aud,
                    family = fam,
                    eventRef = ref,
                    presentationClass = pres,
                    tacticalSpatial = opts.tacticalSpatial,
                    tacticalPresentation = opts.tacticalPresentation,
                })
            end
        end,
    })
end

function S.SendReplyBark(rec, now, ev, act, ref, text, res, toks, opts, threadId)
    opts = type(opts) == "table" and opts or nil
    local pres = res and res.presentationClass or "BARK"
    local tid = threadId or (opts and opts.threadID) or ref
    local offerIDs = (res and res.offerIDs) or (opts and opts.offerIDs) or nil
    local factRefs = (opts and opts.factRefs) or { ref }
    return S.DeliverBark(rec, now, {
        eventType = ev,
        speechEventID = res and res.realizationID or ("semantic." .. ev),
        act = act,
        topic = (res and res.topic) or (opts and opts.topic) or "combat",
        family = (opts and opts.family) or "combat_ally_warn_reply",
        eventRef = ref,
        text = text,
        responsePlanID = res and res.responsePlanID or nil,
        realizationID = res and res.realizationID or nil,
        poolID = res and res.poolID or nil,
        realizationFamily = res and res.realizationFamily or nil,
        flowID = (opts and opts.flowID) or "combat.injury.triage_exchange",
        observerOnly = type(offerIDs) == "table" and #offerIDs > 0 and false or nil,
        recipientKind = type(offerIDs) == "table" and #offerIDs > 0 and "player" or nil,
        offerIDs = offerIDs,
        factRefs = factRefs,
        threadID = tid,
        priority = (opts and opts.priority) or 62,
        priorityHoldMs = (opts and opts.priorityHoldMs) or 700,
        holdMs = opts and opts.holdMs or nil,
        ttlMs = (opts and opts.ttlMs) or 9000,
        cooldownMs = (opts and opts.cooldownMs) or 3500,
        familyCooldownMs = (opts and opts.familyCooldownMs) or (opts and opts.cooldownMs) or 3500,
        clientCooldowns = (opts and opts.clientCooldowns) or cds(1500, 2000, 400),
        maxSpeakers = 1,
        streamKey = (opts and opts.streamKey) or ("ally-warn-reply:" .. tostring(rec.id)),
        presentationClass = pres,
        context = {
            eventType = ev,
            eventRef = ref,
            threadID = tid,
            presentationClass = pres,
            transient = true,
            offerIDs = offerIDs,
            responsePlan = res and res.responsePlan or nil,
            responsePlanID = res and res.responsePlanID or nil,
            realizationID = res and res.realizationID or nil,
            targetLabel = toks and toks["target.name"] or nil,
            targetCount = toks and tonumber(toks["target.count"]) or nil,
            locationLabel = toks and toks["scene.location"] or nil,
            callerName = toks and toks["addressee.name"] or nil,
        },
    })
end

return S

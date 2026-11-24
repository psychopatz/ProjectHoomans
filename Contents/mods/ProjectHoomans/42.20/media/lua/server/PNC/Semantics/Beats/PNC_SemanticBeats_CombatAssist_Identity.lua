-- Proactive "what's your name?" follow-up for combat-assist beats.
-- Reuses StaticProvider_Identity buttons for players and deterministic
-- DispositionProjection + IdentityAlias resolution for colonists/NPCs.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local IdentityBeat = PNC.Semantics.CombatAssistIdentity or {}
PNC.Semantics.CombatAssistIdentity = IdentityBeat

local ASK_COOLDOWN_MS = 600000
local MAX_ASKED_PAIRS = 64
local IDENTITY_OFFER_IDS = {
    "identity.choice.real_name",
    "identity.choice.refuse_name",
    "identity.choice.lie_name",
}

local askedPairs = {}
local askedOrder = {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function pairKey(askerID, targetKey)
    return tostring(askerID or "") .. "->" .. tostring(targetKey or "")
end

local function markAsked(key, now)
    if askedPairs[key] == nil then
        while #askedOrder >= MAX_ASKED_PAIRS do
            local oldest = table.remove(askedOrder, 1)
            askedPairs[oldest] = nil
        end
        askedOrder[#askedOrder + 1] = key
    end
    askedPairs[key] = now
end

function IdentityBeat.WasRecentlyAsked(askerID, targetKey, now)
    local key = pairKey(askerID, targetKey)
    local last = askedPairs[key]
    if last == nil then return false end
    now = nowMs(now)
    return now >= last and (now - last) < ASK_COOLDOWN_MS
end

function IdentityBeat.MarkAsked(askerID, targetKey, now)
    markAsked(pairKey(askerID, targetKey), nowMs(now))
end

function IdentityBeat.ShouldAskName(ctx, opts)
    ctx = type(ctx) == "table" and ctx or {}
    local rel = type(ctx.relationship) == "table" and ctx.relationship or {}
    local actor = type(ctx.actor) == "table" and ctx.actor or {}
    if rel.knowsName == true or rel.sameFaction == true then return false end
    if rel.tier == "hostile" or actor.style == "hostile" then return false end
    if rel.identityTrust == "trusted" then return false end
    local speaker = ctx.speaker
    if type(speaker) ~= "table" or speaker.id == nil then return false end
    local targetKey = (opts and opts.partnerKey) or rel.partnerKey
    if not targetKey or tostring(targetKey) == "" then return false end
    if IdentityBeat.WasRecentlyAsked(speaker.id, targetKey, ctx.now) then return false end
    return true
end

function IdentityBeat.BuildPlayerAskTurn(speaker, player, flatCtx, spec)
    spec = type(spec) == "table" and spec or {}
    local eventRef = tostring(spec.eventRef or ("assist:ask_name:" .. tostring(speaker.id)))
    local turnCtx = {}
    for k, v in pairs(type(flatCtx) == "table" and flatCtx or {}) do
        turnCtx[k] = v
    end
    turnCtx.pendingIdentityExchange = {
        kind = "PLAYER_NAME",
        initiator = "npc",
        eventRef = eventRef,
    }
    return {
        speaker = speaker,
        addressee = player,
        addresseeIsPlayer = true,
        poolID = "semantic.social.identity.ask_name_proactive",
        eventType = "social_identity_prompt",
        domain = "social",
        channel = "social",
        topic = "identity",
        lane = "scene",
        flowID = "social.identity.ask_name_proactive",
        responsePlanID = "semantic.social.identity.ask_name_proactive",
        presentationClass = "SOCIAL_PROMPT",
        act = "QUESTION",
        role = "ask_name_after_assist",
        family = "social_identity_ask_name",
        delayMs = tonumber(spec.delayMs) or 1400,
        ttlMs = tonumber(spec.ttlMs) or 15000,
        priority = tonumber(spec.priority) or 58,
        priorityHoldMs = 1200,
        holdMs = 1200,
        cooldownMs = 4000,
        familyCooldownMs = 4000,
        eventRef = eventRef,
        offerIDs = IDENTITY_OFFER_IDS,
        factRefs = { eventRef },
        observerOnly = false,
        recipientKind = "player",
        meaningful = true,
        context = turnCtx,
        tokens = spec.tokens,
    }
end

local function generateAliasForNPC(responder)
    local Alias = PNC.IdentityAlias
    if type(Alias) ~= "table" then
        local ok, loaded = pcall(require, "PNC/Core/Identity/PNC_IdentityAlias")
        Alias = PNC.IdentityAlias or (ok and type(loaded) == "table" and loaded) or nil
    end
    local canonical = tostring(responder and (responder.name or responder.fullName) or "")
    if Alias and type(Alias.Generate) == "function" then
        local ok, generated = pcall(Alias.Generate, {
            characterUUID = tostring(responder and responder.id or ""),
            gender = responder and (responder.female == true and "female" or "male") or nil,
            playerName = canonical ~= "" and canonical or nil,
        })
        if ok and type(generated) == "string" and generated ~= "" and generated ~= canonical then
            return generated
        end
    end
    return "Sam Miller"
end

function IdentityBeat.DecideAutonomousChoice(responder, asker, ctx)
    ctx = type(ctx) == "table" and ctx or {}
    local partnerStats = type(ctx.partner) == "table" and ctx.partner or {}
    local rel = type(ctx.relationship) == "table" and ctx.relationship or {}
    local env = type(ctx.env) == "table" and ctx.env or {}

    local eff = type(partnerStats.effectiveDisposition) == "table"
        and partnerStats.effectiveDisposition or nil
    local sociability = eff and ((tonumber(eff.sociability) or 50) / 100) or 0.55
    local compassion = tonumber(partnerStats.compassion) or 0.50
    local bravery = tonumber(partnerStats.bravery) or 0.50
    local aggression = tonumber(partnerStats.aggression) or 0.40
    local panic = tonumber(partnerStats.panic) or 0
    local tier = tostring(rel.tier or "stranger")
    local trust = tonumber(rel.trust) or 0
    local trustNorm = math.max(-1, math.min(1, trust / 50))
    local isNightOrDusk = env.timeOfDay == "night" or env.timeOfDay == "dusk"

    local canonical = tostring(responder and (responder.name or responder.fullName) or "")
    if tier == "friendly" or tier == "trusted" or tier == "ally" then
        if canonical ~= "" then return "real_name", canonical end
    end

    local openness = sociability * 0.45 + compassion * 0.30 + trustNorm * 0.25
        - (isNightOrDusk and 0.08 or 0)
        - (panic >= 50 and 0.15 or 0)
    local deception = (1 - compassion) * 0.40 + aggression * 0.25
        + (tier == "wary" and 0.28 or 0)
        + (isNightOrDusk and 0.08 or 0)

    if openness >= 0.45 and canonical ~= "" then
        return "real_name", canonical
    end
    if deception >= 0.55 and bravery >= 0.35 then
        return "lie_name", generateAliasForNPC(responder)
    end
    return "refuse_name", nil
end

function IdentityBeat.RecordAutonomousExchange(asker, responder, choice, claimedName)
    if type(asker) ~= "table" or asker.id == nil then return false end
    if type(responder) ~= "table" or responder.id == nil then return false end
    local relSvc = PNC.Relationships
    if type(relSvc) ~= "table" then return false end

    local er = PNC.EntityRef
    local responderKey = (er and type(er.ForNPC) == "function")
        and tostring(er.ForNPC(responder.id)) or ("npc:" .. tostring(responder.id))
    local askerKey = (er and type(er.ForNPC) == "function")
        and tostring(er.ForNPC(asker.id)) or ("npc:" .. tostring(asker.id))

    local getter = relSvc.GetOrCreate or relSvc.Get
    if type(getter) ~= "function" then return false end

    local okA, relA = pcall(getter, asker.id, responderKey)
    if okA and type(relA) == "table" then
        if choice == "real_name" then
            relA.identityTrust = "trusted"
            relA.identityKnown = true
            relA.knownName = claimedName
        elseif choice == "lie_name" then
            relA.identityTrust = "claimed"
            relA.claimedName = claimedName
        end
    end

    if choice == "real_name" then
        local okR, relR = pcall(getter, responder.id, askerKey)
        if okR and type(relR) == "table" then
            relR.identityTrust = "trusted"
            relR.identityKnown = true
            relR.knownName = tostring(asker.name or asker.fullName or "")
        end
    end
    return true
end

function IdentityBeat.BuildColonistAskReplies(asker, colonist, ctx, flatCtx, spec)
    spec = type(spec) == "table" and spec or {}
    local choice, claimedName = IdentityBeat.DecideAutonomousChoice(colonist, asker, ctx)
    local baseRef = tostring(spec.eventRef or ("assist:npc_ask:" .. tostring(asker.id)))
    local baseDelay = tonumber(spec.delayMs) or 1400
    local pri = tonumber(spec.priority) or 52

    local answerRole = "colonist_answer_" .. choice
    local reactRole = "ask_name_react_" .. choice

    local answerTokens = {}
    if type(spec.tokens) == "table" then
        for k, v in pairs(spec.tokens) do answerTokens[k] = v end
    end
    if claimedName then answerTokens["claimed.name"] = claimedName end

    local reactTokens = {}
    if claimedName then reactTokens["claimed.name"] = claimedName end

    return {
        {
            speaker = asker,
            addressee = colonist,
            poolID = "semantic.social.identity.ask_name_proactive",
            eventType = "social_identity_beat",
            domain = "social",
            channel = "social",
            topic = "identity",
            act = "QUESTION",
            role = "ask_name_after_assist",
            family = "social_identity_ask_name",
            delayMs = baseDelay,
            priority = pri,
            eventRef = baseRef .. ":ask",
            context = flatCtx,
        },
        {
            speaker = colonist,
            addressee = asker,
            poolID = "semantic.social.identity.ask_name_proactive",
            eventType = "social_identity_beat",
            domain = "social",
            channel = "social",
            topic = "identity",
            act = choice == "refuse_name" and "REFUSE" or "INFORM",
            role = answerRole,
            family = "social_identity_ask_name",
            delayMs = baseDelay + 1250,
            priority = pri,
            eventRef = baseRef .. ":ans",
            context = flatCtx,
            tokens = answerTokens,
            onDelivered = function()
                IdentityBeat.RecordAutonomousExchange(asker, colonist, choice, claimedName)
            end,
        },
        {
            speaker = asker,
            addressee = colonist,
            poolID = "semantic.social.identity.ask_name_proactive",
            eventType = "social_identity_beat",
            domain = "social",
            channel = "social",
            topic = "identity",
            act = "REACT",
            role = reactRole,
            family = "social_identity_ask_name",
            delayMs = baseDelay + 2450,
            priority = pri,
            eventRef = baseRef .. ":ack",
            context = flatCtx,
            tokens = reactTokens,
        },
    }
end

function IdentityBeat.ResetRuntime()
    askedPairs = {}
    askedOrder = {}
end

return IdentityBeat

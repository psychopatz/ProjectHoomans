-- Modular Stance Alignment & Witness Ripple engine for organic RPG relationships.
-- Evaluates Player->NPC and NPC->NPC stance choices across topic-specific value
-- axes (compassion, caution, pragmatism, social), asymmetric approval/respect,
-- relationship inertia/hysteresis, emotional stress amplification, group witness
-- ripples, per-topic dedupe, and hourly per-pair caps via PNC.Relationships.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Stance = PNC.Semantics.StanceAlignment or {}
PNC.Semantics.StanceAlignment = Stance

Stance.VERSION = 1

local MAX_APPROVAL_PER_HOUR = 6
local MAX_RESPECT_PER_HOUR = 4
local MAX_PAIR_BUDGETS = 64
local MAX_TOPIC_DEDUPE = 96
local MAX_WITNESSES = 3

local pairBudgets, pairBudgetOrder = {}, {}
local topicDedupe, topicDedupeOrder = {}, {}

-- Extensible topic -> value-axis registry so different topics pull on different
-- personality traits (two NPCs can clash on faith yet bond over survival tactics).
local topicAxes = {
    -- Compassion / Optimism axis
    pastor_radio          = "compassion",
    post_pastor_radio     = "compassion",
    open_band_refugee     = "compassion",
    post_refugee_radio    = "compassion",
    home_vhs              = "compassion",
    post_home_vhs         = "compassion",
    wellbeing_check       = "compassion",
    -- Caution / Bravery axis
    open_band_looter_trap = "caution",
    post_looter_trap      = "caution",
    cannibal_radio        = "caution",
    post_cannibal_radio   = "caution",
    aebs_air_activity     = "caution",
    aebs_power_warning    = "caution",
    post_aebs_alert       = "caution",
    military_comms        = "caution",
    post_military_radio   = "caution",
    post_alarm            = "caution",
    post_chopper          = "caution",
    post_fight            = "caution",
    -- Pragmatism / Utility axis
    open_band_trader      = "pragmatism",
    post_trader_radio     = "pragmatism",
    open_band_settlement  = "pragmatism",
    post_settlement_radio = "pragmatism",
    skill_show            = "pragmatism",
    post_skill_show       = "pragmatism",
    supplies_check        = "pragmatism",
    camp_life             = "pragmatism",
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function roundInt(v)
    if v >= 0 then return math.floor(v + 0.5) end
    return math.ceil(v - 0.5)
end

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function nowWorldHours()
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeHours) == "function" then
            return tonumber(gt:getWorldAgeHours()) or 0
        end
    end
    return 0
end

local function lruPut(map, order, key, val, limit)
    if map[key] == nil then
        while #order >= limit do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = val
end

function Stance.RegisterTopicAxis(topic, axis)
    topic = tostring(topic or "")
    axis = tostring(axis or "")
    if topic == "" or axis == "" then return false end
    topicAxes[topic] = axis
    return true
end

function Stance.GetTopicAxis(topic)
    return topicAxes[tostring(topic or "")] or "social"
end

function Stance.ResolveCompositionalAction(outcome, axis)
    outcome = tostring(outcome or "diplomatic")
    axis = tostring(axis or "social")
    if outcome == "aligned" or outcome == "clashed" then
        if axis == "compassion" or axis == "caution" or axis == "pragmatism" then
            return outcome .. "_" .. axis
        end
        return outcome .. "_pragmatism"
    end
    return outcome
end

local function resolveTargetKey(actor)
    if type(actor) == "string" and actor ~= "" then return actor end
    if type(actor) ~= "table" then return nil end
    if actor.isPlayer == true or type(actor.getUsername) == "function" then
        if PNC.EntityRef and type(PNC.EntityRef.ForPlayerIdentity) == "function" then
            local ok, k = pcall(PNC.EntityRef.ForPlayerIdentity, actor)
            if ok and k then return k end
        end
        local uname = actor.username or actor.id
            or (type(actor.getUsername) == "function" and actor:getUsername())
            or "0"
        return "player:" .. tostring(uname)
    end
    if actor.id ~= nil then
        if PNC.RelationshipTypes and type(PNC.RelationshipTypes.MakeNPCKey) == "function" then
            return PNC.RelationshipTypes.MakeNPCKey(actor.id)
        end
        return "npc:" .. tostring(actor.id)
    end
    return nil
end

local function readPairRelation(observerNPC, targetKey)
    local rel = PNC.Relationships or PNC.RelationshipService
    if rel and type(rel.Get) == "function" and observerNPC and observerNPC.id ~= nil and targetKey then
        local ok, r = pcall(rel.Get, observerNPC.id, targetKey)
        if ok and type(r) == "table" then
            return tonumber(r.approval) or 0, tonumber(r.respect) or 0
        end
    end
    return 0, 0
end

-- Determine a witness NPC's preferred stance on a topic using its Value Axis + VoiceProfile.
function Stance.ResolvePreferredStance(witness, topic, at)
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local voice = (Dir and type(Dir.ResolveVoiceProfile) == "function"
        and Dir.ResolveVoiceProfile(witness, at))
        or { empathy = 0.5, composure = 0.55, reactivity = 0.5, socialStyle = "neutral" }
    local axis = Stance.GetTopicAxis(topic)
    local style = tostring(voice.socialStyle or "neutral")
    local score = 0

    if axis == "compassion" then
        score = (voice.empathy - 0.5) * 2.0
        if style == "warm" or style == "friendly" or style == "protective" then score = score + 0.55
        elseif style == "hostile" or style == "cold" or style == "guarded" or style == "withdrawn" then score = score - 0.65 end
    elseif axis == "caution" then
        -- High composure/practical/protective favors taking threats seriously (positive);
        -- reckless/aggressive/hostile dismisses warnings (negative).
        score = (voice.composure - 0.5) * 1.4
        if style == "protective" or style == "practical" or style == "warm" then score = score + 0.45
        elseif style == "aggressive" or style == "hostile" then score = score - 0.55 end
    elseif axis == "pragmatism" then
        if style == "practical" or style == "warm" or style == "friendly" then score = 0.55
        elseif style == "hostile" or style == "withdrawn" or style == "cold" then score = -0.55
        else score = 0 end
    else
        if style == "warm" or style == "friendly" or style == "protective" then score = 0.55
        elseif style == "hostile" or style == "cold" or style == "guarded" or style == "withdrawn" then score = -0.55
        else score = 0 end
    end

    if score >= 0.28 then return "stance_positive", axis, voice end
    if score <= -0.28 then return "stance_negative", axis, voice end
    return "stance_neutral", axis, voice
end

local function normalizeStance(raw)
    local s = string.lower(tostring(raw or ""))
    if s == "stance_positive" or s == "positive" or s == "agree" or s == "praise" or s == "reassure" then
        return "stance_positive"
    end
    if s == "stance_negative" or s == "negative" or s == "disagree" or s == "criticize" or s == "antagonize" then
        return "stance_negative"
    end
    return "stance_neutral"
end

local function applySingleWitness(witness, speakerKey, topic, chosenStance, isDirect, opts)
    if type(witness) ~= "table" or witness.id == nil or witness.alive == false then return nil end
    local wKey = resolveTargetKey(witness)
    if not speakerKey or not wKey or wKey == speakerKey then return nil end

    local now = nowMs(opts.now)
    local hrs = nowWorldHours()
    local dedupeKey = tostring(witness.id) .. "|" .. tostring(speakerKey) .. "|" .. tostring(opts.topicInstanceKey or topic)
    local prevCount = tonumber(topicDedupe[dedupeKey]) or 0
    if prevCount >= 2 then
        return { witnessId = witness.id, skipped = "topic_diminished", approval = 0, respect = 0 }
    end
    local dimScale = prevCount == 1 and 0.5 or 1.0

    local preferred, axis, voice = Stance.ResolvePreferredStance(witness, topic, now)
    local curApproval, curRespect = readPairRelation(witness, speakerKey)

    -- 1. Base alignment outcome (Approval vs Respect asymmetry)
    local dApp, dRep, dFam, outcome = 0, 0, 1, "neutral"
    if chosenStance == preferred then
        if chosenStance == "stance_neutral" then
            dApp, dRep, outcome = 1, 1, "measured_match"
        else
            dApp, dRep, outcome = 3, 2, "aligned"
        end
    elseif chosenStance == "stance_neutral" or preferred == "stance_neutral" then
        -- Diplomatic middle: respectful unless witness is highly stressed/volatile.
        if (voice.composure or 0.55) <= 0.30 then
            dApp, dRep, outcome = -1, 0, "impatient_neutral"
        else
            dApp, dRep, outcome = 0, 1, "diplomatic"
        end
    else
        -- Opposite poles (positive vs negative): organic friction!
        -- Brave/practical witnesses can still grant grudging +1 respect (Dragon Age II rivalry).
        dApp = -2
        if voice.socialStyle == "practical" or voice.socialStyle == "brave" or (voice.composure or 0.5) >= 0.72 then
            dRep = 1
            outcome = "respected_clash"
        else
            dRep = -1
            outcome = "clashed"
        end
    end

    -- 2. Relationship Inertia / Hysteresis
    if curApproval >= 40 and dApp < 0 then
        -- Close allies forgive minor disagreements.
        dApp = math.min(-1, roundInt(dApp * 0.5))
    elseif curApproval <= -30 and dApp > 0 then
        -- Strained rivals give grudging respect first instead of instant friendship.
        dApp = math.max(1, roundInt(dApp * 0.4))
        dRep = math.max(dRep, 1)
    end

    -- 3. Emotional State Amplifier (stressed/exhausted NPCs feel friction & reassurance 1.5x stronger)
    if (voice.composure or 0.55) <= 0.35 and dApp ~= 0 then
        dApp = roundInt(dApp * 1.5)
    end

    -- 4. Witness Ripple scaling (50% for overhearing bystanders) + Diminishing returns
    local roleScale = isDirect and 1.0 or 0.5
    dApp = roundInt(dApp * roleScale * dimScale)
    dRep = roundInt(dRep * roleScale * dimScale)
    if dApp == 0 and dRep == 0 then
        return { witnessId = witness.id, preferred = preferred, axis = axis, outcome = outcome, approval = 0, respect = 0, applied = false }
    end

    -- 5. Hourly per-pair cap
    local bucket = math.floor(hrs)
    local pKey = tostring(witness.id) .. "->" .. tostring(speakerKey) .. ":" .. tostring(bucket)
    local used = pairBudgets[pKey]
    if not used then
        used = { approval = 0, respect = 0 }
        lruPut(pairBudgets, pairBudgetOrder, pKey, used, MAX_PAIR_BUDGETS)
    end
    local remApp = MAX_APPROVAL_PER_HOUR - math.abs(used.approval)
    local remRep = MAX_RESPECT_PER_HOUR - math.abs(used.respect)
    if remApp <= 0 and remRep <= 0 then
        return { witnessId = witness.id, skipped = "pair_hourly_cap", approval = 0, respect = 0 }
    end
    dApp = clamp(dApp, -remApp, remApp)
    dRep = clamp(dRep, -remRep, remRep)
    used.approval = used.approval + dApp
    used.respect = used.respect + dRep
    lruPut(topicDedupe, topicDedupeOrder, dedupeKey, prevCount + 1, MAX_TOPIC_DEDUPE)

    local applied = false
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if relSvc and type(relSvc.ApplyConversationEffect) == "function" then
        local ok, res = pcall(relSvc.ApplyConversationEffect, witness.id, speakerKey, {
            approval = dApp,
            respect = dRep,
            familiarity = dFam,
            decayPerDay = 0.08,
            memoryType = "stance_" .. outcome,
            interactionType = "stance_alignment",
            tags = { conversation = true, stance_alignment = true, [axis] = true },
        }, {
            worldAgeHours = hrs,
            sourceSystem = "stance_alignment",
            blockID = tostring(topic or "gossip"),
            choiceID = chosenStance,
            outcomeID = outcome,
            eventID = "stance:" .. tostring(witness.id) .. ":" .. tostring(speakerKey) .. ":" .. tostring(math.floor(now)),
        })
        applied = ok == true and res ~= false
    end

    if PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled == true
        and PNC.PerformanceScalingDiagnostics.LogBeatsAudit
    then
        PNC.PerformanceScalingDiagnostics.LogBeatsAudit("stance_impact", {
            "witness=" .. tostring(witness.id),
            "speaker=" .. tostring(speakerKey),
            "topic=" .. tostring(topic),
            "axis=" .. tostring(axis),
            "chosen=" .. tostring(chosenStance),
            "preferred=" .. tostring(preferred),
            "outcome=" .. tostring(outcome),
            "direct=" .. tostring(isDirect),
            "dApproval=" .. tostring(dApp),
            "dRespect=" .. tostring(dRep),
            "applied=" .. tostring(applied),
        })
    end

    return {
        witnessId = witness.id,
        preferred = preferred,
        axis = axis,
        outcome = outcome,
        isDirect = isDirect,
        approval = dApp,
        respect = dRep,
        applied = applied,
        magnitude = math.abs(dApp) + math.abs(dRep),
    }
end

-- Actor-agnostic entry point: evaluates direct addressee (100%) + up to 3
-- overhearing witnesses (50%) when a Player or NPC takes a stance on a topic.
function Stance.EvaluateStanceImpact(speaker, addressee, witnesses, topic, chosenStance, opts)
    opts = type(opts) == "table" and opts or {}
    local speakerKey = resolveTargetKey(speaker)
    if not speakerKey then return {}, nil end
    local normStance = normalizeStance(chosenStance)
    local results = {}
    local seen = {}
    local strongestWitness = nil

    if type(addressee) == "table" and addressee.id ~= nil then
        seen[tostring(addressee.id)] = true
        local r = applySingleWitness(addressee, speakerKey, topic, normStance, true, opts)
        if r then results[#results + 1] = r end
    end

    if type(witnesses) == "table" then
        local count = 0
        for i = 1, #witnesses do
            if count >= MAX_WITNESSES then break end
            local w = witnesses[i]
            if type(w) == "table" and w.id ~= nil and not seen[tostring(w.id)] then
                seen[tostring(w.id)] = true
                local r = applySingleWitness(w, speakerKey, topic, normStance, false, opts)
                if r then
                    count = count + 1
                    results[#results + 1] = r
                    if not strongestWitness or (r.magnitude or 0) > (strongestWitness.magnitude or 0) then
                        strongestWitness = r
                    end
                end
            end
        end
    end

    return results, strongestWitness
end

function Stance.ResetRuntime()
    pairBudgets, pairBudgetOrder = {}, {}
    topicDedupe, topicDedupeOrder = {}, {}
end

return Stance

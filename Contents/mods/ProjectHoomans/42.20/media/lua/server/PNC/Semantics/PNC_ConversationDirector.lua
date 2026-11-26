-- Unified Conversation Director: single ephemeral story brain for overhead NPC
-- speech, combat/wound saturation, personality-weighted chattiness, StoryRecall
-- projection, and actor-agnostic NPC suggestion picking with autonomous
-- rate-limited relationship evolution.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Director = PNC.Semantics.ConversationDirector or {}
PNC.Semantics.ConversationDirector = Director

Director.VERSION = 1

local VOICE_CACHE_TTL_MS = 5000
local MAX_VOICE_CACHE = 64
local MAX_SATURATION_KEYS = 64
local MAX_STORY_GROUPS = 24
local MAX_STORY_MOMENTS = 6
local MAX_CHRONICLE_PER_GROUP = 5
local CHRONICLE_PROMOTE_SALIENCE = 58
local STORY_TTL_MS = 12 * 60 * 1000
local MAX_PAIR_BUDGET_KEYS = 64
local MAX_INTERRUPTED_GROUPS = 16
local INTERRUPTION_TTL_MS = 60000
local MAX_APPROVAL_PER_HOUR = 6
local MAX_RESPECT_PER_HOUR = 4

local voiceCache, voiceOrder = {}, {}
local saturation, saturationOrder = {}, {}
local storyMoments, storyGroupOrder = {}, {}
local groupChronicles, chronicleGroupOrder = {}, {}
local interruptedThreads, interruptedOrder = {}, {}
local recentSpeakerAt = {}
local pairDeltaBudgets, pairBudgetOrder = {}, {}
local evalSeq = 0
local evalCount, admittedCount, suppressedCount, relationshipDeltaCount = 0, 0, 0, 0

-- Extensible registries: subsystems can plug in topic policies, StoryRecall
-- providers, and social-act profiles without modifying core Director logic.
local topicPolicies = {
    combat_wound          = { tier = 1, urgency = 58, salience = 58, saturationWindowMs = 35000, silenceThreshold = 42 },
    fighting_injured      = { tier = 1, urgency = 40, salience = 46, saturationWindowMs = 45000, silenceThreshold = 50 },
    combat_kill_self      = { tier = 1, urgency = 45, salience = 54, saturationWindowMs = 22000, silenceThreshold = 46 },
    combat_human_kill_self= { tier = 2, urgency = 80, salience = 74, saturationWindowMs = 15000, silenceThreshold = 40 },
    combat_blindside      = { tier = 3, urgency = 90, salience = 88, saturationWindowMs =  6000, silenceThreshold = 25 },
    combat_situation      = { tier = 1, urgency = 48, salience = 54, saturationWindowMs = 24000, silenceThreshold = 44 },
    combat_awareness      = { tier = 1, urgency = 52, salience = 56, saturationWindowMs = 20000, silenceThreshold = 44 },
    combat_tactical_prompt= { tier = 3, urgency = 88, salience = 86, saturationWindowMs =  8000, silenceThreshold = 25 },
    group_banter          = { tier = 1, urgency = 24, salience = 54, saturationWindowMs = 45000, silenceThreshold = 42 },
}
local storyRecallProviders = {}
local storyRecallProviderOrder = {}

local STYLE_CHATTINESS = {
    warm = 1.45,
    friendly = 1.38,
    supportive = 1.25,
    protective = 1.08,
    practical = 1.00,
    neutral = 1.00,
    tactical = 0.88,
    brave = 0.85,
    aggressive = 1.05,
    shaken = 1.28,
    guarded = 0.62,
    cold = 0.55,
    withdrawn = 0.42,
    hostile = 0.70,
}

local ACT_SOCIAL_PROFILE = {
    GREET      = { valence =  1, styleBias = { warm = 14, friendly = 14, protective = 8, guarded = -6, hostile = -12 }, approval =  1, respect =  1, familiarity = 2, socialType = "social.greeting" },
    AGREE      = { valence =  1, styleBias = { warm = 12, friendly = 12, supportive = 14, guarded = -4, hostile = -10 }, approval =  2, respect =  1, familiarity = 1, socialType = "social.gratitude" },
    PRAISE     = { valence =  1, styleBias = { warm = 16, friendly = 14, protective = 10, cold = -10, hostile = -16 }, approval =  3, respect =  2, familiarity = 1, socialType = "social.gratitude" },
    THANK      = { valence =  1, styleBias = { warm = 14, friendly = 12, supportive = 12, hostile = -12 }, approval =  2, respect =  1, familiarity = 1, socialType = "social.gratitude" },
    REASSURE   = { valence =  1, styleBias = { protective = 18, warm = 14, supportive = 16, cold = -10, hostile = -14 }, approval =  2, respect =  2, familiarity = 1, socialType = "social.gratitude" },
    DEFUSE     = { valence =  1, styleBias = { protective = 18, warm = 12, practical = 10, aggressive = -12, hostile = -16 }, approval =  2, respect =  2, familiarity = 1, socialType = "social.apology" },
    PACIFY     = { valence =  1, styleBias = { protective = 16, warm = 14, supportive = 14, aggressive = -12, hostile = -16 }, approval =  2, respect =  1, familiarity = 1, socialType = "social.apology" },
    APOLOGIZE  = { valence =  1, styleBias = { warm = 10, supportive = 12, guarded = -8, hostile = -18, aggressive = -14 }, approval =  3, respect =  1, familiarity = 1, socialType = "social.apology" },
    CLARIFY    = { valence =  0, styleBias = { practical = 14, neutral = 14, tactical = 12, brave = 6, guarded = 4, warm = 0, hostile = -4 }, approval = 0, respect = 1, familiarity = 1, socialType = "social.gossip" },
    CRITICIZE  = { valence = -1, styleBias = { guarded = 10, cold = 12, aggressive = 14, hostile = 16, warm = -14, friendly = -12 }, approval = -2, respect = -1, familiarity = 1, socialType = "social.grievance" },
    DISAGREE   = { valence = -1, styleBias = { guarded = 10, practical = 6, cold = 10, aggressive = 10, warm = -8 }, approval = -1, respect =  0, familiarity = 1, socialType = "social.grievance" },
    ANTAGONIZE = { valence = -1, styleBias = { hostile = 20, aggressive = 16, cold = 12, warm = -20, friendly = -18, protective = -16 }, approval = -3, respect = -2, familiarity = 1, socialType = "social.grievance" },
    INSULT     = { valence = -1, styleBias = { hostile = 22, aggressive = 16, warm = -22, friendly = -20, protective = -18 }, approval = -3, respect = -2, familiarity = 1, socialType = "social.grievance" },
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function nowWorldHours()
    if PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function" then
        return tonumber(PNC.Core.NowWorldAgeHours()) or 0
    end
    return 0
end

local function clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
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

local function boundedJitter(seedText, seqNum, amplitude)
    local h = (tonumber(seqNum) or 0) * 131 + 17
    local s = tostring(seedText or "")
    for i = 1, #s do
        h = (h * 31 + string.byte(s, i)) % 100003
    end
    local unit = ((h % 2001) / 1000.0) - 1.0 -- [-1.0, +1.0]
    return unit * (tonumber(amplitude) or 10)
end

local DENSITY_PROFILES = {
    [1] = { level = 1, name = "quiet",     thresholdScale = 1.25, cooldownScale = 1.65 },
    [2] = { level = 2, name = "cinematic", thresholdScale = 1.00, cooldownScale = 1.00 },
    [3] = { level = 3, name = "lively",    thresholdScale = 0.80, cooldownScale = 0.65 },
}

function Director.GetDensityProfile()
    local level = 2
    if PNC.Sandbox and type(PNC.Sandbox.ChatterDensity) == "function" then
        level = tonumber(PNC.Sandbox.ChatterDensity()) or 2
    elseif PNC.Sandbox and type(PNC.Sandbox.ChatterDensityProfile) == "function" then
        local prof = PNC.Sandbox.ChatterDensityProfile()
        if type(prof) == "table" and prof.cooldownScale and prof.thresholdScale then
            return prof
        elseif prof == "quiet" then
            level = 1
        elseif prof == "lively" then
            level = 3
        end
    end
    return DENSITY_PROFILES[level] or DENSITY_PROFILES[2]
end

function Director.ResolveVoiceProfile(record, at)
    if type(record) ~= "table" or record.id == nil then
        return { chattiness = 1.0, composure = 0.5, empathy = 0.5, reactivity = 0.5, socialStyle = "neutral" }
    end
    local now = nowMs(at)
    local id = tostring(record.id)
    local cached = voiceCache[id]
    if cached and now < (tonumber(cached.expiresAt) or 0) then
        return cached.data
    end

    local pers = record.social and record.social.personality or nil
    local style = tostring((pers and pers.socialStyle) or record.socialStyle or "neutral")
    local chattiness = STYLE_CHATTINESS[style] or 1.0
    local composure = 0.55
    local empathy = 0.50
    local reactivity = 0.50

    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if BC and type(BC.ResolveActorStats) == "function" then
        local st = BC.ResolveActorStats(record, { inCombat = false }, now)
        if type(st) == "table" then
            if st.style and STYLE_CHATTINESS[st.style] and style == "neutral" then
                style = st.style
                chattiness = STYLE_CHATTINESS[st.style]
            end
            local bravery = tonumber(st.bravery) or 0.5
            local compassion = tonumber(st.compassion) or 0.5
            local stress = tonumber(st.stress) or 0
            local panic = (tonumber(st.panic) or 0) / 100
            composure = clamp(bravery - (stress * 0.35) - (panic * 0.45), 0.1, 1.0)
            empathy = clamp(compassion, 0.1, 1.0)
            reactivity = clamp(0.45 + stress * 0.35 + panic * 0.45 - bravery * 0.25, 0.15, 1.0)
            if st.isCowardly then chattiness = chattiness * 1.12 end
            if st.isExhausted then chattiness = chattiness * 0.82 end
        end
    end

    -- Respect explicit personality/trait overrides when present on record.
    if pers and tonumber(pers.sociability) then
        local soc = tonumber(pers.sociability)
        if soc > 1 then soc = soc / 100 end
        chattiness = chattiness * clamp(0.65 + soc * 0.70, 0.55, 1.45)
    end
    chattiness = clamp(chattiness, 0.30, 1.75)

    local profile = {
        chattiness = chattiness,
        composure = composure,
        empathy = empathy,
        reactivity = reactivity,
        socialStyle = style,
    }
    lruPut(voiceCache, voiceOrder, id, { expiresAt = now + VOICE_CACHE_TTL_MS, data = profile }, MAX_VOICE_CACHE)
    return profile
end

function Director.CheckSaturation(scopeKey, topic, tier, at, windowMs)
    local now = nowMs(at)
    local key = tostring(scopeKey or "global") .. "|" .. tostring(topic or "generic")
    local entry = saturation[key]
    if not entry then return false, 0, "fresh" end
    local win = tonumber(windowMs) or 35000
    local elapsed = now - (tonumber(entry.lastAt) or 0)
    if elapsed < 0 or elapsed >= win then
        return false, 0, "expired"
    end
    local curTier = tonumber(tier) or 1
    local prevTier = tonumber(entry.tier) or 1
    if curTier > prevTier then
        return false, 0, "escalated"
    end
    local remaining = win - elapsed
    return true, remaining, "saturated"
end

function Director.MarkSpoken(scopeKey, topic, tier, at, speakerId)
    local now = nowMs(at)
    local key = tostring(scopeKey or "global") .. "|" .. tostring(topic or "generic")
    local prev = saturation[key]
    lruPut(saturation, saturationOrder, key, {
        lastAt = now,
        tier = math.max(tonumber(tier) or 1, tonumber(prev and prev.tier) or 1),
        count = (tonumber(prev and prev.count) or 0) + 1,
    }, MAX_SATURATION_KEYS)
    if speakerId ~= nil then
        recentSpeakerAt[tostring(speakerId)] = now
    end
end

function Director.PromoteToChronicle(groupKey, moment, at)
    if type(moment) ~= "table" then return false end
    local gKey = tostring(groupKey or "global")
    local kind = tostring(moment.kind or "event")
    local ring = groupChronicles[gKey]
    if not ring then
        ring = {}
        lruPut(groupChronicles, chronicleGroupOrder, gKey, ring, MAX_STORY_GROUPS)
    end
    for i = #ring, 1, -1 do
        if ring[i].kind == kind then
            table.remove(ring, i)
        end
    end
    while #ring >= MAX_CHRONICLE_PER_GROUP do
        table.remove(ring, 1)
    end
    ring[#ring + 1] = {
        kind = kind,
        topic = tostring(moment.topic or "world_event"),
        actorId = moment.actorId and tostring(moment.actorId) or nil,
        salience = tonumber(moment.salience) or CHRONICLE_PROMOTE_SALIENCE,
        at = nowMs(at),
    }
    return true
end

function Director.GetChronicle(groupKey)
    local gKey = tostring(groupKey or "global")
    local ring = groupChronicles[gKey]
    local out = {}
    if type(ring) ~= "table" then return out end
    for i = #ring, 1, -1 do
        out[#out + 1] = ring[i]
    end
    return out
end

function Director.RecordStoryMoment(groupKey, moment, at)
    if type(moment) ~= "table" then return false end
    local now = nowMs(at)
    local gKey = tostring(groupKey or "global")
    local ring = storyMoments[gKey]
    if not ring then
        ring = {}
        lruPut(storyMoments, storyGroupOrder, gKey, ring, MAX_STORY_GROUPS)
    end
    while #ring >= MAX_STORY_MOMENTS do
        table.remove(ring, 1)
    end
    local entry = {
        kind = tostring(moment.kind or "event"),
        topic = tostring(moment.topic or "world_event"),
        actorId = moment.actorId and tostring(moment.actorId) or nil,
        valence = tonumber(moment.valence) or 0,
        salience = tonumber(moment.salience) or 50,
        meta = type(moment.meta) == "table" and moment.meta or nil,
        at = now,
        expiresAt = now + (tonumber(moment.ttlMs) or STORY_TTL_MS),
    }
    ring[#ring + 1] = entry
    if entry.salience >= CHRONICLE_PROMOTE_SALIENCE or moment.chronicle == true then
        Director.PromoteToChronicle(gKey, entry, now)
    end
    if PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled == true
        and PNC.PerformanceScalingDiagnostics.LogBeatsAudit
    then
        PNC.PerformanceScalingDiagnostics.LogBeatsAudit("director_story_moment", {
            "group=" .. gKey,
            "kind=" .. tostring(moment.kind or "event"),
            "topic=" .. tostring(moment.topic or "world_event"),
            "actor=" .. tostring(moment.actorId or "nil"),
            "salience=" .. tostring(tonumber(moment.salience) or 50),
        })
    end
    return true
end

function Director.GatherStoryRecall(groupKey, members, playerKey, at)
    local now = nowMs(at)
    local out = {}
    local gKey = tostring(groupKey or "global")
    local ring = storyMoments[gKey]
    if type(ring) == "table" then
        for i = #ring, 1, -1 do
            local m = ring[i]
            if now < (tonumber(m.expiresAt) or 0) then
                out[#out + 1] = {
                    source = "short_term",
                    kind = m.kind,
                    topic = m.topic,
                    actorId = m.actorId,
                    valence = m.valence,
                    salience = m.salience,
                    meta = m.meta,
                    ageMs = math.max(0, now - (tonumber(m.at) or now)),
                }
                if #out >= 4 then break end
            end
        end
    end
    -- Pull unforgotten durable world facts from PsychopatzCore.WorldKnowledge.
    local wkg = PsychopatzCore and PsychopatzCore.WorldKnowledge or nil
    if #out < 4 and wkg and type(wkg.QueryActorFacts) == "function"
        and type(members) == "table" and members[1]
    then
        local ok, facts = pcall(wkg.QueryActorFacts, members[1].actorID or members[1].id, { limit = 4 })
        if ok and type(facts) == "table" then
            for i = 1, #facts do
                local f = facts[i]
                if type(f) == "table" and f.factKind then
                    out[#out + 1] = {
                        source = "world_knowledge",
                        kind = tostring(f.factKind),
                        topic = tostring(f.factKind),
                        salience = math.floor((tonumber(f.salience) or 0.5) * 80),
                        valence = 0,
                        factID = f.factID,
                    }
                    if #out >= 4 then break end
                end
            end
        end
    end
    -- Query registered modular StoryRecall providers (e.g. quests, medical, factions).
    if #out < 4 and #storyRecallProviderOrder > 0 then
        for pi = 1, #storyRecallProviderOrder do
            if #out >= 4 then break end
            local pid = storyRecallProviderOrder[pi]
            local fn = storyRecallProviders[pid]
            if type(fn) == "function" then
                local ok, items = pcall(fn, gKey, members, playerKey, now)
                if ok and type(items) == "table" then
                    for ii = 1, #items do
                        local item = items[ii]
                        if type(item) == "table" and item.topic then
                            out[#out + 1] = {
                                source = tostring(item.source or pid),
                                kind = tostring(item.kind or item.topic),
                                topic = tostring(item.topic),
                                actorId = item.actorId and tostring(item.actorId) or nil,
                                valence = tonumber(item.valence) or 0,
                                salience = tonumber(item.salience) or 50,
                                ageMs = tonumber(item.ageMs) or 0,
                            }
                            if #out >= 4 then break end
                        end
                    end
                end
            end
        end
    end
    return out
end

function Director.RegisterTopicPolicy(topic, policy)
    topic = tostring(topic or "")
    if topic == "" or type(policy) ~= "table" then return false end
    topicPolicies[topic] = {
        tier = tonumber(policy.tier) or 1,
        urgency = tonumber(policy.urgency) or 40,
        salience = tonumber(policy.salience) or 50,
        saturationWindowMs = tonumber(policy.saturationWindowMs) or 30000,
        silenceThreshold = tonumber(policy.silenceThreshold) or 46,
    }
    return true
end

function Director.GetTopicPolicy(topic)
    return topicPolicies[tostring(topic or "")]
end

function Director.RegisterStoryRecallProvider(id, fn)
    id = tostring(id or "")
    if id == "" or type(fn) ~= "function" then return false end
    if storyRecallProviders[id] == nil then
        storyRecallProviderOrder[#storyRecallProviderOrder + 1] = id
        table.sort(storyRecallProviderOrder)
    end
    storyRecallProviders[id] = fn
    return true
end

function Director.UnregisterStoryRecallProvider(id)
    id = tostring(id or "")
    if storyRecallProviders[id] == nil then return false end
    storyRecallProviders[id] = nil
    for i = #storyRecallProviderOrder, 1, -1 do
        if storyRecallProviderOrder[i] == id then
            table.remove(storyRecallProviderOrder, i)
            break
        end
    end
    return true
end

function Director.RegisterSocialActProfile(act, profile)
    act = string.upper(tostring(act or ""))
    if act == "" or type(profile) ~= "table" then return false end
    ACT_SOCIAL_PROFILE[act] = profile
    return true
end

-- Unified 1-call admission gate for any emitter using registered topic policies.
function Director.GateEmitter(topic, speaker, opts)
    opts = type(opts) == "table" and opts or {}
    local tName = tostring(topic or "generic")
    local pol = topicPolicies[tName] or {}
    return Director.EvaluateCandidate({
        speaker = speaker,
        scopeKey = opts.scopeKey or (tName .. ":" .. tostring(speaker and speaker.id or "global")),
        groupKey = opts.groupKey,
        topic = opts.topic or tName,
        tier = opts.tier ~= nil and opts.tier or pol.tier,
        urgency = opts.urgency ~= nil and opts.urgency or pol.urgency,
        salience = opts.salience ~= nil and opts.salience or pol.salience,
        contextFit = opts.contextFit,
        continuityBonus = opts.continuityBonus,
        includesPlayer = opts.includesPlayer,
        saturationWindowMs = opts.saturationWindowMs ~= nil and opts.saturationWindowMs or pol.saturationWindowMs,
        silenceThreshold = opts.silenceThreshold ~= nil and opts.silenceThreshold or pol.silenceThreshold,
        jitterAmplitude = opts.jitterAmplitude,
        deterministic = opts.deterministic,
        markOnAdmit = opts.markOnAdmit,
        now = opts.now,
    })
end

function Director.EvaluateCandidate(spec)
    spec = type(spec) == "table" and spec or {}
    local now = nowMs(spec.now)
    local density = Director.GetDensityProfile()
    local urgency = tonumber(spec.urgency) or 30
    local scopeKey = tostring(spec.scopeKey or spec.groupKey or (spec.speaker and spec.speaker.id) or "global")
    local topic = tostring(spec.topic or "generic")
    local tier = tonumber(spec.tier) or 1
    local satWindow = math.floor((tonumber(spec.saturationWindowMs) or 35000) * density.cooldownScale)

    local isSat, satRem, satReason = Director.CheckSaturation(scopeKey, topic, tier, now, satWindow)
    evalCount = evalCount + 1
    local audit = PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled == true
    if isSat and urgency < 85 then
        suppressedCount = suppressedCount + 1
        if audit and PNC.PerformanceScalingDiagnostics.LogBeatsAudit then
            PNC.PerformanceScalingDiagnostics.LogBeatsAudit("director_eval", {
                "decision=suppress",
                "reason=" .. satReason,
                "topic=" .. topic,
                "tier=" .. tostring(tier),
                "remainingMs=" .. tostring(math.floor(satRem)),
            })
        end
        return false, { reason = satReason, remainingMs = satRem, score = 0 }
    end

    local voice = Director.ResolveVoiceProfile(spec.speaker, now)
    local baseSalience = tonumber(spec.salience) or 50
    local contextFit = tonumber(spec.contextFit) or 0
    local continuityBonus = tonumber(spec.continuityBonus) or 0
    local playerBonus = spec.includesPlayer == true and 8 or 0
    local recentPenalty = 0
    local spId = spec.speaker and spec.speaker.id and tostring(spec.speaker.id) or nil
    if spId and recentSpeakerAt[spId] and (now - recentSpeakerAt[spId]) < 15000 then
        recentPenalty = 14
    end

    evalSeq = evalSeq + 1
    local jitter = spec.deterministic == true and 0
        or boundedJitter(scopeKey .. ":" .. topic, evalSeq, tonumber(spec.jitterAmplitude) or 8)
    local score = baseSalience + contextFit + continuityBonus + playerBonus - recentPenalty + jitter
    local baseThreshold = tonumber(spec.silenceThreshold) or 46
    local effectiveThreshold = (baseThreshold / voice.chattiness) * density.thresholdScale
    if urgency >= 80 then
        effectiveThreshold = effectiveThreshold * 0.45
    end

    local admit = score >= effectiveThreshold
    if admit then
        admittedCount = admittedCount + 1
    else
        suppressedCount = suppressedCount + 1
    end
    if admit and spec.markOnAdmit ~= false then
        Director.MarkSpoken(scopeKey, topic, tier, now, spId)
    end
    if audit and PNC.PerformanceScalingDiagnostics.LogBeatsAudit then
        PNC.PerformanceScalingDiagnostics.LogBeatsAudit("director_eval", {
            "decision=" .. (admit and "admit" or "suppress"),
            "topic=" .. topic,
            "speaker=" .. tostring(spId or "nil"),
            "style=" .. tostring(voice.socialStyle),
            "chattiness=" .. tostring(math.floor(voice.chattiness * 100) / 100),
            "score=" .. tostring(math.floor(score * 10) / 10),
            "threshold=" .. tostring(math.floor(effectiveThreshold * 10) / 10),
            "density=" .. tostring(density.name),
        })
    end
    return admit, {
        reason = admit and "admitted" or "below_silence_threshold",
        score = score,
        threshold = effectiveThreshold,
        voice = voice,
        density = density,
    }
end

local function makeNPCTargetKey(rec)
    if type(rec) ~= "table" or rec.id == nil then return nil end
    local types = PNC.RelationshipTypes
    if types and type(types.MakeNPCKey) == "function" then
        return types.MakeNPCKey(rec.id)
    end
    return "npc:" .. tostring(rec.id)
end

local function pairApproval(responder, recipient)
    local rel = PNC.Relationships or PNC.RelationshipService
    if rel and responder and recipient and responder.id ~= nil and recipient.id ~= nil then
        local targetKey = makeNPCTargetKey(recipient)
        if type(rel.Get) == "function" and targetKey then
            local ok, r = pcall(rel.Get, responder.id, targetKey)
            if ok and type(r) == "table" then
                return tonumber(r.approval) or 0, tonumber(r.respect) or 0
            end
        elseif type(rel.GetRelation) == "function" then
            local ok, r = pcall(rel.GetRelation, responder, recipient)
            if ok and type(r) == "table" then
                return tonumber(r.approval) or 0, tonumber(r.respect) or 0
            end
        end
    end
    return 0, 0
end

-- Shared 3-stance actor-agnostic frontier (positive / neutral / negative)
-- reused by both player follow-up choices and NPC-to-NPC gossip selection.
function Director.BuildStanceFrontier(topic)
    local t = tostring(topic or "gossip")
    return {
        { id = t .. ":stance_positive", stance = "stance_positive", speechAct = "AGREE",    priority = 10 },
        { id = t .. ":stance_neutral",  stance = "stance_neutral",  speechAct = "CLARIFY",  priority = 10 },
        { id = t .. ":stance_negative", stance = "stance_negative", speechAct = "DISAGREE", priority = 10 },
    }
end

-- Actor-agnostic NPC suggestion picker: scores the exact same suggestion/offer
-- frontier presented as player UI buttons, using NPC personality, mood, stress,
-- current pair relationship, and bounded organic randomness.
function Director.SelectSuggestionForNPC(responder, recipient, candidates, opts)
    if type(candidates) ~= "table" or #candidates == 0 then return nil, nil end
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(opts.now)
    local voice = Director.ResolveVoiceProfile(responder, now)
    local approval, respect = pairApproval(responder, recipient)
    local tension = tonumber(opts.sceneTension) or 0
    local best, bestScore = nil, -math.huge

    for i = 1, #candidates do
        local c = candidates[i]
        if type(c) == "table" then
            local act = string.upper(tostring(c.speechAct or c.act or c.intent or "AGREE"))
            local prof = ACT_SOCIAL_PROFILE[act] or { valence = 0, styleBias = {} }
            local styleBonus = tonumber(prof.styleBias and prof.styleBias[voice.socialStyle]) or 0
            local relBonus = prof.valence * clamp((approval + respect * 0.5) * 0.18, -14, 14)
            -- Low composure / high stress increases friction probability; high empathy favors defuse.
            local moodBonus = 0
            if prof.valence < 0 then
                moodBonus = (1.0 - voice.composure) * 14 + (tension > 30 and 6 or 0)
            elseif act == "DEFUSE" or act == "PACIFY" or act == "REASSURE" then
                moodBonus = voice.empathy * 14 + (tension >= 20 and 12 or 0)
            else
                moodBonus = voice.empathy * 8
            end
            evalSeq = evalSeq + 1
            local jitter = opts.deterministic == true and 0
                or boundedJitter(tostring(responder and responder.id or "") .. ":" .. act, evalSeq, 7)
            local s = (tonumber(c.priority) or 10) + styleBonus + relBonus + moodBonus + jitter
            if s > bestScore then
                bestScore = s
                best = c
            end
        end
    end
    if best
        and PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled == true
        and PNC.PerformanceScalingDiagnostics.LogBeatsAudit
    then
        PNC.PerformanceScalingDiagnostics.LogBeatsAudit("director_suggestion", {
            "responder=" .. tostring(responder and responder.id or "nil"),
            "recipient=" .. tostring(recipient and recipient.id or "nil"),
            "act=" .. tostring(best.speechAct or best.act or best.intent or "AGREE"),
            "score=" .. tostring(math.floor(bestScore * 10) / 10),
            "tension=" .. tostring(tension),
            "style=" .. tostring(voice.socialStyle),
        })
    end
    return best, bestScore
end

-- Apply rate-limited autonomous NPC-to-NPC relationship evolution through the
-- existing RelationshipService (capped per pair per in-game hour).
function Director.ApplyAutonomousRelationshipDelta(responder, recipient, act, at)
    if type(responder) ~= "table" or type(recipient) ~= "table" then return false, "invalid_actors" end
    if responder.id == nil or recipient.id == nil or responder.id == recipient.id then
        return false, "invalid_pair"
    end
    local prof = ACT_SOCIAL_PROFILE[string.upper(tostring(act or ""))]
    if not prof then return false, "act_no_social_delta" end

    local hrs = nowWorldHours()
    local bucket = math.floor(hrs)
    local aId, bId = tostring(responder.id), tostring(recipient.id)
    local pKey = (aId < bId and (aId .. "|" .. bId) or (bId .. "|" .. aId)) .. ":" .. tostring(bucket)
    local used = pairDeltaBudgets[pKey]
    if not used then
        used = { approval = 0, respect = 0 }
        lruPut(pairDeltaBudgets, pairBudgetOrder, pKey, used, MAX_PAIR_BUDGET_KEYS)
    end
    if math.abs(used.approval) >= MAX_APPROVAL_PER_HOUR and math.abs(used.respect) >= MAX_RESPECT_PER_HOUR then
        return false, "pair_hourly_cap_reached"
    end

    local dApp = clamp(prof.approval or 0, -(MAX_APPROVAL_PER_HOUR - math.abs(used.approval)), MAX_APPROVAL_PER_HOUR - math.abs(used.approval))
    local dRep = clamp(prof.respect or 0, -(MAX_RESPECT_PER_HOUR - math.abs(used.respect)), MAX_RESPECT_PER_HOUR - math.abs(used.respect))
    local dFam = tonumber(prof.familiarity) or 0
    used.approval = used.approval + dApp
    used.respect = used.respect + dRep
    relationshipDeltaCount = relationshipDeltaCount + 1

    local applied = false
    local relSvc = PNC.Relationships or PNC.RelationshipService
    local targetKey = makeNPCTargetKey(recipient)
    if relSvc and type(relSvc.ApplyConversationEffect) == "function" and targetKey then
        local ok, res = pcall(relSvc.ApplyConversationEffect, responder.id, targetKey, {
            approval = dApp,
            respect = dRep,
            familiarity = dFam,
            memoryType = "npc_banter_" .. string.lower(tostring(act)),
            interactionType = tostring(prof.socialType or "npc_banter"),
            tags = { conversation = true, autonomous_banter = true },
        }, {
            worldAgeHours = hrs,
            sourceSystem = "conversation_director",
            blockID = "director_banter",
            choiceID = tostring(act),
            outcomeID = tostring(prof.socialType or act),
            eventID = "director_banter:" .. aId .. ":" .. bId .. ":" .. tostring(math.floor(nowMs(at))),
        })
        applied = ok == true and res ~= false
    elseif relSvc and type(relSvc.ApplyInteractionDelta) == "function" then
        local ok = pcall(relSvc.ApplyInteractionDelta, responder, recipient, {
            approval = dApp,
            respect = dRep,
            familiarity = dFam,
            socialType = prof.socialType,
            source = "conversation_director",
            at = nowMs(at),
        })
        applied = ok == true
    end
    if PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled == true
        and PNC.PerformanceScalingDiagnostics.LogBeatsAudit
    then
        PNC.PerformanceScalingDiagnostics.LogBeatsAudit("director_relationship", {
            "responder=" .. aId,
            "recipient=" .. bId,
            "act=" .. tostring(act),
            "dApproval=" .. tostring(dApp),
            "dRespect=" .. tostring(dRep),
            "dFamiliarity=" .. tostring(dFam),
            "applied=" .. tostring(applied),
        })
    end
    return true, { approval = dApp, respect = dRep, familiarity = dFam, applied = applied }
end

function Director.GetAuditState(at)
    local now = nowMs(at)
    local density = Director.GetDensityProfile()
    local activeStoryMoments = 0
    for i = 1, #storyGroupOrder do
        local ring = storyMoments[storyGroupOrder[i]]
        if type(ring) == "table" then
            for j = 1, #ring do
                if now < (tonumber(ring[j].expiresAt) or 0) then
                    activeStoryMoments = activeStoryMoments + 1
                end
            end
        end
    end
    return {
        densityLevel = density.level,
        densityName = density.name,
        cooldownScale = density.cooldownScale,
        thresholdScale = density.thresholdScale,
        voiceCacheCount = #voiceOrder,
        saturationCount = #saturationOrder,
        storyGroupCount = #storyGroupOrder,
        storyMomentCount = activeStoryMoments,
        pairBudgetCount = #pairBudgetOrder,
        evalCount = evalCount,
        admittedCount = admittedCount,
        suppressedCount = suppressedCount,
        relationshipDeltaCount = relationshipDeltaCount,
    }
end

function Director.RecordInterruption(groupKey, info, at)
    groupKey = tostring(groupKey or "")
    if groupKey == "" or type(info) ~= "table" or not info.topic then return false end
    local now = nowMs(at)
    lruPut(interruptedThreads, interruptedOrder, groupKey, {
        topic = tostring(info.topic),
        speakerID = info.speakerID and tostring(info.speakerID) or nil,
        reason = tostring(info.reason or "interrupted"),
        recordedAt = now,
        expiresAt = now + (tonumber(info.ttlMs) or INTERRUPTION_TTL_MS),
    }, MAX_INTERRUPTED_GROUPS)
    return true
end

function Director.ConsumeInterruption(groupKey, at)
    groupKey = tostring(groupKey or "")
    local entry = interruptedThreads[groupKey]
    if type(entry) ~= "table" then return nil end
    interruptedThreads[groupKey] = nil
    local now = nowMs(at)
    if now > (tonumber(entry.expiresAt) or 0) then
        return nil
    end
    return entry
end

function Director.ResetRuntime()
    voiceCache, voiceOrder = {}, {}
    saturation, saturationOrder = {}, {}
    storyMoments, storyGroupOrder = {}, {}
    groupChronicles, chronicleGroupOrder = {}, {}
    interruptedThreads, interruptedOrder = {}, {}
    recentSpeakerAt = {}
    pairDeltaBudgets, pairBudgetOrder = {}, {}
    evalSeq = 0
    evalCount, admittedCount, suppressedCount, relationshipDeltaCount = 0, 0, 0, 0
    local st = PNC.Semantics and PNC.Semantics.StanceAlignment or nil
    if st and type(st.ResetRuntime) == "function" then st.ResetRuntime() end
end

require "PNC/Semantics/PNC_StanceAlignmentService"

function Director.RegisterTopicAxis(topic, axis)
    local st = PNC.Semantics and PNC.Semantics.StanceAlignment or nil
    return st and type(st.RegisterTopicAxis) == "function" and st.RegisterTopicAxis(topic, axis) or false
end

function Director.ResolvePreferredStance(witness, topic, at)
    local st = PNC.Semantics and PNC.Semantics.StanceAlignment or nil
    if st and type(st.ResolvePreferredStance) == "function" then
        return st.ResolvePreferredStance(witness, topic, at)
    end
    return "stance_neutral", "social", nil
end

function Director.EvaluateStanceImpact(speaker, addressee, witnesses, topic, chosenStance, opts)
    local st = PNC.Semantics and PNC.Semantics.StanceAlignment or nil
    if st and type(st.EvaluateStanceImpact) == "function" then
        return st.EvaluateStanceImpact(speaker, addressee, witnesses, topic, chosenStance, opts)
    end
    return {}, nil
end

return Director

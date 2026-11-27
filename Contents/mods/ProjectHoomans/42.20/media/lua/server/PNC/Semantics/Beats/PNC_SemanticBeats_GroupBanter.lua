-- Unified context-smart banter director atop DialogueBeats + BeatContext + AudienceContext.
-- Supports both solo companion + player banter and 2-4 NPC group conversations
-- with context-scored topic selection (wellbeing, camp, weather, night, supplies, road).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local GROUP_BANTER_COOLDOWN_MS = 55000
local SOLO_BANTER_COOLDOWN_MS = 70000
local GLOBAL_BANTER_COOLDOWN_MS = 28000
local BANTER_SEARCH_RADIUS = 14
local MAX_TRACKED_GROUPS = 32

local groupCooldowns = {}
local groupOrder = {}
local lastTopicByGroup = {}
local introPairCooldowns = {}
local introPairOrder = {}
local globalBanterCooldownUntil = 0
local banterSeq = 0

local INTRO_RADIUS_SQ = 10 * 10
local INTRO_PAIR_COOLDOWN_MS = 180000
local INTRO_REPLY_FRONTIER = {
    { id = "intro_warm",    speechAct = "ACCEPT",  stance = "stance_positive", priority = 14 },
    { id = "intro_caution", speechAct = "CLARIFY", stance = "stance_neutral",  priority = 12 },
    { id = "intro_refuse",  speechAct = "REFUSE",  stance = "stance_negative", priority = 10 },
}

local function pairKey(idA, idB)
    local a, b = tostring(idA or ""), tostring(idB or "")
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function markIntroCooldown(key, untilAt)
    if introPairCooldowns[key] == nil then
        while #introPairOrder >= MAX_TRACKED_GROUPS do
            local oldest = table.remove(introPairOrder, 1)
            introPairCooldowns[oldest] = nil
        end
        introPairOrder[#introPairOrder + 1] = key
    end
    introPairCooldowns[key] = untilAt
end

local function isHostilePair(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    local h = PNC.Hostility
    if h and type(h.IsHostile) == "function" then
        local ok, res = pcall(h.IsHostile, a, b)
        if ok and res == true then return true end
    end
    local ma = string.lower(tostring(a.hostility and a.hostility.mode or ""))
    local mb = string.lower(tostring(b.hostility and b.hostility.mode or ""))
    return ma == "hostile" or mb == "hostile"
end

local function firstNameOf(rec)
    local raw = type(rec) == "table" and (rec.name or rec.fullName or rec.displayName) or nil
    if not raw then return "friend" end
    local s = string.gsub(tostring(raw), "^%s+", "")
    return string.match(s, "^([^%s]+)") or "friend"
end

if type(Beats.RegisterHook) == "function" then
    Beats.RegisterHook("ambient.npc_introduction", {
        eventTypes = { "ambient.npc_introduction" },
        priority = 56,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.anchor or nil
            local b = payload and payload.partner or nil
            if type(a) ~= "table" or type(b) ~= "table" then return nil end
            return Beats.BuildWorldThread(a, b, {
                refPrefix = "npc_intro:" .. pairKey(a.id, b.id),
                family = "npc_identity_exchange",
                poolID = "semantic.social.identity.ask_name_proactive",
                eventType = "ambient_npc_introduction",
                domain = "social",
                channel = "social",
                topic = "identity_exchange",
                openAct = "GREET",
                openRole = "ask_name_meet_stranger",
                replyAct = tostring(payload.replyAct or "ACCEPT"),
                replyRole = tostring(payload.replyRole or "answer_meet_real_name"),
                chimeAct = tostring(payload.reactAct or "CHAT"),
                chimeRole = tostring(payload.reactRole or "react_meet_real_name"),
                third = a,
                delayMs = 1750,
                priority = 56,
                tokens = payload.tokens,
                context = {
                    topic = "identity_exchange",
                },
            })
        end,
    })
end

local function applyIntroductionRelationship(a, b, act, now)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if not relSvc or type(relSvc.ApplyConversationEffect) ~= "function" then return false end
    local worldHours = PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function"
        and PNC.Core.NowWorldAgeHours() or 0
    local isRefuse = act == "REFUSE"
    local famDelta = isRefuse and 1 or (act == "ACCEPT" and 6 or 5)
    local appDelta = isRefuse and 0 or (act == "ACCEPT" and 2 or 1)
    local resDelta = isRefuse and 0 or 1
    pcall(relSvc.ApplyConversationEffect, tostring(a.id), "npc:" .. tostring(b.id), {
        familiarityDelta = famDelta,
        approvalDelta = appDelta,
        respectDelta = resDelta,
        memoryType = isRefuse and "introduction_declined" or "introduced",
        worldHours = worldHours,
        at = now,
    })
    pcall(relSvc.ApplyConversationEffect, tostring(b.id), "npc:" .. tostring(a.id), {
        familiarityDelta = famDelta,
        approvalDelta = appDelta,
        respectDelta = resDelta,
        memoryType = isRefuse and "introduction_declined" or "introduced",
        worldHours = worldHours,
        at = now,
    })
    return true
end

local function tryCrossFactionIntroduction(groups, now, density, audit)
    local ref = PNC.ActorReference or (PNC.Semantics and PNC.Semantics.ActorReference)
    if not ref or type(ref.KnowsName) ~= "function" then return false end
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil

    -- Flatten already-gathered calm NPCs from groups (zero extra world scan)
    local actors = {}
    local seen = {}
    for gi = 1, #groups do
        local members = groups[gi] and groups[gi].members or nil
        if type(members) == "table" then
            for mi = 1, #members do
                local m = members[mi]
                if type(m) == "table" and m.id ~= nil and not seen[tostring(m.id)] then
                    seen[tostring(m.id)] = true
                    actors[#actors + 1] = m
                end
            end
        end
    end
    if #actors < 2 then return false end

    for i = 1, #actors - 1 do
        local a = actors[i]
        for j = i + 1, #actors do
            local b = actors[j]
            if not isHostilePair(a, b) and not ref.KnowsName(a, b) then
                local az, bz = tonumber(a.z) or 0, tonumber(b.z) or 0
                local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
                local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
                local pKey = pairKey(a.id, b.id)
                if math.abs(az - bz) < 1 and (dx * dx + dy * dy) <= INTRO_RADIUS_SQ
                    and now >= (tonumber(introPairCooldowns[pKey]) or 0)
                then
                    local admitted = true
                    if Dir and type(Dir.EvaluateCandidate) == "function" then
                        admitted = Dir.EvaluateCandidate({
                            speaker = a,
                            scopeKey = "intro:" .. pKey,
                            groupKey = "intro:" .. pKey,
                            topic = "identity_exchange",
                            tier = 2,
                            urgency = 36,
                            salience = 62,
                            saturationWindowMs = 45000,
                            silenceThreshold = 38,
                            markOnAdmit = false,
                            now = now,
                        })
                    end
                    if admitted then
                        local chosen = Dir and type(Dir.SelectSuggestionForNPC) == "function"
                            and Dir.SelectSuggestionForNPC(b, a, INTRO_REPLY_FRONTIER, {
                                now = now,
                                sceneTension = 10,
                            }) or INTRO_REPLY_FRONTIER[1]
                        local act = tostring(chosen and chosen.speechAct or "ACCEPT")
                        local replyRole = act == "REFUSE" and "answer_meet_refuse"
                            or (act == "CLARIFY" and "answer_meet_cautious" or "answer_meet_real_name")
                        local reactRole = act == "REFUSE" and "react_meet_refuse" or "react_meet_real_name"
                        local tokens = {
                            ["speaker.name"] = firstNameOf(a),
                            ["claimed.name"] = firstNameOf(b),
                            ["addressee.name"] = firstNameOf(a),
                        }
                        local ok, res = Beats.Emit("ambient.npc_introduction", {
                            anchor = a,
                            partner = b,
                            replyAct = act,
                            replyRole = replyRole,
                            reactAct = act == "REFUSE" and "ACCEPT" or "GREET",
                            reactRole = reactRole,
                            tokens = tokens,
                        }, now)
                        if ok then
                            local cdScale = tonumber(density and density.cooldownScale) or 1.0
                            markIntroCooldown(pKey, now + math.floor(INTRO_PAIR_COOLDOWN_MS * cdScale))
                            globalBanterCooldownUntil = now + math.floor(GLOBAL_BANTER_COOLDOWN_MS * cdScale)
                            applyIntroductionRelationship(a, b, act, now)
                            if Dir and type(Dir.MarkSpoken) == "function" then
                                Dir.MarkSpoken("intro:" .. pKey, "identity_exchange", 2, now, a.id)
                            end
                            if audit then
                                Beats.AuditLog("npc_introduction", {
                                    "speaker=" .. tostring(a.id),
                                    "partner=" .. tostring(b.id),
                                    "act=" .. act,
                                    "exchanged=" .. tostring(act ~= "REFUSE"),
                                    "threadID=" .. tostring(res or "nil"),
                                })
                            end
                            return true, res
                        end
                    end
                end
            end
        end
    end
    return false
end

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function markGroupCooldown(key, untilAt)
    if groupCooldowns[key] == nil then
        while #groupOrder >= MAX_TRACKED_GROUPS do
            local oldest = table.remove(groupOrder, 1)
            groupCooldowns[oldest] = nil
            lastTopicByGroup[oldest] = nil
        end
        groupOrder[#groupOrder + 1] = key
    end
    groupCooldowns[key] = untilAt
end

local function isCampedMember(rec)
    if type(rec) ~= "table" then return false end
    local order = rec.orderSpec
    if type(order) == "table" and tostring(order.kind or "") == "facility_activity" then
        local act = rec.runtime and rec.runtime.facilityActivity or nil
        if type(act) == "table" and type(act.previousOrder) == "table" then
            order = act.previousOrder
        end
    end
    return type(order) == "table" and tostring(order.kind or "") == "camp"
end

local RECALL_TOPIC_SCORES = {
    post_chopper        = 96,
    post_alarm          = 94,
    post_aebs_alert     = 93,
    post_fight          = 88,
    post_news           = 86,
    post_military_radio = 86,
    post_survivor_radio = 85,
    post_skill_show     = 82,
    post_home_vhs       = 80,
    post_entertainment  = 78,
}

function Beats.RegisterBanterRecallTopic(topic, score)
    topic = tostring(topic or "")
    if topic == "" then return false end
    RECALL_TOPIC_SCORES[topic] = tonumber(score) or 82
    return true
end

local function pickSmartTopic(groupKey, members, aud, now)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local weather = BC and type(BC.GetWorldWeather) == "function" and BC.GetWorldWeather(now) or nil
    local util = BC and type(BC.GetWorldUtilities) == "function" and BC.GetWorldUtilities(now) or nil
    local anyInjuredOrTired = (aud and aud.playerInjured == true) or false
    local anyCamped = false

    for i = 1, #members do
        local m = members[i]
        if isCampedMember(m) then anyCamped = true end
        if not anyInjuredOrTired and BC and type(BC.ResolveActorStats) == "function" then
            local st = BC.ResolveActorStats(m, { inCombat = false }, now)
            if type(st) == "table" and (st.isInjured == true or st.isExhausted == true) then
                anyInjuredOrTired = true
            end
        end
    end

    local scored = {}
    local storyRecallTopics = {}
    local storyRecallMeta = {}
    local function addTopic(name, score, isRecall, meta)
        if lastTopicByGroup[groupKey] == name then
            score = score - 40
        end
        if isRecall then
            storyRecallTopics[name] = true
            if type(meta) == "table" and not storyRecallMeta[name] then
                storyRecallMeta[name] = meta
            end
        end
        scored[#scored + 1] = { topic = name, score = score }
    end

    if Dir and type(Dir.GatherStoryRecall) == "function" then
        local recall = Dir.GatherStoryRecall(groupKey, members, nil, now)
        for i = 1, #recall do
            local r = recall[i]
            local sc = RECALL_TOPIC_SCORES[tostring(r.topic or "")]
            if sc then
                addTopic(tostring(r.topic), sc, true, r.meta)
            end
        end
    end

    if anyInjuredOrTired then addTopic("wellbeing_check", 90) end
    if anyCamped then addTopic("camp_life", 75) end
    local tod = weather and tostring(weather.timeOfDay or "") or ""
    if tod == "night" or tod == "dusk" then addTopic("night_watch", 70) end
    if weather and (weather.isHarshWeather == true or weather.isRaining == true
        or weather.weather == "fog" or weather.weather == "cold" or weather.weather == "snow")
    then
        addTopic("weather_talk", 68)
    end
    if util and (util.powerOn == false or util.waterOn == false) then
        addTopic("supplies_check", 64)
    else
        addTopic("supplies_check", 42)
    end
    addTopic("road_morale", 50)

    table.sort(scored, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.topic < b.topic
    end)
    local top = scored[1] and scored[1].topic or "road_morale"
    return top, storyRecallTopics[top] == true, storyRecallMeta[top]
end

local BANTER_REPLY_FRONTIER = {
    { id = "banter_agree", speechAct = "AGREE", priority = 14 },
    { id = "banter_praise", speechAct = "PRAISE", priority = 10 },
    { id = "banter_reassure", speechAct = "REASSURE", priority = 11 },
    { id = "banter_disagree", speechAct = "DISAGREE", priority = 8 },
    { id = "banter_criticize", speechAct = "CRITICIZE", priority = 6 },
    { id = "banter_antagonize", speechAct = "ANTAGONIZE", priority = 4 },
}

local BANTER_MEDIATION_FRONTIER = {
    { id = "banter_defuse", speechAct = "DEFUSE", priority = 14 },
    { id = "banter_reassure", speechAct = "REASSURE", priority = 10 },
    { id = "banter_agree", speechAct = "AGREE", priority = 8 },
    { id = "banter_criticize", speechAct = "CRITICIZE", priority = 6 },
}

local FRICTION_ACTS = { DISAGREE = true, CRITICIZE = true, ANTAGONIZE = true }

Beats.RegisterHook("ambient.group_banter", {
    eventTypes = { "ambient.group_banter" },
    priority = 24,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        if type(a) ~= "table" or a.alive == false then return nil end
        local b = payload.partner or payload.addressee
        if type(Beats.BuildWorldThread) ~= "function" then return nil end
        local topic = tostring(payload.topic or "road_morale")
        local c = payload.third
        local d = payload.fourth or (c and a or nil)
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "banter:" .. topic,
            family = "ambient_group_banter_" .. topic,
            poolID = "semantic.banter.group",
            eventType = "ambient_group_banter",
            domain = "social",
            channel = "social",
            topic = topic,
            openAct = "CHAT",
            replyAct = tostring(payload.replyAct or "CHAT"),
            chimeAct = tostring(payload.chimeAct or "CHAT"),
            wrapAct = "CHAT",
            openRole = "open",
            replyRole = b and tostring(payload.replyRole or "reply") or nil,
            chimeRole = c and tostring(payload.chimeRole or "chime") or nil,
            wrapRole = d and "wrap" or nil,
            third = c,
            fourth = d,
            priority = 24,
            delayMs = 1500,
            chimeDelayMs = 3100,
            wrapDelayMs = 4700,
            tokens = type(payload.tokens) == "table" and payload.tokens or nil,
        })
    end,
})

function Beats.CheckGroupBanter(at, frame)
    local now = nowMs(at)
    if now < globalBanterCooldownUntil then return false end
    -- Never talk over an active beat thread (alarm, chopper, combat, etc.).
    if (tonumber(Beats.PendingCount) or 0) > 0 then return false end
    local groups
    if type(frame) == "table" and type(frame.getGroups) == "function" then
        groups = frame.getGroups(3, BANTER_SEARCH_RADIUS)
    elseif type(Beats.FindCalmGroupsNearPlayer) == "function" then
        groups = Beats.FindCalmGroupsNearPlayer(now, 3, BANTER_SEARCH_RADIUS)
    else
        return false
    end
    if #groups == 0 then return false end

    local audSvc = PNC.Semantics and PNC.Semantics.AudienceContext or nil
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    local density = Dir and type(Dir.GetDensityProfile) == "function"
        and Dir.GetDensityProfile() or { cooldownScale = 1.0 }
    local audit = type(Beats.IsAuditEnabled) == "function" and Beats.IsAuditEnabled() == true
    if type(Beats.TryCrossFactionEncounter) == "function" then
        local encOk, encRes = Beats.TryCrossFactionEncounter(groups, now, density, audit)
        if encOk then
            globalBanterCooldownUntil = now + math.floor(GLOBAL_BANTER_COOLDOWN_MS * (tonumber(density.cooldownScale) or 1.0))
            return true, encRes
        end
    end
    local introOk, introRes = tryCrossFactionIntroduction(groups, now, density, audit)
    if introOk then
        return true, introRes
    end
    for i = 1, #groups do
        local g = groups[i]
        local members = g.members
        local gKey = tostring(g.teamKey)
        local cdUntil = tonumber(groupCooldowns[gKey]) or 0
        if now >= cdUntil and #members >= 1 then
            local ordered = members
            if Dir and type(Dir.ResolveVoiceProfile) == "function" and #members > 1 then
                ordered = {}
                for mi = 1, #members do ordered[mi] = members[mi] end
                table.sort(ordered, function(m1, m2)
                    local c1 = Dir.ResolveVoiceProfile(m1, now).chattiness or 1.0
                    local c2 = Dir.ResolveVoiceProfile(m2, now).chattiness or 1.0
                    if c1 ~= c2 then return c1 > c2 end
                    return tostring(m1.id or "") < tostring(m2.id or "")
                end)
            end
            local offset = (banterSeq % #ordered)
            local a = ordered[(offset % #ordered) + 1]
            local b = #ordered >= 2 and ordered[((offset + 1) % #ordered) + 1] or nil
            local c = #ordered >= 3 and ordered[((offset + 2) % #ordered) + 1] or nil
            local d = #ordered >= 4 and ordered[((offset + 3) % #ordered) + 1] or nil
            local aud = audSvc and type(audSvc.Resolve) == "function"
                and audSvc.Resolve(a, { b, c, d }, { includeNearbyPlayer = true, playerRadius = BANTER_SEARCH_RADIUS }) or nil
            -- Allow 2+ NPCs OR a solo companion/NPC when an allied player is nearby.
            if #ordered >= 2 or (aud and aud.includesPlayer == true) then
                local resumed = Dir and type(Dir.ConsumeInterruption) == "function"
                    and Dir.ConsumeInterruption(gKey, now) or nil
                local topic, isRecall, recallMeta
                if resumed and resumed.topic then
                    topic, isRecall, recallMeta = tostring(resumed.topic), true, nil
                else
                    topic, isRecall, recallMeta = pickSmartTopic(gKey, ordered, aud, now)
                end
                local admitted = true
                if Dir and type(Dir.EvaluateCandidate) == "function" then
                    admitted = Dir.EvaluateCandidate({
                        speaker = a,
                        scopeKey = gKey,
                        groupKey = gKey,
                        topic = "group_banter:" .. topic,
                        tier = isRecall and 2 or 1,
                        urgency = isRecall and 45 or 24,
                        salience = 54,
                        continuityBonus = isRecall and 16 or 0,
                        includesPlayer = aud and aud.includesPlayer == true,
                        saturationWindowMs = 45000,
                        silenceThreshold = 42,
                        markOnAdmit = false,
                        now = now,
                    })
                end
                if admitted then
                    banterSeq = banterSeq + 1
                    local replyRole, replyAct = "reply", "CHAT"
                    local chimeRole, chimeAct = "chime", "CHAT"
                    local chosenReplyAct, chosenChimeAct = nil, nil
                    if Dir and type(Dir.SelectSuggestionForNPC) == "function" and b then
                        local chosen = Dir.SelectSuggestionForNPC(b, a, BANTER_REPLY_FRONTIER, { now = now, sceneTension = 0 })
                        if chosen and chosen.speechAct then
                            chosenReplyAct = tostring(chosen.speechAct)
                            replyAct = chosenReplyAct
                            if FRICTION_ACTS[chosenReplyAct] then
                                replyRole = "reply_friction"
                                if c then
                                    local med = Dir.SelectSuggestionForNPC(c, b, BANTER_MEDIATION_FRONTIER, { now = now, sceneTension = 35 })
                                    if med and med.speechAct then
                                        chosenChimeAct = tostring(med.speechAct)
                                        chimeAct = chosenChimeAct
                                        chimeRole = FRICTION_ACTS[chosenChimeAct] and "chime_escalate" or "chime_defuse"
                                    end
                                end
                            end
                        end
                    end
                    local banterTokens = nil
                    if type(recallMeta) == "table" then
                        banterTokens = {
                            ["slot.show.name"] = recallMeta.showName or recallMeta.episode or "the broadcast",
                            ["show.name"] = recallMeta.showName or recallMeta.episode or "the broadcast",
                            ["slot.broadcast.channel"] = recallMeta.channelName or "the broadcast",
                            ["slot.broadcast.episode"] = recallMeta.episode or recallMeta.showName or "that broadcast",
                            ["slot.broadcast.topic"] = recallMeta.topicLabel or recallMeta.episode or "that broadcast",
                            ["slot.broadcast.theme"] = recallMeta.theme or "",
                        }
                    end
                    local ok, res = Beats.Emit("ambient.group_banter", {
                        anchor = a,
                        partner = b,
                        third = c,
                        fourth = d,
                        topic = topic,
                        teamKey = gKey,
                        replyRole = replyRole,
                        replyAct = replyAct,
                        chimeRole = chimeRole,
                        chimeAct = chimeAct,
                        tokens = banterTokens,
                    }, now)
                    if ok then
                        lastTopicByGroup[gKey] = topic
                        local cdScale = tonumber(density.cooldownScale) or 1.0
                        local baseCd = #ordered >= 2 and GROUP_BANTER_COOLDOWN_MS or SOLO_BANTER_COOLDOWN_MS
                        markGroupCooldown(gKey, now + math.floor(baseCd * cdScale))
                        globalBanterCooldownUntil = now + math.floor(GLOBAL_BANTER_COOLDOWN_MS * cdScale)
                        if Dir then
                            if type(Dir.MarkSpoken) == "function" then
                                Dir.MarkSpoken(gKey, "group_banter:" .. topic, isRecall and 2 or 1, now, a.id)
                            end
                            if type(Dir.EvaluateStanceImpact) == "function" and b and chosenReplyAct then
                                Dir.EvaluateStanceImpact(b, a, { c, d }, topic, chosenReplyAct, {
                                    now = now,
                                    topicInstanceKey = gKey .. ":" .. tostring(topic) .. ":" .. tostring(banterSeq),
                                })
                                if c and chosenChimeAct then
                                    Dir.EvaluateStanceImpact(c, b, { a, d }, topic, chosenChimeAct, {
                                        now = now,
                                        topicInstanceKey = gKey .. ":" .. tostring(topic) .. ":" .. tostring(banterSeq) .. ":chime",
                                    })
                                end
                            elseif type(Dir.ApplyAutonomousRelationshipDelta) == "function" then
                                if b and chosenReplyAct then
                                    Dir.ApplyAutonomousRelationshipDelta(b, a, chosenReplyAct, now)
                                end
                                if c and b and chosenChimeAct then
                                    Dir.ApplyAutonomousRelationshipDelta(c, b, chosenChimeAct, now)
                                end
                            end
                        end
                        if audit then
                            Beats.AuditLog("group_banter", {
                                "group=" .. gKey,
                                "topic=" .. topic,
                                "recall=" .. tostring(isRecall),
                                "speakers=" .. tostring(#ordered),
                                "replyAct=" .. tostring(chosenReplyAct or "CHAT"),
                                "chimeAct=" .. tostring(chosenChimeAct or "CHAT"),
                                "includesPlayer=" .. tostring(aud and aud.includesPlayer == true),
                                "addressee=" .. tostring(aud and aud.label or "nil"),
                                "threadID=" .. tostring(res or "nil"),
                            })
                        end
                        return true, res
                    end
                end
            end
        end
    end
    return false
end

function Beats.GetGroupBanterAuditState(at)
    local now = nowMs(at)
    return {
        globalCooldownRemainingMs = math.max(0, math.floor((tonumber(globalBanterCooldownUntil) or 0) - now)),
        trackedGroups = #groupOrder,
        banterSeq = banterSeq,
    }
end

function Beats.ResetGroupBanterRuntime()
    groupCooldowns = {}
    groupOrder = {}
    lastTopicByGroup = {}
    introPairCooldowns = {}
    introPairOrder = {}
    globalBanterCooldownUntil = 0
    banterSeq = 0
end

local IntroDir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
if IntroDir and type(IntroDir.RegisterTopicAxis) == "function" then
    IntroDir.RegisterTopicAxis("identity_exchange", "social")
end

return Beats

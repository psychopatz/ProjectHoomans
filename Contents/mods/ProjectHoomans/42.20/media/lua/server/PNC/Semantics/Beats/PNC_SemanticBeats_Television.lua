-- Unified TV, Radio, AEBS, VHS, and CD broadcast reaction beats.
-- Uses PNC_BroadcastClassifier for content-aware show/episode/topic grounding
-- and routes admission + StoryRecall continuity through ConversationDirector.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/Beats/PNC_BroadcastClassifier"

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local Classifier = PNC.Semantics.BroadcastClassifier
local Dir = PNC.Semantics.ConversationDirector

-- Vanilla Build 42 ISRadioInteractions skill code -> PNC.SkillCatalog ID map.
-- Each code awards 50 * amount XP (exact parity with vanilla doSkill).
local MEDIA_CODE_TO_SKILL = {
    CRP = "Carpentry",
    COO = "Cooking",
    FRM = "Agriculture",
    DOC = "FirstAid",
    ELC = "Electrical",
    MTL = "Welding",
    FKN = "Knapping",
    CRV = "Carving",
    AIM = "Aiming",
    REL = "Reloading",
    FIS = "Fishing",
    TAI = "Tailoring",
    MEC = "Mechanics",
    SPR = "Sprinting",
    LFT = "Lightfooted",
    NIM = "Nimble",
    SNE = "Sneaking",
    BAA = "Axe",
    BUA = "LongBlunt",
    SPE = "Spear",
    SBU = "ShortBlunt",
    LBA = "LongBlade",
    SBA = "ShortBlade",
    MAS = "Masonry",
    POT = "Pottery",
    BLA = "Blacksmithing",
    GLA = "Glassmaking",
    HUS = "AnimalCare",
    BUT = "Butchering",
}
local MEDIA_XP_RANGE = 5
local MEDIA_XP_PER_POINT = 50
local MAX_SEEN_MEDIA_GUIDS = 128

local function parseMediaSkillAwards(codes)
    if type(codes) ~= "string" or codes == "" then return nil end
    local awards = nil
    for token in string.gmatch(codes, "([^,]+)") do
        if #token > 4 then
            local code = string.sub(token, 1, 3)
            local op = string.sub(token, 4, 4)
            local skillID = MEDIA_CODE_TO_SKILL[code]
            if skillID and op == "+" then
                local amt = tonumber(string.sub(token, 5))
                if amt and amt > 0 then
                    awards = awards or {}
                    awards[#awards + 1] = { skillID = skillID, amount = amt * MEDIA_XP_PER_POINT }
                end
            end
        end
    end
    return awards
end

local function hasSeenMediaLine(rec, guid)
    if not guid or guid == "" then return false end
    rec.runtime = type(rec.runtime) == "table" and rec.runtime or {}
    local seen = rec.runtime.seenMediaLines
    if type(seen) == "table" and seen[guid] == true then return true end
    return false
end

local function markSeenMediaLine(rec, guid)
    if not guid or guid == "" then return end
    rec.runtime = type(rec.runtime) == "table" and rec.runtime or {}
    local seen = rec.runtime.seenMediaLines
    local order = rec.runtime.seenMediaLineOrder
    if type(seen) ~= "table" or type(order) ~= "table" then
        seen, order = {}, {}
        rec.runtime.seenMediaLines = seen
        rec.runtime.seenMediaLineOrder = order
    end
    if seen[guid] then return end
    while #order >= MAX_SEEN_MEDIA_GUIDS do
        local oldest = table.remove(order, 1)
        seen[oldest] = nil
    end
    order[#order + 1] = guid
    seen[guid] = true
end

function Beats.AwardNearbyCompanionMediaXP(guid, codes, nx, ny, nz, device, line)
    local skills = PNC.Skills
    local sp = PNC.SpatialIndex
    if not skills or type(skills.AddXP) ~= "function"
        or not sp or type(sp.QueryNPCs) ~= "function"
    then
        return 0
    end
    local awards = parseMediaSkillAwards(codes)
    if not awards or #awards == 0 then return 0 end

    local cutoff = 10
    if SandboxVars and tonumber(SandboxVars.LevelForMediaXPCutoff) then
        cutoff = tonumber(SandboxVars.LevelForMediaXPCutoff)
    end
    local info = Classifier and type(Classifier.Classify) == "function"
        and Classifier.Classify(guid, codes, line, device) or nil
    local showName = (info and info.showName) or "Life and Living"
    local floorZ = math.floor(tonumber(nz) or 0)
    local nearby = sp.QueryNPCs(nx, ny, MEDIA_XP_RANGE) or {}
    local rewarded = 0
    local cleanGuid = (type(guid) == "string" and guid ~= "") and guid or nil

    for i = 1, #nearby do
        local rec = nearby[i]
        if type(rec) == "table" and rec.alive ~= false
            and math.floor(tonumber(rec.z) or 0) == floorZ
            and math.abs((tonumber(rec.x) or 0) - nx) <= MEDIA_XP_RANGE
            and math.abs((tonumber(rec.y) or 0) - ny) <= MEDIA_XP_RANGE
            and (type(skills.CanLearn) ~= "function" or skills.CanLearn(rec) == true)
            and not hasSeenMediaLine(rec, cleanGuid)
        then
            local anyForRec = false
            for j = 1, #awards do
                local a = awards[j]
                local curLvl = type(skills.GetLevel) == "function"
                    and (tonumber(skills.GetLevel(rec, a.skillID)) or 0) or 0
                if curLvl < cutoff then
                    if skills.AddXP(rec, a.skillID, a.amount, {
                        source = "tv_broadcast",
                        showName = showName,
                    }) then
                        anyForRec = true
                    end
                end
            end
            if anyForRec then
                markSeenMediaLine(rec, cleanGuid)
                rewarded = rewarded + 1
            end
        end
    end
    return rewarded
end

if Dir and type(Dir.RegisterTopicPolicy) == "function" then
    -- AEBS urgent alerts (air activity / power grid) fire even in Quiet density.
    Dir.RegisterTopicPolicy("broadcast_aebs_urgent", {
        tier = 3, urgency = 86, salience = 88, saturationWindowMs = 55000, silenceThreshold = 25,
    })
    Dir.RegisterTopicPolicy("broadcast_news", {
        tier = 2, urgency = 52, salience = 76, saturationWindowMs = 65000, silenceThreshold = 34,
    })
    Dir.RegisterTopicPolicy("broadcast_ambient", {
        tier = 1, urgency = 36, salience = 68, saturationWindowMs = 80000, silenceThreshold = 36,
    })
end

local THEME_ROLES = {
    aebs_air_activity   = { open = "aebs_air_activity_open",   reply = "aebs_air_activity_reply",   chime = "aebs_air_activity_chime",   wrap = "aebs_air_activity_wrap",   act = "WARN" },
    aebs_power_warning  = { open = "aebs_power_warning_open",  reply = "aebs_power_warning_reply",  chime = "aebs_power_warning_chime",  wrap = "aebs_power_warning_wrap",  act = "WARN" },
    aebs_weather_warning= { open = "aebs_weather_warning_open",reply = "aebs_weather_warning_reply",chime = "aebs_weather_warning_chime",wrap = "aebs_weather_warning_wrap",act = "INFORM" },
    military_comms      = { open = "military_comms_open",      reply = "military_comms_reply",      chime = "military_comms_chime",      wrap = "military_comms_wrap",      act = "REACT" },
    survivor_radio      = { open = "survivor_radio_open",      reply = "survivor_radio_reply",      chime = "survivor_radio_chime",      wrap = "survivor_radio_wrap",      act = "REACT" },
    news_outbreak       = { open = "news_outbreak_open",       reply = "news_outbreak_reply",       chime = "news_outbreak_chime",       wrap = "news_outbreak_wrap",       act = "REACT" },
    news_general        = { open = "news_general_open",        reply = "news_general_reply",        chime = "news_general_chime",        wrap = "news_general_wrap",        act = "CHAT" },
    skill_show          = { open = "tv_watching_life_and_living_open", reply = "tv_watching_life_and_living_reply", chime = "tv_watching_life_and_living_chime", wrap = "tv_watching_life_and_living_wrap", act = "CHAT" },
    home_vhs            = { open = "home_vhs_open",            reply = "home_vhs_reply",            chime = "home_vhs_chime",            wrap = "home_vhs_wrap",            act = "CHAT" },
    music_radio         = { open = "music_radio_open",         reply = "music_radio_reply",         chime = "music_radio_chime",         wrap = "music_radio_wrap",         act = "CHAT" },
    entertainment_tv    = { open = "tv_watching_show_open",    reply = "tv_watching_show_reply",    chime = "tv_watching_show_chime",    wrap = "tv_watching_show_wrap",    act = "CHAT" },
}

function Beats.RegisterBroadcastTheme(theme, spec)
    theme = tostring(theme or "")
    if theme == "" or type(spec) ~= "table" then return false end
    THEME_ROLES[theme] = {
        open = tostring(spec.open or (theme .. "_open")),
        reply = tostring(spec.reply or (theme .. "_reply")),
        chime = tostring(spec.chime or (theme .. "_chime")),
        wrap = tostring(spec.wrap or (theme .. "_wrap")),
        act = tostring(spec.act or "CHAT"),
    }
    return true
end

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj, ...)
    if ok then return val end
    return nil
end

local function getDeviceData(obj)
    if not obj then return nil end
    return safeCall(obj, "getDeviceData")
end

local function isTelevision(obj, dd)
    if not obj then return false end
    if dd and safeCall(dd, "getIsTelevision") == true then return true end
    if type(instanceof) == "function" and instanceof(obj, "IsoTelevision") == true then return true end
    if type(obj) == "table" and obj.isTelevision == true then return true end
    return false
end

local function isMediaDevice(obj, dd)
    if not obj then return false end
    if isTelevision(obj, dd) then return true end
    if dd ~= nil then return true end
    if type(obj) == "table" and (obj.isRadio == true or obj.isEmergencyBroadcast == true or obj.isMediaDevice == true) then
        return true
    end
    return false
end

local function buildTelevisionPlan(anchor, partner, openRole, replyRole, fam, refPrefix, showName, poolID, extra)
    if type(Beats.BuildWorldThread) ~= "function" then return nil end
    extra = type(extra) == "table" and extra or {}
    local tokens = extra.tokens or (showName and {
        ["slot.show.name"] = showName,
        ["show.name"] = showName,
    } or nil)
    return Beats.BuildWorldThread(anchor, partner, {
        refPrefix = refPrefix,
        family = fam,
        poolID = poolID or (extra.isBroadcast == true
            and "semantic.world.media.broadcast"
            or "semantic.world.object.notice"),
        eventType = "world_television_beat",
        domain = "world",
        channel = "world",
        topic = tostring(extra.topic or "television"),
        openAct = tostring(extra.openAct or "CHAT"),
        replyAct = "CHAT",
        chimeAct = "CHAT",
        wrapAct = "CHAT",
        openRole = openRole,
        replyRole = partner and replyRole or nil,
        chimeRole = extra.third and extra.chimeRole or nil,
        wrapRole = extra.fourth and extra.wrapRole or nil,
        third = extra.third,
        fourth = extra.fourth,
        priority = tonumber(extra.priority) or 28,
        delayMs = 1100,
        chimeDelayMs = 2400,
        wrapDelayMs = 3700,
        tokens = tokens,
    })
end

if type(Beats.RegisterObjectBeatHook) == "function" then
    Beats.RegisterObjectBeatHook("world_object.television_vicinity", {
        priority = 25,
        cooldownMs = 90000,
        maxDistance = 3,
        matches = function(obj)
            local dd = getDeviceData(obj)
            if not isTelevision(obj, dd) then return false end
            if dd and safeCall(dd, "getIsTurnedOn") == true then
                return false
            end
            return true
        end,
        evaluate = function(obj, _, anchor, partner, ctx)
            local dd = getDeviceData(obj)
            local powerOff = (type(ctx and ctx.env) == "table" and ctx.env.powerOn == false)
                or (dd and safeCall(dd, "canBePoweredHere") == false)
            if powerOff then
                return buildTelevisionPlan(
                    anchor, partner,
                    "tv_power_out_open", "tv_power_out_reply",
                    "world_tv_power_out", "world:tv_power_out", nil
                )
            end
            return buildTelevisionPlan(
                anchor, partner,
                "tv_reminisce_open", "tv_reminisce_reply",
                "world_tv_reminisce", "world:tv_reminisce", nil
            )
        end,
    })
end

if type(Beats.RegisterDeviceTextHook) == "function" then
    Beats.RegisterDeviceTextHook("device_text.television_show", {
        priority = 35,
        cooldownMs = 15000,
        maxDistance = 12,
        matches = function(device, line, _, _, _, _, _, codes, guid)
            local dd = getDeviceData(device)
            if not isMediaDevice(device, dd) then return false end
            if dd and safeCall(dd, "getIsTurnedOn") == false then return false end
            if Classifier and type(Classifier.Classify) == "function" then
                local info = Classifier.Classify(guid, codes, line, device)
                if info and info.isStatic == true then return false end
            end
            return true
        end,
        evaluate = function(device, line, _, _, _, anchor, partner, ctx, codes, guid)
            local now = (type(ctx) == "table" and tonumber(ctx.now)) or nil
            local info = Classifier and type(Classifier.Classify) == "function"
                and Classifier.Classify(guid, codes, line, device)
                or {
                    theme = "entertainment_tv",
                    channelName = "the broadcast",
                    showName = "the broadcast",
                    episode = "the broadcast",
                    topicLabel = "that broadcast",
                    storyTopic = "post_entertainment",
                    directorPolicy = "broadcast_ambient",
                    urgency = 28,
                    tier = 1,
                }
            if info.isStatic == true then return nil end

            local perc = PNC.Perception
            local gKey = tostring((ctx and ctx.teamKey)
                or (perc and perc.GetTeamKey and perc.GetTeamKey(anchor))
                or (anchor and anchor.id) or "global")
            local director = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
            if director and type(director.GateEmitter) == "function" then
                local okGate = director.GateEmitter(info.directorPolicy or "broadcast_ambient", anchor, {
                    scopeKey = gKey .. ":broadcast:" .. tostring(info.theme),
                    groupKey = gKey,
                    topic = "broadcast:" .. tostring(info.theme),
                    tier = info.tier,
                    urgency = info.urgency,
                    now = now,
                })
                if not okGate then return nil end
            end

            if director and type(director.RecordStoryMoment) == "function" and info.storyTopic then
                director.RecordStoryMoment(gKey, {
                    kind = "heard_broadcast",
                    topic = info.storyTopic,
                    actorId = anchor and anchor.id or nil,
                    salience = info.tier >= 3 and 86 or (info.tier == 2 and 74 or 64),
                    valence = (info.theme == "music_radio" or info.theme == "skill_show" or info.theme == "entertainment_tv") and 1 or -1,
                    ttlMs = 420000,
                    meta = {
                        showName = info.showName,
                        episode = info.episode,
                        channelName = info.channelName,
                        topicLabel = info.topicLabel,
                        theme = info.theme,
                        mediaKind = info.mediaKind,
                    },
                }, now)
            end

            local roles = THEME_ROLES[info.theme] or THEME_ROLES.entertainment_tv
            local third = type(ctx) == "table" and ctx.third or nil
            local fourth = type(ctx) == "table" and (ctx.fourth or (third and anchor or nil)) or nil
            -- Publish the aired broadcast into PsychopatzCore.WorldKnowledge
            -- (existing ledger, zero new ModData) so players can question NPCs
            -- about what actually aired and expand it procedurally to closure.
            local wkg = PsychopatzCore and PsychopatzCore.WorldKnowledge or nil
            if wkg and type(wkg.Publish) == "function" then
                local gt = type(getGameTime) == "function" and getGameTime() or nil
                local nowHours = (gt and type(gt.getWorldAgeHours) == "function" and tonumber(gt:getWorldAgeHours())) or 0
                local factID = "fact:pnc:broadcast:" .. tostring(info.theme) .. ":" .. tostring(math.floor(nowHours / 2))
                wkg.Publish({
                    id = factID,
                    kind = "radio." .. tostring(info.theme),
                    provenance = "radio",
                    occurredAt = nowHours,
                    observedAt = nowHours,
                    ttlHours = 24,
                    salience = info.tier >= 3 and 0.90 or (info.tier == 2 and 0.72 or 0.58),
                    payload = {
                        semanticType = "radio." .. tostring(info.theme),
                        storyLabel = info.topicLabel,
                        headline = info.episode,
                        channelName = info.channelName,
                        showName = info.showName,
                        topicLabel = info.topicLabel,
                        theme = info.theme,
                        mediaKind = info.mediaKind,
                        worldHour = nowHours,
                    },
                })
                if type(wkg.Acquire) == "function" then
                    local listeners = { anchor, partner, third, fourth }
                    for li = 1, #listeners do
                        local rec = listeners[li]
                        if type(rec) == "table" and (rec.actorID or rec.id) then
                            wkg.Acquire(rec.actorID or rec.id, factID, { provenance = "radio" })
                        end
                    end
                end
            end
            return buildTelevisionPlan(
                anchor,
                partner,
                roles.open,
                roles.reply,
                "world_broadcast_" .. tostring(info.theme),
                "world:broadcast:" .. tostring(info.theme),
                info.showName,
                "semantic.world.media.broadcast",
                {
                    isBroadcast = true,
                    topic = tostring(info.theme),
                    openAct = roles.act or "CHAT",
                    chimeRole = roles.chime,
                    wrapRole = roles.wrap,
                    third = third,
                    fourth = fourth,
                    priority = info.tier >= 3 and 50 or (info.tier == 2 and 36 or 28),
                    tokens = {
                        ["slot.show.name"] = info.showName,
                        ["show.name"] = info.showName,
                        ["slot.broadcast.channel"] = info.channelName,
                        ["slot.broadcast.episode"] = info.episode,
                        ["slot.broadcast.topic"] = info.topicLabel,
                        ["slot.broadcast.theme"] = info.theme,
                    },
                }
            )
        end,
    })
end

function Beats.ResetTelevisionRuntime()
end

return Beats

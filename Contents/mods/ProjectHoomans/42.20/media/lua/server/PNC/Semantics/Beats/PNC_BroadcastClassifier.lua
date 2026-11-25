-- Modular content-aware classifier for PZ TV, Radio, AEBS, VHS, and CD broadcasts.
-- Extracts grounded show, episode, channel, and content theme metadata for
-- DialogueBeats, ConversationDirector, and StoryRecall continuity topics.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Classifier = PNC.Semantics.BroadcastClassifier or {}
PNC.Semantics.BroadcastClassifier = Classifier

Classifier.VERSION = 1

local customRules = {}
local customRuleOrder = {}

local NEWS_CHANNELS = {
    [200] = "Triple-N",
    [201] = "WBLN News",
    [206] = "KPATV",
    [210] = "GBC",
    [93200] = "LBMW - Kentucky Radio",
    [94200] = "USR",
    [98000] = "NNR Radio",
    [101200] = "KnoxTalk Radio",
}

local SKILL_CHANNELS = {
    [203] = "Life and Living TV",
}

local MILITARY_CHANNELS = {
    [95000] = "Classified M1A1",
}

local SURVIVOR_CHANNELS = {
    [91200] = "Civilian Radio",
    [107600] = "Unknown Frequency",
}

local MUSIC_CHANNELS = {
    [207] = "Music Video Channel",
    [89400] = "Hitz FM",
}

local ENTERTAINMENT_CHANNELS = {
    [204] = "TURBO",
    [205] = "PawsTV",
    [208] = "National Sports TV",
    [209] = "Brennan Movie Channel",
}

local SKILL_CODE_LABELS = {
    { code = "CRP+", label = "carpentry" },
    { code = "COO+", label = "cooking" },
    { code = "FRM+", label = "farming" },
    { code = "MEC+", label = "mechanics" },
    { code = "ELC+", label = "electrical work" },
    { code = "FOR+", label = "foraging" },
    { code = "FIS+", label = "fishing" },
    { code = "TRP+", label = "trapping" },
    { code = "TAI+", label = "tailoring" },
    { code = "MTL+", label = "metalworking" },
}

local SHOW_EPISODE_PATTERNS = {
    { pat = "woodcraft", label = "Woodcraft" },
    { pat = "cook show", label = "The Cook Show" },
    { pat = "exposure survival", label = "Exposure Survival" },
    { pat = "carzone", label = "Carzone" },
    { pat = "dog goblin", label = "Dog Goblin" },
    { pat = "paws", label = "PawsTV" },
}

local OUTBREAK_KEYWORDS = {
    "knox", "quarantine", "evacuat", "infection", "infected", "exclusion zone",
    "louisville", "containment", "military", "army", "military base", "national guard",
    "cordon", "outbreak", "dead", "bite", "airborne", "virus", "mcgrew",
    "checkpoint", "martial law", "riot", "looting", "curfew", "emergency",
    "shelter in place", "muldraugh", "west point", "fever",
    "disease", "epidemic", "president", "government", "roadblock", "troops",
}

local NEWS_TOPIC_SNIPPETS = {
    { pat = "army",           label = "the Army and military bases" },
    { pat = "national guard", label = "the National Guard deployment" },
    { pat = "military",       label = "the military quarantine" },
    { pat = "louisville",     label = "what's happening in Louisville" },
    { pat = "muldraugh",      label = "the situation around Muldraugh" },
    { pat = "west point",     label = "the situation around West Point" },
    { pat = "evacuat",        label = "the evacuation orders" },
    { pat = "quarantine",     label = "the quarantine zone" },
    { pat = "exclusion zone", label = "the Knox exclusion zone" },
    { pat = "airborne",       label = "the airborne infection reports" },
    { pat = "president",      label = "the President's address" },
    { pat = "mcgrew",         label = "General McGrew's statement" },
    { pat = "riot",           label = "the riots and looting" },
    { pat = "curfew",         label = "the curfew warnings" },
    { pat = "fever",          label = "the fever and sickness reports" },
    { pat = "knox",           label = "the Knox outbreak news" },
}

local function detectNewsTopicLabel(lowerLine)
    for i = 1, #NEWS_TOPIC_SNIPPETS do
        if string.find(lowerLine, NEWS_TOPIC_SNIPPETS[i].pat, 1, true) then
            return NEWS_TOPIC_SNIPPETS[i].label
        end
    end
    return nil
end

local MILITARY_KEYWORDS = {
    "perimeter", "breach", "extraction", "overrun", "alpha", "bravo",
    "command", "sector", "fallback", "artillery", "airstrike", "hostiles",
}

local SURVIVOR_KEYWORDS = {
    "anyone out there", "anyone copy", "mayday", "survivor", "safe house",
    "help us", "need supplies", "come in", "over", "horde", "trapped",
}

local WEATHER_KEYWORDS = {
    "storm", "blizzard", "tropical", "heavy rain", "thunder", "fog",
    "freezing", "frost", "snow", "high wind", "extreme",
}

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj, ...)
    if ok then return val end
    return nil
end

local function hasAny(lowerText, list)
    if type(lowerText) ~= "string" or lowerText == "" then return false end
    for i = 1, #list do
        if string.find(lowerText, list[i], 1, true) then return true end
    end
    return false
end

local function isStaticLine(line)
    if type(line) ~= "string" or line == "" then return true end
    if ZomboidRadio and type(ZomboidRadio.isStaticSound) == "function" then
        local ok, res = pcall(ZomboidRadio.isStaticSound, line)
        if ok and res == true then return true end
    end
    local lower = string.lower(line)
    if string.find(lower, "fzzt", 1, true)
        or string.find(lower, "bzzt", 1, true)
        or string.find(lower, "kshh", 1, true)
        or string.find(lower, "<bzzt>", 1, true)
    then
        -- Pure static if very short; lines with real speech + static pass through.
        if #lower < 18 then return true end
    end
    return false
end

local function detectSkillCode(codes)
    if type(codes) ~= "string" or codes == "" then return nil end
    for i = 1, #SKILL_CODE_LABELS do
        if string.find(codes, SKILL_CODE_LABELS[i].code, 1, true) then
            return SKILL_CODE_LABELS[i].label
        end
    end
    return nil
end

local function detectEpisodeLabel(lowerText, mediaTitle, mediaSubtitle)
    if type(mediaSubtitle) == "string" and mediaSubtitle ~= "" then
        return mediaSubtitle
    end
    if type(mediaTitle) == "string" and mediaTitle ~= "" then
        return mediaTitle
    end
    for i = 1, #SHOW_EPISODE_PATTERNS do
        if string.find(lowerText, SHOW_EPISODE_PATTERNS[i].pat, 1, true) then
            return SHOW_EPISODE_PATTERNS[i].label
        end
    end
    return nil
end

function Classifier.RegisterRule(id, fn)
    id = tostring(id or "")
    if id == "" or type(fn) ~= "function" then return false end
    if customRules[id] == nil then
        customRuleOrder[#customRuleOrder + 1] = id
        table.sort(customRuleOrder)
    end
    customRules[id] = fn
    return true
end

function Classifier.UnregisterRule(id)
    id = tostring(id or "")
    if customRules[id] == nil then return false end
    customRules[id] = nil
    for i = #customRuleOrder, 1, -1 do
        if customRuleOrder[i] == id then
            table.remove(customRuleOrder, i)
            break
        end
    end
    return true
end

function Classifier.Classify(guid, codes, line, device)
    local text = tostring(line or "")
    if isStaticLine(text) then
        return { isStatic = true }
    end

    local dd = device and safeCall(device, "getDeviceData") or nil
    local isTV = (dd and safeCall(dd, "getIsTelevision") == true)
        or (type(instanceof) == "function" and device and instanceof(device, "IsoTelevision") == true)
        or (type(device) == "table" and device.isTelevision == true)
    local freq = dd and tonumber(safeCall(dd, "getChannel")) or nil
    local isEmergency = (dd and safeCall(dd, "isEmergencyBroadcast") == true)
        or (type(device) == "table" and device.isEmergencyBroadcast == true)

    local chName = nil
    if freq ~= nil and ZomboidRadio and type(ZomboidRadio.getInstance) == "function" then
        local radio = ZomboidRadio.getInstance()
        chName = radio and safeCall(radio, "getChannelName", freq)
    end
    if (not chName or chName == "") and freq ~= nil then
        chName = NEWS_CHANNELS[freq] or SKILL_CHANNELS[freq] or MILITARY_CHANNELS[freq]
            or SURVIVOR_CHANNELS[freq] or MUSIC_CHANNELS[freq] or ENTERTAINMENT_CHANNELS[freq]
    end
    if (not chName or chName == "") and isEmergency then
        chName = "Automated Emergency Broadcast"
    end

    local media = dd and safeCall(dd, "getMediaData") or nil
    local mediaTitle = media and (safeCall(media, "getTitleEN") or safeCall(media, "getTitle"))
    local mediaSubtitle = media and (safeCall(media, "getSubtitleEN") or safeCall(media, "getSubtitle"))
    local mediaCategory = media and safeCall(media, "getCategory")
    local catLower = string.lower(tostring(mediaCategory or ""))

    local mediaKind = isTV and "tv" or "radio"
    if catLower == "home-vhs" then
        mediaKind = "home_vhs"
    elseif catLower == "retail-vhs" then
        mediaKind = "vhs"
    elseif catLower == "cds" then
        mediaKind = "cd"
    end

    local lowerLine = string.lower(text)
    local lowerCh = string.lower(tostring(chName or ""))
    local lowerTitle = string.lower(tostring(mediaTitle or ""))
    local lowerAll = lowerLine .. " " .. lowerCh .. " " .. lowerTitle
    local skillLabel = detectSkillCode(codes)
    local episode = detectEpisodeLabel(lowerAll, mediaTitle, mediaSubtitle)

    -- Allow modded/custom broadcast rules to override classification cleanly.
    for i = 1, #customRuleOrder do
        local fn = customRules[customRuleOrder[i]]
        if type(fn) == "function" then
            local ok, custom = pcall(fn, {
                guid = guid, codes = codes, line = text, device = device,
                deviceData = dd, frequency = freq, channelName = chName,
                mediaKind = mediaKind, mediaTitle = mediaTitle, mediaSubtitle = mediaSubtitle,
                mediaCategory = mediaCategory, isEmergency = isEmergency,
            })
            if ok and type(custom) == "table" and custom.theme then
                custom.isStatic = false
                return custom
            end
        end
    end

    local theme, storyTopic, directorPolicy, urgency, tier, topicLabel

    -- 1. Automated Emergency Broadcast System (highest gameplay priority)
    if isEmergency or string.find(lowerCh, "emergency broadcast", 1, true)
        or string.find(lowerLine, "air activity detected", 1, true)
    then
        if string.find(lowerLine, "air activity", 1, true) then
            theme = "aebs_air_activity"
            storyTopic = "post_aebs_alert"
            directorPolicy = "broadcast_aebs_urgent"
            urgency, tier = 86, 3
            episode = episode or "Air Activity Alert"
            topicLabel = "the air activity alert"
        elseif string.find(lowerLine, "power grid", 1, true)
            or string.find(lowerLine, "fluctuat", 1, true)
            or string.find(lowerLine, "blackout", 1, true)
            or string.find(lowerLine, "grid failure", 1, true)
        then
            theme = "aebs_power_warning"
            storyTopic = "post_aebs_alert"
            directorPolicy = "broadcast_aebs_urgent"
            urgency, tier = 84, 3
            episode = episode or "Power Grid Warning"
            topicLabel = "the power grid warning"
        else
            theme = "aebs_weather_warning"
            storyTopic = "post_aebs_alert"
            directorPolicy = "broadcast_news"
            urgency, tier = 54, 2
            episode = episode or (hasAny(lowerLine, WEATHER_KEYWORDS) and "Severe Weather Advisory" or "Emergency Broadcast")
            topicLabel = "the emergency weather forecast"
        end
    -- 2. Military Frequency
    elseif MILITARY_CHANNELS[freq] or string.find(lowerCh, "m1a1", 1, true)
        or (not isTV and hasAny(lowerLine, MILITARY_KEYWORDS))
    then
        theme = "military_comms"
        storyTopic = "post_military_radio"
        directorPolicy = "broadcast_news"
        urgency, tier = 52, 2
        episode = episode or "Military Comms"
        topicLabel = "that military frequency"
    -- 3. Amateur / Survivor Radio
    elseif SURVIVOR_CHANNELS[freq] or string.find(lowerCh, "civilian radio", 1, true)
        or string.find(lowerCh, "unknown frequency", 1, true)
        or (not isTV and hasAny(lowerLine, SURVIVOR_KEYWORDS))
    then
        theme = "survivor_radio"
        storyTopic = "post_survivor_radio"
        directorPolicy = "broadcast_news"
        urgency, tier = 48, 2
        episode = episode or "Survivor Transmission"
        topicLabel = "that survivor broadcast"
    -- 4. Home VHS
    elseif mediaKind == "home_vhs" then
        theme = "home_vhs"
        storyTopic = "post_home_vhs"
        directorPolicy = "broadcast_ambient"
        urgency, tier = 32, 1
        episode = episode or "a home tape"
        topicLabel = "that home video"
    -- 5. Skill Show / Life and Living / Skill VHS
    elseif SKILL_CHANNELS[freq] or skillLabel ~= nil
        or string.find(lowerAll, "life and living", 1, true)
        or string.find(lowerAll, "woodcraft", 1, true)
        or string.find(lowerAll, "cook show", 1, true)
        or string.find(lowerAll, "exposure survival", 1, true)
    then
        theme = "skill_show"
        storyTopic = "post_skill_show"
        directorPolicy = "broadcast_ambient"
        urgency, tier = 34, 1
        episode = episode or (skillLabel and (skillLabel .. " lesson") or "Life and Living")
        topicLabel = skillLabel and ("that " .. skillLabel .. " episode") or ("that " .. tostring(episode) .. " episode")
    -- 6. Music Radio / Music TV / CDs
    elseif mediaKind == "cd" or MUSIC_CHANNELS[freq]
        or string.find(lowerCh, "hitz", 1, true)
        or string.find(lowerCh, "music video", 1, true)
    then
        theme = "music_radio"
        storyTopic = "post_entertainment"
        directorPolicy = "broadcast_ambient"
        urgency, tier = 26, 1
        episode = episode or (chName or "some music")
        topicLabel = "that music"
    -- 7. TV & Radio News (Outbreak vs General)
    elseif NEWS_CHANNELS[freq] or string.find(lowerCh, "news", 1, true)
        or string.find(lowerCh, "triple-n", 1, true)
        or string.find(lowerCh, "knoxtalk", 1, true)
        or string.find(lowerCh, "lbmw", 1, true)
        or string.find(lowerCh, "nnr", 1, true)
        or hasAny(lowerLine, OUTBREAK_KEYWORDS)
    then
        local specificTopic = detectNewsTopicLabel(lowerLine)
        local isOutbreak = specificTopic ~= nil or hasAny(lowerLine, OUTBREAK_KEYWORDS)
        theme = isOutbreak and "news_outbreak" or "news_general"
        storyTopic = "post_news"
        directorPolicy = "broadcast_news"
        urgency, tier = isOutbreak and 46 or 34, isOutbreak and 2 or 1
        episode = episode or (specificTopic or (isOutbreak and "the Knox outbreak coverage" or (chName or "the news")))
        topicLabel = specificTopic or (isOutbreak and "the Knox outbreak news" or "the news report")
    -- 8. Entertainment TV / Retail VHS
    else
        theme = "entertainment_tv"
        storyTopic = "post_entertainment"
        directorPolicy = "broadcast_ambient"
        urgency, tier = 26, 1
        episode = episode or (chName or "the show")
        topicLabel = episode and ("watching " .. tostring(episode)) or "that show"
    end

    local showName = (type(mediaTitle) == "string" and mediaTitle ~= "" and mediaTitle)
        or (type(episode) == "string" and episode ~= "" and episode)
        or (type(chName) == "string" and chName ~= "" and chName)
        or "the broadcast"

    return {
        isStatic = false,
        theme = theme,
        mediaKind = mediaKind,
        channelName = chName or showName,
        showName = showName,
        episode = episode or showName,
        topicLabel = topicLabel or showName,
        storyTopic = storyTopic,
        directorPolicy = directorPolicy,
        urgency = urgency,
        tier = tier,
        frequency = freq,
        skillLabel = skillLabel,
        isEmergency = isEmergency == true,
        isTV = isTV == true,
    }
end

-- Read-only base-game aired broadcast query (zero extra ModData).
-- Reads directly from ZomboidRadio's native RadioScriptManager so NPCs never
-- know about broadcasts that have not aired yet in the current save.
function Classifier.QueryAiredBroadcasts()
    local out = {}
    if not ZomboidRadio or type(ZomboidRadio.getInstance) ~= "function" then
        return out
    end
    local radio = safeCall(ZomboidRadio, "getInstance")
    local mgr = radio and safeCall(radio, "getScriptManager") or nil
    local channels = mgr and safeCall(mgr, "getChannels") or nil
    if not channels then return out end

    local function inspectChannel(ch)
        if not ch then return end
        local lastLine = safeCall(ch, "getLastAiredLine")
        if type(lastLine) ~= "string" or lastLine == "" or isStaticLine(lastLine) then
            return
        end
        local freq = tonumber(safeCall(ch, "GetFrequency")) or tonumber(safeCall(ch, "getFrequency"))
        local name = safeCall(ch, "GetName") or safeCall(ch, "getName")
        local isTV = safeCall(ch, "IsTv") == true or safeCall(ch, "isTv") == true
        local info = Classifier.Classify(nil, "", lastLine, {
            isTelevision = isTV,
            isRadio = not isTV,
            getDeviceData = function()
                return {
                    getIsTelevision = function() return isTV end,
                    getIsTurnedOn = function() return true end,
                    getChannel = function() return freq end,
                    isEmergencyBroadcast = function()
                        return string.find(string.lower(tostring(name or "")), "emergency", 1, true) ~= nil
                    end,
                }
            end,
        })
        if info and info.isStatic ~= true then
            info.lastAiredLine = lastLine
            out[#out + 1] = info
        end
    end

    if type(channels) == "table" then
        for _, ch in pairs(channels) do inspectChannel(ch) end
    elseif type(channels.size) == "function" and type(channels.get) == "function" then
        local count = tonumber(safeCall(channels, "size")) or 0
        for i = 0, count - 1 do
            inspectChannel(safeCall(channels, "get", i))
        end
    elseif type(channels.values) == "function" then
        local vals = safeCall(channels, "values")
        local iter = vals and safeCall(vals, "iterator")
        while iter and safeCall(iter, "hasNext") == true do
            inspectChannel(safeCall(iter, "next"))
        end
    end
    return out
end

function Classifier.HasBroadcastAired(freqOrTheme)
    local aired = Classifier.QueryAiredBroadcasts()
    for i = 1, #aired do
        local a = aired[i]
        if a.frequency == freqOrTheme or a.theme == freqOrTheme or a.channelName == freqOrTheme then
            return true, a
        end
    end
    return false, nil
end

return Classifier

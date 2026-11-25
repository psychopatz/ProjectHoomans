-- Modular broadcast classifier rules & theme registrations for:
-- 1) Project Hoomans / PsychopatzCore Open World Band (69.0 MHz) procedural broadcasts
--    (looter traps, trader caravans, refugee maydays, settlement enclaves, on-air drama)
-- 2) Vanilla Build 42 hidden radio story arcs
--    (Classified M1A1 numbers station, Civilian Radio cannibals, NNR Radio pastor)
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
local Classifier = PNC.Semantics.BroadcastClassifier
if not Classifier or type(Classifier.RegisterRule) ~= "function" then return end

local function hasAny(lowerText, list)
    if type(lowerText) ~= "string" or lowerText == "" then return false end
    for i = 1, #list do
        if string.find(lowerText, list[i], 1, true) then return true end
    end
    return false
end

local LOOTER_TRAP_PATTERNS = {
    "come alone", "free supplies", "signal twice", "we will be waiting",
    "crowds draw the dead", "yeah, free",
}
local TRADER_PATTERNS = {
    "caravan calling", "traveling merchants", "fair trades", "we can trade",
    "batteries, tools", "ask for medicine, fuel", "crates of cans",
}
local REFUGEE_PATTERNS = {
    "civilian group", "families, not soldiers", "fever is getting worse",
    "need medicine and food", "battery is nearly gone", "mayday, mayday",
}
local SETTLEMENT_PATTERNS = {
    "enclave broadcasting", "north watch is clear", "our perimeter is near",
    "identify yourself before coming close", "generator is holding", "people are alive here",
}
local CONFLICT_PATTERNS = {
    "you're an idiot", "took the supplies without asking", "keep your people away",
    "marked that place first", "say it to my face", "stop talking over me",
    "filling the channel", "leaving the supplies behind", "check the east road",
}

local NUMBERS_PATTERNS = {
    "zero", "niner", "alpha", "bravo", "charlie", "delta", "echo",
    "foxtrot", "golf", "hotel", "kilo", "lima", "oscar", "papa",
    "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey", "zulu",
}
local CANNIBAL_PATTERNS = {
    "fresh meat", "hungry", "dinner", "feast", "taste", "butcher", "cannibal", "eat them",
}
local PASTOR_PATTERNS = {
    "the lord", "pray", "repent", "judgment", "shepherd", "flock", "amen", "sinners", "salvation",
}

local function registerTheme(theme, act, storyTopic, recallScore)
    if type(Beats.RegisterBroadcastTheme) == "function" then
        Beats.RegisterBroadcastTheme(theme, {
            open = theme .. "_open",
            reply = theme .. "_reply",
            chime = theme .. "_chime",
            wrap = theme .. "_wrap",
            act = act or "REACT",
        })
    end
    if storyTopic and type(Beats.RegisterBanterRecallTopic) == "function" then
        Beats.RegisterBanterRecallTopic(storyTopic, recallScore or 84)
    end
end

registerTheme("open_band_looter_trap", "WARN",  "post_looter_trap",      89)
registerTheme("open_band_trader",      "CHAT",  "post_trader_radio",     86)
registerTheme("open_band_refugee",     "REACT", "post_refugee_radio",    87)
registerTheme("open_band_settlement",  "INFORM","post_settlement_radio", 86)
registerTheme("open_band_conflict",    "REACT", "post_radio_drama",      83)
registerTheme("numbers_station",       "REACT", "post_numbers_station",  85)
registerTheme("cannibal_radio",        "WARN",  "post_cannibal_radio",   88)
registerTheme("pastor_radio",          "CHAT",  "post_pastor_radio",     82)

-- 1) Project Hoomans / PsychopatzCore Open World Band (69.0 MHz)
Classifier.RegisterRule("pnc_open_world_band", function(ctx)
    local freq = tonumber(ctx.frequency)
    local lowerCh = string.lower(tostring(ctx.channelName or ""))
    local isOpenBand = freq == 69000
        or string.find(lowerCh, "open world band", 1, true) ~= nil
        or string.find(tostring(ctx.guid or ""), "PSY-WORLD", 1, true) ~= nil
    local lower = string.lower(tostring(ctx.line or ""))

    if not isOpenBand and not (
        hasAny(lower, LOOTER_TRAP_PATTERNS)
        or hasAny(lower, TRADER_PATTERNS)
        or hasAny(lower, SETTLEMENT_PATTERNS)
        or hasAny(lower, CONFLICT_PATTERNS)
    ) then
        return nil
    end

    local chName = ctx.channelName or "Open World Band"
    if hasAny(lower, LOOTER_TRAP_PATTERNS) then
        return {
            theme = "open_band_looter_trap", mediaKind = "radio",
            channelName = chName, showName = chName,
            episode = "a suspicious supply call", topicLabel = "that looter trap on the radio",
            storyTopic = "post_looter_trap", directorPolicy = "broadcast_news",
            urgency = 62, tier = 2, frequency = freq, isTV = false,
        }
    elseif hasAny(lower, TRADER_PATTERNS) then
        return {
            theme = "open_band_trader", mediaKind = "radio",
            channelName = chName, showName = chName,
            episode = "a trader caravan call", topicLabel = "that trader caravan on the radio",
            storyTopic = "post_trader_radio", directorPolicy = "broadcast_news",
            urgency = 54, tier = 2, frequency = freq, isTV = false,
        }
    elseif hasAny(lower, CONFLICT_PATTERNS) then
        return {
            theme = "open_band_conflict", mediaKind = "radio",
            channelName = chName, showName = chName,
            episode = "an argument on the open band", topicLabel = "that argument we overheard on the radio",
            storyTopic = "post_radio_drama", directorPolicy = "broadcast_news",
            urgency = 46, tier = 2, frequency = freq, isTV = false,
        }
    elseif hasAny(lower, SETTLEMENT_PATTERNS) then
        return {
            theme = "open_band_settlement", mediaKind = "radio",
            channelName = chName, showName = chName,
            episode = "a settlement enclave broadcast", topicLabel = "that settlement enclave on the radio",
            storyTopic = "post_settlement_radio", directorPolicy = "broadcast_news",
            urgency = 54, tier = 2, frequency = freq, isTV = false,
        }
    elseif hasAny(lower, REFUGEE_PATTERNS) then
        return {
            theme = "open_band_refugee", mediaKind = "radio",
            channelName = chName, showName = chName,
            episode = "a refugee distress call", topicLabel = "that refugee mayday on the radio",
            storyTopic = "post_refugee_radio", directorPolicy = "broadcast_news",
            urgency = 56, tier = 2, frequency = freq, isTV = false,
        }
    end
    return nil
end)

-- 2) Vanilla Build 42 Hidden Story Arcs (Numbers Station, Cannibals, Pastor)
Classifier.RegisterRule("pz_vanilla_special_arcs", function(ctx)
    local freq = tonumber(ctx.frequency)
    local lower = string.lower(tostring(ctx.line or ""))
    local lowerCh = string.lower(tostring(ctx.channelName or ""))

    -- Classified M1A1 Numbers Station
    if (freq == 95000 or string.find(lowerCh, "m1a1", 1, true))
        and (string.find(lower, "%d+%s+%d+%s+%d+") or hasAny(lower, NUMBERS_PATTERNS))
    then
        return {
            theme = "numbers_station", mediaKind = "radio",
            channelName = ctx.channelName or "Classified M1A1",
            showName = "Classified M1A1",
            episode = "that numbers station broadcast",
            topicLabel = "that eerie numbers station",
            storyTopic = "post_numbers_station",
            directorPolicy = "broadcast_news",
            urgency = 50, tier = 2, frequency = freq, isTV = false,
        }
    end

    -- Civilian Radio Cannibals ("kanibals" script)
    if (freq == 91200 or string.find(lowerCh, "civilian radio", 1, true))
        and hasAny(lower, CANNIBAL_PATTERNS)
    then
        return {
            theme = "cannibal_radio", mediaKind = "radio",
            channelName = ctx.channelName or "Civilian Radio",
            showName = "Civilian Radio",
            episode = "those cannibals on Civilian Radio",
            topicLabel = "those sickos talking about hunting people",
            storyTopic = "post_cannibal_radio",
            directorPolicy = "broadcast_news",
            urgency = 58, tier = 2, frequency = freq, isTV = false,
        }
    end

    -- NNR Radio Doomsday Pastor ("pastor" script)
    if (freq == 98000 or string.find(lowerCh, "nnr", 1, true))
        and hasAny(lower, PASTOR_PATTERNS)
    then
        return {
            theme = "pastor_radio", mediaKind = "radio",
            channelName = ctx.channelName or "NNR Radio",
            showName = "NNR Radio",
            episode = "that preacher on NNR Radio",
            topicLabel = "that pastor preaching on the radio",
            storyTopic = "post_pastor_radio",
            directorPolicy = "broadcast_news",
            urgency = 42, tier = 1, frequency = freq, isTV = false,
        }
    end

    return nil
end)

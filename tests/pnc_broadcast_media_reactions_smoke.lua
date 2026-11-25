-- Broadcast, TV, Radio, AEBS, VHS & CD context-aware reaction smoke test:
-- 1) Classifier coverage across all 11 vanilla Build 42 themes + static filtering + custom rules
-- 2) Handheld & car radio (-1, -1, -1) coordinate fallback
-- 3) AEBS Air Activity & Power Grid high-urgency admission even in Quiet ChatterDensity
-- 4) Grounded multi-NPC (open/reply/chime/wrap) broadcast reactions with episode/channel/topic tokens
-- 5) StoryRecall follow-up banter carrying grounded broadcast metadata
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

_G.SandboxVars = { ProjectHoomans = { ChatterDensity = 2 } }
local simNow = 200000
_G.getGameTime = function()
    return { getWorldAgeHours = function() return 24.0 end }
end

local playerObj = {
    getX = function() return 150 end,
    getY = function() return 150 end,
    getZ = function() return 0 end,
    getDescriptor = function() return { getForename = function() return "Rick" end } end,
}

_G.PNC = _G.PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Core = {
    Now = function() return simNow end,
    ForEachPlayer = function(fn) fn(playerObj) end,
}

require "PNC/Core/Base/PNC_Sandbox"
require "PNC/Semantics/PNC_SemanticDialogueBeats"

local Beats = PNC.Semantics.DialogueBeats
local Dir = PNC.Semantics.ConversationDirector
local Classifier = PNC.Semantics.BroadcastClassifier

T.truthy(type(Classifier) == "table", "BroadcastClassifier loaded")

local function makeDevice(opts)
    opts = opts or {}
    local dd = {
        getIsTelevision = function() return opts.isTV == true end,
        getIsTurnedOn = function() return opts.turnedOn ~= false end,
        getChannel = function() return opts.freq end,
        isEmergencyBroadcast = function() return opts.isEmergency == true end,
        getMediaData = function()
            if not opts.mediaTitle and not opts.mediaCategory then return nil end
            return {
                getTitleEN = function() return opts.mediaTitle end,
                getSubtitleEN = function() return opts.mediaSubtitle end,
                getCategory = function() return opts.mediaCategory end,
            }
        end,
    }
    return {
        isTelevision = opts.isTV == true,
        isRadio = opts.isTV ~= true,
        getDeviceData = function() return dd end,
        getX = function() return opts.x or -1 end,
        getY = function() return opts.y or -1 end,
        getZ = function() return opts.z or 0 end,
        getVehicle = function() return opts.vehicle end,
    }
end

-- 1) Classifier coverage across all 11 themes + static filter
T.equal(Classifier.Classify("g", "", "<bzzt> fzzt", makeDevice({ isTV = false })).isStatic, true, "short static filtered")

local cAir = Classifier.Classify("g", "", "Air Activity Detected in sector.", makeDevice({ isEmergency = true }))
T.equal(cAir.theme, "aebs_air_activity", "AEBS air activity classified")
T.equal(cAir.storyTopic, "post_aebs_alert", "AEBS air activity maps to post_aebs_alert")

local cPow = Classifier.Classify("g", "", "Power grid fluctuations detected.", makeDevice({ isEmergency = true }))
T.equal(cPow.theme, "aebs_power_warning", "AEBS power grid classified")

local cWx = Classifier.Classify("g", "", "Heavy rain and storm expected tomorrow.", makeDevice({ isEmergency = true }))
T.equal(cWx.theme, "aebs_weather_warning", "AEBS weather classified")

local cMil = Classifier.Classify("g", "", "Perimeter breach at Louisville checkpoint.", makeDevice({ freq = 95000 }))
T.equal(cMil.theme, "military_comms", "Classified M1A1 classified as military_comms")

local cSurv = Classifier.Classify("g", "", "Anyone copy? We are trapped near the mall.", makeDevice({ freq = 91200 }))
T.equal(cSurv.theme, "survivor_radio", "Civilian Radio classified as survivor_radio")

local cNews = Classifier.Classify("g", "", "Knox exclusion zone quarantine extended by military.", makeDevice({ isTV = true, freq = 200 }))
T.equal(cNews.theme, "news_outbreak", "Triple-N outbreak line classified as news_outbreak")
T.equal(cNews.channelName, "Triple-N", "Triple-N channel name resolved")

local cGen = Classifier.Classify("g", "", "Good evening Kentucky, here is the local update.", makeDevice({ isTV = true, freq = 201 }))
T.equal(cGen.theme, "news_general", "WBLN non-outbreak line classified as news_general")

local cSkill = Classifier.Classify("g", "CRP+1", "Today on Woodcraft we build sturdy shelves.", makeDevice({ isTV = true, freq = 203 }))
T.equal(cSkill.theme, "skill_show", "Life and Living Woodcraft classified as skill_show")
T.equal(cSkill.episode, "Woodcraft", "Woodcraft episode extracted")

local cHVHS = Classifier.Classify("g", "", "Happy birthday Sarah!", makeDevice({ isTV = true, mediaTitle = "Birthday 92", mediaCategory = "Home-VHS" }))
T.equal(cHVHS.theme, "home_vhs", "Home-VHS classified as home_vhs")
T.equal(cHVHS.showName, "Birthday 92", "Home-VHS title preserved")

local cMusic = Classifier.Classify("g", "", "Playing the top hits of 1993!", makeDevice({ freq = 89400 }))
T.equal(cMusic.theme, "music_radio", "Hitz FM classified as music_radio")

local cEnt = Classifier.Classify("g", "", "Bottom of the ninth, bases loaded!", makeDevice({ isTV = true, freq = 208 }))
T.equal(cEnt.theme, "entertainment_tv", "National Sports TV classified as entertainment_tv")

-- Custom rule extensibility
Classifier.RegisterRule("mod_weather_radio", function(ctx)
    if ctx.frequency == 111100 then
        return { theme = "survivor_radio", channelName = "Mod Channel", showName = "Mod Show", episode = "Ep 1", topicLabel = "mod broadcast", storyTopic = "post_survivor_radio", directorPolicy = "broadcast_news", urgency = 50, tier = 2 }
    end
end)
T.equal(Classifier.Classify("g", "", "Hello", makeDevice({ freq = 111100 })).channelName, "Mod Channel", "custom classifier rule works")
Classifier.UnregisterRule("mod_weather_radio")

-- 2) Live handheld/car radio (-1, -1, -1) + AEBS urgent in Quiet density + 4-turn multi-NPC thread
local npcA = { id = "n1", name = "Maya", alive = true, presenceState = "live", x = 151, y = 150, z = 0, social = { personality = { socialStyle = "warm", sociability = 0.8 } } }
local npcB = { id = "n2", name = "Cole", alive = true, presenceState = "live", x = 152, y = 150, z = 0, social = { personality = { socialStyle = "practical", sociability = 0.6 } } }
local npcC = { id = "n3", name = "Glenn", alive = true, presenceState = "live", x = 153, y = 150, z = 0, social = { personality = { socialStyle = "protective", sociability = 0.7 } } }

PNC.SpatialIndex = { QueryNPCs = function() return { npcA, npcB, npcC } end }
PNC.Perception = {
    GetTeamKey = function() return "squad_1" end,
    GetActiveSkirmish = function() return nil end,
}
PNC.Registry = {
    Get = function(id)
        if id == "n1" then return npcA end
        if id == "n2" then return npcB end
        if id == "n3" then return npcC end
        return nil
    end,
}

local delivered = {}
PNC.Semantics.SpeechTransport.ResolveLine = function(_, spec)
    local tokens = type(spec) == "table" and spec.tokens or nil
    return tostring(spec and spec.role or "open")
        .. "|" .. tostring(tokens and tokens["slot.broadcast.channel"] or "")
        .. "|" .. tostring(tokens and tokens["slot.broadcast.episode"] or "")
        .. "|" .. tostring(tokens and tokens["slot.broadcast.topic"] or ""), { poolID = spec and spec.poolID }
end
PNC.Semantics.SpeechTransport.Deliver = function(speaker, _, opts)
    delivered[#delivered + 1] = {
        speaker = speaker and speaker.id or nil,
        text = opts and opts.text or "",
        topic = opts and opts.topic or "",
    }
    return true
end

SandboxVars.ProjectHoomans.ChatterDensity = 1 -- Quiet!
Beats.ResetRuntime()
local handheldRadio = makeDevice({ isTV = false, isEmergency = true })
local okRadio = Beats.OnDeviceTextEvent("guid:aebs", "", -1, -1, -1, "Air Activity Detected.", handheldRadio, simNow)
T.equal(okRadio, true, "handheld/car radio (-1,-1,-1) AEBS air activity admitted even in Quiet density")

for step = 1, 10 do
    simNow = simNow + 800
    Beats.Pump(simNow)
end
T.equal(#delivered, 4, "3-member squad delivers 4 coherent grounded turns (open, reply, chime, wrap) for AEBS alert")
T.contains(delivered[1].text, "aebs_air_activity_open", "turn 1 uses aebs_air_activity_open role")
T.contains(delivered[1].text, "Automated Emergency Broadcast", "grounded channel token propagated")
T.contains(delivered[1].text, "Air Activity Alert", "grounded episode token propagated")
T.contains(delivered[1].text, "the air activity alert", "grounded topic token propagated")

-- 3) Multi-line broadcast deduplication (second AEBS air activity line 2s later suppressed)
local okDup = Beats.OnDeviceTextEvent("guid:aebs", "", -1, -1, -1, "Air Activity Detected again.", handheldRadio, simNow + 2000)
T.equal(okDup, false, "repeated broadcast line in same segment does not spam")

-- 4) StoryRecall follow-up banter carries grounded broadcast metadata
SandboxVars.ProjectHoomans.ChatterDensity = 2
delivered = {}
simNow = simNow + 60000
local okBanter = Beats.CheckGroupBanter(simNow)
T.equal(okBanter, true, "GroupBanter picks up broadcast StoryRecall topic")
for step = 1, 10 do
    simNow = simNow + 900
    Beats.Pump(simNow)
end
T.truthy(#delivered >= 1, "StoryRecall broadcast follow-up banter delivered")
T.equal(delivered[1].topic, "post_aebs_alert", "GroupBanter selected post_aebs_alert continuity topic")
T.contains(delivered[1].text, "Air Activity Alert", "StoryRecall banter preserves grounded episode token")
T.contains(delivered[1].text, "the air activity alert", "StoryRecall banter preserves grounded topic token")

-- 5) Regression: Triple-N Army bases news + non-fighting NPC near TV during active skirmish
local cArmy = Classifier.Classify("g:tnn", "BOR-1", "... and the bases and training facilities of the Army itself.", makeDevice({ isTV = true, freq = 200 }))
T.equal(cArmy.theme, "news_outbreak", "Triple-N Army bases line classifies as news_outbreak")
T.equal(cArmy.topicLabel, "the Army and military bases", "Triple-N Army bases line extracts grounded topic label")

Beats.ResetRuntime()
delivered = {}
simNow = simNow + 90000
-- Simulate active_skirmish rejecting FindCalmGroupsNearPoint while an idle companion stands by the TV.
PNC.Perception.GetActiveSkirmish = function() return { active = true } end
local okArmy = Beats.OnDeviceTextEvent("g:tnn", "BOR-1", 150, 150, 0, "... and the bases and training facilities of the Army itself.", makeDevice({ isTV = true, freq = 200, x = 150, y = 150 }), simNow)
T.equal(okArmy, true, "non-fighting companion standing by TV still reacts even when squad has active_skirmish")
Beats.Pump(simNow + 1500)
T.truthy(#delivered >= 1, "Triple-N news reaction delivered")
T.contains(delivered[1].text, "the Army and military bases", "delivered Triple-N reaction contains grounded topic")

-- 6) Open World Band (69.0 MHz) procedural packs & vanilla hidden radio arcs
local obDev = makeDevice({ isTV = false, freq = 69000 })
T.equal(Classifier.Classify("PSY-WORLD-1", "", "Tell them to come alone. Crowds draw the dead.", obDev).theme,
    "open_band_looter_trap", "Open World Band looter trap classified")
T.equal(Classifier.Classify("PSY-WORLD-2", "", "Caravan calling on the open band. We still have batteries, tools.", obDev).theme,
    "open_band_trader", "Open World Band trader caravan classified")
T.equal(Classifier.Classify("PSY-WORLD-3", "", "This is a civilian group. Families, not soldiers.", obDev).theme,
    "open_band_refugee", "Open World Band refugee mayday classified")
T.equal(Classifier.Classify("PSY-WORLD-4", "", "This is an enclave broadcasting on an open band.", obDev).theme,
    "open_band_settlement", "Open World Band settlement enclave classified")
T.equal(Classifier.Classify("PSY-WORLD-5", "", "You took the supplies without asking, Rick.", obDev).theme,
    "open_band_conflict", "Open World Band on-air conflict classified")

T.equal(Classifier.Classify("g:num", "", "Alpha Tango 4 8 15 16 23 42", makeDevice({ freq = 95000 })).theme,
    "numbers_station", "Classified M1A1 numbers station classified")
T.equal(Classifier.Classify("g:can", "", "Fresh meat coming down the highway tonight.", makeDevice({ freq = 91200 })).theme,
    "cannibal_radio", "Civilian Radio cannibals classified")
T.equal(Classifier.Classify("g:pas", "", "Pray for salvation, the Lord's judgment is upon us.", makeDevice({ freq = 98000 })).theme,
    "pastor_radio", "NNR Radio doomsday pastor classified")

-- Verify live looter trap reaction + StoryRecall post_looter_trap continuity
PNC.Perception.GetActiveSkirmish = function() return nil end
Beats.ResetRuntime()
delivered = {}
simNow = simNow + 90000
local okTrap = Beats.OnDeviceTextEvent("PSY-WORLD-TRAP", "", -1, -1, -1, "Attention travelers. Free supplies near Muldraugh. Come alone.", obDev, simNow)
T.equal(okTrap, true, "Open World Band looter trap emits live squad warning")
for step = 1, 8 do
    simNow = simNow + 800
    Beats.Pump(simNow)
end
T.truthy(#delivered >= 1 and string.find(delivered[1].text, "open_band_looter_trap_open", 1, true) ~= nil,
    "looter trap uses open_band_looter_trap_open role")

delivered = {}
simNow = simNow + 90000
local okTrapBanter = Beats.CheckGroupBanter(simNow)
T.equal(okTrapBanter, true, "GroupBanter picks up post_looter_trap StoryRecall")
Beats.Pump(simNow + 1500)
T.truthy(#delivered >= 1 and delivered[1].topic == "post_looter_trap",
    "GroupBanter weaves post_looter_trap continuity topic")

-- 7) Base-game aired-only check (no ModData) + WorldKnowledge procedural Q&A to closure
local airedLineTripleN = ""
_G.ZomboidRadio = {
    getInstance = function()
        return {
            getChannelName = function(_, f) return f == 200 and "Triple-N" or nil end,
            getScriptManager = function()
                return {
                    getChannels = function()
                        return {
                            {
                                GetFrequency = function() return 200 end,
                                GetName = function() return "Triple-N" end,
                                IsTv = function() return true end,
                                getLastAiredLine = function() return airedLineTripleN end,
                            },
                        }
                    end,
                }
            end,
        }
    end,
}

-- Before Triple-N airs anything, NPCs must NOT know about it
T.equal(Classifier.HasBroadcastAired(200), false, "un-aired channel returns HasBroadcastAired=false")
T.equal(#Classifier.QueryAiredBroadcasts(), 0, "un-aired channels produce 0 aired broadcasts")

-- Once Triple-N airs a line in the base game, Classifier reads it directly with zero ModData
airedLineTripleN = "Knox exclusion zone quarantine extended by military."
local hasAired, airedInfo = Classifier.HasBroadcastAired(200)
T.equal(hasAired, true, "aired Triple-N channel detected directly from ZomboidRadio")
T.equal(airedInfo and airedInfo.theme, "news_outbreak", "aired Triple-N classified as news_outbreak")

-- Load PsychopatzCore.WorldKnowledge and verify procedural expansion -> closure
package.path = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;" .. package.path
local WKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"
WKG.Reset()
local topicsBefore = WKG.QueryConversationTopics("n1", { worldHour = 24.0 }, { limit = 3, includeBanter = false })
T.equal(#topicsBefore, 0, "before hearing a broadcast, NPC has 0 WorldKnowledge broadcast topics")

-- Hearing the broadcast via OnDeviceText publishes & acquires it in WorldKnowledge
Beats.ResetRuntime()
simNow = simNow + 90000
Beats.OnDeviceTextEvent("g:wkg:1", "BOR-1", 150, 150, 0, "... and the bases and training facilities of the Army itself.", makeDevice({ isTV = true, freq = 200, x = 150, y = 150 }), simNow)
local topicsAfter = WKG.QueryConversationTopics("n1", { worldHour = 24.0 }, { limit = 3, includeBanter = false })
T.truthy(#topicsAfter >= 1, "after hearing Triple-N, NPC has WorldKnowledge topic")
local top = topicsAfter[1]
T.equal(top.topic, "news_outbreak", "WorldKnowledge topic mapped to news_outbreak")
T.equal(top.maxDepth, 3, "broadcast topic allows 3-step procedural expansion to closure")
T.equal(top.meta and top.meta.channelName, "Triple-N", "WorldKnowledge topic preserves channelName")
T.equal(top.meta and top.meta.topicLabel, "the Army and military bases", "WorldKnowledge topic preserves grounded topicLabel")

local step1 = WKG.AdvanceTopicFollowUp(top, "more", 0)
T.equal(step1.nextDepth, 1, "follow-up step 1 advances depth to 1")
T.equal(step1.exhausted, false, "step 1 is not yet exhausted")
local step2 = WKG.AdvanceTopicFollowUp(top, "more", step1.nextDepth)
T.equal(step2.nextDepth, 2, "follow-up step 2 advances depth to 2")
T.equal(step2.exhausted, false, "step 2 is not yet exhausted")
local step3 = WKG.AdvanceTopicFollowUp(top, "more", step2.nextDepth)
T.equal(step3.nextDepth, 3, "follow-up step 3 advances depth to 3")
T.equal(step3.exhausted, true, "step 3 reaches clean closure (exhausted=true)")

-- 8) 3-Stance Actor-Agnostic Frontier (warm -> positive, practical -> neutral, hostile -> negative)
local stanceFrontier = Dir.BuildStanceFrontier("pastor_radio")
T.equal(#stanceFrontier, 3, "BuildStanceFrontier returns 3 stances (positive, neutral, negative)")
local warmNPC = { id = "st_warm", social = { personality = { socialStyle = "warm" } } }
local pracNPC = { id = "st_prac", social = { personality = { socialStyle = "practical" } } }
local hostNPC = { id = "st_host", social = { personality = { socialStyle = "hostile" } }, conditionStats = { stress = 0.8 } }
local pickWarm = Dir.SelectSuggestionForNPC(warmNPC, pracNPC, stanceFrontier, { deterministic = true, now = simNow })
local pickPrac = Dir.SelectSuggestionForNPC(pracNPC, warmNPC, stanceFrontier, { deterministic = true, now = simNow })
local pickHost = Dir.SelectSuggestionForNPC(hostNPC, warmNPC, stanceFrontier, { deterministic = true, now = simNow })
T.equal(pickWarm and pickWarm.stance, "stance_positive", "warm NPC picks positive stance on pastor_radio")
T.equal(pickPrac and pickPrac.stance, "stance_neutral", "practical NPC picks neutral stance on pastor_radio")
T.equal(pickHost and pickHost.stance, "stance_negative", "hostile NPC picks negative stance on pastor_radio")

print("pnc_broadcast_media_reactions_smoke: OK")

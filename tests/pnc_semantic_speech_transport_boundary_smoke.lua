local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local nowMs = 50000
local powerGridOn = true
local elecShutDay = 30
local waterShutDay = 30
local tvTurnedOn = true
local tvCanPower = true
local worldSquareObjects = {}
local deliveredBarks = {}
local worldSoundHandlers = {}
local ambientSoundHandlers = {}
local elecChangedHandlers = {}
local deviceTextHandlers = {}

isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getCurrentSaveName = function() return "d3-transport-boundary-smoke" end
getText = function(k) return k end
getTextOrNull = function() return nil end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 14.2 end,
        getWorldAgeHours = function() return 14.2 * 24 end,
        getTimeOfDay = function() return 15 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 19 end,
    }
end
getSandboxOptions = function()
    return {
        doesPowerGridExist = function() return powerGridOn end,
        getElecShutModifier = function() return elecShutDay end,
        getWaterShutModifier = function() return waterShutDay end,
    }
end
getWorld = function()
    return { isHydroPowerOn = function() return powerGridOn end }
end
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
            local objs = worldSquareObjects[key] or {}
            return {
                getRoom = function() return nil end,
                getObjects = function()
                    return {
                        size = function() return #objs end,
                        get = function(_, idx) return objs[idx + 1] end,
                    }
                end,
            }
        end,
    }
end
ZomboidRadio = {
    getInstance = function()
        return { getChannelName = function() return "Life and Living TV" end }
    end,
}
instanceof = function(obj, className)
    return type(obj) == "table" and obj._class == className
end

Events = {
    OnWorldSound = { Add = function(fn) worldSoundHandlers[#worldSoundHandlers + 1] = fn end },
    OnAmbientSound = { Add = function(fn) ambientSoundHandlers[#ambientSoundHandlers + 1] = fn end },
    OnElectricityChanged = { Add = function(fn) elecChangedHandlers[#elecChangedHandlers + 1] = fn end },
    OnDeviceText = { Add = function(fn) deviceTextHandlers[#deviceTextHandlers + 1] = fn end },
    OnTick = { Add = function() end },
    OnResetLua = { Add = function() end },
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local playerObj = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 1 end,
    getUsername = function() return "Pat" end,
    getDisplayName = function() return "Pat" end,
    getDescriptor = function()
        return {
            getForename = function() return "Pat" end,
            getSurname = function() return "Tester" end,
        }
    end,
}
getSpecificPlayer = function() return playerObj end

local npcA = {
    id = "npc_d3_1", name = "Sammie", fullName = "Sammie Patz",
    tacticalClass = "friendly", factionID = "survivors",
    x = 10, y = 10, z = 0, alive = true, presenceState = "live", runtime = {},
}
local npcB = {
    id = "npc_d3_2", name = "Adrienne", fullName = "Adrienne Patz",
    tacticalClass = "friendly", factionID = "survivors",
    x = 11, y = 10, z = 0, alive = true, presenceState = "live", runtime = {},
}
local npcStore = { [npcA.id] = npcA, [npcB.id] = npcB }

PNC = {
    Const = {
        MODULE = "ProjectHoomans",
        CMD_CONVERSATION_RELATIONSHIP = "ConversationRelationship",
        CMD_SEMANTIC_SCENE_SPEECH = "SemanticSceneSpeech",
        ZOMBIE_TARGET_RADIUS = 16,
        ALLY_WARNING_RADIUS = 16,
        TACTICAL_CLASS_HOSTILE = "hostile",
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(cb) cb(playerObj) end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = (x2 or 0) - (x1 or 0), (y2 or 0) - (y1 or 0)
            return dx * dx + dy * dy
        end,
    },
    EntityRef = { ForNPC = function(id) return "npc:" .. tostring(id) end },
    Factions = {
        GetFactionID = function(rec) return rec.factionID end,
        AreAllied = function(f1, f2) return f1 == f2 end,
    },
    Relationships = {
        AreNPCsEnemies = function(a, b) return a.tacticalClass ~= b.tacticalClass end,
    },
    SecondaryChannel = { RequestBark = function() end },
    PerceptionService = {
        GetProfile = function() return { id = "default", hearingRange = 36, tactical = false } end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
        GetTeamKey = function(rec) return rec.factionID or "survivors" end,
        AreWarningAllies = function(a, b) return a.id ~= b.id end,
        GetActiveSkirmish = function() return nil end,
        PublishAllyThreatWarning = function(caller, target, opts)
            return {
                emitted = true,
                descriptor = {
                    kind = target.kind or "zombie",
                    semanticClass = "zombie",
                    enemyType = "zombie",
                    enemyCount = 1,
                    x = target.x or 14,
                    y = target.y or 10,
                    z = target.z or 0,
                },
                notified = {
                    { record = npcB, canEngage = true },
                },
            }
        end,
        CanAllyEngageThreat = function() return true, { _id = "z-1" } end,
        ResetAllyThreatWarnings = function() end,
    },
    Registry = {
        Data = npcStore,
        Get = function(id) return npcStore[tostring(id)] end,
        GetLiveZombie = function()
            return {
                isFemale = function() return true end,
                getModData = function() return { PNC_UUID = npcA.id } end,
            }
        end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            local out = {}
            for _, rec in pairs(npcStore) do out[#out + 1] = rec end
            return out
        end,
    },
    Network = {
        ClientState = {
            playerContext = { characterUUID = "player-one" },
            playerNameKnowledge = { [npcA.id] = true, [npcB.id] = true },
            snapshots = {
                [npcA.id] = { id = npcA.id, name = "Sammie", identitySeed = 11, isFemale = true },
                [npcB.id] = { id = npcB.id, name = "Adrienne", identitySeed = 22, isFemale = true },
            },
        },
        SendConversationRelationshipForNPC = function(_, npcID, eventType, payload)
            deliveredBarks[#deliveredBarks + 1] = {
                npcID = tostring(npcID),
                eventType = tostring(eventType),
                payload = payload,
                ambientFlavor = payload and payload.ambientFlavor or nil,
            }
            return true
        end,
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
}

T.load("PsychopatzCore", "common", "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Semantics/PsychopatzSemantic.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueState.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueRouter.lua")
T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/SpeechRealization.lua")
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/CombatBanterArbiter.lua")

local Arbiter = PNC.ConvoEngine.CombatBanterArbiter
Arbiter.ResetRuntime()

-- Load domain-neutral transport and DialogueBeats WITHOUT loading CombatTargetCallouts!
local SpeechTransport = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticSpeechTransport.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticBeatContext.lua")
local Beats = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticDialogueBeats.lua")

T.falsy(PNC.Semantics.CombatTargetCallouts,
    "1. DialogueBeats loads cleanly with zero CombatTargetCallouts dependency")

-- 1. Non-combat beats (weather, house alarm, utility, TV, social) via SpeechTransport
Beats.ResetRuntime()
Arbiter.ResetRuntime()

local function assertNonCombatBark(entry, expectedTopic, expectedChannel, label)
    local af = entry.ambientFlavor
    T.truthy(af, label .. " has ambientFlavor")
    T.equal(af.lane, "beat", label .. " uses lane='beat'")
    T.truthy(af.threadID and af.threadID ~= "", label .. " has threadID")
    T.equal(af.sceneID, nil, label .. " has no sceneID")
    T.equal(af.topic, expectedTopic, label .. " topic=" .. expectedTopic)
    T.equal(af.source.channel, expectedChannel, label .. " channel=" .. expectedChannel)
    T.truthy(af.topic ~= "combat", label .. " never stamps topic='combat'")
    T.truthy(af.source.channel ~= "combat", label .. " never stamps channel='combat'")
    T.falsy(string.find(tostring(entry.eventType), "combat_ally_warn", 1, true),
        label .. " has no combat_ally_warn eventID")
end

-- Weather rain beat (open + reply)
local rainOk = Beats.Emit("environment.weather_changed", {
    weather = "rain", previous = "clear", anchor = npcA, partner = npcB,
}, nowMs)
T.truthy(rainOk, "1a. weather_rain emits without CombatTargetCallouts")
T.equal(#deliveredBarks, 1, "1a. weather_rain opening delivered")
assertNonCombatBark(deliveredBarks[1], "weather", "weather", "weather_rain open")
T.equal(deliveredBarks[1].eventType, "world_weather_beat", "1a. weather_rain uses world_weather_beat")

nowMs = nowMs + 1000
Beats.Pump(nowMs)
T.equal(#deliveredBarks, 2, "1a. weather_rain reply delivered on Pump")
assertNonCombatBark(deliveredBarks[2], "weather", "weather", "weather_rain reply")
T.contains(deliveredBarks[2].ambientFlavor.text, "Sammie", "1a. weather_rain reply addresses Sammie")

-- House alarm beat
nowMs = nowMs + 5000
worldSoundHandlers[1](12, 11, 0, 100, 100, { _class = "Alarm" })
T.equal(#deliveredBarks, 3, "1b. house_alarm opening delivered")
assertNonCombatBark(deliveredBarks[3], "world_event", "world", "house_alarm")

-- Utility shutoff beat
nowMs = nowMs + 10000
powerGridOn = false
elecShutDay = 14
PNC.Semantics.BeatContext.GetWorldUtilities(nowMs, true)
Beats.CheckUtilities(nowMs)
T.equal(#deliveredBarks, 4, "1c. utility shutoff beat delivered")
assertNonCombatBark(deliveredBarks[4], "world_event", "world", "power_shutoff")

-- TV beat
nowMs = nowMs + 10000
local tvObj = {
    _class = "IsoTelevision",
    getX = function() return 11 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getDeviceData = function()
        return {
            getIsTelevision = function() return true end,
            getIsTurnedOn = function() return true end,
            canBePoweredHere = function() return true end,
            getChannel = function() return 203 end,
            getMediaData = function() return { getTitleEN = function() return "Woodcraft" end } end,
        }
    end,
}
deviceTextHandlers[1]("guid-tv-1", "show", 11, 10, 0, "Welcome to Woodcraft!", tvObj)
T.equal(#deliveredBarks, 5, "1d. television beat delivered")
assertNonCombatBark(deliveredBarks[5], "skill_show", "world", "television")

-- Direct domain-neutral social delivery with tts=false
nowMs = nowMs + 5000
local socialSent = SpeechTransport.Deliver(npcA, nowMs, {
    eventType = "social_chat_beat",
    eventRef = "social:test:1",
    domain = "social",
    topic = "social",
    channel = "social",
    lane = "beat",
    threadID = "beat:social:1",
    priority = 45,
    tts = false,
    text = "Quiet night out here.",
})
T.equal(socialSent, 1, "1e. direct SpeechTransport.Deliver delivers social beat")
assertNonCombatBark(deliveredBarks[6], "social", "social", "direct social")
T.equal(deliveredBarks[6].ambientFlavor.presentationState.tts, false, "1e. tts=false preserved")
T.equal(#Arbiter.Decisions, 0,
    "1f. non-combat beats never invoke CombatBanterArbiter")

-- 2. CombatTargetCallouts works as a combat adopter of SpeechTransport
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_API.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_Targeting.lua")
local Callouts = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts.lua")

nowMs = nowMs + 10000
local beforeCombat = #deliveredBarks
local okCombat = Callouts.OnTargetChanged({
    target = { kind = "zombie", zombieId = "z-d3-1", x = 14, y = 10, z = 0 },
    at = nowMs,
}, npcA)
T.truthy(okCombat, "2. CombatTargetCallouts emits through SpeechTransport")
T.equal(#deliveredBarks, beforeCombat + 1, "2. combat opening bark delivered")
local combatFlavor = deliveredBarks[#deliveredBarks].ambientFlavor
T.equal(combatFlavor.topic, "combat", "2. combat adopter sets topic='combat'")
T.equal(combatFlavor.source.channel, "combat", "2. combat adopter sets channel='combat'")
T.equal(combatFlavor.lane, "beat", "2. combat callout stays on lane='beat'")
T.truthy(#Arbiter.Decisions > 0, "2. combat adopter invokes CombatBanterArbiter")

nowMs = nowMs + 800
Callouts.PumpPendingReplies(nowMs)
T.equal(#deliveredBarks, beforeCombat + 2, "2. combat ally reply delivers via SpeechTransport")
T.equal(deliveredBarks[#deliveredBarks].ambientFlavor.topic, "combat", "2. combat reply sets topic='combat'")

-- 3. Bounded thread cleanup (death / leave / expiry / cap) in DialogueBeats
Beats.ResetRuntime()
deliveredBarks = {}
nowMs = 200000

-- 3a. Death cleanup
Beats.StartThread({
    threadID = "beat:death:1",
    replies = {
        { speaker = npcB, addressee = npcA, eventType = "world_weather_beat", poolID = "semantic.world.weather.rain", role = "weather_rain_reply", delayMs = 500, ttlMs = 4000 },
    },
}, nowMs)
T.equal(Beats.GetThreadSnapshot().pendingCount, 1, "3a. reply queued before death")
npcB.alive = false
nowMs = nowMs + 600
local firedDead = Beats.Pump(nowMs)
T.equal(firedDead, 0, "3a. dead speaker reply does not fire")
T.equal(Beats.GetThreadSnapshot().pendingCount, 0, "3a. dead speaker turn pruned")
T.equal(Beats.GetThreadSnapshot().activeThreadCount, 0, "3a. dead thread removed")
npcB.alive = true

-- 3b. Leave cleanup (registry removal)
Beats.StartThread({
    threadID = "beat:leave:1",
    replies = {
        { speaker = npcB, addressee = npcA, eventType = "world_weather_beat", poolID = "semantic.world.weather.rain", role = "weather_rain_reply", delayMs = 500, ttlMs = 4000 },
    },
}, nowMs)
npcStore[npcB.id] = nil
nowMs = nowMs + 200 -- even before dueAt!
Beats.Pump(nowMs)
T.equal(Beats.GetThreadSnapshot().pendingCount, 0, "3b. left speaker turn pruned before dueAt")
T.equal(Beats.GetThreadSnapshot().activeThreadCount, 0, "3b. left thread removed")
npcStore[npcB.id] = npcB

-- 3c. Explicit OnActorUnavailable cleanup
Beats.StartThread({
    threadID = "beat:unavail:1",
    replies = {
        { speaker = npcB, addressee = npcA, eventType = "world_weather_beat", poolID = "semantic.world.weather.rain", role = "weather_rain_reply", delayMs = 500, ttlMs = 4000 },
    },
}, nowMs)
local cancelledCount = Beats.OnActorUnavailable(npcA.id)
T.equal(cancelledCount, 1, "3c. OnActorUnavailable cancels thread turn for departed addressee")
T.equal(Beats.GetThreadSnapshot().pendingCount, 0, "3c. pending queue empty after OnActorUnavailable")

-- 3d. Expiry cleanup
Beats.StartThread({
    threadID = "beat:expire:1",
    replies = {
        { speaker = npcB, addressee = npcA, eventType = "world_weather_beat", poolID = "semantic.world.weather.rain", role = "weather_rain_reply", delayMs = 500, ttlMs = 1500 },
    },
}, nowMs)
nowMs = nowMs + 2000
local firedExpired = Beats.Pump(nowMs)
T.equal(firedExpired, 0, "3d. expired reply does not fire")
T.equal(Beats.GetThreadSnapshot().pendingCount, 0, "3d. expired turn pruned")
T.equal(Beats.GetThreadSnapshot().activeThreadCount, 0, "3d. expired thread pruned")

-- 3e. Bounded queue & thread cap (<= 32)
for idx = 1, 40 do
    Beats.StartThread({
        threadID = "beat:cap:" .. tostring(idx),
        replies = {
            { speaker = npcB, addressee = npcA, eventType = "world_weather_beat", poolID = "semantic.world.weather.rain", role = "weather_rain_reply", delayMs = 5000, ttlMs = 10000 },
        },
    }, nowMs)
end
local capSnap = Beats.GetThreadSnapshot()
T.truthy(capSnap.pendingCount <= 32, "3e. pending turns bounded <= 32")
T.truthy(capSnap.activeThreadCount <= 32, "3e. active threads bounded <= 32")
Beats.ResetRuntime()

-- 4. Interactive Scene sceneID priority floor beats ordinary transient barks + VoiceGateway keeps sceneID
isServer = function() return false end
isClient = function() return true end
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local FlavorClient = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
T.load("ProjectHoomans", "client", "PNC/Conversation/PNC_SemanticSpeechPresentation.lua")
local ScenePresentation = T.load("ProjectHoomans", "client", "PNC/Conversation/PNC_SemanticInteractionScenePresentation.lua")

local voicePackets = {}
PsychopatzCore.Bridge = {
    lifecycle = "READY",
    RegisterPacketChannel = function() return true end,
    SetPacketSnapshot = function() return true end,
    PublishPacket = function(_, _, packet)
        voicePackets[#voicePackets + 1] = packet
        return true, #voicePackets
    end,
    RegisterCommand = function() return true end,
}
PsychopatzCore.Audio = { IsPlayerSpeechEnabled = function() return false end }
T.load("PsychopatzCore", "common", "PsychopatzCore/Voice/PsychopatzVoiceGateway.lua")
T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_VoiceGateway.lua")

local publishedMsgs = {}
EventBus.subscribe(Message.EVENT_TYPE, function(msg)
    publishedMsgs[#publishedMsgs + 1] = msg
end, "d3-scene-priority-test")

FlavorClient.Reset()
nowMs = 300000

-- Seed floor with one short bark so subsequent enqueues wait in queue together
T.truthy(PNC.SemanticSpeechPresentation.Receive({
    eventID = "beat:floor:seed",
    eventRef = "beat:floor:seed",
    eventType = "world_weather_beat",
    family = "environment_weather_rain",
    lane = "beat",
    threadID = "beat:seed",
    npcID = npcA.id,
    semanticOwned = true,
    text = "Seed floor line.",
    priority = 30,
    holdMs = 500,
    respectShortHold = true,
    pumpImmediately = true,
    source = { kind = "semantic_speech", channel = "weather", lane = "beat" },
}), "4. seed beat accepted")
T.equal(#publishedMsgs, 1, "4. seed beat occupies floor briefly")

-- Now enqueue an ordinary transient bark (priority 62) AND an interactive Scene turn
nowMs = nowMs + 100
T.truthy(PNC.SemanticSpeechPresentation.Receive({
    eventID = "beat:bark:normal",
    eventRef = "beat:bark:normal",
    eventType = "combat_ally_warn_callout",
    family = "combat_target_acquired",
    lane = "beat",
    threadID = "beat:bark:1",
    npcID = npcB.id,
    semanticOwned = true,
    text = "Ordinary transient bark.",
    priority = 62,
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
    source = { kind = "semantic_speech", channel = "combat", lane = "beat" },
}), "4. transient bark queued")

local okScenePres, scenePresReason = ScenePresentation.Receive({
    kind = "semantic_scene_speech",
    sceneID = "scene:conv:42",
    eventID = "scene:conv:42:turn:1",
    sequence = 1,
    speakerID = npcA.id,
    recipientID = "player-one",
    audienceRole = "recipient",
    observerOnly = false,
    act = "ASK",
    topic = "CAMP",
    text = "Do you want me on watch tonight?",
})
T.truthy(okScenePres, scenePresReason or "4. scene speech accepted")
-- Clear floor so Pump selects by priority from queue (scene=80 > bark=62)
nowMs = nowMs + 10000
FlavorClient.Pump(nowMs)
T.equal(#publishedMsgs, 2, "4. Pump delivers next highest-priority message")
local sceneMsg = publishedMsgs[2]
T.equal(sceneMsg.text, "Do you want me on watch tonight?",
    "4. interactive Scene priority (80) beats ordinary transient bark (62)")
T.equal(sceneMsg.conversationID, "scene:conv:42",
    "4. interactive Scene preserves sceneID as conversationID (not ambient_floor)")
T.equal(sceneMsg.source.lane, "scene", "4. Scene message preserves lane='scene'")
T.equal(sceneMsg.source.sceneID, "scene:conv:42", "4. Scene message preserves source.sceneID")
T.equal(sceneMsg.source.threadID, nil, "4. Scene message does not collide with beat threadID")

-- Verify voice gateway packet preserves conversation_id = sceneID and speech.priority >= 80
local lastVoice = voicePackets[#voicePackets]
T.truthy(lastVoice, "4. VoiceGateway published packet for Scene message")
T.equal(lastVoice.conversation_id, "scene:conv:42",
    "4. VoiceGateway does not collapse sceneID into ambient_floor")
T.truthy(lastVoice.speech and tonumber(lastVoice.speech.priority) >= 80,
    "4. VoiceGateway preserves Scene speech priority >= 80")

-- 5. Beat-to-scene handoff transitions cleanly without threadID/sceneID collision
isServer = function() return true end
isClient = function() return false end
local Providers = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Interaction/Providers.lua")
local SceneRuntime = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Interaction/SceneRuntime.lua")
local SceneTransport = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Interaction/SceneTransport.lua")

Providers.RegisterActorAdapter({
    id = "d3.test.npc_adapter",
    priority = 99,
    CanAdapt = function(actor) return type(actor) == "table" and actor.id ~= nil end,
    ProjectActor = function(actor)
        return {
            id = tostring(actor.id or "player-one"),
            capabilities = { speech = true, emote = true },
            disposition = { sociability = 0.7, empathy = 0.6, confidence = 0.5 },
            condition = { panic = 0 },
            activity = { currentTask = "idle", idle = true },
            traits = {},
        }
    end,
    ProjectRelationship = function() return { familiarity = 2, approval = 5, trust = 3 } end,
    ProjectKnowledge = function() return { available = true, factRefs = {} } end,
})
SceneRuntime.ResetForTests()
Beats.ResetRuntime()
powerGridOn = true
elecShutDay = 30
waterShutDay = 30
deliveredBarks = {}

local handoffThreadID = "world:alarm:handoff:1"
Beats.StartThread({
    threadID = handoffThreadID,
    opening = {
        speaker = npcA, addressee = npcB, eventType = "world_event_beat",
        poolID = "semantic.world.alarm.react", domain = "world", topic = "world_event",
        channel = "world", role = "house_alarm_open",
    },
    replies = {
        {
            speaker = npcB, addressee = npcA, eventType = "world_event_beat",
            poolID = "semantic.world.alarm.react", domain = "world", topic = "world_event",
            channel = "world", role = "house_alarm_reply", delayMs = 900, ttlMs = 6000,
        },
    },
}, nowMs)
T.equal(Beats.GetThreadSnapshot().pendingCount, 1, "5. beat thread has pending reply before handoff")

-- Even if a caller passes id=handoffThreadID, HandoffToScene prevents threadID/sceneID collision
local handedScene, handedSceneID, handoffMeta = Beats.HandoffToScene(handoffThreadID, {
    id = handoffThreadID,
    topic = "ALARM",
    perceived = true,
    playerParticipant = true,
    participants = {
        { id = npcA.id, actor = npcA, kind = "npc" },
        { id = "player-one", actor = playerObj, isPlayer = true, kind = "player" },
    },
})
T.truthy(handedScene, tostring(handedSceneID) or "5. Beats.HandoffToScene opens interactive Scene via SceneRuntime")
T.truthy(handedSceneID ~= handoffThreadID, "5. handoff prevents threadID/sceneID collision")
T.equal(handoffMeta.cancelledTurns, 1, "5. handoff cancels remaining transient beat turns")
T.equal(Beats.GetThreadSnapshot().pendingCount, 0, "5. pending beat queue cleared on handoff")

-- Advancing time past reply delay must NOT fire the cancelled transient beat reply
local countBeforePump = #deliveredBarks
nowMs = nowMs + 2000
Beats.Pump(nowMs)
T.equal(#deliveredBarks, countBeforePump, "5. cancelled beat reply stays silent after handoff")

-- Scene transport packet routes to ScenePresentation without colliding with beat threadID
local sentScenePackets = {}
PNC.Network.SendToPlayer = function(_, command, packet)
    sentScenePackets[#sentScenePackets + 1] = { command = command, packet = packet }
    return true
end
local syntheticResult = {
    semanticHistoryEvent = {
        sequence = 1,
        targetActorID = npcA.id,
        sourceActorID = "player-one",
    },
    interactionPlan = {
        behaviorID = "behavior.d3.handoff_ack",
        dialogueAct = "ASK",
        topic = "ALARM",
        groundedFactRefs = {},
        groundedEventRefs = {},
    },
    presentation = {
        speech = {
            fallback = "We need to sweep the perimeter now.",
            realizationFamily = "alarm",
            phraseID = "alarm.sweep.1",
        },
    },
    continuation = { mode = "wait", targetID = "player-one", expectedResponse = "semantic" },
}
local deliveredSceneCount = SceneTransport.Deliver(handedScene, syntheticResult, {
    { player = playerObj, actorID = "player-one", role = "recipient" },
})
T.equal(deliveredSceneCount, 1, "5. SceneTransport delivers interactive Scene turn")

isServer = function() return false end
isClient = function() return true end
nowMs = nowMs + 10000
local beforeSceneDeliver = #publishedMsgs
local okDeliveredScene = ScenePresentation.Receive(sentScenePackets[1].packet)
T.truthy(okDeliveredScene, "5. ScenePresentation accepts handed-off Scene packet")
T.equal(#publishedMsgs, beforeSceneDeliver + 1, "5. handed-off Scene turn publishes cleanly")
T.equal(publishedMsgs[#publishedMsgs].conversationID, handedSceneID,
    "5. handed-off Scene turn uses sceneID as conversationID")
T.equal(publishedMsgs[#publishedMsgs].source.sceneID, handedSceneID,
    "5. handed-off Scene turn preserves source.sceneID")
T.equal(publishedMsgs[#publishedMsgs].source.threadID, nil,
    "5. handed-off Scene turn has nil threadID")

T.finish("pnc_semantic_speech_transport_boundary_smoke")

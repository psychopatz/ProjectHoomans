-- Repeatable CPU micro-benchmark and end-to-end dialogue/TTS flow verifier.
-- Usage:
--   lua tests/benchmarks/dialogue_and_combat_flow.lua [--baseline]
local T = require "tests/support/test"

local BASELINE_MODE = false
for i = 1, #(arg or {}) do
    if arg[i] == "--baseline" then BASELINE_MODE = true end
end

local PH_ROOT = os.getenv("PZ_TEST_REPOSITORY") or "."
local DT_ROOT = PH_ROOT .. "/../DynamicTrading"

T.addPackagePaths()
package.path = DT_ROOT .. "/Contents/mods/DTCommon/common/media/lua/shared/?.lua;"
    .. DT_ROOT .. "/Contents/mods/DTCommon/42.20/media/lua/shared/?.lua;"
    .. package.path

-- Shared test clock & minimal globals
local nowMs = 10000
local deliveredBarks = {}
local tickHandlers = {}
local subscribedEvents = {}

isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getCurrentSaveName = function() return "bench-save" end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeHours = function() return 100 end,
        getTimeOfDay = function() return 14 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 18 end,
    }
end

Events = {
    OnTick = {
        Add = function(fn) tickHandlers[#tickHandlers + 1] = fn end,
        Remove = function() end,
    },
    OnResetLua = { Add = function() end, Remove = function() end },
}

local playerWorldObj = {
    _x = 12, _y = 10, _z = 0, _alive = true,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isAlive = function(self) return self._alive end,
    getOnlineID = function() return 77 end,
    getUsername = function() return "BenchPlayer" end,
    getDisplayName = function() return "BenchPlayer" end,
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

PNC = PNC or {}
PNC.Const = {
    ZOMBIE_TARGET_RADIUS = 16,
    ALLY_WARNING_RADIUS = 16,
    ATTACK_TYPE_NONE = "none",
    ATTACK_TYPE_AUTO = "auto",
    TACTICAL_CLASS_HOSTILE = "hostile",
    PRESENCE_LIVE = "live",
    ORDER_FOLLOW = "follow",
}
PNC.Core = {
    Now = function() return nowMs end,
    IsAuthority = function() return true end,
    IsClientOnly = function() return false end,
    DistanceSq = function(x1, y1, x2, y2)
        local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
        local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
        return dx * dx + dy * dy
    end,
    ForEachPlayer = function(cb) cb(playerWorldObj) end,
    ResolvePlayerByOnlineID = function(oid)
        return tostring(oid) == "77" and playerWorldObj or nil
    end,
}
PNC.EntityRef = { ForNPC = function(id) return "npc:" .. tostring(id) end }
PNC.Network = {
    SendConversationRelationshipForNPC = function(_, npcId, eventType, payload)
        deliveredBarks[#deliveredBarks + 1] = {
            npcId = tostring(npcId),
            eventType = tostring(eventType),
            ambientFlavor = payload and payload.ambientFlavor or nil,
            at = nowMs,
        }
        return true
    end,
}

local npcStore = {}
local liveBodies = {}
PNC.Registry = {
    Data = npcStore,
    Get = function(id) return npcStore[tostring(id)] end,
    GetLiveZombie = function(id) return liveBodies[tostring(id)] end,
}
PNC.SpatialIndex = {
    QueryNPCs = function()
        local out = {}
        for _, rec in pairs(npcStore) do out[#out + 1] = rec end
        return out
    end,
}
PNC.Factions = {
    GetFactionID = function(rec)
        return rec and (rec.factionID or (rec.affiliation and rec.affiliation.factionID)) or nil
    end,
    AreAllied = function(f1, f2) return f1 == f2 end,
    CanNPCTargetPlayer = function(rec) return rec and rec.tacticalClass == "hostile" or false end,
}
PNC.Relationships = {
    Get = function() return nil end,
    AreNPCsEnemies = function(a, b)
        return a and b and a.tacticalClass ~= b.tacticalClass
    end,
}
PNC.SecondaryChannel = {
    SetAlertLevel = function() end,
    RequestGaze = function() end,
    ApplyGazeToBody = function() end,
    RequestBark = function() end,
}
PNC.PerceptionService = {
    GetProfile = function(rec)
        return { id = rec.tacticalRole or "default", hearingRange = 34, tactical = rec.tactical == true }
    end,
    RecordClue = function() end,
}

-- Load Core + ProjectHoomans ConvoEngine & Combat stack
T.load("PsychopatzCore", "common", "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua")
local Semantic = T.load("PsychopatzCore", "common", "PsychopatzCore/Semantics/PsychopatzSemantic.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueState.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueRouter.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Conversation/PsychopatzConversationMessage.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Conversation/PsychopatzSocialFlavor.lua")
local FlavorClient = T.load("PsychopatzCore", "common_client", "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient.lua")

T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
local Catalog = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
local SpeechRealization = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/SpeechRealization.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_API.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/Visibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatEligibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatMeta.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatSkirmish.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatTargets.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatAlert.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatPublish.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_Targeting.lua")

local zombieWorld = {
    _x = 18, _y = 10, _z = 0, _dead = false,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isDead = function(self) return self._dead end,
    isAlive = function(self) return not self._dead end,
}
PNC.Perception.CanSeeWorldObject = function() return true, "los_clear" end
PNC.Perception.FindZombieByID = function() return zombieWorld end

local Callouts = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts.lua")
local BeatContext = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticBeatContext.lua")
local DialogueBeats = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticDialogueBeats.lua")

local function makeNPC(id, opts)
    opts = opts or {}
    local rec = {
        id = id,
        name = opts.name or ("NPC_" .. tostring(id)),
        x = opts.x or 10, y = opts.y or 10, z = opts.z or 0,
        alive = true, presenceState = "live",
        factionID = opts.factionID or "survivors",
        attackType = opts.attackType or "auto",
        tactical = opts.tactical == true,
        social = opts.social or { relationships = {} },
        conditionStats = opts.conditionStats or {},
        runtime = opts.runtime or {},
    }
    npcStore[tostring(id)] = rec
    liveBodies[tostring(id)] = {
        getX = function() return rec.x end,
        getY = function() return rec.y end,
        getZ = function() return rec.z end,
        isDead = function() return false end,
        isAlive = function() return true end,
        getForwardDirection = function()
            return { getX = function() return 1 end, getY = function() return 0 end }
        end,
    }
    return rec
end

local function bench(label, count, fn)
    local t0 = os.clock()
    local peak = 0
    for i = 1, count do
        local s0 = os.clock()
        fn(i)
        local dt = (os.clock() - s0) * 1000
        if dt > peak then peak = dt end
    end
    local total = (os.clock() - t0) * 1000
    local avg = total / count
    local ops = total > 0 and (count / (total / 1000)) or 0
    print(string.format(
        "BENCH | %-34s | n=%4d | total=%7.2fms | avg=%.4fms | peak=%.4fms | ops/s=%8.0f",
        label, count, total, avg, peak, ops
    ))
    return total, avg, peak
end

print("=== 1. CPU MICRO-BENCHMARKS (C Lua 5.x; multiply ~10-30x for PZ Kahlua2) ===")
local npcOne = makeNPC("b-1", { name = "Sammie", x = 10, y = 10, tactical = true })
local npcTwo = makeNPC("b-2", { name = "Adrienne", x = 11, y = 10 })
local npcThree = makeNPC("b-3", { name = "Pete", x = 12, y = 10 })
local sampleCtx = {
    npcID = "b-1", semanticThreatClass = "zombie",
    combatReactionStyle = "tactical", combatReactionRole = "lead", inCombat = true,
}
local sampleResp = {
    selectionID = "combat.ally_warn.callout.zombie_tactical",
    templateID = "combat.ally_warn.callout.zombie_tactical",
    fallback = "Eyes up!",
    plan = { schemaVersion = 1, kind = "dialogue_act_plan", dialogueAct = "WARN", turns = {} },
}
local sampleTokens = Callouts.BuildRichSpeechTokens(npcOne, npcTwo, {
    semanticClass = "zombie", enemyType = "zombie", enemyCount = 3, x = 18, y = 10, z = 0,
}, nowMs, "tactical")

bench("Catalog.Select (callout+reply)", 1000, function(i)
    if i % 2 == 1 then
        assert(Catalog.Select("semantic.combat.ally_warn.callout.zombie", sampleCtx, i))
    else
        assert(Catalog.Select("semantic.combat.ally_warn.reply.engaging", sampleCtx, i))
    end
end)

bench("SpeechRealization.Apply (bark)", 1000, function(i)
    SpeechRealization.Apply(sampleResp, { npcID = "b-1", phraseSalt = i })
end)

bench("ResolveSemanticLine", 500, function(i)
    Callouts.ResolveSemanticLine(npcOne, "combat_ally_warn_callout", "WARN", "zombie", "b:" .. i, nil, sampleTokens)
end)

bench("OnTargetChanged (fresh skirmishes)", 200, function(i)
    if i % 3 == 1 then
        PNC.Perception.ResetAllyThreatWarnings()
        Callouts.ResetRuntime()
    end
    Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-" .. i, x = 18, y = 10, z = 0 },
        at = nowMs + i * 20,
    }, npcOne)
end)

PNC.Perception.ResetAllyThreatWarnings()
Callouts.ResetRuntime()
Callouts.OnTargetChanged({ target = { kind = "zombie", zombieId = "z-101", x = 18, y = 10, z = 0 }, at = nowMs }, npcOne)
bench("OnTargetChanged (same skirmish)", 500, function(i)
    Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-101", x = 18, y = 10, z = 0 },
        at = nowMs + i * 20,
    }, npcOne)
end)

BeatContext.Build(npcOne, npcTwo, { now = nowMs })
bench("BeatContext.Build (cached)", 1000, function(i)
    BeatContext.Build(npcOne, npcTwo, { now = nowMs + 10 })
end)

bench("DialogueBeats.Pump (idle)", 2000, function(i)
    DialogueBeats.Pump(nowMs + i)
end)

-- ============================================================================
-- 2. FLOW INVARIANTS CHECKER
-- ============================================================================
local flowFailures = {}
local function check(cond, msg)
    if not cond then
        flowFailures[#flowFailures + 1] = msg
        print("FLOW FAIL | " .. tostring(msg))
    else
        print("FLOW PASS | " .. tostring(msg))
    end
end

print("\n=== 2A. 6-NPC COMBAT + FAREWELL FLOOR & PBRAINZ TTS SERIALIZATION ===")
local publishedEvents = {}
local activeSpeakersNow = 0
local maxConcurrent = 0
local EventBus = PsychopatzCore.Events
local Message = PsychopatzCore.Conversation.Message

EventBus.subscribe(Message.EVENT_TYPE, function(msg)
    publishedEvents[#publishedEvents + 1] = {
        at = nowMs,
        speakerID = msg.speakerID,
        conversationID = msg.conversationID,
        messageID = msg.messageID,
        text = msg.text,
    }
end, "bench-observer")

local function runSerializationSim(bridgeReady)
    publishedEvents = {}
    FlavorClient.Reset()
    FlavorClient.SetLLMProvider(nil)
    PsychopatzCore.VoiceGateway = PsychopatzCore.VoiceGateway or {
        LIFECYCLE_EVENT_TYPE = "PsychopatzCore.Voice.Lifecycle",
    }
    PsychopatzCore.VoiceGateway.IsBridgeReady = function() return bridgeReady end

    local base = 500000
    nowMs = base
    local inputs = {
        { id = "f1", speaker = "sammie", text = "Watch out, walkers coming in from the street!", priority = 62, thread = "t1" },
        { id = "f2", speaker = "adrienne", text = "On your left, moving to intercept.", priority = 62, thread = "t1" },
        { id = "f3", speaker = "pete", text = "I see them too, covering the flank.", priority = 62, thread = "t1" },
        { id = "f4", speaker = "vonda", text = "Watch your step!", priority = 62, thread = "t1" },
        { id = "f5", speaker = "clay", text = "Stay sharp, there are more behind them.", priority = 62, thread = "t1" },
        { id = "f6", speaker = "faustino", text = "Take care, stay safe out there.", priority = 72, family = "conversation_farewell" },
    }
    -- Enqueue f1..f5 first so f1 claims the floor, then enqueue higher-priority non-interrupt f6 mid-turn at +150ms.
    for i = 1, 5 do
        local inp = inputs[i]
        FlavorClient.Enqueue({
            eventID = inp.id, speakerID = inp.speaker,
            family = inp.family or "combat_ally_warn_reply", priority = inp.priority,
            text = inp.text, threadID = inp.thread, ttlMs = 30000,
            cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
        })
    end

    local nextVoiceFinishAt = nil
    local activeMsgId = nil
    local f6Enqueued = false
    for step = 0, 700 do
        nowMs = base + step * 50
        if not f6Enqueued and nowMs >= base + 150 then
            f6Enqueued = true
            local f6 = inputs[6]
            FlavorClient.Enqueue({
                eventID = f6.id, speakerID = f6.speaker, family = f6.family, priority = f6.priority,
                text = f6.text, ttlMs = 30000,
                cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
            })
        end
        nowMs = base + step * 50
        if bridgeReady and nextVoiceFinishAt and nowMs >= nextVoiceFinishAt then
            EventBus.emit("PsychopatzCore.Voice.Lifecycle", {
                event = "speechFinished",
                utterance_id = activeMsgId,
                message_id = activeMsgId,
            })
            nextVoiceFinishAt = nil
            activeMsgId = nil
        end
        local beforeCount = #publishedEvents
        FlavorClient.Pump(nowMs)
        if bridgeReady and #publishedEvents > beforeCount then
            local newest = publishedEvents[#publishedEvents]
            activeMsgId = newest.messageID
            nextVoiceFinishAt = nowMs + 1950
        end
    end

    local uniqueConvIDs = {}
    local minGap = 999999
    local sameTickOverlap = 0
    for idx = 1, #publishedEvents do
        uniqueConvIDs[tostring(publishedEvents[idx].conversationID)] = true
        if idx > 1 then
            local gap = publishedEvents[idx].at - publishedEvents[idx - 1].at
            if gap < minGap then minGap = gap end
            if gap == 0 then sameTickOverlap = sameTickOverlap + 1 end
        end
    end
    local convCount = 0
    for _ in pairs(uniqueConvIDs) do convCount = convCount + 1 end
    return publishedEvents, convCount, minGap, sameTickOverlap
end

local evOff, convOff, gapOff, overlapOff = runSerializationSim(false)
check(#evOff == 6, "TTS-off 6-NPC floor delivered all 6 turns serially (count=" .. #evOff .. ")")
check(overlapOff == 0 and gapOff >= 1800, "TTS-off zero overlap and readable gap (gap=" .. tostring(gapOff) .. "ms, overlap=" .. tostring(overlapOff) .. ")")
check(convOff == 1, "TTS-off shared single ambient conversationID (convIDs=" .. tostring(convOff) .. ")")

local evOn, convOn, gapOn, overlapOn = runSerializationSim(true)
check(#evOn == 6, "TTS-on 6-NPC floor delivered all 6 turns serially (count=" .. #evOn .. ")")
check(overlapOn == 0 and gapOn >= 1950 and gapOn <= 2600, "TTS-on driven by speechFinished lifecycle (gap=" .. tostring(gapOn) .. "ms)")
check(convOn == 1, "TTS-on shared single ambient conversationID (convIDs=" .. tostring(convOn) .. ")")

do
    publishedEvents = {}
    FlavorClient.Reset()
    PsychopatzCore.VoiceGateway.IsBridgeReady = function() return false end
    local eBase = 700000
    nowMs = eBase
    FlavorClient.Enqueue({
        eventID = "norm-1", speakerID = "sammie", family = "combat_ally_warn_reply",
        priority = 62, text = "Eyes up ahead.", ttlMs = 9000,
        cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
    })
    FlavorClient.Pump(nowMs)
    nowMs = eBase + 150
    FlavorClient.Enqueue({
        eventID = "emer-1", speakerID = "adrienne", family = "combat_blindside",
        priority = 80, interrupt = true, text = "Behind you, watch out!", ttlMs = 9000,
        cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
    })
    FlavorClient.Pump(nowMs)
    check(#publishedEvents == 2 and publishedEvents[2].at == eBase + 150,
        "emergency interrupt=true preempts ambient floor immediately (count=" .. #publishedEvents .. ")")
end

print("\n=== 2B. CROSS-MOD HELLO + HEADLESS + SEMANTIC FAREWELL ===")
PNC.Translation = PNC.Translation or { GetKey = function(_, fb) return fb end }
package.loaded["PNC/ConvoEngine/Registry"] = nil
package.preload["PsychopatzCore/Semantics/PsychopatzSemantic"] = function() return Semantic end
DTCommon = { GeneratedSemanticRegistry = require "DTCommon/ConvoEngine/Registry" }
require "DTCommon/DTCommon_SemanticPack"
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ContextState.lua")
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCatalog.lua")
local Policy = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/Policy.lua")
local Suggestions = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/Suggestions.lua")

local router = PsychopatzCore.ConvoEngine.DialogueRouter.New({
    state = PsychopatzCore.ConvoEngine.DialogueState.New({ npcID = "sammie-1" }),
    policy = Policy,
})

local helloResult = router:Process("hello", {
    npcID = "sammie-1",
    capabilities = {},
    socialRole = "colonist",
    npcType = "colonist",
    relationshipState = "Acquaintance",
    dialogueSituation = { npc = { id = "sammie-1" } },
})
local helloText = helloResult and helloResult.decision and helloResult.decision.response and helloResult.decision.response.fallback or ""
local helloRealized = helloResult and helloResult.decision and helloResult.decision.response
    and SpeechRealization.Apply(helloResult.decision.response, {
        npcID = "sammie-1",
        relationshipState = "Acquaintance",
        socialRole = "colonist",
    }) or nil
local finalHelloText = (helloRealized and helloRealized.fallback) or helloText
check(helloResult and helloResult.decision and helloResult.decision.branch == "GREET_ACKNOWLEDGED",
    "cross-mod hello resolves GREET_ACKNOWLEDGED (got=" .. tostring(helloResult and helloResult.decision and helloResult.decision.branch) .. ")")
check(not string.find(finalHelloText, "%s", 1, true) and not string.find(finalHelloText, "%1", 1, true),
    "hello reply contains no raw %s/%1 placeholder (text=" .. tostring(finalHelloText) .. ")")

-- Explicitly test missing familyAddress on bond-styled acknowledgement never leaks %s.
local bondNoAddr = SpeechRealization.Apply({
    selectionID = "social.acknowledged",
    templateID = "social.acknowledged",
    fallback = "All right. I hear you.",
}, {
    npcID = "sammie-1",
    speechStyle = {
        variant = "warm",
        bond = { class = "family", kind = "sister", term = {} },
    },
    phraseSalt = "bond-noaddr",
})
local bondText = bondNoAddr and bondNoAddr.fallback or ""
check(not string.find(bondText, "%s", 1, true) and not string.find(bondText, "%1", 1, true),
    "bond realization without familyAddress never leaks %s (text=" .. tostring(bondText) .. ")")

local sugg = Suggestions.Project and Suggestions.Project({
    decision = helloResult and helloResult.decision,
    ir = helloResult and helloResult.ir,
    semanticDialogueState = router.state,
    conversationID = "conv-bench",
    npcID = "sammie-1",
    capabilities = {},
    actorConversationContext = { npcID = "sammie-1", capabilities = {} },
})
local badAccept = false
for _, c in ipairs(sugg and sugg.choices or {}) do
    local lbl = tostring(c.label or (c.display and c.display.labelFallback) or "")
    if lbl == "Yes, I accept." then badAccept = true end
end
check(not badAccept, "hello suggestions do not show fallback accept/refuse loop")

local byeResult = router:Process("goodbye", {
    npcID = "sammie-1",
    capabilities = {},
    socialRole = "hostile",
    tacticalClass = "hostile",
    playerHostile = true,
    relationshipState = "Hostile",
})
check(byeResult and byeResult.decision and byeResult.decision.branch == "FAREWELL_ACKNOWLEDGED",
    "goodbye resolves FAREWELL_ACKNOWLEDGED (got=" .. tostring(byeResult and byeResult.decision and byeResult.decision.branch) .. ")")
check(byeResult and byeResult.decision and byeResult.decision.closeConversation == true,
    "goodbye marks decision.closeConversation == true")
local byeFallback = byeResult and byeResult.decision and byeResult.decision.response and byeResult.decision.response.fallback or ""
check(byeFallback ~= "" and not string.find(byeFallback, "Take care", 1, true) and not string.find(byeFallback, "%s", 1, true),
    "hostile goodbye produces hostile non-template reply (text=" .. tostring(byeFallback) .. ")")

local roles = { "hostile", "wary", "neutral", "colonist", "friend", "family", "lover" }
local seenFarewellTexts = {}
local distinctRoleTexts = 0
for _, r in ipairs(roles) do
    local sel = Catalog.Select("semantic.flow.farewell", { socialRole = r, farewellSpeaker = "npc", npcID = "npc-" .. r }, 1)
    local ap = sel and SpeechRealization.Apply({
        selectionID = sel.id, templateID = sel.templateID, fallback = sel.fallback,
    }, { npcID = "npc-" .. r, socialRole = r, phraseSalt = "bench:" .. r }) or nil
    local txt = ap and ap.fallback or (sel and sel.fallback) or ""
    if not seenFarewellTexts[txt] then distinctRoleTexts = distinctRoleTexts + 1 end
    seenFarewellTexts[txt] = true
    check(txt ~= "" and not string.find(txt, "%s", 1, true) and not string.find(txt, " - ", 1, true),
        "role '" .. r .. "' farewell resolves cleanly without %s or dash (text=" .. tostring(txt) .. ")")
end
check(distinctRoleTexts == #roles,
    "all 7 relationship farewell roles produce distinct tone lines (distinct=" .. distinctRoleTexts .. ")")

if #flowFailures > 0 then
    print(string.format("\nSUMMARY: %d flow failures (BASELINE_MODE=%s)", #flowFailures, tostring(BASELINE_MODE)))
    if not BASELINE_MODE then os.exit(1) end
else
    print("\nSUMMARY: ALL BENCHMARK & FLOW CHECKS PASSED")
end

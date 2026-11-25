local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 50000
local worldSoundHandlers = {}
local ambientSoundHandlers = {}
local elecChangedHandlers = {}
local deviceTextHandlers = {}
local delivered = {}
local heliActive = false
local heliAction = nil
local queriedNPCs = {}

isClient = function() return false end
isServer = function() return true end
getTimestampMs = function() return nowMs end
getTimeInMillis = function() return nowMs end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 4.5 end,
        getWorldAgeHours = function() return 4.5 * 24 end,
        getTimeOfDay = function() return 14 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 20 end,
    }
end
getSandboxOptions = function()
    return {
        doesPowerGridExist = function() return true end,
        getElecShutModifier = function() return 14 end,
        getWaterShutModifier = function() return 14 end,
    }
end
getWorld = function()
    return {
        isHydroPowerOn = function() return true end,
        getHelicopter = function()
            return { isActive = function() return heliActive end }
        end,
    }
end
instanceof = function() return false end
typeof = function(obj)
    return type(obj) == "table" and obj._javaSimpleName or type(obj)
end
getClassSimpleName = function(obj)
    return type(obj) == "table" and obj._javaSimpleName or nil
end

Events = {
    OnWorldSound = { Add = function(fn) worldSoundHandlers[#worldSoundHandlers + 1] = fn end },
    OnAmbientSound = { Add = function(fn) ambientSoundHandlers[#ambientSoundHandlers + 1] = fn end },
    OnElectricityChanged = { Add = function(fn) elecChangedHandlers[#elecChangedHandlers + 1] = fn end },
    OnDeviceText = { Add = function(fn) deviceTextHandlers[#deviceTextHandlers + 1] = fn end },
    OnTick = { Add = function() end },
    OnResetLua = { Add = function() end },
}

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
    VanillaEventObserver = {
        GetHelicopterState = function() return { active = heliActive } end,
    },
}

local playerObj = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 1 end,
    getUsername = function() return "Pat" end,
    getDisplayName = function() return "Pat" end,
    getDescriptor = function() return { getForename = function() return "Pat" end } end,
}

local npcMap = {}
local function makeNPC(id, name, team, x, y, orderKind)
    local rec = {
        id = id,
        name = name,
        team = team,
        factionID = team,
        alive = true,
        presenceState = "live",
        x = x,
        y = y,
        z = 0,
        orderSpec = orderKind and { kind = orderKind } or nil,
        runtime = {},
    }
    npcMap[id] = rec
    return rec
end

local g1a = makeNPC("g1_a", "Alex", "team:1", 101, 100, "camp")
local g1b = makeNPC("g1_b", "Sam", "team:1", 102, 100, "camp")
local g1c = makeNPC("g1_c", "Morgan", "team:1", 103, 100, "camp")
local g2a = makeNPC("g2_a", "Riley", "team:2", 105, 100, nil)
local g2b = makeNPC("g2_b", "Casey", "team:2", 106, 100, nil)
queriedNPCs = { g1a, g1b, g1c, g2a, g2b }

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return nowMs end,
        NowWorldAgeHours = function() return 108 end,
        ForEachPlayer = function(cb) cb(playerObj) end,
        LogInfo = function() end,
    },
    Registry = {
        Get = function(id) return npcMap[tostring(id)] end,
    },
    SpatialIndex = {
        QueryNPCs = function() return queriedNPCs end,
    },
    Perception = {
        GetTeamKey = function(rec) return rec and rec.team or nil end,
        AreWarningAllies = function(a, b) return a.team == b.team end,
        GetActiveSkirmish = function() return nil end,
        CanSeeWorldObject = function() return true end,
    },
    WorldKnowledge = {
        ObserveHelicopterEpisode = function()
            if not heliAction then return nil end
            local act = heliAction
            heliAction = nil
            return { action = act, x = 100, y = 100, factID = "fact:heli:1" }
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcId, reason, ctx)
            local af = ctx and ctx.ambientFlavor or {}
            delivered[#delivered + 1] = {
                npcId = npcId,
                reason = reason,
                poolID = af.poolID,
                topic = af.topic,
                role = af.context and af.context.beatRole or nil,
                text = af.text,
            }
            return true
        end,
    },
    ConvoEngine = {
        SocialReactions = {
            Resolve = function(spec)
                return {
                    realizationID = tostring(spec.poolID) .. ":" .. tostring(spec.context and spec.context.beatRole or "x"),
                    fallback = "[" .. tostring(spec.poolID) .. "|" .. tostring(spec.context and spec.context.topic or "") .. "|" .. tostring(spec.context and spec.context.beatRole or "") .. "]",
                    presentationClass = "BARK",
                    poolID = spec.poolID,
                }
            end,
        },
        TokenFormatter = {
            FirstTokenName = function(s) return tostring(s or "friend") end,
            CleanName = function(s) return tostring(s or "") end,
            CleanLocation = function(s) return tostring(s or "") end,
            Format = function(text) return text end,
        },
        Lexicon = {
            Expand = function(raw) return raw end,
        },
    },
}

local Beats = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticDialogueBeats.lua")

-- 1. House alarm start fires across BOTH groups (3 speakers in G1, 2 in G2 staggered).
worldSoundHandlers[1](104, 100, 0, 600, 600, { _javaSimpleName = "Alarm" })
for step = 1, 9 do
    nowMs = nowMs + 900
    Beats.Pump(nowMs)
end
local alarmOpenCount, alarmChimeCount, g2Reacted = 0, 0, false
for i = 1, #delivered do
    local d = delivered[i]
    if d.poolID == "semantic.world.alarm.react" then
        if string.find(d.text, "house_alarm_open", 1, true) then alarmOpenCount = alarmOpenCount + 1 end
        if string.find(d.text, "house_alarm_chime", 1, true) then alarmChimeCount = alarmChimeCount + 1 end
        if d.npcId == "g2_a" then g2Reacted = true end
    end
end
T.equal(alarmOpenCount, 2, "Both nearby groups should open on house alarm")
T.equal(alarmChimeCount, 1, "3-member group should include a 3rd-speaker chime")
T.truthy(g2Reacted, "Second group must also react to house alarm")

-- 2. House alarm ended fires after silence (>7s without pulses).
delivered = {}
nowMs = nowMs + 12000
Beats.CheckHouseAlarmEnded(nowMs)
for step = 1, 14 do
    nowMs = nowMs + 900
    Beats.Pump(nowMs)
end
local endedOpen = 0
for i = 1, #delivered do
    if string.find(delivered[i].text, "house_alarm_ended_open", 1, true) then
        endedOpen = endedOpen + 1
    end
end
T.equal(endedOpen, 2, "Both nearby groups should react when house alarm finishes")

-- 3. Helicopter start + ended lifecycle beats.
delivered = {}
heliActive = true
heliAction = "started"
nowMs = nowMs + 15000
Beats.CheckEnvironment(nowMs)
for step = 1, 14 do
    nowMs = nowMs + 900
    Beats.Pump(nowMs)
end
local heliStartCount = 0
for i = 1, #delivered do
    if string.find(delivered[i].text, "chopper_start_open", 1, true) then
        heliStartCount = heliStartCount + 1
    end
end
T.equal(heliStartCount, 2, "Both groups should react to helicopter start")

delivered = {}
heliActive = false
heliAction = "ended"
nowMs = nowMs + 15000
Beats.CheckEnvironment(nowMs)
for step = 1, 14 do
    nowMs = nowMs + 900
    Beats.Pump(nowMs)
end
local heliEndCount = 0
for i = 1, #delivered do
    if string.find(delivered[i].text, "chopper_ended_open", 1, true) then
        heliEndCount = heliEndCount + 1
    end
end
T.equal(heliEndCount, 2, "Both groups should react when helicopter ends")

-- 4. Multi-NPC coherent 4-turn group banter (camp_life -> open, reply, chime, wrap).
delivered = {}
nowMs = nowMs + 60000
Beats.ResetGroupBanterRuntime()
if PNC.Semantics.ConversationDirector then PNC.Semantics.ConversationDirector.ResetRuntime() end
Beats.NextEnvCheckAt = nowMs + 10000
Beats.Pump(nowMs)
local banterOk = Beats.CheckGroupBanter(nowMs)
T.truthy(banterOk, "CheckGroupBanter should start a multi-NPC banter thread")
for step = 1, 14 do
    nowMs = nowMs + 900
    Beats.Pump(nowMs)
end
local banterRoles = {}
for i = 1, #delivered do
    if delivered[i].poolID == "semantic.banter.group" then
        banterRoles[#banterRoles + 1] = delivered[i].text
    end
end
T.equal(#banterRoles, 4, "3-member group banter should deliver 4 coherent turns (open, reply, chime, wrap)")
T.contains(banterRoles[1], "camp_life|open", "Turn 1 should open camp_life banter")
T.contains(banterRoles[2], "camp_life|reply", "Turn 2 should reply")
T.contains(banterRoles[3], "camp_life|chime", "Turn 3 should chime in")
T.contains(banterRoles[4], "camp_life|wrap", "Turn 4 should wrap up")

-- 5. Verify IsHelicopterShelterActive helper in MobileGroupDirector_Ambient_Objective.
PNC.MobileGroupDirectorInternal = {
    Internal = {
        AmbientTargets = {
            finite = function(v, fb) return tonumber(v) or fb end,
        },
        memberRecords = function() return {} end,
        updateMobile = function(f) return f end,
    },
}
PNC.FactionConstants = {
    MOBILE_AMBIENT_DAY = "day",
    MOBILE_AMBIENT_NIGHT = "night",
    MOBILE_AMBIENT_DAY_START_HOUR = 6,
    MOBILE_AMBIENT_NIGHT_START_HOUR = 20,
}
PNC.Factions = {}
PNC.DirectorConfig = {}
local AmbObj = T.load("ProjectHoomans", "server", "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Objective.lua")
heliActive = false
T.equal(AmbObj.IsHelicopterShelterActive({}), false, "Helicopter shelter false when chopper inactive")
heliActive = true
T.equal(AmbObj.IsHelicopterShelterActive({}), true, "Helicopter shelter true when chopper active")

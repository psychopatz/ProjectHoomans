local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 30000
local logs = {}
local worldSoundHandlers = {}
local ambientSoundHandlers = {}
local elecChangedHandlers = {}
local deviceTextHandlers = {}
local delivered = {}
local registeredSettings = {}
local enabledSettings = {}
local canSeePlayer = true
local queriedNPCs = {}
local lastResolvedContext = nil
local isRainingNow = false
local rainIntensityNow = 0

isClient = function() return false end
isServer = function() return true end
getTimestampMs = function() return nowMs end
getTimeInMillis = function() return nowMs end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 5.5 end,
        getWorldAgeHours = function() return 5.5 * 24 end,
        getTimeOfDay = function() return 14 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return isRainingNow end,
        getRainIntensity = function() return rainIntensityNow end,
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
    }
end
-- Simulate real PZ Build 42 Single Player: zombie.iso.Alarm is NOT in
-- LuaManager.exposer.typeMap, so instanceof(source, "Alarm") returns false,
-- while typeof(source) / getClassSimpleName(source) return "Alarm".
instanceof = function() return false end
typeof = function(obj)
    if type(obj) == "table" and obj._javaSimpleName then
        return obj._javaSimpleName
    end
    return type(obj)
end
getClassSimpleName = function(obj)
    if type(obj) == "table" and obj._javaSimpleName then
        return obj._javaSimpleName
    end
    return nil
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
    DebugSettings = {
        Register = function(spec)
            registeredSettings[spec.id] = spec
            enabledSettings[spec.id] = spec.defaultEnabled == true
        end,
        IsEnabled = function(id)
            return enabledSettings[id] == true
        end,
        Set = function(id, value)
            enabledSettings[id] = value == true
            local spec = registeredSettings[id]
            if spec and type(spec.apply) == "function" then
                spec.apply(enabledSettings[id])
            end
        end,
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

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(cb) cb(playerObj) end,
        LogInfo = function(msg) logs[#logs + 1] = tostring(msg) end,
    },
    SpatialIndex = {
        QueryNPCs = function() return queriedNPCs end,
    },
    Perception = {
        GetTeamKey = function() return "team:1" end,
        AreWarningAllies = function() return true end,
        GetActiveSkirmish = function() return nil end,
        CanSeeWorldObject = function() return canSeePlayer end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcId, reason, ctx)
            delivered[#delivered + 1] = { npcId = npcId, reason = reason, text = ctx and ctx.ambientFlavor and ctx.ambientFlavor.text }
            return true
        end,
    },
    ConvoEngine = {
        SocialReactions = {
            Resolve = function(spec)
                lastResolvedContext = spec.context
                return {
                    realizationID = "test.alarm",
                    fallback = "Alarm going off!",
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

T.load("ProjectHoomans", "shared", "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_AuditChannels.lua")
local Beats = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticDialogueBeats.lua")

-- 1. Setting registration defaults to disabled and emits zero audit logs when off.
local setting = registeredSettings["ProjectHoomans.BeatsAudit"]
T.truthy(setting, "ProjectHoomans.BeatsAudit should be registered")
T.equal(setting.defaultEnabled, false, "BeatsAudit must default to false")
T.equal(setting.runtimeMutable, true, "BeatsAudit must be runtimeMutable")
T.equal(PNC.PerformanceScalingDiagnostics.IsBeatsAuditEnabled(), false, "BeatsAudit starts disabled")

local alarmUserdata = { _javaSimpleName = "Alarm" }
local npcA = { id = "npc_1", name = "Alex", alive = true, presenceState = "live", x = 102, y = 100, z = 0, runtime = {} }

-- 2. When no calm speaker is near on first pulse, retry cooldown applies (NOT 65s lockout).
queriedNPCs = {}
T.equal(#worldSoundHandlers, 1, "HouseAlarm must hook OnWorldSound")
worldSoundHandlers[1](105, 100, 0, 600, 600, alarmUserdata)
T.equal(#delivered, 0, "No speaker in range means no delivery yet")
T.equal(#logs, 0, "Disabled BeatsAudit must emit zero logs")

-- 3. Enable BeatsAudit -> immediately dumps snapshot + possible_beats + env_state + alarm_state.
PsychopatzCore.DebugSettings.Set("ProjectHoomans.BeatsAudit", true)
T.equal(PNC.PerformanceScalingDiagnostics.IsBeatsAuditEnabled(), true, "BeatsAudit enabled")
local joined = table.concat(logs, "\n")
T.contains(joined, "beats_audit event=snapshot", "snapshot logged on enable")
T.contains(joined, "beats_audit event=possible_beats", "possible_beats logged on enable")
T.contains(joined, "environment.house_alarm", "house alarm hook listed in possible_beats")
T.contains(joined, "beats_audit event=env_state", "env_state logged on enable")
T.contains(joined, "beats_audit event=alarm_state", "alarm_state logged on enable")
T.contains(joined, "beats_audit event=world_object_state", "world_object_state logged on enable")

-- 4. After 3.5s, NPC enters range; SP unexposed Alarm userdata triggers beat via typeof()!
logs = {}
nowMs = nowMs + 3500
queriedNPCs = { npcA }
canSeePlayer = true
worldSoundHandlers[1](105, 100, 0, 600, 600, alarmUserdata)
T.equal(#delivered, 1, "SP Alarm detected via typeof() after retry window should deliver beat")
joined = table.concat(logs, "\n")
T.contains(joined, "beats_audit event=house_alarm_world_sound", "world sound logged")
T.contains(joined, "sourceType=Alarm isAlarm=true", "sourceType=Alarm isAlarm=true logged")
T.contains(joined, "beats_audit event=speaker_search", "speaker_search logged")
T.contains(joined, "beats_audit event=emit_selected", "emit_selected logged")
T.contains(joined, "beats_audit event=turn_delivered", "turn_delivered logged")

-- 5. Verify transport_drop logs exact CanHear failure details (canSee=false).
logs = {}
Beats.ResetRuntime()
nowMs = nowMs + 70000
canSeePlayer = false
worldSoundHandlers[1](105, 100, 0, 600, 600, alarmUserdata)
T.equal(#delivered, 1, "No delivery when CanSeeWorldObject is false")
joined = table.concat(logs, "\n")
T.contains(joined, "beats_audit event=transport_drop", "transport_drop logged")
T.contains(joined, "reason=can_hear_false", "can_hear_false reason logged")
T.contains(joined, "canSee=false", "canSee=false logged")

-- 6. Meta ambient gunshot (200 tiles away) triggers ambient.world_event.react
--    and populates context.topic = "meta_gunshot" for ConvoDSL variant matching.
canSeePlayer = true
nowMs = nowMs + 60000
lastResolvedContext = nil
local beforeCount = #delivered
for i = 1, #ambientSoundHandlers do
    ambientSoundHandlers[i]("MetaAssaultRifle1", 300, 100)
end
T.equal(#delivered, beforeCount + 1, "Meta gunshot 200 tiles away should trigger beat for nearby calm NPC")
T.equal(lastResolvedContext and lastResolvedContext.topic, "meta_gunshot", "ResolveLine must populate context.topic")

-- 7. Rain transition triggers for a SOLO calm NPC (no longer requires a pair).
nowMs = nowMs + 60000
isRainingNow = false
rainIntensityNow = 0
Beats.CheckEnvironment(nowMs)
nowMs = nowMs + 15000
isRainingNow = true
rainIntensityNow = 0.6
beforeCount = #delivered
Beats.CheckEnvironment(nowMs)
T.equal(#delivered, beforeCount + 1, "Solo calm NPC should react when rain starts")

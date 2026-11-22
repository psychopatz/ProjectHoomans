local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})
package.path = "../psychopatzCore/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;" .. package.path

local mockPowerOn = true
local mockWorldDays = 10
local mockWaterShutDay = 14
local nowMs = 10000
local deliveredBeats = {}
local hookHandlers = {
    OnElectricityChanged = {},
    OnGameStart = {},
    EveryHours = {},
}

isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end

getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return mockWorldDays end,
        getWorldAgeHours = function() return mockWorldDays * 24 end,
    }
end

getSandboxOptions = function()
    return {
        doesPowerGridExist = function() return mockPowerOn end,
        getElecShutModifier = function() return 12 end,
        getWaterShutModifier = function() return mockWaterShutDay end,
    }
end

getWorld = function()
    return {
        isHydroPowerOn = function() return mockPowerOn end,
    }
end

Events = {
    OnElectricityChanged = {
        Add = function(fn) hookHandlers.OnElectricityChanged[#hookHandlers.OnElectricityChanged + 1] = fn end,
    },
    OnGameStart = {
        Add = function(fn) hookHandlers.OnGameStart[#hookHandlers.OnGameStart + 1] = fn end,
    },
    EveryHours = {
        Add = function(fn) hookHandlers.EveryHours[#hookHandlers.EveryHours + 1] = fn end,
    },
}

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedWorldEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Adapter = Core.WorldEventAdapter
local CoreWKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

local npcs = {
    { id = "npc_u1", coreActorID = "actor_u1", name = "Nina", alive = true, x = 100, y = 100, z = 0 },
    { id = "npc_u2", coreActorID = "actor_u2", name = "Tariq", alive = true, x = 102, y = 100, z = 0 },
}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return nowMs end,
        NowWorldAgeHours = function() return mockWorldDays * 24 end,
        ForEachPlayer = function(cb)
            cb({
                getX = function() return 100 end,
                getY = function() return 100 end,
                getZ = function() return 0 end,
                getOnlineID = function() return 1 end,
            })
        end,
    },
    SpatialIndex = {
        QueryNPCs = function() return npcs end,
    },
    Perception = {
        GetTeamKey = function() return "team_u" end,
        AreWarningAllies = function() return true end,
    },
    Semantics = {
        DialogueBeats = {
            RegisterHook = function() end,
            FindCalmSpeakerNearPlayer = function() return npcs[1], npcs[2] end,
            Emit = function(evName, payload)
                deliveredBeats[#deliveredBeats + 1] = { name = evName, payload = payload }
                return true
            end,
        },
        BeatContext = {
            GetWorldUtilities = function()
                return {
                    powerOn = mockPowerOn,
                    waterOn = mockWorldDays < mockWaterShutDay,
                    elecShutDay = 12,
                    waterShutDay = mockWaterShutDay,
                    currentDay = math.floor(mockWorldDays),
                    powerOutToday = (not mockPowerOn) and math.floor(mockWorldDays) == 12,
                    waterOutToday = (mockWorldDays >= mockWaterShutDay) and math.floor(mockWorldDays) == mockWaterShutDay,
                }
            end,
        },
    },
}

require "PNC/WorldKnowledge/PNC_WorldKnowledge"
require "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ"
require "PNC/Director/PNC_ScopedWorldEventDirector"
require "PNC/Semantics/Beats/PNC_SemanticBeats_Utilities"

ScopedWorldEvents.Reset()
Observer.Reset()
CoreWKG.Reset()
PNC.Semantics.DialogueBeats.ResetUtilitiesRuntime()

-- 1. Hoomans default water reader uses Core utility authority cleanly
local readers = PNC.WorldKnowledge.DefaultAuthorityReaders()
local wVal, wSrc = readers.water()
T.equal(wVal, true, "day 10 water initially ON")
T.truthy(tostring(wSrc):find("WaterShutModifier", 1, true) ~= nil, "water source grounded")

-- 2. Initial state on -> 0 global utility cutoff events
PNC.Semantics.DialogueBeats.CheckUtilities(nowMs)
T.falsy(ScopedWorldEvents.Get("core:utility:electricity_cutoff"), "no premature power cutoff")
T.falsy(ScopedWorldEvents.Get("core:utility:water_cutoff"), "no premature water cutoff")

-- 3. Electricity cuts off on day 12 via Beats/OnElectricityChanged -> single Core event + fact + beat
mockPowerOn = false
mockWorldDays = 12.1
nowMs = 30000
for _, fn in ipairs(hookHandlers.OnElectricityChanged) do
    fn()
end
local elecEv = ScopedWorldEvents.Get("core:utility:electricity_cutoff")
T.truthy(elecEv ~= nil, "Core electricity cutoff registered on transition")
T.equal(elecEv.scope, "global", "electricity cutoff global")
T.truthy(CoreWKG.Ledger.Get(CoreWKG.LedgerState, "fact:core:utility.electricity_cutoff:global") ~= nil,
    "electricity cutoff fact in Core WorldKnowledge")
T.equal(#deliveredBeats, 1, "beat emitted once for power shutoff")

-- 4. Water cuts off on day 14 -> single Core event + fact + beat
mockWorldDays = 14.1
nowMs = 60000
PNC.Semantics.DialogueBeats.CheckUtilities(nowMs)
local waterEv = ScopedWorldEvents.Get("core:utility:water_cutoff")
T.truthy(waterEv ~= nil, "Core water cutoff registered on transition")
T.equal(waterEv.scope, "global", "water cutoff global")
T.truthy(CoreWKG.Ledger.Get(CoreWKG.LedgerState, "fact:core:utility.water_cutoff:global") ~= nil,
    "water cutoff fact in Core WorldKnowledge")
T.equal(#deliveredBeats, 2, "beat emitted once for water shutoff")

-- 5. Repeat checks do NOT duplicate Core utility events or beats
nowMs = 90000
PNC.Semantics.DialogueBeats.CheckUtilities(nowMs)
T.equal(#ScopedWorldEvents.QueryActive({ global = true }), 2, "still exactly 2 global utility events")
T.equal(#deliveredBeats, 2, "no duplicate beat emissions")

-- 6. Synthetic event director rejects global defaults
local synGlobal, synErr = PNC.ScopedWorldEventDirector.EvaluateBucket(336, { scope = "global", timeBucket = 14 })
T.falsy(synGlobal, "synthetic crisis blocked from global scope")
T.equal(synErr, "synthetic_global_scope_forbidden", "synthetic global error reason")

T.finish("pnc_vanilla_utilities_world_events_smoke")

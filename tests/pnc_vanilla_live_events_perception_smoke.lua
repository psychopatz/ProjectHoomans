local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})
package.path = "../psychopatzCore/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;" .. package.path

local mockHours = 72
local spatialQueries = 0
local deliveredBeats = {}
local hooks = {
    OnAmbientSound = {},
    OnWorldSound = {},
    OnWeatherPeriodStart = {},
    OnThunderEvent = {},
}

isClient = function() return false end
isServer = function() return true end
getTimestampMs = function() return mockHours * 3600000 end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return mockHours / 24 end,
        getWorldAgeHours = function() return mockHours end,
    }
end
getCell = function()
    return {
        getGridSquare = function(_, x)
            if x >= 8200 then
                return { getRoom = function() return { name = "kitchen" } end }
            end
            return { getRoom = function() return nil end }
        end,
    }
end
instanceof = function(obj, cls)
    return type(obj) == "table" and obj._class == cls
end

Events = {}
for k, v in pairs(hooks) do
    Events[k] = {
        Add = function(fn) v[#v + 1] = fn end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedWorldEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local CoreWKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

local nearOut = { id = "npc_near_out", coreActorID = "actor_near_out", name = "Iris", alive = true, x = 8150, y = 11520, z = 0 }
local nearIn = { id = "npc_near_in", coreActorID = "actor_near_in", name = "Cole", alive = true, x = 8210, y = 11520, z = 0 }
local farActor = { id = "npc_far", coreActorID = "actor_far", name = "Dante", alive = true, x = 14000, y = 14000, z = 0 }

PNC = {
    Core = {
        IsAuthority = function() return true end,
        Now = function() return mockHours * 3600000 end,
    },
    Registry = {
        Get = function(id)
            for _, r in ipairs({ nearOut, nearIn, farActor }) do
                if r.id == id then return r end
            end
            return nil
        end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            spatialQueries = spatialQueries + 1
            return { nearOut, nearIn }
        end,
    },
    Semantics = {
        DialogueBeats = {
            RegisterHook = function() end,
            BuildWorldThread = function(a, b, spec) return { anchor = a, partner = b, spec = spec } end,
            FindCalmSpeakerNearPoint = function() return nearOut, nearIn end,
            Emit = function(name, payload)
                deliveredBeats[#deliveredBeats + 1] = { name = name, payload = payload }
                return true
            end,
        },
    },
}

require "PNC/WorldKnowledge/PNC_WorldKnowledge"
require "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ"
require "PNC/Semantics/Beats/PNC_SemanticBeats_HouseAlarm"

ScopedWorldEvents.Reset()
Observer.Reset()
CoreWKG.Reset()
PNC.WorldKnowledge.InstallCoreEventPerceptionHook()
PNC.Semantics.DialogueBeats.ResetHouseAlarmRuntime()

-- 1. Gunfire via Core OnAmbientSound -> single canonical fact shared by near NPCs with outdoor/indoor provenance
for _, fn in ipairs(hooks.OnAmbientSound) do
    fn("MetaAssaultRifle1", 8155, 11525)
end
T.equal(spatialQueries, 1, "gunfire used 1 bounded spatial query")
local qGunOut = PNC.WorldKnowledge.QueryActorFact(nearOut, { topic = "ambient.gunfire" }, mockHours)
local qGunIn = PNC.WorldKnowledge.QueryActorFact(nearIn, { topic = "ambient.gunfire" }, mockHours)
local qGunFar = PNC.WorldKnowledge.QueryActorFact(farActor, { topic = "ambient.gunfire" }, mockHours)
T.equal(qGunOut.provenance, "witnessed", "outdoor actor witnesses gunfire")
T.equal(qGunIn.provenance, "environmental", "indoor actor hears gunfire")
T.equal(qGunFar.epistemicStatus, "unknown", "far actor stays ignorant")
T.truthy(qGunOut.summary:find("rifle gunfire", 1, true) ~= nil, "gunfire realization uses weapon class")

-- 2. Scream via OnAmbientSound
mockHours = 73
for _, fn in ipairs(hooks.OnAmbientSound) do
    fn("MetaScream", 8160, 11530)
end
local qScream = PNC.WorldKnowledge.QueryActorFact(nearIn, { topic = "ambient.scream" }, mockHours)
T.equal(qScream.epistemicStatus, "known", "nearby actor hears scream")
T.truthy(qScream.summary:find("screaming", 1, true) ~= nil, "scream renders cleanly")

-- 3. House alarm (SP Alarm world sound -> Core fact + Beat emission, deduped!)
mockHours = 74
for _, fn in ipairs(hooks.OnWorldSound) do
    fn(8150, 11520, 0, 600, 600, { _class = "Alarm" })
end
local qAlarm = PNC.WorldKnowledge.QueryActorFact(nearIn, { topic = "world.house_alarm" }, mockHours)
T.equal(qAlarm.epistemicStatus, "known", "nearby actor perceives house alarm")
T.truthy(qAlarm.summary:find("alarm", 1, true) ~= nil, "house alarm renders cleanly")
T.equal(#deliveredBeats, 1, "alarm beat delivered once")

-- 4. Wildlife and thunder stay ephemeral (0 WorldKnowledge facts, 0 spatial queries)
local queriesBeforeEphem = spatialQueries
for i = 1, 50 do
    for _, fn in ipairs(hooks.OnAmbientSound) do
        fn("MetaDogBark", 8150, 11520)
        fn("MetaOwl", 8150, 11520)
        fn("MetaWolfHowl", 8150, 11520)
    end
    for _, fn in ipairs(hooks.OnThunderEvent) do
        fn(8150, 11520, true, true, true)
    end
end
T.equal(spatialQueries, queriesBeforeEphem, "ephemeral wildlife/thunder caused zero spatial NPC queries")
T.equal(PNC.WorldKnowledge.QueryActorFact(nearOut, { topic = "ambient.dog_bark" }, mockHours).epistemicStatus,
    "unknown", "dog bark not persisted in WorldKnowledge")
T.equal(PNC.WorldKnowledge.QueryActorFact(nearOut, { topic = "weather.thunder" }, mockHours).epistemicStatus,
    "unknown", "thunder not persisted in WorldKnowledge")

-- 5. Told sharing of gunfire rumor keeps uncertain epistemic status
local shared = assert(PNC.WorldKnowledge.PropagateConversation(nearOut, farActor, {
    authorized = true, channel = "conversation", max = 4, now = mockHours,
}))
T.truthy(#shared >= 1, "near actor can gossip gunfire/scream/alarm to far actor")
local qGunTold = PNC.WorldKnowledge.QueryActorFact(farActor, { factID = qGunOut.fact.factID }, mockHours)
T.equal(qGunTold.provenance, "told", "far actor receives gunfire via told")
T.equal(qGunTold.epistemicStatus, "uncertain", "secondhand gunfire is uncertain rumor")

T.finish("pnc_vanilla_live_events_perception_smoke")

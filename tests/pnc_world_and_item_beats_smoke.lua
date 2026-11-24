local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 20000
local worldDays = 14.2
local elecShutDay = 14
local waterShutDay = 14
local powerGridOn = true
local tvTurnedOn = false
local tvCanPower = true
local tvChannelName = "Life and Living TV"
local tvMediaTitle = "Woodcraft"
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
getCurrentSaveName = function() return "world-beats-smoke" end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return worldDays end,
        getWorldAgeHours = function() return worldDays * 24 end,
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
    return {
        isHydroPowerOn = function() return powerGridOn end,
    }
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
        return {
            getChannelName = function(_, ch)
                return ch == 203 and tvChannelName or "Triple-N"
            end,
        }
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
    getUsername = function() return "Pat" end,
    getDisplayName = function() return "Pat" end,
    getDescriptor = function() return { getForename = function() return "Pat" end } end,
}

PNC = {
    Const = {
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
        GetTeamKey = function(rec) return rec.factionID or "colonists" end,
        AreWarningAllies = function(a, b) return a.id ~= b.id end,
        GetActiveSkirmish = function() return nil end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcID, eventType, payload)
            deliveredBarks[#deliveredBarks + 1] = {
                npcID = tostring(npcID),
                eventType = tostring(eventType),
                ambientFlavor = payload and payload.ambientFlavor or nil,
            }
            return true
        end,
    },
}

local npcA = {
    id = "npc_beat_1", name = "Sammie", fullName = "Sammie Patz",
    tacticalClass = "friendly", factionID = "colonists",
    x = 10, y = 10, z = 0, alive = true, presenceState = "live", runtime = {},
}
local npcB = {
    id = "npc_beat_2", name = "Adrienne", fullName = "Adrienne Patz",
    tacticalClass = "friendly", factionID = "colonists",
    x = 11, y = 10, z = 0, alive = true, presenceState = "live", runtime = {},
}
local npcStore = { [npcA.id] = npcA, [npcB.id] = npcB }
PNC.Registry = { Data = npcStore, Get = function(id) return npcStore[tostring(id)] end }
PNC.SpatialIndex = {
    QueryNPCs = function() return { npcA, npcB } end,
}

T.load("PsychopatzCore", "common", "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Semantics/PsychopatzSemantic.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueState.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueRouter.lua")
T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/SpeechRealization.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_API.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_Targeting.lua")

T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts.lua")
local BC = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticBeatContext.lua")
local Beats = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticDialogueBeats.lua")

local function assertCleanLine(text, label)
    T.truthy(type(text) == "string" and text ~= "", label .. " non-empty")
    T.falsy(string.find(text, "{", 1, true), label .. " has no unexpanded brace tokens: " .. tostring(text))
    T.falsy(string.find(text, "%%s"), label .. " has no raw %s: " .. tostring(text))
end

local function resetArbiter()
    local banter = PNC.ConvoEngine and PNC.ConvoEngine.CombatBanterArbiter
    if banter and banter.ResetRuntime then banter.ResetRuntime() end
end

-- 1. House alarm beat + spatial dedupe across OnWorldSound & OnAmbientSound
Beats.ResetRuntime()
resetArbiter()
T.equal(#worldSoundHandlers > 0 and #ambientSoundHandlers > 0, true, "house alarm registers sound hooks")
worldSoundHandlers[1](12, 11, 0, 100, 100, { _class = "Alarm" })
T.equal(#deliveredBarks, 1, "house alarm opening bark emits")
T.truthy(string.find(tostring(deliveredBarks[1].ambientFlavor.speechEventID), "house_alarm_open", 1, true), "opening uses house_alarm_open")
assertCleanLine(deliveredBarks[1].ambientFlavor.text, "house alarm open")

-- Duplicate burglar2 sound in same bucket within 65s is deduped
nowMs = nowMs + 1000
ambientSoundHandlers[1]("burglar2", 14, 12)
Beats.Pump(nowMs)
T.equal(#deliveredBarks, 2, "only reply turn arrives after pump; overlapping burglar2 sound was deduped")
T.truthy(string.find(tostring(deliveredBarks[2].ambientFlavor.speechEventID), "house_alarm_reply", 1, true), "reply uses house_alarm_reply")
assertCleanLine(deliveredBarks[2].ambientFlavor.text, "house alarm reply")

-- 2. Electricity & Water shutoff (that day)
Beats.ResetRuntime()
resetArbiter()
deliveredBarks = {}
nowMs = nowMs + 70000
powerGridOn = false
elecShutDay = 14
waterShutDay = 99 -- test power shutoff first, then water shutoff cleanly
BC.GetWorldUtilities(nowMs, true)
T.equal(BC.GetWorldUtilities(nowMs).powerOutToday, true, "BeatContext detects powerOutToday")
Beats.CheckUtilities(nowMs)
T.equal(#deliveredBarks, 1, "power shutoff beat emits on shutoff day")
T.truthy(string.find(tostring(deliveredBarks[1].ambientFlavor.speechEventID), "power_shutoff_open", 1, true), "power shutoff variant selected")
assertCleanLine(deliveredBarks[1].ambientFlavor.text, "power shutoff line")

-- Re-checking same day does not re-emit power shutoff
nowMs = nowMs + 10000
resetArbiter()
Beats.CheckUtilities(nowMs)
T.equal(#deliveredBarks, 1, "power shutoff dedupes for the rest of the day")

-- Water shutoff on same day 14
waterShutDay = 14
BC.GetWorldUtilities(nowMs, true)
T.equal(BC.GetWorldUtilities(nowMs).waterOutToday, true, "BeatContext detects waterOutToday")
Beats.CheckUtilities(nowMs)
T.equal(#deliveredBarks, 2, "water shutoff beat emits on shutoff day")
T.truthy(string.find(tostring(deliveredBarks[2].ambientFlavor.speechEventID), "water_shutoff_open", 1, true), "water shutoff variant selected")
assertCleanLine(deliveredBarks[2].ambientFlavor.text, "water shutoff line")

nowMs = nowMs + 10000
resetArbiter()
Beats.CheckUtilities(nowMs)
T.equal(#deliveredBarks, 2, "water shutoff dedupes for the rest of the day")

-- 3. Television vicinity (power ON reminisce vs power OFF reaction) + Life & Living OnDeviceText
local tvObj = {
    _class = "IsoTelevision",
    getX = function() return 11 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getDeviceData = function()
        return {
            getIsTelevision = function() return true end,
            getIsTurnedOn = function() return tvTurnedOn end,
            canBePoweredHere = function() return tvCanPower end,
            getChannel = function() return 203 end,
            getMediaData = function()
                return { getTitleEN = function() return tvMediaTitle end }
            end,
        }
    end,
}
worldSquareObjects["11:10:0"] = { tvObj }

-- Power ON, TV off -> reminisce
Beats.ResetRuntime()
resetArbiter()
deliveredBarks = {}
powerGridOn = true
elecShutDay = 30
waterShutDay = 30
tvTurnedOn = false
tvCanPower = true
nowMs = nowMs + 100000
Beats.CheckNearbyWorldObjects(nowMs)
T.equal(#deliveredBarks, 1, "off TV with power ON emits reminisce opening")
T.truthy(string.find(tostring(deliveredBarks[1].ambientFlavor.speechEventID), "tv_reminisce_open", 1, true), "selects tv_reminisce_open")
assertCleanLine(deliveredBarks[1].ambientFlavor.text, "tv reminisce open")
nowMs = nowMs + 1200
Beats.Pump(nowMs)
T.equal(#deliveredBarks, 2, "tv_reminisce_reply delivers on Pump")
T.truthy(string.find(tostring(deliveredBarks[2].ambientFlavor.speechEventID), "tv_reminisce_reply", 1, true), "selects tv_reminisce_reply")
assertCleanLine(deliveredBarks[2].ambientFlavor.text, "tv reminisce reply")

-- Power OFF -> power out TV reaction
Beats.ResetRuntime()
resetArbiter()
deliveredBarks = {}
powerGridOn = false
tvCanPower = false
elecShutDay = 14
nowMs = nowMs + 100000
Beats.CheckNearbyWorldObjects(nowMs)
T.equal(#deliveredBarks, 1, "off TV with power OFF emits tv_power_out_open")
T.truthy(string.find(tostring(deliveredBarks[1].ambientFlavor.speechEventID), "tv_power_out_open", 1, true), "selects tv_power_out_open")
assertCleanLine(deliveredBarks[1].ambientFlavor.text, "tv power out open")

-- TV ON watching Life and Living -> OnDeviceText beat with {slot.show.name} resolved
Beats.ResetRuntime()
resetArbiter()
deliveredBarks = {}
powerGridOn = true
tvTurnedOn = true
tvCanPower = true
nowMs = nowMs + 100000
deviceTextHandlers[1]("guid-tv-1", "show", 11, 10, 0, "Welcome to Woodcraft!", tvObj)
T.equal(#deliveredBarks, 1, "active Life and Living TV OnDeviceText emits commentary")
local watchFlavor = deliveredBarks[1].ambientFlavor
T.truthy(string.find(tostring(watchFlavor.speechEventID), "tv_watching_life_and_living_open", 1, true), "selects Life and Living show commentary")
assertCleanLine(watchFlavor.text, "tv watching life and living open")
T.truthy(string.find(watchFlavor.text, "Woodcraft", 1, true), "show title substituted into dialogue: " .. tostring(watchFlavor.text))

-- 4. Extensibility check: custom world-object hook
local customHit = 0
T.truthy(Beats.RegisterObjectBeatHook("test.acoustic_guitar", {
    priority = 80,
    cooldownMs = 1000,
    matches = function(obj) return type(obj) == "table" and obj.isAcousticGuitar == true end,
    evaluate = function(_, _, anchor, partner)
        customHit = customHit + 1
        return Beats.BuildWorldThread(anchor, partner, {
            refPrefix = "world:custom_guitar",
            family = "world_house_alarm",
            poolID = "semantic.world.object.notice",
            eventType = "world_television_beat",
            openRole = "tv_reminisce_open",
            priority = 40,
        })
    end,
}), "custom object beat hook registers cleanly")

worldSquareObjects["11:10:0"] = { { isAcousticGuitar = true } }
nowMs = nowMs + 60000
resetArbiter()
Beats.CheckNearbyWorldObjects(nowMs)
T.equal(customHit, 1, "custom world-object hook matches and evaluates nearby object")
Beats.UnregisterObjectBeatHook("test.acoustic_guitar")

T.finish("pnc_world_and_item_beats_smoke")

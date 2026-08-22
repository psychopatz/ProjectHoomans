local T = require "tests/support/test"

local ACTION_PATH =
    T.path("ProjectHoomans", "client", "PNC/Actions/PNC_BandageAction.lua")

local Base = {}
function Base:derive()
    local child = {}
    child.__index = child
    return setmetatable(child, { __index = self })
end
function Base.new(class, character)
    return setmetatable({ character = character }, class)
end
function Base:setActionAnim(value) self.startedAnimation = value end
function Base:setOverrideHandModels() end
function Base:getJobDelta() return 0.5 end
function Base.stop(self) self.baseStopped = true end
function Base.perform(self) self.basePerformed = true end

package.preload["TimedActions/ISBaseTimedAction"] = function()
    ISBaseTimedAction = Base
    return Base
end

local queued
package.preload["TimedActions/ISTimedActionQueue"] = function()
    ISTimedActionQueue = {
        add = function(action) queued = action end,
    }
    return ISTimedActionQueue
end

local completed = {}
local item = {
    setJobType = function(self, value) self.jobType = value end,
    setJobDelta = function(self, value) self.jobDelta = value end,
    getContainer = function() return {} end,
}
local inventory = {
    containsRecursive = function(_, candidate) return candidate == item end,
}
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isOnFloor = function() return false end,
}
local emitter = { isPlaying = function() return true end }
local playedSound
local rangeAllowed = true
local player = {
    getInventory = function() return inventory end,
    getPerkLevel = function() return 4 end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
    faceThisObject = function() end,
    shouldBeTurning = function() return false end,
    reportEvent = function(self, event) self.reportedEvent = event end,
    SetVariable = function(self, key, value)
        self.animationVariable = key .. "=" .. value
    end,
    playSound = function(_, sound)
        playedSound = sound
        return 7
    end,
    getEmitter = function() return emitter end,
    stopOrTriggerSound = function() end,
}

Perks = { Doctor = "Doctor" }
Metabolics = { LightDomestic = "LightDomestic" }
getText = function() return "Bandage" end

PNC = {
    Const = { BANDAGE_RANGE = 3 },
    Registry = {
        Get = function()
            return {
                id = "npc_timed",
                alive = true,
                healthState = "normal",
                x = 0,
                y = 0,
                z = 0,
            }
        end,
        GetLiveZombie = function() return body end,
    },
    Network = { ClientState = { snapshots = {} } },
    Treatment = {
        FindBandage = function() return item end,
        IsPlayerInBandageRange = function() return rangeAllowed end,
    },
    Client = {
        CompleteBandage = function(npcId, partId, debugFree, bandageType)
            completed = { npcId, partId, debugFree, bandageType }
        end,
    },
}

T.load(ACTION_PATH)

local ok, reason = PNCBandageAction.Queue(
    player, "npc_timed", "Hand_R", false, "Base.Bandage"
)
T.equal(ok, true, "queue action")
T.equal(reason, "queued", "queue reason")
T.truthy(queued, "timed action was not queued")
T.equal(#completed, 0, "bandage completed before timed action")
T.equal(queued.maxTime, 104, "First Aid duration")
T.equal(queued:isValid(), true, "queued action validity")

queued:start()
T.equal(queued.startedAnimation, "Loot", "other-character treatment animation")
T.equal(player.animationVariable, "LootPosition=Mid", "mid treatment pose")
T.equal(player.reportedEvent, "EventLootItem", "treatment interaction event")
T.equal(playedSound, "FirstAidApplyBandage", "vanilla bandage SFX")
T.equal(queued.useProgressBar, true, "vanilla loading bar enabled")
T.equal(item.jobType, "Bandage", "item progress label")

queued:update()
T.equal(item.jobDelta, 0.5, "item loading progress")
queued:perform()
T.equal(completed[1], "npc_timed", "authoritative completion npc")
T.equal(completed[2], "Hand_R", "authoritative completion body part")
T.equal(completed[4], "Base.Bandage", "authoritative completion item type")
T.equal(item.jobDelta, 0, "item progress reset")
T.equal(queued.basePerformed, true, "timed action completion")

rangeAllowed = false
ok, reason = PNCBandageAction.Queue(
    player, "npc_timed", "Hand_R", false, "Base.Bandage"
)
T.equal(ok, false, "out-of-range action rejected before queue")
T.equal(reason, "out_of_range", "out-of-range queue reason")

local completionBeforeBlocked = completed
local blockedAction = PNCBandageAction:new(
    player,
    "npc_timed",
    "Hand_R",
    item,
    false,
    "Base.Bandage"
)
blockedAction:perform()
T.equal(completed, completionBeforeBlocked,
    "out-of-range completion reached authority")
T.equal(blockedAction.basePerformed, true,
    "blocked timed action did not leave the queue")

T.equal(
    PNCBandageAction.ResolveLootPosition("npc_timed", "Head"),
    "High",
    "head treatment pose"
)
T.equal(
    PNCBandageAction.ResolveLootPosition("npc_timed", "LowerLeg_R"),
    "Low",
    "lower-leg treatment pose"
)
T.equal(
    PNCBandageAction.ResolveLootPosition("npc_timed", "Torso_Upper"),
    "Mid",
    "torso treatment pose"
)

PNC.Registry.Get = function()
    return {
        id = "npc_timed",
        alive = true,
        healthState = "incapacitated",
        x = 0,
        y = 0,
        z = 0,
    }
end
T.equal(
    PNCBandageAction.ResolveLootPosition("npc_timed", "Head"),
    "Low",
    "downed patient overrides wound height"
)
T.finish("pnc_bandage_timed_action_smoke")

T.finish("pnc_bandage_timed_action_smoke")

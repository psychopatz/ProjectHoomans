local ACTION_PATH =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/Actions/PNC_BandageAction.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
}
local emitter = { isPlaying = function() return true end }
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
    SetVariable = function(self, key, value) self.animationVariable = key .. "=" .. value end,
    playSound = function() return 7 end,
    getEmitter = function() return emitter end,
    stopOrTriggerSound = function() end,
}

Perks = { Doctor = "Doctor" }
Metabolics = { LightDomestic = "LightDomestic" }
getText = function() return "Bandage" end

PNC = {
    Const = { BANDAGE_RANGE = 3 },
    Registry = {
        Get = function() return { id = "npc_timed", alive = true, x = 0, y = 0, z = 0 } end,
        GetLiveZombie = function() return body end,
    },
    Network = { ClientState = { snapshots = {} } },
    Treatment = {
        FindBandage = function() return item end,
        IsPlayerInBandageRange = function() return true end,
    },
    Client = {
        CompleteBandage = function(npcId, partId, debugFree, bandageType)
            completed = { npcId, partId, debugFree, bandageType }
        end,
    },
}

dofile(ACTION_PATH)

local ok, reason = PNCBandageAction.Queue(
    player, "npc_timed", "Hand_R", false, "Base.Bandage"
)
assertEqual(ok, true, "queue action")
assertEqual(reason, "queued", "queue reason")
assert(queued, "timed action was not queued")
assertEqual(#completed, 0, "bandage completed before timed action")
assertEqual(queued.maxTime, 104, "First Aid duration")
assertEqual(queued:isValid(), true, "queued action validity")

queued:start()
assertEqual(queued.startedAnimation, "Loot", "vanilla other-patient animation")
assertEqual(player.animationVariable, "LootPosition=Mid", "vanilla loot position")
assertEqual(player.reportedEvent, "EventLootItem", "vanilla animation event")
assertEqual(item.jobType, "Bandage", "item progress label")

queued:update()
assertEqual(item.jobDelta, 0.5, "item loading progress")
queued:perform()
assertEqual(completed[1], "npc_timed", "authoritative completion npc")
assertEqual(completed[2], "Hand_R", "authoritative completion body part")
assertEqual(completed[4], "Base.Bandage", "authoritative completion item type")
assertEqual(item.jobDelta, 0, "item progress reset")
assertEqual(queued.basePerformed, true, "timed action completion")

print("pnc_bandage_timed_action_smoke: ok")

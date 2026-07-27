local LIVE_BODY_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua"
local CLIENT_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PNC_ClientHumanNPCSafeguards.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
        contains = function(_, value)
            for _, entry in ipairs(values) do
                if entry == value then return true end
            end
            return false
        end,
        add = function(_, value)
            values[#values + 1] = value
            return true
        end,
    }
end

local stopped = {}
local voicePrefix
local useless = false
local modData = { PNC_NPC = true }
local emitter = {
    stopSoundByName = function(_, name)
        stopped[#stopped + 1] = name
    end,
    stopAll = function()
        error("maintenance must not stop intentional NPC sounds")
    end,
}
local descriptor = {
    setVoicePrefix = function(_, value) voicePrefix = value end,
}
local managedBody = {
    getModData = function() return modData end,
    getDescriptor = function() return descriptor end,
    getEmitter = function() return emitter end,
    setUseless = function(_, value) useless = value end,
    getX = function() return 2 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
    isZombie = function() return true end,
    isAlive = function() return true end,
    isDead = function() return false end,
}

PNC = {
    Core = {
        Now = function() return 1000 end,
        IsManagedNPCBody = function(body)
            local data = body and body.getModData and body:getModData() or nil
            return data and data.PNC_NPC == true or false
        end,
    },
}

dofile(LIVE_BODY_FILE)

assertEqual(PNC.LiveBodyControl.SuppressZombieSounds(managedBody), true,
    "specific zombie channels suppressed")
assertEqual(voicePrefix, "NotAZombie", "human voice prefix")
assertEqual(#stopped, 6, "all Build 42 zombie voice variants stopped")

PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1000)
assertEqual(useless, true, "humanized useless flag reasserted")
assertEqual(#stopped, 12, "first maintenance suppresses voices")
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1100)
assertEqual(#stopped, 12, "voice suppression is cadence bounded")
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1300)
assertEqual(#stopped, 18, "voice suppression repeats after cooldown")

local playerStopped = {}
local panic = 2
local visibleZombies = 0
local stats = {
    get = function() return panic end,
    getNumVisibleZombies = function() return visibleZombies end,
    set = function(_, _, value) panic = value return true end,
    setNumVisibleZombies = function(_, value) visibleZombies = value end,
}
setmetatable(stats, {
    __newindex = function(_, field)
        error("unsupported Stats field write: " .. tostring(field))
    end,
})
local spottedValues = {}
local lastSpottedValues = {}
local player = {
    getPlayerNum = function() return 0 end,
    getStats = function() return stats end,
    getSpottedList = function() return makeList(spottedValues) end,
    getLastSpotted = function() return makeList(lastSpottedValues) end,
    getEmitter = function()
        return {
            stopSoundByName = function(_, name)
                playerStopped[#playerStopped + 1] = name
            end,
        }
    end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

CharacterStat = { PANIC = "panic" }
instanceof = function(body, className)
    return className == "IsoZombie" and body and body.isZombie and body:isZombie()
end
Events = {
    OnPlayerUpdate = { Add = function() end },
    OnResetLua = { Add = function() end },
}
PNC.ClientPresenceSync = { BodyByID = {} }

dofile(CLIENT_FILE)

-- Establish a pre-NPC panic baseline.
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
panic = 5
visibleZombies = 3
spottedValues[1] = managedBody
PNC.ClientPresenceSync.BodyByID.npc_1 = managedBody

PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
assertEqual(panic, 2, "false NPC zombie panic increase removed")
assertEqual(visibleZombies, 0, "false visible zombie count removed")
assertEqual(lastSpottedValues[1], managedBody, "human body pre-seeded as already spotted")
assertEqual(playerStopped[#playerStopped], "ZombieSurprisedPlayer",
    "false zombie surprise sound stopped")

local normalZombie = {
    getModData = function() return {} end,
    isZombie = function() return true end,
    isAlive = function() return true end,
    isDead = function() return false end,
}
spottedValues[2] = normalZombie
panic = 6
visibleZombies = 2
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
assertEqual(panic, 6, "real zombie panic remains untouched")
assertEqual(visibleZombies, 2, "real zombie visible count remains untouched")

print("pnc_human_npc_safeguards_smoke: ok")

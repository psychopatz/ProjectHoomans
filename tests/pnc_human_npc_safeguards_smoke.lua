local LIVE_BODY_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua"
local CLIENT_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PNC_ClientHumanNPCSafeguards.lua"
local SLEEP_PATCH_FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/Patches/PNC_HumanNPCSleepPatch.lua"

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
local grappleOnly = false
local noTeeth = false
local vanillaTarget = {}
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
    isUseless = function() return useless end,
    setNoTeeth = function(_, value) noTeeth = value end,
    isNoTeeth = function() return noTeeth end,
    getTarget = function() return vanillaTarget end,
    setTarget = function(_, value) vanillaTarget = value end,
    clearAggroList = function() end,
    setAttackedBy = function() end,
    isReanimatedForGrappleOnly = function() return grappleOnly end,
    setReanimatedForGrappleOnly = function(_, value) grappleOnly = value end,
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

local zombieUpdateHandler
Events = {
    OnZombieUpdate = {
        Remove = function() end,
        Add = function(handler) zombieUpdateHandler = handler end,
    },
    OnGameStart = { Remove = function() end, Add = function() end },
    OnServerStarted = { Remove = function() end, Add = function() end },
}

dofile(LIVE_BODY_FILE)

assertEqual(PNC.LiveBodyControl.SuppressZombieSounds(managedBody), true,
    "specific zombie channels suppressed")
assertEqual(voicePrefix, "NotAZombie", "human voice prefix")
assertEqual(#stopped, 6, "all Build 42 zombie voice variants stopped")

PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1000)
assertEqual(useless, true, "humanized useless flag reasserted")
assertEqual(noTeeth, true, "humanized no-teeth fail-safe reasserted")
assertEqual(vanillaTarget, nil, "humanized vanilla target cleared")
assertEqual(#stopped, 12, "first maintenance suppresses voices")
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1100)
assertEqual(#stopped, 12, "voice suppression is cadence bounded")
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1300)
assertEqual(#stopped, 18, "voice suppression repeats after cooldown")

useless = false
noTeeth = false
vanillaTarget = {}
zombieUpdateHandler(managedBody)
assertEqual(useless, true, "zombie update repairs persisted useless flag")
assertEqual(noTeeth, true, "zombie update repairs persisted teeth flag")
assertEqual(vanillaTarget, nil, "zombie update clears persisted target")

local panic = 2
local visibleZombies = 0
local chasingZombies = 0
local veryCloseZombies = 0
local stats = {
    get = function() return panic end,
    getNumVisibleZombies = function() return visibleZombies end,
    getNumChasingZombies = function() return chasingZombies end,
    getNumVeryCloseZombies = function() return veryCloseZombies end,
    set = function(_, _, value) panic = value return true end,
    setNumVisibleZombies = function(_, value) visibleZombies = value end,
    setLastNumberChasingZombies = function(_, value) chasingZombies = value end,
}
setmetatable(stats, {
    __newindex = function(_, field)
        error("unsupported Stats field write: " .. tostring(field))
    end,
})
local spottedValues = {}
local lastSpottedValues = {}
local speed = 1
local multiplier = 1
local controls = {
    getCurrentGameSpeed = function() return speed end,
    SetCurrentGameSpeed = function(_, value) speed = value end,
    ButtonClicked = function(_, name)
        if name == "Fast Forward x 1" then
            speed = 2
            multiplier = 5
        elseif name == "Fast Forward x 2" then
            speed = 3
            multiplier = 20
        elseif name == "Wait" then
            speed = 4
            multiplier = 40
        end
    end,
}
local player = {
    getPlayerNum = function() return 0 end,
    getStats = function() return stats end,
    getSpottedList = function() return makeList(spottedValues) end,
    getLastSpotted = function() return makeList(lastSpottedValues) end,
    getEmitter = function()
        return {
            stopSoundByName = function()
                error("human-NPC safeguard must not cut player audio")
            end,
        }
    end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isJustMoved = function() return false end,
    isPlayerMoving = function() return false end,
    isAiming = function() return false end,
    isAttacking = function() return false end,
    isOnFire = function() return false end,
    isDead = function() return false end,
    updateLOS = function()
        visibleZombies = 0
        chasingZombies = 0
        veryCloseZombies = 0
        for _, body in ipairs(spottedValues) do
            local excluded = body.isReanimatedForGrappleOnly
                and body:isReanimatedForGrappleOnly()
            if body.isZombie and body:isZombie() and not excluded then
                visibleZombies = visibleZombies + 1
                veryCloseZombies = veryCloseZombies + 1
            end
        end
    end,
}

CharacterStat = { PANIC = "panic" }
instanceof = function(body, className)
    return className == "IsoZombie" and body and body.isZombie and body:isZombie()
end
Events = {
    OnPlayerUpdate = { Add = function() end },
    OnPreUIDraw = { Add = function() end },
    OnCreatePlayer = { Add = function() end },
    OnResetLua = { Add = function() end },
}
PNC.ClientPresenceSync = { BodyByID = {} }
UIManager = { getSpeedControls = function() return controls end }
getSpecificPlayer = function() return player end
getNumActivePlayers = function() return 1 end
isClient = function() return false end

dofile(CLIENT_FILE)

-- Establish a pre-NPC panic baseline.
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
panic = 5
visibleZombies = 3
chasingZombies = 2
veryCloseZombies = 1
spottedValues[1] = managedBody
PNC.ClientPresenceSync.BodyByID.npc_1 = managedBody

PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
assertEqual(panic, 2, "false NPC zombie panic increase removed")
assertEqual(visibleZombies, 0, "false visible zombie count removed")
assertEqual(chasingZombies, 0, "false chasing zombie count removed")
assertEqual(veryCloseZombies, 0, "false very-close zombie count recalculated")
assertEqual(grappleOnly, false, "temporary LOS exclusion restored")
assertEqual(lastSpottedValues[1], managedBody, "human body pre-seeded as already spotted")

local normalZombie = {
    getModData = function() return {} end,
    isZombie = function() return true end,
    isAlive = function() return true end,
    isDead = function() return false end,
}
spottedValues[2] = normalZombie
panic = 6
visibleZombies = 2
chasingZombies = 2
veryCloseZombies = 2
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
assertEqual(panic, 6, "real zombie panic remains untouched")
assertEqual(visibleZombies, 1, "real zombie visible count survives exact recount")
assertEqual(veryCloseZombies, 1, "real zombie close count survives exact recount")

spottedValues[2] = nil
speed = 3
PNC.ClientHumanNPCSafeguards.CaptureFastForwardIntent()
speed = 1
visibleZombies = 1
veryCloseZombies = 1
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
assertEqual(speed, 3, "managed body does not cancel requested fast-forward")
assertEqual(multiplier, 20, "fast-forward restores vanilla time multiplier")

speed = 1
PNC.ClientHumanNPCSafeguards.CaptureFastForwardIntent()
visibleZombies = 1
veryCloseZombies = 1
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
assertEqual(speed, 1, "explicit normal speed remains selected")

local sleepAllowed
ISWorldObjectContextMenu = {
    onSleepWalkToComplete = function()
        sleepAllowed = stats:getNumVisibleZombies() <= 0
            and stats:getNumChasingZombies() <= 0
            and stats:getNumVeryCloseZombies() <= 0
    end,
}
package.preload["ISUI/ISWorldObjectContextMenu"] = function()
    return ISWorldObjectContextMenu
end
package.loaded["PNC/PNC_ClientHumanNPCSafeguards"] =
    PNC.ClientHumanNPCSafeguards
dofile(SLEEP_PATCH_FILE)

visibleZombies = 1
veryCloseZombies = 1
ISWorldObjectContextMenu.onSleepWalkToComplete(0, {})
assertEqual(sleepAllowed, true, "managed human body does not block sleep")

spottedValues[2] = normalZombie
visibleZombies = 2
veryCloseZombies = 2
ISWorldObjectContextMenu.onSleepWalkToComplete(0, {})
assertEqual(sleepAllowed, false, "ordinary zombie still blocks sleep")

print("pnc_human_npc_safeguards_smoke: ok")

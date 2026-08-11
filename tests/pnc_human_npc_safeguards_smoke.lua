local LIVE_BODY_FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua"
local CLIENT_FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PNC_ClientHumanNPCSafeguards.lua"
local SLEEP_PATCH_FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Patches/PNC_HumanNPCSleepPatch.lua"

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
local uselessWrites = 0
local grappleOnly = false
local noTeeth = false
local vanillaTarget = {}
local actionState = "idle"
local modData = { PNC_NPC = true }
local managedRecord
local nativeFramePumps = 0
local registryFindCalls = 0
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
    setUseless = function(_, value)
        uselessWrites = uselessWrites + 1
        useless = value
    end,
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
    getActionStateName = function() return actionState end,
    setBumpFall = function(_, value)
        if value == false and actionState == "bumped" then
            actionState = "idle"
        end
    end,
    changeState = function()
        actionState = "idle"
    end,
}

ZombieIdleState = {
    instance = function() return "idle_state" end,
}

PNC = {
    Core = {
        Now = function() return 1000 end,
        IsAuthority = function() return true end,
        IsManagedNPCBody = function(body)
            local data = body and body.getModData and body:getModData() or nil
            return data and data.PNC_NPC == true or false
        end,
    },
    Registry = {
        FindRecordByZombie = function()
            registryFindCalls = registryFindCalls + 1
            return managedRecord
        end,
    },
    EnginePathPlanner = {
        PumpFrame = function()
            nativeFramePumps = nativeFramePumps + 1
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

zombieUpdateHandler({
    getModData = function() return {} end,
})
assertEqual(
    registryFindCalls,
    0,
    "ordinary zombie update reached the managed NPC registry"
)

assertEqual(PNC.LiveBodyControl.SuppressZombieSounds(managedBody), true,
    "specific zombie channels suppressed")
assertEqual(voicePrefix, "NotAZombie", "human voice prefix")
assertEqual(#stopped, 6, "all Build 42 zombie voice variants stopped")

PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1000)
assertEqual(useless, true, "humanized useless flag reasserted")
assertEqual(noTeeth, true, "humanized no-teeth fail-safe reasserted")
assertEqual(vanillaTarget, nil, "humanized vanilla target cleared")
assertEqual(#stopped, 12, "first maintenance suppresses voices")
local writesAfterInitialMaintenance = uselessWrites
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1100)
assertEqual(#stopped, 12, "voice suppression is cadence bounded")
assertEqual(
    uselessWrites,
    writesAfterInitialMaintenance,
    "body safety rewrote Java flags before maintenance was due"
)
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1300)
assertEqual(#stopped, 18, "voice suppression repeats after cooldown")
assertEqual(
    uselessWrites,
    writesAfterInitialMaintenance,
    "audio cadence triggered a full body safety rewrite"
)

modData.PNC_BumpActionLease = true
modData.PNC_BumpActionLeaseUntil = 2000
modData.PNC_BumpKeepUseless = true
local writesBeforeActionMaintenance = uselessWrites
PNC.LiveBodyControl.MaintainHumanizedBody(managedBody, 1400)
assertEqual(
    uselessWrites,
    writesBeforeActionMaintenance,
    "active animation lease repeated setUseless and reset ActionContext"
)
actionState = "bumped"
PNC.LiveBodyControl.ApplyHumanizedBodyFlags(managedBody)
assertEqual(
    actionState,
    "bumped",
    "direct humanization cancelled an active PNC action lease"
)
zombieUpdateHandler(managedBody)
assertEqual(
    actionState,
    "bumped",
    "managed safety suppressed the active PNC melee action"
)
modData.PNC_BumpActionLease = nil
modData.PNC_BumpActionLeaseUntil = nil
modData.PNC_BumpKeepUseless = nil

actionState = "attack"
zombieUpdateHandler(managedBody)
assertEqual(
    actionState,
    "idle",
    "vanilla zombie attack graph retained locomotion ownership"
)

useless = false
noTeeth = false
grappleOnly = true
vanillaTarget = {}
zombieUpdateHandler(managedBody)
assertEqual(useless, true, "zombie update repairs persisted useless flag")
assertEqual(noTeeth, true, "zombie update repairs persisted teeth flag")
assertEqual(grappleOnly, false, "zombie update repairs leaked grapple-only flag")
assertEqual(vanillaTarget, nil, "zombie update clears persisted target")

managedRecord = {
    runtime = {
        localNavigation = {
            provider = "engine_path",
            nativeActive = true,
            serverMovementLease = true,
        },
    },
}
useless = true
zombieUpdateHandler(managedBody)
assertEqual(useless, false,
    "multiplayer native movement lease was stomped by body safety")
assertEqual(nativeFramePumps, 1,
    "multiplayer native route was not advanced from zombie update")
PNC.Core.IsAuthority = function() return false end
useless = false
PNC.LiveBodyControl.EnforceManagedSafety(managedBody, "client_replica")
assertEqual(useless, true,
    "client replica inherited the server's native movement lease")
PNC.Core.IsAuthority = function() return true end
managedRecord = nil

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
local speedButtonCalls = 0
local controls = {
    getCurrentGameSpeed = function() return speed end,
    SetCurrentGameSpeed = function(_, value) speed = value end,
    ButtonClicked = function(_, name)
        speedButtonCalls = speedButtonCalls + 1
        if name == "Play" then
            speed = 1
            multiplier = 1
        elseif name == "Fast Forward x 1" then
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
local originalButtonClicked = controls.ButtonClicked
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
                speed = 1
                multiplier = 1
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
    OnTick = { Add = function() end },
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
grappleOnly = false
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
controls:ButtonClicked("Fast Forward x 2")
local playerSpeedButtonCalls = speedButtonCalls
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
player:updateLOS()
assertEqual(speed, 1, "vanilla LOS attempted managed-body speed reset")
PNC.ClientHumanNPCSafeguards.OnTick()
assertEqual(speed, 3, "post-LOS safeguard restores requested fast-forward")
assertEqual(multiplier, 20, "post-LOS safeguard restores vanilla multiplier")
assertEqual(speedButtonCalls, playerSpeedButtonCalls + 1,
    "safeguard delegates restoration through vanilla speed controls")
assertEqual(controls.ButtonClicked, originalButtonClicked,
    "safeguard leaves Java-owned method untouched")

controls:ButtonClicked("Play")
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
player:updateLOS()
PNC.ClientHumanNPCSafeguards.OnTick()
assertEqual(speed, 1, "explicit normal speed remains selected")

spottedValues[2] = normalZombie
controls:ButtonClicked("Fast Forward x 2")
PNC.ClientHumanNPCSafeguards.OnPlayerUpdate(player)
player:updateLOS()
PNC.ClientHumanNPCSafeguards.OnTick()
assertEqual(speed, 1, "ordinary zombie still cancels fast-forward")
spottedValues[2] = nil
PNC.ClientHumanNPCSafeguards.OnResetLua()
assertEqual(controls.ButtonClicked, originalButtonClicked,
    "Lua reset leaves Java-owned method untouched")

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

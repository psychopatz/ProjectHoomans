local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local THREAT_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_HumanNPCThreatSafeguards.lua"
)

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

local panic = 2
local visible = 0
local close = 0
local spotted = {}
local lastSpotted = {}
local grappleOnly = false
local managedData = { PNC_NPC = true }

local managedBody = {
    getModData = function() return managedData end,
    isZombie = function() return true end,
    isAlive = function() return true end,
    isDead = function() return false end,
    getX = function() return 2 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
    isReanimatedForGrappleOnly = function() return grappleOnly end,
    setReanimatedForGrappleOnly = function(_, value) grappleOnly = value end,
}

local player = {
    getPlayerNum = function() return 0 end,
    getStats = function()
        return {
            get = function() return panic end,
            set = function(_, _, value) panic = value end,
            getNumVisibleZombies = function() return visible end,
            getNumChasingZombies = function() return 0 end,
            getNumVeryCloseZombies = function() return close end,
        }
    end,
    getMoodles = function() return { Update = function() end } end,
    getSpottedList = function() return makeList(spotted) end,
    getLastSpotted = function() return makeList(lastSpotted) end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getCell = function()
        return {
            getZombieList = function()
                return makeList({ managedBody })
            end,
        }
    end,
    updateLOS = function()
        visible = 0
        close = 0
        for _, body in ipairs(spotted) do
            if body.isZombie and body:isZombie()
                and (not body.isReanimatedForGrappleOnly
                    or not body:isReanimatedForGrappleOnly())
            then
                visible = visible + 1
                close = close + 1
            end
        end
    end,
}

local ordinaryZombie = {
    getModData = function() return {} end,
    isZombie = function() return true end,
    isAlive = function() return true end,
    isDead = function() return false end,
    getX = function() return 2 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
}

PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return body == managedBody
        end,
    },
}
CharacterStat = { PANIC = "panic" }
instanceof = function(body, className)
    return className == "IsoZombie" and body and body.isZombie and body:isZombie()
end
Events = {
    OnPlayerUpdate = { Add = function() end },
    OnTick = { Add = function() end },
    OnResetLua = { Add = function() end },
}
getNumActivePlayers = function() return 1 end
getSpecificPlayer = function() return player end
isClient = function() return false end
isServer = function() return true end

T.load(THREAT_FILE)
local safeguards = PNC.HumanNPCThreatSafeguards
safeguards.CapturePanicBaseline(player, true)
spotted[1] = managedBody

safeguards.OnPlayerUpdate(player)
player:updateLOS()
safeguards.OnTick()
T.equal(visible, 0, "authority LOS excludes managed human bodies")
T.equal(close, 0, "authority close counter excludes managed human bodies")
T.equal(panic, 2, "authority panic does not increase for managed human bodies")
T.falsy(grappleOnly, "authority LOS lease restores the native flag")

spotted[2] = ordinaryZombie
panic = 3
safeguards.OnPlayerUpdate(player)
player:updateLOS()
safeguards.OnTick()
T.equal(visible, 1, "authority LOS keeps ordinary zombies")
T.equal(close, 1, "authority close counter keeps ordinary zombies")
T.equal(panic, 3, "authority panic remains available for ordinary zombies")
T.falsy(grappleOnly, "authority lease does not leak with ordinary zombies")

T.finish("pnc_human_npc_threat_shared_smoke")

local T = require "tests/support/test"

T.addPackagePaths()

local bodyOne = {
    getOnlineID = function() return 77 end,
    getModData = function() return { PNC_UUID = "npc_one" } end,
    isDead = function() return false end,
}
local bodyTwo = {
    getOnlineID = function() return 77 end,
    getModData = function() return { PNC_UUID = "npc_two" } end,
    isDead = function() return false end,
}
local bodies = { bodyOne, bodyTwo }

local zombieList = {
    size = function() return #bodies end,
    get = function(_, index) return bodies[index + 1] end,
}

getCell = function()
    return { getZombieList = function() return zombieList end }
end

PNC = {
    Const = {
        WORLD_CENSUS_REFRESH_MS = 100,
        WORLD_CENSUS_IDLE_REFRESH_MS = 500,
    },
    Core = {
        Now = function() return 1000 end,
        GenerateID = function(prefix) return tostring(prefix) .. ":generated" end,
        IsManagedNPCBody = function() return true end,
    },
    Network = {
        GetZombieOnlineID = function(zombie)
            return zombie:getOnlineID()
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/World/PNC_WorldCensus.lua")
local Census = PNC.WorldCensus
T.equal(Census.FindByOnlineID(77, 1000), nil,
    "ambiguous online ID fails closed in world census")

T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/PNC_NameplateBodies.lua")
local index = PNC.NameplateBodies.Index(zombieList)
T.equal(index.byOnlineID["77"], false,
    "nameplate index records online-ID collision")
T.equal(PNC.NameplateBodies.Resolve(index, "npc_one", {
    liveBodyOnlineID = 77,
}), bodyOne, "nameplate resolver falls back to UUID identity")

T.finish("pnc_world_census_identity_smoke")

local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local now = 1000

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_AGGRO_RADIUS = 12,
        ZOMBIE_AGGRO_ACTIVE_REFRESH_MS = 250,
        ZOMBIE_AGGRO_ACTIVE_TTL_MS = 1500,
        ZOMBIE_AGGRO_MAX_PER_TICK = 10,
        ZOMBIE_AGGRO_PATH_REQUESTS_PER_TICK = 3,
        ZOMBIE_NPC_AGGRO_LEASE_MS = 1000,
    },
    Core = {
        Now = function() return now end,
        GenerateID = function() return "unused" end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        IsManagedNPCBody = function() return false end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Stealth = {},
    Registry = {
        ForEachLive = function() end,
        GetLiveZombie = function() return nil end,
        Get = function() return nil end,
    },
    SpatialIndex = {
        QueryZombies = function() return {} end,
        QueryNPCs = function() return {} end,
    },
}

dofile(ROOT .. "Zombies/PNC_ZombieAggro_State.lua")
dofile(ROOT .. "Zombies/PNC_ZombieAggro_ActiveSet.lua")

local zombies = {}
for i = 1, 100 do
    zombies[i] = {
        isDead = function() return false end,
        getSquare = function() return true end,
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getModData = function(self)
            self.data = self.data or { PNC_ZombieID = "z_" .. tostring(i) }
            return self.data
        end,
    }
    assert(PNC.ZombieAggro.Activate(zombies[i], now, "test"),
        "failed to activate zombie")
end

local processed = 0
local pathRequests = 0
local first = PNC.ZombieAggro.PumpActiveSet(now, function()
    processed = processed + 1
    if PNC.ZombieAggro.ConsumePathRequestBudget() then
        pathRequests = pathRequests + 1
    end
end)
assert(first == 10 and processed == 10,
    "active aggro processing exceeded its per-tick budget")
assert(pathRequests == 3,
    "zombie pursuit path budget was not enforced")

local second = PNC.ZombieAggro.PumpActiveSet(now, function()
    processed = processed + 1
end)
assert(second == 10 and processed == 20,
    "active aggro cursor did not continue through the bounded set")

now = 3000
local expired = PNC.ZombieAggro.PumpActiveSet(now, function()
    error("expired zombie was processed")
end)
assert(expired == 0, "expired active zombies were retained")

print("pnc_zombie_aggro_budget_smoke: ok")

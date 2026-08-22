local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")
T.addPackagePaths()

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
local dirty = false
local facilities = {
    water = { id = "water", baseId = "base", definitionId = "water_collector",
        level = 1, constructionState = "BUILT", cachedState = "OPERATIONAL",
        componentIds = { spigot = true, tank = true, catcher1 = true,
            catcher2 = true } },
}
local components = {
    spigot = { id = "spigot", role = "water.spigot" },
    tank = { id = "tank", role = "water.tank" },
    catcher1 = { id = "catcher1", role = "water.catcher" },
    catcher2 = { id = "catcher2", role = "water.catcher" },
}
PNC = { SettlementRepository = {
    State = { facilities = facilities }, Load = function() end,
    GetFacility = function(id) return facilities[id] end,
    GetComponent = function(id) return components[id] end,
    MarkDirty = function() dirty = true end,
} }
Events = { EveryTenMinutes = { Add = function() end } }
getGameTime = function()
    return { getWorldAgeHours = function() return 10 end }
end

local Service = T.load(ROOT .. "server/PNC/Settlement/PNC_WaterUtilityService.lua")
Service.Tick(10, false)
Service.Tick(10 + 1 / 6, true)
local snapshot = Service.BuildSnapshot("base")
T.truthy(snapshot.waterLiters == 2, "two catchers should add two liters per ten minutes")
T.truthy(snapshot.capacityLiters == 25, "one tank should hold 25 liters")
T.truthy(snapshot.litersPerTenMinutes == 2, "catcher rate missing from snapshot")
T.truthy(dirty, "water changes should mark settlement persistence dirty")
local ok, remaining = Service.Consume("water", 1)
T.truthy(ok and remaining == 1, "stored water should be consumable")
T.finish("pnc_water_utility_smoke")

T.finish("pnc_water_utility_smoke")

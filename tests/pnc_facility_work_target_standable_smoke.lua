-- A stockpile reconstruct used to block at 0% with the Constructor one tile away
-- from the goal. The work target for a region facility was the region's first
-- tile, which the stockpile's own containers occupy, so the engine reported
-- native_path_unreachable forever. Region work targets must be standable.
local T = require "tests/support/test"

T.addPackagePaths()

local standable = {}
local function mark(x, y, z) standable[x .. ":" .. y .. ":" .. z] = true end

local squares = {}
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function() return true end,
        containsPoint = function() return true end,
        countTiles = function() return 1 end,
        normalize = function(region) return region end,
    }
end

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if not standable[x .. ":" .. y .. ":" .. z] then return nil end
            return {
                hasFloor = function() return true end,
                isFree = function() return true end,
            }
        end,
    }
end

PNC = {
    World = { SquareRules = nil },
    SettlementRepository = {},
    FacilityValidationService = {},
    FacilityDefinitions = { RequiresWorkZone = function() return false end },
    FacilityCostService = {},
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityService/PNC_FacilityService_Targets.lua")

-- Stockpile-shaped region: a 3x3 block whose corner tile is the one the old
-- resolver returned, occupied by the storage containers.
local region = { levels = { [0] = { rows = {} } } }
for y = 11280, 11282 do
    region.levels[0].rows[y] = { 7900, 7902 }
end

local facility = { id = "facility:stockpile",
    constructionRegion = region, componentIds = {} }

-- Nothing standable at all: fall back to the previous behaviour (the region's
-- first tile) rather than reporting no target.
local point, reason = Service.ResolveWorkTarget(facility)
T.truthy(point ~= nil, "work target still resolves when nothing is standable")
T.falsy(reason ~= nil, "a fallback target reports no reason")
T.equal(point.x, 7900, "fallback keeps the region's first tile")

-- A free tile elsewhere inside the region is preferred.
mark(7901, 11281, 0)
point = Service.ResolveWorkTarget(facility)
T.truthy(point ~= nil, "region scan produced a target")
T.equal(point.x, 7901, "free tile inside the region is used")
T.equal(point.y, 11281, "free tile inside the region is used (y)")
T.equal(point.role, "facility.footprint",
    "region target keeps the footprint role")

-- Only a neighbour is free: expand outwards from the region.
standable = {}
mark(7903, 11280, 0)
point = Service.ResolveWorkTarget(facility)
T.truthy(point ~= nil, "neighbour scan produced a target")
T.equal(point.x, 7903, "adjacent standable tile is used")
T.truthy(point.adjacentToRegion == true,
    "adjacent target is flagged as outside the region")

T.finish("pnc_facility_work_target_standable_smoke")

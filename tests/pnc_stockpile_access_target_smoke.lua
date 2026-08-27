local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local zone = { geometry = { id = "base-zone" } }
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { get = function(id) return id == "zone:1" and zone or nil end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function(_, x, y)
            return x >= 0 and x <= 20 and y >= 0 and y <= 20
        end,
        containsPoint = function(_, x, y, z)
            return z == 0 and x >= 0 and x <= 20 and y >= 0 and y <= 20
        end,
    }
end

local blockedX, blockedY = 10, 10
local square = {
    isSolid = function() return false end,
    isSolidTrans = function() return false end,
    isFree = function(_, ignore) return ignore == false end,
}
getCell = function()
    return {
        getGridSquare = function(_, x, y)
            return x >= 9 and x <= 12 and y >= 9 and y <= 12
                and square or nil
        end,
    }
end

PNC = {
    BaseService = {
        Get = function(id)
            return id == "base:1" and {
                id = "base:1", baseZoneId = "zone:1",
                stockpileNodeIds = {}, facilityIds = { ["facility:1"] = true },
            } or nil
        end,
    },
    SettlementRepository = {
        GetComponent = function(id)
            return id == "component:stockpile" and {
                role = "storage.stockpile",
                region = { levels = { [0] = { rows = { [10] = { 10, 10 } } } } },
            } or nil
        end,
        GetFacility = function(id)
            return id == "facility:1" and {
                id = "facility:1", definitionId = "stockpile",
                constructionState = "BUILT",
                componentIds = { ["component:stockpile"] = true },
            } or nil
        end,
        GetStockpileNode = function() return nil end,
    },
    PathService = {
        Internal = {
            isSquareWalkable = function(x, y)
                return not (x == blockedX and y == blockedY)
            end,
        },
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_StockpileAccessService.lua")

local access = Service.FindNearest("base:1", 0, 0, 0, {
    requireLoaded = true,
})
T.truthy(access, "a loaded stockpile access point is found")
T.equal(access.facilityId, "facility:1", "facility supplies the access point")
T.equal(access.x, 9, "blocked stockpile tile uses an adjacent access x")
T.equal(access.y, 10, "adjacent access remains aligned with the stockpile")

local unloadedCell = getCell
getCell = function() return { getGridSquare = function() return nil end } end
T.falsy(Service.FindNearest("base:1", 0, 0, 0, {
    requireLoaded = true,
}), "live work does not target an unloaded stockpile")
getCell = unloadedCell

T.finish("pnc_stockpile_access_target_smoke")

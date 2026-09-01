local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local baseZone = { geometry = { id = "base-zone" } }
local region = { levels = { [0] = { rows = { [10] = { 30, 31 } } } } }
local square = {
    isSolid = function() return false end,
    isSolidTrans = function() return false end,
    isFree = function(_, ignore) return ignore == false end,
}

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { get = function(id) return id == "zone:1" and baseZone or nil end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function(_, x, y)
            return x >= 0 and x <= 20 and y >= 0 and y <= 20
        end,
        containsPoint = function(_, x, y, z)
            return z == 0 and x >= 30 and x <= 31 and y == 10
        end,
    }
end

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return z == 0 and x >= 30 and x <= 31 and y == 10 and square or nil
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
        State = { components = {} },
        GetComponent = function(id)
            return id == "component:stockpile" and {
                role = "storage.stockpile", region = region,
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
        Internal = { isSquareWalkable = function() return true end },
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_StockpileAccessService.lua")
local access = Service.FindNearest("base:1", 30, 10, 0, {
    requireLoaded = true,
})
T.truthy(access, "facility access can be outside the base geometry")
T.equal(access.x, 30, "external region tile is a valid access target")
T.truthy(Service.ContainsFacilityRegionTile("facility:1", 31, 10, 0),
    "drop validation uses stockpile region membership")

local Validation = { Internal = {} }
Validation.Internal.Result = function(ok, reason, details)
    return { ok = ok, reason = reason, details = details }
end
Validation.Internal.LevelDefinition = function()
    return { componentLimits = {
        ["storage.stockpile"] = { kind = "region", minCount = 1,
            maxCount = 1, minTotalTiles = 1, maxTotalTiles = 1000 },
    } }
end
Validation.Internal.BaseContainsRegion = function() return false end
Validation.Internal.FacilityContainsRegion = function() return false end
Validation.Internal.ComponentStats = function()
    return { ["storage.stockpile"] = 1 }, { ["storage.stockpile"] = 2 }
end
Validation.Internal.WorkZoneTouchesFacility = function() return false end
PNC.FacilityValidationService = Validation
PNC.FacilityDefinitions = {
    GetComponentLimit = function()
        return { kind = "region", minCount = 1, maxCount = 1,
            minTotalTiles = 1, maxTotalTiles = 1000 }
    end,
}
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function() return false end,
        containsPoint = function(_, x, y, z)
            return z == 0 and x >= 30 and x <= 31 and y == 10
        end,
        validate = function(value) return true, nil, value end,
        isConnected = function() return true end,
        countTiles = function() return 2 end,
        intersects = function() return false end,
        subtract = function(region) return region end,
        isConnected = function() return true end,
    }
end
-- The component validator is loaded after the access service; invalidate the
-- earlier preload so its require observes the test's validation functions.
package.loaded["PsychopatzCore/World/PC_GridRegion"] = nil
T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityValidationService/PNC_FacilityValidationService_Components.lua")
local check = PNC.FacilityValidationService.NormalizeComponent(
    { id = "base:1" },
    { id = "facility:1", definitionId = "stockpile", constructionRegion = {} },
    { id = "component:stockpile", kind = "region", role = "storage.stockpile",
        region = region }
)
T.truthy(check.ok, "external stockpile region passes component validation")

PNC.BaseValidationService = {
    Internal = {
        Result = function(ok, reason, details)
            return { ok = ok, reason = reason, details = details }
        end,
    },
    ProjectFootprint = function(value) return value end,
}
PNC.SettlementDefinitions = {
    GetTerritoryCapacity = function() return 100 end,
}
package.loaded["PsychopatzCore/World/PC_GridRegion"] = nil
T.load("ProjectHoomans", "server",
    "PNC/Settlement/BaseValidationService/PNC_BaseValidationService_Territory.lua")
local territoryCheck = PNC.BaseValidationService.CanChange(
    PNC.BaseService.Get("base:1"),
    { levels = { [0] = { rows = { [10] = { 30, 31 } } } } },
    { levels = { [0] = { rows = { [10] = { 30, 31 } } } } },
    "REMOVE"
)
T.truthy(territoryCheck.ok,
    "external stockpile region does not block base territory shrinking")

T.finish("pnc_stockpile_outside_base_smoke")

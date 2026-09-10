local T = require "tests/support/test"

local GridRegion = {
    countTiles = function(region)
        return tonumber(region and region.tileCount) or 0
    end,
    union = function(a, b)
        return {
            tileCount = (tonumber(a and a.tileCount) or 0)
                + (tonumber(b and b.tileCount) or 0),
        }
    end,
    subtract = function(a, b)
        return {
            tileCount = math.max(0,
                (tonumber(a and a.tileCount) or 0)
                - (tonumber(b and b.tileCount) or 0)),
        }
    end,
}

local selectorOptions
local createRequest
local expandRequest
local snapshot = {}

package.preload["PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        SettlementReason = function(reason) return tostring(reason or "") end,
    }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return GridRegion
end
package.preload["PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"] = function()
    return {
        EmptyRegion = function() return { tileCount = 0 } end,
        BaseRegion = function(window) return window.baseRegion end,
        Footprint = function(region) return region end,
        ValidateConnected = function(region)
            return GridRegion.countTiles(region) > 0
        end,
        OpenSelector = function(_, options)
            selectorOptions = options
            return options
        end,
    }
end

PNC = {
    CommandHub = {},
    SettlementDefinitions = { STARTING_TERRITORY = 270 },
    ColonyManagementClient = {
        ReadSnapshot = function()
            return { snapshot = snapshot }
        end,
    },
    Client = {
        RequestCreateBase = function(options)
            createRequest = options
            return true, "sent", "create-request-1"
        end,
        RequestExpandBase = function(options)
            expandRequest = options
            return true, "sent", "expand-request-1"
        end,
    },
}

getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end

local Territory = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_BaseTerritoryActions.lua")

local window = {}
snapshot = {
    colony = { id = "colony-old", factionID = "faction-old" },
}
local selector = Territory.Begin(window, "create")
T.truthy(selector, "create territory selector did not open")
T.equal(selectorOptions.debugLabel, "base_territory_create",
    "create selector is missing its Command Hub identity")

snapshot.colony = { id = "colony-new", factionID = "faction-new" }
T.truthy(selectorOptions.onConfirm({ tileCount = 12 }),
    "create selector rejected a valid request")
T.equal(createRequest.colonyId, "colony-new",
    "create request used the stale colony id captured at selector open")
T.equal(createRequest.factionId, "faction-new",
    "create request used the stale faction captured at selector open")
T.equal(window.baseTerritoryRequestID, "create-request-1",
    "create request id was not retained for the async result")

T.truthy(Territory.ApplyResult(window, {
    actionResult = {
        action = "base_create", requestId = "create-request-1", ok = true,
    },
}), "create result was not applied to the Base status surface")
T.falsy(Territory.ApplyResult(window, {
    actionResult = {
        action = "base_create", requestId = "create-request-1", ok = true,
    },
}), "the same territory result was applied twice")

window.baseRegion = { tileCount = 20 }
snapshot = {
    colony = { id = "colony-new", factionID = "faction-new" },
    settlement = {
        id = "base-1", revision = 1,
        territory = { territoryCapacity = 100 },
    },
}
selector = Territory.Begin(window, "expand")
T.truthy(selector, "expand territory selector did not open")
snapshot.settlement.revision = 7
T.truthy(selectorOptions.onConfirm({ tileCount = 3 }),
    "expand selector rejected a valid request")
T.equal(expandRequest.baseId, "base-1",
    "expand request lost the current base id")
T.equal(expandRequest.expectedRevision, 7,
    "expand request used the stale revision captured at selector open")
T.equal(window.baseTerritoryRequestID, "expand-request-1",
    "expand request id was not retained for the async result")

T.finish("pnc_command_hub_base_territory_smoke")

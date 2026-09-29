-- Placement validity used to resolve the settlement from the colony-management
-- projection only. The Base window polls its own lighter projection, so a
-- session that had not refreshed management rejected every tile as outside the
-- base, making placement impossible with nothing in the log.
local T = require "tests/support/test"

local insideBase = true

package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function() return insideBase end,
        containsPoint = function() return insideBase end,
        countTiles = function() return 1 end,
        normalize = function(region) return region end,
    }
end
package.preload["PNC/Core/Settlement/PNC_BuildingFootprint"] = function()
    return { ForEachTile = function() end, FromCursor = function() return {} end }
end
package.preload["PNC/Core/Settlement/PNC_BuildingQueueCollision"] = function()
    return { Find = function() return nil, nil end }
end

local region = { levels = { [0] = { rows = { [10] = { 10, 12 } } } } }
PNC = { Network = { ClientState = {
    colonyBase = { settlement = { id = "base:1",
        geometry = { region = region } } },
} } }

local Policy = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingPlacementPolicy.lua")

-- Management projection is empty; the base projection carries the geometry.
local settlement = Policy.CurrentSettlement()
T.truthy(settlement ~= nil,
    "settlement is not resolved from the base projection")
T.equal(settlement.id, "base:1", "the base projection settlement is used")
local valid, reason = Policy.ValidateCurrentPoint(10, 10, 0)
T.truthy(valid, "a tile inside the base territory is placeable")
T.falsy(reason, "a placeable tile reports no failure reason")

-- Management wins when it is populated.
PNC.Network.ClientState.colonyManagement = { settlement = { id = "base:2",
    geometry = { region = region } } }
T.equal(Policy.CurrentSettlement().id, "base:2",
    "management projection takes precedence when present")

-- Neither projection: report the missing base instead of silently refusing.
insideBase = false
PNC.Network.ClientState.colonyManagement = nil
PNC.Network.ClientState.colonyBase = nil
T.falsy(Policy.CurrentSettlement() ~= nil,
    "missing projections resolve to no settlement")
valid, reason = Policy.ValidateCurrentPoint(10, 10, 0)
T.falsy(valid, "no settlement means no placement")
T.equal(reason, "BUILD_BASE_UNAVAILABLE",
    "missing settlement reports an actionable reason")

T.finish("pnc_building_placement_settlement_source_smoke")

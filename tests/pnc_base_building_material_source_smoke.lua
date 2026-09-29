-- The Facilities tab prices every requirement against the stockpile. It used to
-- read the Base window's own snapshot, which carries no stockpile rows, so a
-- full stockpile still showed "0 in stock" and BUILD stayed disabled.
local T = require "tests/support/test"

T.addPackagePaths()

package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return {
        Probe = function(fullType)
            return { name = tostring(fullType), texture = nil }
        end,
    }
end

-- Player inventory: two stacks of 10 and 2 units for the same type.
local playerItems = {}
local function itemsFor(fullType)
    local list = playerItems[fullType] or {}
    return {
        size = function() return #list end,
        get = function(_, index) return list[index + 1] end,
    }
end
getSpecificPlayer = function()
    return {
        getInventory = function()
            return { getItemsFromType = function(_, fullType)
                return itemsFor(fullType)
            end }
        end,
    }
end

PNC = {
    FacilityDefinitions = {
        Get = function(id)
            if id == "stockpile" then return { bootstrapFromPlayer = true } end
            return { buildCosts = {} }
        end,
    },
    Network = { ClientState = {} },
}

local Data = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingData.lua")

local option = {
    id = "research_table",
    buildMaterials = {
        { fullType = "Base.TreeBranch", amount = 4 },
        { itemTypes = { "Base.Axe", "Base.CrudeAxe" }, amount = 1 },
    },
}

-- 1. Real stockpile rows in the base snapshot, split across two stacks.
local window = { snapshot = { storage = { rows = {
    { fullType = "Base.TreeBranch", quantity = 2 },
    { fullType = "Base.TreeBranch", quantity = 2 },
    { fullType = "Base.Axe", quantity = 1 },
} } } }
local rows = Data.MaterialRows(window, option)
T.equal(#rows, 2, "one row per requirement")
T.equal(rows[1].available, 4, "stacked rows are summed, not maxed")
T.truthy(rows[1].ready, "requirement met by the stockpile is ready")
T.equal(rows[2].available, 1,
    "alternative item types are counted across the group")
T.truthy(rows[2].ready, "alternative type satisfies the requirement")
T.truthy(rows[1].source == "STOCKPILE",
    "non-bootstrap facilities draw from the stockpile")

-- 2. No rows in the base snapshot: fall back to the management projection
--    instead of pricing everything at zero.
PNC.Network.ClientState.colonyManagement = { storage = { rows = {
    { fullType = "Base.TreeBranch", quantity = 9 },
    { fullType = "Base.Axe", quantity = 3 },
} } }
window = { snapshot = {} }
rows = Data.MaterialRows(window, option)
T.equal(rows[1].available, 9, "management snapshot is used as a fallback")
T.truthy(rows[1].ready, "fallback stock still satisfies the requirement")

-- 3. Neither projection carries rows: report honestly as unavailable.
PNC.Network.ClientState.colonyManagement = nil
rows = Data.MaterialRows({ snapshot = {} }, option)
T.equal(rows[1].available, 0, "missing stock reports zero available")
T.falsy(rows[1].ready, "missing stock is not ready")

-- 4. Bootstrap facilities are paid from the player, by unit not by stack.
playerItems = { ["Base.Plank"] = {
    { getCount = function() return 6 end },
    { getCount = function() return 4 end },
} }
local bootstrap = {
    id = "stockpile",
    buildMaterials = { { fullType = "Base.Plank", amount = 10 } },
}
rows = Data.MaterialRows({ snapshot = {} }, bootstrap)
T.equal(rows[1].available, 10, "player units are summed across stacks")
T.truthy(rows[1].ready, "player stock satisfies the bootstrap cost")
T.truthy(rows[1].source == "PLAYER",
    "bootstrap facilities are paid from the player")

-- 5. Data.Stockpile prefers live base rows and falls back cleanly.
PNC.Network.ClientState.colonyManagement = { storage = { rows = {} } }
local stocked = { rows = { { fullType = "Base.Plank", quantity = 1 } } }
T.equal(Data.Stockpile({ snapshot = { storage = stocked } }).rows[1].quantity,
    1, "base rows win when present")

-- 6. The Base window's own snapshot must carry the stockpile projection, or the
--    client has nothing to price requirements against.
local snapshots = T.read("ProjectHoomans", "server",
    "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots.lua")
T.contains(snapshots, "storage = storage",
    "base snapshot does not ship the stockpile projection")
T.contains(snapshots, "includeRows = true",
    "base snapshot ships the stockpile without its rows")

T.finish("pnc_base_building_material_source_smoke")

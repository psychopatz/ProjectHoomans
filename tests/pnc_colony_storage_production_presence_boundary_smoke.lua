local T = require "tests/support/test"

local path =
    "PNC/Colony/Storage/ColonyStorageService/" ..
    "PNC_ColonyStorageService_Production.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix =
    "PNC/Colony/Storage/ColonyStorageService/" ..
    "ColonyStorageService_Production/"
local providers = {
    "PNC_ColonyStorageService_Production_Core",
    "PNC_ColonyStorageService_Production_Reservations",
    "PNC_ColonyStorageService_Production_Transactions",
    "PNC_ColonyStorageService_Production_Transfers",
    "PNC_ColonyStorageService_Production_Queries",
}

local previous = 0
local publicFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    for name in providerSource:gmatch(
        "function%s+Service%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] =
    function() return {} end
package.preload[
    "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
] = function() return {} end
PNC = {
    ColonyStorageService = { Internal = {} },
    ColonyStorageRepository = {},
}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.ColonyStorageService[name]), "function",
        "entry point preserves ColonyStorageService." .. name)
end
T.equal(publicCount, 14, "storage-production public function count")
T.equal(type(PNC.ColonyStorageService.ProductionReservations), "table",
    "production reservation state remains initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] = nil
package.preload[
    "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
] = nil

T.finish("pnc_colony_storage_production_presence_boundary_smoke")

local T = require "tests/support/test"

local path = "PNC/Supply/PNC_SupplyInventory.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Supply/SupplyInventory/"
local providers = {
    "PNC_SupplyInventory_CoreRecords",
    "PNC_SupplyInventory_NativeMatching",
    "PNC_SupplyInventory_Consumption",
    "PNC_SupplyInventory_Removal",
    "PNC_SupplyInventory_PersonalQueries",
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
        "function%s+SupplyInventory%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

local dependencies = {
    "PsychopatzCore/Inventory/PsychopatzInventory",
    "PsychopatzCore/Inventory/PsychopatzItemRecord",
    "PNC/Core/Inventory/PNC_Inventory/Persistence/" ..
        "PNC_Inventory_CoreStateCodec",
    "PsychopatzCore/Inventory/PsychopatzInventoryConstants",
    "PsychopatzCore/Inventory/PsychopatzInventoryUtil",
    "PsychopatzCore/Events/PC_EventBus",
    "PNC/Core/Events/PNC_EventDefinitions",
}
for i = 1, #dependencies do
    package.preload[dependencies[i]] = function() return {} end
end
PNC = { Inventory = { Commands = {} } }
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.SupplyInventory[name]), "function",
        "entry point preserves SupplyInventory." .. name)
end
T.equal(publicCount, 6, "supply-inventory public function count")
T.equal(type(PNC.SupplyInventory.Commands), "table",
    "supply command facade remains initialized")
T.equal(type(PNC.SupplyInventory.Queries), "table",
    "supply query facade remains initialized")
T.equal(PNC.SupplyInventory.Commands.Consume,
    PNC.SupplyInventory.Consume, "consume command remains wired")
T.equal(PNC.SupplyInventory.Queries.FindPersonal,
    PNC.SupplyInventory.QueryPersonal, "personal query remains wired")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
for i = 1, #dependencies do
    package.loaded[dependencies[i]] = nil
    package.preload[dependencies[i]] = nil
end

T.finish("pnc_supply_inventory_presence_boundary_smoke")

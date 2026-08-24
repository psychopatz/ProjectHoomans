local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Server/PNC_ServerInventory.lua")
local prefix = "PNC/Server/ServerInventory/"
local providers = {
    "PNC_ServerInventory_Context",
    "PNC_ServerInventory_NativeItems",
    "PNC_ServerInventory_CompactItems",
    "PNC_ServerInventory_PlayerToNPC",
    "PNC_ServerInventory_NPCToPlayer",
    "PNC_ServerInventory_GiftEffects",
    "PNC_ServerInventory_Transfer",
    "PNC_ServerInventory_Actions",
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

PNC = {}
package.preload["PNC/00_PNC_Init"] = function() return PNC end
package.preload[
    "PsychopatzCore/Inventory/PsychopatzItemTransfer"
] = function()
    return {}
end
T.load("ProjectHoomans", "server", "PNC/Server/PNC_ServerInventory.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.ServerInventory[name]), "function",
        "entry point should preserve ServerInventory." .. name)
end
T.equal(publicCount, 2, "server-inventory function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PNC/00_PNC_Init"] = nil
package.preload[
    "PsychopatzCore/Inventory/PsychopatzItemTransfer"
] = nil

T.finish("pnc_server_inventory_presence_boundary_smoke")

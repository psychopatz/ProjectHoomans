local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Supply/PNC_NPCSupplyService.lua")
local prefix = "PNC/Supply/NPCSupplyService/"
local providers = {
    "PNC_NPCSupplyService_Context",
    "PNC_NPCSupplyService_Acquisition",
    "PNC_NPCSupplyService_Personal",
    "PNC_NPCSupplyService_Process",
    "PNC_NPCSupplyService_Queries",
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

PNC = { SupplyInventory = { Commands = {}, Queries = {} } }
package.preload[
    "PsychopatzCore/Inventory/PsychopatzInventory"
] = function() return {} end
package.preload[
    "PNC/Colony/Storage/PNC_ColonyStorageRepository"
] = function() return {} end
package.preload["PsychopatzCore/Events/PC_EventBus"] =
    function() return {} end
package.preload["PNC/Core/Events/PNC_EventDefinitions"] =
    function() return {} end
T.load("ProjectHoomans", "server", "PNC/Supply/PNC_NPCSupplyService.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.NPCSupplyService[name]), "function",
        "entry point preserves NPCSupplyService." .. name)
end
T.equal(publicCount, 5, "NPC-supply-service function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload[
    "PsychopatzCore/Inventory/PsychopatzInventory"
] = nil
package.preload[
    "PNC/Colony/Storage/PNC_ColonyStorageRepository"
] = nil
package.preload["PsychopatzCore/Events/PC_EventBus"] = nil
package.preload["PNC/Core/Events/PNC_EventDefinitions"] = nil

T.finish("pnc_npc_supply_service_presence_boundary_smoke")

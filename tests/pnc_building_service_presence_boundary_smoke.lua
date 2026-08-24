local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Production/PNC_BuildingService.lua")
local prefix = "PNC/Production/BuildingService/"
local providers = {
    "PNC_BuildingService_Context",
    "PNC_BuildingService_Snapshot",
    "PNC_BuildingService_Commands",
    "PNC_BuildingService_Preparation",
    "PNC_BuildingService_Placement",
    "PNC_BuildingService_Lifecycle",
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

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] =
    function() return {} end
package.preload["PsychopatzCore/World/PC_GridRegion"] =
    function() return {} end
PNC = {
    BuildRecipeCatalog = {}, WorkRepository = {}, WorkDefinitions = {},
    WorkService = {
        CancellationHandlers = {},
        RegisterTargetProvider = function() end,
        RegisterPreparation = function() end,
        RegisterCompletion = function() end,
    },
}
T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_BuildingService.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.BuildingService[name]), "function",
        "entry point preserves BuildingService." .. name)
end
T.equal(publicCount, 3, "building-service public function count")
T.equal(type(PNC.WorkService.CancellationHandlers.BUILD_OBJECT), "function",
    "building cancellation handler remains registered")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = nil
package.preload["PsychopatzCore/World/PC_GridRegion"] = nil

T.finish("pnc_building_service_presence_boundary_smoke")

local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Farming/PNC_FarmingService.lua")
local prefix = "PNC/Farming/FarmingService/"
local providers = {
    "PNC_FarmingService_Context",
    "PNC_FarmingService_Commands",
    "PNC_FarmingService_Materials",
    "PNC_FarmingService_Snapshots",
    "PNC_FarmingService_Ticks",
    "PNC_FarmingService_Provider",
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
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingService.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FarmingService[name]), "function",
        "entry point preserves FarmingService." .. name)
end
T.equal(publicCount, 8, "farming-service function declaration count")
T.equal(type(PNC.FarmingService.Internal.Provider), "table",
    "farming task provider preserved")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_farming_service_presence_boundary_smoke")

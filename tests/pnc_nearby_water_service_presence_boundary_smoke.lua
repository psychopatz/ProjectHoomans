local T = require "tests/support/test"

local path = "PNC/World/PNC_NearbyWaterService.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/World/NearbyWaterService/"
local providers = {
    "PNC_NearbyWaterService_Core",
    "PNC_NearbyWaterService_Origin",
    "PNC_NearbyWaterService_Approach",
    "PNC_NearbyWaterService_Discovery",
    "PNC_NearbyWaterService_Consumption",
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
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.NearbyWaterService[name]), "function",
        "entry point preserves NearbyWaterService." .. name)
end
T.equal(publicCount, 9, "nearby-water public function count")
T.equal(PNC.NearbyWaterService.RADIUS, 12,
    "nearby-water search radius remains stable")
T.equal(PNC.NearbyWaterService.MAX_DRINK_LITERS, 1,
    "nearby-water drink cap remains stable")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_nearby_water_service_presence_boundary_smoke")

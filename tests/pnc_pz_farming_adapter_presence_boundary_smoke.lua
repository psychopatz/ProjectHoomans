local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Farming/PNC_PZFarmingAdapter.lua")
local prefix = "PNC/Farming/PZFarmingAdapter/"
local providers = {
    "PNC_PZFarmingAdapter_Context",
    "PNC_PZFarmingAdapter_Inspection",
    "PNC_PZFarmingAdapter_PlotActions",
    "PNC_PZFarmingAdapter_Inventory",
    "PNC_PZFarmingAdapter_Cultivation",
    "PNC_PZFarmingAdapter_Research",
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
        "function%s+Adapter%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_PZFarmingAdapter.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.PZFarmingAdapter[name]), "function",
        "entry point preserves PZFarmingAdapter." .. name)
end
T.equal(publicCount, 13, "PZ-farming-adapter function declaration count")
T.equal(type(PNC.PZFarmingAdapter.IsWaterItem), "function",
    "entry point preserves PZFarmingAdapter.IsWaterItem")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_pz_farming_adapter_presence_boundary_smoke")

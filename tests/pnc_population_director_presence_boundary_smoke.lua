local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server",
    "PNC/Director/Population/PNC_PopulationDirector.lua")
local prefix = "PNC/Director/Population/PopulationDirector/"
local providers = {
    "PNC_PopulationDirector_Context",
    "PNC_PopulationDirector_Reconciliation",
    "PNC_PopulationDirector_QueueProcessing",
    "PNC_PopulationDirector_Bootstrap",
    "PNC_PopulationDirector_Initialization",
    "PNC_PopulationDirector_API",
    "PNC_PopulationDirector_Lifecycle",
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
        "function%s+Director%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = { DirectorConfig = { Population = {} } }
T.load("ProjectHoomans", "server",
    "PNC/Director/Population/PNC_PopulationDirector.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.PopulationDirector[name]), "function",
        "entry point should preserve PopulationDirector." .. name)
end
T.equal(publicCount, 10, "population-director function declaration count")
T.equal(type(PNC.PopulationDirector.Metrics), "table",
    "entry point should preserve metrics state")
T.equal(type(PNC.PopulationDirector.RateHistory), "table",
    "entry point should preserve rate history")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_population_director_presence_boundary_smoke")

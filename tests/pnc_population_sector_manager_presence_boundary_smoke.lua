local T = require "tests/support/test"

local source = T.read("ProjectHoomans", "server",
    "PNC/Director/Population/PNC_PopulationSectorManager.lua")
local prefix =
    "PNC/Director/Population/PopulationSectorManager/"
local providers = {
    "PNC_PopulationSectorManager_Core",
    "PNC_PopulationSectorManager_Registry",
    "PNC_PopulationSectorManager_Queries",
    "PNC_PopulationSectorManager_Players",
    "PNC_PopulationSectorManager_Repair",
    "PNC_PopulationSectorManager_Generation",
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
        "function%s+Sectors%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {
    DirectorConfig = { Population = {} },
    AbstractWorldStore = {},
    Core = {},
}
T.load("ProjectHoomans", "server",
    "PNC/Director/Population/PNC_PopulationSectorManager.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.PopulationSectors[name]), "function",
        "entry point preserves PopulationSectors." .. name)
end
T.equal(publicCount, 30, "population-sector public function count")
T.equal(type(PNC.PopulationSectors.Runtime), "table",
    "runtime sector index remains initialized")
T.equal(type(PNC.PopulationSectors.Metrics), "table",
    "population-sector metrics remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_population_sector_manager_presence_boundary_smoke")

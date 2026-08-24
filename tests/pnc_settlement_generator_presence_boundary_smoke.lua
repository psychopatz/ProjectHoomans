local T = require "tests/support/test"

local path = "PNC/Director/Population/PNC_SettlementGenerator.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Director/Population/SettlementGenerator/"
local providers = {
    "PNC_SettlementGenerator_Factions",
    "PNC_SettlementGenerator_Planning",
    "PNC_SettlementGenerator_Validation",
    "PNC_SettlementGenerator_Commit",
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
        "function%s+Generator%.([%w_]+)%s*%("
    ) do publicFunctions[name] = true end
end

PNC = {
    DirectorConfig = { Population = {} }, PopulationSectors = {},
    SettlementCandidates = {}, AbstractLocations = {},
    AbstractWorldStore = {}, PopulationIdentity = {},
}
local Generator = T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(Generator[name]), "function",
        "entry point preserves SettlementGenerator." .. name)
end
T.equal(publicCount, 4, "settlement-generator public function count")
T.equal(type(Generator.Metrics), "table", "generator metrics remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_settlement_generator_presence_boundary_smoke")

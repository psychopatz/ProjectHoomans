local T = require "tests/support/test"

local path = "PNC/Factions/PNC_FactionTollService.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Factions/FactionTollService/"
local providers = {
    "PNC_FactionTollService_Core",
    "PNC_FactionTollService_Money",
    "PNC_FactionTollService_Relationships",
    "PNC_FactionTollService_Responses",
    "PNC_FactionTollService_Pump",
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
        "function%s+Tolls%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FactionTolls[name]), "function",
        "entry point preserves FactionTolls." .. name)
end
T.equal(publicCount, 2, "faction-toll public function count")
T.equal(type(PNC.FactionTolls.PendingByPlayerKey), "table",
    "pending demands remain initialized")
T.equal(type(PNC.FactionTolls.InsideByPlayerKey), "table",
    "inside-state map remains initialized")
T.equal(type(PNC.FactionTolls.DepartureByPlayerKey), "table",
    "departure-state map remains initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_faction_toll_service_presence_boundary_smoke")

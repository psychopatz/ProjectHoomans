local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Factions/PNC_FactionIncidentService.lua")
local prefix = "PNC/Factions/FactionIncidentService/"
local providers = {
    "PNC_FactionIncidentService_Context",
    "PNC_FactionIncidentService_Escalation",
    "PNC_FactionIncidentService_IncidentMutation",
    "PNC_FactionIncidentService_AttackPreflight",
    "PNC_FactionIncidentService_AttackAggregation",
    "PNC_FactionIncidentService_Runtime",
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
T.load("ProjectHoomans", "server", "PNC/Factions/PNC_FactionIncidentService.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FactionIncidentService[name]), "function",
        "entry point should preserve FactionIncidentService." .. name)
end
T.equal(publicCount, 6, "faction-incident function declaration count")
T.equal(type(PNC.FactionIncidentService.RuntimeEpisodes), "table",
    "entry point should preserve runtime episodes")
T.equal(type(PNC.FactionIncidentService.RuntimeCallbackIDs), "table",
    "entry point should preserve callback dedupe state")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_faction_incident_service_presence_boundary_smoke")

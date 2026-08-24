local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Factions/PNC_FactionDebug.lua")
local prefix = "PNC/Factions/FactionDebug/"
local providers = {
    "PNC_FactionDebug_Core",
    "PNC_FactionDebug_Summaries",
    "PNC_FactionDebug_NPCDiagnostics",
    "PNC_FactionDebug_Snapshots",
    "PNC_FactionDebug_ActionCreation",
    "PNC_FactionDebug_ActionMembership",
    "PNC_FactionDebug_ActionDiplomacy",
    "PNC_FactionDebug_ActionDiagnostics",
    "PNC_FactionDebug_ActionIncidents",
    "PNC_FactionDebug_Router",
    "PNC_FactionDebug_Formatting",
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
        "function%s+Debug%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Factions/PNC_FactionDebug.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FactionDebug[name]), "function",
        "entry point should preserve FactionDebug." .. name)
end
T.equal(publicCount, 5, "public function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_faction_debug_presence_boundary_smoke")

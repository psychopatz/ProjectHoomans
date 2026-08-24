local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Factions/PNC_FactionBehavior.lua")
local prefix = "PNC/Factions/FactionBehavior/"
local providers = {
    "PNC_FactionBehavior_Context",
    "PNC_FactionBehavior_Intent",
    "PNC_FactionBehavior_OrderPlanning",
    "PNC_FactionBehavior_Application",
    "PNC_FactionBehavior_ReconciliationQueue",
    "PNC_FactionBehavior_ReconciliationPump",
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
        "function%s+Behavior%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Factions/PNC_FactionBehavior.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FactionBehavior[name]), "function",
        "entry point should preserve FactionBehavior." .. name)
end
T.equal(publicCount, 10, "faction-behavior function declaration count")
T.equal(type(PNC.FactionBehavior.ReconciliationQueue), "table",
    "entry point should preserve reconciliation queue state")
T.equal(type(PNC.FactionBehavior.ReconciliationKeys), "table",
    "entry point should preserve reconciliation key state")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_faction_behavior_presence_boundary_smoke")

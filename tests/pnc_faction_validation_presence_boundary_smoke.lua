local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Factions/PNC_FactionValidation.lua")
local prefix = "PNC/Factions/FactionValidation/"
local providers = {
    "PNC_FactionValidation_Context",
    "PNC_FactionValidation_Relations",
    "PNC_FactionValidation_Factions",
    "PNC_FactionValidation_Registry",
    "PNC_FactionValidation_Repair",
    "PNC_FactionValidation_Scenarios",
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
        "function%s+Validation%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Factions/PNC_FactionValidation.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FactionValidation[name]), "function",
        "entry point preserves FactionValidation." .. name)
end
T.equal(publicCount, 5, "faction-validation function declaration count")
T.equal(#PNC.FactionValidation.Scenarios, 14,
    "faction-validation scenario catalog preserved")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_faction_validation_presence_boundary_smoke")

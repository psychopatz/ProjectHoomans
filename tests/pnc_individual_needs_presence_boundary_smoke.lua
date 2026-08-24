local T = require "tests/support/test"

local path = "PNC/Needs/PNC_IndividualNeeds.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Needs/IndividualNeeds/"
local providers = {
    "PNC_IndividualNeeds_Core",
    "PNC_IndividualNeeds_Actions",
    "PNC_IndividualNeeds_Evolution",
    "PNC_IndividualNeeds_Lifecycle",
}

local previous = 0
local directFunctions = {}
local commandFunctions = {}
local queryFunctions = {}
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
        "function%s+Needs%.([%w_]+)%s*%("
    ) do directFunctions[name] = true end
    for name in providerSource:gmatch(
        "function%s+Needs%.Commands%.([%w_]+)"
    ) do commandFunctions[name] = true end
    for name in providerSource:gmatch(
        "function%s+Needs%.Queries%.([%w_]+)"
    ) do queryFunctions[name] = true end
end

package.preload["PsychopatzCore/Events/PC_EventBus"] = function()
    return { emit = function() end }
end
PNC = {
    NeedsDefinitions = {}, NeedsUtils = {}, PlayerNeedsModel = {},
    EventTypes = {},
}
local Needs = T.load("ProjectHoomans", "server", path)

local directCount = 0
for name in pairs(directFunctions) do
    directCount = directCount + 1
    T.equal(type(Needs[name]), "function",
        "entry point preserves IndividualNeeds." .. name)
end
T.equal(directCount, 21, "individual-needs direct function count")
local commandCount = 0
for name in pairs(commandFunctions) do
    commandCount = commandCount + 1
    T.equal(type(Needs.Commands[name]), "function",
        "entry point preserves IndividualNeeds.Commands." .. name)
end
T.equal(commandCount, 3, "individual-needs command function count")
local queryCount = 0
for name in pairs(queryFunctions) do
    queryCount = queryCount + 1
    T.equal(type(Needs.Queries[name]), "function",
        "entry point preserves IndividualNeeds.Queries." .. name)
end
T.equal(queryCount, 1, "individual-needs query function count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PsychopatzCore/Events/PC_EventBus"] = nil

T.finish("pnc_individual_needs_presence_boundary_smoke")

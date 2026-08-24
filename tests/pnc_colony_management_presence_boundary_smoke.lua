local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Colony/PNC_ColonyManagement.lua")
local prefix = "PNC/Colony/ColonyManagement/"
local providers = {
    "PNC_ColonyManagement_Core",
    "PNC_ColonyManagement_DebugAccess",
    "PNC_ColonyManagement_ColonistActions",
    "PNC_ColonyManagement_FacilityDebug",
    "PNC_ColonyManagement_NearbyWater",
    "PNC_ColonyManagement_DebugNeeds",
    "PNC_ColonyManagement_Snapshots",
    "PNC_ColonyManagement_FactionCommands",
    "PNC_ColonyManagement_ActionSettlement",
    "PNC_ColonyManagement_ActionStorageColonists",
    "PNC_ColonyManagement_ActionProduction",
    "PNC_ColonyManagement_ActionWorkDebug",
    "PNC_ColonyManagement_Router",
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
        "function%s+Management%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = { NeedsDefinitions = {} }
T.load("ProjectHoomans", "server", "PNC/Colony/PNC_ColonyManagement.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.ColonyManagement[name]), "function",
        "entry point should preserve ColonyManagement." .. name)
end
T.equal(publicCount, 5, "public function declaration count")
T.equal(type(PNC.ColonyManagement.CanUseDebug), "function",
    "debug authorization entry")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_colony_management_presence_boundary_smoke")

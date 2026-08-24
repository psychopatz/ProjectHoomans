local T = require "tests/support/test"

local path = "PNC/Director/PNC_AbstractGroupManager.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Director/AbstractGroupManager/"
local providers = {
    "PNC_AbstractGroupManager_Core",
    "PNC_AbstractGroupManager_MobileImport",
    "PNC_AbstractGroupManager_Membership",
    "PNC_AbstractGroupManager_ThreatAndLOD",
    "PNC_AbstractGroupManager_State",
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
        "function%s+Groups%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.AbstractGroups[name]), "function",
        "entry point preserves AbstractGroups." .. name)
end
T.equal(publicCount, 17, "abstract-group-manager public function count")
T.equal(type(PNC.AbstractGroups.Metrics), "table",
    "group metrics remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_abstract_group_manager_presence_boundary_smoke")

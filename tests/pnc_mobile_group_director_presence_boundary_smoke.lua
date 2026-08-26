local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Director/PNC_MobileGroupDirector.lua")
local prefix = "PNC/Director/MobileGroupDirector/"
local providers = {
    "PNC_MobileGroupDirector_Core",
    "PNC_MobileGroupDirector_Sites",
    "PNC_MobileGroupDirector_Members",
    "PNC_MobileGroupDirector_Ambient",
    "PNC_MobileGroupDirector_Generation",
    "PNC_MobileGroupDirector_Relocation",
    "PNC_MobileGroupDirector_Pump",
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
        "function%s+Director%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Director/PNC_MobileGroupDirector.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.MobileGroupDirector[name]), "function",
        "entry point preserves MobileGroupDirector." .. name)
end
T.equal(publicCount, 7, "mobile-group-director public function count")
T.equal(PNC.MobileGroupDirectorInternal.PumpIntervalMs, 5000,
    "pump interval remains initialized before pump provider")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_mobile_group_director_presence_boundary_smoke")

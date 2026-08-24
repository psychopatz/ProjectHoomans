local T = require "tests/support/test"

local path = "PNC/Director/PNC_AbstractLocationManager.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Director/AbstractLocationManager/"
local providers = {
    "PNC_AbstractLocationManager_Core",
    "PNC_AbstractLocationManager_Occupancy",
    "PNC_AbstractLocationManager_Queries",
    "PNC_AbstractLocationManager_Registration",
    "PNC_AbstractLocationManager_LoadedDiscovery",
    "PNC_AbstractLocationManager_MetaDiscovery",
    "PNC_AbstractLocationManager_Nearby",
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
        "function%s+Locations%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.AbstractLocations[name]), "function",
        "entry point preserves AbstractLocations." .. name)
end
T.equal(publicCount, 12, "abstract-location public function count")
T.equal(type(PNC.AbstractLocations.Ref), "function",
    "location reference adapter remains public")
T.equal(type(PNC.AbstractLocations.Cells), "table",
    "location spatial cells remain initialized")
T.equal(type(PNC.AbstractLocations.Membership), "table",
    "location memberships remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_abstract_location_manager_presence_boundary_smoke")

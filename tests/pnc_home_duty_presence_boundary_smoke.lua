local T = require "tests/support/test"

local path = "PNC/Production/PNC_HomeDutyService.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Production/HomeDutyService/"
local providers = {
    "PNC_HomeDutyService_Core",
    "PNC_HomeDutyService_Queries",
    "PNC_HomeDutyService_Commands",
    "PNC_HomeDutyService_Arrivals",
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

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] =
    function() return { get = function() return nil end } end
package.preload["PsychopatzCore/World/PC_GridRegion"] =
    function() return { containsXY = function() return false end } end
PNC = { HomeDutyService = {} }
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.HomeDutyService[name]), "function",
        "entry point preserves HomeDutyService." .. name)
end
T.equal(publicCount, 11, "home-duty public function count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = nil
package.preload["PsychopatzCore/World/PC_GridRegion"] = nil

T.finish("pnc_home_duty_presence_boundary_smoke")

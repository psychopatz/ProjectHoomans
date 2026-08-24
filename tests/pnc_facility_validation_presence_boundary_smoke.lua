local T = require "tests/support/test"

local path = "PNC/Settlement/PNC_FacilityValidationService.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Settlement/FacilityValidationService/"
local providers = {
    "PNC_FacilityValidationService_Core",
    "PNC_FacilityValidationService_Footprint",
    "PNC_FacilityValidationService_Components",
    "PNC_FacilityValidationService_Operational",
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
        "function%s+Validation%.([%w_]+)%s*%("
    ) do publicFunctions[name] = true end
end

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] =
    function() return {} end
package.preload["PsychopatzCore/World/PC_GridRegion"] =
    function() return {} end
PNC = {
    SettlementRepository = {}, FacilityDefinitions = {}, Farming = {},
}
local Validation = T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(Validation[name]), "function",
        "entry point preserves FacilityValidationService." .. name)
end
T.equal(publicCount, 6, "facility-validation public function count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = nil
package.preload["PsychopatzCore/World/PC_GridRegion"] = nil

T.finish("pnc_facility_validation_presence_boundary_smoke")

local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Settlement/PNC_FacilityService.lua")
local prefix = "PNC/Settlement/FacilityService/"
local providers = {
    "PNC_FacilityService_Core",
    "PNC_FacilityService_Creation",
    "PNC_FacilityService_Targets",
    "PNC_FacilityService_Upgrades",
    "PNC_FacilityService_ComponentInternals",
    "PNC_FacilityService_ComponentCommands",
    "PNC_FacilityService_AnchorFinalization",
    "PNC_FacilityService_Removal",
    "PNC_FacilityService_Queries",
    "PNC_FacilityService_Snapshots",
    "PNC_FacilityService_Bootstrap",
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

package.loaded["PsychopatzCore/World/PC_GridRegion"] = {
    intersects = function() return false end,
}
PNC = {
    SettlementRepository = {
        State = { facilities = {}, components = {} },
        Load = function() end,
        MarkDirty = function() end,
        GetFacility = function() return nil end,
        GetComponent = function() return nil end,
    },
    FacilityValidationService = {
        CalculateOperationalState = function() return "OPERATIONAL" end,
    },
    FacilityDefinitions = {},
    BaseService = { Get = function() return nil end },
}
T.load("ProjectHoomans", "server", "PNC/Settlement/PNC_FacilityService.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FacilityService[name]), "function",
        "entry point should preserve FacilityService." .. name)
end
T.equal(publicCount, 17, "public function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.loaded["PsychopatzCore/World/PC_GridRegion"] = nil

T.finish("pnc_facility_service_presence_boundary_smoke")

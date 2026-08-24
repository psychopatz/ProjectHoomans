local T = require "tests/support/test"

local path = "PNC/Settlement/FacilityJobs/PNC_FacilityJobs_Service.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix =
    "PNC/Settlement/FacilityJobs/FacilityJobs_Service/"
local providers = {
    "PNC_FacilityJobs_Service_Core",
    "PNC_FacilityJobs_Service_ManualTargets",
    "PNC_FacilityJobs_Service_Toggle",
    "PNC_FacilityJobs_Service_Resolution",
    "PNC_FacilityJobs_Service_Start",
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
        "function%s+Jobs%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.FacilityJobs[name]), "function",
        "entry point preserves FacilityJobs." .. name)
end
T.equal(publicCount, 4, "facility-jobs public function count")
T.equal(type(PNC.FacilityJobsServiceInternal.BaseForRecord), "function",
    "forward base resolver remains available to manual targets")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_facility_jobs_service_presence_boundary_smoke")

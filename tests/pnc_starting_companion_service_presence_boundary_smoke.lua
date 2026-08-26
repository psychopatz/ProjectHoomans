local T = require "tests/support/test"

local path = "PNC/Companions/PNC_StartingCompanionService.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Companions/StartingCompanionService/"
local providers = {
    "PNC_StartingCompanionService_Core",
    "PNC_StartingCompanionService_Identity",
    "PNC_StartingCompanionService_Assignment",
    "PNC_StartingCompanionService_Grant",
    "PNC_StartingCompanionService_Ensure",
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
        "function%s+Starting%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.StartingCompanions[name]), "function",
        "entry point preserves StartingCompanions." .. name)
end
T.equal(publicCount, 1, "starting-companion public function count")
T.equal(type(PNC.StartingCompanions.NextRetryAt), "table",
    "starting-companion retry state remains initialized")
T.equal(PNC.StartingCompanions.RETRY_DELAY_MS, 5000,
    "retry delay remains stable")
T.equal(PNC.StartingCompanions.ENRICHMENT_VERSION, 5,
    "enrichment version remains stable")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_starting_companion_service_presence_boundary_smoke")

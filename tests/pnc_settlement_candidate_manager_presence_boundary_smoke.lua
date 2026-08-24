local T = require "tests/support/test"

local path = "PNC/Director/Population/PNC_SettlementCandidateManager.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Director/Population/SettlementCandidateManager/"
local providers = {
    "PNC_SettlementCandidateManager_Core",
    "PNC_SettlementCandidateManager_Discovery",
    "PNC_SettlementCandidateManager_MetaDiscovery",
    "PNC_SettlementCandidateManager_Evaluation",
    "PNC_SettlementCandidateManager_Selection",
    "PNC_SettlementCandidateManager_Reservations",
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
        "function%s+Candidates%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = { DirectorConfig = { Population = {} } }
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.SettlementCandidates[name]), "function",
        "entry point preserves SettlementCandidates." .. name)
end
T.equal(publicCount, 13, "settlement-candidate public function count")
T.equal(type(PNC.SettlementCandidates.Pools), "table",
    "candidate pools remain initialized")
T.equal(type(PNC.SettlementCandidates.Reservations), "table",
    "candidate reservations remain initialized")
T.equal(type(PNC.SettlementCandidates.Metrics), "table",
    "candidate metrics remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_settlement_candidate_manager_presence_boundary_smoke")

local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Base/PNC_Constants.lua"
)
local providers = {
    "Identity", "NetworkCommands", "Orders", "SchedulingPresence",
    "TravelPathing", "BehaviorInventory", "HealthThreats",
    "ReplicationBodies", "CombatTactics",
}

local previous = 0
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "PNC/Core/Base/PNC_Constants/'
        .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Constants.lua")

local count = 0
for _ in pairs(PNC.Const) do count = count + 1 end
T.equal(count, 503, "constant key count")
T.equal(PNC.Const.PERSISTENCE_VERSION, 15, "persistence contract")
T.equal(PNC.Const.CMD_FULL_SYNC_REQUEST, "RequestFullSync", "network contract")
T.equal(PNC.Const.CMD_LLM_REQUEST_RESERVE, "LLMRequestReserve",
    "llm request reservation contract")
T.equal(PNC.Const.CMD_LLM_REQUEST_RELEASE, "LLMRequestRelease",
    "llm request release contract")
T.equal(PNC.Const.TRAVEL_SCHEMA_VERSION, 2, "travel contract")
T.equal(PNC.Const.FOLLOW_RETREAT_MAX_DISTANCE,
    PNC.Const.FOLLOW_COMBAT_LEASH_DISTANCE, "derived follow constant")
T.equal(PNC.Const.COMBAT_DEBUG_VISIBLE_ZOMBIE_LIMIT, 6, "final provider loaded")

T.finish("pnc_constants_presence_boundary_smoke")

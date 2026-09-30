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
-- Change detector: update this when a constant is intentionally added or
-- removed so the growth is reviewed instead of silent.
T.equal(count, 614, "constant key count")
T.equal(PNC.Const.PERSISTENCE_VERSION, 16, "persistence contract")
T.equal(PNC.Const.NETWORK_PAYLOAD_BUDGET_BYTES, 786432,
    "server payload budget contract")
T.equal(PNC.Const.NETWORK_PAYLOAD_ENVELOPE, "pncOversize",
    "payload refusal envelope contract")
T.equal(PNC.Const.NETWORK_PAYLOAD_CHUNK, "pncChunk",
    "payload chunk envelope contract")
T.equal(PNC.Const.CMD_FULL_SYNC_REQUEST, "RequestFullSync", "network contract")
T.equal(PNC.Const.CMD_LLM_REQUEST_RESERVE, "LLMRequestReserve",
    "llm request reservation contract")
T.equal(PNC.Const.CMD_LLM_REQUEST_RELEASE, "LLMRequestRelease",
    "llm request release contract")
T.equal(PNC.Const.CMD_PUPPET_OPERA_REQUEST, "PuppetOperaRequest",
    "Puppet Opera request contract")
T.equal(PNC.Const.CMD_PUPPET_OPERA_STATE, "PuppetOperaState",
    "Puppet Opera state contract")
T.equal(PNC.Const.CMD_PUPPET_OPERA_TRACE, "PuppetOperaTrace",
    "Puppet Opera trace contract")
T.equal(PNC.Const.TRAVEL_SCHEMA_VERSION, 2, "travel contract")
T.equal(PNC.Const.TRAVEL_LIVE_PROGRESS_TIMEOUT_MS, 12000,
    "live travel watchdog contract")
T.equal(PNC.Const.FOLLOW_RETREAT_MAX_DISTANCE,
    PNC.Const.FOLLOW_COMBAT_LEASH_DISTANCE, "derived follow constant")
T.equal(PNC.Const.COMBAT_DEBUG_VISIBLE_ZOMBIE_LIMIT, 6, "final provider loaded")
T.truthy((tonumber(PNC.Const.COMBAT_STANCE_HOLD_MS) or 0) > 0,
    "weapon-drawn fighting-mode hold contract")

T.finish("pnc_constants_presence_boundary_smoke")

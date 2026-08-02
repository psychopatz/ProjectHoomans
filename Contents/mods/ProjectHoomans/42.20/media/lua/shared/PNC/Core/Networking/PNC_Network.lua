--[[
    PNC Networking
    Public facade and shared networking state.

    Feature modules register their existing public functions on PNC.Network so
    callers keep a stable API while networking responsibilities remain isolated.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.ClientState = PNC.Network.ClientState or {
    snapshots = {},
    characterPayloads = {},
    debugRoster = {},
    debugAuthorized = false,
    relationshipDebug = nil,
    relationshipDebugAuthorized = false,
    npcKnowledge = {},
    npcPresentations = {},
    playerContext = nil,
    bootstrapState = "idle",
    knowledgeDebug = nil,
    knowledgeDebugAuthorized = false,
    factionDebug = nil,
    factionDebugAuthorized = false,
    factionMembers = nil,
    factionMembersReason = nil,
    communityDebug = nil,
    communityDebugAuthorized = false,
    needsDebug = nil,
    needsDebugAuthorized = false,
    colonyManagement = nil,
}
PNC.Network.ServerState = PNC.Network.ServerState or {
    interests = {},
    rosterDeltas = {},
    rosterRevision = 0,
    lastInterestRefreshAt = 0,
    lastRosterFlushAt = 0,
}
if PNC.Network.ClientState.communityDebugAuthorized == nil then
    PNC.Network.ClientState.communityDebugAuthorized = false
end
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local ServerState = Network.ServerState

function Network.ResetServerState()
    ServerState.interests = {}
    ServerState.rosterDeltas = {}
    ServerState.rosterRevision = 0
    ServerState.lastInterestRefreshAt = 0
    ServerState.lastRosterFlushAt = 0
end

require "PNC/Core/Networking/PNC_Network_SnapshotParts"
require "PNC/Core/Networking/PNC_Network_Snapshots"
require "PNC/Core/Networking/PNC_Network_Server"
require "PNC/Core/Networking/PNC_Network_CombatEvents"

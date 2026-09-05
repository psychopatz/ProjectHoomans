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
    managedBodyOnlineIDs = {},
    managedBodyOnlineIDsReady = false,
    characterPayloads = {},
    debugRoster = {},
    debugAuthorized = false,
    relationshipDebug = nil,
    relationshipDebugAuthorized = false,
    npcKnowledge = {},
    npcPresentations = {},
    conversationRelationshipDiagnostics = {},
    conversationDiary = {},
    conversationDiaryRevisions = {},
    conversationDiaryRevision = 0,
    lastConversationDeltas = {},
    llmToolResults = {},
    llmToolResultOrder = {},
    playerEmoteInteractionResults = {},
    playerEmoteInteractionResultOrder = {},
    playerContext = nil,
    rosterRevision = 0,
    rosterEntryRevisions = {},
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
    directorDebug = nil,
    directorDebugAuthorized = false,
    colonyManagement = nil,
    colonyManagementRevision = 0,
    colonyJournal = {
        rows = {}, cursor = 0, latestSequence = 0, rowSequences = {},
    },
    colonyJournalRevision = 0,
    worldDiscovery = nil,
}
if PNC.Network.ClientState.managedBodyOnlineIDs == nil then
    PNC.Network.ClientState.managedBodyOnlineIDs = {}
end
if PNC.Network.ClientState.managedBodyOnlineIDsReady == nil then
    PNC.Network.ClientState.managedBodyOnlineIDsReady = false
end
PNC.Network.ServerState = PNC.Network.ServerState or {
    interests = {},
    rosterDeltas = {},
    rosterRevision = 0,
    fullSyncSerial = 0,
    lastInterestRefreshAt = 0,
    lastRosterFlushAt = 0,
}
if PNC.Network.ClientState.communityDebugAuthorized == nil then
    PNC.Network.ClientState.communityDebugAuthorized = false
end
if PNC.Network.ClientState.colonyManagementRevision == nil then
    PNC.Network.ClientState.colonyManagementRevision = 0
end
if PNC.Network.ClientState.directorDebugAuthorized == nil then
    PNC.Network.ClientState.directorDebugAuthorized = false
end
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local ServerState = Network.ServerState

-- Native IsoZombie updates run before the client presence tick. Keep a small
-- identity index beside the roster so the early OnZombieUpdate safety hook
-- can recognize a carrier before presentation has written PNC modData.
-- Rebuilding is explicit and only happens when roster state changes; it is
-- never a per-zombie or per-frame scan.
function Network.RefreshClientBodyIdentityIndex()
    local index = {}
    local snapshot
    local onlineID
    for _, candidate in pairs(Network.ClientState.snapshots or {}) do
        snapshot = candidate
        if type(snapshot) == "table"
            and snapshot.presenceState == "live"
            and snapshot.alive ~= false
        then
            onlineID = tonumber(snapshot.liveBodyOnlineID)
            if onlineID ~= nil and onlineID >= 0 then
                index[tostring(onlineID)] = true
            end
        end
    end
    Network.ClientState.managedBodyOnlineIDs = index
    Network.ClientState.managedBodyOnlineIDsReady = true
    return index
end

function Network.ResetServerState()
    ServerState.interests = {}
    ServerState.rosterDeltas = {}
    ServerState.rosterRevision = 0
    ServerState.lastInterestRefreshAt = 0
    ServerState.lastRosterFlushAt = 0
end

require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots"
require "PNC/Core/Networking/PNC_Network_Server"
require "PNC/Core/Networking/PNC_Network_CombatEvents"

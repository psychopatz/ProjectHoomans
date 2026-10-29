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
    uniqueNPCDebug = nil,
    uniqueNPCDebugAuthorized = false,
    uniqueNPCDebugReason = nil,
    lastUniqueNPCDebugRequestAt = 0,
    lastUniqueNPCDebugReceiveAt = 0,
    uniqueNPCTestSpawn = nil,
    relationshipDebug = nil,
    relationshipDebugAuthorized = false,
    npcKnowledge = {},
    npcPresentations = {},
    semanticCognition = {},
    pendingSemanticCognition = {},
    lastSemanticCognitionRequestAt = {},
    lastSemanticCognitionReceiveAt = 0,
    lastSemanticCognitionFailure = nil,
    conversationRelationshipDiagnostics = {},
    conversationDiary = {},
    conversationDiaryRevisions = {},
    conversationDiaryRevision = 0,
    lastConversationDeltas = {},
    semanticHubPresentation = {},
    llmToolResults = {},
    llmToolResultOrder = {},
    playerEmoteInteractionResults = {},
    playerEmoteInteractionResultOrder = {},
    -- Per command+scope record of the last payload-budget refusal, so a UI can
    -- report a sync failure instead of rendering empty data.
    payloadSync = {},
    playerContext = nil,
    rosterRevision = 0,
    rosterEntryRevisions = {},
    bootstrapState = "idle",
    knowledgeDebug = nil,
    knowledgeDebugAuthorized = false,
    worldKnowledgeDebug = nil,
    worldKnowledgeDebugAuthorized = false,
    worldKnowledgeDebugReason = nil,
    lastWorldKnowledgeDebugRequestAt = 0,
    lastWorldKnowledgeDebugReceiveAt = 0,
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
    zombiePursuitDirectives = {},
    stealthDiscovery = nil,
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
if PNC.Network.ClientState.zombiePursuitDirectives == nil then
    PNC.Network.ClientState.zombiePursuitDirectives = {}
end
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local ServerState = Network.ServerState

-- Deprecated compatibility hook. Roster online IDs are hints, never client
-- body identity. Canonical MultiplayerBodyBinding owns managed admission.
function Network.RefreshClientBodyIdentityIndex()
    Network.ClientState.managedBodyOnlineIDs = {}
    Network.ClientState.managedBodyOnlineIDsReady = true
    return Network.ClientState.managedBodyOnlineIDs
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

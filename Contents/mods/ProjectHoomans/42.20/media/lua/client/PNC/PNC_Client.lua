--[[
    PNC Client
    Loads focused command modules and owns top-level client event wiring.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

local function isWorldReady()
    return (not isIngameState) or isIngameState()
end

Internal.IsWorldReady = isWorldReady

require "PNC/Networking/PNC_ClientCommandRouter"
require "PNC/Networking/PNC_ClientCombatCommands"
require "PNC/Networking/PNC_ClientRequests"
require "PNC/Networking/PNC_ClientRosterCommands"
require "PNC/Networking/PNC_ClientInventoryCommands"
require "PNC/Networking/PNC_ClientActions"

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    local square
    if not isWorldReady() then
        return
    end
    if test then
        return
    end

    square = PNC.NPCSelection and PNC.NPCSelection.GetWorldSquare and PNC.NPCSelection.GetWorldSquare(worldobjects) or nil
    if square and Client.CanUseDebug() then
        if PNC.DebugSpawnMenu and PNC.DebugSpawnMenu.Add then
            PNC.DebugSpawnMenu.Add(context, square)
        end
    end
    if PNC.ContextHub and PNC.ContextHub.BuildWorldContext then
        PNC.ContextHub.BuildWorldContext(playerNum, context, worldobjects, test)
    end
    if PNC.SinkCompanionContext
        and PNC.SinkCompanionContext.BuildWorldContext
    then
        PNC.SinkCompanionContext.BuildWorldContext(
            playerNum, context, worldobjects, test)
    end
end

local function onServerCommand(module, command, args)
    if module == Const.MODULE then
        Client.HandleServerCommand(command, args or {})
    end
end

local function onResetLua()
    ClientState.snapshots = {}
    ClientState.npcKnowledge = {}
    ClientState.npcPresentations = {}
    ClientState.playerContext = nil
    ClientState.bootstrapState = "idle"
    ClientState.activeBootstrapRequestID = nil
    ClientState.bootstrapKnowledgeRevision = nil
    ClientState.lastBootstrapRequestAt = nil
    ClientState.bootstrapRetryAttempt = nil
    ClientState.bootstrapReason = nil
    if PNC.KnowledgeInterest and PNC.KnowledgeInterest.Reset then
        PNC.KnowledgeInterest.Reset()
    end
    ClientState.pendingDisclosure = {}
    ClientState.characterPayloads = {}
    ClientState.debugRoster = {}
    ClientState.debugAuthorized = false
    ClientState.relationshipDebug = nil
    ClientState.relationshipDebugAuthorized = false
    ClientState.relationshipDebugReason = nil
    ClientState.conversationRelationships = {}
    ClientState.conversationHistory = {}
    ClientState.conversationDiary = {}
    ClientState.conversationDiaryRevision = 0
    ClientState.lastConversationDelta = nil
    ClientState.factionDebug = nil
    ClientState.factionDebugAuthorized = false
    ClientState.factionDebugReason = nil
    ClientState.inventoryResult = nil
    ClientState.inventoryRequestSerial = 0
    ClientState.needsDebug = nil
    ClientState.needsDebugAuthorized = false
    ClientState.needsDebugReason = nil
    ClientState.directorDebug = nil
    ClientState.directorDebugAuthorized = false
    ClientState.directorDebugReason = nil
    ClientState.colonyManagement = nil
    ClientState.colonyManagementRevision = 0
    ClientState.worldDiscovery = nil
    ClientState.scavengeSessions = {}
    ClientState.activeScavengeSessionId = nil
    ClientState.lastScavengeFailure = nil
    if PNC.ScavengeController and PNC.ScavengeController.Reset then
        PNC.ScavengeController.Reset()
    end
    if PNC.ScavengeNotifications and PNC.ScavengeNotifications.Reset then
        PNC.ScavengeNotifications.Reset()
    end
    ClientState.lastWorldDiscoveryRequestAt = nil
    Client.BiteReplicas = {}
    Client.ZombieReactionReplicas = {}
    if PNC.ClientFirearmEffects and PNC.ClientFirearmEffects.Reset then
        PNC.ClientFirearmEffects.Reset()
    end
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(Client.RequestFullSync)
end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(Client.RequestFullSync)
end
if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
if Events and Events.OnTick then
    Events.OnTick.Add(Internal.PumpCombatReplicas)
end

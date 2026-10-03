-- Inbound knowledge and identity command composition root.

local Internal = PNC.Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_KnowledgeMemory"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_KnowledgeState"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_KnowledgePresentationState"
local KnowledgeState = Internal.KnowledgeState

local function clearPendingBootstrap()
    ClientState.pendingBootstrap = nil
end

local function rejectBootstrapStream(reason)
    clearPendingBootstrap()
    ClientState.bootstrapState = "error"
    ClientState.bootstrapReason = reason or "invalid_bootstrap_stream"
end

Internal.RegisterServerCommand(Const.CMD_NPC_KNOWLEDGE, function(args)
    Internal.ApplyNPCKnowledgeSnapshot(args.snapshot, args.reason)
end)

require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_KnowledgeBootstrap"
local bootstrapDependencies = {
    clearPending = clearPendingBootstrap,
    reject = rejectBootstrapStream,
    isStale = KnowledgeState.IsStaleKnowledge,
    projectionIsCurrent = KnowledgeState.ProjectionIsCurrent,
}

Internal.RegisterServerCommand(Const.CMD_PLAYER_BOOTSTRAP, function(args)
    Internal.HandlePlayerBootstrap(args, bootstrapDependencies)
end)

Internal.RegisterServerCommand(Const.CMD_NPC_PRESENTATION, function(args)
    Internal.ApplyNPCPresentation(args)
end)

require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_KnowledgeDisclosure"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_KnowledgeDebug"

return PNC.Client

local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {}
local received = {}
local discoveryResponse

PNC = {
    Const = {
        CMD_PLAYER_BOOTSTRAP_REQUEST = "PlayerBootstrapRequest",
        CMD_NPC_PRESENTATION_REQUEST = "NPCPresentationRequest",
        CMD_KNOWLEDGE_DISCLOSURE_REQUEST = "KnowledgeDisclosureRequest",
        CMD_WORLD_DISCOVERY_REQUEST = "WorldDiscoveryRequest",
        CMD_WORLD_DISCOVERY_ACTION = "WorldDiscoveryAction",
    },
    PlayerKnowledgeCommands = {
        HandleBootstrap = function(receivedPlayer, args)
            received.bootstrap = { player = receivedPlayer, args = args }
        end,
        HandlePresentation = function(receivedPlayer, args)
            received.presentation = { player = receivedPlayer, args = args }
        end,
        HandleDisclosure = function(receivedPlayer, args)
            received.disclosure = { player = receivedPlayer, args = args }
        end,
    },
    WorldDiscovery = {
        HandleAction = function(receivedPlayer, args)
            received.discovery = { player = receivedPlayer, args = args }
            return { revision = 7 }
        end,
    },
    Network = {
        SendWorldDiscovery = function(receivedPlayer, payload)
            discoveryResponse = { player = receivedPlayer, payload = payload }
        end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerKnowledgeCommandHandler"

local bootstrapArgs = { requestID = "bootstrap:1" }
T.equal(Router.Handle("PlayerBootstrapRequest", player, bootstrapArgs), true,
    "bootstrap handled")
T.equal(received.bootstrap.player, player, "bootstrap player")
T.equal(received.bootstrap.args, bootstrapArgs, "bootstrap payload")

local presentationArgs = { npcID = "npc-1", requestID = "presentation:1" }
T.equal(Router.Handle(
    "NPCPresentationRequest",
    player,
    presentationArgs
), true, "presentation handled")
T.equal(received.presentation.args, presentationArgs,
    "presentation payload")

local disclosureArgs = { npcID = "npc-1", topicID = "identity_name" }
T.equal(Router.Handle(
    "KnowledgeDisclosureRequest",
    player,
    disclosureArgs
), true, "disclosure handled")
T.equal(received.disclosure.args, disclosureArgs, "disclosure payload")

local discoveryArgs = { action = "debug_discover_all" }
T.equal(Router.Handle(
    "WorldDiscoveryAction",
    player,
    discoveryArgs
), true, "world-discovery action handled")
T.equal(received.discovery.args, discoveryArgs, "discovery payload")
T.equal(discoveryResponse.player, player, "discovery response player")
T.equal(discoveryResponse.payload.revision, 7,
    "discovery response payload")

T.equal(Router.Handle("WorldDiscoveryRequest", player, nil), true,
    "world-discovery request handled")
T.equal(type(received.discovery.args), "table",
    "nil payload normalized to table")
T.finish("pnc_server_knowledge_command_handler_smoke")

T.finish("pnc_server_knowledge_command_handler_smoke")

local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
assertEqual(Router.Handle("PlayerBootstrapRequest", player, bootstrapArgs), true,
    "bootstrap handled")
assertEqual(received.bootstrap.player, player, "bootstrap player")
assertEqual(received.bootstrap.args, bootstrapArgs, "bootstrap payload")

local presentationArgs = { npcID = "npc-1", requestID = "presentation:1" }
assertEqual(Router.Handle(
    "NPCPresentationRequest",
    player,
    presentationArgs
), true, "presentation handled")
assertEqual(received.presentation.args, presentationArgs,
    "presentation payload")

local disclosureArgs = { npcID = "npc-1", topicID = "identity_name" }
assertEqual(Router.Handle(
    "KnowledgeDisclosureRequest",
    player,
    disclosureArgs
), true, "disclosure handled")
assertEqual(received.disclosure.args, disclosureArgs, "disclosure payload")

local discoveryArgs = { action = "debug_discover_all" }
assertEqual(Router.Handle(
    "WorldDiscoveryAction",
    player,
    discoveryArgs
), true, "world-discovery action handled")
assertEqual(received.discovery.args, discoveryArgs, "discovery payload")
assertEqual(discoveryResponse.player, player, "discovery response player")
assertEqual(discoveryResponse.payload.revision, 7,
    "discovery response payload")

assertEqual(Router.Handle("WorldDiscoveryRequest", player, nil), true,
    "world-discovery request handled")
assertEqual(type(received.discovery.args), "table",
    "nil payload normalized to table")

print("pnc_server_knowledge_command_handler_smoke: ok")

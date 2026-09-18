local T = require "tests/support/test"
T.addPackagePaths()

local localPlayer = {}
local localEvents = {}
local remoteCommands = {}

PNC = {
    Core = { Now = function() return 42 end },
    Const = { MODULE = "ProjectHoomans" },
    Network = { Internal = {} },
    Semantics = {},
}
isServer = function() return true end
getSpecificPlayer = function(index)
    return index == 0 and localPlayer or nil
end
triggerEvent = function(eventName, module, command, payload)
    localEvents[#localEvents + 1] = {
        eventName = eventName,
        module = module,
        command = command,
        payload = payload,
    }
end
sendServerCommand = function(target, module, command, payload)
    remoteCommands[#remoteCommands + 1] = {
        target = target,
        module = module,
        command = command,
        payload = payload,
    }
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticIdentityExchange.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_DebugPayloads.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticIdentityNetwork.lua"
)

local localPayload = {}
T.truthy(PNC.Network.SendSemanticIdentityResult(
    localPlayer, localPayload
), "singleplayer identity result is delivered")
T.equal(#localEvents, 1,
    "singleplayer identity result uses the local server-command event")
T.equal(localEvents[1].command, "SemanticIdentityResult",
    "singleplayer identity result reaches the semantic client command")
T.equal(localPayload.serverTime, 42,
    "identity transport stamps the authoritative server time")

local remotePlayer = {}
T.truthy(PNC.Network.SendSemanticIdentityResult(
    remotePlayer, {}
), "multiplayer identity result is sent")
T.equal(#remoteCommands, 1,
    "multiplayer identity result uses the native server command")
T.equal(remoteCommands[1].command, "SemanticIdentityResult",
    "multiplayer identity result preserves its command name")

T.finish("pnc_semantic_identity_transport_smoke")

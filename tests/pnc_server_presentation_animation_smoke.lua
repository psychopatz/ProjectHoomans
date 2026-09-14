local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local FILE = T.path(
    "ProjectHoomans",
    "server",
    "PNC/Networking/Handlers/PNC_ServerPresentationAnimationCommandHandler.lua"
)

local registered
local requests = {}
local body = {}
local record = { id = "npc-1", presenceState = "live" }

PNC = {
    Const = {
        CMD_NPC_PRESENTATION_ANIMATION = "NPCPresentationAnimation",
    },
    ServerCommandRouter = {
        Register = function(command, handler)
            registered = { command = command, handler = handler }
        end,
    },
    Registry = {
        Get = function(npcID)
            if npcID == "npc-1" then return record end
            return nil
        end,
        GetLiveZombie = function(npcID)
            if npcID == "npc-1" then return body end
            return nil
        end,
    },
    PresentationAnimations = {
        Get = function(animationID)
            if animationID == "greeting.wavehi" then
                return { id = animationID }
            end
            return nil
        end,
        Request = function(targetRecord, targetBody, animationID, options)
            requests[#requests + 1] = {
                record = targetRecord,
                body = targetBody,
                animationID = animationID,
                options = options,
            }
            return true, "started"
        end,
    },
    Conversation = {
        Authority = {
            Internal = {
                ValidateLease = function(player, targetRecord, token)
                    if token ~= "lease-1" then return false, "invalid_lease" end
                    return true, nil
                end,
            },
        },
    },
}

local handle = T.load(FILE)
T.truthy(registered, "server handler did not register")
T.equal(registered.command, "NPCPresentationAnimation",
    "server handler registered the wrong command")
T.equal(handle, registered.handler, "server handler did not return itself")

local denied, deniedReason = registered.handler("player-1", {
    id = "npc-1",
    animationID = "greeting.wavehi",
    eventID = "message-1",
    token = "wrong-token",
})
T.falsy(denied, "unleased client request reached live presentation")
T.equal(deniedReason, "invalid_lease",
    "unleased request reported the wrong reason")
T.equal(#requests, 0, "unleased request reached the animation arbiter")

local accepted, acceptedReason = registered.handler("player-1", {
    npcID = "npc-1",
    animation = "greeting.wavehi",
    eventID = "message-1",
    token = "lease-1",
})
T.truthy(accepted, "leased client request was rejected")
T.equal(acceptedReason, "started", "leased request returned the wrong result")
T.equal(#requests, 1, "leased request did not reach the animation arbiter")
T.equal(requests[1].options.eventID, "message-1",
    "server handler did not forward the message identity")

local unknown, unknownReason = registered.handler("player-1", {
    id = "npc-1",
    animationID = "unregistered.animation",
    eventID = "message-2",
    token = "lease-1",
})
T.falsy(unknown, "unregistered animation was accepted")
T.equal(unknownReason, "animation_not_registered",
    "unregistered animation reported the wrong reason")

T.finish("pnc_server_presentation_animation_smoke")

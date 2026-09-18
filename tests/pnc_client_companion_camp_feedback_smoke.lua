local T = require "tests/support/test"

local CLIENT_ROOT = T.path(
    "ProjectHoomans",
    "client",
    "PNC/Networking/"
)

T.addPackagePaths()

local executeCount = 0
local rejectionCount = 0
local exchange
local lastArgs
local queuedArgs
local observedHintOrigin
local visibleHint = {
    version = 1,
    source = "client_loaded_rooms",
    kind = "camp_site",
    scope = "room",
    siteScope = "room",
    siteID = "room:test-building:test-room",
    roomID = "test-room",
    buildingID = "test-building",
    x = 2.5,
    y = 0.5,
    z = 0,
    radius = 32,
    score = 1,
}
local player = {
    getUsername = function() return "alice" end,
    isDead = function() return false end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local record = {
    id = "owned",
    alive = true,
    recruited = true,
    tacticalClass = "colonist",
    ownerUsername = "alice",
    presenceState = "live",
    x = 2,
    y = 0,
    z = 0,
}
local body = {
    isDead = function() return false end,
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}

PNC = {
    Const = {
        MODULE = "PNC",
        COMPANION_COMMAND_RADIUS = 20,
    },
    Core = {
        IsClientOnly = function() return false end,
        Now = function() return 100 end,
    },
    Network = {
        ClientState = {},
    },
    Semantics = {
        ClientCampSiteHints = {
            MAX_RADIUS = 32,
            Resolve = function(_, context)
                observedHintOrigin = context and context.selectionOrigin
                if visibleHint then return visibleHint end
                return nil, "no_matching_loaded_object"
            end,
        },
    },
    Registry = {
        Get = function() return record end,
        GetLiveZombie = function() return body end,
        ForEach = function(callback) callback(record, record.id) end,
    },
    CompanionCommands = {
        Get = function(commandID)
            return commandID == "camp"
                and { id = "camp", emote = "freeze" }
                or { id = commandID }
        end,
        CanPlayerCommand = function() return true, "commandable" end,
        CanApply = function() return true, "commandable" end,
        Execute = function(_, args)
            executeCount = executeCount + 1
            lastArgs = args
            return 1, "commanded"
        end,
    },
    CompanionCommandPresentation = {
        ShowCommandRejection = function()
            rejectionCount = rejectionCount + 1
            return true
        end,
        ShowCampInteraction = function(_, target, targets, outcome, context)
            exchange = {
                target = target,
                targets = targets,
                outcome = outcome,
                context = context,
            }
            return true
        end,
    },
    Client = {},
}

getSpecificPlayer = function() return player end
package.preload["PsychopatzCore/World/PsychopatzTeleport"] = function()
    return {}
end

T.load(CLIENT_ROOT .. "PNC_ClientActions.lua")

T.truthy(PNC.Client.SendCompanionCommand(
    "camp", "owned", nil, { record = record }
), "room targeted camp was rejected despite a visible site")
T.equal(executeCount, 1,
    "room targeted camp did not reach the order executor")
T.equal(lastArgs.campSiteHint.scope, "room",
    "room targeted camp did not attach the client site hint")
T.equal(observedHintOrigin, player,
    "direct camp discovery incorrectly used the companion as its origin")
T.equal(rejectionCount, 0,
    "room targeted camp presented a safety warning")

visibleHint = {
    version = 1,
    source = "client_loaded_campfire",
    kind = "campfire",
    scope = "campfire",
    siteScope = "campfire",
    campfireID = "campfire@test",
    x = 3.5,
    y = 0.5,
    z = 0,
    radius = 32,
    score = 1,
}
T.truthy(PNC.Client.SendCompanionCommand(
    "camp", nil, "group", {
        targets = { { id = "owned" }, { id = "owned_second" } },
    }
), "campfire group camp was rejected despite a visible site")
T.equal(executeCount, 2,
    "campfire group camp did not reach the order executor")
T.equal(lastArgs.campSiteHint.scope, "campfire",
    "campfire group camp did not attach the client site hint")
T.equal(lastArgs.targetIDs[1], "owned",
    "group camp omitted the first compact nearby target id")
T.equal(lastArgs.targetIDs[2], "owned_second",
    "group camp omitted the second compact nearby target id")
T.equal(rejectionCount, 0,
    "campfire group camp presented a safety warning")

visibleHint = nil
T.falsy(PNC.Client.SendCompanionCommand(
    "camp", "owned", nil, { record = record }
), "camp without a visible site reached execution")
T.equal(executeCount, 2,
    "camp without a visible site reached the order executor")
T.equal(rejectionCount, 1,
    "camp without a visible site did not present its rejection")

visibleHint = {
    version = 1,
    source = "client_loaded_rooms",
    kind = "camp_site",
    scope = "room",
    siteScope = "room",
    x = 2.5,
    y = 0.5,
    z = 0,
    radius = 32,
    score = 1,
}
PNC.Core.IsClientOnly = function() return true end
sendClientCommand = function(_, _, _, args) queuedArgs = args end
local queued, queuedReason = PNC.Client.SendCompanionCommand(
    "camp", "owned", nil, { record = record })
T.equal(queued, true, "multiplayer camp with a visible site was not queued")
T.equal(queuedReason, "network_queued",
    "multiplayer camp returned the wrong queue result")
T.equal(executeCount, 2,
    "multiplayer camp incorrectly executed through the local authority")
T.equal(queuedArgs.campSiteHint.scope, "room",
    "multiplayer camp omitted its primitive site hint")

local target = { id = "owned", name = "Mel patz" }
local emoteResult = false
local emoteReason = "camp_no_visible_site"
local originalEmote

ISEmoteRadialMenu = {
    PNCCompanionCommandsInstalled = false,
    init = function() end,
    emote = function(_, emote)
        originalEmote = emote
        return emote
    end,
}
package.preload["ISUI/ISEmoteRadialMenu"] = function()
    return ISEmoteRadialMenu
end
package.preload["PNC/Commands/PNC_CompanionTargetResolver"] = function()
    return {
        ResolveRecipients = function()
            return { target = target, targets = { target } }
        end,
        CollectNearbyCompanions = function()
            return { target = target, targets = { target } }
        end,
        BuildConversationEntry = function(candidate)
            return candidate
        end,
    }
end
PNC.VanillaEmoteInteractions = nil
PNC.CompanionCommandEmotes = nil
PNC.Client.ExecuteCompanionCommand = function(_, commandID, npcId)
    return emoteResult, emoteReason
end
T.load(T.path(
    "ProjectHoomans",
    "client",
    "PNC/Commands/PNC_CompanionCommandEmotes.lua"
))

ISEmoteRadialMenu.PNCClosestCompanion = target
emoteResult = false
emoteReason = "camp_no_visible_site"
ISEmoteRadialMenu:emote("PNC_ClosestCommand_camp")
T.equal(exchange.outcome, "invalid",
    "camp emote did not route the unsafe result to the exchange")
T.equal(exchange.context.origin, "companion_emote",
    "camp emote did not mark its conversation origin")

ISEmoteRadialMenu.PNCClosestCompanion = nil
emoteReason = "no_targets"
ISEmoteRadialMenu:emote("PNC_ClosestCommand_camp")
T.equal(exchange.outcome, "none",
    "camp emote without an NPC did not route the empty exchange")

ISEmoteRadialMenu.PNCClosestCompanion = target
emoteResult = true
emoteReason = "commanded"
ISEmoteRadialMenu:emote("PNC_ClosestCommand_camp")
T.equal(exchange.outcome, "valid",
    "camp emote did not route the valid result to the exchange")
T.equal(originalEmote, "freeze", "camp emote visual was preserved")

T.finish("pnc_client_companion_camp_feedback_smoke")

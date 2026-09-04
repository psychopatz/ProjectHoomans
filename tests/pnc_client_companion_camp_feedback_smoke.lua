local T = require "tests/support/test"

local CLIENT_ROOT = T.path(
    "ProjectHoomans",
    "client",
    "PNC/Networking/"
)

T.addPackagePaths()

local indoor = false
local executeCount = 0
local rejectionCount = 0
local exchange
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
        CanApply = function()
            return indoor and true or false,
                indoor and "camp_inside_building"
                    or "camp_requires_building"
        end,
        Execute = function()
            executeCount = executeCount + 1
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

T.falsy(PNC.Client.SendCompanionCommand(
    "camp", "owned", nil, { record = record }
), "outdoor targeted camp should be rejected before execution")
T.equal(executeCount, 0,
    "outdoor targeted camp reached the order executor")
T.equal(rejectionCount, 1,
    "outdoor targeted camp did not present its safety warning")

T.falsy(PNC.Client.SendCompanionCommand(
    "camp", nil, "group"
), "outdoor group camp should be rejected before execution")
T.equal(executeCount, 0,
    "outdoor group camp reached the order executor")
T.equal(rejectionCount, 2,
    "outdoor group camp did not present its safety warning")

indoor = true
T.truthy(PNC.Client.SendCompanionCommand(
    "camp", "owned", nil, { record = record }
), "indoor targeted camp was incorrectly rejected")
T.equal(executeCount, 1,
    "indoor targeted camp did not reach the order executor")

local target = { id = "owned", name = "Mel patz" }
local emoteResult = false
local emoteReason = "camp_requires_building"
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
emoteReason = "camp_requires_building"
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

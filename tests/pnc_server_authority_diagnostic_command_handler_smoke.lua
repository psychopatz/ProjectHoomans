local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {
    access = "",
    getAccessLevel = function(self) return self.access end,
}
local calls = {}
local factionArgs
local membershipActionArgs
local communityArgs
local needsArgs
local directorArgs

local function capture(name)
    return function(...)
        calls[name] = { ... }
    end
end

PNC = {
    Const = {
        CMD_FACTION_DEBUG_REQUEST = "FactionDebugRequest",
        CMD_FACTION_MEMBERS_REQUEST = "FactionMembersRequest",
        CMD_FACTION_MEMBER_ACTION = "FactionMemberAction",
        CMD_COMMUNITY_DEBUG_REQUEST = "CommunityDebugRequest",
        CMD_NEEDS_DEBUG_REQUEST = "NeedsDebugRequest",
        CMD_DIRECTOR_DEBUG_REQUEST = "DirectorDebugRequest",
    },
    Network = {
        SendFactionDebug = capture("factionDebug"),
        SendFactionMembers = capture("factionMembers"),
        SendCommunityDebug = capture("communityDebug"),
        SendNeedsDebug = capture("needsDebug"),
        SendDirectorDebug = capture("directorDebug"),
    },
    FactionDebug = {
        BuildSnapshot = function(...)
            factionArgs = { ... }
            return { kind = "faction" }
        end,
    },
    FactionMembership = {
        BuildSnapshot = function(receivedPlayer)
            return { kind = "members", player = receivedPlayer },
                "members_reason"
        end,
        PerformAction = function(receivedPlayer, args)
            membershipActionArgs = args
            return { kind = "member_action", player = receivedPlayer },
                "action_reason"
        end,
    },
    CommunityDebug = {
        BuildSnapshot = function(...)
            communityArgs = { ... }
            return { kind = "community" }
        end,
    },
    NeedsDebug = {
        BuildSnapshot = function(...)
            needsArgs = { ... }
            return { kind = "needs" }
        end,
    },
    AbstractDirectorDebug = {
        BuildSnapshot = function(...)
            directorArgs = { ... }
            return { kind = "director" }
        end,
    },
}

isServer = function() return true end

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerAuthorityDiagnosticCommandHandler"

Router.Handle("FactionDebugRequest", player, {})
T.equal(calls.factionDebug[2], nil, "unauthorized faction snapshot")
T.equal(calls.factionDebug[3], false, "unauthorized faction flag")
T.equal(calls.factionDebug[4], "not_authorized",
    "unauthorized faction reason")
T.equal(factionArgs, nil, "unauthorized faction builder called")

Router.Handle("CommunityDebugRequest", player, {})
T.equal(calls.communityDebug[3], false, "unauthorized community flag")
T.equal(calls.communityDebug[4], "not_authorized",
    "unauthorized community reason")
T.equal(communityArgs, nil, "unauthorized community builder called")

Router.Handle("NeedsDebugRequest", player, {})
T.equal(calls.needsDebug[3], false, "unauthorized Needs flag")
T.equal(calls.needsDebug[4], "not_authorized",
    "unauthorized Needs reason")
T.equal(needsArgs, nil, "unauthorized Needs builder called")

Router.Handle("DirectorDebugRequest", player, {})
T.equal(calls.directorDebug[3], false, "unauthorized Director flag")
T.equal(calls.directorDebug[4], "not_authorized",
    "unauthorized Director reason")
T.equal(directorArgs, nil, "unauthorized Director builder called")

Router.Handle("FactionMembersRequest", player, nil)
T.equal(calls.factionMembers[2].kind, "members",
    "faction members snapshot")
T.equal(calls.factionMembers[2].player, player,
    "faction members player")
T.equal(calls.factionMembers[3], "members_reason",
    "faction members reason")

Router.Handle("FactionMemberAction", player, nil)
T.equal(type(membershipActionArgs), "table",
    "nil faction action not normalized")
T.equal(calls.factionMembers[2].kind, "member_action",
    "faction action snapshot")
T.equal(calls.factionMembers[3], "action_reason",
    "faction action reason")
local actionArgs = { action = "promote", npcID = "npc-1" }
Router.Handle("FactionMemberAction", player, actionArgs)
T.equal(membershipActionArgs, actionArgs, "faction action payload identity")

player.access = "admin"
Router.Handle("FactionDebugRequest", player, {
    factionID = "faction-1",
    npcID = "npc-2",
    targetFactionID = "faction-2",
})
T.equal(factionArgs[1], "faction-1", "faction debug faction")
T.equal(factionArgs[2], "npc-2", "faction debug NPC")
T.equal(factionArgs[3], nil, "faction debug record")
T.equal(factionArgs[4], player, "faction debug player")
T.equal(factionArgs[5], "faction-2", "faction debug target")
T.equal(calls.factionDebug[2].kind, "faction", "faction response")
T.equal(calls.factionDebug[3], true, "faction authorized flag")

Router.Handle("CommunityDebugRequest", player, {
    communityID = "community-1",
    factionID = "faction-1",
    npcID = "npc-3",
})
T.equal(communityArgs[1], "community-1", "community ID")
T.equal(communityArgs[2], "faction-1", "community faction")
T.equal(communityArgs[3], "npc-3", "community NPC")
T.equal(communityArgs[4], nil, "community record")
T.equal(communityArgs[5], player, "community player")
T.equal(calls.communityDebug[3], true, "community authorized flag")

Router.Handle("NeedsDebugRequest", player, {
    groupID = "group-1",
    npcID = "npc-4",
})
T.equal(needsArgs[1], "group-1", "Needs group")
T.equal(needsArgs[2], "npc-4", "Needs NPC")
T.equal(needsArgs[3], nil, "Needs record")
T.equal(calls.needsDebug[3], true, "Needs authorized flag")

Router.Handle("DirectorDebugRequest", player, {
    groupID = "group-2",
    locationID = "location-1",
    populationSectorID = "sector-1",
})
T.equal(directorArgs[1], "group-2", "Director group")
T.equal(directorArgs[2], "location-1", "Director location")
T.equal(directorArgs[3], nil, "Director state")
T.equal(directorArgs[4], "sector-1", "Director sector")
T.equal(calls.directorDebug[3], true, "Director authorized flag")
T.finish("pnc_server_authority_diagnostic_command_handler_smoke")

T.finish("pnc_server_authority_diagnostic_command_handler_smoke")

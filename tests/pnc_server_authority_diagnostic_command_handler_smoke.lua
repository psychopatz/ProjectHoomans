local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
assertEqual(calls.factionDebug[2], nil, "unauthorized faction snapshot")
assertEqual(calls.factionDebug[3], false, "unauthorized faction flag")
assertEqual(calls.factionDebug[4], "not_authorized",
    "unauthorized faction reason")
assertEqual(factionArgs, nil, "unauthorized faction builder called")

Router.Handle("CommunityDebugRequest", player, {})
assertEqual(calls.communityDebug[3], false, "unauthorized community flag")
assertEqual(calls.communityDebug[4], "not_authorized",
    "unauthorized community reason")
assertEqual(communityArgs, nil, "unauthorized community builder called")

Router.Handle("NeedsDebugRequest", player, {})
assertEqual(calls.needsDebug[3], false, "unauthorized Needs flag")
assertEqual(calls.needsDebug[4], "not_authorized",
    "unauthorized Needs reason")
assertEqual(needsArgs, nil, "unauthorized Needs builder called")

Router.Handle("DirectorDebugRequest", player, {})
assertEqual(calls.directorDebug[3], false, "unauthorized Director flag")
assertEqual(calls.directorDebug[4], "not_authorized",
    "unauthorized Director reason")
assertEqual(directorArgs, nil, "unauthorized Director builder called")

Router.Handle("FactionMembersRequest", player, nil)
assertEqual(calls.factionMembers[2].kind, "members",
    "faction members snapshot")
assertEqual(calls.factionMembers[2].player, player,
    "faction members player")
assertEqual(calls.factionMembers[3], "members_reason",
    "faction members reason")

Router.Handle("FactionMemberAction", player, nil)
assertEqual(type(membershipActionArgs), "table",
    "nil faction action not normalized")
assertEqual(calls.factionMembers[2].kind, "member_action",
    "faction action snapshot")
assertEqual(calls.factionMembers[3], "action_reason",
    "faction action reason")
local actionArgs = { action = "promote", npcID = "npc-1" }
Router.Handle("FactionMemberAction", player, actionArgs)
assertEqual(membershipActionArgs, actionArgs, "faction action payload identity")

player.access = "admin"
Router.Handle("FactionDebugRequest", player, {
    factionID = "faction-1",
    npcID = "npc-2",
    targetFactionID = "faction-2",
})
assertEqual(factionArgs[1], "faction-1", "faction debug faction")
assertEqual(factionArgs[2], "npc-2", "faction debug NPC")
assertEqual(factionArgs[3], nil, "faction debug record")
assertEqual(factionArgs[4], player, "faction debug player")
assertEqual(factionArgs[5], "faction-2", "faction debug target")
assertEqual(calls.factionDebug[2].kind, "faction", "faction response")
assertEqual(calls.factionDebug[3], true, "faction authorized flag")

Router.Handle("CommunityDebugRequest", player, {
    communityID = "community-1",
    factionID = "faction-1",
    npcID = "npc-3",
})
assertEqual(communityArgs[1], "community-1", "community ID")
assertEqual(communityArgs[2], "faction-1", "community faction")
assertEqual(communityArgs[3], "npc-3", "community NPC")
assertEqual(communityArgs[4], nil, "community record")
assertEqual(communityArgs[5], player, "community player")
assertEqual(calls.communityDebug[3], true, "community authorized flag")

Router.Handle("NeedsDebugRequest", player, {
    groupID = "group-1",
    npcID = "npc-4",
})
assertEqual(needsArgs[1], "group-1", "Needs group")
assertEqual(needsArgs[2], "npc-4", "Needs NPC")
assertEqual(needsArgs[3], nil, "Needs record")
assertEqual(calls.needsDebug[3], true, "Needs authorized flag")

Router.Handle("DirectorDebugRequest", player, {
    groupID = "group-2",
    locationID = "location-1",
    populationSectorID = "sector-1",
})
assertEqual(directorArgs[1], "group-2", "Director group")
assertEqual(directorArgs[2], "location-1", "Director location")
assertEqual(directorArgs[3], nil, "Director state")
assertEqual(directorArgs[4], "sector-1", "Director sector")
assertEqual(calls.directorDebug[3], true, "Director authorized flag")

print("pnc_server_authority_diagnostic_command_handler_smoke: ok")

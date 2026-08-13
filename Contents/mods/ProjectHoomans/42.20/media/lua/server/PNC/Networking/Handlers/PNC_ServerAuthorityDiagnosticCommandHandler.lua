-- Authority diagnostic adapters. Domain services retain snapshot and action policy.

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Network = PNC.Network

Router.Register(Const.CMD_FACTION_DEBUG_REQUEST,
    function(player, args, rawArgs)
        if not Router.CanUseDebug(player) then
            Network.SendFactionDebug(player, nil, false, "not_authorized")
            return
        end
        Network.SendFactionDebug(
            player,
            PNC.FactionDebug.BuildSnapshot(
                rawArgs and rawArgs.factionID,
                rawArgs and rawArgs.npcID,
                nil,
                player,
                rawArgs and rawArgs.targetFactionID
            ),
            true,
            nil
        )
    end
)

Router.Register(Const.CMD_FACTION_MEMBERS_REQUEST, function(player)
    local snapshot
    local reason
    snapshot, reason = PNC.FactionMembership.BuildSnapshot(player)
    Network.SendFactionMembers(player, snapshot, reason)
end)

Router.Register(Const.CMD_FACTION_MEMBER_ACTION, function(player, args)
    local snapshot
    local reason
    snapshot, reason = PNC.FactionMembership.PerformAction(player, args)
    Network.SendFactionMembers(player, snapshot, reason)
end)

Router.Register(Const.CMD_COMMUNITY_DEBUG_REQUEST,
    function(player, args, rawArgs)
        if not Router.CanUseDebug(player) then
            Network.SendCommunityDebug(player, nil, false, "not_authorized")
            return
        end
        Network.SendCommunityDebug(
            player,
            PNC.CommunityDebug.BuildSnapshot(
                rawArgs and rawArgs.communityID,
                rawArgs and rawArgs.factionID,
                rawArgs and rawArgs.npcID,
                nil,
                player
            ),
            true,
            nil
        )
    end
)

Router.Register(Const.CMD_NEEDS_DEBUG_REQUEST,
    function(player, args, rawArgs)
        if not Router.CanUseDebug(player) then
            Network.SendNeedsDebug(player, nil, false, "not_authorized")
            return
        end
        Network.SendNeedsDebug(
            player,
            PNC.NeedsDebug.BuildSnapshot(
                rawArgs and rawArgs.groupID,
                rawArgs and rawArgs.npcID,
                nil
            ),
            true,
            nil
        )
    end
)

Router.Register(Const.CMD_DIRECTOR_DEBUG_REQUEST,
    function(player, args, rawArgs)
        if not Router.CanUseDebug(player) then
            Network.SendDirectorDebug(player, nil, false, "not_authorized")
            return
        end
        Network.SendDirectorDebug(
            player,
            PNC.AbstractDirectorDebug.BuildSnapshot(
                rawArgs and rawArgs.groupID,
                rawArgs and rawArgs.locationID,
                nil,
                rawArgs and rawArgs.populationSectorID
            ),
            true,
            nil
        )
    end
)

-- Colony-management network adapter. ColonyManagement retains action policy.

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Network = PNC.Network

Router.Register(Const.CMD_COLONY_MANAGEMENT_REQUEST, function(player)
    Network.SendColonyManagement(
        player,
        PNC.ColonyManagement.BuildSnapshot(player)
    )
end)

Router.Register(Const.CMD_COLONY_MANAGEMENT_ACTION,
    function(player, args, rawArgs)
        local snapshot
        local result
        if PNC.ColonyManagement and PNC.ColonyManagement.HandleAction then
            snapshot, result = PNC.ColonyManagement.HandleAction(
                player,
                rawArgs
            )
        else
            snapshot = PNC.ColonyManagement.BuildSnapshot(player)
            result = { ok = false, reason = "unknown_colony_action" }
        end
        snapshot.actionResult = result
        local settlementAction = {
            base_create = true, base_expand = true, base_shrink = true,
            barricade_build = true, hq_upgrade = true,
            facility_create = true, facility_upgrade = true,
            facility_component_set = true, facility_component_remove = true,
            facility_destroy = true, stockpile_node_create = true,
            stockpile_node_remove = true,
        }
        if settlementAction[tostring(rawArgs and rawArgs.action or "")]
            and Network.SendSettlementDelta
        then
            Network.SendSettlementDelta(
                player,
                snapshot.settlement,
                result,
                snapshot.storage
            )
        else
            Network.SendColonyManagement(player, snapshot)
        end
    end
)

-- Character roster/detail replication adapter.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

local function buildSnapshotList()
    local registry = PNC.Registry
    local network = PNC.Network
    local list = {}
    registry.ForEach(function(record)
        list[#list + 1] = network.BuildRosterSnapshot(record)
    end)
    if registry.ForEachDeathMarker and network.BuildDeathMarkerSnapshot then
        registry.ForEachDeathMarker(function(marker)
            list[#list + 1] = network.BuildDeathMarkerSnapshot(marker)
        end)
    end
    return list
end

Router.Register(Const.CMD_FULL_SYNC_REQUEST, function(player)
    PNC.Network.BroadcastFullSync(player, buildSnapshotList())
end)

Router.Register(Const.CMD_REQUEST_CHARACTER, function(player, args)
    if not args.id then return end
    local registry = PNC.Registry
    local network = PNC.Network
    local record = registry.Get(args.id)
    if record and network.CanViewCharacter(player, record) then
        if tonumber(args.inventoryRevision)
            and tonumber(args.inventoryRevision) > 0
        then
            network.SendInventoryDelta(
                player,
                record,
                args.inventoryRevision
            )
        else
            network.SendCharacterPayload(player, record)
        end
    else
        PNC.Core.LogWarn(
            "Rejected unauthorized NPC character request player="
                .. tostring(player and player.getUsername
                    and player:getUsername() or "unknown")
                .. " npc=" .. tostring(args.id)
        )
    end
end)

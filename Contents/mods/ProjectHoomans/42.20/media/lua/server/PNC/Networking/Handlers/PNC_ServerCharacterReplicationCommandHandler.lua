-- Character roster/detail replication adapter.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

local function buildSnapshotList(leanPortrait)
    local registry = PNC.Registry
    local network = PNC.Network
    local list = {}
    registry.ForEach(function(record)
        list[#list + 1] = network.BuildRosterSnapshot(record, true, leanPortrait)
    end)
    if registry.ForEachDeathMarker and network.BuildDeathMarkerSnapshot then
        registry.ForEachDeathMarker(function(marker)
            local snapshot = network.BuildDeathMarkerSnapshot(marker)
            if snapshot then
                list[#list + 1] = snapshot
            end
        end)
    end
    return list
end

Router.Register(Const.CMD_FULL_SYNC_REQUEST, function(player, args)
    local network = PNC.Network
    if network.NegotiateDomainDeltas then
        network.NegotiateDomainDeltas(player, args and args.domainDeltaProtocol)
    end
    local leanPortrait = network.NegotiateRosterPortraits
        and network.NegotiateRosterPortraits(player, args and args.portraitProtocol,
            args and args.portraitCodec, args and args.portraitPatch)
    network.BroadcastFullSync(
        player,
        buildSnapshotList(leanPortrait),
        args and (args.requestID or args.syncID) or nil,
        leanPortrait and Const.ROSTER_PORTRAIT_PROTOCOL or nil
    )
end)

if Const.CMD_REQUEST_RECORD_REPAIR then
    Router.Register(Const.CMD_REQUEST_RECORD_REPAIR, function(player, args)
        if type(args) ~= "table" or type(args.id) ~= "string"
            or args.id == "" or #args.id > 128
        then
            return false
        end
        local registry = PNC.Registry
        local network = PNC.Network
        local record = registry and registry.Get and registry.Get(args.id) or nil
        if not record then return false end
        if network and type(network.SendRecordRepair) == "function" then
            return network.SendRecordRepair(
                player, record, args.reason or "gap_repair"
            )
        end
        return false
    end)
end

Router.Register(Const.CMD_REQUEST_ROSTER_PORTRAIT, function(player, args)
    return PNC.Network.SendRosterPortrait(player, args)
end)

Router.Register(Const.CMD_REQUEST_CHARACTER, function(player, args)
    if not args.id then return end
    local registry = PNC.Registry
    local network = PNC.Network
    local record = registry.Get(args.id)
    if record and network.CanViewCharacter(player, record) then
        if args.forceFull == true then
            network.SendCharacterPayload(player, record)
        elseif tonumber(args.inventoryRevision)
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


Router.Register(Const.CMD_REQUEST_CHARACTER_INVENTORY, function(player, args)
    local registry
    local network
    local record
    if not args or not args.id then return end
    registry = PNC.Registry
    network = PNC.Network
    record = registry.Get(args.id)
    if record and network.CanViewCharacter(player, record)
        and network.SendCharacterInventoryPayload
    then
        network.SendCharacterInventoryPayload(player, record,
            args.requestID)
    else
        PNC.Core.LogWarn(
            "Rejected unauthorized NPC inventory request player="
                .. tostring(player and player.getUsername
                    and player:getUsername() or "unknown")
                .. " npc=" .. tostring(args.id)
        )
    end
end)

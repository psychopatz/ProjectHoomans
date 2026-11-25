-- Local debug actions for unique-NPC and tactical-class spawning.
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
return {
    spawn_unique_test = function(player, args)
        local uniqueAPI = PNC.API and PNC.API.UniqueNPCs
        local record
        local reason
        if not args.definitionId and not args.id then return false end
        if Core.IsClientOnly and Core.IsClientOnly() then
            if not sendClientCommand then
                return false, "network_unavailable"
            end
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
            return true, "request_sent"
        end
        if not uniqueAPI or not uniqueAPI.SpawnTest then
            return false, "unique_test_spawn_unavailable"
        end
        record, reason = uniqueAPI.SpawnTest(
            args.definitionId or args.id, player)
        ClientState.uniqueNPCTestSpawn = {
            success = record ~= nil,
            runtime = record and {
                id = tostring(record.id or ""),
                name = record.name,
                x = record.x,
                y = record.y,
                z = record.z,
            } or nil,
            reason = reason,
            at = Core.Now(),
        }
        return record ~= nil, reason, record
    end,

    spawn = function(player, args)
        if isClient and isClient() == true then
            if not player or not sendClientCommand then
                return false, "network_unavailable"
            end
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
            return true, "request_sent"
        end
        local handler = PNC.ServerDebugCommandHandler
        if not handler or not handler.Spawn then
            return false, "debug_spawn_unavailable"
        end
        local record, reason = handler.Spawn(player, args)
        return record ~= nil, reason, record
    end,

    spawn_mobile_group = function(player, args)
        if isClient and isClient() == true then
            if not player or not sendClientCommand then
                return false, "network_unavailable"
            end
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
            return true, "request_sent"
        end
        local handler = PNC.ServerDebugCommandHandler
        if not handler or not handler.SpawnMobileGroup then
            return false, "debug_mobile_group_spawn_unavailable"
        end
        local faction, reason, details = handler.SpawnMobileGroup(player, args)
        return faction ~= nil, reason, details or faction
    end,
}

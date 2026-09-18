-- Local debug actions for companion recruitment, audits, and teleportation.
local Client = PNC.Client
local Core = PNC.Core
local Registry = PNC.Registry
local ClientState = PNC.Network.ClientState
local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"

local CONTINUE = "__pnc_debug_dispatch_continue"

local function teleportLocalPlayerNear(record, player)
    if not record or not player then
        return false
    end
    local body = Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    local x = body and body:getX() or tonumber(record.x) or 0
    local y = body and body:getY() or tonumber(record.y) or 0
    local z = body and body:getZ() or tonumber(record.z) or 0
    return Teleport.ToCoordinates(player, x + 1.5, y + 1.5, z)
end

return {
    conversation_debug_recruit = function(player, args)
        local ok
        local reason
        if not PNC.DebugCompanionRecruit
            or not PNC.DebugCompanionRecruit.Try
        then
            return false, "debug_recruit_service_unavailable"
        end
        ok, reason = PNC.DebugCompanionRecruit.Try(player, args)
        if ok and Client.RequestColonyManagement then
            Client.RequestColonyManagement()
            if PNC.ColonyNamePrompt
                and PNC.ColonyNamePrompt.OpenIfNeeded
            then
                PNC.ColonyNamePrompt.OpenIfNeeded(
                    ClientState.colonyManagement
                )
            end
        end
        return ok, reason
    end,

    audit_bodies = function()
        if PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
            PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
            Client.RequestDebugRoster(false)
            return true
        end
        return nil, CONTINUE
    end,

    teleport_to_npc = function(player, args)
        if not args.id then
            return nil, CONTINUE
        end
        return teleportLocalPlayerNear(Registry.Get(args.id), player)
    end,
}

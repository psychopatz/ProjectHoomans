-- Revive and bandage action transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core

function Client.SendRevive(npcId)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId then
        return false
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false
        end
        sendClientCommand(player, Const.MODULE, Const.CMD_REVIVE, { id = npcId })
        return true
    end
    return PNC.Revive and PNC.Revive.Try and PNC.Revive.Try(player, npcId) or false
end

function Client.CompleteBandage(npcId, partId, debugFree, bandageType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId or not partId then return false end
    debugFree = debugFree == true and Client.CanUseDebug()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_BANDAGE, {
            id = npcId,
            partId = tostring(partId),
            debugFree = debugFree,
            bandageType = bandageType,
        })
        return true
    end
    return PNC.Treatment and PNC.Treatment.TryBandage
        and PNC.Treatment.TryBandage(player, npcId, partId, {
            consumeItem = not debugFree,
            bandageType = bandageType,
        }) or false
end

function Client.SendBandage(npcId, partId, debugFree, bandageType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId or not partId then return false end
    debugFree = debugFree == true and Client.CanUseDebug()
    if not PNCBandageAction or not PNCBandageAction.Queue then return false end
    return PNCBandageAction.Queue(player, npcId, partId, debugFree, bandageType)
end

return PNC.Client


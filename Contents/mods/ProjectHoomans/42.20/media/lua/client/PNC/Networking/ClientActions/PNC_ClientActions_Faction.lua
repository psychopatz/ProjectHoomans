-- Faction-member command transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Client.SendFactionMemberAction(
    memberAction,
    playerKey
)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    if not player then return false end
    local args = {
        memberAction = tostring(memberAction or ""),
        playerKey = playerKey
            and tostring(playerKey) or nil,
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_FACTION_MEMBER_ACTION,
            args
        )
        return true
    end
    if not PNC.FactionMembership
        or not PNC.FactionMembership.PerformAction
    then
        return false
    end
    local snapshot
    local reason
    snapshot, reason =
        PNC.FactionMembership.PerformAction(
            player,
            args
        )
    ClientState.factionMembers = snapshot
    ClientState.factionMembersReason = reason
    ClientState.lastFactionMembersReceiveAt = Core.Now()
    return snapshot ~= nil
end

return PNC.Client


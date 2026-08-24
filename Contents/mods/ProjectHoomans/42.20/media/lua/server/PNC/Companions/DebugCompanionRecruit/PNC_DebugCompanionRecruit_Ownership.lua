if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}
PNC.Recruitment = PNC.Recruitment or PNC.DebugCompanionRecruit
PNC.DebugCompanionRecruitInternal =
    PNC.DebugCompanionRecruitInternal or {}

local Recruit = PNC.DebugCompanionRecruit
local H = PNC.DebugCompanionRecruitInternal
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry
local Graph = PNC.RelationshipGraph

function H.ForceFollow(record, player, reason)
    local username = player and player.getUsername
        and player:getUsername() or nil
    local onlineID = player and player.getOnlineID
        and player:getOnlineID() or nil
    record.recruited = true
    record.faction = Const.FACTION_COLONIST
    record.ownerUsername = username
    record.ownerOnlineID = onlineID
    record.runtime = record.runtime or {}
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = username,
            ownerOnlineID = onlineID,
        })
    else
        record.orderSpec = {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = username,
            ownerOnlineID = onlineID,
        }
    end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_recruit")
    end
end

function H.PreserveOwnedState(record, player, reason)
    record.recruited = true
    record.faction = Const.FACTION_COLONIST
    if not record.ownerUsername and player and player.getUsername then
        record.ownerUsername = player:getUsername()
    end
    if record.ownerOnlineID == nil and player and player.getOnlineID then
        record.ownerOnlineID = player:getOnlineID()
    end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_membership_repair")
    end
end

return Recruit


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

function H.PlayerCharacterUUID(player)
    if not player
        or not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetCharacterUUID
    then
        return nil
    end
    local uuid = PNC.PlayerCharacters.GetCharacterUUID(player)
    return uuid ~= nil and tostring(uuid) or nil
end

local function recordOwnerCharacterUUID(record)
    local orderSpec = record and record.orderSpec or nil
    local generation = record and record.generation or nil
    local uuid = record and record.ownerCharacterUUID or nil
    if uuid == nil and orderSpec then
        uuid = orderSpec.ownerCharacterUUID
    end
    if uuid == nil
        and generation
        and tostring(generation.source or "") == "starting_companion_trait"
    then
        uuid = generation.playerCharacterUUID
    end
    return uuid ~= nil and tostring(uuid) or nil
end

function H.ForceFollow(record, player, reason)
    local username = player and player.getUsername
        and player:getUsername() or nil
    local onlineID = player and player.getOnlineID
        and player:getOnlineID() or nil
    local characterUUID = H.PlayerCharacterUUID(player)
    record.recruited = true
    record.tacticalClass = Const.TACTICAL_CLASS_COLONIST
    record.ownerUsername = username
    record.ownerOnlineID = onlineID
    record.ownerCharacterUUID = characterUUID
    record.runtime = record.runtime or {}
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = username,
            ownerOnlineID = onlineID,
            ownerCharacterUUID = characterUUID,
        })
    else
        record.orderSpec = {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = username,
            ownerOnlineID = onlineID,
            ownerCharacterUUID = characterUUID,
        }
    end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_recruit")
    end
end

function H.PreserveOwnedState(record, player, reason)
    local characterUUID = H.PlayerCharacterUUID(player)
    record.recruited = true
    record.tacticalClass = Const.TACTICAL_CLASS_COLONIST
    if not record.ownerUsername and player and player.getUsername then
        record.ownerUsername = player:getUsername()
    end
    if record.ownerOnlineID == nil and player and player.getOnlineID then
        record.ownerOnlineID = player:getOnlineID()
    end
    if record.ownerCharacterUUID == nil and characterUUID ~= nil then
        record.ownerCharacterUUID = characterUUID
    end
    if record.orderSpec
        and tostring(record.orderSpec.kind or "")
            == tostring(Const.ORDER_FOLLOW or "follow")
        and record.orderSpec.ownerCharacterUUID == nil
        and characterUUID ~= nil
    then
        record.orderSpec.ownerCharacterUUID = characterUUID
    end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_membership_repair")
    end
end

function H.ReleasePersonalOwnership(record, reason)
    local body
    local x
    local y
    local z
    if not record or record.alive == false then return false end
    record.recruited = false
    record.ownerUsername = nil
    record.ownerOnlineID = nil
    record.ownerCharacterUUID = nil
    if record.orderSpec
        and tostring(record.orderSpec.kind or "")
            == tostring(Const.ORDER_FOLLOW or "follow")
    then
        body = Registry.GetLiveZombie
            and Registry.GetLiveZombie(record.id) or nil
        x = body and body.getX and body:getX() or record.x or record.anchorX
        y = body and body.getY and body:getY() or record.y or record.anchorY
        z = body and body.getZ and body:getZ() or record.z or record.anchorZ
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, {
                kind = Const.ORDER_GUARD or "guard",
                x = x,
                y = y,
                z = z,
            })
        else
            record.orderSpec = {
                kind = Const.ORDER_GUARD or "guard",
                x = x,
                y = y,
                z = z,
            }
        end
    end
    record.runtime = record.runtime or {}
    record.runtime.followOrderActive = nil
    record.runtime.followOwnerResolveAttempts = nil
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_owner_character_released")
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(
            record,
            reason or "companion_owner_character_released"
        )
    end
    return true
end

function Recruit.ReleaseCharacterOwnership(characterUUID, reason)
    local released = 0
    characterUUID = characterUUID ~= nil
        and tostring(characterUUID) or nil
    if not characterUUID or not Registry or not Registry.ForEach then
        return 0
    end
    Registry.ForEach(function(record)
        if record and record.recruited == true
            and recordOwnerCharacterUUID(record) == characterUUID
            and H.ReleasePersonalOwnership(record, reason)
        then
            released = released + 1
        end
    end)
    return released
end

function Recruit.ReconcileCharacterOwnership(player, currentCharacterUUID)
    local username = player and player.getUsername
        and player:getUsername() or nil
    local released = 0
    currentCharacterUUID = currentCharacterUUID ~= nil
        and tostring(currentCharacterUUID) or H.PlayerCharacterUUID(player)
    if not username or not currentCharacterUUID
        or not Registry or not Registry.ForEach
    then
        return 0
    end
    Registry.ForEach(function(record)
        local boundUUID
        local ownerCharacter
        if not record or record.recruited ~= true
            or tostring(record.ownerUsername or "") ~= tostring(username)
        then
            return
        end
        boundUUID = recordOwnerCharacterUUID(record)
        if not boundUUID or boundUUID == currentCharacterUUID then
            return
        end
        ownerCharacter = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetRegistryRecord
            and PNC.PlayerCharacters.GetRegistryRecord(boundUUID)
            or nil
        if ownerCharacter
            and (
                tostring(ownerCharacter.status or "") == "dead"
                or tostring(ownerCharacter.status or "") == "retired"
            )
            and H.ReleasePersonalOwnership(
                record,
                "stale_dead_player_character_owner"
            )
        then
            released = released + 1
        end
    end)
    return released
end

return Recruit

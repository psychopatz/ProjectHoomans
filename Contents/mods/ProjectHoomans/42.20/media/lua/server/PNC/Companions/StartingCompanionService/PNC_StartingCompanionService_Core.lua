if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}
PNC.StartingCompanionServiceInternal =
    PNC.StartingCompanionServiceInternal or {}

local Starting = PNC.StartingCompanions
local H = PNC.StartingCompanionServiceInternal
local Traits = PNC.StartingCompanionTraits
local Identity = PNC.Identity
local Registry = PNC.Registry

Starting.NextRetryAt = Starting.NextRetryAt or {}
Starting.RETRY_DELAY_MS = 5000
Starting.ENRICHMENT_VERSION = 3

function H.NowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function H.PlayerFemale(player)
    if player and player.isFemale then
        local ok, value = pcall(player.isFemale, player)
        if ok then return value == true end
    end
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    return descriptor and descriptor.isFemale
        and descriptor:isFemale() == true or false
end

function H.PlayerSurname(player)
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    local surname = descriptor and descriptor.getSurname
        and descriptor:getSurname() or nil
    surname = tostring(surname or "")
    return surname ~= "" and surname or nil
end

function H.PlayerPosition(player)
    return player and player.getX and player:getX() or 0,
        player and player.getY and player:getY() or 0,
        player and player.getZ and player:getZ() or 0
end

function H.Persist(reason)
    if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
        return PNC.PersistenceCoordinator.Commit(reason)
    end
    local saved, why = PNC.PlayerCharacters.Save()
    if saved == false and why ~= "not_dirty" then return false, why end
    return true, "committed"
end

function H.UpdateState(characterUUID, state, reason)
    local _, why = PNC.PlayerCharacters.ApplyStartingCompanionState(
        characterUUID, state
    )
    if why ~= "updated" and why ~= "unchanged" then return false, why end
    return H.Persist(reason)
end

function H.OwnerMatches(record, player)
    if not record or record.recruited ~= true then return false end
    local username = player and player.getUsername
        and player:getUsername() or nil
    return username ~= nil and record.ownerUsername == username
end

return Starting


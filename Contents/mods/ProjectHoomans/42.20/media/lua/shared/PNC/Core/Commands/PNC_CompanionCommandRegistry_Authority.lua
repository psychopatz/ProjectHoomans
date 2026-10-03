-- Companion identity, ownership, reachability, and radio relay policy.
-- Gameplay order application remains in the parent command entry module.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local Equipment = PNC.Equipment
if type(Commands) ~= "table" then return false end

Commands.Internal = Commands.Internal or {}

function Commands.IsCompanion(record)
    if not record or record.alive == false then return false end
    if PNC.Identity and PNC.Identity.Verifier
        and PNC.Identity.Verifier.IsCompanion
    then
        return PNC.Identity.Verifier.IsCompanion(record)
    end
    return record.recruited == true
end

function Commands.IsOwnedByPlayer(record, player, ownershipContext)
    local organizationID
    local organization
    local uuid
    local playerKey
    if not record or not player then return false end
    if PNC.Identity and PNC.Identity.Verifier
        and PNC.Identity.Verifier.IsOwnedByPlayer
    then
        return PNC.Identity.Verifier.IsOwnedByPlayer(
            record, player, ownershipContext)
    end
    organizationID = record.affiliation
        and record.affiliation.factionID or nil
    organization = organizationID
        and PNC.Factions
        and PNC.Factions.Get
        and PNC.Factions.Get(organizationID)
        or nil
    if organization then
        if type(ownershipContext) == "table"
            and ownershipContext.unavailable == true
        then
            return false
        end
        if type(ownershipContext) == "table" then
            playerKey = ownershipContext.playerKey
                or ownershipContext.entityKey
        end
        uuid = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetCharacterUUID
            and not playerKey
            and PNC.PlayerCharacters.GetCharacterUUID(player)
            or nil
        if not playerKey then
            local context = PNC.PlayerContext and PNC.PlayerContext.Peek
                and PNC.PlayerContext.Peek(player) or nil
            local character = uuid and PNC.PlayerCharacters.Registry
                and PNC.PlayerCharacters.Registry.byUUID
                and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
            playerKey = context and context.entityKey
                or uuid and character and PNC.EntityRef
                    and PNC.EntityRef.ForPlayerIdentity(
                        character.accountKey or character.accountIdentity,
                        uuid
                    ) or nil
        end
        if playerKey then
            return organization.ownerPlayerKey == playerKey
                or organization.playerMemberKeys
                    and organization.playerMemberKeys[playerKey] == true
        end
        -- Organizational ownership is character-UUID scoped. If the stable
        -- key cannot be resolved, never fall back to account name or online
        -- ID and accidentally grant a replacement survivor authority.
        return false
    end
    return false
end

local function livePosition(record)
    local zombie = record and record.id and Registry.GetLiveZombie(record.id) or nil
    if zombie and (not zombie.isDead or not zombie:isDead()) then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    return tonumber(record and record.x),
        tonumber(record and record.y),
        tonumber(record and record.z)
end

Commands.Internal.LivePosition = livePosition

function Commands.CanPlayerCommand(record, player, radius)
    local x
    local y
    local z
    if not player or (player.isDead and player:isDead()) then
        return false, "invalid_player"
    end
    if not Commands.IsCompanion(record) then
        return false, "not_companion"
    end
    if not Commands.IsOwnedByPlayer(record, player) then
        return false, "not_owner"
    end
    if tostring(record.presenceState or Const.PRESENCE_LIVE)
        ~= tostring(Const.PRESENCE_LIVE)
    then
        return false, "not_live"
    end
    x, y, z = livePosition(record)
    if x == nil or y == nil or z == nil then
        return false, "position_missing"
    end
    if math.floor(tonumber(player:getZ()) or 0) ~= math.floor(z) then
        return false, "different_floor"
    end
    radius = math.max(
        1,
        math.min(
            tonumber(Const.COMPANION_COMMAND_RADIUS) or 20,
            tonumber(radius) or tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
        )
    )
    if Core.DistanceSq(player:getX(), player:getY(), x, y) > radius * radius then
        return false, "too_far"
    end
    return true, "commandable"
end

local function playerRadioActive(player)
    local deviceState = PsychopatzCore and PsychopatzCore.RadioDeviceState or nil
    if not deviceState or type(deviceState.FindActivePlayerDevice) ~= "function" then
        return false
    end
    -- Reuses the same "turned on and audible" verdict the radio UI and the
    -- discovery broadcasts rely on, so relay behavior stays consistent.
    local ok, device = pcall(deviceState.FindActivePlayerDevice, player)
    return ok and device ~= nil
end

-- Radio relay lets an owner reach a colonist who is out of earshot, on another
-- floor, or currently abstract, provided both ends carry working radio gear.
-- Only definitions that opt in with radioRelay = true are eligible, so the
-- proximity-only verbs keep the strict CanPlayerCommand contract.
function Commands.CanRelayCommand(record, player, definition)
    local gate = PNC.CommandRelayGate
    local radioGear
    if not gate or type(gate.Evaluate) ~= "function" then
        return false, "relay_unavailable"
    end
    if type(definition) ~= "table" or definition.radioRelay ~= true then
        return false, "relay_not_allowed"
    end
    radioGear = Equipment and Equipment.RadioGear or nil
    return gate.Evaluate({
        companion = Commands.IsCompanion(record) == true,
        owned = Commands.IsOwnedByPlayer(record, player) == true,
        dead = record ~= nil and record.alive == false,
        reachableDirectly = false,
        relayAllowed = true,
        playerRadio = playerRadioActive(player),
        npcRadio = radioGear and type(radioGear.HasEquipped) == "function"
            and radioGear.HasEquipped(record) == true or false,
    })
end

return true

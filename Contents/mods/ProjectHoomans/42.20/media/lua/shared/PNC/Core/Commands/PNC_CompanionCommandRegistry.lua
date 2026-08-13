-- Data-driven, authority-owned companion commands. Client adapters render the
-- same definitions in the emote radial and NPC context menu.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Network = PNC.Network
local Equipment = PNC.Equipment

Commands.Definitions = Commands.Definitions or {}
Commands.DefinitionOrder = Commands.DefinitionOrder or {}
Commands.Groups = Commands.Groups or {}
Commands.GroupOrder = Commands.GroupOrder or {}

local function appendDefinitionID(commandID)
    local i
    for i = 1, #Commands.DefinitionOrder do
        if Commands.DefinitionOrder[i] == commandID then return end
    end
    Commands.DefinitionOrder[#Commands.DefinitionOrder + 1] = commandID
end

function Commands.RegisterGroup(definition)
    local groupID
    if type(definition) ~= "table" then return false end
    groupID = tostring(definition.id or "")
    if groupID == "" then return false end
    definition.id = groupID
    Commands.Groups[groupID] = definition
    local i
    for i = 1, #Commands.GroupOrder do
        if Commands.GroupOrder[i] == groupID then return true end
    end
    Commands.GroupOrder[#Commands.GroupOrder + 1] = groupID
    return true
end

function Commands.GetGroup(groupID)
    return Commands.Groups[tostring(groupID or "")]
end

function Commands.ListGroups()
    local output = {}
    local i
    local definition
    for i = 1, #Commands.GroupOrder do
        definition = Commands.Groups[Commands.GroupOrder[i]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

function Commands.Register(definition)
    local commandID
    if type(definition) ~= "table" then return false end
    commandID = tostring(definition.id or "")
    if commandID == "" or (
        type(definition.buildOrder) ~= "function"
        and definition.attackType == nil
        and type(definition.apply) ~= "function"
    ) then
        return false
    end
    definition.id = commandID
    Commands.Definitions[commandID] = definition
    appendDefinitionID(commandID)
    return true
end

function Commands.NormalizeAttackType(value)
    if PNC.Types and PNC.Types.NormalizeAttackType then
        return PNC.Types.NormalizeAttackType(value)
    end
    value = string.lower(tostring(value or "auto"))
    if value == "auto" or value == "melee"
        or value == "ranged" or value == "none"
    then
        return value
    end
    return "auto"
end

function Commands.GetCurrentAttackType(record)
    return Commands.NormalizeAttackType(record and record.attackType)
end

function Commands.IsCurrent(record, commandID)
    local definition = Commands.Get(commandID)
    if not definition or definition.attackType == nil then return false end
    return Commands.GetCurrentAttackType(record)
        == Commands.NormalizeAttackType(definition.attackType)
end

function Commands.GetAttackTypeDefinition(attackType)
    local normalized = Commands.NormalizeAttackType(attackType)
    local definitions = Commands.List()
    local i
    local definition
    for i = 1, #definitions do
        definition = definitions[i]
        if definition.attackType ~= nil
            and Commands.NormalizeAttackType(definition.attackType) == normalized
        then
            return definition
        end
    end
    return nil
end

function Commands.Get(commandID)
    return Commands.Definitions[tostring(commandID or "")]
end

function Commands.List()
    local output = {}
    local i
    local definition
    for i = 1, #Commands.DefinitionOrder do
        definition = Commands.Definitions[Commands.DefinitionOrder[i]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

local function ownerUsername(record)
    return record and (
        record.ownerUsername
        or record.characterWindow and record.characterWindow.ownerUsername
    ) or nil
end

local function ownerOnlineID(record)
    return record and (
        record.ownerOnlineID
        or record.characterWindow and record.characterWindow.ownerOnlineID
    ) or nil
end

function Commands.IsCompanion(record)
    local faction
    local hasOwner
    if not record or record.alive == false then return false end
    faction = tostring(record.faction or "")
    hasOwner = ownerUsername(record) ~= nil or ownerOnlineID(record) ~= nil
    return (faction == tostring(Const.FACTION_COLONIST or "colonist")
        or faction == "companion")
        and (record.recruited == true or hasOwner)
end

function Commands.IsOwnedByPlayer(record, player)
    local recordUsername
    local recordOnlineID
    local username
    local onlineID
    local organizationID
    local organization
    local uuid
    local playerKey
    if not record or not player then return false end
    organizationID = record.affiliation
        and record.affiliation.factionID or nil
    organization = organizationID
        and PNC.Factions
        and PNC.Factions.Get
        and PNC.Factions.Get(organizationID)
        or nil
    if organization and organization.ownerPlayerKey then
        uuid = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetCharacterUUID
            and PNC.PlayerCharacters.GetCharacterUUID(player)
            or nil
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
        if playerKey then
            return organization.playerMemberKeys[playerKey] == true
        end
        -- Organizational ownership is character-UUID scoped. If the stable
        -- key cannot be resolved, never fall back to account name or online
        -- ID and accidentally grant a replacement survivor authority.
        return false
    end
    recordUsername = ownerUsername(record)
    recordOnlineID = tonumber(ownerOnlineID(record))
    username = player.getUsername and tostring(player:getUsername() or "") or ""
    onlineID = player.getOnlineID and tonumber(player:getOnlineID()) or nil
    if recordUsername ~= nil and username ~= ""
        and tostring(recordUsername) == username
    then
        return true
    end
    return recordOnlineID ~= nil and onlineID ~= nil
        and recordOnlineID == onlineID
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

local function refreshEquipmentState(record)
    local equipmentInfo
    if not Equipment or not Equipment.Describe then return end
    equipmentInfo = Equipment.Describe(record)
    record.runtime = record.runtime or {}
    record.runtime.combatModeResolved = equipmentInfo.combatModeResolved
    record.runtime.weaponStatus = equipmentInfo.weaponStatus
end

local function applyAttackType(record, definition)
    local attackType = Commands.NormalizeAttackType(definition.attackType)
    local zombie
    if definition.attackType == nil then return false end
    record.attackType = attackType
    if attackType == (Const.ATTACK_TYPE_AUTO or "auto") then
        record.weaponMode = "mixed"
    elseif attackType == (Const.ATTACK_TYPE_MELEE or "melee") then
        record.weaponMode = "melee"
    elseif attackType == (Const.ATTACK_TYPE_RANGED or "ranged") then
        record.weaponMode = "ranged"
    end
    if attackType == (Const.ATTACK_TYPE_NONE or "none") then
        zombie = record.id and Registry.GetLiveZombie(record.id) or nil
        if PNC.Combat and PNC.Combat.Internal
            and PNC.Combat.Internal.finishAttackAction
        then
            PNC.Combat.Internal.finishAttackAction(record, zombie)
        elseif record.runtime then
            record.runtime.attackAction = nil
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.ClearCombatTarget then
            PNC.BehaviorCommon.ClearCombatTarget(
                record,
                "attack_type_none",
                zombie
            )
        end
    end
    refreshEquipmentState(record)
    if attackType == (Const.ATTACK_TYPE_NONE or "none") then
        record.runtime = record.runtime or {}
        record.runtime.combatModeResolved = "none"
        record.runtime.weaponStatus = "holstered"
        record.runtime.combatBlockReason = "attack_type_none"
    end
    Registry.MarkDirty(record, "equipment")
    Registry.MarkDirty(record, "combat")
    return true
end

function Commands.Apply(record, player, commandID, radius)
    local definition = Commands.Get(commandID)
    local allowed
    local reason
    local orderSpec
    if not Core.IsAuthority() then return false, "not_authority" end
    if not definition then return false, "unknown_command" end
    allowed, reason = Commands.CanPlayerCommand(record, player, radius)
    if not allowed then return false, reason end
    if type(definition.buildOrder) == "function" then
        orderSpec = definition.buildOrder(record, player)
        if type(orderSpec) ~= "table" then return false, "invalid_order" end
        OrderSystem.SetOrder(record, orderSpec)
    end
    applyAttackType(record, definition)
    if type(definition.apply) == "function" then
        reason = definition.apply(record, player)
        if reason == false then return false, "command_rejected" end
    end
    record.runtime = record.runtime or {}
    record.runtime.lastCompanionCommand = tostring(definition.id)
    record.runtime.lastCompanionCommandAt = Core.Now()
    record.runtime.lastCompanionCommandRevision =
        (tonumber(record.runtime.lastCompanionCommandRevision) or 0) + 1
    record.runtime.lastCompanionCommandOwner = player.getUsername
        and tostring(player:getUsername() or "") or nil
    Network.BroadcastRecord(
        record,
        "companion_command_" .. tostring(definition.id)
    )
    return true, "commanded"
end

function Commands.Execute(player, args)
    local commandID = tostring(args and args.commandID or "")
    local targetID = args and args.id or nil
    local scope = string.lower(tostring(args and args.scope or ""))
    local radius = tonumber(args and args.radius)
        or tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
    local definition = Commands.Get(commandID)
    local affected = 0
    local lastReason = "no_targets"
    local applied
    local reason
    local closestRecord
    local closestDistSq
    local closestID
    local x
    local y
    local z
    local distSq
    if commandID == "" or not definition then
        return 0, "unknown_command"
    end
    if scope == "group" and definition.attackType ~= nil then
        return 0, "personalized_command"
    end
    if scope == "closest" then
        Registry.ForEach(function(record)
            local allowed = Commands.CanPlayerCommand(record, player, radius)
            if not allowed then return end
            x, y, z = livePosition(record)
            if x == nil or y == nil or z == nil then return end
            distSq = Core.DistanceSq(player:getX(), player:getY(), x, y)
            if closestRecord == nil or distSq < closestDistSq
                or (distSq == closestDistSq
                    and tostring(record.id) < tostring(closestID))
            then
                closestRecord = record
                closestDistSq = distSq
                closestID = record.id
            end
        end)
        if not closestRecord then return 0, "no_targets" end
        applied, reason = Commands.Apply(
            closestRecord,
            player,
            commandID,
            radius
        )
        return applied and 1 or 0, reason
    end
    if targetID ~= nil then
        applied, reason = Commands.Apply(
            Registry.Get(targetID),
            player,
            commandID,
            radius
        )
        return applied and 1 or 0, reason
    end
    if definition.attackType ~= nil then
        return 0, "personalized_command"
    end
    Registry.ForEach(function(record)
        applied, reason = Commands.Apply(record, player, commandID, radius)
        if applied then
            affected = affected + 1
        elseif reason ~= "not_companion" and reason ~= "not_owner" then
            lastReason = reason
        end
    end)
    return affected, affected > 0 and "commanded" or lastReason
end

return Commands

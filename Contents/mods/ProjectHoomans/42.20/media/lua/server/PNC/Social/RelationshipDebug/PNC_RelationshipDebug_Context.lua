if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Internal = Debug.Internal
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Core = PNC.Core

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    local value = gameTime
        and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
    if value ~= value or value == math.huge or value == -math.huge then
        return 0
    end
    return math.max(0, value)
end

local function displayName(record)
    local summary = record and record.identitySummary or nil
    local character = record and record.characterWindow or nil
    return tostring(
        summary and summary.displayName
        or character and character.displayName
        or record and record.name
        or record and record.id
        or "Unknown NPC"
    )
end

local function resolveTarget(player, args, at)
    local targetKind = tostring(args and args.targetKind or "")
    local targetID
    local record
    local key
    if targetKind == "current_player" then
        if not PNC.PlayerCharacters
            or not PNC.PlayerCharacters.GetEntityKey
        then
            return nil, nil, "player_identity_unavailable"
        end
        key, targetID = PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "relationship_debug",
            worldAgeHours = at,
        })
        if not key then
            return nil, nil, targetID
        end
        return key, {
            kind = "player",
            key = key,
            label = player and player.getDisplayName
                and tostring(player:getDisplayName())
                or player and player.getUsername
                and tostring(player:getUsername())
                or "Current player",
        }
    end
    if targetKind ~= "npc" then
        return nil, nil, "invalid_target_kind"
    end
    targetID = args and args.targetNPCID
    if type(targetID) ~= "string"
        and type(targetID) ~= "number"
    then
        return nil, nil, "invalid_target_npc_id"
    end
    targetID = tostring(targetID)
    record = Registry and Registry.Get and Registry.Get(targetID) or nil
    if not record or record.alive == false then
        return nil, nil, "target_npc_not_found"
    end
    key = EntityRef.ForNPC(targetID)
    if not key then
        return nil, nil, "invalid_target_key"
    end
    return key, {
        kind = "npc",
        key = key,
        npcID = targetID,
        label = displayName(record),
    }
end

Internal.copy = copy
Internal.worldAgeHours = worldAgeHours
Internal.displayName = displayName
Internal.resolveTarget = resolveTarget

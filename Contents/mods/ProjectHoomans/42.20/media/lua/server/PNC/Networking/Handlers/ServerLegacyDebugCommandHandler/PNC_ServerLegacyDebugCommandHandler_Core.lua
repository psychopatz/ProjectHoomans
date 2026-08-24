if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerLegacyDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

function Handler.ConfigureTeleport(value)
    H.Teleport = value
end

function H.ResolveDebugArchetype(args, faction, fallbackID)
    local explicit = args and args.archetypeID or nil
    local defaults
    local archetypes = PNC.Archetypes
    if explicit and archetypes and archetypes.Get then
        return archetypes.Get(explicit).id
    end
    if archetypes then
        defaults = faction == "hostile" and archetypes.GetHostileDefaults
            and archetypes.GetHostileDefaults()
            or archetypes.GetColonistDefaults
                and archetypes.GetColonistDefaults()
        if type(defaults) == "table" and defaults[1] then
            return tostring(defaults[1])
        end
    end
    return fallbackID
end

function H.HandleDebugSpawn(player, args)
    local x = tonumber(args and args.x) or (player and player:getX()) or 0
    local y = tonumber(args and args.y) or (player and player:getY()) or 0
    local z = tonumber(args and args.z) or (player and player:getZ()) or 0
    local variant = tostring(args and args.variant or "colonist")
    local legacyFaction = (variant == "hostile_melee"
        or variant == "hostile_ranged") and "hostile" or variant
    local faction = PNC.Types.NormalizeFaction(
        args and args.faction or legacyFaction
    )
    local equipmentSpawnMode = PNC.Inventory.GetDebugEquipmentSpawnMode(
        variant,
        args and args.equipmentSpawnMode
    )
    local colonist = faction == "colonist"
    local hostile = faction == "hostile"
    if faction ~= "colonist" and faction ~= "neutral"
        and faction ~= "hostile"
    then
        faction = "colonist"
        colonist = true
        hostile = false
    end
    local ownerUsername = colonist and player and player:getUsername() or nil
    local ownerOnlineID = colonist and player and player:getOnlineID() or nil
    local orderSpec = hostile
        and { kind = Const.ORDER_HOSTILE_HUNT, x = x, y = y, z = z }
        or colonist and {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = ownerUsername,
            ownerOnlineID = ownerOnlineID,
        }
        or {
            kind = Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_AREA,
            x = x,
            y = y,
            z = z,
            radius = Const.ROAM_DEFAULT_RADIUS,
        }
    local record = PNC.API.Spawn({
        faction = faction,
        archetypeID = H.ResolveDebugArchetype(
            args,
            faction,
            hostile and "Scavenger" or "General"
        ),
        x = x,
        y = y,
        z = z,
        ownerUsername = ownerUsername,
        ownerOnlineID = ownerOnlineID,
        orderSpec = orderSpec,
        forceLive = true,
        equipmentSpawnMode = equipmentSpawnMode,
        debug = true,
    })
    PNC.Core.LogInfo("PNC debug spawn variant=" .. variant
        .. " faction=" .. faction
        .. " equipment=" .. tostring(equipmentSpawnMode or "sandbox_chances")
        .. " id=" .. tostring(record and record.id or "failed"))
    return record
end

function H.FindTeleportPosition(record)
    local body = record and PNC.Registry.GetLiveZombie(record.id) or nil
    local x = body and body:getX() or tonumber(record and record.x) or 0
    local y = body and body:getY() or tonumber(record and record.y) or 0
    local z = body and body:getZ() or tonumber(record and record.z) or 0
    local cell = getCell and getCell() or nil
    local offsets = {
        { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
    }
    local i
    if cell then
        for i = 1, #offsets do
            local square = cell:getGridSquare(
                math.floor(x) + offsets[i][1],
                math.floor(y) + offsets[i][2],
                math.floor(z)
            )
            if square and (not square.isFree or square:isFree(false)) then
                return square:getX() + 0.5,
                    square:getY() + 0.5,
                    square:getZ()
            end
        end
    end
    return x + 1.5, y + 1.5, z
end

function H.TeleportPlayerToRecord(player, npcId)
    local record = npcId and PNC.Registry.Get(npcId) or nil
    local x
    local y
    local z
    if not player or not record then
        return false
    end
    x, y, z = H.FindTeleportPosition(record)
    if H.Teleport.ToCoordinates(player, x, y, z) then
        PNC.Core.LogInfo("PNC debug queued teleport for "
            .. tostring(player:getUsername())
            .. " near NPC " .. tostring(record.id))
        return true
    end
    PNC.Core.LogWarn("PNC debug teleport unavailable for NPC "
        .. tostring(record.id))
    return false
end

return Handler


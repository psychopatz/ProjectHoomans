-- Legacy debug-envelope adapter. Action strings remain one compatibility API.

PNC.ServerLegacyDebugCommandHandler =
    PNC.ServerLegacyDebugCommandHandler or {}

local Handler = PNC.ServerLegacyDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Teleport

function Handler.ConfigureTeleport(value)
    Teleport = value
end

local function resolveDebugArchetype(args, faction, fallbackID)
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

local function handleDebugSpawn(player, args)
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
        archetypeID = resolveDebugArchetype(
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

local function findTeleportPosition(record)
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

local function teleportPlayerToRecord(player, npcId)
    local record = npcId and PNC.Registry.Get(npcId) or nil
    local x
    local y
    local z
    if not player or not record then
        return false
    end
    x, y, z = findTeleportPosition(record)
    if Teleport.ToCoordinates(player, x, y, z) then
        PNC.Core.LogInfo("PNC debug queued teleport for "
            .. tostring(player:getUsername())
            .. " near NPC " .. tostring(record.id))
        return true
    end
    PNC.Core.LogWarn("PNC debug teleport unavailable for NPC "
        .. tostring(record.id))
    return false
end

local directDebugActions = {
    force_live = true,
    force_abstract = true,
    heal = true,
    revive = true,
    damage = true,
    damage_part = true,
    infection = true,
    clear_infection = true,
    bandage_almost_dirty = true,
    animation_scene_play = true,
    animation_scene_pool_step = true,
    animation_scene_pool_start = true,
    animation_scene_stop = true,
    set_map_presentation = true,
    set_weapon_mode = true,
    set_equipment_slot = true,
    clear_equipment = true,
    toggle_debug = true,
}

local function handleRelationshipAction(player, args)
    local network = PNC.Network
    if args.action == "social_trigger_event" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.TriggerSocialEvent(player, args)
        network.SendRelationshipDebug(player, snapshot, true, reason)
        return true
    end
    if args.action == "conversation_relationship_standing" then
        local summary
        local reason
        summary, reason = PNC.RelationshipDebug.SetConversationStanding(
            player,
            args
        )
        network.SendConversationRelationship(player, summary, reason)
        return true
    end
    if args.action == "relationship_debug_baseline" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.ApplyDebugBaseline(
            player,
            args
        )
        network.SendRelationshipDebug(player, snapshot, true, reason)
        return true
    end
    if args.action == "relationship_pacification" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.SetPlayerPacification(
            player,
            args
        )
        network.SendRelationshipDebug(player, snapshot, true, reason)
        return true
    end
    return false
end

local function handleKnowledgeOrRecruitAction(player, args)
    local network = PNC.Network
    if args.action == "knowledge_debug_action" then
        local snapshot
        local reason
        if PNC.NPCKnowledge and PNC.NPCKnowledge.ExecuteDebugForPlayer then
            snapshot, reason = PNC.NPCKnowledge.ExecuteDebugForPlayer(
                player,
                args
            )
        else
            reason = "knowledge_service_unavailable"
        end
        network.SendKnowledgeDebug(player, snapshot, true, reason)
        return true
    end
    if args.action == "conversation_debug_recruit" then
        local ok
        local reason
        if PNC.DebugCompanionRecruit and PNC.DebugCompanionRecruit.Try then
            ok, reason = PNC.DebugCompanionRecruit.Try(player, args)
        else
            ok, reason = false, "debug_recruit_service_unavailable"
        end
        if ok ~= true then
            PNC.Core.LogWarn("Rejected debug companion recruit npc="
                .. tostring(args.npcID or args.id or "unknown")
                .. " reason=" .. tostring(reason))
        elseif PNC.ColonyManagement
            and PNC.ColonyManagement.BuildSnapshot
        then
            network.SendColonyManagement(
                player,
                PNC.ColonyManagement.BuildSnapshot(player)
            )
        end
        return true
    end
    return false
end

local function handleDiagnosticAction(player, args)
    local network = PNC.Network
    if args.action == "faction_debug_action" then
        network.SendFactionDebug(
            player,
            PNC.FactionDebug.PerformAction(player, args),
            true,
            nil
        )
        return true
    end
    if args.action == "community_debug_action" then
        network.SendCommunityDebug(
            player,
            PNC.CommunityDebug.PerformAction(player, args),
            true,
            nil
        )
        return true
    end
    if args.action == "needs_debug_action" then
        network.SendNeedsDebug(
            player,
            PNC.NeedsDebug.PerformAction(args),
            true,
            nil
        )
        return true
    end
    if args.action == "director_debug_action" then
        network.SendDirectorDebug(
            player,
            PNC.AbstractDirectorDebug.PerformAction(args),
            true,
            nil
        )
        return true
    end
    return false
end

local function handleAPIAction(player, args)
    local api = PNC.API
    if directDebugActions[args.action] then
        api.DebugCommand(args.id, args.action, args)
        return true
    end
    if args.action == "set_map_known" then
        args.playerKey = player and player.getUsername
            and player:getUsername() or nil
        api.DebugCommand(args.id, "set_map_known", args)
        return true
    end
    if args.action == "copy_held_weapon" then
        if player and player.getPrimaryHandItem then
            local primary = player:getPrimaryHandItem()
            if primary and primary.getFullType then
                args.weaponFullType = primary:getFullType()
            end
        end
        args.sourcePlayer = player
        api.DebugCommand(args.id, "copy_held_weapon", args)
        return true
    end
    if args.action == "copy_player_loadout" then
        args.sourcePlayer = player
        api.DebugCommand(args.id, "copy_player_loadout", args)
        return true
    end
    if args.action == "set_order" then
        api.SetOrder(args.id, args.orderSpec)
        return true
    end
    if args.action == "set_hostility" then
        api.SetHostility(args.id, args.modeSpec)
        return true
    end
    return false
end

local function handleBodyAudit(player, args)
    if args.action == "audit_bodies" then
        local bodyLifecycle = PNC.BodyLifecycle
        if bodyLifecycle and bodyLifecycle.AuditLoadedBodies then
            bodyLifecycle.AuditLoadedBodies(PNC.Core.Now(), true)
        end
        PNC.Network.SendDebugRoster(
            player,
            bodyLifecycle and bodyLifecycle.BuildDebugRoster
                and bodyLifecycle.BuildDebugRoster() or {},
            true,
            bodyLifecycle and bodyLifecycle.LastAudit or {}
        )
        return true
    end
    return false
end

Router.Register(Const.CMD_DEBUG, function(player, normalizedArgs, rawArgs)
    local args = rawArgs
    if not Router.CanUseDebug(player) then
        PNC.Core.LogWarn("Rejected unauthorized PNC debug command action="
            .. tostring(args and args.action or "unknown"))
        return
    end
    if not args then return end
    if args.action == "spawn" then
        handleDebugSpawn(player, args)
        return
    end
    if args.action == "teleport_to_npc" then
        teleportPlayerToRecord(player, args.id)
        return
    end
    if handleRelationshipAction(player, args) then return end
    if handleKnowledgeOrRecruitAction(player, args) then return end
    if handleDiagnosticAction(player, args) then return end
    if handleAPIAction(player, args) then return end
    if handleBodyAudit(player, args) then return end
end)

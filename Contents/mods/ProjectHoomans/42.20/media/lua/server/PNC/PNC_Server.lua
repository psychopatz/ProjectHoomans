--[[
    PNC Server Authority
    Owns server-side NPC ticking, presence reconciliation, sync dispatch, and
    debug command routing. Clients never create authoritative NPC records here.
]]

if isClient() and not isServer() then
    return
end

local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"

PNC = PNC or {}
PNC.Server = PNC.Server or {}

local Server = PNC.Server
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local Presence = PNC.Presence
local Health = PNC.Health
local Behavior = PNC.BehaviorSystem
local PathService = PNC.PathService
local Scheduler = PNC.Scheduler
local SimulationClock = PNC.SimulationClock
local SimulationLOD = PNC.SimulationLOD
local Performance = PNC.Performance
local Network = PNC.Network
local API = PNC.API
local ZombieAggro = PNC.ZombieAggro
local Stamina = PNC.Stamina
local Archetypes = PNC.Archetypes
local Types = PNC.Types
local Animation = PNC.Animation
local BodyLifecycle = PNC.BodyLifecycle
local PlayerDamage = PNC.PlayerDamage
local Treatment = PNC.Treatment
local CompanionCommands = PNC.CompanionCommands
local MapCommandService = PNC.MapCommandService
local ConversationScene = PNC.ConversationScene
local PlayerCharacterLifecycle = PNC.PlayerCharacterLifecycle
local buildDebugRoster
local lastLivePositionSafetyRefreshAt = 0

local function canUseDebug(player)
    local access
    if not isServer or not isServer() then
        if isDebugEnabled then
            return isDebugEnabled() == true
        end
        return getCore and getCore() and getCore():getDebug() == true or false
    end
    access = player and player.getAccessLevel and tostring(player:getAccessLevel() or "") or ""
    return string.lower(access) == "admin"
end

local function getSyncInterval(record)
    local runtime = record and record.runtime or nil
    if record and record.presenceState ~= Const.PRESENCE_LIVE then
        return 500
    end
    if runtime and runtime.attackAction then
        return 75
    end
    if runtime and runtime.target then
        return 100
    end
    if runtime and runtime.pathing and (runtime.pathing.phase == "requested" or runtime.pathing.phase == "active") then
        return 150
    end
    if runtime and runtime.pathing and Core.Now() < ((tonumber(runtime.pathing.visualMovingUntil) or 0) + 250) then
        return 150
    end
    return 500
end

local function resolveDebugArchetype(args, faction, fallbackID)
    local explicit = args and args.archetypeID or nil
    local defaults
    if explicit and Archetypes and Archetypes.Get then
        return Archetypes.Get(explicit).id
    end
    if Archetypes then
        defaults = faction == "hostile" and Archetypes.GetHostileDefaults and Archetypes.GetHostileDefaults()
            or Archetypes.GetColonistDefaults and Archetypes.GetColonistDefaults()
        if type(defaults) == "table" and defaults[1] then
            return tostring(defaults[1])
        end
    end
    return fallbackID
end

local function buildSnapshotList()
    local list = {}
    Registry.ForEach(function(record)
        list[#list + 1] = Network.BuildRosterSnapshot(record)
    end)
    if Registry.ForEachDeathMarker and Network.BuildDeathMarkerSnapshot then
        Registry.ForEachDeathMarker(function(marker)
            list[#list + 1] = Network.BuildDeathMarkerSnapshot(marker)
        end)
    end
    return list
end

local function processRecord(record, now)
    local zombie = Registry.GetLiveZombie(record.id)
    local forceSyncEvent
    local decisionInterval
    local pathDue = false
    local forcePresence = record.runtime
        and record.runtime.forcePresenceCheck == true
    if zombie and Registry.RefreshLivePosition then
        Registry.RefreshLivePosition(record, zombie, false)
    end
    if ConversationScene and ConversationScene.Pump then
        ConversationScene.Pump(record, zombie, now)
    end
    if not SimulationClock
        or SimulationClock.IsDue(
            record,
            "presence",
            now,
            SimulationLOD and SimulationLOD.GetPresenceInterval(record) or 500,
            forcePresence
        )
    then
        Presence.Reconcile(record)
    end
    zombie = Registry.GetLiveZombie(record.id)
    if not SimulationClock
        or SimulationClock.IsDue(
            record,
            "vitals",
            now,
            SimulationLOD and SimulationLOD.GetVitalsInterval(record) or 250,
            false
        )
    then
        Health.Update(record, zombie, now)
        if Stamina and Stamina.Update then
            Stamina.Update(record, zombie, now)
        end
    end

    if record.alive == false then
        if not (record.runtime and record.runtime.deathRetired)
            and record.lastSyncAt ~= record.presenceRevision
        then
            Network.BroadcastRemoval(record.id, "death")
            record.lastSyncAt = record.presenceRevision
        end
        if Spatial and Spatial.RemoveNPC then
            Spatial.RemoveNPC(record.id)
        end
        return
    end

    if now >= (tonumber(record.nextThinkAt) or 0) then
        record.runtime = record.runtime or {}
        record.runtime.abstractStepElapsedMs = math.max(
            0,
            now - (tonumber(record.lastThinkAt) or now)
        )
        Behavior.Tick(record, zombie, now)
        -- A behavior may abstract a boarding companion or materialize a
        -- disembarking one. Refresh the lease-bound body before any pathing or
        -- animation work so this tick never pumps a removed IsoZombie (and a
        -- newly materialized passenger is immediately eligible for setup).
        zombie = Registry.GetLiveZombie(record.id)
        record.lastThinkAt = now
        decisionInterval = SimulationLOD
            and SimulationLOD.GetDecisionInterval(record)
            or Scheduler.GetCadence(record)
        record.nextThinkAt = now + decisionInterval
    end

    pathDue = zombie and record.alive ~= false and (
        not SimulationClock
        or SimulationClock.IsDue(
            record,
            "path",
            now,
            SimulationLOD and SimulationLOD.GetPathInterval(record) or 100,
            false
        )
    )
    if pathDue then
        PathService.Pump(record, zombie)
        if Registry.RefreshLivePosition then
            Registry.RefreshLivePosition(record, zombie, false)
        end
    end

    forceSyncEvent = record.runtime and record.runtime.forceSyncEvent or nil
    if forceSyncEvent then
        record.runtime.forceSyncEvent = nil
        Network.BroadcastRecord(record, forceSyncEvent)
        record.lastSyncAt = now
    elseif (now - (tonumber(record.lastSyncAt) or 0)) >= getSyncInterval(record) then
        Network.BroadcastRecord(record, "tick")
        record.lastSyncAt = now
    end

    if zombie and pathDue and Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie, record)
    end
    if Spatial and Spatial.UpdateNPC then
        Spatial.UpdateNPC(record)
    end
    if Network and Network.QueuePeriodicRoster then
        Network.QueuePeriodicRoster(record, now)
    end
    if Scheduler and Scheduler.Schedule then
        Scheduler.Schedule(record, now + Scheduler.GetCadence(record))
    end
end

function Server.OnTick()
    local now = Core.Now()
    local startedAt = Performance and Performance.Begin and Performance.Begin() or nil
    local due
    local i
    if Presence.BeginServerTick then
        Presence.BeginServerTick(now)
    end
    Registry.EnsureLoaded()
    if PlayerCharacterLifecycle
        and PlayerCharacterLifecycle.Pump
    then
        PlayerCharacterLifecycle.Pump(now, false)
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.PumpReconciliation
    then
        PNC.FactionBehavior.PumpReconciliation()
    end
    if PNC.FactionIncidentService
        and PNC.FactionIncidentService.PumpRuntime
    then
        PNC.FactionIncidentService.PumpRuntime(
            getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
        )
    end
    if PNC.FactionTolls and PNC.FactionTolls.Pump then
        PNC.FactionTolls.Pump(now)
    end
    if PNC.MobileGroupDirector
        and PNC.MobileGroupDirector.Pump
    then
        PNC.MobileGroupDirector.Pump(now)
    end
    if PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.PumpServerFrame
    then
        PNC.EnginePathPlanner.PumpServerFrame()
    end
    if PNC.Travel and PNC.Travel.Service
        and PNC.Travel.Service.RefreshAbstractPositions
    then
        PNC.Travel.Service.RefreshAbstractPositions(now, false)
    end
    if BodyLifecycle and BodyLifecycle.PumpStartupBodyCleanup then
        BodyLifecycle.PumpStartupBodyCleanup(now, false)
    end
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(now, false)
    end
    if PNC.CompanionVehicle and PNC.CompanionVehicle.AuditLoadedReservations then
        PNC.CompanionVehicle.AuditLoadedReservations(now, false)
    end
    if now - lastLivePositionSafetyRefreshAt
        >= (tonumber(Const.LIVE_POSITION_SAFETY_REFRESH_MS) or 1000)
    then
        Registry.RefreshLivePositions(false)
        lastLivePositionSafetyRefreshAt = now
    end
    Spatial.Rebuild(now, false)
    if Presence.RefreshMaterializationCandidates then
        Presence.RefreshMaterializationCandidates(now, false)
    end
    if Network.RefreshInterestSets then
        Network.RefreshInterestSets(now)
    end
    due = Scheduler.PopDue(Registry.Data, now)
    for i = 1, #due do
        processRecord(due[i], now)
    end
    if Network.FlushRosterDeltas then
        Network.FlushRosterDeltas(now, false)
    end
    if ZombieAggro and ZombieAggro.Pump then
        ZombieAggro.Pump(now)
    end
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.Pump
        and PNC.SocialEventHooks
    then
        if PNC.SocialEventHooks.PruneThreatAttributions then
            PNC.SocialEventHooks.PruneThreatAttributions(
                PNC.SocialEventHooks.WorldAgeHours()
            )
        end
        PNC.SocialEncounterTracker.Pump(
            PNC.SocialEventHooks.WorldAgeHours()
        )
    end
    if Performance then
        Performance.Finish("server.tick", startedAt)
    end
end

local function handleDebugSpawn(player, args)
    local x = tonumber(args and args.x) or (player and player:getX()) or 0
    local y = tonumber(args and args.y) or (player and player:getY()) or 0
    local z = tonumber(args and args.z) or (player and player:getZ()) or 0
    local variant = tostring(args and args.variant or "colonist")
    local legacyFaction = (variant == "hostile_melee" or variant == "hostile_ranged")
        and "hostile" or variant
    local faction = Types.NormalizeFaction(args and args.faction or legacyFaction)
    local equipmentSpawnMode = PNC.Inventory.GetDebugEquipmentSpawnMode(
        variant,
        args and args.equipmentSpawnMode
    )
    local colonist = faction == "colonist"
    local hostile = faction == "hostile"
    if faction ~= "colonist" and faction ~= "neutral" and faction ~= "hostile" then
        faction = "colonist"
        colonist = true
        hostile = false
    end
    local ownerUsername = colonist and player and player:getUsername() or nil
    local ownerOnlineID = colonist and player and player:getOnlineID() or nil
    local orderSpec = hostile
        and { kind = Const.ORDER_HOSTILE_HUNT, x = x, y = y, z = z }
        or colonist and { kind = Const.ORDER_FOLLOW, ownerUsername = ownerUsername, ownerOnlineID = ownerOnlineID }
        or {
            kind = Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_AREA,
            x = x,
            y = y,
            z = z,
            radius = Const.ROAM_DEFAULT_RADIUS,
        }
    local record = API.Spawn({
        faction = faction,
        archetypeID = resolveDebugArchetype(args, faction, hostile and "Scavenger" or "General"),
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
    Core.LogInfo("PNC debug spawn variant=" .. variant .. " faction=" .. faction
        .. " equipment=" .. tostring(equipmentSpawnMode or "sandbox_chances")
        .. " id=" .. tostring(record and record.id or "failed"))
    return record
end

local function findTeleportPosition(record)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    local x = body and body:getX() or tonumber(record and record.x) or 0
    local y = body and body:getY() or tonumber(record and record.y) or 0
    local z = body and body:getZ() or tonumber(record and record.z) or 0
    local cell = getCell and getCell() or nil
    local offsets = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
    local i
    if cell then
        for i = 1, #offsets do
            local square = cell:getGridSquare(math.floor(x) + offsets[i][1], math.floor(y) + offsets[i][2], math.floor(z))
            if square and (not square.isFree or square:isFree(false)) then
                return square:getX() + 0.5, square:getY() + 0.5, square:getZ()
            end
        end
    end
    return x + 1.5, y + 1.5, z
end

local function teleportPlayerToRecord(player, npcId)
    local record = npcId and Registry.Get(npcId) or nil
    local x
    local y
    local z
    if not player or not record then
        return false
    end
    x, y, z = findTeleportPosition(record)
    if Teleport.ToCoordinates(player, x, y, z) then
        Core.LogInfo("PNC debug queued teleport for " .. tostring(player:getUsername())
            .. " near NPC " .. tostring(record.id))
        return true
    end
    Core.LogWarn("PNC debug teleport unavailable for NPC " .. tostring(record.id))
    return false
end

local function onClientCommand(module, command, player, args)
    local snapshots
    if module ~= Const.MODULE then
        return
    end

    if command == Const.CMD_FULL_SYNC_REQUEST then
        snapshots = buildSnapshotList()
        Network.BroadcastFullSync(player, snapshots)
        return
    end

    if ConversationScene
        and (
            command == ConversationScene.CMD_BEGIN
            or command == ConversationScene.CMD_END
            or command == ConversationScene.CMD_CEASEFIRE
        )
    then
        ConversationScene.HandleClientCommand(
            player,
            command,
            args or {}
        )
        return
    end

    if command == Const.CMD_REQUEST_CHARACTER and args and args.id then
        local record = Registry.Get(args.id)
        if record and Network.CanViewCharacter(player, record) then
            if tonumber(args.inventoryRevision) and tonumber(args.inventoryRevision) > 0 then
                Network.SendInventoryDelta(player, record, args.inventoryRevision)
            else
                Network.SendCharacterPayload(player, record)
            end
        else
            Core.LogWarn("Rejected unauthorized NPC character request player="
                .. tostring(player and player.getUsername and player:getUsername() or "unknown")
                .. " npc=" .. tostring(args.id))
        end
        return
    end

    if command == Const.CMD_REVIVE and args and args.id then
        if PNC.Revive and PNC.Revive.Try then
            PNC.Revive.Try(player, args.id)
        end
        return
    end

    if command == Const.CMD_BANDAGE and args and args.id and args.partId then
        if Treatment and Treatment.TryBandage then
            local debugFree = args.debugFree == true and canUseDebug(player)
            Treatment.TryBandage(player, args.id, args.partId, {
                consumeItem = not debugFree,
                bandageType = args.bandageType,
            })
        end
        return
    end

    if command == Const.CMD_COMPANION_COMMAND and args and args.commandID then
        if CompanionCommands and CompanionCommands.Execute then
            CompanionCommands.Execute(player, args)
        end
        return
    end

    if command == Const.CMD_MAP_COMMAND then
        local result = MapCommandService and MapCommandService.Execute
            and MapCommandService.Execute(player, args or {}, {
                debugAuthorized = canUseDebug(player),
                source = "network",
            }) or {
                ok = false,
                reason = "map_commands_unavailable",
            }
        if sendServerCommand then
            sendServerCommand(
                player,
                Const.MODULE,
                Const.CMD_MAP_COMMAND_RESULT,
                result
            )
        end
        return
    end

    if command == Const.CMD_FACTION_TOLL_RESPONSE then
        if PNC.FactionTolls
            and PNC.FactionTolls.HandleResponse
        then
            PNC.FactionTolls.HandleResponse(
                player,
                args or {}
            )
        end
        return
    end

    if command == Const.CMD_INVENTORY_TRANSFER then
        if PNC.ServerInventory and PNC.ServerInventory.Transfer then
            PNC.ServerInventory.Transfer(player, args or {})
        end
        return
    end

    if command == Const.CMD_INVENTORY_ACTION then
        if PNC.ServerInventory and PNC.ServerInventory.Action then
            PNC.ServerInventory.Action(player, args or {})
        end
        return
    end

    if command == Const.CMD_PLAYER_WEAPON_HIT then
        if PlayerDamage and PlayerDamage.HandleClientReport then
            PlayerDamage.HandleClientReport(player, args or {})
        end
        return
    end

    if command == Const.CMD_DEBUG_ROSTER_REQUEST then
        if not canUseDebug(player) then
            Network.SendDebugRoster(player, {}, false, BodyLifecycle and BodyLifecycle.LastAudit or {})
            return
        end
        if args and args.audit == true and BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
            BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
        end
        if args and args.performance == true
            and Performance
            and Performance.Enable
        then
            Performance.Enable(60000)
        end
        Network.SendDebugRoster(
            player,
            BodyLifecycle and BodyLifecycle.BuildDebugRoster
                and BodyLifecycle.BuildDebugRoster() or {},
            true,
            BodyLifecycle and BodyLifecycle.LastAudit or {}
        )
        return
    end

    if command == Const.CMD_RELATIONSHIP_DEBUG_REQUEST then
        local snapshot
        local reason
        if not canUseDebug(player) then
            Network.SendRelationshipDebug(
                player,
                nil,
                false,
                "not_authorized"
            )
            return
        end
        snapshot, reason =
            PNC.RelationshipDebug.BuildSnapshotForRequest(
                player,
                args or {}
            )
        Network.SendRelationshipDebug(
            player,
            snapshot,
            true,
            reason
        )
        return
    end

    if command == Const.CMD_CONVERSATION_RELATIONSHIP_REQUEST then
        local summary
        local reason
        local presentation = PNC.RelationshipPresentation
        if presentation and presentation.BuildForConversation then
            summary, reason = presentation.BuildForConversation(
                player,
                args and args.npcID
            )
        else
            reason = "presentation_unavailable"
        end
        Network.SendConversationRelationship(player, summary, reason)
        return
    end

    if command == Const.CMD_NPC_KNOWLEDGE_REQUEST then
        local snapshot
        local reason
        if PNC.NPCKnowledge and PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer then
            snapshot, reason = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(
                player, args and args.npcID
            )
        else
            reason = "knowledge_service_unavailable"
        end
        Network.SendNPCKnowledge(player, snapshot, reason)
        return
    end

    if command == Const.CMD_KNOWLEDGE_DEBUG_REQUEST then
        if not canUseDebug(player) then
            Network.SendKnowledgeDebug(player, nil, false, "not_authorized")
            return
        end
        local snapshot
        local reason
        if PNC.NPCKnowledge and PNC.NPCKnowledge.BuildDebugSnapshotForPlayer then
            snapshot, reason = PNC.NPCKnowledge.BuildDebugSnapshotForPlayer(
                player, args and args.npcID, args and args.showTruth ~= false,
                args and args.descriptorID
            )
        else
            reason = "knowledge_service_unavailable"
        end
        Network.SendKnowledgeDebug(player, snapshot, true, reason)
        return
    end

    if command == Const.CMD_FACTION_DEBUG_REQUEST then
        if not canUseDebug(player) then
            Network.SendFactionDebug(
                player,
                nil,
                false,
                "not_authorized"
            )
            return
        end
        Network.SendFactionDebug(
            player,
            PNC.FactionDebug.BuildSnapshot(
                args and args.factionID,
                args and args.npcID,
                nil,
                player,
                args and args.targetFactionID
            ),
            true,
            nil
        )
        return
    end

    if command == Const.CMD_FACTION_MEMBERS_REQUEST then
        local snapshot
        local reason
        snapshot, reason =
            PNC.FactionMembership.BuildSnapshot(player)
        Network.SendFactionMembers(
            player,
            snapshot,
            reason
        )
        return
    end

    if command == Const.CMD_FACTION_MEMBER_ACTION then
        local snapshot
        local reason
        snapshot, reason =
            PNC.FactionMembership.PerformAction(
                player,
                args or {}
            )
        Network.SendFactionMembers(
            player,
            snapshot,
            reason
        )
        return
    end

    if command == Const.CMD_COMMUNITY_DEBUG_REQUEST then
        if not canUseDebug(player) then
            Network.SendCommunityDebug(
                player,
                nil,
                false,
                "not_authorized"
            )
            return
        end
        Network.SendCommunityDebug(
            player,
            PNC.CommunityDebug.BuildSnapshot(
                args and args.communityID,
                args and args.factionID,
                args and args.npcID,
                nil,
                player
            ),
            true,
            nil
        )
        return
    end

    if command ~= Const.CMD_DEBUG then
        return
    end

    if not canUseDebug(player) then
        Core.LogWarn("Rejected unauthorized PNC debug command action=" .. tostring(args and args.action or "unknown"))
        return
    end

    if args and args.action == "spawn" then
        handleDebugSpawn(player, args)
        return
    end

    if args and args.action == "teleport_to_npc" then
        teleportPlayerToRecord(player, args.id)
        return
    end

    if args and args.action == "social_trigger_event" then
        local snapshot
        local reason
        snapshot, reason =
            PNC.RelationshipDebug.TriggerSocialEvent(
                player,
                args
            )
        Network.SendRelationshipDebug(
            player,
            snapshot,
            true,
            reason
        )
        return
    end

    if args and args.action == "conversation_relationship_standing" then
        local summary
        local reason
        summary, reason = PNC.RelationshipDebug.SetConversationStanding(
            player,
            args
        )
        Network.SendConversationRelationship(player, summary, reason)
        return
    end

    if args and args.action == "relationship_debug_baseline" then
        local snapshot
        local reason
        snapshot, reason = PNC.RelationshipDebug.ApplyDebugBaseline(
            player,
            args
        )
        Network.SendRelationshipDebug(player, snapshot, true, reason)
        return
    end

    if args and args.action == "knowledge_debug_action" then
        if not canUseDebug(player) then
            Network.SendKnowledgeDebug(player, nil, false, "not_authorized")
            return
        end
        local snapshot
        local reason
        if PNC.NPCKnowledge and PNC.NPCKnowledge.ExecuteDebugForPlayer then
            snapshot, reason = PNC.NPCKnowledge.ExecuteDebugForPlayer(player, args)
        else
            reason = "knowledge_service_unavailable"
        end
        Network.SendKnowledgeDebug(player, snapshot, true, reason)
        return
    end

    if args and args.action == "relationship_pacification" then
        local snapshot
        local reason
        snapshot, reason =
            PNC.RelationshipDebug.SetPlayerPacification(
                player,
                args
            )
        Network.SendRelationshipDebug(
            player,
            snapshot,
            true,
            reason
        )
        return
    end

    if args and args.action == "faction_debug_action" then
        Network.SendFactionDebug(
            player,
            PNC.FactionDebug.PerformAction(player, args),
            true,
            nil
        )
        return
    end

    if args and args.action == "community_debug_action" then
        Network.SendCommunityDebug(
            player,
            PNC.CommunityDebug.PerformAction(player, args),
            true,
            nil
        )
        return
    end

    if args and args.action == "force_live" then
        API.DebugCommand(args.id, "force_live", args)
        return
    end

    if args and args.action == "force_abstract" then
        API.DebugCommand(args.id, "force_abstract", args)
        return
    end

    if args and args.action == "heal" then
        API.DebugCommand(args.id, "heal", args)
        return
    end

    if args and args.action == "revive" then
        API.DebugCommand(args.id, "revive", args)
        return
    end

    if args and args.action == "damage" then
        API.DebugCommand(args.id, "damage", args)
        return
    end

    if args and args.action == "damage_part" then
        API.DebugCommand(args.id, "damage_part", args)
        return
    end

    if args and args.action == "infection" then
        API.DebugCommand(args.id, "infection", args)
        return
    end

    if args and args.action == "clear_infection" then
        API.DebugCommand(args.id, "clear_infection", args)
        return
    end

    if args and args.action == "bandage_almost_dirty" then
        API.DebugCommand(args.id, "bandage_almost_dirty", args)
        return
    end

    if args and (
        args.action == "animation_scene_play"
        or args.action == "animation_scene_pool_step"
        or args.action == "animation_scene_pool_start"
        or args.action == "animation_scene_stop"
    ) then
        API.DebugCommand(args.id, args.action, args)
        return
    end

    if args and args.action == "set_map_presentation" then
        API.DebugCommand(args.id, "set_map_presentation", args)
        return
    end

    if args and args.action == "set_map_known" then
        args.playerKey = player and player.getUsername
            and player:getUsername() or nil
        API.DebugCommand(args.id, "set_map_known", args)
        return
    end

    if args and args.action == "set_weapon_mode" then
        API.DebugCommand(args.id, "set_weapon_mode", args)
        return
    end

    if args and args.action == "copy_held_weapon" then
        if player and player.getPrimaryHandItem then
            local primary = player:getPrimaryHandItem()
            if primary and primary.getFullType then
                args.weaponFullType = primary:getFullType()
            end
        end
        args.sourcePlayer = player
        API.DebugCommand(args.id, "copy_held_weapon", args)
        return
    end

    if args and args.action == "copy_player_loadout" then
        args.sourcePlayer = player
        API.DebugCommand(args.id, "copy_player_loadout", args)
        return
    end

    if args and args.action == "set_equipment_slot" then
        API.DebugCommand(args.id, "set_equipment_slot", args)
        return
    end

    if args and args.action == "clear_equipment" then
        API.DebugCommand(args.id, "clear_equipment", args)
        return
    end

    if args and args.action == "toggle_debug" then
        API.DebugCommand(args.id, "toggle_debug", args)
        return
    end

    if args and args.action == "set_order" then
        API.SetOrder(args.id, args.orderSpec)
        return
    end

    if args and args.action == "set_hostility" then
        API.SetHostility(args.id, args.modeSpec)
        return
    end

    if args and args.action == "audit_bodies" then
        if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
            BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
        end
        Network.SendDebugRoster(
            player,
            BodyLifecycle and BodyLifecycle.BuildDebugRoster
                and BodyLifecycle.BuildDebugRoster() or {},
            true,
            BodyLifecycle and BodyLifecycle.LastAudit or {}
        )
        return
    end
end

local function onServerStarted()
    Registry.Load()
    if PNC.NPCKnowledge and PNC.NPCKnowledge.Load then
        PNC.NPCKnowledge.Load()
    end
    if PNC.Factions and PNC.Factions.Load then
        PNC.Factions.Load()
    end
    if PNC.Communities and PNC.Communities.Load then
        PNC.Communities.Load()
    end
    if PNC.Factions
        and PNC.Factions
            .ReconcileTerritorialLooterFactions
    then
        PNC.Factions.ReconcileTerritorialLooterFactions()
    end
    if PlayerCharacterLifecycle
        and PlayerCharacterLifecycle.OnServerStarted
    then
        PlayerCharacterLifecycle.OnServerStarted(Core.Now())
    end
    if BodyLifecycle and BodyLifecycle.RunStartupBodyCleanupNow then
        BodyLifecycle.RunStartupBodyCleanupNow(
            Core.Now(),
            "server_started",
            true
        )
    end
    if PNC.CompanionVehicle and PNC.CompanionVehicle.AuditLoadedReservations then
        PNC.CompanionVehicle.AuditLoadedReservations(Core.Now(), true)
    end
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
    end
    Core.LogInfo("PNC server started.")
end

Events.OnTick.Add(Server.OnTick)
Events.OnClientCommand.Add(onClientCommand)
Events.OnServerStarted.Add(onServerStarted)

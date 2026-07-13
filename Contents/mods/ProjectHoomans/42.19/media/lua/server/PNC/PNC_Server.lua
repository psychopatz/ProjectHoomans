--[[
    PNC Server Authority
    Owns server-side NPC ticking, presence reconciliation, sync dispatch, and
    debug command routing. Clients never create authoritative NPC records here.
]]

if isClient() and not isServer() then
    return
end

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
local Network = PNC.Network
local API = PNC.API
local ZombieAggro = PNC.ZombieAggro
local Stamina = PNC.Stamina
local Archetypes = PNC.Archetypes
local Animation = PNC.Animation
local BodyLifecycle = PNC.BodyLifecycle
local buildDebugRoster

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
            or Archetypes.GetCompanionDefaults and Archetypes.GetCompanionDefaults()
        if type(defaults) == "table" and defaults[1] then
            return tostring(defaults[1])
        end
    end
    return fallbackID
end

local function buildSnapshotList()
    local list = {}
    Registry.ForEach(function(record)
        list[#list + 1] = Network.BuildSnapshot(record)
    end)
    return list
end

local function processRecord(record, now)
    local zombie = Registry.GetLiveZombie(record.id)
    local forceSyncEvent

    Presence.Reconcile(record)
    zombie = Registry.GetLiveZombie(record.id)
    Health.Update(record, zombie, now)
    if Stamina and Stamina.Update then
        Stamina.Update(record, zombie, now)
    end

    if record.alive == false then
        if record.lastSyncAt ~= record.presenceRevision then
            Network.BroadcastRemoval(record.id, "death")
            record.lastSyncAt = record.presenceRevision
        end
        return
    end

    if now >= (tonumber(record.nextThinkAt) or 0) then
        Behavior.Tick(record, zombie, now)
        record.lastThinkAt = now
        record.nextThinkAt = now + Scheduler.GetCadence(record)
    end

    if zombie and record.alive ~= false then
        PathService.Pump(record, zombie)
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

    if zombie and Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie, record)
    end
end

function Server.OnTick()
    local now = Core.Now()
    Registry.EnsureLoaded()
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(now, false)
    end
    Registry.RefreshLivePositions()
    Spatial.Rebuild()
    Registry.ForEach(function(record)
        processRecord(record, now)
    end)
    if ZombieAggro and ZombieAggro.Pump then
        ZombieAggro.Pump(now)
    end
end

local function handleDebugSpawn(player, args)
    local x = tonumber(args and args.x) or (player and player:getX()) or 0
    local y = tonumber(args and args.y) or (player and player:getY()) or 0
    local z = tonumber(args and args.z) or (player and player:getZ()) or 0
    local variant = tostring(args and args.variant or "companion")
    local faction = (variant == "hostile_melee" or variant == "hostile_ranged") and "hostile" or variant
    local companion = faction == "companion"
    local hostile = faction == "hostile"
    if faction ~= "companion" and faction ~= "friendly" and faction ~= "neutral" and faction ~= "hostile" then
        faction = "companion"
        companion = true
        hostile = false
    end
    local ownerUsername = companion and player and player:getUsername() or nil
    local ownerOnlineID = companion and player and player:getOnlineID() or nil
    local orderSpec = hostile
        and { kind = Const.ORDER_HOSTILE_HUNT, x = x, y = y, z = z }
        or companion and { kind = Const.ORDER_FOLLOW, ownerUsername = ownerUsername, ownerOnlineID = ownerOnlineID }
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
        weaponMode = variant == "hostile_ranged" and "ranged" or "melee",
        debug = true,
    })
    Core.LogInfo("PNC debug spawn variant=" .. variant .. " faction=" .. faction
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
    if player.setX then player:setX(x) end
    if player.setY then player:setY(y) end
    if player.setZ then player:setZ(z) end
    if player.setLx then player:setLx(x) end
    if player.setLy then player:setLy(y) end
    if player.setLz then player:setLz(z) end
    Core.LogInfo("PNC debug teleported " .. tostring(player:getUsername()) .. " near NPC " .. tostring(record.id))
    return true
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

    if command == Const.CMD_REQUEST_CHARACTER and args and args.id then
        Network.SendCharacterPayload(player, Registry.Get(args.id))
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
        Network.SendDebugRoster(player, buildDebugRoster(), true, BodyLifecycle and BodyLifecycle.LastAudit or {})
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
        Network.SendDebugRoster(player, buildDebugRoster(), true, BodyLifecycle and BodyLifecycle.LastAudit or {})
        return
    end
end

local function onServerStarted()
    Registry.Load()
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
    end
    Core.LogInfo("PNC server started.")
end

function buildDebugRoster()
    local list = {}
    if not BodyLifecycle or not BodyLifecycle.BuildDiagnostics then
        return list
    end
    Registry.ForEach(function(record)
        list[#list + 1] = BodyLifecycle.BuildDiagnostics(record)
    end)
    table.sort(list, function(a, b)
        return tostring(a and a.name or a and a.id or "") < tostring(b and b.name or b and b.id or "")
    end)
    return list
end

Events.OnTick.Add(Server.OnTick)
Events.OnClientCommand.Add(onClientCommand)
Events.OnServerStarted.Add(onServerStarted)

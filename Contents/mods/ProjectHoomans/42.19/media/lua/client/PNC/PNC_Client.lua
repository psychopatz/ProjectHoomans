--[[
    PNC Client Command Surface
    Owns client-side command requests, server snapshot intake, and the top-level
    world context hook. Focused live-body snapshot application stays in the
    dedicated client presence sync module.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local ClientState = PNC.Network.ClientState
local Interpolation = PNC.ClientInterpolation

Client.BiteReplicas = Client.BiteReplicas or {}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

local function teleportLocalPlayerNear(record, player)
    if not record or not player then
        return false
    end
    local body = Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    local x = body and body:getX() or tonumber(record.x) or 0
    local y = body and body:getY() or tonumber(record.y) or 0
    local z = body and body:getZ() or tonumber(record.z) or 0
    return Teleport.ToCoordinates(player, x + 1.5, y + 1.5, z)
end

local function isWorldReady()
    return (not isIngameState) or isIngameState()
end

local function applyZombieReaction(args)
    local targetZombie
    local attackerZombie
    local reaction
    if not args then
        return false
    end
    targetZombie = PNC.Network and PNC.Network.FindZombieByOnlineID
        and PNC.Network.FindZombieByOnlineID(args.targetOnlineID) or nil
    if not targetZombie then
        return false
    end
    attackerZombie = PNC.Network and PNC.Network.FindZombieByOnlineID
        and PNC.Network.FindZombieByOnlineID(args.attackerOnlineID) or nil
    reaction = PNC.CombatZombieReaction
    if not reaction or not reaction.ApplyReplicatedHit then
        return false
    end
    return reaction.ApplyReplicatedHit(attackerZombie, targetZombie, args)
end

local function signalBiteRelease(attackerZombie)
    if not attackerZombie then
        return
    end
    if attackerZombie.setBumpDone then
        attackerZombie:setBumpDone(true)
    end
    if attackerZombie.setVariable then
        attackerZombie:setVariable("BumpDone", true)
        attackerZombie:setVariable("BumpAnimFinished", true)
    end
end

local function finishBiteReplica(attackerZombie)
    signalBiteRelease(attackerZombie)
    if attackerZombie and attackerZombie.setBumpType then
        attackerZombie:setBumpType("")
    end
    if attackerZombie and attackerZombie.setBumpedChr then
        pcall(attackerZombie.setBumpedChr, attackerZombie, nil)
    end
    if attackerZombie and attackerZombie.setVariable then
        attackerZombie:setVariable("PNCZombieBitingNPC", false)
    end
end

local function applyZombieBite(args)
    local attackerZombie
    local targetNPCBody
    local key
    local state
    local now
    if not args or not PNC.Network or not PNC.Network.FindZombieByOnlineID then
        return false
    end
    key = tostring(args.attackerOnlineID or "")
    if key == "" then
        return false
    end
    now = Core.Now()
    attackerZombie = PNC.Network.FindZombieByOnlineID(args.attackerOnlineID)
    state = Client.BiteReplicas[key] or {
        attackerOnlineID = args.attackerOnlineID,
        startedAt = now,
    }
    Client.BiteReplicas[key] = state
    if args.phase == "clear" then
        state.phase = "release"
        state.releaseAt = now
        state.releaseDeadline = now + (tonumber(Const.BITE_RELEASE_TIMEOUT_MS) or 650)
        signalBiteRelease(attackerZombie)
        return true
    end
    state.phase = "windup"
    state.targetOnlineID = args.targetOnlineID
    state.npcId = args.npcId
    state.bumpType = tostring(args.bumpType or "Bite")
    state.startedAt = now
    state.localReleaseAt = now + (tonumber(Const.ZOMBIE_BITE_CLEAR_DELAY_MS) or 700) + 350
    if not attackerZombie then
        return true
    end
    targetNPCBody = PNC.Network.FindZombieByOnlineID(args.targetOnlineID)
    if not targetNPCBody and PNC.ClientPresenceSync then
        local npcKey = tostring(args.npcId or "")
        local snapshot = ClientState.snapshots and ClientState.snapshots[npcKey] or nil
        if snapshot and snapshot.liveBodyLease and PNC.ClientPresenceSync.BodyByLease then
            targetNPCBody = PNC.ClientPresenceSync.BodyByLease[
                npcKey .. ":" .. tostring(snapshot.liveBodyLease)
            ]
        elseif not snapshot or not snapshot.liveBodyLease then
            targetNPCBody = PNC.ClientPresenceSync.BodyByID
                and PNC.ClientPresenceSync.BodyByID[npcKey] or nil
        end
    end
    if targetNPCBody and attackerZombie.faceThisObject then
        attackerZombie:faceThisObject(targetNPCBody)
    end
    if targetNPCBody and attackerZombie.setBumpedChr then
        attackerZombie:setBumpedChr(targetNPCBody)
    end
    if attackerZombie.setBumpDone then
        attackerZombie:setBumpDone(false)
    end
    if attackerZombie.setVariable then
        attackerZombie:setVariable("PNCZombieBitingNPC", true)
        attackerZombie:setVariable("BumpDone", false)
        attackerZombie:setVariable("BumpAnimFinished", false)
    end
    if attackerZombie.setBumpType then
        attackerZombie:setBumpType(state.bumpType)
    end
    state.applied = true
    return true
end

local function pumpBiteReplicas()
    local now = Core.Now()
    local key
    local state
    local zombie
    local asn
    for key, state in pairs(Client.BiteReplicas) do
        zombie = PNC.Network and PNC.Network.FindZombieByOnlineID
            and PNC.Network.FindZombieByOnlineID(state.attackerOnlineID) or nil
        if state.phase ~= "release" and now >= (tonumber(state.localReleaseAt) or math.huge) then
            state.phase = "release"
            state.releaseAt = now
            state.releaseDeadline = now + (tonumber(Const.BITE_RELEASE_TIMEOUT_MS) or 650)
        end
        if state.phase == "release" then
            signalBiteRelease(zombie)
            asn = zombie and zombie.getActionStateName and tostring(zombie:getActionStateName() or "") or ""
            if (zombie and asn ~= "bumped" and (now - (tonumber(state.releaseAt) or now)) >= 35)
                or now >= (tonumber(state.releaseDeadline) or now)
            then
                finishBiteReplica(zombie)
                Client.BiteReplicas[key] = nil
            end
        elseif zombie and state.applied ~= true then
            applyZombieBite({
                attackerOnlineID = state.attackerOnlineID,
                targetOnlineID = state.targetOnlineID,
                npcId = state.npcId,
                bumpType = state.bumpType,
                phase = "start",
            })
        end
    end
end

local function requestFullSync()
    local player = getSpecificPlayer(0)
    if not isWorldReady() then
        return
    end
    ClientState.lastFullSyncRequestAt = Core.Now()
    if player and sendClientCommand then
        sendClientCommand(player, Const.MODULE, Const.CMD_FULL_SYNC_REQUEST, {})
        return
    end
    if PNC.Registry and PNC.Network and PNC.Network.BuildSnapshot then
        ClientState.snapshots = {}
        if Interpolation and Interpolation.ClearAll then
            Interpolation.ClearAll()
        end
        PNC.Registry.ForEach(function(record)
            local snapshot = PNC.Network.BuildSnapshot(record)
            ClientState.snapshots[snapshot.id] = snapshot
        end)
        ClientState.lastSyncReceiveAt = Core.Now()
    end
end

Client.RequestFullSync = requestFullSync

function Client.CanUseDebug()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local access
    access = player and player.getAccessLevel and tostring(player:getAccessLevel() or "") or ""
    if string.lower(access) == "admin" then
        return true
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        return false
    end
    if isDebugEnabled then
        return isDebugEnabled() == true
    end
    return getCore and getCore() and getCore():getDebug() == true or false
end

function Client.RequestDebugRoster(forceAudit)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local diagnostics = {}
    if not Client.CanUseDebug() then
        ClientState.debugAuthorized = false
        ClientState.debugRoster = {}
        return false
    end
    ClientState.lastDebugRosterRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG_ROSTER_REQUEST, { audit = forceAudit == true })
            return true
        end
        return false
    end
    if forceAudit and PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
        PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
    end
    if PNC.Registry and PNC.BodyLifecycle and PNC.BodyLifecycle.BuildDiagnostics then
        PNC.Registry.ForEach(function(record)
            diagnostics[#diagnostics + 1] = PNC.BodyLifecycle.BuildDiagnostics(record)
        end)
    end
    ClientState.debugRoster = diagnostics
    ClientState.debugAuthorized = true
    ClientState.debugAudit = PNC.BodyLifecycle and PNC.BodyLifecycle.LastAudit or {}
    return true
end

function Client.RequestCharacterPayload(npcId)
    local player = getSpecificPlayer(0)
    local payload
    local cached
    local inventoryRevision
    if not npcId then
        return false
    end
    if not sendClientCommand and PNC.API and PNC.API.GetCharacterPayload then
        payload = PNC.API.GetCharacterPayload(npcId)
        if payload then
            ClientState.characterPayloads = ClientState.characterPayloads or {}
            ClientState.characterPayloads[npcId] = payload
            if payload.snapshot and payload.snapshot.id then
                ClientState.snapshots[payload.snapshot.id] = payload.snapshot
            end
            return true
        end
        return false
    end
    if not player or not sendClientCommand then
        return false
    end
    cached = ClientState.characterPayloads and ClientState.characterPayloads[npcId] or nil
    inventoryRevision = cached and cached.inventory and cached.inventory.summary
        and tonumber(cached.inventory.summary.revision) or nil
    sendClientCommand(player, Const.MODULE, Const.CMD_REQUEST_CHARACTER, {
        id = npcId,
        inventoryRevision = inventoryRevision,
    })
    return true
end

local function removeFromContainer(inventory, itemID)
    local container
    local i
    for _, container in pairs(inventory and inventory.containers or {}) do
        for i = #(container.items or {}), 1, -1 do
            if container.items[i] == itemID then
                table.remove(container.items, i)
            end
        end
    end
end

local function applyInventoryDelta(args)
    local cached = args and ClientState.characterPayloads and ClientState.characterPayloads[args.npcId] or nil
    local inventory = cached and cached.inventory or nil
    local i
    local op
    local item
    local container
    if not inventory or type(inventory.items) ~= "table" or type(args.ops) ~= "table" then
        Client.RequestCharacterPayload(args and args.npcId)
        return false
    end
    for i = 1, #args.ops do
        op = args.ops[i]
        if op.op == "add" and type(op.item) == "table" and op.item.id then
            item = Core.DeepCopy(op.item)
            inventory.items[item.id] = item
            container = inventory.containers[item.container or op.container or "root"]
            if container then
                container.items[#container.items + 1] = item.id
            end
        elseif op.op == "remove" and op.itemID then
            removeFromContainer(inventory, op.itemID)
            inventory.items[op.itemID] = nil
        elseif op.op == "move" and op.itemID and inventory.items[op.itemID] then
            removeFromContainer(inventory, op.itemID)
            inventory.items[op.itemID].container = op.to
            container = inventory.containers[op.to]
            if container then
                container.items[#container.items + 1] = op.itemID
            end
        elseif op.op == "update" and op.itemID and inventory.items[op.itemID] then
            item = inventory.items[op.itemID]
            if op.stack ~= nil then item.stack = op.stack end
            if op.uses ~= nil then item.uses = op.uses end
            if op.cond ~= nil then item.cond = op.cond end
        end
    end
    inventory.summary = Core.DeepCopy(args.summary or inventory.summary or {})
    inventory.summary.revision = tonumber(args.inventoryRevision) or inventory.summary.revision
    inventory.revision = inventory.summary.revision
    return true
end

local function mergeSnapshot(current, incoming)
    local key
    if type(current) ~= "table" then
        return incoming
    end
    for key, _ in pairs(incoming or {}) do
        current[key] = incoming[key]
    end
    return current
end

function Client.HandleServerCommand(command, args)
    local snapshot
    local i
    ClientState.lastSyncReceiveAt = Core.Now()
    if command == Const.CMD_ZOMBIE_REACTION then
        applyZombieReaction(args)
        return
    end
    if command == Const.CMD_ZOMBIE_BITE then
        applyZombieBite(args)
        return
    end
    if command == Const.CMD_DEBUG_ROSTER then
        ClientState.debugAuthorized = args and args.authorized == true or false
        ClientState.debugRoster = args and args.diagnostics or {}
        ClientState.debugAudit = args and args.audit or {}
        ClientState.lastDebugRosterReceiveAt = Core.Now()
        return
    end
    if command == Const.CMD_FULL_SYNC then
        ClientState.snapshots = {}
        ClientState.characterPayloads = {}
        if Interpolation and Interpolation.ClearAll then
            Interpolation.ClearAll()
        end
        if args and args.snapshots then
            for i = 1, #args.snapshots do
                snapshot = args.snapshots[i]
                ClientState.snapshots[snapshot.id] = snapshot
            end
        end
        return
    end

    if command == Const.CMD_ROSTER_SYNC_BEGIN then
        ClientState.pendingRoster = {}
        ClientState.pendingRosterRevision = args and args.directoryRevision or 0
        ClientState.pendingRosterExpectedChunks = args and args.chunkCount or 0
        ClientState.pendingRosterChunks = {}
        return
    end

    if command == Const.CMD_ROSTER_SYNC_CHUNK then
        ClientState.pendingRoster = ClientState.pendingRoster or {}
        for i = 1, #(args and args.snapshots or {}) do
            snapshot = args.snapshots[i]
            if snapshot and snapshot.id then
                ClientState.pendingRoster[snapshot.id] = snapshot
            end
        end
        if args and args.chunkIndex then
            ClientState.pendingRosterChunks[args.chunkIndex] = true
        end
        return
    end

    if command == Const.CMD_ROSTER_SYNC_END then
        local receivedChunks = 0
        for _, _ in pairs(ClientState.pendingRosterChunks or {}) do
            receivedChunks = receivedChunks + 1
        end
        if receivedChunks < (tonumber(ClientState.pendingRosterExpectedChunks) or 0) then
            ClientState.pendingRoster = nil
            ClientState.pendingRosterChunks = nil
            Client.RequestFullSync()
            return
        end
        ClientState.snapshots = ClientState.pendingRoster or {}
        ClientState.characterPayloads = {}
        ClientState.rosterRevision = args and args.directoryRevision or ClientState.pendingRosterRevision or 0
        ClientState.pendingRoster = nil
        ClientState.pendingRosterChunks = nil
        if Interpolation and Interpolation.ClearAll then
            Interpolation.ClearAll()
        end
        return
    end

    if command == Const.CMD_ROSTER_DELTA then
        for i = 1, #(args and args.entries or {}) do
            local entry = args.entries[i]
            if entry.removed == true then
                ClientState.snapshots[entry.id] = nil
                if ClientState.characterPayloads then
                    ClientState.characterPayloads[entry.id] = nil
                end
            elseif entry.snapshot and entry.snapshot.id then
                local current = ClientState.snapshots[entry.snapshot.id]
                if not current or not current.visualState then
                    ClientState.snapshots[entry.snapshot.id] = entry.snapshot
                else
                    current.displayName = entry.snapshot.displayName
                    current.name = entry.snapshot.name
                    current.faction = entry.snapshot.faction
                    current.recruited = entry.snapshot.recruited
                end
            end
        end
        ClientState.rosterRevision = args and args.directoryRevision or ClientState.rosterRevision
        return
    end

    if command == Const.CMD_SYNC_RECORD then
        snapshot = args and args.snapshot or nil
        if snapshot and snapshot.id then
            if args.event == "interest_exit" or args.event == "interest_enter" then
                ClientState.snapshots[snapshot.id] = snapshot
            else
                ClientState.snapshots[snapshot.id] = mergeSnapshot(ClientState.snapshots[snapshot.id], snapshot)
            end
            if ClientState.characterPayloads and ClientState.characterPayloads[snapshot.id] then
                ClientState.characterPayloads[snapshot.id].snapshot = ClientState.snapshots[snapshot.id]
            end
        end
        return
    end

    if command == Const.CMD_CHARACTER_PAYLOAD and args and args.npcId then
        ClientState.characterPayloads = ClientState.characterPayloads or {}
        ClientState.characterPayloads[args.npcId] = args
        if args.snapshot and args.snapshot.id then
            ClientState.snapshots[args.snapshot.id] = args.snapshot
        end
        return
    end

    if command == Const.CMD_INVENTORY_DELTA and args and args.npcId then
        applyInventoryDelta(args)
        return
    end

    if command == Const.CMD_REMOVE_RECORD and args and args.id then
        ClientState.snapshots[args.id] = nil
        if ClientState.characterPayloads then
            ClientState.characterPayloads[args.id] = nil
        end
        if Interpolation and Interpolation.ClearNPC then
            Interpolation.ClearNPC(args.id)
        end
    end
end

function Client.SendDebug(action, payload)
    local player = getSpecificPlayer(0)
    local args = payload or {}
    args.action = action
    if not Client.CanUseDebug() then
        return false
    end
    if Core.IsClientOnly and Core.IsClientOnly() and player then
        sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
        return true
    end
    if action == "audit_bodies" and PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
        PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
        Client.RequestDebugRoster(false)
        return true
    end
    if action == "teleport_to_npc" and args.id then
        return teleportLocalPlayerNear(Registry.Get(args.id), player)
    end
    if action == "spawn" and PNC.API and PNC.API.Spawn then
        local variant = tostring(args.variant or "colonist")
        local faction = (variant == "hostile_melee" or variant == "hostile_ranged") and "hostile" or PNC.Types.NormalizeFaction(variant)
        if faction ~= "colonist" and faction ~= "neutral" and faction ~= "hostile" then
            faction = "colonist"
        end
        local colonist = faction == "colonist"
        local hostile = faction == "hostile"
        local ownerUsername = colonist and player and player.getUsername and player:getUsername() or nil
        local ownerOnlineID = colonist and player and player.getOnlineID and player:getOnlineID() or nil
        local x = tonumber(args.x) or (player and player:getX()) or 0
        local y = tonumber(args.y) or (player and player:getY()) or 0
        local z = tonumber(args.z) or (player and player:getZ()) or 0
        return PNC.API.Spawn({
            faction = faction,
            x = x, y = y, z = z,
            ownerUsername = ownerUsername,
            ownerOnlineID = ownerOnlineID,
            orderSpec = colonist and {
                kind = Const.ORDER_FOLLOW,
                ownerUsername = ownerUsername,
                ownerOnlineID = ownerOnlineID,
            } or hostile and {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = x, y = y, z = z,
            } or {
                kind = Const.ORDER_ROAM,
                roamMode = Const.ROAM_MODE_AREA,
                x = x, y = y, z = z,
                radius = Const.ROAM_DEFAULT_RADIUS,
            },
            weaponMode = variant == "hostile_ranged" and "ranged" or "melee",
            forceLive = true,
            debug = true,
        }) ~= nil
    end
    if PNC.API and args.id then
        return PNC.API.DebugCommand(args.id, action, args)
    end
    return false
end

function Client.SendRevive(npcId)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId then
        return false
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false
        end
        sendClientCommand(player, Const.MODULE, Const.CMD_REVIVE, { id = npcId })
        return true
    end
    return PNC.Revive and PNC.Revive.Try and PNC.Revive.Try(player, npcId) or false
end

function Client.SendBandage(npcId, partId)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not npcId or not partId then return false end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_BANDAGE, {
            id = npcId,
            partId = tostring(partId),
        })
        return true
    end
    return PNC.Treatment and PNC.Treatment.TryBandage
        and PNC.Treatment.TryBandage(player, npcId, partId) or false
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    local subMenu
    local square
    if not isWorldReady() then
        return
    end
    if test then
        return
    end

    square = PNC.NPCSelection and PNC.NPCSelection.GetWorldSquare and PNC.NPCSelection.GetWorldSquare(worldobjects) or nil
    if square and Client.CanUseDebug() then
        subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(context:addOption(tr("UI_PNC_Spawn", "PNC Spawn")), subMenu)
        subMenu:addOption(tr("UI_PNC_SpawnColonist", "Spawn Colonist"), nil, function()
            Client.SendDebug("spawn", { variant = "colonist", x = square:getX(), y = square:getY(), z = square:getZ() })
        end)
        subMenu:addOption(tr("UI_PNC_SpawnNeutral", "Spawn Neutral"), nil, function()
            Client.SendDebug("spawn", { variant = "neutral", x = square:getX(), y = square:getY(), z = square:getZ() })
        end)
        subMenu:addOption(tr("UI_PNC_SpawnHostileMelee", "Spawn Hostile Melee"), nil, function()
            Client.SendDebug("spawn", { variant = "hostile_melee", x = square:getX(), y = square:getY(), z = square:getZ() })
        end)
        subMenu:addOption(tr("UI_PNC_SpawnHostileRanged", "Spawn Hostile Ranged"), nil, function()
            Client.SendDebug("spawn", { variant = "hostile_ranged", x = square:getX(), y = square:getY(), z = square:getZ() })
        end)
    end
    if PNC.ContextHub and PNC.ContextHub.BuildWorldContext then
        PNC.ContextHub.BuildWorldContext(playerNum, context, worldobjects, test)
    end
end

local function onServerCommand(module, command, args)
    if module == Const.MODULE then
        Client.HandleServerCommand(command, args or {})
    end
end

local function onResetLua()
    ClientState.snapshots = {}
    ClientState.characterPayloads = {}
    ClientState.debugRoster = {}
    ClientState.debugAuthorized = false
    Client.BiteReplicas = {}
    if Interpolation and Interpolation.ClearAll then
        Interpolation.ClearAll()
    end
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(requestFullSync)
end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(requestFullSync)
end
if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
if Events and Events.OnTick then
    Events.OnTick.Add(pumpBiteReplicas)
end

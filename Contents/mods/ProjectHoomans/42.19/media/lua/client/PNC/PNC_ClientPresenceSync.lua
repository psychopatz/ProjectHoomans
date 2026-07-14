--[[
    PNC Client Presence Sync
    Owns client-side live NPC visual reconciliation for nearby bodies. Remote
    clients use it for interpolation plus visual sync, while local-authority
    worlds use the same snapshot stream for animation, facing, and UI only.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}

local Sync = PNC.ClientPresenceSync
local Core = PNC.Core
local Const = PNC.Const
local Animation = PNC.Animation
local Client = PNC.Client
local Network = PNC.Network
local Registry = PNC.Registry
local ClientState = PNC.Network.ClientState
local Visuals = PNC.Visuals
local Equipment = PNC.Equipment
local Interpolation = PNC.ClientInterpolation

Sync.BodyByID = Sync.BodyByID or {}
Sync.BodyByOnlineID = Sync.BodyByOnlineID or {}
Sync.BodyByInstanceID = Sync.BodyByInstanceID or {}
Sync.BodyByLease = Sync.BodyByLease or {}
Sync.FacingByID = Sync.FacingByID or {}
Sync.UnresolvedLogAtByID = Sync.UnresolvedLogAtByID or {}
Sync.lastBodyScanAt = Sync.lastBodyScanAt or 0
Sync.lastLocalSnapshotBuildAt = Sync.lastLocalSnapshotBuildAt or 0

local function isWorldReady()
    return (not isIngameState) or isIngameState()
end

local function isClientVisualReplicaMode()
    return Core and Core.IsClientOnly and Core.IsClientOnly()
end

local function canRequestRemoteSync()
    return isClientVisualReplicaMode()
end

local function isSnapshotDebugEnabled(snapshot)
    if snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true then
        return true
    end
    return false
end

local function logClientMotionDebug(snapshot, id, event, extra)
    if not isSnapshotDebugEnabled(snapshot) or not Core or not Core.Log then
        return
    end
    Core.Log("DEBUG", "client_presence npc=" .. tostring(id or "nil") .. " event=" .. tostring(event or "unknown") .. (extra and extra ~= "" and (" " .. tostring(extra)) or ""))
end

local function applySnapshotFacing(zombie, snapshot)
    local visualState
    local hint
    local interpState
    local targetX
    local targetY
    local dirX
    local dirY
    local len
    local now
    local facingState
    local facingKey
    local dot
    local authoritativeDirX
    local authoritativeDirY
    if not zombie or not snapshot then
        return false
    end
    visualState = snapshot.visualState or {}
    if visualState.specialActive == true
        or (visualState.moving ~= true
            and visualState.attackActive ~= true
            and visualState.stationaryFacing ~= true)
    then
        return false
    end
    hint = type(visualState.motionHint) == "table" and visualState.motionHint or nil
    interpState = snapshot and snapshot.id ~= nil and Interpolation and Interpolation.StateByID
        and Interpolation.StateByID[tostring(snapshot.id)] or nil
    targetX = tonumber(snapshot and snapshot.x) or zombie:getX()
    targetY = tonumber(snapshot and snapshot.y) or zombie:getY()
    authoritativeDirX = (visualState.attackActive == true or visualState.stationaryFacing == true)
        and tonumber(visualState.facingDirX)
        or tonumber(visualState.travelDirX)
    authoritativeDirY = (visualState.attackActive == true or visualState.stationaryFacing == true)
        and tonumber(visualState.facingDirY)
        or tonumber(visualState.travelDirY)
    if authoritativeDirX == nil
        and authoritativeDirY == nil
        and not hint
        and not interpState
        and math.abs(targetX - zombie:getX()) <= 0.001
        and math.abs(targetY - zombie:getY()) <= 0.001
    then
        return false
    end
    dirX = authoritativeDirX
        or tonumber(interpState and interpState.renderDirX)
        or tonumber(hint and hint.dirX)
        or tonumber(interpState and interpState.dirX)
        or ((tonumber(hint and hint.toX) or targetX) - (tonumber(hint and hint.fromX) or zombie:getX()))
    dirY = authoritativeDirY
        or tonumber(interpState and interpState.renderDirY)
        or tonumber(hint and hint.dirY)
        or tonumber(interpState and interpState.dirY)
        or ((tonumber(hint and hint.toY) or targetY) - (tonumber(hint and hint.fromY) or zombie:getY()))
    len = math.sqrt((dirX * dirX) + (dirY * dirY))
    if len <= 0.0001 then
        dirX = targetX - zombie:getX()
        dirY = targetY - zombie:getY()
        len = math.sqrt((dirX * dirX) + (dirY * dirY))
    end
    if len <= 0.0001 then
        return false
    end
    dirX = dirX / len
    dirY = dirY / len
    now = Core.Now()
    facingKey = tostring(snapshot.id or zombie)
    facingState = Sync.FacingByID[facingKey]
    if facingState and facingState.body == zombie then
        dot = (tonumber(facingState.dirX) or 0) * dirX
            + (tonumber(facingState.dirY) or 0) * dirY
        if (dot >= 0.998 and (now - (tonumber(facingState.appliedAt) or 0)) < (tonumber(Const.CLIENT_FACING_REASSERT_MS) or 220))
            or (dot >= 0.985 and (now - (tonumber(facingState.appliedAt) or 0)) < 120)
        then
            return false
        end
    end
    if zombie.faceLocation then
        zombie:faceLocation(zombie:getX() + dirX, zombie:getY() + dirY)
    elseif zombie.faceLocationF then
        zombie:faceLocationF(zombie:getX() + dirX, zombie:getY() + dirY)
    else
        return false
    end
    Sync.FacingByID[facingKey] = {
        body = zombie,
        dirX = dirX,
        dirY = dirY,
        appliedAt = now,
    }
    return true
end

local function buildRecordView(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    local moving = visualState.moving == true
    local specialActive = visualState.specialActive == true
    return {
        activeBehavior = snapshot and snapshot.activeBehavior or snapshot and snapshot.aiState or "Idle",
        activeJob = snapshot and snapshot.activeJob or snapshot and snapshot.aiState or "Idle",
        orderSpec = {
            kind = snapshot and snapshot.orderKind or "none",
        },
        presenceState = snapshot and snapshot.presenceState or Const.PRESENCE_ABSTRACT,
        weaponMode = snapshot and snapshot.weaponMode or "melee",
        visualProfile = snapshot and snapshot.visualProfile or nil,
        isFemale = snapshot and snapshot.isFemale == true or false,
        identitySeed = snapshot and snapshot.identitySeed or 1,
        archetypeID = snapshot and snapshot.archetypeID or nil,
        archetypeLabel = snapshot and snapshot.archetypeLabel or nil,
        health = {
            state = snapshot and snapshot.healthState or "normal",
        },
        outfit = snapshot and snapshot.appearance and snapshot.appearance.outfit or nil,
        identity = snapshot and snapshot.identity or nil,
        equipment = {
            primaryFullType = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.primaryFullType or nil,
            secondaryFullType = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.secondaryFullType or nil,
            worn = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.worn or {},
            attached = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.attached or {},
        },
        runtime = {
            debug = snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true or false,
            pathing = {
                phase = moving and "active" or "idle",
                ownerMode = moving and "fake_locomotion" or "idle",
                animSpeed = tonumber(visualState.animSpeed) or 1.0,
                mode = visualState.mode or "walk",
                resolvedMode = visualState.mode or "walk",
                moveAnim = visualState.moveAnim or visualState.anim or "Idle",
                walkType = visualState.walkType or "",
                engineWalkType = visualState.engineWalkType or visualState.walkType or "",
                profileKey = visualState.profileKey or visualState.mode or "walk",
                isRunning = visualState.isRunning == true,
                isCrawling = visualState.isCrawling == true,
                speed = tonumber(visualState.animSpeed) or 1.0,
                specialAnim = specialActive and visualState.specialAnim or nil,
                specialMoveUntil = specialActive and (tonumber(visualState.specialFinishAt) or 0) or 0,
                motionProfile = {
                    animSpeed = tonumber(visualState.animSpeed) or 1.0,
                    moveAnim = visualState.moveAnim or visualState.anim or "Idle",
                    walkType = visualState.walkType or "",
                    engineWalkType = visualState.engineWalkType or visualState.walkType or "",
                    isRunning = visualState.isRunning == true,
                    isCrawling = visualState.isCrawling == true,
                    profileKey = visualState.profileKey or visualState.mode or "walk",
                },
            },
        },
    }
end

local function stableTableSignature(tbl)
    local keys = {}
    local i = 0
    local key
    if type(tbl) ~= "table" then
        return ""
    end
    for key, _ in pairs(tbl) do
        i = i + 1
        keys[i] = tostring(key)
    end
    table.sort(keys)
    for i = 1, #keys do
        keys[i] = keys[i] .. "=" .. tostring(tbl[keys[i]] or "")
    end
    return table.concat(keys, ";")
end

local function buildVisualKey(snapshot)
    local appearance = snapshot and snapshot.appearance or {}
    local equipment = snapshot and snapshot.equipmentSummary or {}
    return table.concat({
        tostring(snapshot and snapshot.presenceRevision or 0),
        tostring(snapshot and snapshot.visualProfile or ""),
        tostring(snapshot and snapshot.isFemale == true),
        tostring(appearance.outfit or ""),
        tostring(appearance.skinTexture or ""),
        tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""),
        stableTableSignature(equipment.worn),
        stableTableSignature(equipment.attached),
    }, "|")
end

local function buildHandsKey(snapshot)
    local equipment = snapshot and snapshot.equipmentSummary or {}
    return table.concat({
        tostring(snapshot and snapshot.presenceRevision or 0),
        tostring(equipment.primaryFullType or ""),
        tostring(equipment.secondaryFullType or ""),
    }, "|")
end

local function buildMotionKey(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    return table.concat({
        tostring(snapshot and snapshot.presenceRevision or 0),
        tostring(snapshot and snapshot.healthState or "normal"),
        tostring(visualState.anim or "Idle"),
        tostring(visualState.moveAnim or ""),
        tostring(visualState.walkType or ""),
        tostring(visualState.engineWalkType or ""),
        tostring(visualState.mode or ""),
        tostring(visualState.moving == true),
        tostring(visualState.attackActive == true),
        tostring(visualState.attackAnim or ""),
        tostring(visualState.attackFinishAt or 0),
        tostring(tonumber(visualState.animSpeed) or 1.0),
        tostring(visualState.isRunning == true),
        tostring(visualState.isCrawling == true),
        tostring(visualState.profileKey or ""),
        tostring(visualState.specialActive == true),
        tostring(visualState.specialAnim or ""),
        tostring(visualState.specialFinishAt or 0),
    }, "|")
end

local function applyIdentityVars(zombie, snapshot)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable("PNCActor", true)
    zombie:setVariable("PNCLive", snapshot and snapshot.presenceState == Const.PRESENCE_LIVE)
    if zombie.setFemaleEtc then
        zombie:setFemaleEtc(snapshot and snapshot.isFemale == true)
    end
end

local function refreshBodyMap(now)
    local zombieList
    local body
    local modData
    local onlineID
    local instanceKey
    local scanInterval = tonumber(Const.CLIENT_BODY_SCAN_MS) or 750
    local i
    local id
    local snapshot
    if not getCell
        or now < ((tonumber(Sync.lastBodyScanAt) or 0) + (tonumber(Const.CLIENT_BODY_SCAN_UNRESOLVED_MS) or 200))
    then
        return
    end
    for id, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.interestDetailed ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE and snapshot.alive ~= false
        then
            onlineID = snapshot.liveBodyOnlineID ~= nil and tostring(snapshot.liveBodyOnlineID) or nil
            instanceKey = snapshot.liveBodyInstanceID ~= nil and tostring(snapshot.liveBodyInstanceID) or nil
            local leaseKey = snapshot.liveBodyLease
                and (tostring(id) .. ":" .. tostring(snapshot.liveBodyLease)) or nil
            if not (leaseKey and Sync.BodyByLease[leaseKey])
                and not Sync.BodyByID[tostring(id)]
                and not (onlineID and Sync.BodyByOnlineID[onlineID])
                and not (instanceKey and Sync.BodyByInstanceID[instanceKey])
            then
                scanInterval = tonumber(Const.CLIENT_BODY_SCAN_UNRESOLVED_MS) or 200
                break
            end
        end
    end
    if now < ((tonumber(Sync.lastBodyScanAt) or 0) + scanInterval) then
        return
    end
    Sync.lastBodyScanAt = now
    Sync.BodyByID = {}
    Sync.BodyByOnlineID = {}
    Sync.BodyByInstanceID = {}
    Sync.BodyByLease = {}
    zombieList = getCell():getZombieList()
    if not zombieList then
        return
    end
    for i = 0, zombieList:size() - 1 do
        body = zombieList:get(i)
        modData = body and body.getModData and body:getModData() or nil
        if modData and modData.PNC_UUID and modData.PNC_NPC == true then
            id = tostring(modData.PNC_UUID)
            if Sync.BodyByID[id] ~= nil and Sync.BodyByID[id] ~= body then
                Sync.BodyByID[id] = false
            elseif Sync.BodyByID[id] == nil then
                Sync.BodyByID[id] = body
            end
            if modData.PNC_BodyLease then
                instanceKey = id .. ":" .. tostring(modData.PNC_BodyLease)
                if Sync.BodyByLease[instanceKey] ~= nil and Sync.BodyByLease[instanceKey] ~= body then
                    Sync.BodyByLease[instanceKey] = false
                elseif Sync.BodyByLease[instanceKey] == nil then
                    Sync.BodyByLease[instanceKey] = body
                end
            end
        end
        onlineID = Network and Network.GetZombieOnlineID and Network.GetZombieOnlineID(body) or nil
        if onlineID ~= nil then
            Sync.BodyByOnlineID[tostring(onlineID)] = body
        end
        if body and body.getPersistentOutfitID then
            instanceKey = tostring(body:getPersistentOutfitID() or "")
            if instanceKey ~= "" and instanceKey ~= "0" and instanceKey ~= "-1" then
                if Sync.BodyByInstanceID[instanceKey] ~= nil and Sync.BodyByInstanceID[instanceKey] ~= body then
                    Sync.BodyByInstanceID[instanceKey] = false
                elseif Sync.BodyByInstanceID[instanceKey] == nil then
                    Sync.BodyByInstanceID[instanceKey] = body
                end
            end
        end
    end
end

local function refreshLocalAuthoritySnapshots(now)
    local snapshots
    if canRequestRemoteSync() then
        return
    end
    if not Registry or not Registry.ForEach or not Network or not Network.BuildSnapshot then
        return
    end
    if now < ((tonumber(Sync.lastLocalSnapshotBuildAt) or 0) + 75) then
        return
    end
    Sync.lastLocalSnapshotBuildAt = now
    snapshots = {}
    Registry.ForEach(function(record)
        local snapshot = Network.BuildSnapshot(record)
        if snapshot and snapshot.id then
            snapshots[snapshot.id] = snapshot
        end
    end)
    ClientState.snapshots = snapshots
    ClientState.lastSyncReceiveAt = now
end

local function applySnapshotToBody(snapshot, zombie)
    local visualState = snapshot and snapshot.visualState or {}
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local attackKey
    local specialKey
    local desiredAnim
    local recordView
    local visualKey
    local handsKey
    local motionKey
    local now
    if not snapshot or not zombie or (zombie.isDead and zombie:isDead()) then
        return
    end

    now = Core and Core.Now and Core.Now() or 0
    if Animation and Animation.PumpBumpRelease then
        Animation.PumpBumpRelease(zombie, now)
    end

    recordView = buildRecordView(snapshot)
    applyIdentityVars(zombie, snapshot)
    if modData and snapshot and snapshot.id ~= nil then
        modData.PNC_UUID = tostring(snapshot.id)
        modData.PNC_NPC = true
        modData.PNC_LiveBodyInstanceID = snapshot.liveBodyInstanceID
        modData.PNC_LiveBodyOnlineID = snapshot.liveBodyOnlineID
        modData.PNC_BodyKind = "live"
        modData.PNC_BodyLease = snapshot.liveBodyLease
        modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    end

    visualKey = buildVisualKey(snapshot)
    handsKey = buildHandsKey(snapshot)
    if modData and modData.PNC_ClientVisualKey ~= visualKey then
        if Animation and Animation.ApplyLiveSetup then
            Animation.ApplyLiveSetup(zombie, recordView)
        end
        if Visuals and Visuals.ApplyResolvedAppearance then
            Visuals.ApplyResolvedAppearance(zombie, snapshot.appearance or {}, snapshot.isFemale == true)
        end
        if Equipment and Equipment.Apply then
            Equipment.Apply(zombie, recordView)
        end
        modData.PNC_ClientVisualKey = visualKey
        modData.PNC_ClientHandsKey = handsKey
    elseif modData and modData.PNC_ClientHandsKey ~= handsKey then
        if Equipment and Equipment.ApplyHands then
            Equipment.ApplyHands(zombie, recordView)
        elseif Equipment and Equipment.Apply then
            Equipment.Apply(zombie, recordView)
        end
        modData.PNC_ClientHandsKey = handsKey
    end

    -- The multiplayer zombie packet may reapply rot, blood, dirt, or a zombie
    -- skin after the one-time visual snapshot. Reassert only the inexpensive
    -- human visual fields on a bounded cadence; clothes and inventory stay put.
    if Visuals and Visuals.MaintainHumanAppearance
        and (not modData or now >= (tonumber(modData.PNC_ClientHumanVisualAt) or 0))
    then
        Visuals.MaintainHumanAppearance(zombie, snapshot.appearance or {}, snapshot.isFemale == true, true)
        if modData then
            modData.PNC_ClientHumanVisualAt = now + 1000
        end
    end

    motionKey = buildMotionKey(snapshot)

    if snapshot.healthState == "incapacitated" then
        if Animation and Animation.ApplyDowned then
            Animation.ApplyDowned(zombie, recordView, visualState.moving == true and visualState.isCrawling == true and recordView.runtime.pathing.motionProfile or false)
        end
        if modData then
            modData.PNC_ClientMotionKey = motionKey
        end
        return
    elseif Animation and Animation.ClearDowned then
        Animation.ClearDowned(zombie)
    end

    attackKey = visualState.attackActive and visualState.attackAnim
        and (tostring(visualState.attackAnim) .. ":" .. tostring(visualState.attackFinishAt or 0))
        or nil
    if attackKey and modData and modData.PNC_ClientAttackKey ~= attackKey then
        Animation.PlayBump(zombie, recordView, visualState.attackAnim)
        modData.PNC_ClientAttackKey = attackKey
        modData.PNC_ClientMotionKey = motionKey
        return
    end
    if modData and not attackKey and modData.PNC_ClientAttackKey ~= nil then
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientAttackKey = nil
        return
    end
    if attackKey then
        return
    end

    specialKey = visualState.specialActive and visualState.specialAnim
        and (tostring(visualState.specialAnim) .. ":" .. tostring(visualState.specialFinishAt or 0))
        or nil
    if specialKey and modData and modData.PNC_ClientSpecialKey ~= specialKey then
        Animation.PlayBump(zombie, recordView, visualState.specialAnim)
        modData.PNC_ClientSpecialKey = specialKey
        modData.PNC_ClientMotionKey = motionKey
        return
    end
    if modData and not specialKey and modData.PNC_ClientSpecialKey ~= nil then
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientSpecialKey = nil
        return
    end
    if specialKey then
        return
    end

    desiredAnim = visualState.anim or "Idle"
    if Animation and Animation.Apply and (not modData or modData.PNC_ClientMotionKey ~= motionKey) then
        Animation.Apply(zombie, recordView, desiredAnim, recordView.runtime.pathing.motionProfile, visualState.moving == true)
        if modData then
            modData.PNC_ClientMotionKey = motionKey
        end
    end
    if visualState.moving == true and Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie, recordView)
        logClientMotionDebug(snapshot, snapshot and snapshot.id or nil, "locomotion_resync", "mode=" .. tostring(visualState.mode or "walk") .. " walkType=" .. tostring(visualState.walkType or ""))
    end
end

local function requestSyncIfStale(now)
    local player = getSpecificPlayer(0)
    local lastRequestAt = tonumber(ClientState.lastFullSyncRequestAt or 0) or 0
    local lastReceiveAt = tonumber(ClientState.lastSyncReceiveAt or 0) or 0
    local hasSnapshots = false
    local id
    if not player or not sendClientCommand or not Client or not Client.RequestFullSync then
        return
    end
    for id, _ in pairs(ClientState and ClientState.snapshots or {}) do
        hasSnapshots = true
        break
    end
    if hasSnapshots then
        return
    end
    if lastReceiveAt > 0 and (now - lastReceiveAt) < 6000 then
        return
    end
    if (now - lastRequestAt) < 4000 then
        return
    end
    Client.RequestFullSync()
end

function Sync.OnTick()
    local now = Core.Now()
    local id
    local snapshot
    local body
    if not isWorldReady() then
        return
    end
    if canRequestRemoteSync() then
        requestSyncIfStale(now)
    end
    refreshLocalAuthoritySnapshots(now)
    refreshBodyMap(now)
    for id, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.interestDetailed ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE and snapshot.alive ~= false
        then
            body = Sync.BodyByOnlineID[tostring(snapshot.liveBodyOnlineID or "")]
            if not body and snapshot.liveBodyLease then
                body = Sync.BodyByLease[tostring(id) .. ":" .. tostring(snapshot.liveBodyLease)]
            end
            if not body and not snapshot.liveBodyLease then
                body = Sync.BodyByID[tostring(id)]
            end
            body = body or Sync.BodyByInstanceID[tostring(snapshot.liveBodyInstanceID or "")]
            if body then
                if canRequestRemoteSync() and Interpolation and Interpolation.RecordSnapshot then
                    Interpolation.RecordSnapshot(snapshot, body, now)
                end
                if canRequestRemoteSync() and Interpolation and Interpolation.ApplyToZombie then
                    Interpolation.ApplyToZombie(snapshot, body, now)
                end
                -- The authoritative SP/listen-server body was already faced
                -- by PathService.  Re-facing it from the client snapshot loop
                -- created a second movement owner.  Dedicated clients alone
                -- apply replicated facing, with throttling above.
                if canRequestRemoteSync() then
                    applySnapshotFacing(body, snapshot)
                end
                applySnapshotToBody(snapshot, body)
            elseif isSnapshotDebugEnabled(snapshot)
                and (now - (tonumber(Sync.UnresolvedLogAtByID[tostring(id)]) or 0)) >= 3000
            then
                Sync.UnresolvedLogAtByID[tostring(id)] = now
                logClientMotionDebug(
                    snapshot,
                    id,
                    "body_unresolved",
                    "onlineID=" .. tostring(snapshot.liveBodyOnlineID or "nil")
                        .. " instanceID=" .. tostring(snapshot.liveBodyInstanceID or "nil")
                )
            end
        end
    end
end

local function onResetLua()
    Sync.BodyByID = {}
    Sync.BodyByOnlineID = {}
    Sync.BodyByInstanceID = {}
    Sync.BodyByLease = {}
    Sync.FacingByID = {}
    Sync.UnresolvedLogAtByID = {}
    Sync.lastBodyScanAt = 0
    if Interpolation and Interpolation.ClearAll then
        Interpolation.ClearAll()
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(Sync.OnTick)
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

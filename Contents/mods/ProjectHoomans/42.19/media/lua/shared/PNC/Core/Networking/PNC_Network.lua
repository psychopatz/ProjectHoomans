--[[
    PNC Networking
    Owns compact roster/full snapshot payloads and server-to-client replication.
    It serializes canonical view data only and leaves client visual application
    to dedicated client modules.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.ClientState = PNC.Network.ClientState or {
    snapshots = {},
    characterPayloads = {},
    debugRoster = {},
    debugAuthorized = false,
}
PNC.Network.ServerState = PNC.Network.ServerState or {
    interests = {},
    rosterDeltas = {},
    rosterRevision = 0,
    lastInterestRefreshAt = 0,
    lastRosterFlushAt = 0,
}

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const
local Equipment = PNC.Equipment
local Inventory = PNC.Inventory
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Profiles = PNC.VisualProfiles
local MotionHints = PNC.MotionHints
local Wounds = PNC.NPCWounds
local Firearms = PNC.Firearms
local ServerState = PNC.Network.ServerState

local function buildTravelSummary(record, includeRoute)
    return PNC.Travel
        and PNC.Travel.Model
        and PNC.Travel.Model.BuildSummary
        and PNC.Travel.Model.BuildSummary(record and record.travel, includeRoute)
        or nil
end

local function buildMapPresentationSummary(record)
    return PNC.MapPresentation
        and PNC.MapPresentation.BuildSummary
        and PNC.MapPresentation.BuildSummary(
            record and record.mapPresentation
        )
        or nil
end

function PNC.Network.ResetServerState()
    ServerState.interests = {}
    ServerState.rosterDeltas = {}
    ServerState.rosterRevision = 0
    ServerState.lastInterestRefreshAt = 0
    ServerState.lastRosterFlushAt = 0
end

local function playerKey(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return tostring(player)
end

local function sendToPlayer(player, command, payload)
    if isServer and isServer() and player and sendServerCommand then
        sendServerCommand(player, Const.MODULE, command, payload)
        return true
    end
    if not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
        return true
    end
    return false
end

local function sendToInterestedNPC(npcId, command, payload)
    local state
    local count = 0
    npcId = npcId and tostring(npcId) or nil
    if not npcId then
        return 0
    end
    for _, state in pairs(ServerState.interests) do
        if state.player and state.ids and state.ids[npcId] then
            sendToPlayer(state.player, command, payload)
            count = count + 1
        end
    end
    return count
end

local function resolveAIState(record)
    local healthState = record.health and tostring(record.health.state or "normal") or "normal"
    local hasTarget = record.runtime and record.runtime.target ~= nil
    local inCombat = hasTarget
        or ((tonumber(record.runtime and record.runtime.inCombatUntil or 0) or 0) > Core.Now())
    if record.alive == false then
        return "Dead", false
    end
    if healthState == "incapacitated" then
        return "Downed", true
    end
    if record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        return "VehiclePassenger", false
    end
    if record.presenceState == Const.PRESENCE_ABSTRACT then
        return "Abstract", false
    end
    if inCombat then
        return "Combat", true
    end
    if record.activeBehavior and record.activeBehavior ~= "" then
        return tostring(record.activeBehavior), false
    end
    return "Idle", false
end

local function buildIdentitySummary(record)
    local summary = PNC.Identity and PNC.Identity.GetCharacterSummary and PNC.Identity.GetCharacterSummary(record) or {}
    return {
        displayName = summary.displayName or record.name,
        archetypeID = summary.archetypeID or record.archetypeID,
        archetypeLabel = summary.archetypeLabel or record.archetypeLabel,
        identitySeed = summary.identitySeed or record.identitySeed,
        isFemale = summary.isFemale == true or record.isFemale == true,
        survivor = Core.DeepCopy(summary.survivor or {}),
    }
end

local function buildCombatSummary(record, equipmentInfo)
    local target = record.runtime and record.runtime.target or nil
    equipmentInfo = equipmentInfo or Equipment and Equipment.Describe and Equipment.Describe(record) or {}
    return {
        targetKind = target and target.kind or "none",
        combatModeResolved = equipmentInfo.combatModeResolved or record.weaponMode,
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        combatBlockReason = record.runtime and record.runtime.combatBlockReason or nil,
    }
end

local function buildCommandFeedback(record)
    local runtime = record and record.runtime or nil
    local revision = tonumber(runtime and runtime.lastCompanionCommandRevision)
    if not runtime or not runtime.lastCompanionCommand or revision == nil then
        return false
    end
    if Core.Now() - (tonumber(runtime.lastCompanionCommandAt) or 0)
        > (tonumber(Const.COMPANION_COMMAND_FEEDBACK_MS) or 5000)
    then
        return false
    end
    return {
        id = tostring(runtime.lastCompanionCommand),
        revision = revision,
        issuedAt = tonumber(runtime.lastCompanionCommandAt) or 0,
        ownerUsername = runtime.lastCompanionCommandOwner,
    }
end

local function buildBandageFeedback(record)
    local runtime = record and record.runtime or nil
    local revision = tonumber(runtime and runtime.bandageCompletionRevision)
    local completedAt = tonumber(runtime and runtime.bandageCompletionAt) or 0
    if not runtime or revision == nil then return false end
    if Core.Now() - completedAt
        > (tonumber(Const.BANDAGE_COMPLETION_FEEDBACK_MS) or 5000)
    then
        return false
    end
    return {
        revision = revision,
        completedAt = completedAt,
        partId = runtime.bandageCompletionPartId,
        sound = tostring(
            Const.BANDAGE_COMPLETION_SOUND or "PNC_BandageComplete"
        ),
    }
end

local function buildVisualState(record)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local attack = runtime and runtime.attackAction or nil
    local now = Core.Now()
    local healthState = record and record.health and tostring(record.health.state or "normal") or "normal"
    local moving = path and (
        path.phase == "requested"
        or path.phase == "active"
        or now < (tonumber(path.visualMovingUntil) or 0)
    ) or false
    local mode = moving and tostring(path.resolvedMode or path.mode or "walk") or nil
    local walkType = moving and tostring(path.walkType or "") or ""
    local moveAnim = moving and tostring(path.moveAnim or "") or ""
    local engineWalkType = moving and tostring(path.engineWalkType or "") or ""
    local anim = "Idle"
    local attackActive = attack ~= nil and now < (tonumber(attack.finishAt) or 0)
    local specialActive = path ~= nil and now < (tonumber(path.specialMoveUntil) or 0)
    local animSpeed = path and tonumber(path.animSpeed) or 1.0
    local profileKey = path and tostring(path.profileKey or "") or ""
    local isRunning = path and path.isRunning == true or false
    local isCrawling = path and path.isCrawling == true or false
    local motionHint = path and MotionHints and MotionHints.BuildNetworkHint and MotionHints.BuildNetworkHint(record, path, now) or nil
    local travelDirX = tonumber(motionHint and motionHint.dirX) or tonumber(path and path.lastFacingDirX)
    local travelDirY = tonumber(motionHint and motionHint.dirY) or tonumber(path and path.lastFacingDirY)
    local travelLen = travelDirX and travelDirY and math.sqrt((travelDirX * travelDirX) + (travelDirY * travelDirY)) or 0
    local facingDirX = tonumber(path and path.lastFacingDirX)
    local facingDirY = tonumber(path and path.lastFacingDirY)

    if travelLen > 0.0001 then
        travelDirX = travelDirX / travelLen
        travelDirY = travelDirY / travelLen
    else
        travelDirX = nil
        travelDirY = nil
    end

    if healthState == "incapacitated" then
        walkType = moving and tostring(path and path.walkType or "Crawl") or ""
        moveAnim = moving and tostring(path and path.moveAnim or "Crawl") or ""
        engineWalkType = moving and tostring(path and path.engineWalkType or "") or ""
        anim = moving and moveAnim or "Downed"
        isCrawling = moving
        profileKey = moving and tostring(path and path.profileKey or "crawl") or "downed"
    elseif moving then
        anim = moveAnim ~= "" and moveAnim or "Walk"
    end

    if specialActive and path and path.specialAnim then
        anim = tostring(path.specialAnim)
        moving = false
        walkType = ""
        moveAnim = ""
        engineWalkType = ""
    end

    if attackActive and attack and attack.anim then
        anim = tostring(attack.anim)
    end

    return {
        moving = moving,
        mode = mode,
        walkType = walkType,
        moveAnim = moveAnim,
        engineWalkType = engineWalkType,
        anim = anim,
        attackActive = attackActive,
        attackAnim = attack and attack.anim or nil,
        attackStartedAt = attack and attack.startedAt or 0,
        attackHitAt = attack and attack.hitAt or 0,
        attackFinishAt = attack and attack.finishAt or 0,
        animSpeed = animSpeed,
        isRunning = isRunning,
        isCrawling = isCrawling,
        profileKey = profileKey,
        motionHint = motionHint,
        travelDirX = travelDirX,
        travelDirY = travelDirY,
        facingDirX = facingDirX,
        facingDirY = facingDirY,
        facingOwner = path and path.facingOwner or nil,
        stationaryFacing = not moving and path and path.facingOwner == "behavior_idle" or false,
        specialActive = specialActive,
        specialAnim = specialActive and path and path.specialAnim or nil,
        specialFinishAt = specialActive and path and path.specialMoveUntil or 0,
    }
end

function Network.BuildRosterSnapshot(record, includeTravelRoute)
    local aiState
    local inCombat
    local staminaInfo
    local identity
    if type(record) ~= "table" then
        return nil
    end
    aiState, inCombat = resolveAIState(record)
    staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    identity = buildIdentitySummary(record)
    return {
        interestDetailed = false,
        id = record.id,
        displayName = identity.displayName,
        name = identity.displayName,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        identitySeed = identity.identitySeed,
        faction = record.faction,
        presenceState = record.presenceState,
        x = record.x,
        y = record.y,
        z = record.z,
        orderKind = record.orderSpec and record.orderSpec.kind or nil,
        attackType = record.attackType or "auto",
        ownerUsername = record.ownerUsername
            or record.characterWindow
                and record.characterWindow.ownerUsername,
        ownerOnlineID = record.ownerOnlineID
            or record.characterWindow
                and record.characterWindow.ownerOnlineID,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        aiState = aiState,
        inCombat = inCombat,
        recruited = record.recruited == true,
        persist = record.persist ~= false,
        travel = buildTravelSummary(record, includeTravelRoute ~= false),
        mapPresentation = buildMapPresentationSummary(record),
    }
end

function Network.BuildSnapshot(record)
    local aiState
    local canRevive
    local inCombat
    local staminaInfo
    local equipmentInfo
    local identity
    local inventorySummary
    local combat
    local visualState
    local appearance
    local bodyHealth
    local firearmState
    local vehiclePassenger
    local treatmentState
    local attackMode
    aiState, inCombat = resolveAIState(record)
    canRevive = PNC.Health and PNC.Health.CanRevive and PNC.Health.CanRevive(record) or false
    staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    equipmentInfo = Equipment and Equipment.Describe and Equipment.Describe(record) or {}
    identity = buildIdentitySummary(record)
    inventorySummary = Inventory and Inventory.BuildSummaryPayload and Inventory.BuildSummaryPayload(record) or nil
    combat = buildCombatSummary(record, equipmentInfo)
    visualState = buildVisualState(record)
    appearance = Profiles and Profiles.RollAppearance and Profiles.RollAppearance(record) or nil
    bodyHealth = Wounds and Wounds.BuildSnapshot and Wounds.BuildSnapshot(record) or nil
    firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
    treatmentState = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.BuildSnapshot
        and PNC.BehaviorTreatment.BuildSnapshot(record) or nil
    attackMode = record.runtime and (
        record.runtime.target ~= nil
        or (
            record.runtime.attackAction ~= nil
            and Core.Now() < (
                tonumber(record.runtime.attackAction.finishAt) or 0
            )
        )
    ) or false
    return {
        interestDetailed = true,
        id = record.id,
        name = identity.displayName,
        displayName = identity.displayName,
        identitySeed = identity.identitySeed,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        recruited = record.recruited == true,
        persist = record.persist ~= false,
        faction = record.faction,
        visualProfile = record.visualProfile,
        isFemale = identity.isFemale,
        identity = identity,
        x = record.x,
        y = record.y,
        z = record.z,
        orderKind = record.orderSpec and record.orderSpec.kind or nil,
        attackType = record.attackType or "auto",
        ownerUsername = record.ownerUsername
            or record.characterWindow
                and record.characterWindow.ownerUsername,
        ownerOnlineID = record.ownerOnlineID
            or record.characterWindow
                and record.characterWindow.ownerOnlineID,
        commandFeedback = buildCommandFeedback(record),
        bandageFeedback = buildBandageFeedback(record),
        activeJob = record.activeJob,
        activeBehavior = record.activeBehavior,
        presenceState = record.presenceState,
        alive = record.alive,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        canRevive = canRevive,
        reviveUntil = record.health and record.health.reviveUntil or 0,
        recentDamageUntil = record.health and record.health.recentDamageUntil or 0,
        bodyHealth = bodyHealth,
        treatmentState = treatmentState,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        staminaVisibleUntil = staminaInfo.visibleUntil,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        staminaRatio = math.max(0, math.min(1, (tonumber(staminaInfo.current) or 0) / math.max(1, tonumber(staminaInfo.max) or 1))),
        skillLevels = Skills and Skills.BuildSnapshot and Skills.BuildSnapshot(record) or {},
        weaponMode = record.weaponMode,
        weaponFullType = record.equipment and record.equipment.primaryFullType or nil,
        combatModeResolved = equipmentInfo.combatModeResolved or record.weaponMode,
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        firearmState = firearmState,
        vehiclePassenger = vehiclePassenger and {
            active = vehiclePassenger.active == true,
            vehicleId = vehiclePassenger.vehicleId,
            seat = vehiclePassenger.seat,
            ownerOnlineID = vehiclePassenger.ownerOnlineID,
            boardedAt = vehiclePassenger.boardedAt,
        } or nil,
        presenceRevision = record.presenceRevision,
        liveBodyInstanceID = record.liveBodyInstanceID,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyLease = record.runtime and record.runtime.bodyLease or nil,
        aiState = aiState,
        inCombat = inCombat,
        attackMode = attackMode,
        visualState = visualState,
        appearance = appearance and Core.DeepCopy(appearance) or nil,
        travel = buildTravelSummary(record, true),
        mapPresentation = buildMapPresentationSummary(record),
        equipmentSummary = {
            primaryFullType = record.equipment and record.equipment.primaryFullType or nil,
            secondaryFullType = record.equipment and record.equipment.secondaryFullType or nil,
            worn = Core.DeepCopy(record.equipment and record.equipment.worn or {}),
            attached = Core.DeepCopy(record.equipment and record.equipment.attached or {}),
        },
        inventorySummary = inventorySummary,
        characterWindow = {
            displayName = identity.displayName,
            archetypeID = identity.archetypeID,
            archetypeLabel = identity.archetypeLabel,
            identitySeed = identity.identitySeed,
            ownerUsername = record.ownerUsername,
            recruited = record.recruited == true,
            canRevive = canRevive,
            carry = inventorySummary,
        },
        debugState = {
            aiState = aiState,
            activeJob = record.activeJob,
            activeBehavior = record.activeBehavior,
            orderKind = record.orderSpec and record.orderSpec.kind or nil,
            attackType = record.attackType or "auto",
            targetKind = combat.targetKind,
            healthState = record.health and record.health.state or nil,
            canRevive = canRevive,
            weaponMode = record.weaponMode,
            combatModeResolved = combat.combatModeResolved,
            weaponStatus = combat.weaponStatus,
            magazineCount = firearmState and firearmState.count or nil,
            magazineCapacity = firearmState and firearmState.capacity or nil,
            ammoReserveUnlimited = firearmState and firearmState.unlimitedReserve == true or false,
            ammoReserveCount = firearmState and firearmState.reserveCount or nil,
            firearmReloadActive = firearmState and firearmState.reloadActive == true or false,
            vehiclePassenger = vehiclePassenger and vehiclePassenger.active == true or false,
            vehicleId = vehiclePassenger and vehiclePassenger.vehicleId or nil,
            vehicleSeat = vehiclePassenger and vehiclePassenger.seat or nil,
            vehicleBlockReason = record.runtime and record.runtime.vehicleBlockReason or nil,
            combatBlockReason = combat.combatBlockReason,
            staminaState = staminaInfo.state,
            staminaCurrent = staminaInfo.current,
            staminaMax = staminaInfo.max,
            staminaBaseMax = staminaInfo.baseMax,
            encumbranceLevel = staminaInfo.encumbranceLevel,
            encumbranceRatio = staminaInfo.encumbranceRatio,
            stealthActive = record.runtime and record.runtime.stealthActive == true or false,
            debugEnabled = record.runtime and record.runtime.debug == true or false,
            presenceState = record.presenceState,
            movePhase = record.runtime and record.runtime.pathing and record.runtime.pathing.phase or "idle",
            moveMode = record.runtime and record.runtime.pathing and (record.runtime.pathing.resolvedMode or record.runtime.pathing.mode) or nil,
            moveGoal = record.runtime and record.runtime.pathing and record.runtime.pathing.goal or nil,
            moveCancelReason = record.runtime and record.runtime.pathing and record.runtime.pathing.cancelReason or nil,
            moveBlockReason = record.runtime and record.runtime.pathing and record.runtime.pathing.blockReason or nil,
        },
    }
end

function Network.BuildPresenceDelta(record)
    local aiState
    local inCombat
    local staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    local firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    local vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
    aiState, inCombat = resolveAIState(record)
    return {
        interestDetailed = true,
        id = record.id,
        x = record.x,
        y = record.y,
        z = record.z,
        presenceState = record.presenceState,
        alive = record.alive,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        attackType = record.attackType or "auto",
        commandFeedback = buildCommandFeedback(record),
        bandageFeedback = buildBandageFeedback(record),
        treatmentState = PNC.BehaviorTreatment
            and PNC.BehaviorTreatment.BuildSnapshot
            and PNC.BehaviorTreatment.BuildSnapshot(record) or nil,
        recentDamageUntil = record.health and record.health.recentDamageUntil or 0,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        staminaVisibleUntil = staminaInfo.visibleUntil,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        presenceRevision = record.presenceRevision,
        liveBodyInstanceID = record.liveBodyInstanceID,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyLease = record.runtime and record.runtime.bodyLease or nil,
        aiState = aiState,
        inCombat = inCombat,
        attackMode = record.runtime and record.runtime.target ~= nil or false,
        firearmState = firearmState,
        vehiclePassenger = vehiclePassenger and {
            active = vehiclePassenger.active == true,
            vehicleId = vehiclePassenger.vehicleId,
            seat = vehiclePassenger.seat,
            ownerOnlineID = vehiclePassenger.ownerOnlineID,
            boardedAt = vehiclePassenger.boardedAt,
        } or nil,
        visualState = buildVisualState(record),
        travel = buildTravelSummary(record, false),
    }
end

function Network.BuildCharacterPayload(record)
    local snapshot = Network.BuildSnapshot(record)
    local inventoryPayload = Inventory and Inventory.BuildFullPayload and Inventory.BuildFullPayload(record) or nil
    local identity = buildIdentitySummary(record)
    return {
        npcId = record.id,
        revision = record.presenceRevision,
        snapshot = snapshot,
        identity = identity,
        health = Core.DeepCopy(record.health or {}),
        stamina = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {},
        inventory = inventoryPayload,
        equipment = Core.DeepCopy(record.equipment or {}),
        progression = {
            recruited = record.recruited == true,
            skillLevels = Skills and Skills.BuildSnapshot and Skills.BuildSnapshot(record) or {},
            skillXP = Core.DeepCopy(record.progression and record.progression.skillXP or {}),
        },
    }
end

function Network.QueueRosterDelta(record, removed, reason, includeTravelRoute)
    local id = type(record) == "table" and record.id or record
    local snapshot
    if id == nil then
        return false
    end
    if removed ~= true and type(record) ~= "table" then
        return false
    end
    id = tostring(id)
    -- Lua's `condition and nil or value` idiom can never produce nil: the `or`
    -- branch runs because nil is falsey. Build removal entries explicitly so an
    -- NPC id string is never passed to BuildRosterSnapshot as though it were a
    -- record table.
    if removed ~= true then
        snapshot = Network.BuildRosterSnapshot(
            record,
            includeTravelRoute ~= false
        )
    end
    ServerState.rosterRevision = (tonumber(ServerState.rosterRevision) or 0) + 1
    ServerState.rosterDeltas[id] = {
        id = id,
        removed = removed == true,
        reason = reason,
        revision = ServerState.rosterRevision,
        snapshot = snapshot,
    }
    return true
end

function Network.QueuePeriodicRoster(record, now)
    local runtime
    local signature
    if not record or not record.id then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    now = tonumber(now) or Core.Now()
    signature = table.concat({
        tostring(math.floor(tonumber(record.x) or 0)),
        tostring(math.floor(tonumber(record.y) or 0)),
        tostring(math.floor(tonumber(record.z) or 0)),
        tostring(record.presenceState or ""),
        tostring(record.health and record.health.state or ""),
        tostring(record.orderSpec and record.orderSpec.kind or ""),
        tostring(record.travel and record.travel.state or ""),
        tostring(record.travel and record.travel.revision or 0),
    }, ":")
    if runtime.rosterSignature == signature then
        return false
    end
    if now - (tonumber(runtime.lastRosterQueuedAt) or 0) < Const.ROSTER_DELTA_INTERVAL_MS then
        return false
    end
    runtime.rosterSignature = signature
    runtime.lastRosterQueuedAt = now
    Network.QueueRosterDelta(record, false, "periodic", false)
    return true
end

function Network.RefreshInterestSets(now)
    local Spatial = PNC.SpatialIndex
    local seenPlayers = {}
    now = tonumber(now) or Core.Now()
    if not isServer or not isServer() or now - (tonumber(ServerState.lastInterestRefreshAt) or 0) < Const.INTEREST_REFRESH_MS then
        return
    end
    ServerState.lastInterestRefreshAt = now
    Core.ForEachPlayer(function(player)
        local key = playerKey(player)
        local state = ServerState.interests[key] or { ids = {} }
        local candidates = Spatial and Spatial.QueryNPCs and Spatial.QueryNPCs(
            player:getX(), player:getY(), Const.INTEREST_LEAVE_DISTANCE
        ) or {}
        local nextIDs = {}
        local i
        local record
        local distance
        state.player = player
        seenPlayers[key] = true
        for i = 1, #candidates do
            record = candidates[i]
            if record and record.id and record.alive ~= false then
                distance = Core.Distance(player:getX(), player:getY(), record.x, record.y)
                if (state.ids[record.id] and distance <= Const.INTEREST_LEAVE_DISTANCE)
                    or distance <= Const.INTEREST_ENTER_DISTANCE
                then
                    nextIDs[record.id] = true
                    if not state.ids[record.id] then
                        sendToPlayer(player, Const.CMD_SYNC_RECORD, {
                            event = "interest_enter",
                            snapshot = Network.BuildSnapshot(record),
                        })
                    end
                end
            end
        end
        for id, _ in pairs(state.ids) do
            if not nextIDs[id] then
                record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
                if record then
                    sendToPlayer(player, Const.CMD_SYNC_RECORD, {
                        event = "interest_exit",
                        snapshot = Network.BuildRosterSnapshot(record),
                    })
                end
            end
        end
        state.ids = nextIDs
        ServerState.interests[key] = state
    end)
    for key, _ in pairs(ServerState.interests) do
        if not seenPlayers[key] then
            ServerState.interests[key] = nil
        end
    end
end

function Network.FlushRosterDeltas(now, force)
    local entries = {}
    local id
    now = tonumber(now) or Core.Now()
    if not force and now - (tonumber(ServerState.lastRosterFlushAt) or 0) < Const.ROSTER_DELTA_INTERVAL_MS then
        return 0
    end
    for id, _ in pairs(ServerState.rosterDeltas) do
        entries[#entries + 1] = ServerState.rosterDeltas[id]
    end
    if #entries <= 0 then
        ServerState.lastRosterFlushAt = now
        return 0
    end
    Core.ForEachPlayer(function(player)
        sendToPlayer(player, Const.CMD_ROSTER_DELTA, {
            directoryRevision = ServerState.rosterRevision,
            entries = entries,
        })
    end)
    ServerState.rosterDeltas = {}
    ServerState.lastRosterFlushAt = now
    return #entries
end

function Network.BroadcastRecord(record, eventName)
    local payload
    local path
    local recipients = {}
    local state
    if not Core.IsAuthority() then
        return
    end
    if eventName ~= "tick" and eventName ~= "materialize" and eventName ~= "interest_enter" then
        Network.QueueRosterDelta(record, false, eventName)
    end
    if isServer and isServer() then
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[record.id] then
                recipients[#recipients + 1] = state.player
            end
        end
        if #recipients <= 0 then
            return
        end
    end
    payload = {
        event = eventName or "update",
        snapshot = eventName == "tick" and Network.BuildPresenceDelta(record) or Network.BuildSnapshot(record),
    }
    path = record and record.runtime and record.runtime.pathing or nil
    if path and MotionHints and MotionHints.MarkBroadcast then
        MotionHints.MarkBroadcast(record, path, Core.Now())
    end
    if isServer and isServer() then
        local i
        for i = 1, #recipients do
            sendToPlayer(recipients[i], Const.CMD_SYNC_RECORD, payload)
        end
        return
    end
    triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_SYNC_RECORD, payload)
end

function Network.BroadcastRemoval(id, reason)
    local payload = { id = id, reason = reason }
    local record
    if not Core.IsAuthority() then
        return
    end
    if tostring(reason or "") == "death" then
        record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
        if record then
            Network.QueueRosterDelta(record, false, reason)
            payload = { event = "death", snapshot = Network.BuildSnapshot(record) }
            if isServer and isServer() then
                local state
                for _, state in pairs(ServerState.interests) do
                    if state.player and state.ids and state.ids[id] then
                        sendToPlayer(state.player, Const.CMD_SYNC_RECORD, payload)
                        state.ids[id] = nil
                    end
                end
            else
                triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_SYNC_RECORD, payload)
            end
            return
        end
    end
    Network.QueueRosterDelta(id, true, reason)
    if isServer and isServer() then
        local state
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[id] then
                sendToPlayer(state.player, Const.CMD_REMOVE_RECORD, payload)
                state.ids[id] = nil
            end
        end
    else
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_REMOVE_RECORD, payload)
    end
end

function Network.BroadcastBodyRemoval(id, bodyInstanceID, bodyOnlineID, reason)
    local payload
    if not Core.IsAuthority() then
        return false
    end
    payload = {
        id = id and tostring(id) or nil,
        bodyInstanceID = bodyInstanceID ~= nil and tostring(bodyInstanceID) or nil,
        bodyOnlineID = tonumber(bodyOnlineID),
        reason = tostring(reason or "stale_body"),
    }
    if isServer and isServer() then
        -- A stale engine zombie can be present on a client before that client
        -- has entered the NPC interest set. Send instance removals to every
        -- connected player instead of relying on roster interest membership.
        Core.ForEachPlayer(function(player)
            sendToPlayer(player, Const.CMD_REMOVE_BODY, payload)
        end)
    else
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_REMOVE_BODY, payload)
    end
    return true
end

function Network.GetZombieOnlineID(zombie)
    local onlineID
    if not zombie or not zombie.getOnlineID then
        return nil
    end
    onlineID = tonumber(zombie:getOnlineID())
    if not onlineID or onlineID < 0 then
        return nil
    end
    return onlineID
end

function Network.FindZombieByOnlineID(onlineID)
    local cell
    local zombieList
    local zombie
    local i
    onlineID = tonumber(onlineID)
    if onlineID == nil or not getCell then
        return nil
    end
    if PNC.WorldCensus and PNC.WorldCensus.FindByOnlineID then
        return PNC.WorldCensus.FindByOnlineID(onlineID, Core.Now())
    end
    cell = getCell()
    if not cell or not cell.getZombieList then
        return nil
    end
    zombieList = cell:getZombieList()
    if not zombieList then
        return nil
    end
    for i = zombieList:size() - 1, 0, -1 do
        zombie = zombieList:get(i)
        if Network.GetZombieOnlineID(zombie) == onlineID then
            return zombie
        end
    end
    return nil
end

function Network.BroadcastZombieReaction(targetZombie, attackerZombie, options)
    local targetOnlineID
    local attackerOnlineID
    local health
    local payload
    local attackerModData
    local npcId
    if not Core.IsAuthority()
        or not isServer
        or not isServer()
        or not sendServerCommand
        or not targetZombie
        or (targetZombie.isDead and targetZombie:isDead())
    then
        return false
    end
    targetOnlineID = Network.GetZombieOnlineID(targetZombie)
    if not targetOnlineID then
        return false
    end
    attackerOnlineID = Network.GetZombieOnlineID(attackerZombie)
    health = targetZombie.getHealth and tonumber(targetZombie:getHealth()) or nil
    options = options or {}
    payload = {
        targetOnlineID = targetOnlineID,
        attackerOnlineID = attackerOnlineID,
        kind = tostring(options.kind or "weapon_hit"),
        hitReaction = options.hitReaction and tostring(options.hitReaction) or nil,
        hitForce = tonumber(options.hitForce) or 0.92,
        stagger = options.stagger ~= false,
        health = health and health > 0 and health or nil,
        partId = options.partId and tostring(options.partId) or nil,
        woundType = options.woundType and tostring(options.woundType) or nil,
    }
    attackerModData = attackerZombie and attackerZombie.getModData and attackerZombie:getModData() or nil
    npcId = attackerModData and attackerModData.PNC_UUID or nil
    return sendToInterestedNPC(npcId, Const.CMD_ZOMBIE_REACTION, payload) > 0
end

function Network.BroadcastZombieBite(attackerZombie, targetNPCBody, npcId, phase, bumpType)
    local attackerOnlineID
    local targetOnlineID
    if not Core.IsAuthority()
        or not isServer
        or not isServer()
        or not sendServerCommand
    then
        return false
    end
    attackerOnlineID = Network.GetZombieOnlineID(attackerZombie)
    if not attackerOnlineID then
        return false
    end
    targetOnlineID = Network.GetZombieOnlineID(targetNPCBody)
    local payload = {
        attackerOnlineID = attackerOnlineID,
        targetOnlineID = targetOnlineID,
        npcId = npcId and tostring(npcId) or nil,
        phase = phase == "clear" and "clear" or "start",
        bumpType = bumpType and tostring(bumpType) or "Bite",
    }
    return sendToInterestedNPC(npcId, Const.CMD_ZOMBIE_BITE, payload) > 0
end

function Network.BroadcastFirearmShot(payload)
    local deliveryRadius
    local sent = 0
    if not Core.IsAuthority() or type(payload) ~= "table" then
        return false
    end
    if isServer and isServer() then
        if not sendServerCommand then return false end
        -- A gunshot can be heard beyond an NPC's normal detailed-interest
        -- bubble. Deliver this transient event by the weapon's own noise
        -- radius, with the interest distance as the minimum visual range.
        deliveryRadius = math.max(
            tonumber(payload.soundRadius) or 0,
            tonumber(Const.INTEREST_LEAVE_DISTANCE) or 56
        )
        Core.ForEachPlayer(function(player)
            local dx
            local dy
            local dz
            if not player then return end
            dx = (tonumber(player:getX()) or 0) - (tonumber(payload.sx) or 0)
            dy = (tonumber(player:getY()) or 0) - (tonumber(payload.sy) or 0)
            dz = math.abs((tonumber(player:getZ()) or 0) - (tonumber(payload.sz) or 0))
            if dz <= 2 and ((dx * dx) + (dy * dy)) <= (deliveryRadius * deliveryRadius) then
                sendToPlayer(player, Const.CMD_FIREARM_SHOT, payload)
                sent = sent + 1
            end
        end)
        return sent > 0
    end
    if triggerEvent then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_FIREARM_SHOT, payload)
        return true
    end
    return false
end

function Network.BroadcastFullSync(targetPlayer, records)
    local chunkSize = math.max(1, tonumber(Const.ROSTER_CHUNK_SIZE) or 50)
    local total = #(records or {})
    local chunkCount = math.ceil(total / chunkSize)
    local chunkIndex
    local startIndex
    local finishIndex
    local chunk
    local i
    sendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_BEGIN, {
        directoryRevision = ServerState.rosterRevision,
        total = total,
        chunkCount = chunkCount,
    })
    for chunkIndex = 1, chunkCount do
        chunk = {}
        startIndex = ((chunkIndex - 1) * chunkSize) + 1
        finishIndex = math.min(total, startIndex + chunkSize - 1)
        for i = startIndex, finishIndex do
            chunk[#chunk + 1] = records[i]
        end
        sendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_CHUNK, {
            directoryRevision = ServerState.rosterRevision,
            chunkIndex = chunkIndex,
            snapshots = chunk,
        })
    end
    sendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_END, {
        directoryRevision = ServerState.rosterRevision,
        total = total,
    })
    if isServer and isServer() and targetPlayer then
        local state = ServerState.interests[playerKey(targetPlayer)]
        if state then
            state.ids = {}
        end
        ServerState.lastInterestRefreshAt = 0
    end
end

function Network.SendCharacterPayload(targetPlayer, record)
    local payload
    if not record then
        return
    end
    payload = Network.BuildCharacterPayload(record)
    if not payload then
        return
    end
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_CHARACTER_PAYLOAD, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_CHARACTER_PAYLOAD, payload)
    end
end

function Network.CanViewCharacter(player, record)
    local access
    local distance
    if not player or not record then
        return false
    end
    access = player.getAccessLevel and string.lower(tostring(player:getAccessLevel() or "")) or ""
    if access == "admin" then
        return true
    end
    if record.ownerUsername and player.getUsername and tostring(record.ownerUsername) == tostring(player:getUsername()) then
        return true
    end
    if math.floor(tonumber(player:getZ()) or 0) ~= math.floor(tonumber(record.z) or 0) then
        return false
    end
    distance = Core.Distance(player:getX(), player:getY(), record.x, record.y)
    return distance <= Const.CHARACTER_DETAIL_DISTANCE
end

function Network.SendInventoryDelta(targetPlayer, record, sinceRevision)
    local delta = Inventory and Inventory.BuildDeltaPayload and Inventory.BuildDeltaPayload(record, sinceRevision) or nil
    if not delta or delta.fullRequired == true then
        Network.SendCharacterPayload(targetPlayer, record)
        return false
    end
    sendToPlayer(targetPlayer, Const.CMD_INVENTORY_DELTA, delta)
    return true
end

function Network.SendDebugRoster(targetPlayer, diagnostics, authorized, audit)
    local payload = {
        authorized = authorized == true,
        diagnostics = diagnostics or {},
        audit = audit or {},
        performance = authorized == true
            and PNC.Performance
            and PNC.Performance.Snapshot
            and PNC.Performance.Snapshot(false)
            or nil,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_DEBUG_ROSTER, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_DEBUG_ROSTER, payload)
    end
end

--[[
    PNC Client Presence Visuals: snapshot record views
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Const = PNC.Const
local Equipment = PNC.Equipment

local function buildRecordView(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    local moving = visualState.moving == true
    local specialActive = visualState.specialActive == true
    return {
        id = snapshot and snapshot.id or nil,
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
        appearance = snapshot and snapshot.appearance or nil,
        equipment = {
            primaryFullType = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.primaryFullType or nil,
            primaryVisual = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.primaryVisual or nil,
            secondaryFullType = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.secondaryFullType or nil,
            worn = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.worn or {},
            wornVisuals = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.wornVisuals or {},
            attached = snapshot and snapshot.equipmentSummary and snapshot.equipmentSummary.attached or {},
        },
        runtime = {
            attackMode = snapshot and snapshot.attackMode == true or false,
            debug = snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true or false,
            localNavigation = {
                provider = visualState.nativeMoveActive == true
                    and "engine_path" or nil,
                nativeActive = visualState.nativeMoveActive == true,
                clientDelegated = visualState.nativeMoveActive == true,
            },
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

local function ensureReplicaClothingSnapshot(snapshot, zombie)
    if not snapshot or not zombie
        or not Equipment
        or not Equipment.EnsureReplicaVisuals
    then
        return false
    end
    return Equipment.EnsureReplicaVisuals(
        zombie,
        buildRecordView(snapshot)
    )
end

Internal.EnsureReplicaClothingSnapshot =
    ensureReplicaClothingSnapshot


Internal.BuildRecordView = buildRecordView


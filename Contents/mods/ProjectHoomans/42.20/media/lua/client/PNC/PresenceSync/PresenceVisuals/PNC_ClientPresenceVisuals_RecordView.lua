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
    local equipmentSummary = snapshot and snapshot.equipmentSummary or {}
    local workPresentation = snapshot and snapshot.workPresentation
        or equipmentSummary.workPresentation
    local primaryFullType = equipmentSummary.primaryFullType
        or workPresentation and workPresentation.fullType
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
            primaryFullType = primaryFullType,
            primaryVisual = equipmentSummary.primaryVisual,
            secondaryFullType = equipmentSummary.secondaryFullType,
            worn = equipmentSummary.worn or {},
            wornVisuals = equipmentSummary.wornVisuals or {},
            attached = equipmentSummary.attached or {},
            workPresentation = workPresentation,
        },
        runtime = {
            attackMode = snapshot and snapshot.attackMode == true or false,
            -- Fighting mode mirrored from the authority.  Equipment presentation
            -- reads this so a body that is fighting holds its weapon in hand
            -- even on a frame with no attack action in flight.
            combatStance = snapshot and snapshot.combatStance == true or false,
            workPresentation = workPresentation,
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

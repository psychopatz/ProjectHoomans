--[[
    PNC Client Presence Visuals
    Applies identity, appearance, equipment, treatment audio, and animation.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const
local Animation = PNC.Animation
local Visuals = PNC.Visuals
local Equipment = PNC.Equipment
local LiveBodyControl = PNC.LiveBodyControl
local AnimationTrace = PNC.AnimationTrace
local logClientMotionDebug = Internal.LogClientMotionDebug
local LOCOMOTION_MAINTAIN_MS = 500
local ATTACK_BUMP_REARM_MS = 100
local ATTACK_BUMP_MAX_REARMS = 1

local function getActionStateName(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(
            zombie:getActionStateName() or ""
        ))
    end
    return ""
end

local function getBumpType(zombie)
    if zombie and zombie.getBumpType then
        return tostring(zombie:getBumpType() or "")
    end
    return ""
end

local function beginClientAttackBump(
    snapshot,
    zombie,
    recordView,
    modData,
    attackKey,
    anim,
    now
)
    if Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, recordView, anim)
    end
    if modData then
        modData.PNC_ClientAttackKey = attackKey
        modData.PNC_ClientAttackLocalStartedAt = now
        modData.PNC_ClientAttackRetries = 0
        modData.PNC_ClientAttackRequestedAnim =
            tostring(anim or "")
        modData.PNC_ClientAttackResolvedAnim =
            Animation and Animation.ResolveBumpType
                and Animation.ResolveBumpType(anim)
                or tostring(anim or "")
        modData.PNC_ClientAttackActionState =
            getActionStateName(zombie)
        modData.PNC_ClientAttackBumpType =
            getBumpType(zombie)
    end
    logClientMotionDebug(
        snapshot,
        snapshot and snapshot.id or nil,
        "attack_anim_start",
        "anim=" .. tostring(anim)
            .. " bump=" .. getBumpType(zombie)
            .. " action=" .. getActionStateName(zombie)
    )
end

local function observeClientAttackBump(zombie, modData)
    if not modData then return end
    modData.PNC_ClientAttackActionState =
        getActionStateName(zombie)
    modData.PNC_ClientAttackBumpType =
        getBumpType(zombie)
end

local function rearmDroppedClientAttackBump(
    snapshot,
    zombie,
    recordView,
    modData,
    attackKey,
    anim,
    now
)
    local startedAt
    local retries
    local actionState
    if not zombie or not modData or not attackKey then return false end
    startedAt = tonumber(modData.PNC_ClientAttackLocalStartedAt) or now
    retries = tonumber(modData.PNC_ClientAttackRetries) or 0
    actionState = getActionStateName(zombie)
    if actionState == "bumped"
        or now - startedAt < ATTACK_BUMP_REARM_MS
        or retries >= ATTACK_BUMP_MAX_REARMS
    then
        return false
    end
    -- PathFindState can consume the first BumpType change while it exits,
    -- leaving the requested selector installed but the ActionContext idle.
    -- Toggle the selector once to create a fresh edge after path ownership has
    -- been released. Never do this after BumpedState has actually started.
    if zombie.setBumpType then zombie:setBumpType("") end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, recordView, anim, {
            leaseUntil = snapshot
                and snapshot.visualState
                and snapshot.visualState.attackFinishAt
                or nil,
        })
    end
    modData.PNC_ClientAttackRetries = retries + 1
    observeClientAttackBump(zombie, modData)
    logClientMotionDebug(
        snapshot,
        snapshot and snapshot.id or nil,
        "attack_anim_rearm",
        "anim=" .. tostring(anim)
            .. " bump=" .. getBumpType(zombie)
            .. " action=" .. getActionStateName(zombie)
    )
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "client_attack_rearm", now, true)
    end
    return true
end

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

local function stableValueSignature(value, seen)
    local valueType = type(value)
    local entries
    local key
    local entry
    local i
    if valueType ~= "table" then
        return valueType .. ":" .. tostring(value)
    end
    if seen[value] then
        return "table:<cycle>"
    end
    seen[value] = true
    entries = {}
    for key, _ in pairs(value) do
        entries[#entries + 1] = {
            key = key,
            keySignature = type(key) .. ":" .. tostring(key),
        }
    end
    table.sort(entries, function(left, right)
        return left.keySignature < right.keySignature
    end)
    for i = 1, #entries do
        entry = entries[i]
        entries[i] = entry.keySignature
            .. "="
            .. stableValueSignature(value[entry.key], seen)
    end
    seen[value] = nil
    return "table:{" .. table.concat(entries, ";") .. "}"
end

local function stableTableSignature(tbl)
    if type(tbl) ~= "table" then
        return ""
    end
    return stableValueSignature(tbl, {})
end

local function buildVisualKey(snapshot)
    local appearance = snapshot and snapshot.appearance or {}
    local equipment = snapshot and snapshot.equipmentSummary or {}
    return table.concat({
        tostring(snapshot and snapshot.liveBodyInstanceID or ""),
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(snapshot and snapshot.liveBodyOnlineID or ""),
        tostring(snapshot and snapshot.visualProfile or ""),
        tostring(snapshot and snapshot.isFemale == true),
        tostring(appearance.outfit or ""),
        tostring(appearance.skinTexture or ""),
        tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""),
        stableTableSignature(equipment.worn),
        stableTableSignature(equipment.wornVisuals),
        stableTableSignature(equipment.attached),
    }, "|")
end

local function buildHandsKey(snapshot)
    local equipment = snapshot and snapshot.equipmentSummary or {}
    return table.concat({
        tostring(snapshot and snapshot.liveBodyInstanceID or ""),
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(snapshot and snapshot.liveBodyOnlineID or ""),
        tostring(snapshot and snapshot.attackMode == true),
        tostring(equipment.primaryFullType or ""),
        stableTableSignature(equipment.primaryVisual),
        tostring(equipment.secondaryFullType or ""),
    }, "|")
end

Sync.Internal.BuildVisualKey = buildVisualKey
Sync.Internal.BuildHandsKey = buildHandsKey

local function buildMotionKey(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    local treatment = snapshot and snapshot.treatmentState or {}
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
        tostring(visualState.nativeMoveActive == true),
        tostring(visualState.nativeMoveRevision or 0),
        tostring(treatment.phase or "idle"),
        tostring(treatment.partId or ""),
        tostring(treatment.startedAt or 0),
        tostring(treatment.finishAt or 0),
        tostring(visualState.sceneActive == true),
        tostring(visualState.sceneId or ""),
        tostring(visualState.sceneBump or ""),
        tostring(visualState.sceneRevision or 0),
        tostring(visualState.scenePlaybackRevision or 0),
        tostring(visualState.sceneFinishAt or 0),
        tostring(visualState.sceneNextStepAt or 0),
        tostring(visualState.sceneLoop == true),
        tostring(visualState.sceneRepeatMode or "once"),
    }, "|")
end

local function syncTreatmentSound(zombie, snapshot, modData)
    local treatment = snapshot and snapshot.treatmentState or nil
    local phase = tostring(treatment and treatment.phase or "idle")
    local completion = snapshot and snapshot.bandageFeedback or nil
    local completionKey
    local soundKey
    local emitter
    local soundManager
    if not modData then return end
    if completion then
        completionKey = tostring(completion.revision or "")
            .. ":" .. tostring(completion.completedAt or 0)
            .. ":" .. tostring(completion.partId or "")
        if modData.PNC_ClientBandageCompletionKey ~= completionKey then
            emitter = zombie and zombie.getEmitter
                and zombie:getEmitter() or nil
            soundManager = getSoundManager and getSoundManager() or nil
            if emitter and emitter.playSound then
                emitter:playSound(tostring(
                    completion.sound or "PNC_BandageComplete"
                ))
                modData.PNC_ClientBandageCompletionKey = completionKey
            elseif zombie and zombie.playSound then
                zombie:playSound(tostring(
                    completion.sound or "PNC_BandageComplete"
                ))
                modData.PNC_ClientBandageCompletionKey = completionKey
            elseif zombie and zombie.getSquare and zombie:getSquare()
                and soundManager and soundManager.PlayWorldSound
            then
                soundManager:PlayWorldSound(
                    tostring(completion.sound or "PNC_BandageComplete"),
                    zombie:getSquare(),
                    0,
                    8,
                    1.0,
                    false
                )
                modData.PNC_ClientBandageCompletionKey = completionKey
            end
        end
    end
    if phase ~= "bandaging" then
        modData.PNC_ClientTreatmentSoundKey = nil
        return
    end
    soundKey = tostring(treatment.partId or "")
        .. ":" .. tostring(treatment.startedAt or 0)
    if modData.PNC_ClientTreatmentSoundKey == soundKey then return end
    emitter = emitter
        or zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        modData.PNC_ClientTreatmentSoundKey = soundKey
    end
end

local function getTreatmentPresentation(snapshot)
    local treatment = snapshot and snapshot.treatmentState or nil
    local phase = tostring(treatment and treatment.phase or "idle")
    local partId
    local key
    local anim
    if phase ~= "bandaging" then
        return nil
    end
    partId = tostring(treatment.partId or "")
    key = partId .. ":" .. tostring(treatment.startedAt or 0)
    anim = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.ResolveBandageAnimation
        and PNC.BehaviorTreatment.ResolveBandageAnimation(partId)
        or "BandageUpperBody"
    return {
        key = key,
        anim = anim,
        finishAt = tonumber(treatment.finishAt) or 0,
    }
end

local function syncTreatmentAnimation(
    zombie,
    recordView,
    modData,
    presentation
)
    if not modData then
        return presentation ~= nil, false
    end
    if not presentation then
        if modData.PNC_ClientTreatmentAnimKey == nil then
            return false, false
        end
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientTreatmentAnimKey = nil
        return false, true
    end
    if modData.PNC_ClientTreatmentAnimKey ~= presentation.key then
        if Animation and Animation.PlayBump then
            Animation.PlayBump(
                zombie,
                recordView,
                presentation.anim,
                {
                    leaseUntil = presentation.finishAt,
                }
            )
        end
        modData.PNC_ClientTreatmentAnimKey = presentation.key
    elseif Animation and Animation.MaintainBump then
        Animation.MaintainBump(
            zombie,
            recordView,
            presentation.anim,
            presentation.finishAt
        )
    end
    return true, false
end

local function getScenePresentation(snapshot, now)
    local visualState = snapshot and snapshot.visualState or {}
    local finishAt
    local leaseUntil
    if visualState.sceneActive ~= true
        or tostring(visualState.sceneId or "") == ""
        or tostring(visualState.sceneBump or "") == ""
    then
        return nil
    end
    finishAt = tonumber(visualState.sceneFinishAt) or 0
    leaseUntil = finishAt
    if visualState.sceneLoop == true and finishAt <= 0 then
        leaseUntil = now + 10000
    end
    return {
        key = tostring(visualState.sceneId)
            .. ":" .. tostring(
                visualState.sceneRevision or 0
            )
            .. ":" .. tostring(
                visualState.scenePlaybackRevision or 0
            ),
        id = tostring(visualState.sceneId),
        bump = tostring(visualState.sceneBump),
        loop = visualState.sceneLoop == true,
        finishAt = finishAt,
        leaseUntil = leaseUntil,
    }
end

local function syncAnimationScene(
    zombie,
    recordView,
    modData,
    presentation
)
    if not modData then
        return presentation ~= nil, false
    end
    if not presentation then
        if modData.PNC_ClientAnimationSceneKey == nil then
            return false, false
        end
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientAnimationSceneKey = nil
        return false, true
    end
    if modData.PNC_ClientAnimationSceneKey
        ~= presentation.key
    then
        if Animation and Animation.PlayBump then
            Animation.PlayBump(
                zombie,
                recordView,
                presentation.bump,
                {
                    sceneId = presentation.id,
                    leaseUntil = presentation.leaseUntil,
                }
            )
        end
        modData.PNC_ClientAnimationSceneKey =
            presentation.key
    elseif presentation.loop
        and Animation
        and Animation.MaintainBump
    then
        Animation.MaintainBump(
            zombie,
            recordView,
            presentation.bump,
            presentation.leaseUntil,
            {
                sceneId = presentation.id,
            }
        )
    end
    return true, false
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

local function applySnapshotToBody(snapshot, zombie, remoteReplica)
    local visualState = snapshot and snapshot.visualState or {}
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local attackKey
    local specialKey
    local desiredAnim
    local recordView
    local visualKey
    local handsKey
    local motionKey
    local motionChanged
    local engineMovementActive
    local bumpReleaseActive
    local treatmentPresentation
    local treatmentActive
    local treatmentReleased
    local scenePresentation
    local sceneActive
    local sceneReleased
    local now
    if not snapshot or not zombie or (zombie.isDead and zombie:isDead()) then
        return
    end
    -- Preserve the legacy exported-helper contract for tests/extensions.
    -- Production callers always pass the authority decision explicitly.
    if remoteReplica == nil then
        remoteReplica = true
    end

    now = Core and Core.Now and Core.Now() or 0
    treatmentPresentation = getTreatmentPresentation(snapshot)
    treatmentActive = treatmentPresentation ~= nil
    scenePresentation = getScenePresentation(snapshot, now)
    sceneActive = scenePresentation ~= nil
    -- The animation player is an explicitly selected, client-local debug
    -- owner. While it is active, snapshots may keep identity current but must
    -- not rewrite animation variables or replay locomotion over the requested
    -- XML node. Stop/close restores normal snapshot ownership immediately.
    if PNC.AnimationDebugPlayer
        and PNC.AnimationDebugPlayer.IsPreviewing
        and PNC.AnimationDebugPlayer.IsPreviewing(zombie)
    then
        applyIdentityVars(zombie, snapshot)
        if modData and snapshot.id ~= nil then
            modData.PNC_UUID = tostring(snapshot.id)
            modData.PNC_NPC = true
        end
        PNC.AnimationDebugPlayer.Maintain(zombie, now)
        return
    end
    attackKey = not (
            remoteReplica
            and visualState.nativeTraversalActive == true
        )
        and visualState.attackActive
        and visualState.attackAnim
        and (
            tostring(visualState.attackAnim)
                .. ":"
                .. tostring(
                    visualState.attackFinishAt or 0
                )
        )
        or nil
    if attackKey
        and modData
        and modData.PNC_ClientAttackKey ~= attackKey
        and AnimationTrace
        and AnimationTrace.Begin
    then
        AnimationTrace.Begin(zombie, {
            npcId = snapshot.id,
            attackKey = attackKey,
            requested = visualState.attackAnim,
            resolved = Animation
                and Animation.ResolveBumpType
                and Animation.ResolveBumpType(
                    visualState.attackAnim
                )
                or visualState.attackAnim,
            debugEnabled = snapshot.debugState
                and snapshot.debugState.debugEnabled == true
                or snapshot.combatDebugState ~= nil
                or false,
        }, now)
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(
            zombie,
            "client_pre_maintain",
            now
        )
    end
    engineMovementActive = remoteReplica
        and (
            visualState.nativeMoveActive == true
            or visualState.nativeTraversalActive == true
            or visualState.attackActive == true
            or treatmentActive
            or sceneActive
            or modData and modData.PNC_BumpActionLease == true
            or modData and modData.PNC_BumpReleasePending == true
        )
    if LiveBodyControl and LiveBodyControl.MaintainHumanizedBody then
        -- Native path/traversal and bumped action leases need Java-side action
        -- updates. The attack remains gameplay-scripted; this lease only lets
        -- the selected arm/weapon clip advance on the local client body.
        LiveBodyControl.MaintainHumanizedBody(
            zombie,
            now,
            engineMovementActive
        )
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(
            zombie,
            "client_post_maintain",
            now
        )
    end
    if (
        remoteReplica
        or (
            modData
            and (
                modData.PNC_ClientAttackKey ~= nil
                or modData.PNC_BumpReleasePending == true
            )
        )
    )
        and Animation and Animation.PumpBumpRelease
    then
        bumpReleaseActive =
            Animation.PumpBumpRelease(zombie, now)
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(
            zombie,
            "client_post_release_pump",
            now
        )
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
        modData.PNC_PersistedShell = true
        modData.PNC_ShellVersion = Const.BODY_SHELL_VERSION
        modData.PNC_BaseOutfit = "Naked"
    end
    if PNC.ClientHumanNPCSafeguards
        and PNC.ClientHumanNPCSafeguards.RegisterHumanBody
    then
        PNC.ClientHumanNPCSafeguards.RegisterHumanBody(zombie)
    end
    syncTreatmentSound(zombie, snapshot, modData)
    if PNC.CompanionCommandPresentation
        and PNC.CompanionCommandPresentation.SyncAcknowledgement
    then
        PNC.CompanionCommandPresentation.SyncAcknowledgement(
            zombie,
            snapshot,
            modData
        )
    end

    visualKey = buildVisualKey(snapshot)
    handsKey = buildHandsKey(snapshot)
    if modData and modData.PNC_ClientVisualKey ~= visualKey then
        if not remoteReplica
            and Animation
            and Animation.ApplyLiveSetup
        then
            Animation.ApplyLiveSetup(zombie, recordView)
        end
        if remoteReplica
            and Visuals
            and Visuals.ApplyReplicaAppearance
        then
            Visuals.ApplyReplicaAppearance(
                zombie,
                snapshot.appearance or {},
                snapshot.isFemale == true
            )
        elseif Visuals and Visuals.ApplyResolvedAppearance then
            Visuals.ApplyResolvedAppearance(zombie, snapshot.appearance or {}, snapshot.isFemale == true)
        end
        if remoteReplica
            and Equipment
            and Equipment.ApplyReplicaVisuals
        then
            Equipment.ApplyReplicaVisuals(
                zombie,
                recordView
            )
        elseif Equipment and Equipment.Apply then
            Equipment.Apply(zombie, recordView)
        end
        modData.PNC_ClientVisualKey = visualKey
        modData.PNC_ClientHandsKey = handsKey
    elseif modData and modData.PNC_ClientHandsKey ~= handsKey then
        if remoteReplica
            and Equipment
            and Equipment.ApplyReplicaHands
        then
            Equipment.ApplyReplicaHands(zombie, recordView)
        elseif Equipment and Equipment.ApplyHands then
            Equipment.ApplyHands(zombie, recordView)
        elseif Equipment and Equipment.Apply then
            Equipment.Apply(zombie, recordView)
        end
        modData.PNC_ClientHandsKey = handsKey
    end
    if not remoteReplica
        and snapshot.attackMode == true
        and Equipment
        and Equipment.EnsureCombatHands
    then
        -- Engine action-state transitions may discard IsoZombie hand models.
        -- This is a read-mostly repair and never rebuilds worn clothing.
        Equipment.EnsureCombatHands(zombie, recordView)
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(
            zombie,
            "client_post_equipment",
            now
        )
    end

    motionKey = buildMotionKey(snapshot)

    if snapshot.healthState == "incapacitated" then
        -- Downed-state repair is idempotent and also clears late vanilla
        -- stagger/hit-reaction latches on the authoritative body.
        if Animation and Animation.ApplyDowned then
            Animation.ApplyDowned(zombie, recordView, visualState.moving == true and visualState.isCrawling == true and recordView.runtime.pathing.motionProfile or false)
        end
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientWasDowned = true
        end
        return
    elseif modData
        and modData.PNC_ClientWasDowned == true
        and Animation
        and Animation.ClearDowned
    then
        -- ClearDowned writes the generic movement variables, so it is only a
        -- transition repair. Running it for every healthy snapshot competes
        -- with PathFindBehavior2 and forces WalkTowardState over path2.
        Animation.ClearDowned(zombie)
        modData.PNC_ClientWasDowned = nil
    end

    -- Combat presentation is client-owned in every topology. The server
    -- chooses the clip and hit timing; SP and MP clients both render the
    -- resulting attack snapshot. remoteReplica only gates replicated
    -- locomotion, facing, and traversal presentation.
    if attackKey and modData and modData.PNC_ClientAttackKey ~= attackKey then
        modData.PNC_ClientTreatmentAnimKey = nil
        modData.PNC_ClientAnimationSceneKey = nil
        beginClientAttackBump(
            snapshot,
            zombie,
            recordView,
            modData,
            attackKey,
            visualState.attackAnim,
            now
        )
        modData.PNC_ClientMotionKey = motionKey
        return
    end
    if modData and not attackKey and modData.PNC_ClientAttackKey ~= nil then
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientAttackKey = nil
        modData.PNC_ClientAttackLocalStartedAt = nil
        modData.PNC_ClientAttackRetries = nil
        modData.PNC_ClientAttackRequestedAnim = nil
        modData.PNC_ClientAttackResolvedAnim = nil
        return
    end
    if attackKey then
        rearmDroppedClientAttackBump(
            snapshot,
            zombie,
            recordView,
            modData,
            attackKey,
            visualState.attackAnim,
            now
        )
        observeClientAttackBump(zombie, modData)
        if AnimationTrace and AnimationTrace.Sample then
            AnimationTrace.Sample(
                zombie,
                "client_attack_observe",
                now
            )
        end
        return
    end
    if bumpReleaseActive then
        -- A newer movement snapshot can arrive before BumpedState consumes
        -- BumpAnimFinished. Do not let traversal, native locomotion, or fake
        -- locomotion presentation overwrite that final action-graph frame.
        if modData then
            modData.PNC_ClientMotionKey = motionKey
        end
        return
    end

    if treatmentPresentation and modData then
        modData.PNC_ClientAnimationSceneKey = nil
    end
    treatmentActive, treatmentReleased =
        syncTreatmentAnimation(
            zombie,
            recordView,
            modData,
            treatmentPresentation
        )
    if treatmentActive or treatmentReleased then
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return
    end

    sceneActive, sceneReleased =
        syncAnimationScene(
            zombie,
            recordView,
            modData,
            scenePresentation
        )
    if sceneActive or sceneReleased then
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return
    end

    if remoteReplica
        and visualState.nativeTraversalActive == true
    then
        -- Fence/window traversal is already carried by the engine zombie
        -- packet and its native action state.  Replaying a PNC locomotion or
        -- scripted bump here would create a second animation owner.
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return
    end

    specialKey = visualState.specialActive and visualState.specialAnim
        and (tostring(visualState.specialAnim) .. ":" .. tostring(visualState.specialFinishAt or 0))
        or nil
    if specialKey and modData and modData.PNC_ClientSpecialKey ~= specialKey then
        if remoteReplica and Animation and Animation.PlayBump then
            Animation.PlayBump(zombie, recordView, visualState.specialAnim)
        end
        modData.PNC_ClientSpecialKey = specialKey
        modData.PNC_ClientMotionKey = motionKey
        return
    end
    if modData and not specialKey and modData.PNC_ClientSpecialKey ~= nil then
        if remoteReplica and Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientSpecialKey = nil
        return
    end
    if specialKey then
        return
    end

    if remoteReplica
        and visualState.nativeMoveActive == true
    then
        -- The nearest client submits the PathFindState request. Only its
        -- walk/run presentation style is ours; movement and action-state
        -- variables remain exclusively engine-owned.
        if Animation and Animation.SyncNativeLocomotionStyle then
            Animation.SyncNativeLocomotionStyle(zombie, recordView)
        end
        if modData then
            modData.PNC_ClientMotionKey = motionKey
            modData.PNC_ClientLocomotionMaintainAt = nil
        end
        return
    end

    desiredAnim = visualState.anim or "Idle"
    motionChanged = not modData
        or modData.PNC_ClientMotionKey ~= motionKey
    if remoteReplica and Animation and Animation.Apply
        and motionChanged
    then
        Animation.Apply(zombie, recordView, desiredAnim, recordView.runtime.pathing.motionProfile, visualState.moving == true)
        if modData then
            modData.PNC_ClientMotionKey = motionKey
        end
    end
    if remoteReplica and visualState.moving == true
        and Animation and Animation.SyncLocomotion
        and (
            motionChanged
            or not modData
            or now >= (
                tonumber(modData.PNC_ClientLocomotionMaintainAt)
                    or 0
            )
        )
    then
        Animation.SyncLocomotion(zombie, recordView)
        if modData then
            modData.PNC_ClientLocomotionMaintainAt =
                now + LOCOMOTION_MAINTAIN_MS
        end
        logClientMotionDebug(snapshot, snapshot and snapshot.id or nil, "locomotion_resync", "mode=" .. tostring(visualState.mode or "walk") .. " walkType=" .. tostring(visualState.walkType or ""))
    elseif modData and visualState.moving ~= true then
        modData.PNC_ClientLocomotionMaintainAt = nil
    end
end

Internal.ApplySnapshotToBody = applySnapshotToBody

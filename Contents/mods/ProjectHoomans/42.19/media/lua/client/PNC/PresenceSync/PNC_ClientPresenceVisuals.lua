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
local logClientMotionDebug = Internal.LogClientMotionDebug

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
            attackMode = snapshot and snapshot.attackMode == true or false,
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
        tostring(equipment.secondaryFullType or ""),
    }, "|")
end

Sync.Internal.BuildVisualKey = buildVisualKey
Sync.Internal.BuildHandsKey = buildHandsKey

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
    if LiveBodyControl and LiveBodyControl.MaintainHumanizedBody then
        LiveBodyControl.MaintainHumanizedBody(zombie, now)
    end
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
    if snapshot.attackMode == true
        and Equipment
        and Equipment.EnsureCombatHands
    then
        -- Engine action-state transitions may discard IsoZombie hand models.
        -- This is a read-mostly repair and never rebuilds worn clothing.
        Equipment.EnsureCombatHands(zombie, recordView)
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

Internal.ApplySnapshotToBody = applySnapshotToBody

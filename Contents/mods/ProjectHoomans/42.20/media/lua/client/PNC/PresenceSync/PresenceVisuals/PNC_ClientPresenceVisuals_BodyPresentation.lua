--[[
    PNC Client Presence Visuals: identity, appearance, and equipment application
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Const = PNC.Const
local Animation = PNC.Animation
local Visuals = PNC.Visuals
local Equipment = PNC.Equipment
local AnimationTrace = PNC.AnimationTrace
local NPCVoice = PNC.NPCVoice
local buildVisualKey = Internal.BuildVisualKey
local buildHandsKey = Internal.BuildHandsKey
local syncTreatmentSound = Internal.SyncTreatmentSound

local function resolveDrinkSound(snapshot)
    local action = snapshot and snapshot.actionInformation or nil
    local visual = snapshot and snapshot.visualState or nil
    local capability = tostring(action and action.capability or "")
    local resourceKind = tostring(action and action.resourceKind or "")
    local fullType = string.lower(tostring(
        action and action.activityItemFullType or ""))
    local waterFill = capability == "survival.fill.water"
        or resourceKind == "water_refill"
    local inventoryDrink = capability == "survival.drink.inventory"
        or resourceKind == "personal_drink"
    local worldDrink = capability == "survival.drink.world"
        or resourceKind == "world_water"
    if not visual or visual.sceneActive ~= true then
        return nil
    end
    if waterFill then
        if tostring(visual.sceneStepId or "") ~= "fill" then
            return nil
        end
        return "GetWaterFromTap"
    end
    if tostring(visual.sceneStepId or "") ~= "drink"
        or not (inventoryDrink or worldDrink)
    then return nil end
    if string.find(fullType, "bottleglass", 1, true)
        or string.find(fullType, "glass", 1, true)
    then return "DrinkingFromBottleGlass" end
    if string.find(fullType, "bottle", 1, true) then
        return "DrinkingFromBottlePlastic"
    end
    if string.find(fullType, "can", 1, true) then
        return "DrinkingFromCan"
    end
    if string.find(fullType, "carton", 1, true) then
        return "DrinkingFromCarton"
    end
    if string.find(fullType, "mug", 1, true) then
        return "DrinkingFromMug"
    end
    if inventoryDrink then return "DrinkingFromGeneric" end
    if resourceKind == "faucet" or fullType == "" then
        return "DrinkingFromTap"
    end
    return "DrinkingFromRiver"
end

local function syncDrinkSound(zombie, snapshot, modData)
    local visual = snapshot and snapshot.visualState or nil
    local sound = resolveDrinkSound(snapshot)
    local key
    local emitter
    local handle
    local stopped
    if not modData then return end
    local function stopCurrentDrinkSound()
        local currentHandle = modData.PNC_ClientDrinkSoundHandle
        local currentSound = modData.PNC_ClientDrinkSoundName
        local currentEmitter = zombie and zombie.getEmitter
            and zombie:getEmitter() or nil
        local ok
        if currentEmitter and currentHandle
            and currentEmitter.stopSoundLocal
        then
            ok = pcall(currentEmitter.stopSoundLocal, currentEmitter,
                currentHandle)
            stopped = ok == true
        end
        if not stopped and currentEmitter and currentSound
            and currentEmitter.stopSoundByName
        then
            pcall(currentEmitter.stopSoundByName, currentEmitter, currentSound)
        end
        if not stopped and zombie and currentHandle
            and zombie.stopOrTriggerSound
        then
            pcall(zombie.stopOrTriggerSound, zombie, currentHandle)
        end
        modData.PNC_ClientDrinkSoundHandle = nil
        modData.PNC_ClientDrinkSoundName = nil
        modData.PNC_ClientDrinkSoundKey = nil
    end
    if not sound then
        stopCurrentDrinkSound()
        return
    end
    key = tostring(visual.sceneId or "") .. ":"
        .. tostring(visual.sceneRevision or 0) .. ":"
        .. tostring(visual.scenePlaybackRevision or 0) .. ":"
        .. tostring(visual.sceneStepStartedAt or 0)
    if modData.PNC_ClientDrinkSoundKey == key then return end
    if modData.PNC_ClientDrinkSoundKey ~= nil then
        stopCurrentDrinkSound()
    end
    emitter = zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        local ok
        ok, handle = pcall(emitter.playSound, emitter, sound)
        if not ok then handle = nil end
        modData.PNC_ClientDrinkSoundKey = key
        modData.PNC_ClientDrinkSoundHandle = handle
        modData.PNC_ClientDrinkSoundName = sound
    elseif zombie and zombie.playSound then
        local ok
        ok, handle = pcall(zombie.playSound, zombie, sound)
        if not ok then handle = nil end
        modData.PNC_ClientDrinkSoundKey = key
        modData.PNC_ClientDrinkSoundHandle = handle
        modData.PNC_ClientDrinkSoundName = sound
    end
end

local function resolveActivityHands(snapshot)
    local action = snapshot and snapshot.actionInformation or nil
    local visual = snapshot and snapshot.visualState or nil
    local capability = tostring(action and action.capability or "")
    local actionKind = tostring(action and action.kind or "")
    local operation = tostring(action and action.operation or "")
    local treatmentPhase = tostring(action and action.phase or "")
    local medical = snapshot and snapshot.medicalCareState or nil
    local medicalPhase = tostring(medical and medical.phase or "")
    local sceneId = tostring(visual and visual.sceneId or "")
    local fullType = tostring(action and action.activityItemFullType or "")
    local medicalType = tostring(medical and medical.bandageType or "")
    if snapshot and snapshot.attackMode == true
        or visual and visual.attackActive == true
    then
        return nil
    end
    if (capability == "food.dine"
        or capability == "survival.eat.inventory")
        and sceneId == "survival.eat.inventory"
    then
        return {
            source = "food",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if capability == "survival.drink.inventory"
        and sceneId == "survival.drink.inventory"
    then
        return {
            source = "hydration",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if capability == "survival.drink.world"
        and sceneId == "survival.drink.world"
    then
        return {
            source = "world_water",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if actionKind == "treatment" and treatmentPhase == "bandaging" then
        local treatment = snapshot and snapshot.treatmentState or nil
        if fullType == "" then return nil end
        return {
            source = "self_treatment",
            activityItemFullType = fullType,
            hand = "primary",
            revision = treatment and treatment.startedAt or nil,
        }
    end
    if medicalPhase == "treating" and medicalType ~= "" then
        return {
            source = "medical_care",
            activityItemFullType = medicalType,
            hand = "primary",
            revision = medical and medical.startedAt or nil,
        }
    end
    if operation == "CRAFT"
        and sceneId == "production.craft"
        and fullType ~= ""
    then
        return {
            source = "crafting",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if operation == "DISASSEMBLE"
        and sceneId == "production.disassemble"
        and fullType ~= ""
    then
        return {
            source = "disassembly",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if capability == "farm.work"
        and sceneId == "facility.farm.work"
        and fullType ~= ""
    then
        return {
            source = "farming",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if (tostring(action and action.job or "") == "Fishing"
        or tostring(action and action.orderKind or "") == "fishing")
        and sceneId == "fishing.cast"
        and fullType ~= ""
    then
        return {
            source = "fishing",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if (tostring(action and action.job or "") == "Scavenge"
        or tostring(action and action.orderKind or "") == "scavenge")
        and (sceneId == "scavenge.loot"
            or sceneId == "scavenge.loot_high"
            or sceneId == "scavenge.loot_low")
        and fullType ~= ""
    then
        return {
            source = "scavenging",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if (operation == "CONSTRUCT"
        or operation == "RECONSTRUCT"
        or operation == "DECONSTRUCT"
        or operation == "BUILD_OBJECT")
        and sceneId == "production.construct"
        and fullType ~= ""
    then
        return {
            source = "construction",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if operation == "LUMBER"
        and sceneId == "lumber.chop"
        and fullType ~= ""
    then
        return {
            source = "lumber",
            activityItemFullType = fullType,
            hand = "primary",
            sceneId = sceneId,
            stepId = visual and visual.sceneStepId or nil,
            revision = visual and visual.sceneStartedAt or nil,
        }
    end
    if fullType == "" then return nil end
    return nil
end

local function applyIdentityVars(zombie, snapshot)
    local isFemale
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable("PNCActor", true)
    zombie:setVariable("PNCLive", snapshot and snapshot.presenceState == Const.PRESENCE_LIVE)
    isFemale = snapshot and snapshot.isFemale == true
    if zombie.setFemaleEtc then
        -- IsoZombie:setFemaleEtc also rewrites the descriptor voice prefix to
        -- MaleZombie/FemaleZombie.  Repeating that write for every snapshot
        -- re-enables native zombie vocals after LiveBodyControl has silenced
        -- the carrier.  Only touch the engine gender when it actually differs.
        if not zombie.isFemale or zombie:isFemale() ~= isFemale then
            zombie:setFemaleEtc(isFemale)
        end
    end
end


local function applyBodyPresentation(
    snapshot,
    zombie,
    remoteReplica,
    recordView,
    modData,
    now
)
    local visualKey
    local handsKey
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
    syncDrinkSound(zombie, snapshot, modData)
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
            Visuals.ApplyResolvedAppearance(
                zombie,
                snapshot.appearance or {},
                snapshot.isFemale == true
            )
        end
        if remoteReplica
            and Equipment
            and Equipment.ApplyReplicaVisuals
        then
            Equipment.ApplyReplicaVisuals(zombie, recordView)
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
        Equipment.EnsureCombatHands(zombie, recordView)
    end
    if Equipment and Equipment.ApplyActivityHands then
        Equipment.ApplyActivityHands(zombie, resolveActivityHands(snapshot))
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "client_post_equipment", now)
    end
    if NPCVoice and NPCVoice.Bind then
        NPCVoice.Bind(snapshot, zombie)
    end
end

Internal.ApplyIdentityVars = applyIdentityVars
Internal.ApplyBodyPresentation = applyBodyPresentation
Internal.ResolveActivityHands = resolveActivityHands
Internal.ResolveDrinkSound = resolveDrinkSound
Internal.SyncDrinkSound = syncDrinkSound

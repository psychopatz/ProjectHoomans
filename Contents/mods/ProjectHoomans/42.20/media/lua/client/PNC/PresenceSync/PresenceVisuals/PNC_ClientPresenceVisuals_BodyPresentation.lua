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
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "client_post_equipment", now)
    end
    if NPCVoice and NPCVoice.Bind then
        NPCVoice.Bind(snapshot, zombie)
    end
end

Internal.ApplyIdentityVars = applyIdentityVars
Internal.ApplyBodyPresentation = applyBodyPresentation

local Network = PNC.Network
local H = Network.Internal.DetailedPayload
if not H then return Network end

local Core = H.Core
local Skills = H.Skills
local Settings = H.Settings
if not H.BuildSnapshotState then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_State"
end
if not H.BuildIdentityProjection then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_Identity"
end
if not H.BuildPresentationProjection then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_PresentationProjection"
end
local buildSnapshotState = H.BuildSnapshotState
local buildIdentityProjection = H.BuildIdentityProjection
local buildPresentationProjection = H.BuildPresentationProjection
local buildCommandFeedback = H.buildCommandFeedback
local buildCorpseHaulDiagnostic = H.buildCorpseHaulDiagnostic
local buildBandageFeedback = H.buildBandageFeedback
local buildActionInformation = H.buildActionInformation
local buildStaminaRecoverySummary = H.buildStaminaRecoverySummary

function Network.BuildSnapshot(record, inventorySummaryOverride)
    if type(buildSnapshotState) ~= "function"
        or type(buildIdentityProjection) ~= "function"
        or type(buildPresentationProjection) ~= "function"
    then return nil end
    local state = buildSnapshotState(record, inventorySummaryOverride)
    local aiState = state.aiState
    local canRevive = state.canRevive
    local inCombat = state.inCombat
    local staminaInfo = state.staminaInfo
    local equipmentInfo = state.equipmentInfo
    local combat = state.combat
    local visualState = state.visualState
    local bodyHealth = state.bodyHealth
    local firearmState = state.firearmState
    local vehiclePassenger = state.vehiclePassenger
    local treatmentState = state.treatmentState
    local medicalCareState = state.medicalCareState
    local needsSummary = state.needsSummary
    local attackMode = state.attackMode
    local snapshot = buildIdentityProjection(record, state)
    snapshot.commandFeedback = buildCommandFeedback(record)
    snapshot.corpseHaulManualDiagnostic = buildCorpseHaulDiagnostic(record)
    snapshot.bandageFeedback = buildBandageFeedback(record)
    snapshot.actionInformation = buildActionInformation(record)
    snapshot.staminaRecovery = buildStaminaRecoverySummary(record)
    snapshot.lumberRuntime = record.runtime and record.runtime.lumber
        and Core.DeepCopy(record.runtime.lumber) or nil
    snapshot.storageCourier = record.runtime and record.runtime.storageCourier
        and Core.DeepCopy(record.runtime.storageCourier) or nil
    snapshot.activeJob = record.activeJob
    snapshot.activeBehavior = record.activeBehavior
    snapshot.presenceState = record.presenceState
    snapshot.zombieTargetable = Settings
        and Settings.CanZombieTargetRecord
        and Settings.CanZombieTargetRecord(record)
        or false
    snapshot.alive = record.alive
    snapshot.hpCurrent = record.health and record.health.current or nil
    snapshot.hpMax = record.health and record.health.max or nil
    snapshot.healthState = record.health and record.health.state or nil
    snapshot.needs = needsSummary
    snapshot.canRevive = canRevive
    snapshot.reviveUntil = record.health and record.health.reviveUntil or 0
    snapshot.recentDamageUntil = record.health
        and record.health.recentDamageUntil or 0
    snapshot.recentDamageType = record.health
        and record.health.recentDamageType or nil
    snapshot.bodyHealth = bodyHealth
    snapshot.treatmentState = treatmentState
    snapshot.medicalCareState = medicalCareState
    snapshot.staminaCurrent = staminaInfo.current
    snapshot.staminaMax = staminaInfo.max
    snapshot.staminaBaseMax = staminaInfo.baseMax
    snapshot.staminaState = staminaInfo.state
    snapshot.staminaVisibleUntil = staminaInfo.visibleUntil
    snapshot.encumbranceLevel = staminaInfo.encumbranceLevel
    snapshot.encumbranceRatio = staminaInfo.encumbranceRatio
    snapshot.staminaRatio = math.max(
        0,
        math.min(
            1,
            (tonumber(staminaInfo.current) or 0)
                / math.max(1, tonumber(staminaInfo.max) or 1)
        )
    )
    snapshot.skillLevels = Skills and Skills.BuildSnapshot
        and Skills.BuildSnapshot(record) or {}
    snapshot.weaponMode = record.weaponMode
    snapshot.weaponFullType = record.equipment
        and record.equipment.primaryFullType or nil
    snapshot.combatModeResolved = equipmentInfo.combatModeResolved
        or record.weaponMode
    snapshot.weaponStatus = equipmentInfo.weaponStatus or "unknown"
    snapshot.firearmState = firearmState
    snapshot.vehiclePassenger = vehiclePassenger and {
        active = vehiclePassenger.active == true,
        vehicleId = vehiclePassenger.vehicleId,
        seat = vehiclePassenger.seat,
        ownerOnlineID = vehiclePassenger.ownerOnlineID,
        boardedAt = vehiclePassenger.boardedAt,
    } or nil
    snapshot.presenceRevision = record.presenceRevision
    snapshot.replicaSequence = record.runtime
        and record.runtime.replicaSequence or nil
    snapshot.liveBodyInstanceID = record.liveBodyInstanceID
    snapshot.liveBodyOnlineID = record.liveBodyOnlineID
    snapshot.liveBodyLease = record.runtime
        and record.runtime.bodyLease or nil
    snapshot.aiState = aiState
    snapshot.inCombat = inCombat
    snapshot.attackMode = attackMode
    -- Explicit fighting-mode flag: a remote body draws its weapon from this
    -- instead of reconstructing the whole combat runtime.
    snapshot.combatStance = combat and combat.combatStance == true or false
    snapshot.visualState = visualState
    local presentation = buildPresentationProjection(record, state)
    snapshot.pathDebugState = presentation.pathDebugState
    snapshot.combatDebugState = presentation.combatDebugState
    snapshot.seatingDebug = presentation.seatingDebug
    snapshot.appearance = presentation.appearance
    snapshot.travel = presentation.travel
    snapshot.mapPresentation = presentation.mapPresentation
    snapshot.equipmentSummary = presentation.equipmentSummary
    snapshot.inventorySummary = presentation.inventorySummary
    snapshot.characterWindow = presentation.characterWindow
    snapshot.debugState = presentation.debugState
    return snapshot
end

return Network

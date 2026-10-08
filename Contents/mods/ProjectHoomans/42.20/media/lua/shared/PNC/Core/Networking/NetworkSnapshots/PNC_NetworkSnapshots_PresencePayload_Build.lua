-- Shared presence payload builder provider.
local Network = PNC.Network
local H = Network.Internal.PresencePayload
if not H then return Network end
local Core = H.Core
local Equipment = PNC.Equipment
local Stamina = H.Stamina
local Firearms = H.Firearms
local Settings = H.Settings
local buildTravelSummary = H.BuildTravelSummary
local resolveAIState = H.ResolveAIState
local buildCommandFeedback = H.BuildCommandFeedback
local buildCorpseHaulDiagnostic = H.BuildCorpseHaulDiagnostic
local buildBandageFeedback = H.BuildBandageFeedback
local buildActionInformation = H.BuildActionInformation
local buildStaminaRecoverySummary = H.BuildStaminaRecoverySummary
local buildVisualState = H.BuildVisualState
local buildPathDebugState = H.BuildPathDebugState
local buildCampResourceDebugState = H.BuildCampResourceDebugState
local buildSeatingDebugState = H.BuildSeatingDebugState
local buildIdentityOwnershipSummary = H.BuildIdentityOwnershipSummary
if not H.BuildCombatDebugDelta then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PresencePayload_CombatDebug"
end
local buildCombatDebugDelta = H.BuildCombatDebugDelta

function Network.BuildPresenceDelta(record)
    local aiState
    local inCombat
    local now = Core.Now()
    local ownership = buildIdentityOwnershipSummary(record)
    local radioGear = Equipment and Equipment.RadioGear
        and Equipment.RadioGear.Describe
        and Equipment.RadioGear.Describe(record) or nil
    local staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    local firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    local vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
    local medicalCareState = PNC.Treatment
        and PNC.Treatment.BuildMedicalCareSnapshot
        and PNC.Treatment.BuildMedicalCareSnapshot(record) or nil
    aiState, inCombat = resolveAIState(record)
    local pathDebugState
    local lastPathDebugAt = record.runtime
        and tonumber(record.runtime.pathDebugReplicatedAt) or 0
    if lastPathDebugAt <= 0 or now - lastPathDebugAt >= 350 then
        pathDebugState = buildPathDebugState(record)
        if record.runtime then
            record.runtime.pathDebugReplicatedAt = now
        end
    end
    local combatDebugState = buildCombatDebugDelta(
        record,
        inCombat,
        now,
        firearmState
    )
    return {
        interestDetailed = true,
        id = record.id,
        x = record.x,
        y = record.y,
        z = record.z,
        -- Keep the compact ownership identity on presence deltas as well as
        -- roster/detail payloads. A client may first learn an NPC through a
        -- mobile presence update, so conversation and map UI must not infer
        -- membership from the tactical class.
        factionID = ownership.factionID,
        colonyOwned = ownership.colonyOwned,
        recruited = ownership.recruited,
        ownerUsername = ownership.ownerUsername,
        ownerOnlineID = ownership.ownerOnlineID,
        radioGear = radioGear,
        presenceState = record.presenceState,
        zombieTargetable = Settings
            and Settings.CanZombieTargetRecord
            and Settings.CanZombieTargetRecord(record)
            or false,
        alive = record.alive,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        attackType = record.attackType or "auto",
        commandFeedback = buildCommandFeedback(record),
        corpseHaulManualDiagnostic = buildCorpseHaulDiagnostic(record),
        bandageFeedback = buildBandageFeedback(record),
        actionInformation = buildActionInformation(record),
        staminaRecovery = buildStaminaRecoverySummary(record),
        treatmentState = PNC.BehaviorTreatment
            and PNC.BehaviorTreatment.BuildSnapshot
            and PNC.BehaviorTreatment.BuildSnapshot(record) or nil,
        medicalCareState = medicalCareState,
        recentDamageUntil = record.health and record.health.recentDamageUntil or 0,
        recentDamageType = record.health and record.health.recentDamageType or nil,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        staminaVisibleUntil = staminaInfo.visibleUntil,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        presenceRevision = record.presenceRevision,
        replicaSequence = record.runtime
            and record.runtime.replicaSequence or nil,
        liveBodyInstanceID = record.liveBodyInstanceID,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyLease = record.runtime and record.runtime.bodyLease or nil,
        aiState = aiState,
        activeBehavior = record.activeBehavior,
        inCombat = inCombat,
        attackMode = record.runtime and record.runtime.target ~= nil or false,
        -- `combat` was never a local in this builder. That made every
        -- presence delta report a false stance, so multiplayer replicas could
        -- not honor the combat lease even while the server had one active.
        combatStance = record.runtime
            and (record.runtime.combatStance == true or inCombat == true)
            or inCombat == true,
        firearmState = firearmState,
        vehiclePassenger = vehiclePassenger and {
            active = vehiclePassenger.active == true,
            vehicleId = vehiclePassenger.vehicleId,
            seat = vehiclePassenger.seat,
            ownerOnlineID = vehiclePassenger.ownerOnlineID,
            boardedAt = vehiclePassenger.boardedAt,
        } or nil,
        visualState = buildVisualState(record),
        -- Presence deltas omit the full clothing projection, but work-held
        -- state must refresh while a live job is running.
        workPresentation = Equipment
            and Equipment.BuildWorkPresentationSummary
            and Equipment.BuildWorkPresentationSummary(record)
            or nil,
        pathDebugState = pathDebugState,
        combatDebugState = combatDebugState,
        campResourceDebug = buildCampResourceDebugState(record),
        seatingDebug = buildSeatingDebugState(record),
        travel = buildTravelSummary(record, false),
    }
end


-- Combat damage is a high-frequency mutation. It must replicate the
-- authoritative health/wound result, but it does not need to rebuild the
-- inventory, skills, appearance, route, and debug projections carried by a
-- detailed snapshot. Keep this payload merge-compatible with the client
-- snapshot cache so UI and remote incapacitation state update immediately.
function Network.BuildCombatDamageDelta(record)
    local health = record and record.health or {}
    local runtime = record and record.runtime or {}
    local wounds = PNC.NPCWounds
    local bodyHealth = wounds and wounds.BuildSnapshot
        and wounds.BuildSnapshot(record) or nil
    local visualState = buildVisualState and buildVisualState(record) or nil
    return {
        interestDetailed = true,
        id = record and record.id or nil,
        x = record and record.x or nil,
        y = record and record.y or nil,
        z = record and record.z or nil,
        presenceState = record and record.presenceState or nil,
        alive = record and record.alive or false,
        hpCurrent = health.current,
        hpMax = health.max,
        healthState = health.state,
        recentDamageUntil = health.recentDamageUntil or 0,
        recentDamageType = health.recentDamageType,
        bodyHealth = bodyHealth,
        activeJob = record and record.activeJob or nil,
        activeBehavior = record and record.activeBehavior or nil,
        inCombat = true,
        attackMode = runtime.target ~= nil or runtime.attackAction ~= nil,
        combatStance = runtime.combatStance == true
            or runtime.target ~= nil
            or runtime.attackAction ~= nil,
        visualState = visualState,
        weaponFullType = record and record.equipment
            and record.equipment.primaryFullType or nil,
        presenceRevision = record and record.presenceRevision or nil,
        replicaSequence = runtime.replicaSequence,
        liveBodyInstanceID = record and record.liveBodyInstanceID or nil,
        liveBodyOnlineID = record and record.liveBodyOnlineID or nil,
        liveBodyLease = runtime.bodyLease,
    }
end

return Network

--[[
    PNC Network Snapshots - Presence Payload
    Builds throttled incremental presence snapshots.
]]

local Network = PNC.Network
local Core = PNC.Core
local Equipment = PNC.Equipment
local Stamina = PNC.Stamina
local Firearms = PNC.Firearms
local Settings = PNC.Sandbox
local Parts = Network.Internal.SnapshotParts
local buildTravelSummary = Parts.BuildTravelSummary
local resolveAIState = Parts.ResolveAIState
local buildCombatSummary = Parts.BuildCombatSummary
local buildCommandFeedback = Parts.BuildCommandFeedback
local buildBandageFeedback = Parts.BuildBandageFeedback
local buildActionInformation = Parts.BuildActionInformation
local buildVisualState = Parts.BuildVisualState
local buildPathDebugState = Parts.BuildPathDebugState
local buildCombatDebugState = Parts.BuildCombatDebugState
local buildCampResourceDebugState = Parts.BuildCampResourceDebugState
local buildSeatingDebugState = Parts.BuildSeatingDebugState
local buildIdentityOwnershipSummary =
    Parts.BuildIdentityOwnershipSummary

function Network.BuildPresenceDelta(record)
    local aiState
    local inCombat
    local now = Core.Now()
    local ownership = buildIdentityOwnershipSummary(record)
    local staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    local firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    local vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
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
    local combatDebugState
    local lastCombatDebugAt = record.runtime
        and tonumber(record.runtime.combatDebugReplicatedAt) or 0
    local combatDebugTransitioned = record.runtime
        and record.runtime.combatDebugWasActive ~= inCombat
        or false
    if lastCombatDebugAt <= 0
        or combatDebugTransitioned
        or (inCombat and now - lastCombatDebugAt >= 150)
    then
        local equipmentInfo = Equipment
            and Equipment.Describe
            and Equipment.Describe(record)
            or {}
        local combat = buildCombatSummary(record, equipmentInfo)
        combatDebugState = buildCombatDebugState(
            record,
            combat,
            firearmState
        )
        if record.runtime then
            record.runtime.combatDebugReplicatedAt = now
        end
    end
    if record.runtime then
        record.runtime.combatDebugWasActive = inCombat
    end
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
        bandageFeedback = buildBandageFeedback(record),
        actionInformation = buildActionInformation(record),
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
        pathDebugState = pathDebugState,
        combatDebugState = combatDebugState,
        campResourceDebug = buildCampResourceDebugState(record),
        seatingDebug = buildSeatingDebugState(record),
        travel = buildTravelSummary(record, false),
    }
end

return Network

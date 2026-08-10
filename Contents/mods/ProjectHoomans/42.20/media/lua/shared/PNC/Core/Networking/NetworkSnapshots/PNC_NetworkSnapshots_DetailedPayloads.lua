local Network = PNC.Network
local Core = PNC.Core
local Equipment = PNC.Equipment
local Inventory = PNC.Inventory
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Profiles = PNC.VisualProfiles
local Wounds = PNC.NPCWounds
local Firearms = PNC.Firearms
local Settings = PNC.Sandbox
local Parts = Network.Internal.SnapshotParts
local buildTravelSummary = Parts.BuildTravelSummary
local buildMapPresentationSummary = Parts.BuildMapPresentationSummary
local resolveAIState = Parts.ResolveAIState
local buildIdentitySummary = Parts.BuildIdentitySummary
local buildOrganizationalFactionSummary =
    Parts.BuildOrganizationalFactionSummary
local buildCombatSummary = Parts.BuildCombatSummary
local buildCommandFeedback = Parts.BuildCommandFeedback
local buildBandageFeedback = Parts.BuildBandageFeedback
local buildVisualState = Parts.BuildVisualState
local buildPathDebugState = Parts.BuildPathDebugState
local buildCombatDebugState = Parts.BuildCombatDebugState
local buildDetailedDebugState = Parts.BuildDetailedDebugState

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
        portrait = PNC.Identity
            and PNC.Identity.BuildPortraitSummary
            and PNC.Identity.BuildPortraitSummary(record)
            or nil,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        recruited = record.recruited == true,
        persist = record.persist ~= false,
        faction = record.faction,
        organizationalFaction =
            buildOrganizationalFactionSummary(record),
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
        zombieTargetable = Settings
            and Settings.CanZombieTargetRecord
            and Settings.CanZombieTargetRecord(record)
            or false,
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
        pathDebugState = buildPathDebugState(record),
        combatDebugState = buildCombatDebugState(
            record,
            combat,
            firearmState
        ),
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
        debugState = buildDetailedDebugState(
            record,
            combat,
            firearmState,
            staminaInfo,
            canRevive,
            aiState,
            vehiclePassenger
        ),
    }
end

return Network

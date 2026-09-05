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
local buildCorpseHaulDiagnostic = Parts.BuildCorpseHaulDiagnostic
local buildBandageFeedback = Parts.BuildBandageFeedback
local buildActionInformation = Parts.BuildActionInformation
local buildVisualState = Parts.BuildVisualState
local buildPathDebugState = Parts.BuildPathDebugState
local buildCombatDebugState = Parts.BuildCombatDebugState
local buildDetailedDebugState = Parts.BuildDetailedDebugState
local buildSeatingDebugState = Parts.BuildSeatingDebugState
local buildIdentityOwnershipSummary =
    Parts.BuildIdentityOwnershipSummary

local function buildNeedsSummary(record)
    local repository = PNC.NeedsRepository
    local state = repository and repository.Get
        and repository.Get(record, false) or nil
    local needs = state and state.needs or record.needs
    if type(needs) ~= "table" then return nil end
    local evaluatedAt = repository and repository.GetEvaluatedAt
        and repository.GetEvaluatedAt(record) or nil
    return {
        hunger = tonumber(needs.hunger) or 0,
        thirst = tonumber(needs.thirst) or 0,
        fatigue = tonumber(needs.fatigue) or 0,
        sampledAt = evaluatedAt,
    }
end

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
    local medicalCareState
    local needsSummary
    local attackMode
    local ownership
    aiState, inCombat = resolveAIState(record)
    canRevive = PNC.Health and PNC.Health.CanRevive and PNC.Health.CanRevive(record) or false
    staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    equipmentInfo = Equipment and Equipment.Describe and Equipment.Describe(record) or {}
    identity = buildIdentitySummary(record)
    ownership = buildIdentityOwnershipSummary(record)
    inventorySummary = Inventory and Inventory.BuildSummaryPayload and Inventory.BuildSummaryPayload(record) or nil
    combat = buildCombatSummary(record, equipmentInfo)
    visualState = buildVisualState(record)
    appearance = Profiles and Profiles.RollAppearance and Profiles.RollAppearance(record) or nil
    bodyHealth = Wounds and Wounds.BuildSnapshot and Wounds.BuildSnapshot(record) or nil
    needsSummary = buildNeedsSummary(record)
    firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
    treatmentState = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.BuildSnapshot
        and PNC.BehaviorTreatment.BuildSnapshot(record) or nil
    medicalCareState = PNC.Treatment
        and PNC.Treatment.BuildMedicalCareSnapshot
        and PNC.Treatment.BuildMedicalCareSnapshot(record) or nil
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
        vanillaTraits = PNC.PlayerNeedsModel
            and PNC.PlayerNeedsModel.NormalizeTraits(record.vanillaTraits)
            or {},
        vanillaTraitsAuthored = record.vanillaTraitsAuthored == true,
        vanillaTraitsGenerationVersion = math.max(0, math.floor(
            tonumber(record.vanillaTraitsGenerationVersion) or 0
        )),
        dynamicTraits = PNC.ConditionStats
            and PNC.ConditionStats.NormalizeTraits(record.dynamicTraits) or {},
        dynamicTraitsAuthored = record.dynamicTraitsAuthored == true,
        conditionStats = PNC.ConditionStats
            and PNC.ConditionStats.NormalizeState(record.conditionStats, 0)
            or {},
        morale = record.social and record.social.morale or 0,
        recruited = ownership.recruited,
        relationshipCategory = record.generation
                and record.generation.relationshipKind == "lover"
            and "Lover" or nil,
        startingRelationship = record.generation
            and record.generation.source == "starting_companion_trait"
            and {
                kind = record.generation.relationshipKind,
                since = record.generation.relationshipSince,
            } or nil,
        persist = record.persist ~= false,
        tacticalClass = record.tacticalClass,
        factionID = ownership.factionID,
        colonyOwned = ownership.colonyOwned,
        -- Tactical class remains separate from factionID. Replicate explicit
        -- hostility flags so MP clients never infer player hostility from a
        -- coarse class value alone.
        hostility = Core.DeepCopy(record.hostility or {}),
        organizationalFaction =
            buildOrganizationalFactionSummary(record),
        worldDiscovery = Parts.BuildWorldDiscoverySummary(record),
        visualProfile = record.visualProfile,
        isFemale = identity.isFemale,
        identity = identity,
        x = record.x,
        y = record.y,
        z = record.z,
        orderKind = record.orderSpec and record.orderSpec.kind or nil,
        attackType = record.attackType or "auto",
        ownerUsername = ownership.ownerUsername,
        ownerOnlineID = ownership.ownerOnlineID,
        commandFeedback = buildCommandFeedback(record),
        corpseHaulManualDiagnostic = buildCorpseHaulDiagnostic(record),
        bandageFeedback = buildBandageFeedback(record),
        actionInformation = buildActionInformation(record),
        lumberRuntime = record.runtime and record.runtime.lumber
            and Core.DeepCopy(record.runtime.lumber) or nil,
        storageCourier = record.runtime and record.runtime.storageCourier
            and Core.DeepCopy(record.runtime.storageCourier) or nil,
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
        needs = needsSummary,
        canRevive = canRevive,
        reviveUntil = record.health and record.health.reviveUntil or 0,
        recentDamageUntil = record.health and record.health.recentDamageUntil or 0,
        bodyHealth = bodyHealth,
        treatmentState = treatmentState,
        medicalCareState = medicalCareState,
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
        replicaSequence = record.runtime
            and record.runtime.replicaSequence or nil,
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
        seatingDebug = buildSeatingDebugState(record),
        appearance = appearance and Core.DeepCopy(appearance) or nil,
        travel = buildTravelSummary(record, true),
        mapPresentation = buildMapPresentationSummary(record),
        equipmentSummary = {
            primaryFullType = record.equipment and record.equipment.primaryFullType or nil,
            primaryVisual = Equipment
                and Equipment.BuildPrimaryVisualSummary
                and Equipment.BuildPrimaryVisualSummary(record)
                or nil,
            secondaryFullType = record.equipment and record.equipment.secondaryFullType or nil,
            worn = Core.DeepCopy(record.equipment and record.equipment.worn or {}),
            wornVisuals = Equipment
                and Equipment.BuildWornVisualSummary
                and Equipment.BuildWornVisualSummary(record)
                or {},
            attached = Core.DeepCopy(record.equipment and record.equipment.attached or {}),
        },
        inventorySummary = inventorySummary,
        characterWindow = {
            displayName = identity.displayName,
            archetypeID = identity.archetypeID,
            archetypeLabel = identity.archetypeLabel,
            identitySeed = identity.identitySeed,
            ownerUsername = ownership.ownerUsername,
            recruited = ownership.recruited,
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

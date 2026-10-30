local Codec = require "PNC/Core/Base/PNC_RecordCodec"
PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}
local MemoryRepository = require "PNC/Conversation/Memory/PNC_ConversationMemoryRepository"
local InventoryRepository = require "PNC/Core/Inventory/PNC_InventoryRepository"

local HealthRepository = require "PNC/Core/Health/PNC_HealthRepository"
local IdentityRepository = require "PNC/Core/Identity/PNC_IdentityRepository"
local RelationshipRepository = require "PNC/Core/Relationships/PNC_RelationshipRepository"
local SkillsRepository = require "PNC/Core/Skills/PNC_SkillsRepository"
local CompanionRecordRepository = require "PNC/Core/Commands/PNC_CompanionRecordRepository"
local CombatRecordRepository = require "PNC/Core/Combat/PNC_CombatRecordRepository"
local BodyRepository = require "PNC/Core/Presence/PNC_BodyRepository"
local Persistence = PNC.Persistence
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local Inventory = PNC.Inventory
local FactionTypes = PNC.FactionTypes
local function serializeAuthoredTraits(record, field, authoredField, normalize)
    local traits
    if type(record) ~= "table" or record[authoredField] ~= true then
        return nil
    end
    traits = normalize(record[field])
    return Codec.hasTableEntries(traits) and traits or nil
end

local function serializeMapPresentation(record)
    local presentation
    if type(record) ~= "table"
        or type(record.mapPresentation) ~= "table"
        or not PNC.MapPresentation
        or not PNC.MapPresentation.BuildSummary
    then
        return nil
    end
    presentation = PNC.MapPresentation.BuildSummary(record.mapPresentation)
    if presentation.visibility == PNC.MapPresentation.VISIBILITY_ALL
        and not Codec.hasTableEntries(presentation.knownBy)
        and presentation.roleTag == nil
        and presentation.iconID == nil
        and presentation.revision == 0
    then
        return nil
    end
    return presentation
end

local function serializeSemanticActionPlan(record)
    local contract = PNC.Semantics and PNC.Semantics.ActionPlan
    local plan
    if not contract or type(contract.Normalize) ~= "function"
        or type(record and record.semanticActionPlan) ~= "table"
    then
        return nil
    end
    plan = contract.Normalize(record.semanticActionPlan)
    if not plan or tostring(plan.npcID) ~= tostring(record.id) then
        return nil
    end
    return plan
end

function Persistence.SerializeRecord(record)
    local identity
    local appearance
    local appearanceContract
    local progression
    local payload
    local inventoryPayload
    local recipeKnowledge
    if not record or record.persist == false then
        return nil
    end
    if type(record.appearance) == "table"
        and (tonumber(record.appearance.schemaVersion) ~= 2
            or PNC.Identity.Appearance
                and PNC.Identity.Appearance.Validate
                and not PNC.Identity.Appearance.Validate(record.appearance))
    then
        return nil
    end
    MemoryRepository.PrepareRecord(record)
    identity = IdentityRepository.Normalize(record.identity, record)
    appearance = type(record.appearance) == "table"
        and Core.DeepCopy(record.appearance) or nil
    appearanceContract = IdentityRepository.BuildAppearanceContract(record)
    progression = SkillsRepository.SerializeRecord(record)
    inventoryPayload = InventoryRepository.SerializeRecord(record)
    recipeKnowledge = PNC.RecipeKnowledge
        and PNC.RecipeKnowledge.Serialize(record) or nil
    payload = {
        schemaVersion = Const.PERSISTENCE_VERSION,
        recordRevision = math.max(0, math.floor(Codec.normalizeNumber(record.recordRevision, 0))),
        repairVersions = Persistence.Repairs
            and Persistence.Repairs.CopyVersions(
                record.persistenceRepairVersions
            ) or nil,
        id = record.id,
        uniqueDefinitionId = Codec.normalizeString(
            record.uniqueDefinitionId
        ),
        uniqueDefinitionVersion = tonumber(record.uniqueDefinitionVersion)
            and math.max(1, math.floor(tonumber(record.uniqueDefinitionVersion)))
            or nil,
        inventoryTemplateRef = Codec.normalizeString(
            record.inventoryTemplateRef
        ),
        startingItems = not record.inventoryTemplateRef
            and Codec.hasTableEntries(record.startingItems)
            and Core.DeepCopy(record.startingItems) or nil,
        skillBaseLevels = Types and Types.NormalizeSkillLevels
            and SkillsRepository.SerializeBaseLevels(record) or nil,
        tacticalClass = record.tacticalClass,
        ownerUsername = Codec.normalizeString(record.ownerUsername),
        ownerCharacterUUID = Codec.normalizeString(
            record.ownerCharacterUUID
        ),
        identity = identity,
        appearance = appearance,
        appearanceContract = appearanceContract,
        m = MemoryRepository.SerializeRecord(record),
        position = {
            x = Codec.normalizeNumber(record.x, 0),
            y = Codec.normalizeNumber(record.y, 0),
            z = Codec.normalizeNumber(record.z, 0),
        },
        spawn = {
            x = Codec.normalizeNumber(record.spawnX, record.x),
            y = Codec.normalizeNumber(record.spawnY, record.y),
            z = Codec.normalizeNumber(record.spawnZ, record.z),
        },
        anchor = {
            x = Codec.normalizeNumber(record.anchorX, record.x),
            y = Codec.normalizeNumber(record.anchorY, record.y),
            z = Codec.normalizeNumber(record.anchorZ, record.z),
        },
        orderSpec = CompanionRecordRepository.SerializeOrder(record),
        patrolPoints = CompanionRecordRepository.SerializePatrolPoints(record),
        patrolIndex = record.orderSpec
                and tostring(record.orderSpec.kind or "")
                    == tostring(Const.ORDER_PATROL or "patrol")
            and math.max(1, math.floor(Codec.normalizeNumber(record.patrolIndex, 1)))
            or nil,
        hostility = CombatRecordRepository.NormalizeHostility(record.hostility, record.tacticalClass),
        health = HealthRepository.Serialize(record.health, record.health and record.health.max or Const.DEFAULT_HP_MAX),
        stamina = HealthRepository.SerializeStamina(record.stamina),
        weaponMode = tostring(record.weaponMode or "melee"),
        attackType = CombatRecordRepository.NormalizeAttackType(record.attackType, record.weaponMode),
        equipmentSpawnMode = Codec.normalizeString(record.equipmentSpawnMode),
        equipmentPoolID = Codec.normalizeString(record.equipmentPoolID) or "Default",
        equipment = {
            primaryFullType = Codec.normalizeString(record.equipment and record.equipment.primaryFullType),
            secondaryFullType = Codec.normalizeString(record.equipment and record.equipment.secondaryFullType),
            worn = Codec.copyStringMap(record.equipment and record.equipment.worn),
            wornVisuals = record.equipment
                and record.equipment.wornVisuals
                and Core.DeepCopy(record.equipment.wornVisuals)
                or {},
            attached = Codec.copyStringMap(record.equipment and record.equipment.attached),
        },
        allowedJobs = type(record.allowedJobs) == "table"
            and Core.DeepCopy(record.allowedJobs) or {},
        jobPriorities = type(record.jobPriorities) == "table"
                and Codec.hasTableEntries(record.jobPriorities)
            and Core.DeepCopy(record.jobPriorities) or nil,
        inventory = inventoryPayload,
        social = RelationshipRepository.SerializeRecord(record),
        semanticCognition = PNC.Semantics
            and PNC.Semantics.CognitionProjection
            and PNC.Semantics.CognitionProjection.Serialize(
                record.semanticCognition,
                record.id
            ) or nil,
        semanticActionPlan = serializeSemanticActionPlan(record),
        followerAbandonment = CompanionRecordRepository.NormalizeAbandonment(
            record.followerAbandonment
        ),
        colonistDeparture = CompanionRecordRepository.NormalizeDeparture(
            record.colonistDeparture
        ),
        affiliation = FactionTypes
            and FactionTypes.NormalizeAffiliation(
                record.affiliation
            ) or nil,
        progression = progression,
        recipeKnowledge = recipeKnowledge,
        corpse = BodyRepository.NormalizeCorpse(record.corpse, record),
        travel = PNC.Travel
            and PNC.Travel.Model
            and PNC.Travel.Model.BuildSummary
            and PNC.Travel.Model.BuildSummary(record.travel, true)
            or nil,
        mapPresentation = serializeMapPresentation(record),
        vanillaTraits = PNC.PlayerNeedsModel
            and serializeAuthoredTraits(
                record,
                "vanillaTraits",
                "vanillaTraitsAuthored",
                PNC.PlayerNeedsModel.NormalizeTraits
            ) or nil,
        vanillaTraitsAuthored = record.vanillaTraitsAuthored == true
            and true or nil,
        dynamicTraits = PNC.ConditionStats
            and serializeAuthoredTraits(
                record,
                "dynamicTraits",
                "dynamicTraitsAuthored",
                PNC.ConditionStats.NormalizeTraits
            ) or nil,
        dynamicTraitsAuthored = record.dynamicTraitsAuthored == true
            and true or nil,
        npcTraits = PNC.NPCTraits
            and PNC.NPCTraits.NormalizeSet(record.npcTraits) or nil,
        conditionStats = PNC.ConditionStats
            and type(record.conditionStats) == "table"
            and PNC.ConditionStats.NormalizeState(record.conditionStats, 0)
            or nil,
        generation = type(record.generation) == "table"
            and PNC.Core.DeepCopy(record.generation) or nil,
        npcJournal = PNC.Journals and PNC.Journals.ExportNPC
            and PNC.Journals.ExportNPC(record) or nil,
    }
    payload.bodyHint = BodyRepository.BuildHint(record)
    return payload
end

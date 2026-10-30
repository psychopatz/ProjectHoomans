local Codec = require "PNC/Core/Base/PNC_RecordCodec"
PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}
local MemoryRepository = require "PNC/Conversation/Memory/PNC_ConversationMemoryRepository"

local HealthRepository = require "PNC/Core/Health/PNC_HealthRepository"
local IdentityRepository = require "PNC/Core/Identity/PNC_IdentityRepository"
local RelationshipRepository = require "PNC/Core/Relationships/PNC_RelationshipRepository"
local SkillsRepository = require "PNC/Core/Skills/PNC_SkillsRepository"
local CompanionRecordRepository = require "PNC/Core/Commands/PNC_CompanionRecordRepository"
local CombatRecordRepository = require "PNC/Core/Combat/PNC_CombatRecordRepository"
local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local FactionTypes = PNC.FactionTypes
local Reset = Persistence.Reset
    or require "PNC/Core/Persistence/PNC_ModDataStore"

local function buildDefinition(
    raw,
    fallbackID,
    identity,
    inventoryData,
    position,
    anchor
)
    return {
        id = raw.id or fallbackID,
        uniqueDefinitionId = raw.uniqueDefinitionId,
        uniqueDefinitionVersion = raw.uniqueDefinitionVersion,
        inventoryTemplateRef = raw.inventoryTemplateRef,
        startingItems = raw.startingItems,
        skillBaseLevels = raw.skillBaseLevels,
        displayName = raw.displayName or raw.name
            or (identity and identity.displayName) or nil,
        name = raw.displayName or raw.name
            or (identity and identity.displayName) or nil,
        tacticalClass = raw.tacticalClass,
        visualProfile = raw.visualProfile,
        outfit = raw.outfit,
        isFemale = raw.isFemale == true
            or (identity and identity.isFemale == true),
        x = Codec.normalizeNumber(position.x, raw.x or 0),
        y = Codec.normalizeNumber(position.y, raw.y or 0),
        z = Codec.normalizeNumber(position.z, raw.z or 0),
        anchorX = Codec.normalizeNumber(
            anchor.x,
            raw.anchorX or raw.x or 0
        ),
        anchorY = Codec.normalizeNumber(
            anchor.y,
            raw.anchorY or raw.y or 0
        ),
        anchorZ = Codec.normalizeNumber(
            anchor.z,
            raw.anchorZ or raw.z or 0
        ),
        ownerUsername = Codec.normalizeString(raw.ownerUsername),
        ownerCharacterUUID = Codec.normalizeString(
            raw.ownerCharacterUUID
        ),
        identitySeed = raw.identitySeed
            or (identity and identity.seed) or nil,
        identity = identity,
        appearance = type(raw.appearance) == "table"
            and Core.DeepCopy(raw.appearance) or nil,
        appearanceAuthored = raw.appearanceContract
            and raw.appearanceContract.authored == true
            or type(raw.appearance) == "table",
        appearanceProvenance = type(raw.appearanceContract) == "table"
            and Core.DeepCopy(raw.appearanceContract) or nil,
        orderSpec = raw.orderSpec,
        patrolPoints = raw.patrolPoints,
        weaponMode = raw.weaponMode,
        attackType = raw.attackType,
        equipmentSpawnMode = raw.equipmentSpawnMode,
        equipmentPoolID = raw.equipmentPoolID,
        combatProfile = raw.combatProfile,
        equipment = raw.equipment,
        inventory = inventoryData,
        allowedJobs = raw.allowedJobs,
        jobPriorities = raw.jobPriorities,
        archetypeID = raw.archetypeID
            or (identity and identity.archetypeID) or nil,
        persist = raw.persist ~= false,
        recruited = raw.recruited == true,
        social = RelationshipRepository.Normalize(
            raw.social,
            raw.identitySeed or (identity and identity.seed),
            raw.archetypeID or (identity and identity.archetypeID)
        ),
        semanticCognition = raw.semanticCognition,
        affiliation = raw.affiliation,
        mapPresentation = raw.mapPresentation,
        generation = raw.generation,
        vanillaTraits = raw.vanillaTraits,
        vanillaTraitsAuthored = raw.vanillaTraitsAuthored == true,
        dynamicTraits = raw.dynamicTraits,
        dynamicTraitsAuthored = raw.dynamicTraitsAuthored == true,
        npcTraits = raw.npcTraits,
        recipeKnowledge = raw.recipeKnowledge,
    }
end

function Persistence.DeserializeRecord(raw, fallbackID)
    local definition
    local position
    local spawn
    local anchor
    local record
    local identity
    local identityBirthBefore
    local progression
    local inventoryData
    local bodyHint
    local actionPlan
    local reason = Reset.Check(raw, Const.PERSISTENCE_VERSION, nil,
        function(value)
            return type(value.id) == "string" and value.id ~= ""
        end)
    if reason ~= nil then
        return nil
    end
    if IdentityRepository.ValidateRecord then
        reason = IdentityRepository.ValidateRecord(raw)
        if reason ~= nil then
            return nil
        end
    end
    position = raw.position or raw
    spawn = raw.spawn or raw
    anchor = raw.anchor or raw
    identity = type(raw.identity) == "table"
        and Core.DeepCopy(raw.identity) or nil
    identity = IdentityRepository.RestoreVoiceProfile
        and IdentityRepository.RestoreVoiceProfile(identity) or identity
    if identity and IdentityRepository.NormalizeBackstoryMetadata then
        identity.backstory = IdentityRepository.NormalizeBackstoryMetadata(
            identity.backstory
        )
    end
    identityBirthBefore = identity and identity.birth or nil
    inventoryData = type(raw.inventory) == "table"
        and Core.DeepCopy(raw.inventory) or nil
    definition = buildDefinition(
        raw,
        fallbackID,
        identity,
        inventoryData,
        position,
        anchor
    )
    record = Types.NewRecord(definition)
    if not record then
        return nil
    end
    record.id = tostring(raw.id or record.id)
    record.semanticActionPlan = nil
    local actionPlanContract = PNC.Semantics
        and PNC.Semantics.ActionPlan or nil
    if actionPlanContract
        and type(actionPlanContract.Normalize) == "function"
        and type(raw.semanticActionPlan) == "table"
    then
        actionPlan = actionPlanContract.Normalize(raw.semanticActionPlan)
        if actionPlan and tostring(actionPlan.npcID) == record.id then
            record.semanticActionPlan = actionPlan
        end
    end
    record.recordRevision = math.max(0, math.floor(Codec.normalizeNumber(raw.recordRevision, 0)))
    record.persistenceRepairVersions = Persistence.Repairs
        and Persistence.Repairs.NormalizeVersions(raw.repairVersions)
        or {}
    record.x = Codec.normalizeNumber(position.x, record.x)
    record.y = Codec.normalizeNumber(position.y, record.y)
    record.z = Codec.normalizeNumber(position.z, record.z)
    record.spawnX = Codec.normalizeNumber(spawn.x, raw.spawnX or record.x)
    record.spawnY = Codec.normalizeNumber(spawn.y, raw.spawnY or record.y)
    record.spawnZ = Codec.normalizeNumber(spawn.z, raw.spawnZ or record.z)
    record.anchorX = Codec.normalizeNumber(anchor.x, record.anchorX)
    record.anchorY = Codec.normalizeNumber(anchor.y, record.anchorY)
    record.anchorZ = Codec.normalizeNumber(anchor.z, record.anchorZ)
    record.ownerUsername = Codec.normalizeString(raw.ownerUsername)
        or record.ownerUsername
    record.ownerCharacterUUID = Codec.normalizeString(
        raw.ownerCharacterUUID
    ) or record.ownerCharacterUUID
    record.weaponMode = tostring(raw.weaponMode or record.weaponMode or "melee")
    record.attackType = CombatRecordRepository.NormalizeAttackType(raw.attackType, record.weaponMode)
    CompanionRecordRepository.RestoreDirective(record, raw)
    -- Camp resources are a server runtime cache, not durable NPC state.
    -- Older saves may still contain campState; discard it here so loading a
    -- save cannot recreate one copy of the resource table per NPC.
    record.campState = nil
    record.hostility = CombatRecordRepository.NormalizeHostility(raw.hostility, record.tacticalClass)
    HealthRepository.RestoreHealth(record, raw.health or raw)
    progression = SkillsRepository.NormalizeProgression(raw.progression)
    record = SkillsRepository.RestoreRecord(record, progression)
    record.social = RelationshipRepository.Normalize(
        raw.social,
        record.identitySeed,
        record.archetypeID
    )
    CompanionRecordRepository.RestoreMarkers(record, raw)
    record.affiliation = FactionTypes
        and FactionTypes.NormalizeAffiliation(raw.affiliation)
        or nil
    record.persist = raw.persist ~= false
    record.generation = type(raw.generation) == "table"
        and PNC.Core.DeepCopy(raw.generation) or nil
    if PNC.RecipeKnowledge and PNC.RecipeKnowledge.Normalize then
        record.recipeKnowledge = PNC.RecipeKnowledge.Normalize(
            raw.recipeKnowledge or record.recipeKnowledge)
        record.runtime.recipeKnowledgeIndex = nil
    end
    record = Internal.FinalizeDeserializedRecord(
        record,
        raw,
        identity,
        progression
    )
    record = MemoryRepository.RestoreRecord(record, raw)
    if record and record.identity
        and record.identity.birth ~= identityBirthBefore
        and PNC.Registry
        and type(PNC.Registry.MarkDirty) == "function"
    then
        PNC.Registry.MarkDirty(record, "identity")
    end
    return record
end

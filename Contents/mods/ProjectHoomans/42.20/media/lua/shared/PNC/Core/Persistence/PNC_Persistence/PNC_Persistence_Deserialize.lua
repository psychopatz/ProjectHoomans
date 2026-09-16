PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local Inventory = PNC.Inventory
local RelationshipTypes = PNC.RelationshipTypes
local RelationshipMath = PNC.RelationshipMath
local FactionTypes = PNC.FactionTypes
local Reset = Persistence.Reset
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

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
        x = Internal.normalizeNumber(position.x, raw.x or 0),
        y = Internal.normalizeNumber(position.y, raw.y or 0),
        z = Internal.normalizeNumber(position.z, raw.z or 0),
        anchorX = Internal.normalizeNumber(
            anchor.x,
            raw.anchorX or raw.x or 0
        ),
        anchorY = Internal.normalizeNumber(
            anchor.y,
            raw.anchorY or raw.y or 0
        ),
        anchorZ = Internal.normalizeNumber(
            anchor.z,
            raw.anchorZ or raw.z or 0
        ),
        ownerUsername = Internal.normalizeString(raw.ownerUsername),
        identitySeed = raw.identitySeed
            or (identity and identity.seed) or nil,
        identity = identity,
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
        social = Internal.sanitizeSocial(
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
    position = raw.position or raw
    spawn = raw.spawn or raw
    anchor = raw.anchor or raw
    identity = type(raw.identity) == "table"
        and Core.DeepCopy(raw.identity) or nil
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
    record.recordRevision = math.max(0, math.floor(Internal.normalizeNumber(raw.recordRevision, 0)))
    record.persistenceRepairVersions = Persistence.Repairs
        and Persistence.Repairs.NormalizeVersions(raw.repairVersions)
        or {}
    record.x = Internal.normalizeNumber(position.x, record.x)
    record.y = Internal.normalizeNumber(position.y, record.y)
    record.z = Internal.normalizeNumber(position.z, record.z)
    record.spawnX = Internal.normalizeNumber(spawn.x, raw.spawnX or record.x)
    record.spawnY = Internal.normalizeNumber(spawn.y, raw.spawnY or record.y)
    record.spawnZ = Internal.normalizeNumber(spawn.z, raw.spawnZ or record.z)
    record.anchorX = Internal.normalizeNumber(anchor.x, record.anchorX)
    record.anchorY = Internal.normalizeNumber(anchor.y, record.anchorY)
    record.anchorZ = Internal.normalizeNumber(anchor.z, record.anchorZ)
    record.ownerUsername = Internal.normalizeString(raw.ownerUsername) or record.ownerUsername
    record.weaponMode = tostring(raw.weaponMode or record.weaponMode or "melee")
    record.attackType = PNC.Types and PNC.Types.NormalizeAttackType
        and PNC.Types.NormalizeAttackType(raw.attackType, record.weaponMode)
        or tostring(raw.attackType or record.weaponMode or "melee")
    record.patrolPoints = Internal.copyPoints(raw.patrolPoints or record.patrolPoints, record.anchorX, record.anchorY, record.anchorZ)
    record.patrolIndex = math.max(1, math.floor(Internal.normalizeNumber(raw.patrolIndex, 1)))
    record.orderSpec = Internal.sanitizeOrderSpec(raw.orderSpec, record)
    if record.orderSpec and PNC.OrderSystem and PNC.OrderSystem.Normalize then
        record.orderSpec = PNC.OrderSystem.Normalize(record, record.orderSpec)
    end
    -- Camp resources are a server runtime cache, not durable NPC state.
    -- Older saves may still contain campState; discard it here so loading a
    -- save cannot recreate one copy of the resource table per NPC.
    record.campState = nil
    record.hostility = Internal.sanitizeHostility(raw.hostility, record.tacticalClass)
    record.health = Internal.sanitizeHealth(raw.health or raw, record.health and record.health.max or Const.DEFAULT_HP_MAX)
    record.alive = tostring(record.health.state or "") ~= "dead"
        and tostring(record.health.state or "") ~= "corpse"
    progression = Internal.sanitizeProgression(raw.progression)
    record.progression = {
        skillLevelDeltas = progression.skillLevelDeltas,
        skillXP = progression.skillXP,
    }
    record.recruited = progression.recruited == true or record.recruited == true
    record.social = Internal.sanitizeSocial(
        raw.social,
        record.identitySeed,
        record.archetypeID
    )
    record.followerAbandonment = Internal.sanitizeFollowerAbandonment(
        raw.followerAbandonment
    )
    record.colonistDeparture = Internal.sanitizeColonistDeparture(
        raw.colonistDeparture
    )
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
    return Internal.FinalizeDeserializedRecord(
        record,
        raw,
        identity,
        progression
    )
end

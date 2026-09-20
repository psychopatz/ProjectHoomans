PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}
require "PNC/Conversation/Memory/PNC_ConversationMemory"

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
local MemoryEvents = PNC.Conversation
    and PNC.Conversation.Memory
    and PNC.Conversation.Memory.Events or nil

local function serializeAuthoredTraits(record, field, authoredField, normalize)
    local traits
    if type(record) ~= "table" or record[authoredField] ~= true then
        return nil
    end
    traits = normalize(record[field])
    return Internal.hasTableEntries(traits) and traits or nil
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
        and not Internal.hasTableEntries(presentation.knownBy)
        and presentation.roleTag == nil
        and presentation.iconID == nil
        and presentation.revision == 0
    then
        return nil
    end
    return presentation
end

local function serializeSocial(record)
    local social = Internal.sanitizeSocial(
        record and record.social,
        record and record.identitySeed,
        record and record.archetypeID
    )
    -- Conduct scores are a projection of baseline + evidence. Keep the
    -- evidence authoritative in the save and rebuild this view on load.
    if social and social.conduct then
        social.conduct.scores = nil
    end
    return social
end

local function prepareProgression(record)
    local progression = Internal.sanitizeProgression(record.progression)
    progression.recruited = record.recruited == true
    if not Internal.hasTableEntries(progression.skillLevelDeltas) then
        progression.skillLevelDeltas = nil
    end
    if not Internal.hasTableEntries(progression.skillXP) then
        progression.skillXP = nil
    end
    if progression.recruited ~= true
        and progression.skillLevelDeltas == nil
        and progression.skillXP == nil
    then
        return nil
    end
    return progression
end

local function serializeInventory(record)
    if record.inventory and Inventory and Inventory.Serialize then
        return Inventory.Serialize(record)
    end
    if type(record.persistedInventory) ~= "table" then
        return nil
    end
    if tonumber(record.persistenceSourceVersion)
            and tonumber(record.persistenceSourceVersion)
                < tonumber(Const.PERSISTENCE_VERSION)
        and Inventory
        and Inventory.EnsureRecordInventory
        and Inventory.Serialize
    then
        Inventory.EnsureRecordInventory(record)
        return Inventory.Serialize(record)
    end
    return Core.DeepCopy(record.persistedInventory)
end

local function serializeSkillBaseLevels(record)
    local levels
    if not Types or not Types.Internal
        or not Types.Internal.NormalizeSkillLevels
    then
        return nil
    end
    levels = Types.Internal.NormalizeSkillLevels(record.skillBaseLevels)
    return Internal.hasTableEntries(levels) and levels or nil
end

local function addBodyHint(payload, record)
    local startupBodyHint = record.runtime
        and record.runtime.startupBodyHint or nil
    if record.liveBodyInstanceID == nil and not startupBodyHint then
        return
    end
    payload.bodyHint = {
        instanceID = record.liveBodyInstanceID
            or startupBodyHint and startupBodyHint.instanceID or nil,
        onlineID = record.liveBodyOnlineID
            or startupBodyHint and startupBodyHint.onlineID or nil,
        lease = record.runtime and record.runtime.bodyLease
            or startupBodyHint and startupBodyHint.lease or nil,
        x = Internal.normalizeNumber(record.x, 0),
        y = Internal.normalizeNumber(record.y, 0),
        z = Internal.normalizeNumber(record.z, 0),
    }
end

local function serializeOrderSpec(record)
    local order = record and record.orderSpec or nil
    if type(order) ~= "table"
        or tostring(order.kind or "") == "facility_activity"
    then
        return nil
    end
    return Internal.sanitizeOrderSpec(order, record)
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
    local progression
    local payload
    local inventoryPayload
    local recipeKnowledge
    if not record or record.persist == false then
        return nil
    end
    identity = Internal.sanitizeIdentity(record.identity, record)
    progression = prepareProgression(record)
    inventoryPayload = serializeInventory(record)
    recipeKnowledge = PNC.RecipeKnowledge
        and PNC.RecipeKnowledge.Serialize(record) or nil
    payload = {
        schemaVersion = Const.PERSISTENCE_VERSION,
        recordRevision = math.max(0, math.floor(Internal.normalizeNumber(record.recordRevision, 0))),
        repairVersions = Persistence.Repairs
            and Persistence.Repairs.CopyVersions(
                record.persistenceRepairVersions
            ) or nil,
        id = record.id,
        uniqueDefinitionId = Internal.normalizeString(
            record.uniqueDefinitionId
        ),
        uniqueDefinitionVersion = tonumber(record.uniqueDefinitionVersion)
            and math.max(1, math.floor(tonumber(record.uniqueDefinitionVersion)))
            or nil,
        inventoryTemplateRef = Internal.normalizeString(
            record.inventoryTemplateRef
        ),
        startingItems = not record.inventoryTemplateRef
            and Internal.hasTableEntries(record.startingItems)
            and Core.DeepCopy(record.startingItems) or nil,
        skillBaseLevels = serializeSkillBaseLevels(record),
        tacticalClass = record.tacticalClass,
        ownerUsername = Internal.normalizeString(record.ownerUsername),
        identity = identity,
        m = MemoryEvents
            and MemoryEvents.Serialize(record.memory) or nil,
        position = {
            x = Internal.normalizeNumber(record.x, 0),
            y = Internal.normalizeNumber(record.y, 0),
            z = Internal.normalizeNumber(record.z, 0),
        },
        spawn = {
            x = Internal.normalizeNumber(record.spawnX, record.x),
            y = Internal.normalizeNumber(record.spawnY, record.y),
            z = Internal.normalizeNumber(record.spawnZ, record.z),
        },
        anchor = {
            x = Internal.normalizeNumber(record.anchorX, record.x),
            y = Internal.normalizeNumber(record.anchorY, record.y),
            z = Internal.normalizeNumber(record.anchorZ, record.z),
        },
        orderSpec = serializeOrderSpec(record),
        patrolPoints = Internal.serializePatrolPoints(record),
        patrolIndex = record.orderSpec
                and tostring(record.orderSpec.kind or "")
                    == tostring(Const.ORDER_PATROL or "patrol")
            and math.max(1, math.floor(Internal.normalizeNumber(record.patrolIndex, 1)))
            or nil,
        hostility = Internal.sanitizeHostility(record.hostility, record.tacticalClass),
        health = Internal.serializeHealth(record.health, record.health and record.health.max or Const.DEFAULT_HP_MAX),
        stamina = Internal.serializeStamina(record.stamina),
        weaponMode = tostring(record.weaponMode or "melee"),
        attackType = PNC.Types and PNC.Types.NormalizeAttackType
            and PNC.Types.NormalizeAttackType(record.attackType, record.weaponMode)
            or tostring(record.attackType or record.weaponMode or "melee"),
        equipmentSpawnMode = Internal.normalizeString(record.equipmentSpawnMode),
        equipmentPoolID = Internal.normalizeString(record.equipmentPoolID) or "Default",
        equipment = {
            primaryFullType = Internal.normalizeString(record.equipment and record.equipment.primaryFullType),
            secondaryFullType = Internal.normalizeString(record.equipment and record.equipment.secondaryFullType),
            worn = Internal.copyStringMap(record.equipment and record.equipment.worn),
            wornVisuals = record.equipment
                and record.equipment.wornVisuals
                and Core.DeepCopy(record.equipment.wornVisuals)
                or {},
            attached = Internal.copyStringMap(record.equipment and record.equipment.attached),
        },
        allowedJobs = type(record.allowedJobs) == "table"
            and Core.DeepCopy(record.allowedJobs) or {},
        jobPriorities = type(record.jobPriorities) == "table"
                and Internal.hasTableEntries(record.jobPriorities)
            and Core.DeepCopy(record.jobPriorities) or nil,
        inventory = inventoryPayload,
        social = serializeSocial(record),
        semanticCognition = PNC.Semantics
            and PNC.Semantics.CognitionProjection
            and PNC.Semantics.CognitionProjection.Serialize(
                record.semanticCognition,
                record.id
            ) or nil,
        semanticActionPlan = serializeSemanticActionPlan(record),
        followerAbandonment = Internal.sanitizeFollowerAbandonment(
            record.followerAbandonment
        ),
        colonistDeparture = Internal.sanitizeColonistDeparture(
            record.colonistDeparture
        ),
        affiliation = FactionTypes
            and FactionTypes.NormalizeAffiliation(
                record.affiliation
            ) or nil,
        progression = progression,
        recipeKnowledge = recipeKnowledge,
        corpse = Internal.sanitizeCorpse(record.corpse, record),
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
    addBodyHint(payload, record)
    return payload
end

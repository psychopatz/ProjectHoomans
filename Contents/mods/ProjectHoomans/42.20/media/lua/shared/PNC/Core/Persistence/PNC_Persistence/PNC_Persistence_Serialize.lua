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

local function prepareProgression(record)
    local progression = Internal.sanitizeProgression(record.progression)
    if Internal.hasTableEntries(progression.legacySkillLevels) then
        for skillID, level in pairs(progression.legacySkillLevels) do
            local base = PNC.Skills and PNC.Skills.GetBaseLevel
                and PNC.Skills.GetBaseLevel(record, skillID) or 0
            progression.skillLevelDeltas[skillID] = math.max(
                -10,
                math.min(10, level - base)
            )
        end
    end
    progression.legacySkillLevels = nil
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

function Persistence.SerializeRecord(record)
    local identity
    local progression
    local payload
    local inventoryPayload
    if not record or record.persist == false then
        return nil
    end
    identity = Internal.sanitizeIdentity(record.identity, record)
    progression = prepareProgression(record)
    inventoryPayload = serializeInventory(record)
    payload = {
        schemaVersion = Const.PERSISTENCE_VERSION,
        recordRevision = math.max(0, math.floor(Internal.normalizeNumber(record.recordRevision, 0))),
        id = record.id,
        persist = record.persist ~= false,
        faction = record.faction,
        ownerUsername = Internal.normalizeString(record.ownerUsername),
        identity = identity,
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
        presenceState = record.alive == false and Const.PRESENCE_CORPSE or Const.PRESENCE_ABSTRACT,
        orderSpec = Internal.sanitizeOrderSpec(record.orderSpec, record),
        patrolPoints = Internal.serializePatrolPoints(record),
        patrolIndex = record.orderSpec
                and tostring(record.orderSpec.kind or "")
                    == tostring(Const.ORDER_PATROL or "patrol")
            and math.max(1, math.floor(Internal.normalizeNumber(record.patrolIndex, 1)))
            or nil,
        hostility = Internal.sanitizeHostility(record.hostility, record.faction),
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
        inventory = inventoryPayload,
        social = Internal.sanitizeSocial(
            record.social,
            record.identitySeed,
            record.archetypeID
        ),
        affiliation = FactionTypes
            and FactionTypes.NormalizeAffiliation(
                record.affiliation
            ) or nil,
        progression = progression,
        corpse = Internal.sanitizeCorpse(record.corpse, record),
        travel = PNC.Travel
            and PNC.Travel.Model
            and PNC.Travel.Model.BuildSummary
            and PNC.Travel.Model.BuildSummary(record.travel, true)
            or nil,
        mapPresentation = PNC.MapPresentation
            and PNC.MapPresentation.BuildSummary(record.mapPresentation)
            or nil,
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
        dynamicTraitsGenerationVersion = math.max(0, math.floor(
            tonumber(record.dynamicTraitsGenerationVersion) or 0
        )),
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

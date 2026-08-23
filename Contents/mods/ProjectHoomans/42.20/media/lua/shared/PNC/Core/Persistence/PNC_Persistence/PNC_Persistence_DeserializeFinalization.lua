PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity

local function restoreTraits(record, raw)
    local vanilla = raw.vanillaTraits or raw.physiologicalTraits
    local vanillaAuthored = raw.vanillaTraitsAuthored == true
        or (raw.vanillaTraitsAuthored == nil
            and Internal.hasTableEntries(vanilla))
    local vanillaVersion = math.max(0, math.floor(
        tonumber(raw.vanillaTraitsGenerationVersion) or 0
    ))
    if PNC.PlayerNeedsModel
        and (vanillaAuthored or vanillaVersion > 0)
    then
        record.vanillaTraits = PNC.PlayerNeedsModel.NormalizeTraits(vanilla)
        record.vanillaTraitsAuthored = vanillaAuthored
        record.vanillaTraitsGenerationVersion = vanillaAuthored
            and 0 or vanillaVersion
    end

    local dynamic = raw.dynamicTraits or raw.pncTraits
    local dynamicAuthored = raw.dynamicTraitsAuthored == true
        or (raw.dynamicTraitsAuthored == nil
            and Internal.hasTableEntries(dynamic))
    local dynamicVersion = math.max(0, math.floor(
        tonumber(raw.dynamicTraitsGenerationVersion) or 0
    ))
    if PNC.ConditionStats
        and (dynamicAuthored or dynamicVersion > 0)
    then
        record.dynamicTraits = PNC.ConditionStats.NormalizeTraits(dynamic)
        record.dynamicTraitsAuthored = dynamicAuthored
        record.dynamicTraitsGenerationVersion = dynamicAuthored
            and 0 or dynamicVersion
    end
    if PNC.ConditionStats and type(raw.conditionStats) == "table" then
        record.conditionStats = PNC.ConditionStats.NormalizeState(
            raw.conditionStats,
            0
        )
    end
end

local function restoreIdentityAndProgression(
    record,
    raw,
    identity,
    progression
)
    record.corpse = Internal.sanitizeCorpse(raw.corpse, record)
    if record.alive == false and not record.corpse then
        record.corpse = {
            token = nil,
            x = record.x,
            y = record.y,
            z = record.z,
            createdWorldHour = 0,
        }
    end
    Identity.ApplyRecordIdentity(record, {
        archetypeID = raw.archetypeID or record.archetypeID,
        identitySeed = identity and identity.seed or record.identitySeed,
        identity = identity,
        displayName = raw.displayName or raw.name,
        name = raw.displayName or raw.name,
        visualProfile = raw.visualProfile,
        outfit = raw.outfit,
        isFemale = raw.isFemale == true
            or (identity and identity.isFemale == true),
    })
    record.social = Internal.sanitizeSocial(
        raw.social,
        record.identitySeed,
        record.archetypeID
    )
    if Internal.hasTableEntries(progression.legacySkillLevels) then
        for skillID, level in pairs(progression.legacySkillLevels) do
            local base = PNC.Skills and PNC.Skills.GetBaseLevel
                and PNC.Skills.GetBaseLevel(record, skillID) or 0
            record.progression.skillLevelDeltas[skillID] = math.max(
                -10,
                math.min(10, level - base)
            )
        end
    end
end

local function restoreJournalAndTravel(record, raw)
    if PNC.Journals and PNC.Journals.RemoveNPC then
        PNC.Journals.RemoveNPC(record.id)
    end
    if type(raw.npcJournal) == "table"
        and PNC.Journals and PNC.Journals.ImportNPC
    then
        local imported = pcall(
            PNC.Journals.ImportNPC,
            record,
            raw.npcJournal
        )
        if not imported and Core and Core.LogWarn then
            Core.LogWarn("Rejected NPC journal id=" .. tostring(record.id))
        end
    end
    if type(raw.travel) == "table"
        and PNC.Travel
        and PNC.Travel.Model
        and PNC.Travel.Model.Normalize
    then
        record.travel = PNC.Travel.Model.Normalize(
            raw.travel,
            record,
            PNC.Travel.Service and PNC.Travel.Service.WorldHour
                and PNC.Travel.Service.WorldHour()
                or tonumber(raw.travel.lastAdvancedWorldHour)
                or 0
        )
        if record.travel and PNC.Travel.Model.IsActive(record.travel) then
            record.orderSpec = {
                kind = Const.ORDER_TRAVEL or "travel",
                journeyId = record.travel.journeyId,
            }
        end
    end
end

local function restoreBodyHint(record, raw)
    local bodyHint = type(raw.bodyHint) == "table"
        and raw.bodyHint or nil
    if bodyHint and bodyHint.instanceID ~= nil then
        record.runtime.startupBodyHint = {
            instanceID = tostring(bodyHint.instanceID),
            onlineID = tonumber(bodyHint.onlineID),
            lease = Internal.normalizeString(bodyHint.lease),
            x = Internal.normalizeNumber(bodyHint.x, record.x),
            y = Internal.normalizeNumber(bodyHint.y, record.y),
            z = Internal.normalizeNumber(bodyHint.z, record.z),
        }
    end
end

function Internal.FinalizeDeserializedRecord(
    record,
    raw,
    identity,
    progression
)
    restoreTraits(record, raw)
    restoreIdentityAndProgression(record, raw, identity, progression)
    Internal.sanitizeStamina(raw.stamina, record)
    record.inventory = nil
    record.persistedInventory = type(raw.inventory) == "table"
        and Core.DeepCopy(raw.inventory) or nil
    record = Persistence.RebuildRuntime(record)
    restoreJournalAndTravel(record, raw)
    record.persistenceSourceVersion = tonumber(raw.schemaVersion) or 0
    restoreBodyHint(record, raw)
    return record
end


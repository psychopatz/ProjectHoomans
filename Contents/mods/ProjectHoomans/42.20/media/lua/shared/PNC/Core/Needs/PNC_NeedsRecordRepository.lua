-- Needs-owned physiological traits and condition schema restoration.
local Repository = {}

function Repository.RestoreRecord(record, raw)
    local vanilla = raw.vanillaTraits
    local vanillaAuthored = raw.vanillaTraitsAuthored == true
    if PNC.PlayerNeedsModel
        and vanillaAuthored
    then
        record.vanillaTraits = PNC.PlayerNeedsModel.NormalizeTraits(vanilla)
        record.vanillaTraitsAuthored = vanillaAuthored
        record.vanillaTraitsGenerationVersion = 0
    end
    if PNC.PlayerNeedsModel and PNC.PlayerNeedsModel.EnsureTraits then
        PNC.PlayerNeedsModel.EnsureTraits(record)
    end

    local dynamic = raw.dynamicTraits
    local dynamicAuthored = raw.dynamicTraitsAuthored == true
    if PNC.ConditionStats
        and dynamicAuthored
    then
        record.dynamicTraits = PNC.ConditionStats.NormalizeTraits(dynamic)
        record.dynamicTraitsAuthored = dynamicAuthored
        record.dynamicTraitsGenerationVersion = 0
    end
    if PNC.ConditionStats and PNC.ConditionStats.EnsureTraits then
        PNC.ConditionStats.EnsureTraits(record)
    end
    if PNC.NPCTraits and PNC.NPCTraits.Fingerprint then
        record.dynamicTraitFingerprint = PNC.NPCTraits.Fingerprint(
            record.dynamicTraits or {})
    end
    if PNC.ConditionStats and type(raw.conditionStats) == "table" then
        record.conditionStats = PNC.ConditionStats.NormalizeState(
            raw.conditionStats,
            0
        )
    end
end

return Repository

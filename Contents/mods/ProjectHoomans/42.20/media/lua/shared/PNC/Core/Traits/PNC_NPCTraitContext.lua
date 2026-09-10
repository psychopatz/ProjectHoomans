-- Shared, normalized NPC trait context for conversation and rule evaluation.
-- Physiological and dynamic traits remain separate on the record, but gates
-- need one read-only set when evaluating an NPC conversation.

PNC = PNC or {}
PNC.NPCTraitContext = PNC.NPCTraitContext or {}

local TraitContext = PNC.NPCTraitContext

local function addSource(output, source)
    if type(source) ~= "table" then return end
    for key, enabled in pairs(source) do
        local id = type(key) == "number" and enabled or key
        if id ~= nil and (type(key) == "number" or enabled == true) then
            id = tostring(id)
            output[id] = true
            output[string.lower(id)] = true
        end
    end
end

function TraitContext.Collect(record)
    local output = {}
    if type(record) ~= "table" then return output end

    if PNC.PlayerNeedsModel
        and PNC.PlayerNeedsModel.GetTraits
    then
        addSource(output, PNC.PlayerNeedsModel.GetTraits(record))
    else
        addSource(output, record.vanillaTraits)
    end

    if PNC.ConditionStats
        and PNC.ConditionStats.NormalizeTraits
    then
        addSource(output, PNC.ConditionStats.NormalizeTraits(
            record.dynamicTraits
        ))
    else
        addSource(output, record.dynamicTraits)
    end

    -- Preserve compatibility with older snapshots and external records.
    addSource(output, record.traits)
    addSource(output, record.socialTraits)
    return output
end

return TraitContext

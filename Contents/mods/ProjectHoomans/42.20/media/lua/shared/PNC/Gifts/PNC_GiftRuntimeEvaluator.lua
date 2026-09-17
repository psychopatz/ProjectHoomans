-- Runtime bridge from an NPC record to the pure gift evaluator.
--
-- This bridge is intentionally read-only.  It creates a transient profile
-- from record.identitySeed and returns a bounded evaluation; callers remain
-- responsible for relationship mutation, inventory transfer, and dialogue.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Runtime = Foundation.RuntimeEvaluator or {}
Foundation.RuntimeEvaluator = Runtime

local function knownFacts(facts)
    if type(facts) ~= "table" then return false end
    if facts.marketSenseSource == "api_unavailable"
        or facts.marketSenseSource == "price_details_unavailable"
    then
        return false
    end
    return (tonumber(facts.price) or 0) > 0
        or #(facts.marketSenseTags or {}) > 0
        or tostring(facts.primary or "") ~= ""
end

function Runtime.Evaluate(record, itemTypes, options)
    record = type(record) == "table" and record or {}
    options = type(options) == "table" and options or {}
    local adapter = Foundation.MarketSenseAdapter
    local profile = Foundation.PreferenceProfile
    local evaluator = Foundation.Evaluator
    if not adapter or not profile or not evaluator then
        return nil, "gift_foundation_unavailable"
    end
    local entries = {}
    local known = 0
    local index
    local fullType
    local facts
    local marketOptions = options.marketSenseOptions or options
    for index = 1, #(itemTypes or {}) do
        fullType = tostring(itemTypes[index] or "")
        if fullType ~= "" then
            facts = adapter.BuildFacts(fullType, nil, marketOptions)
            if knownFacts(facts) then known = known + 1 end
            entries[#entries + 1] = {
                fullType = fullType,
                quantity = 1,
                facts = facts,
            }
        end
    end
    if known == 0 or #entries == 0 then
        return nil, "marketsense_unavailable"
    end
    local personality = options.personality
        or record.personality
        or record.social and record.social.personality
        or record.socialProfile and record.socialProfile.personality
    local evaluationOptions = {}
    local key
    local value
    for key, value in pairs(options) do
        if key ~= "marketSenseOptions" then
            evaluationOptions[key] = value
        end
    end
    evaluationOptions.personality = personality
    local generatedProfile = profile.FromNPC(record, options)
    return evaluator.Evaluate(entries, generatedProfile, evaluationOptions),
        "evaluated"
end

return Runtime

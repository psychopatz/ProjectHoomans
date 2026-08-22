PNC = PNC or {}
PNC.FarmingResearch = PNC.FarmingResearch or {}

local Research = PNC.FarmingResearch

-- These are deliberately data-only for now.  The server adapter owns the
-- actual vanilla plant mutations so future research can unlock the same
-- effects without moving authority into the client UI.
Research.EFFECTS = Research.EFFECTS or {
    fast_growth = {
        id = "fast_growth",
        displayKey = "UI_PNC_Farming_DebugFastGrowth",
        fallback = "FAST GROWTH",
    },
    boost_yield = {
        id = "boost_yield",
        displayKey = "UI_PNC_Farming_DebugBoostYield",
        fallback = "BOOST YIELD",
    },
    fertilize = {
        id = "fertilize",
        displayKey = "UI_PNC_Farming_DebugFertilize",
        fallback = "ADD FERTILIZER",
    },
    gmo_upgrade = {
        id = "gmo_upgrade",
        displayKey = "UI_PNC_Farming_DebugGMO",
        fallback = "GMO UPGRADE",
    },
}

local ALIASES = {
    grow = "fast_growth",
    fertilizer = "fertilize",
    gmo = "gmo_upgrade",
}

function Research.NormalizeEffect(value)
    local effect = string.lower(tostring(value or ""))
    effect = ALIASES[effect] or effect
    return Research.EFFECTS[effect] and effect or nil
end

function Research.Get(effect)
    local id = Research.NormalizeEffect(effect)
    return id and Research.EFFECTS[id] or nil
end

function Research.List()
    local output = {}
    for _, effect in pairs(Research.EFFECTS) do
        output[#output + 1] = effect
    end
    table.sort(output, function(a, b) return a.id < b.id end)
    return output
end

return Research

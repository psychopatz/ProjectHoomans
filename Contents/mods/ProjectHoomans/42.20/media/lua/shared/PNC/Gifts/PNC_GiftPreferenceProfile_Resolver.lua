-- Preference matching: authored overrides first, seeded taxonomy second.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Profile = PNC.Gifts.Foundation.PreferenceProfile

local function normalized(value)
    value = string.lower(tostring(value or ""))
    return string.gsub(value, "[^%w]", "")
end

local function bounded(value, maximum)
    value = tostring(value or "")
    if #value > (maximum or 96) then
        return string.sub(value, 1, maximum or 96)
    end
    return value
end

local function overrideMatch(profile, facts)
    local overrides = profile and profile.overrides
    if type(overrides) ~= "table" or type(facts) ~= "table" then
        return nil
    end
    local fields = {
        { "exact", facts.fullType },
        { "leaf", facts.leafKey or facts.leaf },
        { "subcategory", facts.subcategoryKey or facts.subcategory },
        { "tag", facts.expandedTags },
        { "tag", facts.tags },
        { "category", facts.categoryKey or facts.category },
        { "any", facts.fullType },
    }
    local fieldIndex
    local dispositionIndex
    local field
    local disposition
    local value
    local key
    for fieldIndex = 1, #fields do
        field = fields[fieldIndex]
        for dispositionIndex = 1, #Profile.DISPOSITION_ORDER do
            disposition = Profile.DISPOSITION_ORDER[dispositionIndex]
            local map = overrides[disposition]
                and overrides[disposition][field[1]] or nil
            if type(map) == "table" then
                if type(field[2]) == "table" then
                    for _, value in ipairs(field[2]) do
                        key = normalized(value)
                        if key ~= "" and map[key] then
                            return disposition, field[1], key
                        end
                    end
                else
                    key = normalized(field[2])
                    if key ~= "" and map[key] then
                        return disposition, field[1], key
                    end
                end
            end
        end
    end
    return nil
end

local function candidates(facts)
    local output = {}
    local seen = {}
    local index
    local candidate
    if type(facts) ~= "table" then return output end
    for index = 1, #(facts.preferenceCandidates or {}) do
        candidate = facts.preferenceCandidates[index]
        if type(candidate) == "table" then
            local key = normalized(candidate.key or candidate.value)
            if key ~= "" and not seen[key] then
                seen[key] = true
                output[#output + 1] = {
                    type = bounded(candidate.type, 32),
                    key = key,
                    priority = tonumber(candidate.priority) or 1,
                }
            end
        end
    end
    if #output == 0 then
        local function add(candidateType, value, priority)
            local key = normalized(value)
            if key ~= "" and key ~= "general" and not seen[key] then
                seen[key] = true
                output[#output + 1] = {
                    type = candidateType, key = key, priority = priority,
                }
            end
        end
        add("leaf", facts.leafKey or facts.leaf, 5)
        add("subcategory", facts.subcategoryKey or facts.subcategory, 4)
        for index = 1, #(facts.expandedTags or {}) do
            add("tag", facts.expandedTags[index], 3)
        end
        for index = 1, #(facts.tags or {}) do
            add("tag", facts.tags[index], 2)
        end
        add("category", facts.categoryKey or facts.category, 1)
    end
    return output
end

function Profile.Resolve(profile, facts)
    facts = type(facts) == "table" and facts or {}
    if type(profile) ~= "table" then
        return {
            disposition = "neutral", multiplier = 1, confidence = 0,
            generated = false, reason = "profile_unavailable",
        }
    end
    local disposition
    local matchType
    local matchKey
    disposition, matchType, matchKey = overrideMatch(profile, facts)
    if disposition then
        return {
            disposition = disposition,
            multiplier = Profile.MULTIPLIERS[disposition] or 1,
            confidence = 1, generated = false,
            reason = "authored_override",
            matchType = matchType, matchKey = matchKey,
        }
    end
    local best
    local index
    local candidate
    local generated
    local strength
    local priority
    local weighted
    local candidateValues = candidates(facts)
    for index = 1, #candidateValues do
        candidate = candidateValues[index]
        generated = Profile.GeneratedDisposition(profile, candidate.key)
        strength = Profile.STRENGTH[generated] or 0
        priority = math.max(1, math.min(5,
            tonumber(candidate.priority) or 1))
        weighted = strength * (0.50 + (priority / 5) * 0.50)
        if weighted ~= 0
            and (not best or math.abs(weighted) > math.abs(best.weighted)) then
            best = {
                disposition = generated, weighted = weighted,
                type = candidate.type, key = candidate.key,
                priority = priority,
            }
        end
    end
    if not best then
        return {
            disposition = "neutral", multiplier = 1, confidence = 0.25,
            generated = true, reason = "no_specific_taxonomy_key",
        }
    end
    return {
        disposition = best.disposition,
        multiplier = Profile.MULTIPLIERS[best.disposition] or 1,
        confidence = math.max(0.35, math.min(0.85,
            0.35 + best.priority * 0.10)),
        generated = true,
        reason = "identity_seed_taxonomy_match",
        matchType = best.type,
        matchKey = best.key,
    }
end

return Profile

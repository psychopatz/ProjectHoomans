-- Pure target-query and observed-object matching for client world hints.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local Matcher = {}

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum)
    if maximum and #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function split(value)
    local output = {}
    for token in string.gmatch(text(value), "%S+") do
        output[#output + 1] = token
    end
    return output
end

local function swapped(a, b)
    if #a ~= #b then return false end
    local first
    local second
    for index = 1, #a do
        if string.sub(a, index, index) ~= string.sub(b, index, index) then
            if not first then
                first = index
            elseif not second then
                second = index
            else
                return false
            end
        end
    end
    return first ~= nil and second ~= nil
        and string.sub(a, first, first) == string.sub(b, second, second)
        and string.sub(a, second, second) == string.sub(b, first, first)
end

local function editDistance(a, b)
    if a == b then return 0 end
    local previous = {}
    local current = {}
    local index
    for index = 0, #b do previous[index] = index end
    for index = 1, #a do
        current[0] = index
        for other = 1, #b do
            local cost = string.sub(a, index, index)
                == string.sub(b, other, other) and 0 or 1
            current[other] = math.min(
                current[other - 1] + 1,
                previous[other] + 1,
                previous[other - 1] + cost
            )
        end
        previous, current = current, previous
    end
    return previous[#b] or math.max(#a, #b)
end

local function wordScore(left, right)
    left = Catalog.Normalize(left)
    right = Catalog.Normalize(right)
    if left == "" or right == "" then return 0 end
    if left == right then return 1 end
    if swapped(left, right) then return 0.90 end
    local shorter = math.min(#left, #right)
    if shorter >= 4
        and string.sub(left, 1, shorter) == string.sub(right, 1, shorter)
    then
        return 0.84
    end
    local maximum = math.max(#left, #right)
    local distance = editDistance(left, right)
    local allowed = math.max(1, math.floor(maximum * 0.34))
    if distance <= allowed then
        return math.max(0, 1 - distance / math.max(1, maximum))
    end
    return 0
end

local function phraseScore(query, alias)
    query = Catalog.Normalize(query)
    alias = Catalog.Normalize(alias)
    if query == "" or alias == "" then return 0 end
    if query == alias then return 1 end
    if string.find(alias, query, 1, true)
        or string.find(query, alias, 1, true)
    then
        return 0.92
    end

    local queryTokens = split(query)
    local aliasTokens = split(alias)
    local total = 0
    local best
    for index = 1, #queryTokens do
        best = 0
        for other = 1, #aliasTokens do
            best = math.max(best,
                wordScore(queryTokens[index], aliasTokens[other]))
        end
        total = total + best
    end
    if #queryTokens == 0 then return 0 end
    return total / #queryTokens
end

local function profileAliasScore(query, profile)
    local best = 0
    for index = 1, #(profile and profile.aliases or {}) do
        best = math.max(best, phraseScore(query, profile.aliases[index]))
    end
    return best
end

function Matcher.TargetQuery(target)
    if type(target) ~= "table" then return "" end
    return text(target.text or target.value or target.category
        or target.concept or target.id, 64)
end

function Matcher.ProfilesFor(target, query, minimumProfileMargin)
    local output = {}
    local exact = Catalog.ResolveKind(target)
    local profile = exact and Catalog.Get(exact) or nil
    if profile then
        output[1] = profile
        return output, { exact = true, score = 1 }
    end

    local bestProfile
    local bestScore = 0
    local secondScore = 0
    for _, candidate in ipairs(Catalog.List()) do
        local score = profileAliasScore(query, candidate)
        if score > bestScore then
            secondScore = bestScore
            bestScore = score
            bestProfile = candidate
        elseif score > secondScore then
            secondScore = score
        end
    end
    if not bestProfile or bestScore < 0.55 then
        return output, {
            reason = "target_profile_unavailable",
            score = bestScore,
            secondScore = secondScore,
        }
    end
    if secondScore > 0
        and bestScore - secondScore < minimumProfileMargin
    then
        return output, {
            reason = "ambiguous_target_profile",
            score = bestScore,
            secondScore = secondScore,
        }
    end
    output[1] = bestProfile
    return output, {
        score = bestScore,
        secondScore = secondScore,
    }
end

local function objectLabelScore(query, metadata)
    local best = 0
    for index = 1, #(metadata and metadata.labels or {}) do
        best = math.max(best, phraseScore(query, metadata.labels[index]))
    end
    return best
end

local function candidateKey(candidate)
    return tostring(candidate.x) .. ":" .. tostring(candidate.y)
        .. ":" .. tostring(candidate.z) .. ":" .. tostring(candidate.kind)
end

function Matcher.AddCandidate(candidates, profile, observation,
    originX, originY, originZ, query)
    local metadata = observation and observation.metadata or {}
    if not observation or not Catalog.Matches(profile.kind, metadata) then
        return
    end
    local x = number(observation.x)
    local y = number(observation.y)
    local z = number(observation.z) or originZ
    if x == nil or y == nil or z ~= originZ then return end
    local dx = x - originX
    local dy = y - originY
    local distanceSq = dx * dx + dy * dy
    local score = math.max(
        profileAliasScore(query, profile),
        objectLabelScore(query, metadata)
    )
    score = math.min(1, score + 0.04)
    candidates[#candidates + 1] = {
        kind = profile.kind,
        label = text(profile.label, 64),
        commandName = text(profile.commandName, 64),
        targetID = text(observation.targetID or observation.objectKey,
            128),
        resourceKey = text(observation.resourceKey or observation.objectKey,
            128),
        x = x,
        y = y,
        z = z,
        score = score,
        distanceSq = distanceSq,
        source = "client_loaded_world",
    }
end

function Matcher.SortCandidates(candidates)
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return candidateKey(left) < candidateKey(right)
    end)
end


Matcher.Number = number
Matcher.Text = text

return Matcher

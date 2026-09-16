-- Small, side-effect-free entity-name index for semantic dialogue.
--
-- Callers provide already-authorized scalar candidates. This module does not
-- inspect the world or infer hidden identities; it only performs exact
-- normalized-name matching and reports ambiguity explicitly.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Resolver = PNC.Semantics.EntityResolver or {}
PNC.Semantics.EntityResolver = Resolver

Resolver.VERSION = 1
Resolver.MAX_CANDIDATES = 64
Resolver.MAX_ALIASES_PER_CANDIDATE = 8

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copy(item, depth + 1)
        end
    end
    return output
end

local function stringValue(value)
    if value == nil then return nil end
    value = tostring(value)
    return value ~= "" and value or nil
end

function Resolver.NormalizeName(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w%s']", " ")
    value = string.gsub(value, "%s+", " ")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function appendUnique(list, seen, value)
    value = stringValue(value)
    if not value or seen[value] then return false end
    list[#list + 1] = value
    seen[value] = true
    return true
end

local function sourceAliases(candidate)
    local aliases = {}
    local seen = {}
    local source = candidate.names or candidate.aliases
    local index
    local value
    if type(source) == "string" then
        appendUnique(aliases, seen, source)
    elseif type(source) == "table" then
        for index = 1, #source do
            appendUnique(aliases, seen, source[index])
            if #aliases >= Resolver.MAX_ALIASES_PER_CANDIDATE then
                break
            end
        end
        if #aliases == 0 then
            for _, alias in pairs(source) do
                appendUnique(aliases, seen, alias)
                if #aliases >= Resolver.MAX_ALIASES_PER_CANDIDATE then
                    break
                end
            end
        end
    end
    for _, key in ipairs({
        "name", "displayName", "fullName", "firstName", "forename",
        "lastName", "surname",
    }) do
        if #aliases >= Resolver.MAX_ALIASES_PER_CANDIDATE then break end
        appendUnique(aliases, seen, candidate[key])
    end
    return aliases
end

local function normalizedCandidate(candidate)
    if type(candidate) ~= "table" then return nil end
    if candidate.known == false or candidate.authorized == false then
        return nil
    end
    local id = stringValue(
        candidate.id or candidate.entityID or candidate.npcID
            or candidate.uuid
    )
    if not id then return nil end
    local aliases = sourceAliases(candidate)
    if #aliases <= 0 then return nil end
    return {
        id = id,
        entityType = stringValue(
            candidate.entityType or candidate.kind or candidate.type
        ) or "entity",
        name = stringValue(
            candidate.name or candidate.displayName or aliases[1]
        ) or aliases[1],
        aliases = aliases,
        source = stringValue(candidate.source),
    }
end

local function addEntry(index, candidate, alias)
    local normalized = Resolver.NormalizeName(alias)
    if normalized == "" then return end
    local entries = index.byName[normalized]
    if not entries then
        entries = {}
        index.byName[normalized] = entries
    end
    for _, existing in ipairs(entries) do
        if existing.id == candidate.id then return end
    end
    entries[#entries + 1] = candidate
end

function Resolver.BuildIndex(candidates)
    local index = {
        version = Resolver.VERSION,
        byName = {},
        candidates = {},
    }
    if type(candidates) ~= "table" then return index end

    local count = 0
    for _, raw in ipairs(candidates) do
        if count >= Resolver.MAX_CANDIDATES then break end
        local candidate = normalizedCandidate(raw)
        if candidate then
            index.candidates[#index.candidates + 1] = candidate
            count = count + 1
            for _, alias in ipairs(candidate.aliases) do
                addEntry(index, candidate, alias)
            end
        end
    end
    return index
end

local function validIndex(index)
    return type(index) == "table" and type(index.byName) == "table"
end

function Resolver.Resolve(value, index)
    if type(value) ~= "table"
        or value.unresolved ~= true
        or value.reference ~= nil
    then
        return nil, "not_an_entity_candidate"
    end
    if not validIndex(index) then return nil, "entity_index_unavailable" end

    local query = Resolver.NormalizeName(value.text or value.value)
    if query == "" then return nil, "entity_name_empty" end
    local entries = index.byName[query] or {}
    if #entries == 0 then return nil, "unknown_entity" end
    if #entries > 1 then
        return nil, "ambiguous_entity", copy(entries)
    end

    local candidate = entries[1]
    return {
        id = candidate.id,
        entityType = candidate.entityType,
        name = candidate.name,
        text = candidate.name,
        value = candidate.name,
        unresolved = false,
    }, "exact_name", copy(candidate)
end

return Resolver

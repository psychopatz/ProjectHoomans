-- Seed-selected facts stay computed; only a small stable-ID selection delta is
-- persisted.  Definitions remain the authoritative source for every fact.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Data = Memory._registry
local PROFILE_CACHE_LIMIT = 256
local BACKSTORY_METADATA_SCHEMA_VERSION = 1
local BACKSTORY_SELECTION_LIMIT = 64
local CLASSES = { "shared", "colonist", "neutral", "hostile" }
local CLASS_SET = {
    shared = true,
    colonist = true,
    neutral = true,
    hostile = true,
}

Memory.BACKSTORY_CATALOG_VERSION = tonumber(
    Memory.BACKSTORY_CATALOG_VERSION
) or 1

local function normalizeTags(raw)
    local tags = {}
    local seen = {}
    if type(raw) ~= "table" then
        return tags
    end
    for i = 1, math.min(#raw, 12) do
        local tag = tostring(raw[i] or "")
        if tag ~= "" and not seen[tag] then
            seen[tag] = true
            tags[#tags + 1] = tag
        end
    end
    return tags
end

local function newBucket()
    return { entries = {}, cumulativeWeights = {}, totalWeight = 0 }
end

local function appendToBucket(class, entry)
    local classBuckets = Data.backstoryBuckets[class]
    local bucket = classBuckets[entry.kind]
    if not bucket then
        bucket = newBucket()
        classBuckets[entry.kind] = bucket
    end
    bucket.totalWeight = bucket.totalWeight + entry.weight
    bucket.entries[#bucket.entries + 1] = entry
    bucket.cumulativeWeights[#bucket.cumulativeWeights + 1] =
        bucket.totalWeight
end

local function clearProfileCache()
    Data.profileCache = {}
    Data.profileOrder = {}
    Data.profileCount = 0
    Data.profileNext = 1
end

local function normalizeStableID(value)
    if value == nil or value == "" then
        return nil
    end
    local result = tostring(value)
    if result == "" or #result > 160 then
        return nil
    end
    return result
end

local function copyStableIDMap(raw)
    local output = {}
    local count = 0
    local key
    local value
    if type(raw) ~= "table" then
        return output
    end
    for key, value in pairs(raw) do
        if count >= BACKSTORY_SELECTION_LIMIT then
            break
        end
        key = normalizeStableID(key)
        value = normalizeStableID(value)
        if key and value then
            output[key] = value
            count = count + 1
        end
    end
    return output
end

local function hasEntries(value)
    local _
    for _, _ in pairs(value or {}) do
        return true
    end
    return false
end

local function isClass(value)
    value = string.lower(tostring(value or ""))
    return CLASS_SET[value] and value or nil
end

local function markMetadataDirty(record, changed)
    local core = PNC.Core
    if not changed or not core or type(core.IsAuthority) ~= "function"
        or not core.IsAuthority()
        or not PNC.Registry
        or type(PNC.Registry.MarkDirty) ~= "function"
    then
        return
    end
    PNC.Registry.MarkDirty(record, "backstory_metadata")
end

function Memory.RegisterBackstory(definition)
    if type(definition) ~= "table" then
        return false, "backstory_definition_required"
    end
    local id = tostring(definition.id or "")
    local kind = string.lower(tostring(definition.kind or ""))
    local class = string.lower(tostring(definition.class or ""))
    local value = type(definition.value) == "string"
        and definition.value or nil
    local resolver = type(definition.resolve) == "function"
        and definition.resolve or nil
    if id == "" or kind == "" or not CLASS_SET[class] then
        return false, "invalid_backstory_identity"
    end
    if value == "" then
        value = nil
    end
    if not value and not resolver then
        return false, "backstory_value_or_resolver_required"
    end
    if Data.backstoryByID[id] then
        return false, "duplicate_backstory_id"
    end
    local textKey = type(definition.textKey) == "string"
        and definition.textKey or nil
    if textKey == "" then
        textKey = nil
    end
    local textSource
    if textKey then
        local reason
        textSource, reason = Memory.NormalizeTextSource(
            definition.textSource,
            Memory.BACKSTORY_SOURCE
        )
        if not textSource then
            return false, reason
        end
    end
    local weight = math.max(
        1,
        math.min(10000, math.floor(tonumber(definition.weight) or 1))
    )
    local entry = {
        id = id,
        kind = kind,
        class = class,
        value = value,
        textKey = textKey,
        textSource = textSource,
        tags = normalizeTags(definition.tags),
        weight = weight,
        resolve = resolver,
    }
    Data.backstoryByID[id] = entry
    if not Data.backstoryKindSet[kind] then
        Data.backstoryKindSet[kind] = true
        Data.backstoryKinds[#Data.backstoryKinds + 1] = kind
    end
    if class == "shared" then
        for i = 1, #CLASSES do
            appendToBucket(CLASSES[i], entry)
        end
    else
        appendToBucket(class, entry)
    end
    if textKey then
        Memory.RegisterTextKey(textSource, textKey)
    end
    clearProfileCache()
    return true, entry
end

local function recordContext(record)
    local identity = type(record.identity) == "table" and record.identity or {}
    local rawSeed = identity.seed or record.identitySeed
    local identityAPI = PNC.Identity
    local seed
    if identityAPI and type(identityAPI.NormalizeSeed) == "function" then
        seed = identityAPI.NormalizeSeed(rawSeed, record.id or "pnc_memory")
    else
        seed = math.max(1, math.floor(tonumber(rawSeed) or 1))
    end
    local class = string.lower(tostring(record.tacticalClass or ""))
    if not CLASS_SET[class] then
        class = "shared"
    end
    return seed, class
end

local function chooseBackstory(seed, class, kind)
    local classBuckets = Data.backstoryBuckets[class]
    local bucket = classBuckets and classBuckets[kind]
    if not bucket or bucket.totalWeight <= 0 then
        return nil
    end
    local identityAPI = PNC.Identity
    local roll
    if identityAPI and type(identityAPI.Range) == "function" then
        roll = identityAPI.Range(
            seed,
            "pnc:backstory:" .. kind,
            1,
            bucket.totalWeight
        )
    else
        roll = (seed % bucket.totalWeight) + 1
    end
    local low = 1
    local high = #bucket.cumulativeWeights
    while low < high do
        local middle = math.floor((low + high) / 2)
        if roll <= bucket.cumulativeWeights[middle] then
            high = middle
        else
            low = middle + 1
        end
    end
    return bucket.entries[low]
end

local function selectedEntry(kind, id)
    local entry
    id = normalizeStableID(id)
    if not id then
        return nil
    end
    entry = Data.backstoryByID[id]
    if not entry or entry.kind ~= kind then
        return nil
    end
    return entry
end

local function ensureSelectionMetadata(record, seed, class)
    local identity
    local raw
    local metadata
    local selectionClass
    local generated
    local overrideID
    local kind
    local changed = false
    if type(record) ~= "table" then
        return nil, false
    end
    identity = type(record.identity) == "table" and record.identity or nil
    if not identity then
        return nil, false
    end
    raw = type(identity.backstory) == "table"
        and identity.backstory or nil
    metadata = {
        schemaVersion = BACKSTORY_METADATA_SCHEMA_VERSION,
        catalogVersion = tonumber(raw and raw.catalogVersion)
            and math.max(1, math.floor(tonumber(raw.catalogVersion)))
            or Memory.BACKSTORY_CATALOG_VERSION,
        selectionClass = isClass(raw and raw.selectionClass) or class,
        selections = copyStableIDMap(raw and raw.selections),
        overrides = copyStableIDMap(raw and raw.overrides),
    }
    if not raw
        or tonumber(raw.schemaVersion) ~= BACKSTORY_METADATA_SCHEMA_VERSION
        or tonumber(raw.catalogVersion) ~= metadata.catalogVersion
        or isClass(raw.selectionClass) ~= metadata.selectionClass
    then
        changed = true
    end
    selectionClass = metadata.selectionClass
    for i = 1, #Data.backstoryKinds do
        kind = Data.backstoryKinds[i]
        overrideID = metadata.overrides[kind]
        if overrideID then
            if metadata.selections[kind] ~= overrideID then
                metadata.selections[kind] = overrideID
                changed = true
            end
        elseif not metadata.selections[kind] then
            generated = chooseBackstory(seed, selectionClass, kind)
            if generated then
                metadata.selections[kind] = generated.id
                changed = true
            end
        end
    end
    if not hasEntries(metadata.overrides) then
        metadata.overrides = nil
    end
    if not hasEntries(metadata.selections) then
        if raw then
            identity.backstory = nil
            return nil, true
        end
        return nil, false
    end
    if raw and type(raw.overrides) == "table"
        and hasEntries(metadata.overrides) == false
    then
        changed = true
    end
    identity.backstory = metadata
    return metadata, changed
end

function Memory.EnsureBackstoryMetadata(record)
    local seed
    local class
    local metadata
    local changed
    if type(record) ~= "table" then
        return nil, false
    end
    seed, class = recordContext(record)
    metadata, changed = ensureSelectionMetadata(record, seed, class)
    markMetadataDirty(record, changed)
    return metadata, changed
end

local function resolveBackstory(entry, record)
    if not entry then
        return nil
    end
    if type(entry.resolve) ~= "function" then
        return entry
    end
    local resolved = entry.resolve(record, entry)
    if type(resolved) ~= "table" then
        return nil
    end
    resolved.id = entry.id
    resolved.kind = entry.kind
    resolved.class = entry.class
    return resolved
end

function Memory.GetBackstoryDefinition(id)
    return Data.backstoryByID[tostring(id or "")]
end

function Memory.GetBackstory(record, kind)
    local metadata
    local seed
    local class
    local entry
    if type(record) ~= "table" or type(kind) ~= "string" then
        return nil
    end
    seed, class = recordContext(record)
    metadata = Memory.EnsureBackstoryMetadata(record)
    if metadata then
        entry = selectedEntry(kind, metadata.selections[kind])
        return resolveBackstory(entry, record)
    end
    return resolveBackstory(chooseBackstory(seed, class, kind), record)
end

local function getCachedSelection(seed, class)
    local cacheKey = class .. ":" .. tostring(seed)
    local cached = Data.profileCache[cacheKey]
    if cached then
        return cached
    end
    local definitions = {}
    for i = 1, #Data.backstoryKinds do
        local kind = Data.backstoryKinds[i]
        definitions[kind] = chooseBackstory(seed, class, kind)
    end
    cached = { definitions = definitions }
    if Data.profileCount < PROFILE_CACHE_LIMIT then
        Data.profileCount = Data.profileCount + 1
        Data.profileOrder[Data.profileCount] = cacheKey
    else
        local evictedKey = Data.profileOrder[Data.profileNext]
        if evictedKey then
            Data.profileCache[evictedKey] = nil
        end
        Data.profileOrder[Data.profileNext] = cacheKey
        Data.profileNext = (Data.profileNext % PROFILE_CACHE_LIMIT) + 1
    end
    Data.profileCache[cacheKey] = cached
    return cached
end

function Memory.GetBackstoryProfile(record)
    local metadata
    if type(record) ~= "table" then
        return nil
    end
    local seed, class = recordContext(record)
    metadata = Memory.EnsureBackstoryMetadata(record)
    local selection = getCachedSelection(
        seed,
        metadata and metadata.selectionClass or class
    )
    local facts = {}
    for i = 1, #Data.backstoryKinds do
        local kind = Data.backstoryKinds[i]
        local definition = metadata
            and selectedEntry(kind, metadata.selections[kind])
            or selection.definitions[kind]
        local fact = resolveBackstory(definition, record)
        if fact then
            facts[kind] = fact
        end
    end
    local birth = facts.date_of_birth
    return {
        identitySeed = seed,
        tacticalClass = class,
        facts = facts,
        dateOfBirth = birth,
        age = birth and birth.age or nil,
    }
end

function Memory.GetBackstoryKinds()
    local kinds = {}
    for i = 1, #Data.backstoryKinds do
        kinds[i] = Data.backstoryKinds[i]
    end
    return kinds
end

function Memory.GetBackstoryText(backstory, language)
    local entry = type(backstory) == "table"
        and backstory or Memory.GetBackstoryDefinition(backstory)
    if not entry or not entry.textKey then
        return nil, "backstory_text_unavailable"
    end
    return Memory.GetText(
        entry.textSource or Memory.BACKSTORY_SOURCE,
        entry.textKey,
        language
    )
end

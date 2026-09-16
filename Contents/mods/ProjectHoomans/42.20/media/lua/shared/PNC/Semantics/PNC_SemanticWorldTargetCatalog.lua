-- Data-driven vocabulary for semantic world targets.
--
-- This catalog deliberately contains no Project Zomboid objects and no world
-- lookups.  It is shared by the client observer and the server validator so a
-- client hint and an authoritative server resolution use the same vocabulary
-- without sharing live Java objects.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.WorldTargetCatalog or {}
PNC.Semantics.WorldTargetCatalog = Catalog

Catalog.VERSION = 1
Catalog.Profiles = Catalog.Profiles or {}
Catalog.Order = Catalog.Order or {}
Catalog.Aliases = Catalog.Aliases or {}

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function kindKey(value)
    value = Catalog.Normalize(value)
    return string.gsub(value, "%s+", "_")
end

-- This is a language-key normalizer, not an item-name formatter.  Keep it
-- deterministic and intentionally small so future localization can replace
-- the data without changing the matching code.
function Catalog.Normalize(value)
    value = lower(value)
    value = string.gsub(value, "[%p_]+", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "^(the|a|an|nearest)%s+", "")
    return value
end

local function assetKey(value)
    value = lower(value)
    value = string.gsub(value, "%s+", "")
    return value
end

local function copyList(values, normalizer)
    local output = {}
    if type(values) ~= "table" then return output end
    for index = 1, #values do
        local value = normalizer(values[index])
        if value and value ~= "" then output[#output + 1] = value end
    end
    return output
end

local function addAliases(profile)
    for index = 1, #(profile.aliases or {}) do
        local alias = profile.aliases[index]
        if alias ~= "" then Catalog.Aliases[alias] = profile.kind end
    end
end

function Catalog.Register(kind, definition)
    kind = kindKey(kind)
    if kind == "" or type(definition) ~= "table" then
        return false, "invalid_world_target_profile"
    end

    local existing = Catalog.Profiles[kind]
    local profile = {
        kind = kind,
        label = text(definition.label) or kind,
        aliases = copyList(definition.aliases, Catalog.Normalize),
        spriteNames = copyList(definition.spriteNames, assetKey),
        objectNames = copyList(definition.objectNames, Catalog.Normalize),
        special = text(definition.special),
    }

    if not existing then Catalog.Order[#Catalog.Order + 1] = kind end
    Catalog.Profiles[kind] = profile
    addAliases(profile)
    return true, profile
end

function Catalog.Get(kind)
    return Catalog.Profiles[kindKey(kind)]
end

function Catalog.List()
    local output = {}
    for index = 1, #Catalog.Order do
        local profile = Catalog.Profiles[Catalog.Order[index]]
        if profile then output[#output + 1] = profile end
    end
    return output
end

local function valuesFor(target)
    if type(target) ~= "table" then return { target } end
    return {
        target.kind,
        target.category,
        target.concept,
        target.id,
        target.value,
        target.text,
    }
end

function Catalog.ResolveKind(target)
    local values = valuesFor(target)
    for index = 1, #values do
        local key = kindKey(values[index])
        local mapped = Catalog.Aliases[key]
        if mapped then return mapped end
        if Catalog.Profiles[key] then return key end
    end
    return nil
end

local function contains(values, wanted)
    for index = 1, #(values or {}) do
        local value = values[index]
        if value == wanted
            or string.find(value, wanted, 1, true) ~= nil
        then
            return true
        end
    end
    return false
end

-- `metadata` is intentionally plain data.  Client and server adapters may
-- collect different engine fields, but both can ask this same profile matcher
-- whether those fields describe a target kind.
function Catalog.Matches(kind, metadata)
    local profile = Catalog.Get(kind)
    if not profile or type(metadata) ~= "table" then return false end

    if profile.special and metadata.special == profile.special then
        return true
    end

    local sprites = {}
    for index = 1, #(metadata.spriteNames or {}) do
        sprites[#sprites + 1] = assetKey(metadata.spriteNames[index])
    end
    for index = 1, #profile.spriteNames do
        for spriteIndex = 1, #sprites do
            if sprites[spriteIndex] == profile.spriteNames[index] then
                return true
            end
        end
    end

    local labels = {}
    for index = 1, #(metadata.labels or {}) do
        local normalized = Catalog.Normalize(metadata.labels[index])
        if normalized ~= "" then labels[#labels + 1] = normalized end
    end
    if contains(labels, profile.kind) then return true end
    for index = 1, #profile.aliases do
        if contains(labels, profile.aliases[index]) then return true end
    end
    for index = 1, #profile.objectNames do
        if contains(labels, profile.objectNames[index]) then return true end
    end
    return false
end

-- Initial Project Hoomans profiles.  Adding another target should be a data
-- registration, not a new parser branch or a new client/server scan loop.
Catalog.Register("recycle_bin", {
    label = "recycle bin",
    aliases = {
        "recycle bin", "recycling bin", "trash bin", "garbage bin",
        "bin",
    },
    objectNames = {
        "recycle bin", "recycling bin", "trash bin", "garbage bin",
    },
    spriteNames = { "trashcontainers_01_16" },
})

Catalog.Register("campfire", {
    label = "campfire",
    aliases = { "campfire", "fire pit", "firepit", "fire" },
    objectNames = { "campfire", "fire pit", "firepit" },
    special = "campfire",
})

-- Ordinary IsoObjects can opt into the same wait-at target path through their
-- exposed object/sprite/property labels.  These profiles are intentionally
-- conservative: a profile without matching metadata is ignored rather than
-- guessing from an arbitrary nearby object.
Catalog.Register("bed", {
    label = "bed",
    aliases = { "bed", "cot", "bunk", "sleeping spot" },
    objectNames = { "bed", "cot", "bunk" },
})

Catalog.Register("chair", {
    label = "chair",
    aliases = { "chair", "seat", "bench" },
    objectNames = { "chair", "seat", "bench" },
})

Catalog.Register("door", {
    label = "door",
    aliases = { "door", "doorway", "entrance" },
    objectNames = { "door", "doorway", "entrance" },
})

Catalog.Register("table", {
    label = "table",
    aliases = { "table", "desk", "counter" },
    objectNames = { "table", "desk", "counter" },
})

return Catalog

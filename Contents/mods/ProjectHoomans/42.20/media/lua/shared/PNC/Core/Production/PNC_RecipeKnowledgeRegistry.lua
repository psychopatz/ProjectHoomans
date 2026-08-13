-- Save-stable recipe identity. Only idToKey is canonical persistence; the
-- reverse index and current availability are rebuilt at runtime.

PNC = PNC or {}
PNC.RecipeKnowledgeRegistry = PNC.RecipeKnowledgeRegistry or {}

local Registry = PNC.RecipeKnowledgeRegistry
Registry.SCHEMA_VERSION = 1
Registry.State = Registry.State or {
    schemaVersion = Registry.SCHEMA_VERSION, revision = 0, nextId = 1,
    idToKey = {},
}
Registry.KeyToId = Registry.KeyToId or {}
Registry.Commands = Registry.Commands or {}
Registry.Queries = Registry.Queries or {}

local function clean(raw)
    local state = { schemaVersion = Registry.SCHEMA_VERSION,
        revision = 0, nextId = 1, idToKey = {} }
    local highest = 0
    if type(raw) == "table" and tonumber(raw.schemaVersion) == Registry.SCHEMA_VERSION then
        for id, key in pairs(raw.idToKey or {}) do
            id = math.floor(tonumber(id) or 0)
            if id > 0 and type(key) == "string" and key ~= "" then
                state.idToKey[id] = key
                if id > highest then highest = id end
            end
        end
        state.nextId = math.max(highest + 1,
            math.floor(tonumber(raw.nextId) or 1))
        state.revision = math.max(highest,
            math.floor(tonumber(raw.revision) or 0))
    end
    return state
end

function Registry.Commands.Import(raw)
    Registry.State = clean(raw)
    Registry.KeyToId = {}
    for id, key in pairs(Registry.State.idToKey) do
        if not Registry.KeyToId[key] then Registry.KeyToId[key] = id end
    end
    return Registry.State
end

function Registry.Commands.GetOrCreateId(key)
    key = tostring(key or "")
    if key == "" then return nil, "RECIPE_KEY_REQUIRED" end
    local existing = Registry.KeyToId[key]
    if existing then return existing, false end
    local id = Registry.State.nextId
    Registry.State.nextId = id + 1
    Registry.State.revision = Registry.State.revision + 1
    Registry.State.idToKey[id] = key
    Registry.KeyToId[key] = id
    return id, true
end

function Registry.Queries.GetId(key)
    return Registry.KeyToId[tostring(key or "")]
end
function Registry.Queries.GetKey(id)
    return Registry.State.idToKey[math.floor(tonumber(id) or 0)]
end
function Registry.Queries.Resolve(id)
    local key = Registry.Queries.GetKey(id)
    if not key then return nil, "RECIPE_ID_UNKNOWN" end
    local descriptor = PNC.RecipeCatalog and PNC.RecipeCatalog.Queries.Get(key)
    if not descriptor then return { id = id, key = key,
        status = "KNOWN_BUT_UNAVAILABLE" } end
    return { id = id, key = key, status = "AVAILABLE", descriptor = descriptor }
end
function Registry.Queries.Export()
    local idToKey = {}
    for id, key in pairs(Registry.State.idToKey) do idToKey[id] = key end
    return { schemaVersion = Registry.SCHEMA_VERSION,
        revision = Registry.State.revision, nextId = Registry.State.nextId,
        idToKey = idToKey }
end
function Registry.Queries.GetDelta(sinceRevision)
    local start = math.max(0, math.floor(tonumber(sinceRevision) or 0)) + 1
    local entries = {}
    for id = start, Registry.State.nextId - 1 do
        local key = Registry.State.idToKey[id]
        if key then entries[#entries + 1] = { id, key } end
    end
    return { schemaVersion = Registry.SCHEMA_VERSION,
        revision = Registry.State.revision, entries = entries }
end
function Registry.Commands.ApplyDelta(delta)
    if type(delta) ~= "table"
        or tonumber(delta.schemaVersion) ~= Registry.SCHEMA_VERSION
    then return false, "REGISTRY_SCHEMA_MISMATCH" end
    for index = 1, #(delta.entries or {}) do
        local entry = delta.entries[index]
        local id = math.floor(tonumber(entry and entry[1]) or 0)
        local key = entry and entry[2]
        if id <= 0 or type(key) ~= "string" or key == "" then
            return false, "INVALID_REGISTRY_ENTRY"
        end
        if Registry.State.idToKey[id] and Registry.State.idToKey[id] ~= key then
            return false, "REGISTRY_ID_CONFLICT"
        end
        if Registry.KeyToId[key] and Registry.KeyToId[key] ~= id then
            return false, "REGISTRY_KEY_CONFLICT"
        end
        Registry.State.idToKey[id], Registry.KeyToId[key] = key, id
        if id >= Registry.State.nextId then Registry.State.nextId = id + 1 end
    end
    Registry.State.revision = math.max(Registry.State.revision,
        math.floor(tonumber(delta.revision) or 0))
    return true
end
function Registry.Queries.Diagnostics()
    local missing = 0
    for id, _ in pairs(Registry.State.idToKey) do
        local resolved = Registry.Queries.Resolve(id)
        if resolved and resolved.status ~= "AVAILABLE" then missing = missing + 1 end
    end
    return { schemaVersion = Registry.SCHEMA_VERSION,
        persistentRecipeIdCount = Registry.State.nextId - 1,
        nextId = Registry.State.nextId, revision = Registry.State.revision,
        missingUnavailableKeys = missing, reverseIndexReady = true }
end

Registry.Commands.Import(Registry.State)
return Registry

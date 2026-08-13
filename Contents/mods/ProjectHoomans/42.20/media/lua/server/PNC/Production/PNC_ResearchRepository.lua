if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchRepository = PNC.ResearchRepository or {}

local Repository = PNC.ResearchRepository
Repository.SCHEMA_VERSION = 1
Repository.MODDATA_KEY = "PNC_Research_V1"
Repository.ByColony = Repository.ByColony or {}
Repository.Runtime = Repository.Runtime or {}
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function denseUnique(source, numeric)
    local output, seen = {}, {}
    for index = 1, #(type(source) == "table" and source or {}) do
        local value = numeric and math.floor(tonumber(source[index]) or 0)
            or tostring(source[index] or "")
        if value and value ~= 0 and value ~= "" and not seen[value] then
            seen[value] = true; output[#output + 1] = value
        end
    end
    table.sort(output)
    return output
end

local function rebuildRuntime(colonyId, state)
    local learnedRecipeSet, learnedTechnologySet = {}, {}
    for index = 1, #state.learnedRecipeIds do
        learnedRecipeSet[state.learnedRecipeIds[index]] = true
    end
    for index = 1, #state.learnedTechnologyIds do
        learnedTechnologySet[state.learnedTechnologyIds[index]] = true
    end
    Repository.Runtime[colonyId] = {
        learnedRecipeSet = learnedRecipeSet,
        learnedTechnologySet = learnedTechnologySet,
    }
end

local function normalize(colonyId, raw)
    local state = {
        schemaVersion = Repository.SCHEMA_VERSION,
        colonyId = colonyId,
        learnedRecipeIds = denseUnique(raw and raw.learnedRecipeIds, true),
        learnedTechnologyIds = denseUnique(raw and raw.learnedTechnologyIds, false),
        knowledgeRevision = math.max(0,
            math.floor(tonumber(raw and raw.knowledgeRevision) or 0)),
    }
    rebuildRuntime(colonyId, state)
    return state
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.ByColony end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    Repository.ByColony, Repository.Runtime = {}, {}
    if type(raw) == "table"
        and tonumber(raw.schemaVersion) == Repository.SCHEMA_VERSION
    then
        for colonyId, state in pairs(raw.byColony or {}) do
            colonyId = tostring(colonyId)
            Repository.ByColony[colonyId] = normalize(colonyId, state)
        end
    end
    Repository.Loaded, Repository.Dirty = true, false
    return Repository.ByColony
end

function Repository.Get(colonyId, create)
    Repository.Load()
    colonyId = tostring(colonyId or "")
    if colonyId == "" then return nil end
    local state = Repository.ByColony[colonyId]
    if not state and create ~= false then
        state = normalize(colonyId, nil)
        Repository.ByColony[colonyId] = state
        Repository.Dirty = true
    end
    if state and not Repository.Runtime[colonyId] then
        rebuildRuntime(colonyId, state)
    end
    return state
end

function Repository.RebuildRuntime()
    Repository.Runtime = {}
    for colonyId, state in pairs(Repository.ByColony) do
        rebuildRuntime(colonyId, state)
    end
    return Repository.Runtime
end

function Repository.MarkDirty() Repository.Dirty = true end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    local output = { schemaVersion = Repository.SCHEMA_VERSION, byColony = {} }
    for colonyId, state in pairs(Repository.ByColony) do
        output.byColony[colonyId] = {
            schemaVersion = Repository.SCHEMA_VERSION,
            colonyId = colonyId,
            learnedRecipeIds = copy(state.learnedRecipeIds),
            learnedTechnologyIds = copy(state.learnedTechnologyIds),
            knowledgeRevision = state.knowledgeRevision,
        }
    end
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(output) do target[key] = value end
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository

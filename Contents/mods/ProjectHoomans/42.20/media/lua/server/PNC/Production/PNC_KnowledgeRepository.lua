if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.KnowledgeRepository = PNC.KnowledgeRepository or {}

local Repository = PNC.KnowledgeRepository
local Registry = PNC.RecipeKnowledgeRegistry
Repository.MODDATA_KEY = "PNC_RecipeKnowledge_V1"
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Registry.State end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    Registry.Commands.Import(raw)
    Repository.Loaded = true
    Repository.Dirty = false
    return Registry.State
end

function Repository.GetOrCreateId(key)
    Repository.Load()
    local id, created = Registry.Commands.GetOrCreateId(key)
    if created then Repository.Dirty = true end
    return id, created
end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    local payload = Registry.Queries.Export()
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(payload) do target[key] = value end
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository

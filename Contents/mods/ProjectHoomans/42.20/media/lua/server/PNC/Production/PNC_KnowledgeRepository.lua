if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.KnowledgeRepository = PNC.KnowledgeRepository or {}

local Repository = PNC.KnowledgeRepository
local Registry = PNC.RecipeKnowledgeRegistry
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"
Repository.MODDATA_KEY = "PNC_RecipeKnowledge_V1"
Repository.SCHEMA_VERSION = Registry.SCHEMA_VERSION
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Registry.State end
    local raw = Reset.Read(Repository.MODDATA_KEY)
    local reason = Reset.Check(raw, Repository.SCHEMA_VERSION)
    Registry.Commands.Import(reason == nil and raw or nil)
    Repository.Loaded = true
    Repository.Dirty = reason ~= nil and reason ~= "empty_state"
    if Repository.Dirty then
        Reset.Mark(Repository, raw, Repository.SCHEMA_VERSION, reason,
            "recipe_knowledge")
    end
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
    local payload = Registry.Queries.Export()
    local written = Reset.Write(Repository.MODDATA_KEY, payload)
    if not written then return false, "moddata_unavailable" end
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository

-- Optional handoff from the source-preserving Hoomans import planner to the
-- Core-owned actor migration service. This adapter never loads Core itself;
-- callers provide an already-loaded Core facade at the integration boundary.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreMigration or {}
Persistence.CoreMigration = Adapter

function Adapter.BuildPlan(raw, options)
    if not Persistence.ImportPlan
        or type(Persistence.ImportPlan.Build) ~= "function"
    then return nil, "import_plan_unavailable" end
    return Persistence.ImportPlan.Build(raw, options)
end

function Adapter.Import(plan, core, store, options)
    if type(core) ~= "table" or type(core.Actors) ~= "table"
        or type(core.Actors.Migration) ~= "table"
        or type(core.Actors.Migration.Import) ~= "function"
    then return nil, "core_migration_unavailable" end
    local registry = options and options.registry
        or core.Actors.DefaultRegistry
    return core.Actors.Migration.Import(plan, registry, store, options)
end

function Adapter.Rollback(importResult, core, store, options)
    if type(core) ~= "table" or type(core.Actors) ~= "table"
        or type(core.Actors.Migration) ~= "table"
        or type(core.Actors.Migration.Rollback) ~= "function"
    then return false, "core_migration_unavailable" end
    local registry = options and options.registry
        or core.Actors.DefaultRegistry
    return core.Actors.Migration.Rollback(importResult, registry, store)
end

return Adapter

-- Unique NPC registry provider.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.UniqueNPCRegistry = PNC.UniqueNPCRegistry or {}

local Registry = PNC.UniqueNPCRegistry
local Internal = Registry.Internal or {}
Registry.Internal = Internal
local Catalog = PNC.UniqueNPCs
local Store = PNC.AbstractWorldStore
local Identity = PNC.Identity
local Config = PNC.DirectorConfig
local copy = Internal.Copy
local authority = Internal.Authority
local ensure = Internal.Ensure
local now = Internal.Now
local getEntry = Internal.GetEntry
local isAvailable = Internal.IsAvailable
local selectionSeed = Internal.SelectionSeed
local chooseWeighted = Internal.ChooseWeighted

local buildDefinitionDiagnostic = Internal.BuildDefinitionDiagnostic

function Registry.BuildDebugSnapshot()
    local states
    local definitions
    local rows = {}
    local errors = {}
    local errorCount = 0
    local seen = {}
    local counts = {
        total = 0,
        registered = 0,
        unspawned = 0,
        reserved = 0,
        alive = 0,
        dead = 0,
        disabled = 0,
        problems = 0,
        registrationErrors = 0,
    }
    local index
    local definition
    local entry
    local row
    local definitionID
    states = ensure()
    if not states then return nil, "not_authority" end
    definitions = Catalog and Catalog.List and Catalog.List() or {}
    if Catalog and Catalog.ListRegistrationErrors then
        for _, errorEntry in ipairs(Catalog.ListRegistrationErrors()) do
            if errorEntry.id then
                errors[tostring(errorEntry.id)] = errorEntry
            end
            errorCount = errorCount + 1
        end
    end
    for index = 1, #definitions do
        definition = definitions[index]
        definitionID = tostring(definition.id)
        seen[definitionID] = true
        entry = states[definitionID]
        row = buildDefinitionDiagnostic(definition, entry, errors)
        rows[#rows + 1] = row
    end
    for definitionID, entry in pairs(states) do
        if not seen[tostring(definitionID)] then
            rows[#rows + 1] = buildDefinitionDiagnostic(
                nil, entry, errors)
        end
    end
    table.sort(rows, function(left, right)
        local leftName = tostring(left.displayName or left.definitionId)
        local rightName = tostring(right.displayName or right.definitionId)
        if leftName ~= rightName then return leftName < rightName end
        return tostring(left.definitionId) < tostring(right.definitionId)
    end)
    for _, row in ipairs(rows) do
        counts.total = counts.total + 1
        if row.registered then counts.registered = counts.registered + 1 end
        if row.status == "unseen" then counts.unspawned = counts.unspawned + 1 end
        if row.status == "reserved" then counts.reserved = counts.reserved + 1 end
        if row.status == "alive" then counts.alive = counts.alive + 1 end
        if row.status == "dead" then counts.dead = counts.dead + 1 end
        if row.status == "disabled" then counts.disabled = counts.disabled + 1 end
        if row.integrity or row.registrationError then
            counts.problems = counts.problems + 1
        end
    end
    counts.registrationErrors = errorCount
    return {
        schemaVersion = 1,
        revision = Store.Registry.revision or 0,
        poolChance = tonumber(Config and Config.UNIQUE_NPC_POOL_CHANCE) or 0,
        generatedAt = Store.WorldAgeHours(),
        counts = counts,
        registrationErrors = Catalog and Catalog.ListRegistrationErrors
            and Catalog.ListRegistrationErrors() or {},
        entries = rows,
    }, "ok"
end

function Registry.Reconcile()
    local states
    local definitionID
    local entry
    local record
    local changed = false
    states = ensure()
    if not states then return false, "not_authority" end
    for definitionID, entry in pairs(states) do
        if entry.status == "reserved" or entry.status == "alive" then
            record = nil
            if tostring(entry.runtimeNpcId or "") ~= ""
                and PNC.Registry
                and PNC.Registry.Get
            then
                record = PNC.Registry.Get(entry.runtimeNpcId)
            end
            if record
                and tostring(record.uniqueDefinitionId or "")
                    == tostring(definitionID)
            then
                if entry.status == "reserved" then
                    entry.status = "alive"
                    entry.spawnedAt = tonumber(entry.spawnedAt)
                        or Store.WorldAgeHours()
                    changed = true
                end
            else
                states[definitionID] = nil
                changed = true
            end
        end
    end
    if changed and Store.Touch then
        Store.Touch("unique_npc_reconciled")
    end
    return true, changed
end

function Registry.IsUniqueRecord(record)
    return type(record) == "table"
        and tostring(record.uniqueDefinitionId or "") ~= ""
end

return Registry

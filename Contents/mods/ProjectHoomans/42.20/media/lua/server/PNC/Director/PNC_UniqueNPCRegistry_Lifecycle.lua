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

function Registry.Get(definitionID)
    local states = ensure()
    local entry
    if not states then return nil end
    entry = getEntry(states, tostring(definitionID or ""))
    return entry and copy(entry) or nil
end

function Registry.ReserveForGeneration(context)
    local states
    local candidates = {}
    local definitions
    local definition
    local entry
    local chance
    local seed
    local index
    local identitySeed
    context = type(context) == "table" and context or {}
    states = ensure()
    if not states then return nil, "not_authority" end
    definitions = Catalog and Catalog.List and Catalog.List() or {}
    if #definitions <= 0 then return nil, "unique_catalog_empty" end
    if context.maxPerGeneration == 0 then
        return nil, "unique_generation_limit" end
    seed = selectionSeed(context)
    chance = tonumber(context.poolChance)
        or tonumber(Config.UNIQUE_NPC_POOL_CHANCE) or 0
    chance = math.max(0, math.min(1, chance))
    if context.force ~= true and Identity.Float(seed, "unique_pool:roll") >= chance then
        return nil, "pool_roll_missed"
    end
    for index = 1, #definitions do
        definition = definitions[index]
        entry = getEntry(states, definition.id)
        if isAvailable(entry)
            and (definition.spawnChance == nil
                or Identity.Float(seed, "unique_spawn:" .. definition.id)
                    < definition.spawnChance)
        then
            candidates[#candidates + 1] = definition
        end
    end
    if #candidates <= 0 then return nil, "unique_catalog_exhausted" end
    definition = chooseWeighted(candidates, seed)
    if not definition then return nil, "unique_candidate_unweighted" end
    identitySeed = tonumber(definition.identitySeed)
        or Identity.MixSeed(seed, "unique_identity:" .. definition.id)
    states[definition.id] = {
        definitionId = definition.id,
        status = "reserved",
        runtimeNpcId = nil,
        identitySeed = identitySeed,
        definitionVersion = definition.version,
        reservedAt = now(context),
        spawnedAt = 0,
        diedAt = 0,
    }
    if Store.Touch then Store.Touch("unique_npc_reserved") end
    return {
        definitionId = definition.id,
        identitySeed = identitySeed,
        definitionVersion = definition.version,
        definition = copy(definition),
    }, "reserved"
end

function Registry.CommitSpawn(claim, record, worldAgeHours)
    local states
    local entry
    local definitionID
    if type(claim) ~= "table" or type(record) ~= "table" then
        return false, "claim_or_record_missing"
    end
    states = ensure()
    if not states then return false, "not_authority" end
    definitionID = tostring(claim.definitionId or "")
    entry = states[definitionID]
    if not entry or entry.status ~= "reserved" then
        return false, "unique_claim_not_reserved"
    end
    entry.status = "alive"
    entry.runtimeNpcId = tostring(record.id or "")
    entry.spawnedAt = tonumber(worldAgeHours) or Store.WorldAgeHours()
    if Store.Touch then Store.Touch("unique_npc_spawned") end
    return true, "alive"
end

function Registry.PrepareForGeneration(context)
    local claim
    local definition
    local reason
    local catalog = PNC.UniqueNPCs
    claim, reason = Registry.ReserveForGeneration(context)
    if not claim then return nil, nil, reason end
    definition, reason = catalog.Resolve(claim.definition, {
        identitySeed = claim.identitySeed,
        archetypeID = context and context.archetypeID,
        generation = context and context.generation,
    })
    if not definition then
        Registry.Release(claim, "unique_resolve_failed")
        return nil, nil, reason or "unique_resolve_failed"
    end
    return claim, definition, "prepared"
end

function Registry.Release(claim, reason)
    local states
    local definitionID
    local entry
    if type(claim) ~= "table" then return false, "claim_missing" end
    states = ensure()
    if not states then return false, "not_authority" end
    definitionID = tostring(claim.definitionId or "")
    entry = states[definitionID]
    if not entry or entry.status ~= "reserved" then
        return false, "unique_claim_not_reserved"
    end
    states[definitionID] = nil
    if Store.Touch then
        Store.Touch("unique_npc_reservation_released:" .. tostring(reason or "unknown"))
    end
    return true, "released"
end

function Registry.RollbackSpawn(claim, reason)
    local states
    local definitionID
    local entry
    if type(claim) ~= "table" then return false, "claim_missing" end
    states = ensure()
    if not states then return false, "not_authority" end
    definitionID = tostring(claim.definitionId or "")
    entry = states[definitionID]
    if not entry or (entry.status ~= "reserved" and entry.status ~= "alive") then
        return false, "unique_claim_not_active"
    end
    states[definitionID] = nil
    if Store.Touch then
        Store.Touch("unique_npc_spawn_rollback:" .. tostring(reason or "unknown"))
    end
    return true, "rolled_back"
end

function Registry.MarkDead(record, reason, worldAgeHours)
    local states
    local definitionID
    local entry
    if type(record) ~= "table" then return false, "record_missing" end
    definitionID = tostring(record.uniqueDefinitionId or "")
    if definitionID == "" then return false, "not_unique" end
    states = ensure()
    if not states then return false, "not_authority" end
    entry = states[definitionID] or {
        definitionId = definitionID,
        definitionVersion = tonumber(record.uniqueDefinitionVersion) or 1,
    }
    entry.status = "dead"
    entry.runtimeNpcId = tostring(record.id or entry.runtimeNpcId or "")
    entry.identitySeed = tonumber(record.identitySeed) or entry.identitySeed
    entry.diedAt = tonumber(worldAgeHours) or Store.WorldAgeHours()
    entry.deathReason = tostring(reason or record.deathReason or "unknown")
    states[definitionID] = entry
    if Store.Touch then Store.Touch("unique_npc_died") end
    return true, "dead"
end


return Registry

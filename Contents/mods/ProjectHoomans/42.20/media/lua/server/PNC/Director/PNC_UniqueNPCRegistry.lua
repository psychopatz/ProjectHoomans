-- Authority-side one-time unique NPC reservation and lifecycle state.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.UniqueNPCRegistry = PNC.UniqueNPCRegistry or {}

local Registry = PNC.UniqueNPCRegistry
local Catalog = PNC.UniqueNPCs
local Store = PNC.AbstractWorldStore
local Identity = PNC.Identity
local Config = PNC.DirectorConfig
local Core = PNC.Core

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function ensure()
    if not authority() then return nil, "not_authority" end
    if not Store or not Store.EnsureLoaded then
        return nil, "abstract_world_store_unavailable"
    end
    Store.EnsureLoaded()
    Store.Registry.uniqueNPCsByID = Store.Registry.uniqueNPCsByID or {}
    return Store.Registry.uniqueNPCsByID
end

local function now(context)
    return tonumber(context and context.worldAgeHours)
        or Store.WorldAgeHours()
end

local function getEntry(states, definitionID)
    return states[definitionID]
end

local function isAvailable(entry)
    return entry == nil or entry.status == "unseen"
end

local function selectionSeed(context)
    context = type(context) == "table" and context or {}
    return Identity.NormalizeSeed(
        context.selectionSeed or context.seed,
        "unique_pool:" .. tostring(context.generationId or "world")
    )
end

local function chooseWeighted(definitions, seed)
    local total = 0
    local roll
    local index
    local definition
    local weight
    for index = 1, #definitions do
        definition = definitions[index]
        weight = math.max(0, tonumber(definition.chanceWeight) or 1)
        total = total + weight
    end
    if total <= 0 then return nil end
    roll = Identity.Float(seed, "unique_pool:candidate") * total
    total = 0
    for index = 1, #definitions do
        definition = definitions[index]
        total = total + math.max(0, tonumber(definition.chanceWeight) or 1)
        if roll < total then return definition end
    end
    return definitions[#definitions]
end

local function currentPosition(record)
    local body
    local x
    local y
    local z
    if type(record) ~= "table" then return nil end
    x = tonumber(record.x) or 0
    y = tonumber(record.y) or 0
    z = tonumber(record.z) or 0
    if PNC.Registry and PNC.Registry.GetLiveZombie then
        body = PNC.Registry.GetLiveZombie(record.id)
    end
    if body then
        if body.getX then x = tonumber(body:getX()) or x end
        if body.getY then y = tonumber(body:getY()) or y end
        if body.getZ then z = tonumber(body:getZ()) or z end
    end
    return { x = x, y = y, z = z }
end

local function factionSummary(record)
    local affiliation = type(record) == "table"
        and type(record.affiliation) == "table"
        and record.affiliation or nil
    local verifier = PNC.Identity and PNC.Identity.Verifier
    local factionID = verifier and verifier.GetFactionID
        and verifier.GetFactionID(record)
        or affiliation and affiliation.factionID
        or type(record) == "table" and (record.factionID or record.factionId)
        or nil
    local faction
    if not factionID then return nil end
    affiliation = affiliation or {}
    if PNC.Factions and PNC.Factions.GetPresentation then
        faction = PNC.Factions.GetPresentation(factionID)
    elseif PNC.Factions and PNC.Factions.Get then
        faction = PNC.Factions.Get(factionID)
    end
    return {
        id = tostring(factionID),
        name = faction and faction.name or tostring(factionID),
        archetypeID = faction and faction.archetypeID or nil,
        status = faction and faction.status or nil,
        membershipStatus = affiliation.membershipStatus,
        role = affiliation.role,
        rank = affiliation.rank,
    }
end

local function communitySummary(record)
    local affiliation = type(record) == "table"
        and type(record.affiliation) == "table"
        and record.affiliation or nil
    local communityID = affiliation and affiliation.communityID or nil
    local community
    if not communityID then return nil end
    if PNC.Communities and PNC.Communities.Get then
        community = PNC.Communities.Get(communityID)
    end
    return {
        id = tostring(communityID),
        name = community and community.name or tostring(communityID),
        status = community and community.status or nil,
        role = affiliation.communityRole,
    }
end

local function runtimeSummary(record)
    local position
    local summary
    local health
    local runtime
    if type(record) ~= "table" then return nil end
    position = currentPosition(record)
    health = type(record.health) == "table" and record.health or {}
    runtime = type(record.runtime) == "table" and record.runtime or {}
    summary = {
        runtimeNpcId = tostring(record.id or ""),
        name = record.name,
        alive = record.alive ~= false,
        presenceState = record.presenceState,
        tacticalClass = record.tacticalClass,
        bodyLease = runtime.bodyLease,
        position = position,
        x = position and position.x or nil,
        y = position and position.y or nil,
        z = position and position.z or nil,
        hpCurrent = health.current,
        hpMax = health.max,
        healthState = health.state,
        skillLevels = PNC.Skills and PNC.Skills.BuildSnapshot
            and PNC.Skills.BuildSnapshot(record)
            or copy(record.skillBaseLevels or {}),
        skillBaseLevels = copy(record.skillBaseLevels or {}),
        vanillaTraits = copy(record.vanillaTraits or {}),
        dynamicTraits = copy(record.dynamicTraits or {}),
        npcTraits = copy(record.npcTraits or {}),
        equipment = copy(record.equipment or {}),
        inventoryTemplateRef = record.inventoryTemplateRef,
        affiliation = factionSummary(record),
        community = communitySummary(record),
    }
    return summary
end

local function buildDefinitionDiagnostic(definition, entry, errors)
    local record
    local runtime
    local status = entry and entry.status or "unseen"
    local integrity
    local definitionID = definition and definition.id
        or entry and entry.definitionId or ""
    if entry and entry.runtimeNpcId and PNC.Registry
        and PNC.Registry.Get
    then
        record = PNC.Registry.Get(entry.runtimeNpcId)
    end
    runtime = runtimeSummary(record)
    if status == "alive" and not runtime then
        integrity = "alive_record_missing"
    elseif runtime
        and tostring(runtime.runtimeNpcId or "") ~= ""
        and tostring(record.uniqueDefinitionId or "")
            ~= tostring(definitionID)
    then
        integrity = "runtime_definition_mismatch"
    elseif not definition then
        integrity = "definition_missing"
    end
    return {
        definitionId = tostring(definitionID),
        registered = definition ~= nil,
        registrationError = errors and errors[tostring(definitionID)] or nil,
        displayName = definition and definition.displayName
            or tostring(definitionID),
        version = definition and definition.version
            or entry and entry.definitionVersion or nil,
        isFemale = definition and definition.isFemale or nil,
        archetypeID = definition and definition.archetypeID or nil,
        status = status,
        spawned = runtime ~= nil,
        identitySeed = entry and entry.identitySeed
            or definition and definition.identitySeed or nil,
        reservedAt = entry and entry.reservedAt or 0,
        spawnedAt = entry and entry.spawnedAt or 0,
        diedAt = entry and entry.diedAt or 0,
        deathReason = entry and entry.deathReason or nil,
        runtime = runtime,
        authored = definition and {
            identity = copy(definition.identity or {}),
            tacticalClass = definition.tacticalClass,
            visualProfile = definition.visualProfile,
            outfit = definition.outfit,
            hpMax = definition.hpMax,
            combatProfile = copy(definition.combatProfile or {}),
            equipment = copy(definition.equipment or {}),
            factionID = definition.factionID,
            membershipStatus = definition.membershipStatus,
            factionRole = definition.factionRole,
            factionRank = definition.factionRank,
            skillLevels = copy(definition.skillLevels or {}),
            vanillaTraits = copy(definition.vanillaTraits or {}),
            dynamicTraits = copy(definition.dynamicTraits or {}),
            npcTraits = copy(definition.npcTraits or {}),
            inventoryTemplateRef = definition.inventoryTemplateRef,
            startingItems = copy(definition.startingItems or {}),
            startingItemCount = definition.startingItems
                and #definition.startingItems or 0,
        } or nil,
        integrity = integrity,
    }
end

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

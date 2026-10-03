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


Internal.BuildDefinitionDiagnostic = buildDefinitionDiagnostic

return Registry

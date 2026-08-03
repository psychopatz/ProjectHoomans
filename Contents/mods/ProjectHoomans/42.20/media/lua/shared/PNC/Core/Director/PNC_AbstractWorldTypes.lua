-- Serialization-safe constructors and migrations for strategic entities.

PNC = PNC or {}
PNC.AbstractWorldTypes = PNC.AbstractWorldTypes or {}

local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local output = {}
    for key, item in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            output[key] = copy(item, seen)
        end
    end
    seen[value] = nil
    return output
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then value = tonumber(fallback) or 0 end
    return value
end

local function integer(value, minimum, maximum, fallback)
    return math.max(minimum, math.min(maximum,
        math.floor(finite(value, fallback))))
end

local function safeID(value, prefix)
    value = type(value) == "string" and value or nil
    if not value or #value < 3 or #value > 192
        or string.find(value, "%c")
        or string.match(value, "^[%w_%-%.:]+$") == nil
    then return nil end
    if prefix and string.sub(value, 1, #prefix) ~= prefix then return nil end
    return value
end

local function stringSet(value)
    local output = {}
    for key, item in pairs(type(value) == "table" and value or {}) do
        if type(key) == "number" then
            item = type(item) == "string" and item or nil
            if item then output[item] = true end
        elseif item == true and type(key) == "string" then
            output[key] = true
        end
    end
    return output
end

local function idArray(value)
    local set = stringSet(value)
    local output = {}
    for id in pairs(set) do output[#output + 1] = id end
    table.sort(output)
    return output
end

local function resources(value)
    value = type(value) == "table" and value or {}
    return {
        food = math.max(0, finite(value.food, 0)),
        water = math.max(0, finite(value.water, 0)),
        ammo = math.max(0, finite(value.ammo, 0)),
        medical = math.max(0, finite(value.medical, value.medicine)),
        materials = math.max(0, finite(value.materials, 0)),
        weapons = math.max(0, finite(value.weapons, 0)),
    }
end

local function generation(value)
    local source = type(value) == "table" and value or nil
    if not source then return nil end
    local generationID = safeID(source.generationId)
    if not generationID then return nil end
    return {
        source = type(source.source) == "string" and source.source
            or "WORLD_POPULATION_DIRECTOR",
        generationId = generationID,
        sectorId = safeID(source.sectorId),
        createdAt = math.max(0, finite(source.createdAt, 0)),
        seed = integer(source.seed, 0, 2147483647, 0),
    }
end

function Types.NormalizeLocationRef(value)
    local source = type(value) == "table" and value or {}
    local id = safeID(source.id, "aloc_")
    if not id then return nil end
    return {
        id = id,
        type = Config.LOCATION_TYPES[source.type]
            and source.type or "TEMPORARY",
        x = finite(source.x, 0), y = finite(source.y, 0),
        z = finite(source.z, 0),
    }
end

function Types.NormalizeCombatProfile(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    local fields = { "manpower", "meleePower", "rangedPower", "defense",
        "mobility", "morale", "experience", "medical", "ammoState",
        "condition", "overallPower", "memberCount", "combatantCount" }
    for _, field in ipairs(fields) do
        output[field] = math.max(0, finite(source[field], 0))
    end
    output.builtAt = math.max(0, finite(source.builtAt, 0))
    output.revision = integer(source.revision, 0, 2147483647, 0)
    output.ammoLabel = type(source.ammoLabel) == "string"
        and source.ammoLabel or "EMPTY"
    return output
end

function Types.NormalizeBehaviorProfile(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    for _, field in ipairs({ "aggression", "bravery", "greed", "caution",
        "mercy", "discipline", "civilianHostility" }) do
        output[field] = math.max(0, math.min(1, finite(source[field], 0)))
    end
    output.builtAt = math.max(0, finite(source.builtAt, 0))
    output.source = type(source.source) == "string" and source.source or "normalized"
    return output
end

function Types.NormalizeAction(value)
    local source = type(value) == "table" and value or nil
    if not source then return nil end
    local actionType = tostring(source.type or "")
    local locationID = safeID(source.locationId, "aloc_")
    if actionType == "" or not locationID then return nil end
    local startedAt = math.max(0, finite(source.startedAt, 0))
    local endsAt = math.max(startedAt, finite(source.endsAt, startedAt))
    return { type = actionType, locationId = locationID,
        startedAt = startedAt, endsAt = endsAt,
        seed = integer(source.seed, 0, 2147483647, 0),
        status = type(source.status) == "string" and source.status or "ACTIVE" }
end

local function previousMission(value)
    local source = type(value) == "table" and value or nil
    if not source or not Config.MISSIONS[source.type] then return nil end
    return { type = source.type,
        targetLocationId = safeID(source.targetLocationId, "aloc_") }
end

local function expiryMap(value, prefix)
    local output = {}
    for key, expiry in pairs(type(value) == "table" and value or {}) do
        if safeID(key, prefix) then
            output[key] = math.max(0, finite(expiry, 0))
        end
    end
    local count = 0
    for _ in pairs(output) do count = count + 1 end
    while count > Config.RECENT_THREAT_HISTORY_LIMIT do
        local oldestKey, oldestExpiry
        for key, expiry in pairs(output) do
            if not oldestExpiry or expiry < oldestExpiry then
                oldestKey, oldestExpiry = key, expiry
            end
        end
        if not oldestKey then break end
        output[oldestKey] = nil
        count = count - 1
    end
    return output
end

function Types.NormalizeGroup(value, groupID)
    local source = type(value) == "table" and value or {}
    local id = safeID(groupID or source.id, "agroup_")
    local location = Types.NormalizeLocationRef(source.location)
    if not id or not location then return nil end
    local groupType = Config.GROUP_TYPES[source.groupType]
        and source.groupType or "WANDERER"
    local state = Config.STATES[source.state] and source.state or "IDLE"
    local target = Types.NormalizeLocationRef(source.targetLocation)
    if state == "TRAVELING" and not target then state = "IDLE" end
    local action = Types.NormalizeAction(source.action)
    if action and action.locationId ~= location.id then action = nil end
    if action and state ~= "ACTIVE" and state ~= "TRAVELING" then
        state = "PERFORMING_ACTION"
    elseif (state == "PERFORMING_ACTION" or state == "ENGAGED") and not action then
        state = "ARRIVED"
    end
    return {
        schemaVersion = Config.SCHEMA_VERSION,
        id = id,
        factionId = safeID(source.factionId),
        homeCommunityId = safeID(source.homeCommunityId),
        groupType = groupType,
        memberIds = idArray(source.memberIds),
        leaderId = safeID(source.leaderId),
        mission = Config.MISSIONS[source.mission]
            and source.mission or "IDLE",
        state = state,
        location = location,
        targetLocation = target,
        stateStartedAt = math.max(0, finite(source.stateStartedAt, 0)),
        stateEndsAt = math.max(0, finite(source.stateEndsAt, 0)),
        missionStartedAt = math.max(0, finite(source.missionStartedAt, 0)),
        resources = resources(source.resources),
        action = action,
        previousMission = previousMission(source.previousMission),
        behaviorProfile = type(source.behaviorProfile) == "table"
            and Types.NormalizeBehaviorProfile(source.behaviorProfile) or nil,
        morale = math.max(0, math.min(1, finite(source.morale, 0.65))),
        recentAvoidedLocations = expiryMap(source.recentAvoidedLocations, "aloc_"),
        recentHostileGroups = expiryMap(source.recentHostileGroups, "agroup_"),
        activeEncounterId = safeID(source.activeEncounterId, "encounter_"),
        recentEncounterId = safeID(source.recentEncounterId, "encounter_"),
        knowledge = type(source.knowledge) == "table"
            and copy(source.knowledge) or {},
        visited = stringSet(source.visited),
        simulation = {
            lod = "ABSTRACT",
            nextUpdate = math.max(0, finite(source.simulation
                and source.simulation.nextUpdate, 0)),
        },
        combatProfile = source.combatProfile
            and Types.NormalizeCombatProfile(source.combatProfile) or nil,
        combatProfileDirty = source.combatProfileDirty ~= false,
        combatProfileReason = type(source.combatProfileReason) == "string"
            and source.combatProfileReason or "migration",
        combatProfileSignature = type(source.combatProfileSignature) == "string"
            and source.combatProfileSignature or nil,
        revision = integer(source.revision, 0, 2147483647, 0),
        diagnostics = type(source.diagnostics) == "table"
            and copy(source.diagnostics) or {},
        generation = generation(source.generation),
    }
end

function Types.NormalizeLocation(value, locationID)
    local source = type(value) == "table" and value or {}
    local id = safeID(locationID or source.id, "aloc_")
    if not id then return nil end
    local occupants = {}
    for groupID, visit in pairs(type(source.occupants) == "table"
        and source.occupants.groups or {}) do
        if safeID(groupID, "agroup_") and type(visit) == "table" then
            occupants[groupID] = {
                arrivedAt = math.max(0, finite(visit.arrivedAt, 0)),
                plannedDepartureAt = math.max(0,
                    finite(visit.plannedDepartureAt, 0)),
            }
        end
    end
    return {
        schemaVersion = Config.SCHEMA_VERSION,
        id = id,
        type = Config.LOCATION_TYPES[source.type]
            and source.type or "TEMPORARY",
        x = finite(source.x, 0), y = finite(source.y, 0),
        z = finite(source.z, 0),
        tags = stringSet(source.tags),
        resourcePotential = resources(source.resourcePotential),
        scavengedLevel = math.max(0, math.min(100,
            finite(source.scavengedLevel, 0))),
        danger = math.max(0, math.min(100, finite(source.danger, 0))),
        occupants = { groups = occupants },
        visitHistory = type(source.visitHistory) == "table"
            and copy(source.visitHistory) or {},
        sourceSite = type(source.sourceSite) == "table"
            and copy(source.sourceSite) or nil,
        populationHistory = type(source.populationHistory) == "table" and {
            formerSettlement = source.populationHistory.formerSettlement == true,
            destroyedAt = math.max(0,
                finite(source.populationHistory.destroyedAt, 0)),
            regenerationBlockedUntil = math.max(0,
                finite(source.populationHistory.regenerationBlockedUntil, 0)),
        } or nil,
        revision = integer(source.revision, 0, 2147483647, 0),
    }
end

local function normalizePopulation(value)
    local source = type(value) == "table" and value or {}
    local output = {
        nextGenerationSerial = integer(source.nextGenerationSerial,
            1, 2147483647, 1),
        bootstrapCompleted = source.bootstrapCompleted == true,
        bootstrapCompletedAt = math.max(0,
            finite(source.bootstrapCompletedAt, 0)),
        starterSettlementId = safeID(source.starterSettlementId),
        starterAttempts = integer(source.starterAttempts,
            0, 2147483647, 0),
        worldSeed = integer(source.worldSeed, 0, 2147483647, 0),
        worldSeedString = type(source.worldSeedString) == "string"
            and string.sub(source.worldSeedString, 1, 128) or nil,
        sectors = {}, siteHistory = {}, provenance = {},
        committedGenerationIds = {}, committedOrder = {},
    }
    for id, raw in pairs(type(source.sectors) == "table" and source.sectors or {}) do
        if safeID(id, "psector_") and type(raw) == "table" then
            output.sectors[id] = {
                id = id, discovered = raw.discovered == true,
                hadGroups = raw.hadGroups == true,
                hadSettlements = raw.hadSettlements == true,
                groupGenerationCooldownUntil = math.max(0,
                    finite(raw.groupGenerationCooldownUntil, 0)),
                settlementGenerationCooldownUntil = math.max(0,
                    finite(raw.settlementGenerationCooldownUntil, 0)),
                lastReconciledAt = math.max(0,
                    finite(raw.lastReconciledAt, 0)),
            }
        end
    end
    for locationID, raw in pairs(type(source.siteHistory) == "table"
        and source.siteHistory or {}) do
        if safeID(locationID, "aloc_") and type(raw) == "table" then
            output.siteHistory[locationID] = {
                formerSettlement = raw.formerSettlement == true,
                destroyedAt = math.max(0, finite(raw.destroyedAt, 0)),
                regenerationBlockedUntil = math.max(0,
                    finite(raw.regenerationBlockedUntil, 0)),
            }
        end
    end
    for entityID, raw in pairs(type(source.provenance) == "table"
        and source.provenance or {}) do
        local normalized = generation(raw)
        if safeID(entityID) and normalized then output.provenance[entityID] = normalized end
    end
    local order = idArray(source.committedOrder)
    local limit = Config.Population.COMMITTED_GENERATION_HISTORY_LIMIT
    local first = math.max(1, #order - limit + 1)
    for index = first, #order do
        local id = order[index]
        if source.committedGenerationIds and source.committedGenerationIds[id] == true then
            output.committedOrder[#output.committedOrder + 1] = id
            output.committedGenerationIds[id] = true
        end
    end
    return output
end

Types.NormalizePopulation = normalizePopulation

function Types.NewRegistry()
    return { schemaVersion = Config.SCHEMA_VERSION, revision = 0,
        groupsByID = {}, locationsByID = {}, encounters = {},
        encounterCooldowns = {}, nextEncounterSerial = 1,
        population = normalizePopulation(nil) }
end

function Types.NormalizeRegistry(value)
    local source = type(value) == "table" and value or {}
    local output = Types.NewRegistry()
    output.revision = integer(source.revision, 0, 2147483647, 0)
    output.population = normalizePopulation(source.population)
    for id, raw in pairs(type(source.locationsByID) == "table"
        and source.locationsByID or {}) do
        local location = Types.NormalizeLocation(raw, id)
        if location then output.locationsByID[location.id] = location end
    end
    for id, raw in pairs(type(source.groupsByID) == "table"
        and source.groupsByID or {}) do
        local group = Types.NormalizeGroup(raw, id)
        if group and output.locationsByID[group.location.id] then
            output.groupsByID[group.id] = group
        end
    end
    for _, report in ipairs(type(source.encounters) == "table"
        and source.encounters or {}) do
        if type(report) == "table" and safeID(report.id, "encounter_") then
            output.encounters[#output.encounters + 1] = copy(report)
        end
    end
    while #output.encounters > Config.ENCOUNTER_HISTORY_LIMIT do
        local removable
        for index, report in ipairs(output.encounters) do
            if report.outcome ~= "QUEUED" then removable = index break end
        end
        if not removable then break end
        table.remove(output.encounters, removable)
    end
    for key, expiry in pairs(type(source.encounterCooldowns) == "table"
        and source.encounterCooldowns or {}) do
        if type(key) == "string" and #key <= 640 then
            output.encounterCooldowns[key] = math.max(0, finite(expiry, 0))
        end
    end
    local cooldownLimit = Config.ENCOUNTER_HISTORY_LIMIT * 4
    local cooldownCount = 0
    for _ in pairs(output.encounterCooldowns) do cooldownCount = cooldownCount + 1 end
    while cooldownCount > cooldownLimit do
        local oldestKey, oldestExpiry
        for key, expiry in pairs(output.encounterCooldowns) do
            if not oldestExpiry or expiry < oldestExpiry then
                oldestKey, oldestExpiry = key, expiry
            end
        end
        if not oldestKey then break end
        output.encounterCooldowns[oldestKey] = nil
        cooldownCount = cooldownCount - 1
    end
    output.nextEncounterSerial = integer(source.nextEncounterSerial,
        1, 2147483647, #output.encounters + 1)
    return output
end

Types.SafeID = safeID
Types.IDArray = idArray
Types.Resources = resources

return Types

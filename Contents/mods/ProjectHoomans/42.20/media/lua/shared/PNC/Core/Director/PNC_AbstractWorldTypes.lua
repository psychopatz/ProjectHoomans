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
        behaviorProfile = type(source.behaviorProfile) == "table"
            and copy(source.behaviorProfile) or nil,
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
        revision = integer(source.revision, 0, 2147483647, 0),
    }
end

function Types.NewRegistry()
    return { schemaVersion = Config.SCHEMA_VERSION, revision = 0,
        groupsByID = {}, locationsByID = {}, encounters = {},
        nextEncounterSerial = 1 }
end

function Types.NormalizeRegistry(value)
    local source = type(value) == "table" and value or {}
    local output = Types.NewRegistry()
    output.revision = integer(source.revision, 0, 2147483647, 0)
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
        table.remove(output.encounters, 1)
    end
    output.nextEncounterSerial = integer(source.nextEncounterSerial,
        1, 2147483647, #output.encounters + 1)
    return output
end

Types.SafeID = safeID
Types.IDArray = idArray
Types.Resources = resources

return Types

local Types = PNC.AbstractWorldTypes
local Internal = Types.Internal
local Config = PNC.DirectorConfig

function Types.NewRegistry()
    return {
        schemaVersion = Config.SCHEMA_VERSION,
        revision = 0,
        groupsByID = {},
        locationsByID = {},
        encounters = {},
        encounterCooldowns = {},
        nextEncounterSerial = 1,
        population = Types.NormalizePopulation(nil),
    }
end

local function normalizeLocations(source, output)
    local id
    local raw
    local location
    for id, raw in pairs(
        type(source.locationsByID) == "table"
            and source.locationsByID or {}
    ) do
        location = Types.NormalizeLocation(raw, id)
        if location then output[location.id] = location end
    end
end

local function normalizeGroups(source, locations, output)
    local id
    local raw
    local group
    for id, raw in pairs(
        type(source.groupsByID) == "table" and source.groupsByID or {}
    ) do
        group = Types.NormalizeGroup(raw, id)
        if group and locations[group.location.id] then
            output[group.id] = group
        end
    end
end

local function normalizeEncounters(source, output)
    local report
    local removable
    local index
    for _, report in ipairs(
        type(source.encounters) == "table" and source.encounters or {}
    ) do
        if type(report) == "table"
            and Internal.SafeID(report.id, "encounter_")
        then
            output[#output + 1] = Internal.Copy(report)
        end
    end
    while #output > Config.ENCOUNTER_HISTORY_LIMIT do
        removable = nil
        for index, report in ipairs(output) do
            if report.outcome ~= "QUEUED" then
                removable = index
                break
            end
        end
        if not removable then break end
        table.remove(output, removable)
    end
end

local function oldestCooldown(cooldowns)
    local key
    local expiry
    local oldestKey
    local oldestExpiry
    for key, expiry in pairs(cooldowns) do
        if not oldestExpiry or expiry < oldestExpiry then
            oldestKey = key
            oldestExpiry = expiry
        end
    end
    return oldestKey
end

local function normalizeCooldowns(source, output)
    local key
    local expiry
    local count = 0
    local limit = Config.ENCOUNTER_HISTORY_LIMIT * 4
    local oldestKey
    for key, expiry in pairs(
        type(source.encounterCooldowns) == "table"
            and source.encounterCooldowns or {}
    ) do
        if type(key) == "string" and #key <= 640 then
            output[key] = math.max(0, Internal.Finite(expiry, 0))
            count = count + 1
        end
    end
    while count > limit do
        oldestKey = oldestCooldown(output)
        if not oldestKey then break end
        output[oldestKey] = nil
        count = count - 1
    end
end

function Types.NormalizeRegistry(value)
    local source = type(value) == "table" and value or {}
    local output = Types.NewRegistry()
    output.revision = Internal.Integer(
        source.revision, 0, 2147483647, 0
    )
    output.population = Types.NormalizePopulation(source.population)
    normalizeLocations(source, output.locationsByID)
    normalizeGroups(source, output.locationsByID, output.groupsByID)
    normalizeEncounters(source, output.encounters)
    normalizeCooldowns(source, output.encounterCooldowns)
    output.nextEncounterSerial = Internal.Integer(
        source.nextEncounterSerial,
        1,
        2147483647,
        #output.encounters + 1
    )
    return output
end

-- Pure serialization-safe faction and affiliation constructors/normalizers.

PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}

local Types = PNC.FactionTypes
Types.Internal = Types.Internal or {}

local Internal = Types.Internal
local Constants = PNC.FactionConstants
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
local DiplomacyMath = PNC.FactionDiplomacyMath
local IncidentDefinitions = PNC.FactionIncidentDefinitions
local Balance = PNC.FactionBalance
local Emblems = PNC.FactionEmblems

function Internal.Tuning(name, fallback)
    local value = Balance and Balance.Get and Balance.Get(name)
    return value == nil and fallback or value
end

function Internal.Finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = tonumber(fallback)
    end
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return 0
    end
    return value
end

function Internal.Timestamp(value, fallback)
    return math.max(0, Internal.Finite(value, fallback))
end

function Internal.Revision(value)
    return math.max(0, math.floor(Internal.Finite(value, 0)))
end

function Internal.SafeString(value, maximum)
    if type(value) ~= "string" then return nil end
    value = string.match(value, "^%s*(.-)%s*$")
    if value == "" or #value > maximum or string.find(value, "%c") then
        return nil
    end
    return value
end

function Types.IsValidFactionID(value)
    return type(value) == "string"
        and #value > #Constants.ID_PREFIX
        and #value <= Constants.ID_MAX_LENGTH
        and string.sub(value, 1, #Constants.ID_PREFIX)
            == Constants.ID_PREFIX
        and string.match(value, "^faction_[%w_%-]+$") ~= nil
end

function Types.IsValidNPCID(value)
    return type(value) == "string"
        and value ~= ""
        and #value <= 192
        and string.find(value, "%c") == nil
end

function Types.IsValidFactionArchetype(value)
    return Archetypes.Exists(value)
end

function Types.IsValidMembershipStatus(value)
    return type(value) == "string"
        and Constants.VALID_MEMBERSHIP_STATUSES[value] == true
end

function Types.IsValidFactionRole(value)
    return type(value) == "string"
        and Constants.VALID_ROLES[value] == true
end

function Types.IsValidFactionRank(value)
    return type(value) == "string"
        and Constants.VALID_RANKS[value] == true
end

function Internal.NormalizeTags(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        local normalizedKey = Internal.SafeString(
            key,
            Constants.TAG_KEY_MAX_LENGTH
        )
        if normalizedKey and (item == true or item == false) then
            output[normalizedKey] = item
        elseif normalizedKey and type(item) == "string" then
            local normalizedValue = Internal.SafeString(
                item,
                Constants.TAG_VALUE_MAX_LENGTH
            )
            if normalizedValue then
                output[normalizedKey] = normalizedValue
            end
        end
    end
    return output
end

local function normalizeTargetPoint(value, fallbackKind)
    if type(value) ~= "table" then return nil end
    local x = tonumber(value.x)
    local y = tonumber(value.y)
    if not x or not y or x ~= x or y ~= y
        or x == math.huge or x == -math.huge
        or y == math.huge or y == -math.huge
    then
        return nil
    end
    local output = {
        kind = Internal.SafeString(
            value.kind,
            Constants.TAG_VALUE_MAX_LENGTH
        ) or fallbackKind,
        x = x,
        y = y,
        z = Internal.Finite(value.z, 0),
        radius = math.max(1, Internal.Finite(value.radius, 1)),
        siteID = Internal.SafeString(value.siteID, Constants.ID_MAX_LENGTH),
        baseID = Internal.SafeString(value.baseID, Constants.ID_MAX_LENGTH),
        factionID = Internal.SafeString(value.factionID, Constants.ID_MAX_LENGTH),
        zoneID = Internal.SafeString(value.zoneID, Constants.ID_MAX_LENGTH),
    }
    local bounds = type(value.bounds) == "table"
        and value.bounds or nil
    if bounds then
        local minX = tonumber(bounds.minX)
        local minY = tonumber(bounds.minY)
        local maxX = tonumber(bounds.maxX)
        local maxY = tonumber(bounds.maxY)
        if minX and minY and maxX and maxY then
            output.bounds = {
                minX = math.min(minX, maxX),
                minY = math.min(minY, maxY),
                maxX = math.max(minX, maxX),
                maxY = math.max(minY, maxY),
            }
        end
    end
    return output
end

local function normalizeAmbient(value)
    if type(value) ~= "table" then return nil end
    local phase = Constants.VALID_MOBILE_AMBIENT_PHASES[value.phase]
        and value.phase or Constants.MOBILE_AMBIENT_DAY
    local objective = Constants.VALID_MOBILE_AMBIENT_OBJECTIVES[
        value.objective
    ] and value.objective or nil
    local target = normalizeTargetPoint(value.target, objective)
    if not objective or not target then
        objective, target = nil, nil
    end
    return {
        phase = phase,
        objective = objective,
        target = target,
        nextCheckAt = Internal.Timestamp(value.nextCheckAt, 0),
        nextObjectiveAt = Internal.Timestamp(value.nextObjectiveAt, 0),
        retryAt = Internal.Timestamp(value.retryAt, 0),
        revision = Internal.Revision(value.revision),
    }
end

local function normalizeStrategicTarget(value)
    local target = normalizeTargetPoint(value, "location")
    if not target then return nil end
    target.kind = target.kind or "location"
    return target
end

-- Mobile groups deliberately store a primitive site snapshot rather than a
-- Community record. A mobile faction has no reservation, population ledger,
-- or home claim; the snapshot is only its current abstract staging point.
function Types.NormalizeMobileGroup(value)
    local source = type(value) == "table" and value or {}
    local CommunityTypes = PNC.CommunityTypes
    local site
    local lastMovedAt
    local nextMoveAt
    local relocationHours
    local pathMode
    local controlMode
    local ambient
    local strategicTarget
    if source.active ~= true then return nil end
    if not CommunityTypes or not CommunityTypes.NormalizeSite then
        return nil
    end
    site = CommunityTypes.NormalizeSite(
        source.site,
        source.site and source.site.id
    )
    if not site then return nil end
    lastMovedAt = Internal.Timestamp(source.lastMovedAt, 0)
    relocationHours = math.max(
        Constants.MOBILE_GROUP_MIN_RELOCATION_HOURS,
        math.min(
            Constants.MOBILE_GROUP_MAX_RELOCATION_HOURS,
            Internal.Finite(
                source.relocationHours,
                Constants.MOBILE_GROUP_RELOCATION_HOURS
            )
        )
    )
    nextMoveAt = Internal.Timestamp(
        source.nextMoveAt,
        lastMovedAt + relocationHours
    )
    if nextMoveAt <= lastMovedAt then
        nextMoveAt = lastMovedAt + relocationHours
    end
    pathMode = Constants.VALID_MOBILE_PATH_MODES[
        source.pathMode
    ] and source.pathMode or Constants.MOBILE_PATH_RANDOM
    controlMode = Constants.VALID_MOBILE_CONTROL_MODES[
        source.controlMode
    ] and source.controlMode or (
        pathMode == Constants.MOBILE_PATH_PLAYER
            and Constants.MOBILE_CONTROL_STRATEGIC
            or Constants.MOBILE_CONTROL_AMBIENT
    )
    ambient = normalizeAmbient(source.ambient)
    strategicTarget = normalizeStrategicTarget(
        source.strategicTarget
    )
    return {
        schemaVersion = Constants.MOBILE_GROUP_SCHEMA_VERSION,
        active = true,
        pathMode = pathMode,
        controlMode = controlMode,
        strategicTarget = strategicTarget,
        ambient = ambient,
        site = site,
        lastMovedAt = lastMovedAt,
        nextMoveAt = nextMoveAt,
        relocationHours = relocationHours,
        relocationCount = math.max(
            0,
            math.floor(Internal.Finite(source.relocationCount, 0))
        ),
        revision = Internal.Revision(source.revision),
    }
end

function Internal.NormalizeIDSet(value, validator)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, enabled in pairs(value) do
        if enabled == true and validator(key) then
            output[key] = true
        end
    end
    return output
end

function Types.NormalizePlayerPacification(value, playerKey)
    local source = type(value) == "table" and value or {}
    if not EntityRef.IsPlayer(playerKey) then return nil end
    local untilWorldAgeHours = Internal.Timestamp(
        source.untilWorldAgeHours,
        0
    )
    if untilWorldAgeHours <= 0 then return nil end
    local createdAt = Internal.Timestamp(source.createdAt, 0)
    return {
        schemaVersion =
            Constants.PLAYER_PACIFICATION_SCHEMA_VERSION,
        playerKey = playerKey,
        createdAt = math.min(createdAt, untilWorldAgeHours),
        untilWorldAgeHours = untilWorldAgeHours,
        reason = Internal.SafeString(
            source.reason,
            Constants.PLAYER_PACIFICATION_REASON_MAX_LENGTH
        ) or "temporary_pacification",
        sourceNPCID = Types.IsValidNPCID(source.sourceNPCID)
            and source.sourceNPCID or nil,
        revision = Internal.Revision(source.revision),
    }
end

function Types.NormalizePlayerPacifications(value)
    local output = {}
    local ordered = {}
    for playerKey, raw in pairs(
        type(value) == "table" and value or {}
    ) do
        local entry = Types.NormalizePlayerPacification(
            raw,
            playerKey
        )
        if entry then
            ordered[#ordered + 1] = entry
        end
    end
    table.sort(ordered, function(left, right)
        if left.untilWorldAgeHours
            ~= right.untilWorldAgeHours
        then
            return left.untilWorldAgeHours
                > right.untilWorldAgeHours
        end
        return left.playerKey < right.playerKey
    end)
    while #ordered
        > Constants.PLAYER_PACIFICATION_LIMIT
    do
        table.remove(ordered)
    end
    for _, entry in ipairs(ordered) do
        output[entry.playerKey] = entry
    end
    return output
end

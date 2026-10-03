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
        communityID = Internal.SafeString(
            value.communityID,
            Constants.ID_MAX_LENGTH
        ),
        locationID = Internal.SafeString(
            value.locationID,
            Constants.ID_MAX_LENGTH
        ),
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
        holdForNoShelter = value.holdForNoShelter == true,
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

local function normalizePlayerRoam(value)
    if type(value) ~= "table" then return nil end
    local phase = Constants.VALID_MOBILE_PLAYER_ROAM_PHASES[
        value.phase
    ] and value.phase or Constants.MOBILE_PLAYER_ROAM_PHASE_APPROACH
    local area = normalizeTargetPoint(
        value.area,
        "player_roam_area"
    )
    local untilAt = Internal.Timestamp(value.untilAt, 0)
    if phase == Constants.MOBILE_PLAYER_ROAM_PHASE_AREA
        and (not area or untilAt <= 0)
    then
        phase = Constants.MOBILE_PLAYER_ROAM_PHASE_APPROACH
        area = nil
        untilAt = 0
    end
    return {
        phase = phase,
        area = area,
        untilAt = untilAt,
        lastArrivalAt = Internal.Timestamp(value.lastArrivalAt, 0),
        lastRollDay = math.max(
            -1,
            math.floor(Internal.Finite(value.lastRollDay, -1))
        ),
    }
end

local function normalizeMobileTravel(value)
    if type(value) ~= "table" then return nil end
    local destination = normalizeTargetPoint(
        value.destination or value.target,
        Constants.MOBILE_TRAVEL_SETTLEMENT
    )
    if not destination then return nil end
    local startedAt = Internal.Timestamp(value.startedAt, 0)
    return {
        kind = Constants.MOBILE_TRAVEL_SETTLEMENT,
        purpose = Constants.VALID_MOBILE_TRAVEL_PURPOSES[value.purpose]
            and value.purpose
            or Constants.MOBILE_TRAVEL_PURPOSE_ADMISSION,
        destination = destination,
        startedAt = startedAt,
        departureDay = math.max(
            0,
            math.floor(Internal.Finite(
                value.departureDay,
                math.floor(startedAt / 24)
            ))
        ),
        revision = Internal.Revision(value.revision),
    }
end

local function normalizeSettlementVisit(value)
    if type(value) ~= "table" then return nil end
    local startedAt = Internal.Timestamp(value.startedAt, 0)
    local expiresAt = Internal.Timestamp(value.expiresAt, 0)
    local visitID = Internal.SafeString(
        value.id,
        Constants.ID_MAX_LENGTH * 2
    )
    local settlementFactionID = Internal.SafeString(
        value.settlementFactionID,
        Constants.ID_MAX_LENGTH
    )
    local communityID = Internal.SafeString(
        value.communityID,
        Constants.ID_MAX_LENGTH
    )
    if not visitID or not settlementFactionID or not communityID
        or expiresAt <= startedAt
    then
        return nil
    end
    local pendingMemberIDs = Internal.NormalizeIDSet(
        value.pendingMemberIDs,
        Types.IsValidNPCID
    )
    local completedMemberIDs = Internal.NormalizeIDSet(
        value.completedMemberIDs,
        Types.IsValidNPCID
    )
    for npcID, _ in pairs(completedMemberIDs) do
        pendingMemberIDs[npcID] = nil
    end
    return {
        schemaVersion = Constants.MOBILE_SETTLEMENT_VISIT_SCHEMA_VERSION,
        id = visitID,
        kind = "settlement_admission",
        settlementFactionID = settlementFactionID,
        communityID = communityID,
        siteID = Internal.SafeString(value.siteID, Constants.ID_MAX_LENGTH),
        locationID = Internal.SafeString(
            value.locationID,
            Constants.ID_MAX_LENGTH
        ),
        startedAt = startedAt,
        expiresAt = expiresAt,
        pendingMemberIDs = pendingMemberIDs,
        completedMemberIDs = completedMemberIDs,
        revision = Internal.Revision(value.revision),
    }
end

local function normalizeSettlementArrival(value)
    if type(value) ~= "table" then return nil end
    local travel = normalizeMobileTravel(value.travel)
    local locationID = Internal.SafeString(
        value.locationID,
        Constants.ID_MAX_LENGTH
    )
    if not travel or not locationID then return nil end
    return {
        schemaVersion = Constants.MOBILE_SETTLEMENT_ARRIVAL_SCHEMA_VERSION,
        travel = travel,
        locationID = locationID,
        reportIDs = Internal.NormalizeIDSet(
            value.reportIDs,
            Types.IsValidNPCID
        ),
        startedAt = Internal.Timestamp(value.startedAt, travel.startedAt),
    }
end

-- Mobile groups deliberately store a primitive site snapshot rather than a
-- Community record. A mobile faction has no reservation, population ledger,
-- or home claim; the snapshot is only its current abstract staging point.

Internal.NormalizeTargetPoint = normalizeTargetPoint
Internal.NormalizeAmbient = normalizeAmbient
Internal.NormalizeStrategicTarget = normalizeStrategicTarget
Internal.NormalizePlayerRoam = normalizePlayerRoam
Internal.NormalizeMobileTravel = normalizeMobileTravel
Internal.NormalizeSettlementVisit = normalizeSettlementVisit
Internal.NormalizeSettlementArrival = normalizeSettlementArrival

require "PNC/Core/Factions/PNC_FactionTypes/Mobile"

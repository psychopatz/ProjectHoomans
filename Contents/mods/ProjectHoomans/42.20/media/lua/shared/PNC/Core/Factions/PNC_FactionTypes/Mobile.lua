PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}

local Types = PNC.FactionTypes
Types.Internal = Types.Internal or {}

local Internal = Types.Internal
local Constants = PNC.FactionConstants
local EntityRef = PNC.EntityRef
local CommunityTypes = PNC.CommunityTypes
local normalizeAmbient = Internal.NormalizeAmbient
local normalizeStrategicTarget = Internal.NormalizeStrategicTarget
local normalizeMobileTravel = Internal.NormalizeMobileTravel
local normalizeSettlementArrival = Internal.NormalizeSettlementArrival
local normalizeSettlementVisit = Internal.NormalizeSettlementVisit
local normalizePlayerRoam = Internal.NormalizePlayerRoam

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
    local activity
    local travel
    local pendingSettlementArrival
    local visit
    local playerRoam
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
    travel = normalizeMobileTravel(source.travel)
    pendingSettlementArrival = normalizeSettlementArrival(
        source.pendingSettlementArrival
    )
    visit = normalizeSettlementVisit(source.visit)
    activity = Constants.VALID_MOBILE_ACTIVITY_STATES[
        source.activity
    ] and source.activity or Constants.MOBILE_ACTIVITY_STREET_ROAMING
    if activity == Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
        and not travel
    then
        activity = Constants.MOBILE_ACTIVITY_STREET_ROAMING
    end
    playerRoam = normalizePlayerRoam(source.playerRoam)
    if pathMode == Constants.MOBILE_PATH_PLAYER then
        playerRoam = playerRoam or {
            phase = Constants.MOBILE_PLAYER_ROAM_PHASE_APPROACH,
            area = nil,
            untilAt = 0,
            lastArrivalAt = 0,
            lastRollDay = -1,
        }
    else
        playerRoam = nil
    end
    return {
        schemaVersion = Constants.MOBILE_GROUP_SCHEMA_VERSION,
        active = true,
        pathMode = pathMode,
        controlMode = controlMode,
        strategicTarget = strategicTarget,
        ambient = ambient,
        activity = activity,
        travel = travel,
        pendingSettlementArrival = pendingSettlementArrival,
        visit = visit,
        playerRoam = playerRoam,
        lastDepartureAt = source.lastDepartureAt == nil
            and -1 or math.max(-1, math.floor(Internal.Finite(
                source.lastDepartureAt,
                -1
            ))),
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

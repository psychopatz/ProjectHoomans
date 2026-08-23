PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants
local EntityRef = PNC.EntityRef
local IncidentDefinitions = PNC.FactionIncidentDefinitions

local function normalizeIncidentTags(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, enabled in pairs(value) do
        key = Internal.SafeString(key, Constants.TAG_KEY_MAX_LENGTH)
        if key and enabled == true then output[key] = true end
    end
    return output
end

function Types.NormalizeIncident(
    value,
    relationSourceFactionID,
    relationTargetFactionID
)
    local source = type(value) == "table" and value or {}
    local id = Internal.SafeString(
        source.id,
        Constants.INCIDENT_ID_MAX_LENGTH
    )
    local incidentType = Internal.SafeString(
        source.type,
        Constants.INCIDENT_TYPE_MAX_LENGTH
    )
    local definition = IncidentDefinitions
        and IncidentDefinitions.Get(incidentType) or nil
    local incidentSourceFactionID =
        Types.IsValidFactionID(source.sourceFactionID)
        and source.sourceFactionID or nil
    local incidentTargetFactionID =
        Types.IsValidFactionID(source.targetFactionID)
        and source.targetFactionID or nil
    local pairMatches = (
        incidentSourceFactionID == relationSourceFactionID
        and incidentTargetFactionID == relationTargetFactionID
    ) or (
        incidentSourceFactionID == relationTargetFactionID
        and incidentTargetFactionID == relationSourceFactionID
    )
    if not id or not definition
        or not Types.IsValidFactionID(relationSourceFactionID)
        or not Types.IsValidFactionID(relationTargetFactionID)
        or relationSourceFactionID == relationTargetFactionID
        or not pairMatches
    then
        return nil
    end
    local actorKey = EntityRef.IsValid(source.actorKey)
        and source.actorKey or nil
    local subjectKey = EntityRef.IsValid(source.subjectKey)
        and source.subjectKey or nil
    return {
        id = id,
        type = incidentType,
        sourceFactionID = incidentSourceFactionID,
        targetFactionID = incidentTargetFactionID,
        actorKey = actorKey,
        subjectKey = subjectKey,
        occurredAt = Internal.Timestamp(source.occurredAt, 0),
        standingEffect = Internal.Clamp(
            source.standingEffect,
            Constants.STANDING_MIN,
            Constants.STANDING_MAX
        ),
        trustEffect = Internal.Clamp(
            source.trustEffect,
            Constants.TRUST_MIN,
            Constants.TRUST_MAX
        ),
        fearEffect = Internal.Clamp(
            source.fearEffect,
            -Constants.FEAR_MAX,
            Constants.FEAR_MAX
        ),
        grievanceEffect = Internal.Clamp(
            source.grievanceEffect,
            -Constants.GRIEVANCE_MAX,
            Constants.GRIEVANCE_MAX
        ),
        severity = Internal.Clamp(source.severity, 0, 1),
        public = source.public == true,
        witnessed = source.witnessed == true,
        preserve = source.preserve == true
            or definition.preserve == true,
        tags = normalizeIncidentTags(source.tags),
    }
end

function Internal.NormalizeRecentIncidentIDs(value)
    local output = {}
    local seen = {}
    if type(value) ~= "table" then return output end
    for index = 1, #value do
        local id = Internal.SafeString(
            value[index],
            Constants.INCIDENT_ID_MAX_LENGTH
        )
        if id and not seen[id] then
            seen[id] = true
            output[#output + 1] = id
        end
    end
    while #output > Internal.Tuning(
        "recentIncidentIDLimit",
        Constants.RECENT_INCIDENT_ID_LIMIT
    ) do
        table.remove(output, 1)
    end
    return output
end

function Internal.NormalizeIncidents(
    value,
    sourceFactionID,
    targetFactionID
)
    local output = {}
    local seen = {}
    for _, raw in pairs(type(value) == "table" and value or {}) do
        local incident = Types.NormalizeIncident(
            raw,
            sourceFactionID,
            targetFactionID
        )
        if incident and not seen[incident.id] then
            seen[incident.id] = true
            output[#output + 1] = incident
        end
    end
    table.sort(output, function(left, right)
        if left.occurredAt ~= right.occurredAt then
            return left.occurredAt < right.occurredAt
        end
        return left.id < right.id
    end)
    while #output > Internal.Tuning(
        "incidentHistoryLimit", Constants.INCIDENT_LIMIT
    ) do
        local weakestIndex
        for index, incident in ipairs(output) do
            if incident.preserve ~= true
                and (
                    not weakestIndex
                    or incident.severity
                        < output[weakestIndex].severity
                    or (
                        incident.severity
                            == output[weakestIndex].severity
                        and incident.occurredAt
                            < output[weakestIndex].occurredAt
                    )
                    or (
                        incident.severity
                            == output[weakestIndex].severity
                        and incident.occurredAt
                            == output[weakestIndex].occurredAt
                        and incident.id
                            < output[weakestIndex].id
                    )
                )
            then
                weakestIndex = index
            end
        end
        table.remove(output, weakestIndex or 1)
    end
    return output
end

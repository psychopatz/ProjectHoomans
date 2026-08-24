if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}

local Service = PNC.FactionIncidentService
local Internal = Service.Internal
local Constants = PNC.FactionConstants
local Math = PNC.FactionDiplomacyMath
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local Balance = PNC.FactionBalance

Service.RuntimeEpisodes = Service.RuntimeEpisodes or {}
Service.RuntimeCallbackIDs = Service.RuntimeCallbackIDs or {}
Service.RuntimeCallbackOrder =
    Service.RuntimeCallbackOrder or {}
Service.LastRuntimePumpAtMS =
    tonumber(Service.LastRuntimePumpAtMS) or 0

local function tuning(name, fallback)
    local value = Balance and Balance.Get and Balance.Get(name)
    return value == nil and fallback or value
end

local function authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

local function finiteTimestamp(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
        or value < 0
    then
        return nil
    end
    return value
end

local function safeEntityKey(value)
    return EntityRef and EntityRef.IsValid
        and EntityRef.IsValid(value) and value or nil
end

local function containsID(relation, incidentID)
    for _, id in ipairs(relation.recentIncidentIDs or {}) do
        if id == incidentID then return true end
    end
    return false
end

local function pushID(relation, incidentID)
    relation.recentIncidentIDs =
        relation.recentIncidentIDs or {}
    relation.recentIncidentIDs[
        #relation.recentIncidentIDs + 1
    ] = incidentID
    while #relation.recentIncidentIDs
        > tuning("recentIncidentIDLimit",
            Constants.RECENT_INCIDENT_ID_LIMIT)
    do
        table.remove(relation.recentIncidentIDs, 1)
    end
end

local function trimIncidents(relation)
    while #relation.incidents > tuning(
        "incidentHistoryLimit", Constants.INCIDENT_LIMIT
    ) do
        local weakest
        for index, incident in ipairs(relation.incidents) do
            if incident.preserve ~= true
                and (
                    not weakest
                    or incident.severity
                        < relation.incidents[weakest].severity
                    or (
                        incident.severity
                            == relation.incidents[weakest].severity
                        and incident.occurredAt
                            < relation.incidents[weakest].occurredAt
                    )
                    or (
                        incident.severity
                            == relation.incidents[weakest].severity
                        and incident.occurredAt
                            == relation.incidents[weakest].occurredAt
                        and incident.id
                            < relation.incidents[weakest].id
                    )
                )
            then
                weakest = index
            end
        end
        table.remove(relation.incidents, weakest or 1)
    end
end

local function applyEffects(relation, definition, multiplier)
    multiplier = tonumber(multiplier) or 1
    relation.standing = Math.ClampStanding(
        relation.standing + definition.standing * multiplier
    )
    relation.trust = Math.ClampTrust(
        relation.trust + definition.trust * multiplier
    )
    relation.fear = Math.ClampFear(
        relation.fear + definition.fear * multiplier
    )
    relation.grievance = Math.ClampGrievance(
        relation.grievance + definition.grievance * multiplier
    )
end

local function warReasonFor(incidentType, leader)
    if incidentType == "member_killed" then
        return leader and "leader_killed" or "member_killed"
    end
    return incidentType == "member_attacked_severe"
        and "severe_assault" or "repeated_aggression"
end

Internal.tuning = tuning
Internal.authority = authority
Internal.finiteTimestamp = finiteTimestamp
Internal.safeEntityKey = safeEntityKey
Internal.containsID = containsID
Internal.pushID = pushID
Internal.trimIncidents = trimIncidents
Internal.applyEffects = applyEffects
Internal.warReasonFor = warReasonFor

PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants
local DiplomacyMath = PNC.FactionDiplomacyMath

function Types.NormalizeRelation(
    value,
    sourceFactionID,
    targetFactionID
)
    if not Types.IsValidFactionID(sourceFactionID)
        or not Types.IsValidFactionID(targetFactionID)
        or sourceFactionID == targetFactionID
    then
        return nil
    end
    local source = type(value) == "table" and value or {}
    local relation = {
        schemaVersion = Constants.RELATION_SCHEMA_VERSION,
        targetFactionID = targetFactionID,
        standing = DiplomacyMath.ClampStanding(
            source.standing
        ),
        trust = DiplomacyMath.ClampTrust(source.trust),
        fear = DiplomacyMath.ClampFear(source.fear),
        grievance = DiplomacyMath.ClampGrievance(
            source.grievance
        ),
        state = Constants.VALID_RELATION_STATES[source.state]
            and source.state or "unknown",
        previousState =
            Constants.VALID_RELATION_STATES[
                source.previousState
            ] and source.previousState or "unknown",
        atWar = source.atWar == true,
        allied = source.allied == true,
        truceUntil = Internal.Timestamp(source.truceUntil, 0),
        warStartedAt = Internal.Timestamp(source.warStartedAt, 0),
        warEndedAt = Internal.Timestamp(source.warEndedAt, 0),
        warReason = Constants.WAR_REASONS[source.warReason]
            and source.warReason or nil,
        initiatingFactionID =
            Types.IsValidFactionID(
                source.initiatingFactionID
            ) and source.initiatingFactionID or nil,
        triggeringIncidentID = Internal.SafeString(
            source.triggeringIncidentID,
            Constants.INCIDENT_ID_MAX_LENGTH
        ),
        incidents = Internal.NormalizeIncidents(
            source.incidents,
            sourceFactionID,
            targetFactionID
        ),
        recentIncidentIDs = Internal.NormalizeRecentIncidentIDs(
            source.recentIncidentIDs
        ),
        lastEvaluatedAt = Internal.Timestamp(
            source.lastEvaluatedAt,
            0
        ),
        revision = Internal.Revision(source.revision),
    }
    if relation.atWar then
        relation.allied = false
        relation.truceUntil = 0
    elseif relation.allied then
        relation.truceUntil = 0
    end
    relation.state = DiplomacyMath.ResolveState(
        relation,
        relation.lastEvaluatedAt
    )
    return relation
end

function Types.NewRelation(sourceFactionID, targetFactionID)
    return Types.NormalizeRelation(
        nil,
        sourceFactionID,
        targetFactionID
    )
end

-- Pairwise faction-relation invariant checks.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}
local Validation = PNC.FactionValidation
local Internal = Validation.Internal
local Factions = PNC.Factions
local Constants = PNC.FactionConstants
local Balance = PNC.FactionBalance
local addIssue = Internal.AddIssue
local newResult = Internal.NewResult

local function checkRelationInto(
    result,
    sourceID,
    targetID,
    relation
)
    result.checks = result.checks + 1
    if relation.targetFactionID ~= targetID then
        addIssue(result, "error", "relation_target_mismatch",
            sourceID .. "->" .. targetID)
    end
    local ranges = {
        standing = {
            Constants.STANDING_MIN, Constants.STANDING_MAX,
        },
        trust = { Constants.TRUST_MIN, Constants.TRUST_MAX },
        fear = { Constants.FEAR_MIN, Constants.FEAR_MAX },
        grievance = {
            Constants.GRIEVANCE_MIN, Constants.GRIEVANCE_MAX,
        },
    }
    for name, limits in pairs(ranges) do
        local value = tonumber(relation[name])
        if not value or value < limits[1] or value > limits[2] then
            addIssue(result, "error", "metric_out_of_range",
                sourceID .. "->" .. targetID .. ":" .. name)
        end
    end
    if relation.atWar == true and relation.allied == true then
        addIssue(result, "error", "war_and_alliance",
            sourceID .. "->" .. targetID)
    end
    if relation.atWar == true
        and (tonumber(relation.truceUntil) or 0) > 0
    then
        addIssue(result, "error", "war_and_truce",
            sourceID .. "->" .. targetID)
    end
    local incidentIDs = {}
    for _, incident in ipairs(relation.incidents or {}) do
        if incidentIDs[incident.id] then
            addIssue(result, "error", "duplicate_incident_id",
                tostring(incident.id))
        end
        incidentIDs[incident.id] = true
    end
    if #(relation.incidents or {}) > (
        Balance and Balance.Get("incidentHistoryLimit")
            or Constants.INCIDENT_LIMIT
    ) then
        addIssue(result, "error", "incident_history_unbounded",
            sourceID .. "->" .. targetID)
    end
    if #(relation.recentIncidentIDs or {})
        > (
            Balance
            and Balance.Get("recentIncidentIDLimit")
            or Constants.RECENT_INCIDENT_ID_LIMIT
        )
    then
        addIssue(result, "error", "recent_incident_cache_unbounded",
            sourceID .. "->" .. targetID)
    end
end

function Validation.CheckRelation(sourceID, targetID)
    local result = newResult(
        "relation:" .. tostring(sourceID)
            .. "->" .. tostring(targetID)
    )
    local source = Factions.Registry.byID[sourceID]
    local target = Factions.Registry.byID[targetID]
    local relation = source and source.relations[targetID]
    if not source or not target or not relation then
        addIssue(result, "error", "relation_missing",
            result.scope)
        return result
    end
    checkRelationInto(result, sourceID, targetID, relation)
    local reverse = target.relations[sourceID]
    if relation.atWar == true
        and (not reverse or reverse.atWar ~= true)
    then
        addIssue(result, "error", "asymmetric_war", result.scope)
    end
    if relation.allied == true
        and (not reverse or reverse.allied ~= true)
    then
        addIssue(result, "error", "asymmetric_alliance",
            result.scope)
    end
    local forwardTruce = tonumber(relation.truceUntil) or 0
    local reverseTruce = tonumber(
        reverse and reverse.truceUntil
    ) or 0
    if forwardTruce ~= reverseTruce then
        addIssue(result, "error", "asymmetric_truce",
            result.scope)
    end
    return result
end

Internal.CheckRelationInto = checkRelationInto

return Validation

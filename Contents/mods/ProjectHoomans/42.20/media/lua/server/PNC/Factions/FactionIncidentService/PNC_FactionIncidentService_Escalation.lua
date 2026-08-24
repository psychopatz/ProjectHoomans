if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}

local Service = PNC.FactionIncidentService
local Internal = Service.Internal
local Factions = PNC.Factions
local tuning = Internal.tuning
local warReasonFor = Internal.warReasonFor

local function maybeEscalate(
    actorFactionID,
    victimFactionID,
    incident,
    relation,
    spec
)
    if Factions.AreAtWar(actorFactionID, victimFactionID) then
        return false, "already_at_war"
    end
    local victimFaction = Factions.Registry.byID[victimFactionID]
    local policy = victimFaction and victimFaction.policy or {}
    local at = incident.occurredAt
    local truceUntil = Factions.GetTruceUntil(
        actorFactionID,
        victimFactionID
    )
    local leader = spec.targetRecord
        and (
            spec.targetRecord.id == victimFaction.leaderNPCID
            or (
                spec.targetRecord.affiliation
                and spec.targetRecord.affiliation.rank == "leader"
            )
        )
    local shouldDeclare = truceUntil > at
    local reason = shouldDeclare and "truce_broken"
        or warReasonFor(incident.type, leader)
    if not shouldDeclare and incident.type == "member_killed" then
        shouldDeclare = leader
            or (tonumber(policy.retaliation) or 0.5)
                >= tuning("killedRetaliationMinimum", 0.25)
    elseif not shouldDeclare
        and incident.type == "member_attacked_severe"
    then
        local score = relation.grievance
            + (tonumber(policy.retaliation) or 0.5)
                * tuning("escalationRetaliationWeight", 35)
            + (tonumber(policy.aggression) or 0.5)
                * tuning("escalationAggressionWeight", 15)
        shouldDeclare = score
            >= (tonumber(policy.warThreshold) or 70)
            or leader
                and (tonumber(policy.retaliation) or 0.5)
                    >= tuning(
                        "leaderRetaliationMinimum", 0.25
                    )
    elseif not shouldDeclare
        and incident.type == "member_attacked_minor"
    then
        shouldDeclare = relation.state == "hostile"
            and (tonumber(policy.retaliation) or 0.5)
                >= tuning(
                    "hostileMinorRetaliationMinimum", 0.5
                )
    elseif not shouldDeclare
        and incident.type == "personal_grievance_report"
    then
        local rank = tostring(spec.authorityRank or "member")
        local influence = rank == "leader"
            and tuning("leaderAuthorityInfluence", 20)
            or rank == "second"
                and tuning("secondAuthorityInfluence", 15)
            or rank == "officer"
                and tuning("officerAuthorityInfluence", 10)
            or 0
        local score = relation.grievance + influence
            + (tonumber(policy.retaliation) or 0.5)
                * tuning("escalationRetaliationWeight", 35)
            + (tonumber(policy.aggression) or 0.5)
                * tuning("escalationAggressionWeight", 15)
        shouldDeclare = relation.state == "hostile"
            and score >= (tonumber(policy.warThreshold) or 70)
    end
    if not shouldDeclare then
        return false, "escalation_threshold_not_met"
    end
    return Factions.DeclareWar(
        victimFactionID,
        actorFactionID,
        {
            worldAgeHours = at,
            reason = reason,
            instigatorFactionID = victimFactionID,
            triggeringIncidentID = incident.id,
        }
    )
end

Internal.maybeEscalate = maybeEscalate

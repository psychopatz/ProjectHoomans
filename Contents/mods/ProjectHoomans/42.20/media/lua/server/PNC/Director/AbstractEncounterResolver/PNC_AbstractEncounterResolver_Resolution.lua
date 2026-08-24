if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractEncounterResolver = PNC.AbstractEncounterResolver or {}
PNC.AbstractEncounterResolverInternal =
    PNC.AbstractEncounterResolverInternal or {}

local Resolver = PNC.AbstractEncounterResolver
local H = PNC.AbstractEncounterResolverInternal
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Evaluator = PNC.AbstractEncounterEvaluator
local Combat = PNC.AbstractCombatResolver

function Resolver.Resolve(report)
    local participantIDs = type(report and report.participants) == "table"
        and report.participants or {}
    local first = report and Groups.Get(report.initiatorId or participantIDs[1]) or nil
    local second = report and Groups.Get(report.targetId or participantIDs[2]) or nil
    local location = report and Locations.Get(report.locationId) or nil
    local at = Store.WorldAgeHours()
    if not first or not second or not location
        or first.location.id ~= location.id or second.location.id ~= location.id
        or first.state == "TRAVELING" or second.state == "TRAVELING"
    then
        report.outcome, report.reasonEnded = "VOID", "PARTICIPANTS_SEPARATED"
        Store.Touch("abstract_encounter_voided")
        return report
    end
    -- This is the final gate before any strategic mutation.
    if PNC.AbstractEncounters.IsPlayerNearby(location) then
        report.outcome = "MATERIALIZATION_REQUIRED"
        report.reasonEnded = "PLAYER_OBSERVATION_SAFETY"
        report.abstractResolutionAllowed = false
        Resolver.Metrics.materializationRequired = Resolver.Metrics.materializationRequired + 1
        Store.Touch("abstract_encounter_materialization_required")
        Store.Emit("GROUP_MATERIALIZATION_REQUESTED", { encounterId = report.id,
            locationId = location.id, participantIds = report.participants })
        return report
    end
    if first.activeEncounterId or second.activeEncounterId then return nil, "participant_locked" end
    local saved = { [first.id] = H.SaveState(first), [second.id] = H.SaveState(second) }
    first.activeEncounterId, second.activeEncounterId = report.id, report.id
    Groups.SetState(first, "ENGAGED", at, at)
    Groups.SetState(second, "ENGAGED", at, at)
    local context = Evaluator.BuildContext(report, first, second, location)
    local evaluations = Evaluator.Evaluate(context, first, second)
    report.relationship = context.relationship
    report.relativeStrength = context.initiatorThreat.relativeStrength
    report.combatSummary = { [first.id] = context.initiatorCombatProfile,
        [second.id] = context.targetCombatProfile }
    report.behaviorSummary = { [first.id] = context.initiatorBehavior,
        [second.id] = context.targetBehavior }
    report.intentScores = evaluations
    report.selectedIntents = { [first.id] = evaluations[first.id].selected,
        [second.id] = evaluations[second.id].selected }
    Store.Emit("ABSTRACT_ENCOUNTER_EVALUATED", { encounterId = report.id,
        intents = report.selectedIntents })
    local actor, target, hostileIntent = H.ChooseHostile(first, second, evaluations)
    if hostileIntent == "ATTACK" then
        H.InterruptCombat(first, second, at)
        report.combatResult = Combat.Resolve(context, first, second, location)
        report.outcome = report.combatResult.outcome
        report.reasonEnded = report.combatResult.reasonEnded
    elseif hostileIntent == "EXTORT" or hostileIntent == "ROB" then
        local response = H.HostileResponse(actor, target, evaluations[actor.id],
            evaluations[target.id], hostileIntent, report.seed)
        report.hostileInteraction = { actorId = actor.id, targetId = target.id,
            type = hostileIntent, response = response }
        if response == "COMPLY" then
            if hostileIntent == "ROB" and target.action and PNC.AbstractActions then
                PNC.AbstractActions.Interrupt(target, "abstract_robbery", at)
            end
            report.resourceChanges = H.Transfer(actor, target, hostileIntent, report.seed)
            target.morale = math.max(0, (tonumber(target.morale) or 0.65) - 0.08)
            report.outcome = hostileIntent .. "_COMPLIED"
            report.reasonEnded = "TARGET_COMPLIED"
            Store.Emit(hostileIntent == "ROB" and "ABSTRACT_ROBBERY_RESOLVED"
                or "ABSTRACT_EXTORTION_RESOLVED", report.hostileInteraction)
        elseif response == "RESIST_ATTACK" then
            H.InterruptCombat(first, second, at)
            report.combatResult = Combat.Resolve(context, actor, target, location)
            report.outcome = report.combatResult.outcome
            report.reasonEnded = "HOSTILE_INTERACTION_RESISTED"
        else
            report.outcome = hostileIntent .. "_REFUSED"
            report.reasonEnded = "ESCALATION_NOT_JUSTIFIED"
        end
    else
        local fleeGroup = evaluations[first.id].selected == "FLEE" and first
            or evaluations[second.id].selected == "FLEE" and second or nil
        local avoidGroup = evaluations[first.id].selected == "AVOID" and first
            or evaluations[second.id].selected == "AVOID" and second or nil
        if fleeGroup then
            local threat = fleeGroup == first and second or first
            local _, _, changes = H.Displace(fleeGroup, threat, location, at, true, report.seed)
            report.resourceChanges = { [fleeGroup.id] = changes }
            report.moraleChanges = { [fleeGroup.id] = fleeGroup.morale }
            report.outcome, report.reasonEnded = "FLEE", "THREAT_AVOIDANCE"
        elseif avoidGroup then
            local threat = avoidGroup == first and second or first
            H.Displace(avoidGroup, threat, location, at, false, report.seed)
            report.outcome, report.reasonEnded = "AVOID", "CONTACT_AVOIDED"
        else
            report.outcome = (evaluations[first.id].selected == "NEGOTIATE"
                or evaluations[second.id].selected == "NEGOTIATE")
                and "NEGOTIATE" or "IGNORE"
            report.reasonEnded = "NON_COMBAT"
        end
    end
    first.activeEncounterId, second.activeEncounterId = nil, nil
    first.recentEncounterId, second.recentEncounterId = report.id, report.id
    H.RestoreState(first, saved[first.id], at)
    H.RestoreState(second, saved[second.id], at)
    if #(first.memberIds or {}) == 0 then
        Groups.Remove(first.id, "abstract_combat_destroyed")
    end
    if #(second.memberIds or {}) == 0 then
        Groups.Remove(second.id, "abstract_combat_destroyed")
    end
    Resolver.Metrics.resolved = Resolver.Metrics.resolved + 1
    Store.Touch("abstract_encounter_resolved")
    Store.Emit("ABSTRACT_ENCOUNTER_RESOLVED", report)
    return report
end

return Resolver


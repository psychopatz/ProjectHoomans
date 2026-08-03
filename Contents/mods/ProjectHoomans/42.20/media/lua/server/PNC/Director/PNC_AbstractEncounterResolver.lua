-- Bounded encounter queue and application of non-combat/combat outcomes.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractEncounterResolver = PNC.AbstractEncounterResolver or {}

local Resolver = PNC.AbstractEncounterResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Evaluator = PNC.AbstractEncounterEvaluator
local Combat = PNC.AbstractCombatResolver

Resolver.Queue = Resolver.Queue or {}
Resolver.QueuedIDs = Resolver.QueuedIDs or {}
Resolver.Metrics = Resolver.Metrics or { queued = 0, resolved = 0,
    deferred = 0, materializationRequired = 0,
    processingRuns = 0, totalProcessingMS = 0 }
Resolver.Metrics.processingRuns = tonumber(Resolver.Metrics.processingRuns) or 0
Resolver.Metrics.totalProcessingMS = tonumber(Resolver.Metrics.totalProcessingMS) or 0

local function findReport(id)
    for _, report in ipairs(Store.Registry.encounters) do
        if report.id == id then return report end
    end
end

function Resolver.Enqueue(report)
    if not report or report.abstractResolutionAllowed ~= true then return false end
    if Resolver.QueuedIDs[report.id] then return false end
    Resolver.Queue[#Resolver.Queue + 1] = { encounterId = report.id, attempts = 0 }
    Resolver.QueuedIDs[report.id] = true
    Resolver.Metrics.queued = Resolver.Metrics.queued + 1
    return true
end

local function saveState(group)
    return { state = group.state, startedAt = group.stateStartedAt,
        endsAt = group.stateEndsAt }
end

local function restoreState(group, saved, at)
    if group.state ~= "ENGAGED" then return end
    if group.action then
        Groups.SetState(group, "PERFORMING_ACTION", saved.startedAt,
            group.action.endsAt)
    else
        Groups.SetState(group, saved.state == "ENGAGED" and "IDLE" or saved.state,
            saved.startedAt or at, saved.endsAt or at)
    end
end

local function transfer(actor, target, intent, seed)
    local fraction = intent == "ROB" and 0.22 or 0.12
    local changes = { [actor.id] = {}, [target.id] = {} }
    for _, category in ipairs({ "food", "water", "ammo", "medical" }) do
        local available = math.max(0, tonumber(target.resources[category]) or 0)
        local variance = 0.80 + PNC.AbstractScavengeResolver.Unit(seed, category) * 0.40
        local amount = math.min(available, math.floor(available * fraction * variance + 0.5))
        target.resources[category] = available - amount
        actor.resources[category] = math.max(0,
            (tonumber(actor.resources[category]) or 0) + amount)
        changes[actor.id][category] = amount
        changes[target.id][category] = -amount
    end
    Groups.MarkCombatProfileDirty(actor, "hostile_resource_transfer")
    Groups.MarkCombatProfileDirty(target, "hostile_resource_transfer")
    actor.revision, target.revision = actor.revision + 1, target.revision + 1
    Store.Touch("abstract_resource_transfer")
    return changes
end

local function hostileResponse(actor, target, actorEvaluation, targetEvaluation,
    intent, seed)
    local targetBehavior = targetEvaluation.components
    local targetRatio = targetEvaluation.components.relativeStrength
    local weakness = math.max(0, math.min(1, (1 - targetRatio) / 0.8))
    local compliance = targetBehavior.caution * 0.35 + weakness * 0.45
        + (1 - targetBehavior.morale) * 0.20
    if PNC.AbstractScavengeResolver.Unit(seed, "compliance:" .. target.id)
        <= compliance
    then return "COMPLY" end
    local escalation = actorEvaluation.components.aggression * 0.45
        + actorEvaluation.components.desperation * 0.25
        + actorEvaluation.components.advantage * 0.30
    return escalation >= (intent == "ROB" and 0.58 or 0.70)
        and "RESIST_ATTACK" or "REFUSE"
end

Resolver.EvaluateHostileResponse = hostileResponse

local function displace(group, threat, location, at, strong, seed)
    if PNC.AbstractActions and group.action then
        PNC.AbstractActions.Interrupt(group, strong and "flee" or "avoid", at)
    end
    local expiry = at + Config.Retreat.RECENT_THREAT_COOLDOWN_HOURS
    Groups.RememberThreat(group, location.id, threat.id, expiry, at)
    local resourceChanges = {}
    if strong then
        group.previousMission = { type = group.mission,
            targetLocationId = group.targetLocation and group.targetLocation.id or nil }
        Groups.SetMission(group, "FLEE", at, true)
        group.morale = math.max(0, (tonumber(group.morale) or 0.65)
            - Config.Retreat.FLEE_MORALE_PENALTY)
        for _, category in ipairs({ "food", "water", "materials" }) do
            local available = math.max(0, tonumber(group.resources[category]) or 0)
            local loss = math.floor(available * Config.Retreat.ABANDON_RESOURCE_FRACTION
                * PNC.AbstractScavengeResolver.Unit(seed, "abandon:" .. category) + 0.5)
            group.resources[category] = available - loss
            resourceChanges[category] = -loss
        end
    end
    local fallback = PNC.AbstractTraversal.ChooseFallback(group, location.id)
    if fallback and PNC.AbstractTraversal.Begin(group, fallback, at) then
        Store.Emit(strong and "ABSTRACT_GROUP_RETREATED" or "ABSTRACT_GROUP_AVOIDED",
            { groupId = group.id, threatGroupId = threat.id,
                fromLocationId = location.id, targetLocationId = fallback.id })
        return true, fallback.id, resourceChanges
    end
    Groups.SetState(group, strong and "RETREATING" or "IDLE", at, at)
    return false, nil, resourceChanges
end

local function chooseHostile(first, second, evaluations)
    local priority = { ATTACK = 3, ROB = 2, EXTORT = 1 }
    local a, b = evaluations[first.id].selected, evaluations[second.id].selected
    if (priority[a] or 0) == 0 and (priority[b] or 0) == 0 then return nil end
    if (priority[b] or 0) > (priority[a] or 0) then return second, first, b end
    return first, second, a
end

local function interruptCombat(first, second, at)
    if not PNC.AbstractActions then return end
    if first.action then PNC.AbstractActions.Interrupt(first, "abstract_combat", at) end
    if second.action then PNC.AbstractActions.Interrupt(second, "abstract_combat", at) end
end

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
    local saved = { [first.id] = saveState(first), [second.id] = saveState(second) }
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
    local actor, target, hostileIntent = chooseHostile(first, second, evaluations)
    if hostileIntent == "ATTACK" then
        interruptCombat(first, second, at)
        report.combatResult = Combat.Resolve(context, first, second, location)
        report.outcome = report.combatResult.outcome
        report.reasonEnded = report.combatResult.reasonEnded
    elseif hostileIntent == "EXTORT" or hostileIntent == "ROB" then
        local response = hostileResponse(actor, target, evaluations[actor.id],
            evaluations[target.id], hostileIntent, report.seed)
        report.hostileInteraction = { actorId = actor.id, targetId = target.id,
            type = hostileIntent, response = response }
        if response == "COMPLY" then
            if hostileIntent == "ROB" and target.action and PNC.AbstractActions then
                PNC.AbstractActions.Interrupt(target, "abstract_robbery", at)
            end
            report.resourceChanges = transfer(actor, target, hostileIntent, report.seed)
            target.morale = math.max(0, (tonumber(target.morale) or 0.65) - 0.08)
            report.outcome = hostileIntent .. "_COMPLIED"
            report.reasonEnded = "TARGET_COMPLIED"
            Store.Emit(hostileIntent == "ROB" and "ABSTRACT_ROBBERY_RESOLVED"
                or "ABSTRACT_EXTORTION_RESOLVED", report.hostileInteraction)
        elseif response == "RESIST_ATTACK" then
            interruptCombat(first, second, at)
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
            local _, _, changes = displace(fleeGroup, threat, location, at, true, report.seed)
            report.resourceChanges = { [fleeGroup.id] = changes }
            report.moraleChanges = { [fleeGroup.id] = fleeGroup.morale }
            report.outcome, report.reasonEnded = "FLEE", "THREAT_AVOIDANCE"
        elseif avoidGroup then
            local threat = avoidGroup == first and second or first
            displace(avoidGroup, threat, location, at, false, report.seed)
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
    restoreState(first, saved[first.id], at)
    restoreState(second, saved[second.id], at)
    Resolver.Metrics.resolved = Resolver.Metrics.resolved + 1
    Store.Touch("abstract_encounter_resolved")
    Store.Emit("ABSTRACT_ENCOUNTER_RESOLVED", report)
    return report
end

function Resolver.ProcessBatch(_, budget)
    local startedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    budget = math.max(1, math.floor(tonumber(budget) or Config.EncounterQueue.WORK_BUDGET))
    local processed = 0
    while processed < budget and #Resolver.Queue > 0 do
        local entry = table.remove(Resolver.Queue, 1)
        Resolver.QueuedIDs[entry.encounterId] = nil
        local report = findReport(entry.encounterId)
        if report and (report.outcome == "QUEUED" or report.outcome == "DETECTED") then
            local resolved, reason = Resolver.Resolve(report)
            if not resolved and reason == "participant_locked"
                and entry.attempts < Config.EncounterQueue.MAX_ATTEMPTS
            then
                entry.attempts = entry.attempts + 1
                Resolver.Queue[#Resolver.Queue + 1] = entry
                Resolver.QueuedIDs[entry.encounterId] = true
                Resolver.Metrics.deferred = Resolver.Metrics.deferred + 1
            else processed = processed + 1 end
        else processed = processed + 1 end
    end
    if PNC.AbstractEncounters and PNC.AbstractEncounters.TrimHistory then
        PNC.AbstractEncounters.TrimHistory()
    end
    local finishedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or startedAt
    Resolver.Metrics.processingRuns = Resolver.Metrics.processingRuns + 1
    Resolver.Metrics.totalProcessingMS = Resolver.Metrics.totalProcessingMS
        + math.max(0, (tonumber(finishedAt) or 0) - (tonumber(startedAt) or 0))
    return processed
end

return Resolver

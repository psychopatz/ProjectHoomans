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

function H.Transfer(actor, target, intent, seed)
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

function H.HostileResponse(actor, target, actorEvaluation, targetEvaluation,
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

Resolver.EvaluateHostileResponse = H.HostileResponse

return Resolver


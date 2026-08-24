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

function H.Displace(group, threat, location, at, strong, seed)
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

function H.ChooseHostile(first, second, evaluations)
    local priority = { ATTACK = 3, ROB = 2, EXTORT = 1 }
    local a, b = evaluations[first.id].selected, evaluations[second.id].selected
    if (priority[a] or 0) == 0 and (priority[b] or 0) == 0 then return nil end
    if (priority[b] or 0) > (priority[a] or 0) then return second, first, b end
    return first, second, a
end

function H.InterruptCombat(first, second, at)
    if not PNC.AbstractActions then return end
    if first.action then PNC.AbstractActions.Interrupt(first, "abstract_combat", at) end
    if second.action then PNC.AbstractActions.Interrupt(second, "abstract_combat", at) end
end

return Resolver


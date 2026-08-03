-- Morale break/escape decision and fallback travel application.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractRetreatResolver = PNC.AbstractRetreatResolver or {}

local Retreat = PNC.AbstractRetreatResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups

local function unit(seed, salt)
    return PNC.AbstractScavengeResolver.Unit(seed, salt)
end

function Retreat.Decide(group, morale, relativeStrength, myMobility,
    enemyMobility, casualtiesThisRound, behavior, seed)
    local tuning = Config.Retreat
    local caution = behavior and behavior.stable and behavior.stable.caution or 0.5
    local discipline = behavior and behavior.stable and behavior.stable.discipline or 0.5
    local should = morale <= tuning.MORALE_BREAK_THRESHOLD
        or relativeStrength <= tuning.OUTMATCHED_RATIO
        or casualtiesThisRound > 0 and morale < 0.55
    if not should then return { attempted = false, succeeded = false } end
    local chance = tuning.BASE_SUCCESS + (tonumber(myMobility) or 0) * 0.18
        - (tonumber(enemyMobility) or 0) * 0.12 + caution * 0.12
        - discipline * 0.04
    chance = math.max(0.12, math.min(0.90, chance))
    return { attempted = true, succeeded = unit(seed, "retreat:" .. group.id) <= chance,
        chance = chance, morale = morale, relativeStrength = relativeStrength }
end

function Retreat.Apply(group, threatGroup, location, at, reason)
    if PNC.AbstractActions and group.action then
        PNC.AbstractActions.Interrupt(group, reason or "retreat", at)
    end
    group.previousMission = { type = group.mission,
        targetLocationId = group.targetLocation and group.targetLocation.id or nil }
    local expiry = at + Config.Retreat.RECENT_THREAT_COOLDOWN_HOURS
    Groups.RememberThreat(group, location.id, threatGroup and threatGroup.id,
        expiry, at)
    group.morale = math.max(0, (tonumber(group.morale) or 0.65)
        - Config.Retreat.FLEE_MORALE_PENALTY)
    Groups.SetMission(group, "FLEE", at, true)
    local fallback = PNC.AbstractTraversal and PNC.AbstractTraversal.ChooseFallback
        and PNC.AbstractTraversal.ChooseFallback(group, location.id) or nil
    if fallback then
        local ok = PNC.AbstractTraversal.Begin(group, fallback, at)
        if ok then
            Store.Emit("ABSTRACT_GROUP_RETREATED", { groupId = group.id,
                threatGroupId = threatGroup and threatGroup.id,
                fromLocationId = location.id, targetLocationId = fallback.id,
                reason = reason })
            return true, "retreating", fallback.id
        end
    end
    Groups.SetState(group, "RETREATING", at, at)
    return false, "no_fallback"
end

return Retreat

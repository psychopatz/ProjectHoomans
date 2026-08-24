if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Internal.mutateTreaty(
    firstFactionID,
    secondFactionID,
    incidentType,
    options,
    mutate
)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local first, second, reason = Internal.relationPair(
        firstFactionID,
        secondFactionID
    )
    if not first then return false, reason end
    if first.status ~= "active" or second.status ~= "active" then
        return false, "faction_not_active"
    end
    options = type(options) == "table" and options or {}
    local suppliedAt = tonumber(options.worldAgeHours)
    if suppliedAt == nil or suppliedAt ~= suppliedAt
        or suppliedAt == math.huge or suppliedAt == -math.huge
        or suppliedAt < 0
    then
        return false, "invalid_world_age"
    end
    if options.instigatorFactionID ~= nil
        and options.instigatorFactionID ~= firstFactionID
        and options.instigatorFactionID ~= secondFactionID
    then
        return false, "invalid_instigator_faction"
    end
    local at = suppliedAt
    local forward = Internal.currentRelation(first, secondFactionID)
    local reverse = Internal.currentRelation(second, firstFactionID)
    local oldForward = Internal.copy(forward)
    local oldReverse = Internal.copy(reverse)
    local ok, mutationReason = mutate(
        forward,
        reverse,
        at,
        options,
        first,
        second
    )
    if ok == false then
        return false, mutationReason, Internal.copy(forward)
    end
    local forwardState = forward.state
    local reverseState = reverse.state
    local resolvedForward =
        PNC.FactionDiplomacyMath.ResolveState(
        forward,
        at
    )
    local resolvedReverse =
        PNC.FactionDiplomacyMath.ResolveState(
        reverse,
        at
    )
    if resolvedForward ~= forwardState then
        forward.previousState = forwardState
        forward.state = resolvedForward
    end
    if resolvedReverse ~= reverseState then
        reverse.previousState = reverseState
        reverse.state = resolvedReverse
    end
    Internal.appendAudit(
        forward,
        firstFactionID,
        secondFactionID,
        incidentType,
        at,
        options.instigatorFactionID or firstFactionID
    )
    Internal.appendAudit(
        reverse,
        secondFactionID,
        firstFactionID,
        incidentType,
        at,
        options.instigatorFactionID or firstFactionID
    )
    if Types.AreEqual(oldForward, forward)
        and Types.AreEqual(oldReverse, reverse)
    then
        return false, "unchanged", Internal.copy(forward)
    end
    forward.revision = oldForward.revision + 1
    reverse.revision = oldReverse.revision + 1
    first.relations[secondFactionID] = forward
    second.relations[firstFactionID] = reverse
    Internal.touchFaction(first)
    Internal.touchFaction(second)
    Internal.touchRegistry()
    Internal.reconcilePair(
        firstFactionID,
        secondFactionID,
        "diplomacy_" .. incidentType,
        at
    )
    return true, incidentType, Internal.copy(forward)
end

return Factions

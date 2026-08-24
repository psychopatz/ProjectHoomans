if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Combat = PNC.AbstractCombatResolver
local Profiles = PNC.AbstractCombatProfile
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local H = Combat.Internal

function H.Finalize(result, first, second, participants, morale,
    retreating, ended)
    local firstPower = H.Alive(first) > 0 and (Profiles.Get(first, false).overallPower or 0) or 0
    local secondPower = H.Alive(second) > 0 and (Profiles.Get(second, false).overallPower or 0) or 0
    local winner
    if retreating then winner = retreating.id == first.id and second.id or first.id
    elseif firstPower > secondPower * 1.08 then winner = first.id
    elseif secondPower > firstPower * 1.08 then winner = second.id end
    result.winnerId = winner
    result.reasonEnded = ended or (H.Alive(first) == 0 or H.Alive(second) == 0)
        and "DESTRUCTION" or "MAX_ROUNDS"
    result.outcome = result.reasonEnded == "DESTRUCTION" and "DESTRUCTION"
        or result.reasonEnded == "RETREAT" and "WITHDRAWAL"
        or winner and "VICTORY" or "STALEMATE"
    for _, group in ipairs(participants) do
        result.participantResults[group.id] = {
            survivors = H.Alive(group), morale = group.morale,
            outcome = H.Alive(group) == 0 and "DESTROYED"
                or group == retreating and "WITHDRAWAL"
                or winner == group.id and "VICTORY" or "DEFEAT" }
        Groups.MarkCombatProfileDirty(group, "abstract_combat_resolved")
    end
    result.moraleChanges[first.id] = morale[first.id]
    result.moraleChanges[second.id] = morale[second.id]
    Store.Touch("abstract_combat_resolved")
    Store.Emit("ABSTRACT_COMBAT_RESOLVED", result)
    return result
end

return Combat


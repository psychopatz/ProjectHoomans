-- Horde-count and attack-retreat policy for live FollowOwner ticks.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local H = Companion.Internal.FollowOwnerCombatHorde
if type(H) ~= "table" then
    return Companion
end

local Const = H.Const
local CombatTactics = H.CombatTactics
local BehaviorCombat = H.BehaviorCombat
local Perception = H.Perception
local TryRespondToImmediateThreat = H.TryRespondToImmediateThreat
local SetFollowMode = H.SetFollowMode

function H.TryHandle(record, zombie, followState, hazard, retreatState, now)
    local hordeCount = tonumber(hazard and hazard.count) or 0
    local combatHordeCount = hazard and hazard.combatCountReady
        and tonumber(hazard.combatCount) or nil
    local combatHordeCacheDue
    local attackRetreatTriggered
    local combatTarget

    -- A near miss does not necessarily populate recentThreat, but it still
    -- arms the combat retreat marker. Do not let owner-priority formation
    -- logic hide that marker while a four-zombie horde is present.
    if combatHordeCount == nil then
        combatHordeCacheDue = now >= (
            tonumber(followState.nextCombatHordeCountAt) or 0
        )
        combatHordeCount = tonumber(followState.combatHordeCount) or hordeCount
    end
    if combatHordeCount == nil then combatHordeCount = 0 end
    if combatHordeCacheDue
        and Perception
        and Perception.CountEnemyZombies
    then
        combatHordeCount = Perception.CountEnemyZombies(
            record,
            Const.COMBAT_HORDE_RADIUS
        )
        followState.combatHordeCount = combatHordeCount
        followState.nextCombatHordeCountAt = now + (
            tonumber(Const.FOLLOW_COMBAT_HORDE_CACHE_MS) or 350
        )
    end
    attackRetreatTriggered = CombatTactics
        and CombatTactics.IsHordeAttackRetreatTriggered
        and CombatTactics.IsHordeAttackRetreatTriggered(
            retreatState,
            { hordeCount = combatHordeCount },
            now
        )
    if not attackRetreatTriggered then
        return false
    end
    if TryRespondToImmediateThreat(record, zombie) then
        SetFollowMode(record, "combat_retreat")
        return true
    end
    combatTarget = record.runtime and record.runtime.target or nil
    if combatTarget and combatTarget.kind == "zombie"
        and BehaviorCombat and BehaviorCombat.TickEngage
        and tostring(record.attackType or Const.ATTACK_TYPE_AUTO)
            ~= tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        BehaviorCombat.TickEngage(record, zombie, combatTarget)
        SetFollowMode(record, "combat_retreat")
        return true
    end
    return false
end

return Companion

local Internal = PNC.CombatDefense.Internal
local Const = PNC.Const

local function reactionOptions()
    return {
        kind = "npc_zombie_parry",
        stagger = true,
        hitForce = 0.92,
        durationMs = 280,
        pushDurationMs = 190,
        pushDistance = 0.42,
        stepDistance = 0.07,
    }
end

local function tryPush(npcBody, zombie, chance)
    local roll = Internal.RandomUnit()
    local options
    local pushed = false
    if roll < chance
        and PNC.CombatZombieReaction
        and PNC.CombatZombieReaction.Start
    then
        options = reactionOptions()
        pushed = PNC.CombatZombieReaction.Start(
            npcBody, zombie, options
        ) == true
        if pushed and PNC.Network
            and PNC.Network.BroadcastZombieReaction
        then
            PNC.Network.BroadcastZombieReaction(zombie, npcBody, options)
        end
    end
    return roll, pushed
end

local function markNearMiss(record, zombie, now)
    if PNC.CombatTactics and PNC.CombatTactics.MarkZombieNearMiss then
        PNC.CombatTactics.MarkZombieNearMiss(
            record,
            zombie and zombie.getX and zombie:getX() or record.x,
            zombie and zombie.getY and zombie:getY() or record.y,
            zombie and zombie.getZ and zombie:getZ() or record.z,
            now
        )
    end
end

function Internal.ResolveNearMiss(record, npcBody, zombie, now, chance)
    local pushRoll
    local pushed
    chance = tonumber(chance) or Internal.SettingNumber(
        "NPC_ZOMBIE_DEFENSE_PUSH_CHANCE",
        tonumber(Const.NPC_ZOMBIE_DEFENSE_PUSH_CHANCE) or 0.50,
        0,
        1
    )
    pushRoll, pushed = tryPush(npcBody, zombie, chance)
    markNearMiss(record, zombie, now)
    return pushRoll, pushed
end

local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local Core = PNC.Core
local Settings = PNC.Sandbox
local Stealth = PNC.Stealth
local Perception = PNC.Perception
local TraversalQuery = PNC.TraversalQuery
local State = ZombieAggro.State

function BiteInternal.ShouldPreventZombieAttack(record)
    return record ~= nil and (
        not Settings.CanZombieTargetRecord(record)
        or (
            Stealth
            and Stealth.ShouldSuppressZombieAggro
            and Stealth.ShouldSuppressZombieAggro(record)
        )
    )
end

function BiteInternal.GetBiteEntry(zombieId)
    return zombieId and State.bites and State.bites[zombieId] or nil
end

function BiteInternal.ActionState(zombie)
    return zombie and zombie.getActionStateName
        and tostring(zombie:getActionStateName() or "") or ""
end

function BiteInternal.RememberAttackLane(record, clear, reason)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.zombieAttackLane = {
        clear = clear == true,
        reason = tostring(reason or (clear and "clear" or "blocked")),
        checkedAt = Core.Now(),
    }
end

local function hasTraversableLane(zombie, npcBody)
    local canStep
    local reason
    if not TraversalQuery or not TraversalQuery.CanStep then
        return true, nil
    end
    canStep, reason = TraversalQuery.CanStep(
        zombie:getX(), zombie:getY(), zombie:getZ(),
        npcBody:getX(), npcBody:getY(), npcBody:getZ(),
        getCell and getCell() or nil
    )
    if canStep ~= true then
        return false, "bite_lane_" .. tostring(reason or "blocked")
    end
    return true, reason
end

local function hasVisibleLane(record, zombie, stepReason)
    local visible
    local kind
    if not Perception or not Perception.CanSeeWorldObject then
        return true, stepReason
    end
    visible, kind = Perception.CanSeeWorldObject(record, zombie)
    if kind ~= nil
        and (visible ~= true or kind == "clearthroughwindow")
    then
        return false, "bite_los_" .. tostring(kind or "blocked")
    end
    return true, kind or stepReason
end

function ZombieAggro.HasBiteLane(zombie, npcBody, record)
    local clear
    local reason
    if not zombie or not npcBody or not record then
        return false, "bite_lane_missing"
    end
    if math.abs(zombie:getZ() - npcBody:getZ()) >= 0.3 then
        return false, "bite_lane_floor"
    end
    clear, reason = hasTraversableLane(zombie, npcBody)
    if not clear then
        return false, reason
    end
    return hasVisibleLane(record, zombie, reason)
end

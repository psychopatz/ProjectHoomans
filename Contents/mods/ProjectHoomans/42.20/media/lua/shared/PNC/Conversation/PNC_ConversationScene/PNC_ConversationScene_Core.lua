local Scene = PNC.ConversationScene
local Internal = Scene.Internal

function Internal.Now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
end

function Internal.DistanceSq(first, second)
    local dx
    local dy
    if not first or not second
        or not first.getX or not second.getX
    then
        return math.huge
    end
    if first.getZ and second.getZ
        and math.abs(first:getZ() - second:getZ()) >= 1
    then
        return math.huge
    end
    dx = first:getX() - second:getX()
    dy = first:getY() - second:getY()
    return dx * dx + dy * dy
end

function Internal.IsAlive(value)
    return value ~= nil
        and (not value.isDead or value:isDead() ~= true)
end

function Internal.SameTarget(target, player, zombie, record)
    if not target then return false end
    if target == player or target == zombie then return true end
    if type(target) ~= "table" then return false end
    return tostring(target.id or "")
            == tostring(record and record.id or "")
        or target.worldObject == player
        or target.worldObject == zombie
end

function Internal.TargetsPlayer(target, player)
    if not target or not player then return false end
    if target == player then return true end
    return type(target) == "table"
        and (target.player == player or target.worldObject == player)
end

function Internal.EngineTargetsConversation(candidate, player, zombie)
    local target
    if not candidate or not candidate.getTarget then return false end
    target = candidate:getTarget()
    return target == player or target == zombie
end

function Internal.WorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
        or 0
end

function Internal.PlayerKey(player, callback)
    if not player or not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then
        return nil
    end
    return PNC.PlayerCharacters.GetEntityKey(player, {
        callback = callback or "conversation",
        worldAgeHours = Internal.WorldAgeHours(),
    })
end

function Internal.ApplyParley(record, zombie, reason)
    if PNC.BehaviorCommon and PNC.BehaviorCommon.ClearCombatTarget then
        PNC.BehaviorCommon.ClearCombatTarget(record, reason, zombie)
    else
        record.runtime = record.runtime or {}
        record.runtime.target = nil
    end
    record.runtime = record.runtime or {}
    record.runtime.attackAction = nil
    record.runtime.inCombatUntil = 0
    record.nextThinkAt = Internal.Now()
end

function Internal.SendCeasefireResult(player, ok, reason, value)
    local network = PNC.Network
    local command = PNC.Const
        and PNC.Const.CMD_CONVERSATION_CEASEFIRE_RESULT or nil
    if not command or not network or not network.Internal
        or not network.Internal.SendToPlayer
    then
        return false
    end
    return network.Internal.SendToPlayer(player, command, {
        ok = ok == true,
        reason = tostring(reason or "unknown"),
        factionID = value and value.factionID or nil,
        untilWorldAgeHours = value and value.untilWorldAgeHours or nil,
    })
end

-- Low-level engine body and corpse operations.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Internal = PNC.BodyLifecycle.Internal

function Internal.worldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours and tonumber(gameTime:getWorldAgeHours()) or 0
end

function Internal.itemFullType(item)
    return item and item.getFullType and tostring(item:getFullType() or "") or ""
end

function Internal.clearBodyCombat(zombie)
    if not zombie then
        return
    end
    if PNC.ZombieAggro and PNC.ZombieAggro.ClearForNPCBody then
        PNC.ZombieAggro.ClearForNPCBody(zombie)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    if zombie.setReanimate then
        zombie:setReanimate(false)
    end
end

function Internal.removeZombie(zombie)
    if not zombie then
        return false
    end
    Internal.clearBodyCombat(zombie)
    -- Match the proven Dynamic Trading V2 removal path. The zombie manager may
    -- keep a persisted shell eligible for reload; removing the concrete world
    -- object and square membership directly makes the transition deterministic
    -- and keeps errors visible instead of hiding them behind pcall.
    if zombie.removeFromWorld then
        zombie:removeFromWorld()
    end
    if zombie.removeFromSquare then
        zombie:removeFromSquare()
    end
    return true
end

function Internal.removeCorpse(corpse)
    local square
    if not corpse then
        return false
    end
    square = corpse.getSquare and corpse:getSquare() or nil
    if square and square.transmitRemoveItemFromSquare then
        pcall(square.transmitRemoveItemFromSquare, square, corpse)
    end
    if corpse.removeFromWorld then
        pcall(corpse.removeFromWorld, corpse)
    end
    if corpse.removeFromSquare then
        pcall(corpse.removeFromSquare, corpse)
    end
    if corpse.setSquare then
        pcall(corpse.setSquare, corpse, nil)
    end
    return true
end

function Internal.forEachCorpse(square, callback)
    local seen = {}
    local list
    local i
    local corpse
    if not square or type(callback) ~= "function" then
        return
    end
    list = square.getDeadBodys and square:getDeadBodys() or nil
    if list then
        for i = list:size() - 1, 0, -1 do
            corpse = list:get(i)
            if corpse and not seen[corpse] then
                seen[corpse] = true
                callback(corpse)
            end
        end
    end
    list = square.getStaticMovingObjects and square:getStaticMovingObjects() or nil
    if list then
        for i = list:size() - 1, 0, -1 do
            corpse = list:get(i)
            if corpse and not seen[corpse]
                and instanceof and instanceof(corpse, "IsoDeadBody")
            then
                seen[corpse] = true
                callback(corpse)
            end
        end
    end
end

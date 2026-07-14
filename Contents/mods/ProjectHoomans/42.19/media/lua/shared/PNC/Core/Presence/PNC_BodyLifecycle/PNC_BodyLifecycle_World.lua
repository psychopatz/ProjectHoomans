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

function Internal.addItemToContainer(container, item)
    if not container or not item then
        return false
    end
    if item.getContainer and item:getContainer() == container then
        return true
    end
    return container.AddItem and pcall(container.AddItem, container, item) or false
end

function Internal.clearBodyCombat(zombie)
    if not zombie then
        return
    end
    if PNC.ZombieAggro and PNC.ZombieAggro.ClearForNPCBody then
        pcall(PNC.ZombieAggro.ClearForNPCBody, zombie)
    end
    if zombie.clearAggroList then
        pcall(zombie.clearAggroList, zombie)
    end
    if zombie.setTarget then
        pcall(zombie.setTarget, zombie, nil)
    end
    if zombie.setAttackedBy then
        pcall(zombie.setAttackedBy, zombie, nil)
    end
    if zombie.setUseless then
        pcall(zombie.setUseless, zombie, true)
    end
    if zombie.setRunning then
        pcall(zombie.setRunning, zombie, false)
    end
    if zombie.setReanimate then
        pcall(zombie.setReanimate, zombie, false)
    end
end

function Internal.removeZombie(zombie)
    local ok
    local removed = false
    if not zombie then
        return false
    end
    Internal.clearBodyCombat(zombie)
    if VirtualZombieManager and VirtualZombieManager.instance
        and VirtualZombieManager.instance.removeZombieFromWorld
    then
        ok, removed = pcall(
            VirtualZombieManager.instance.removeZombieFromWorld,
            VirtualZombieManager.instance,
            zombie
        )
        removed = ok and removed == true
    end
    if not removed and zombie.removeFromWorld then
        pcall(zombie.removeFromWorld, zombie)
    end
    if not removed and zombie.removeFromSquare then
        pcall(zombie.removeFromSquare, zombie)
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

-- Low-level engine body and corpse operations.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Internal = PNC.BodyLifecycle.Internal

local function invalidateCorpseRender(corpse)
    local dirtyLevel
    if not corpse or not corpse.invalidateRenderChunkLevel then
        return
    end
    dirtyLevel = FBORenderChunk
        and FBORenderChunk.DIRTY_OBJECT_MODIFY or 66
    pcall(corpse.invalidateRenderChunkLevel, corpse, dirtyLevel)
end

local function squareAt(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

local function setCorpsePosition(corpse, x, y, z, square)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not corpse or not corpse.setX or not corpse.setY
        or not corpse.setZ or not x or not y or not z
    then
        return false, "CORPSE_POSITION_API_UNAVAILABLE"
    end
    corpse:setX(tonumber(x))
    corpse:setY(tonumber(y))
    corpse:setZ(tonumber(z))
    -- addCorpse() owns square membership. Only cross-tile transfers update the
    -- moving object's current square; repeatedly calling setCurrent() on a
    -- static body while it remains in one square can leave a stale render
    -- entry and produce the oversized shadow/duplicate-body artifact.
    if square and corpse.setCurrent then corpse:setCurrent(square) end
    invalidateCorpseRender(corpse)
    return true
end

local function announceCorpse(corpse)
    -- IsoGridSquare:addCorpse() sends an add packet for a client, but the
    -- dedicated server path requires GameServer.sendCorpse(). Announce only
    -- after membership has been verified so a failed handoff cannot create a
    -- client-side duplicate.
    if sendCorpse and corpse then
        pcall(sendCorpse, corpse)
    elseif GameServer and GameServer.sendCorpse and corpse then
        pcall(GameServer.sendCorpse, corpse)
    end
end

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

function Internal.moveCorpse(corpse, destination, x, y, z)
    local source = corpse and corpse.getSquare and corpse:getSquare() or nil
    local oldX = corpse and corpse.getX and corpse:getX() or nil
    local oldY = corpse and corpse.getY and corpse:getY() or nil
    local oldZ = corpse and corpse.getZ and corpse:getZ() or nil
    local newX = tonumber(x)
    local newY = tonumber(y)
    local newZ = tonumber(z)
    local attached = false

    if not corpse or not source or not destination then
        return false, "CORPSE_TRANSFER_SQUARE_UNAVAILABLE"
    end
    if source == destination then
        return false, "CORPSE_TRANSFER_SAME_SQUARE"
    end
    if not source.removeCorpse or not destination.addCorpse then
        return false, "CORPSE_TRANSFER_API_UNAVAILABLE"
    end
    if not corpse.setX or not corpse.setY or not corpse.setZ then
        return false, "CORPSE_TRANSFER_POSITION_API_UNAVAILABLE"
    end
    if not newX or not newY or not newZ then
        return false, "CORPSE_TRANSFER_POSITION_INVALID"
    end

    -- Move the existing engine object. This preserves the corpse's clothing,
    -- inventory, and mod data, while the square APIs keep the server/client
    -- world representation authoritative in both singleplayer and MP.
    source:removeCorpse(corpse, false)
    corpse:setX(newX + 0.5)
    corpse:setY(newY + 0.5)
    corpse:setZ(newZ)
    destination:addCorpse(corpse, false)

    Internal.forEachCorpse(destination, function(candidate)
        if candidate == corpse then attached = true end
    end)
    if attached then
        announceCorpse(corpse)
        return true
    end

    -- Do not leave a corpse detached if the engine rejected the destination
    -- insertion. Restore the exact prior object and coordinates.
    destination:removeCorpse(corpse, false)
    corpse:setX(oldX)
    corpse:setY(oldY)
    corpse:setZ(oldZ)
    source:addCorpse(corpse, false)
    announceCorpse(corpse)
    return false, "CORPSE_TRANSFER_NOT_ATTACHED"
end

function Internal.followCorpse(corpse, x, y, z)
    local source = corpse and corpse.getSquare and corpse:getSquare() or nil
    local destination = squareAt(x, y, z)
    local oldX = corpse and corpse.getX and corpse:getX() or nil
    local oldY = corpse and corpse.getY and corpse:getY() or nil
    local oldZ = corpse and corpse.getZ and corpse:getZ() or nil
    local attached = false

    if not corpse or not source then
        return false, "CORPSE_FOLLOW_SOURCE_UNAVAILABLE"
    end
    if not destination then
        return false, "CORPSE_FOLLOW_DESTINATION_UNAVAILABLE"
    end
    if not source.removeCorpse or not destination.addCorpse then
        return false, "CORPSE_FOLLOW_API_UNAVAILABLE"
    end

    -- Position updates inside one tile do not need a remove/add cycle. The
    -- corpse remains a real IsoDeadBody, so its vanilla renderer follows the
    -- coordinates while the square still owns the object.
    if source == destination then
        return setCorpsePosition(corpse, x, y, z, nil)
    end

    source:removeCorpse(corpse, false)
    local positioned = setCorpsePosition(corpse, x, y, z, destination)
    if not positioned then
        source:addCorpse(corpse, false)
        return false, "CORPSE_POSITION_API_UNAVAILABLE"
    end
    destination:addCorpse(corpse, false)

    Internal.forEachCorpse(destination, function(candidate)
        if candidate == corpse then attached = true end
    end)
    if attached then
        announceCorpse(corpse)
        return true
    end

    -- Roll back a failed square insertion so a transient/unloaded destination
    -- cannot strand the corpse outside the world.
    destination:removeCorpse(corpse, false)
    setCorpsePosition(corpse, oldX, oldY, oldZ, source)
    source:addCorpse(corpse, false)
    announceCorpse(corpse)
    return false, "CORPSE_FOLLOW_NOT_ATTACHED"
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

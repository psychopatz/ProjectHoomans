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
    -- IsoGridSquare:addCorpse() does not synchronize IsoObject.square or
    -- IsoMovingObject.current. Keep both fields authoritative before insertion;
    -- otherwise the next transfer removes from the stale square and leaves the
    -- same body in multiple staticMovingObjects lists.
    if square and corpse.setSquare then corpse:setSquare(square) end
    if square and corpse.setCurrent then corpse:setCurrent(square) end
    invalidateCorpseRender(corpse)
    return true
end

local function removeCorpseFromSquareList(square, corpse)
    local list
    local i
    if not square or not corpse or not square.getStaticMovingObjects then
        return
    end
    list = square:getStaticMovingObjects()
    if not list or not list.remove then return end
    for i = list:size() - 1, 0, -1 do
        if list:get(i) == corpse then
            pcall(list.remove, list, i)
        end
    end
end

local function corpseSquares(corpse)
    local visible = corpse and corpse.getSquare and corpse:getSquare() or nil
    local current = corpse and corpse.getCurrentSquare
        and corpse:getCurrentSquare() or nil
    local raw = visible
    if current and corpse.setCurrent then
        -- getSquare() prefers current; briefly clear it to recover the raw
        -- IsoObject.square left behind by the engine remove path.
        corpse:setCurrent(nil)
        raw = corpse.getSquare and corpse:getSquare() or raw
        corpse:setCurrent(current)
    end
    return visible, current, raw
end

local function detachCorpseMembership(corpse, visible, current, raw)
    if current then removeCorpseFromSquareList(current, corpse) end
    if visible and visible ~= current then
        removeCorpseFromSquareList(visible, corpse)
    end
    if raw and raw ~= visible and raw ~= current then
        removeCorpseFromSquareList(raw, corpse)
    end
end

local function announceCorpse(corpse)
    -- IsoGridSquare:addCorpse() sends an add packet for a client, but the
    -- dedicated server path requires GameServer.sendCorpse(). Announce only
    -- after membership has been verified so a failed handoff cannot create a
    -- client-side duplicate.
    if not corpse then
        return false
    end
    if isServer and isServer() == true then
        if sendCorpse then
            return pcall(sendCorpse, corpse)
        elseif GameServer and GameServer.sendCorpse then
            return pcall(GameServer.sendCorpse, corpse)
        end
    end
    -- Singleplayer already owns the local corpse; there is no packet to send.
    return true
end

Internal.announceCorpse = announceCorpse

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
    local current
    local raw
    if not corpse then
        return false
    end
    square, current, raw = corpseSquares(corpse)
    if square and square.transmitRemoveItemFromSquare then
        pcall(square.transmitRemoveItemFromSquare, square, corpse)
    end
    if current and current ~= square
        and current.transmitRemoveItemFromSquare
    then
        pcall(current.transmitRemoveItemFromSquare, current, corpse)
    end
    detachCorpseMembership(corpse, square, current, raw)
    if corpse.removeFromWorld then
        pcall(corpse.removeFromWorld, corpse)
    end
    if corpse.removeFromSquare then
        pcall(corpse.removeFromSquare, corpse)
    end
    if corpse.setSquare then
        pcall(corpse.setSquare, corpse, nil)
    end
    if corpse.setCurrent then
        pcall(corpse.setCurrent, corpse, nil)
    end
    return true
end

function Internal.moveCorpse(corpse, destination, x, y, z)
    local source = corpse and corpse.getSquare and corpse:getSquare() or nil
    local current = corpse and corpse.getCurrentSquare
        and corpse:getCurrentSquare() or nil
    local raw
    local visible
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

    visible, current, raw = corpseSquares(corpse)
    source = visible or source
    detachCorpseMembership(corpse, source, current, raw)

    -- Move the existing engine object. This preserves the corpse's clothing,
    -- inventory, and mod data, while the square APIs keep the server/client
    -- world representation authoritative in both singleplayer and MP.
    source:removeCorpse(corpse, false)
    raw = corpse.getSquare and corpse:getSquare() or raw
    if raw and raw ~= source then
        removeCorpseFromSquareList(raw, corpse)
    end
    corpse:setX(newX + 0.5)
    corpse:setY(newY + 0.5)
    corpse:setZ(newZ)
    if corpse.setSquare then corpse:setSquare(destination) end
    if corpse.setCurrent then corpse:setCurrent(destination) end
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
    removeCorpseFromSquareList(destination, corpse)
    corpse:setX(oldX)
    corpse:setY(oldY)
    corpse:setZ(oldZ)
    if corpse.setSquare then corpse:setSquare(source) end
    if corpse.setCurrent then corpse:setCurrent(source) end
    source:addCorpse(corpse, false)
    announceCorpse(corpse)
    return false, "CORPSE_TRANSFER_NOT_ATTACHED"
end

function Internal.followCorpse(corpse, x, y, z)
    local source = corpse and corpse.getSquare and corpse:getSquare() or nil
    local current = corpse and corpse.getCurrentSquare
        and corpse:getCurrentSquare() or nil
    local raw
    local visible
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

    visible, current, raw = corpseSquares(corpse)
    source = visible or source

    -- Position updates inside one tile do not need a remove/add cycle. The
    -- corpse remains a real IsoDeadBody, so its vanilla renderer follows the
    -- coordinates while the square still owns the object.
    if source == destination then
        detachCorpseMembership(corpse, source, current, raw)
        local positioned = setCorpsePosition(corpse, x, y, z, source)
        if positioned then
            -- This is a local membership repair, not a network handoff. The
            -- remote flag prevents a listen-server client from receiving an
            -- unmatched AddCorpse packet for an object that never left its
            -- tile.
            source:addCorpse(corpse, true)
        end
        return positioned
    end

    detachCorpseMembership(corpse, source, current, raw)
    source:removeCorpse(corpse, false)
    raw = corpse.getSquare and corpse:getSquare() or raw
    if raw and raw ~= source then
        removeCorpseFromSquareList(raw, corpse)
    end
    local positioned = setCorpsePosition(corpse, x, y, z, destination)
    if not positioned then
        if corpse.setSquare then corpse:setSquare(source) end
        if corpse.setCurrent then corpse:setCurrent(source) end
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
    removeCorpseFromSquareList(destination, corpse)
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

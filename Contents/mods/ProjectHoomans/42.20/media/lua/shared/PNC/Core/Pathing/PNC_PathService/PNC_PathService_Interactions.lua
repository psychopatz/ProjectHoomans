--[[
    PNC Path Service Interactions
    Door and window handling plus special-action suppression helpers.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal
local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles

local function normalize2D(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then
        return nil, nil
    end
    return dx / len, dy / len
end

local function improvesGoalDistance(fromX, fromY, toX, toY, goalX, goalY)
    return Internal.Core.Distance(toX, toY, goalX, goalY) + 0.05 < Internal.Core.Distance(fromX, fromY, goalX, goalY)
end

local function buildObstacleSquareKey(square)
    return square and ("sq:" .. Internal.describeSquare(square)) or nil
end

local function sameSquare(left, right)
    return left ~= nil and right ~= nil
        and left:getX() == right:getX()
        and left:getY() == right:getY()
        and left:getZ() == right:getZ()
end

local function windowDestination(object, actorSquare)
    local objectSquare = object and object.getSquare
        and object:getSquare() or nil
    local oppositeSquare = object and object.getOppositeSquare
        and object:getOppositeSquare() or nil
    if sameSquare(actorSquare, objectSquare) then
        return oppositeSquare
    end
    if sameSquare(actorSquare, oppositeSquare) then
        return objectSquare
    end
    return nil
end

local function logTraversalReject(record, zombie, lane, event, reason, extra)
    Internal.logMoveDebug(record, zombie, lane, event or "traversal_rejected", reason or "rejected", extra or "")
end

local function methodReturnsTrue(object, names)
    local i
    local method
    local result
    if not object then return false end
    for i = 1, #names do
        method = object[names[i]]
        if type(method) == "function" then
            result = method(object)
            if result == true then return true end
        end
    end
    return false
end

local function findFenceAhead(cell, zombie, goalX, goalY)
    if TraversalQuery and TraversalQuery.FindFenceAhead then
        return TraversalQuery.FindFenceAhead(zombie, goalX, goalY, cell)
    end
    return nil
end

local function isObstacleAhead(zombie, square, goalX, goalY, fallbackX, fallbackY)
    local goalDirX
    local goalDirY
    local objectX
    local objectY
    local obstacleDirX
    local obstacleDirY
    if not zombie then
        return false
    end
    goalDirX, goalDirY = normalize2D((tonumber(goalX) or zombie:getX()) - zombie:getX(), (tonumber(goalY) or zombie:getY()) - zombie:getY())
    if not goalDirX then
        return true
    end
    objectX = square and (square:getX() + 0.5) or fallbackX
    objectY = square and (square:getY() + 0.5) or fallbackY
    obstacleDirX, obstacleDirY = normalize2D((tonumber(objectX) or zombie:getX()) - zombie:getX(), (tonumber(objectY) or zombie:getY()) - zombie:getY())
    if not obstacleDirX and fallbackX and fallbackY then
        obstacleDirX, obstacleDirY = normalize2D(fallbackX - zombie:getX(), fallbackY - zombie:getY())
    end
    if not obstacleDirX then
        return true
    end
    return ((goalDirX * obstacleDirX) + (goalDirY * obstacleDirY)) >= 0.25
end

function Internal.rememberSpecialAction(lane, key, now)
    if not lane then
        return
    end
    lane.lastSpecialActionKey = key
    lane.lastSpecialActionAt = now
end

function Internal.shouldSuppressSpecialAction(lane, key, now)
    if not lane or not key then
        return false
    end
    return lane.lastSpecialActionKey == key and (now - (tonumber(lane.lastSpecialActionAt) or 0)) < Internal.SPECIAL_ACTION_COOLDOWN_MS
end

function Internal.isDoorCollision(zombie)
    local method
    if not zombie then return false end
    method = zombie.isCollidedWithDoor
    if type(method) == "function" then
        return method(zombie) == true
    end
    return methodReturnsTrue(zombie, { "isCollidedThisFrame", "isCollided" })
end

function Internal.openDoorForNPC(zombie, object)
    local square
    local properties
    local doorSound
    local opened
    local doubleDoor
    local garageDoor
    if not object then
        return false
    end
    if methodReturnsTrue(object, { "IsOpen", "isOpen" }) then
        return true
    end
    doubleDoor = IsoDoor
        and IsoDoor.getDoubleDoorIndex
        and IsoDoor.getDoubleDoorIndex(object) > -1
        or false
    garageDoor = IsoDoor
        and IsoDoor.getGarageDoorIndex
        and IsoDoor.getGarageDoorIndex(object) > -1
        or false
    -- Bandits deliberately lets non-hostile actors operate garage doors from
    -- either side without applying the ordinary lock/obstruction branch.
    -- Garages otherwise trap followers spawned inside.
    if not garageDoor
        and (
            methodReturnsTrue(object, { "isLocked", "IsLocked" })
            or methodReturnsTrue(object, { "isLockedByKey" })
            or methodReturnsTrue(
                object,
                { "isBarricaded", "IsBarricaded" }
            )
            or methodReturnsTrue(object, { "isObstructed" })
        )
    then
        return false
    end
    square = object.getSquare and object:getSquare() or nil
    if not square then
        return false
    end

    if doubleDoor then
        IsoDoor.toggleDoubleDoor(object, true)
        opened = true
    elseif garageDoor then
        IsoDoor.toggleGarageDoor(object, true)
        opened = true
    else
        if object.DirtySlice then object:DirtySlice() end
        if square.InvalidateSpecialObjectPaths then square:InvalidateSpecialObjectPaths() end
        if object.ToggleDoorSilent then
            object:ToggleDoorSilent()
        elseif object.toggleDoorSilent then
            object:toggleDoorSilent()
        end
    end

    opened = opened
        or methodReturnsTrue(object, { "IsOpen", "isOpen" })
    if not opened and object.setOpen then
        object:setOpen(true)
        opened = methodReturnsTrue(object, { "IsOpen", "isOpen" })
    elseif not opened and object.SetOpen then
        object:SetOpen(true)
        opened = methodReturnsTrue(object, { "IsOpen", "isOpen" })
    end
    if not opened then
        return false
    end
    if square.InvalidateSpecialObjectPaths then square:InvalidateSpecialObjectPaths() end
    if square.RecalcProperties then square:RecalcProperties() end
    if object.syncIsoObject then
        object:syncIsoObject(false, 1, nil, nil)
    end
    if LuaEventManager and LuaEventManager.triggerEvent then
        LuaEventManager.triggerEvent("OnContainerUpdate")
    end
    if FBORenderChunk and object.invalidateRenderChunkLevel then
        object:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)
    end

    properties = object.getProperties and object:getProperties() or nil
    doorSound = properties and properties:has("DoorSound") and properties:get("DoorSound") or "WoodDoor"
    if zombie.playSound then
        zombie:playSound(doorSound .. "Open")
    end
    return opened
end

function Internal.openWindowForNPC(zombie, object)
    local square
    if not object or methodReturnsTrue(object, { "IsOpen", "isOpen" }) then
        return object ~= nil
    end
    if methodReturnsTrue(object, { "isSmashed", "IsSmashed" })
        or methodReturnsTrue(object, { "isPermaLocked" })
    then
        return false
    end
    if object.ToggleWindow then
        object:ToggleWindow(zombie)
    elseif object.toggleWindow then
        object:toggleWindow(zombie)
    else
        return false
    end
    if not methodReturnsTrue(object, { "IsOpen", "isOpen" }) then
        return false
    end
    square = object.getSquare and object:getSquare() or nil
    if object.syncIsoObject then
        object:syncIsoObject(false, 1, nil, nil)
    end
    if square and square.InvalidateSpecialObjectPaths then
        square:InvalidateSpecialObjectPaths()
    end
    if square and square.RecalcProperties then
        square:RecalcProperties()
    end
    if zombie and zombie.playSound then
        zombie:playSound("OpenWindow")
    end
    return true
end

function Internal.smashWindowForNPC(zombie, object)
    local square
    if not object then return false end
    if methodReturnsTrue(object, { "isSmashed", "IsSmashed" }) then
        return true
    end
    if not object.smashWindow then
        return false
    end
    object:smashWindow()
    if not methodReturnsTrue(object, { "isSmashed", "IsSmashed" }) then
        return false
    end
    square = object.getSquare and object:getSquare() or nil
    if square and square.InvalidateSpecialObjectPaths then
        square:InvalidateSpecialObjectPaths()
    end
    if square and square.RecalcProperties then
        square:RecalcProperties()
    end
    return true
end

function Internal.tryDoorOrWindowInteraction(zombie, record, lane, goalX, goalY, goalZ)
    local cell
    local now
    local zx
    local zy
    local zz
    local fd
    local fdx
    local fdy
    local candidates
    local i
    local square
    local objects
    local j
    local object
    local objectSquare
    local facingSatisfied
    local candidatesByGoal
    local actionKey
    local fromPoint
    local destSquare
    local fromX
    local fromY
    local fromZ
    local destX
    local destY
    local destZ
    local objectKey
    local candidateCenterX
    local candidateCenterY
    local fence
    local landingSquare
    local landingX
    local landingY
    local landingZ
    local travelDuration
    local fenceKey
    local fenceSquare
    local fenceFromSquare
    local blockedSquare
    local blockedFromSquare
    local blockedFence
    local blockedFenceTall
    local blockedPassage
    local passageAhead
    local collided
    local traversalProfile
    local windowOpened
    local actorSquare

    if not zombie or not getCell then
        return false, nil
    end

    now = Internal.Core.Now()
    cell = getCell()
    zx = math.floor(zombie:getX())
    zy = math.floor(zombie:getY())
    zz = zombie:getZ()
    fromX = zombie:getX()
    fromY = zombie:getY()
    fromZ = zz
    actorSquare = zombie.getSquare and zombie:getSquare()
        or cell:getGridSquare(zx, zy, zz)
    fromPoint = Internal.describePoint(string.format("%.2f", fromX), string.format("%.2f", fromY), zz)
    collided = Internal.isDoorCollision(zombie)
    fd = zombie:getForwardDirection()
    fdx = Internal.roundHalf(fd:getX())
    fdy = Internal.roundHalf(fd:getY())
    blockedSquare = lane and lane.blockedStepToX ~= nil
        and cell:getGridSquare(math.floor(lane.blockedStepToX), math.floor(lane.blockedStepToY), lane.blockedStepToZ or zz)
        or nil
    blockedFromSquare = lane and lane.blockedStepFromX ~= nil
        and cell:getGridSquare(math.floor(lane.blockedStepFromX), math.floor(lane.blockedStepFromY), lane.blockedStepFromZ or zz)
        or nil
    blockedPassage = blockedFromSquare and blockedSquare and TraversalQuery and TraversalQuery.GetPassageBetween
        and TraversalQuery.GetPassageBetween(blockedFromSquare, blockedSquare)
        or nil
    if not blockedPassage and TraversalQuery and TraversalQuery.FindPassageToward then
        passageAhead = TraversalQuery.FindPassageToward(zombie, goalX, goalY, goalZ, cell)
        if passageAhead then
            blockedPassage = passageAhead.object
            blockedFromSquare = passageAhead.fromSquare
            blockedSquare = passageAhead.toSquare
        end
    end

    -- A blocked fake-locomotion step identifies the exact edge object. Open it
    -- directly: a door can belong to the origin square, which makes its square
    -- center look non-progressive even though the passage itself is ahead.
    if blockedPassage and TraversalQuery and TraversalQuery.IsDoor
        and TraversalQuery.IsDoor(blockedPassage)
    then
        objectSquare = blockedPassage.getSquare and blockedPassage:getSquare() or blockedSquare
        actionKey = "door:" .. Internal.describeSquare(objectSquare)
        if not Internal.shouldSuppressSpecialAction(lane, actionKey, now)
            and Internal.openDoorForNPC(zombie, blockedPassage)
        then
            Internal.rememberSpecialAction(lane, actionKey, now)
            if Internal.MotionHints and Internal.MotionHints.RememberHold then
                Internal.MotionHints.RememberHold(lane, zombie:getX(), zombie:getY(), zombie:getZ(), now, 180, {
                    kind = "door_open",
                    profile = lane.motionProfile,
                })
            end
            Internal.logMoveDebug(record, zombie, lane, "door_open", "blocked_passage",
                "from=" .. fromPoint .. " object=" .. Internal.describeSquare(objectSquare)
                    .. " goal=" .. Internal.describePoint(goalX, goalY, goalZ))
            return true, "door_open"
        end
    end

    -- Bandits inspects only the collision-facing square. Scanning every
    -- neighboring tile made an invalid Behavior2 route adopt unrelated
    -- windows along the same wall, producing smash/climb/replan loops.
    candidates = {
        { x = zx, y = zy, z = zz },
        blockedSquare and { x = blockedSquare:getX(), y = blockedSquare:getY(), z = blockedSquare:getZ() } or { x = zx, y = zy, z = zz, skip = true },
        { x = zx + fdx, y = zy + fdy, z = zz },
    }

    candidatesByGoal = {}
    for i = 1, #candidates do
        if not candidatesByGoal[candidates[i].x .. ":" .. candidates[i].y .. ":" .. candidates[i].z] then
            candidatesByGoal[candidates[i].x .. ":" .. candidates[i].y .. ":" .. candidates[i].z] = true
        else
            candidates[i].skip = true
        end
    end

    for i = 1, #candidates do
        if not candidates[i].skip then
            square = cell:getGridSquare(candidates[i].x, candidates[i].y, candidates[i].z)
        else
            square = nil
        end
        if square then
            objects = square:getObjects()
            for j = 0, objects:size() - 1 do
                object = objects:get(j)
                if object then
                    candidateCenterX = candidates[i].x + 0.5
                    candidateCenterY = candidates[i].y + 0.5
                    facingSatisfied = zombie.isFacingObject and zombie:isFacingObject(object, 0.5)
                    if (instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object.isDoor and object:isDoor() == true)) then
                        if (not facingSatisfied)
                            and object == blockedPassage
                            and zombie.faceThisObject
                        then
                            zombie:faceThisObject(object)
                            facingSatisfied = true
                        end
                    end
                    if (instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object.isDoor and object:isDoor() == true)) and facingSatisfied then
                        objectSquare = object:getSquare()
                        objectKey = buildObstacleSquareKey(objectSquare)
                        if object ~= blockedPassage
                            and not (collided and i <= 4)
                            and not isObstacleAhead(zombie, objectSquare, goalX, goalY, candidateCenterX, candidateCenterY)
                        then
                            logTraversalReject(record, zombie, lane, "traversal_rejected", "door_not_ahead", "object=" .. tostring(objectKey or "nil"))
                            objectSquare = nil
                        end
                        if objectSquare and object ~= blockedPassage
                            and not (collided and i <= 4)
                            and not improvesGoalDistance(fromX, fromY, objectSquare:getX() + 0.5, objectSquare:getY() + 0.5, goalX, goalY)
                        then
                            logTraversalReject(record, zombie, lane, "traversal_rejected", "door_not_progressive", "object=" .. tostring(objectKey or "nil"))
                            objectSquare = nil
                        end
                        if objectSquare then
                            actionKey = "door:" .. Internal.describeSquare(objectSquare)
                            if Internal.shouldSuppressSpecialAction(lane, actionKey, now) then
                                logTraversalReject(record, zombie, lane, "traversal_rejected", "door_special_cooldown", "object=" .. tostring(objectKey or "nil"))
                                return false, nil
                            end
                            if Internal.openDoorForNPC(zombie, object) then
                                Internal.rememberSpecialAction(lane, actionKey, now)
                                if Internal.MotionHints and Internal.MotionHints.RememberHold then
                                    Internal.MotionHints.RememberHold(lane, zombie:getX(), zombie:getY(), zombie:getZ(), now, 180, {
                                        kind = "door_open",
                                        profile = lane.motionProfile,
                                    })
                                end
                                Internal.logMoveDebug(record, zombie, lane, "door_open", "door_open", "from=" .. fromPoint .. " object=" .. Internal.describeSquare(objectSquare) .. " goal=" .. Internal.describePoint(goalX, goalY, goalZ))
                                return true, "door_open"
                            end
                            logTraversalReject(record, zombie, lane, "traversal_rejected", "door_open_failed_or_locked", "object=" .. tostring(objectKey or "nil"))
                        end
                    end
                    if instanceof(object, "IsoWindow") then
                        if (not facingSatisfied)
                            and object == blockedPassage
                            and zombie.faceThisObject
                        then
                            zombie:faceThisObject(object)
                            facingSatisfied = true
                        end
                    end
                    if instanceof(object, "IsoWindow") and facingSatisfied then
                        objectSquare = object:getSquare()
                        objectKey = buildObstacleSquareKey(objectSquare)
                        if object ~= blockedPassage and not isObstacleAhead(zombie, objectSquare, goalX, goalY, candidateCenterX, candidateCenterY) then
                            logTraversalReject(record, zombie, lane, "traversal_rejected", "window_not_ahead", "object=" .. tostring(objectKey or "nil"))
                        elseif objectSquare then
                            if (not object:IsOpen()) and (not object:isSmashed()) then
                                actionKey = "window_open:" .. Internal.describeSquare(objectSquare)
                                if Internal.shouldSuppressSpecialAction(lane, actionKey, now) then
                                    logTraversalReject(record, zombie, lane, "traversal_rejected", "window_special_cooldown", "object=" .. tostring(objectKey or "nil"))
                                    return false, nil
                                end
                                windowOpened = Internal.openWindowForNPC(
                                    zombie,
                                    object
                                )
                                if windowOpened then
                                    Internal.rememberSpecialAction(lane, actionKey, now)
                                    if Internal.MotionHints and Internal.MotionHints.RememberHold then
                                        Internal.MotionHints.RememberHold(lane, zombie:getX(), zombie:getY(), zombie:getZ(), now, 250, {
                                            kind = "window_open",
                                            profile = lane.motionProfile,
                                        })
                                    end
                                    Internal.logMoveDebug(record, zombie, lane, "window_open", "window_open", "from=" .. fromPoint .. " object=" .. Internal.describeSquare(objectSquare) .. " goal=" .. Internal.describePoint(goalX, goalY, goalZ))
                                else
                                    actionKey = "window_smash:" .. Internal.describeSquare(objectSquare)
                                    if not Internal.beginTraversalAction
                                        or not Internal.beginTraversalAction(zombie, record, lane, {
                                            kind = "window_smash",
                                            anim = "PNC_WindowSmash",
                                            obstacle = object,
                                            fromX = fromX,
                                            fromY = fromY,
                                            fromZ = fromZ,
                                            toX = fromX,
                                            toY = fromY,
                                            toZ = fromZ,
                                            travelDurationMs = 650,
                                            finishHoldMs = 260,
                                        })
                                    then
                                        logTraversalReject(record, zombie, lane, "traversal_rejected", "window_smash_runtime_unavailable", "object=" .. tostring(objectKey or "nil"))
                                        return false, nil
                                    end
                                    Internal.rememberSpecialAction(lane, actionKey, now)
                                    Internal.logMoveDebug(record, zombie, lane, "window_smash", "window_open_failed", "from=" .. fromPoint .. " object=" .. Internal.describeSquare(objectSquare))
                                    return true, "window_smash"
                                end
                            end
                            if object:canClimbThrough(zombie) then
                                actionKey = "window_climb:" .. Internal.describeSquare(objectSquare)
                                if Internal.isRepeatedTraversalAttempt
                                    and Internal.isRepeatedTraversalAttempt(lane, actionKey, fromX, fromY, fromZ, lane and lane.goalRevision or 0, now)
                                then
                                    logTraversalReject(record, zombie, lane, "traversal_rejected", "window_repeat_same_side", "object=" .. tostring(objectKey or "nil"))
                                    return false, nil
                                end
                                if Internal.shouldSuppressSpecialAction(lane, actionKey, now) then
                                    logTraversalReject(record, zombie, lane, "traversal_rejected", "window_climb_special_cooldown", "object=" .. tostring(objectKey or "nil"))
                                    return false, nil
                                end
                                if blockedFromSquare and blockedSquare
                                    and TraversalQuery
                                    and TraversalQuery.GetPassageBetween
                                    and TraversalQuery.GetPassageBetween(blockedFromSquare, blockedSquare) == object
                                then
                                    destSquare = blockedSquare
                                elseif object.getOppositeSquare then
                                    destSquare = windowDestination(
                                        object,
                                        actorSquare
                                    )
                                else
                                    destSquare = nil
                                end
                                if not destSquare or not Internal.isSquareWalkable(destSquare:getX() + 0.5, destSquare:getY() + 0.5, destSquare:getZ()) then
                                    logTraversalReject(record, zombie, lane, "traversal_rejected", "window_dest_blocked", "object=" .. tostring(objectKey or "nil"))
                                    return false, nil
                                end
                                destX = destSquare:getX() + 0.5
                                destY = destSquare:getY() + 0.5
                                destZ = destSquare:getZ()
                                -- A blocked edge reported by the pathfinder is
                                -- stronger evidence than the goal-distance
                                -- heuristic. Building traversal can require a
                                -- brief sideways or backward window crossing.
                                if object ~= blockedPassage
                                    and not improvesGoalDistance(fromX, fromY, destX, destY, goalX, goalY)
                                then
                                    if Internal.noteTraversalAttempt then
                                        Internal.noteTraversalAttempt(lane, "window_climb", actionKey, fromX, fromY, fromZ, destX, destY, destZ, now, lane and lane.goalRevision or 0)
                                    end
                                    logTraversalReject(record, zombie, lane, "traversal_rejected", "window_dest_not_progressive", "object=" .. tostring(objectKey or "nil") .. " to=" .. Internal.describeSquare(destSquare))
                                    return false, nil
                                end
                                traversalProfile = TraversalProfiles
                                    and TraversalProfiles.Resolve
                                    and TraversalProfiles.Resolve(
                                        "window_climb",
                                        {
                                            record = record,
                                            body = zombie,
                                            lane = lane,
                                            obstacle = object,
                                        },
                                        "default"
                                    ) or {}
                                if not Internal.beginTraversalAction or not Internal.beginTraversalAction(zombie, record, lane, {
                                    kind = "window_climb",
                                    anim = traversalProfile.anim
                                        or "PNC_ClimbWindow",
                                    fromX = fromX,
                                    fromY = fromY,
                                    fromZ = fromZ,
                                    toX = destX,
                                    toY = destY,
                                    toZ = destZ,
                                    travelDurationMs = tonumber(
                                        traversalProfile.travelDurationMs
                                    ) or 700,
                                    finishHoldMs = tonumber(
                                        traversalProfile.finishHoldMs
                                    ) or 320,
                                }) then
                                    logTraversalReject(record, zombie, lane, "traversal_rejected", "window_runtime_unavailable", "object=" .. tostring(objectKey or "nil"))
                                    return false, nil
                                end
                                Internal.rememberSpecialAction(lane, actionKey, now)
                                if Internal.noteTraversalAttempt then
                                    Internal.noteTraversalAttempt(lane, "window_climb", actionKey, fromX, fromY, fromZ, destX, destY, destZ, now, lane and lane.goalRevision or 0)
                                end
                                Internal.logMoveDebug(
                                    record,
                                    zombie,
                                    lane,
                                    "window_climb",
                                    "window_climb",
                                    "from=" .. fromPoint .. " object=" .. Internal.describeSquare(objectSquare) .. " to=" .. Internal.describeSquare(destSquare) .. " goal=" .. Internal.describePoint(goalX, goalY, goalZ)
                                )
                                return true, "window_climb"
                            end
                        end
                    end
                end
            end
        end
    end

    if blockedFromSquare and blockedSquare and TraversalQuery and TraversalQuery.GetFenceBetween then
        blockedFence, blockedFenceTall = TraversalQuery.GetFenceBetween(blockedFromSquare, blockedSquare)
    end
    if blockedFence then
        fence = {
            object = blockedFence,
            tall = blockedFenceTall == true,
            square = blockedFence.getSquare and blockedFence:getSquare() or blockedFromSquare,
            fromSquare = blockedFromSquare,
            landingSquare = blockedSquare,
        }
    else
        fence = findFenceAhead(cell, zombie, goalX, goalY)
    end
    if fence and fence.landingSquare then
        landingSquare = fence.landingSquare
        fenceFromSquare = fence.fromSquare or blockedFromSquare
        if not fenceFromSquare and TraversalQuery and TraversalQuery.GetSquare then
            fenceFromSquare = TraversalQuery.GetSquare(
                fromX,
                fromY,
                fromZ,
                cell
            )
        end
        if TraversalQuery
            and TraversalQuery.IsFenceApproachReady
            and not TraversalQuery.IsFenceApproachReady(
                fromX,
                fromY,
                fenceFromSquare,
                landingSquare,
                fence.dirX,
                fence.dirY
            )
        then
            logTraversalReject(
                record,
                zombie,
                lane,
                "traversal_rejected",
                "fence_not_ready",
                "from=" .. tostring(fenceFromSquare and Internal.describeSquare(fenceFromSquare) or "nil")
            )
            return false, nil
        end
        landingX = landingSquare:getX() + 0.5
        landingY = landingSquare:getY() + 0.5
        landingZ = landingSquare:getZ()
        fenceSquare = fence.square
        fenceKey = "fence:" .. Internal.describeSquare(fenceSquare)
        -- Trust an exact blocked edge at fence corners even when its landing
        -- tile does not immediately approach the final goal.
        if not blockedFence
            and not improvesGoalDistance(fromX, fromY, landingX, landingY, goalX, goalY)
        then
            logTraversalReject(record, zombie, lane, "traversal_rejected", "fence_not_progressive", "object=" .. tostring(fenceKey))
            return false, nil
        end
        if Internal.isRepeatedTraversalAttempt
            and Internal.isRepeatedTraversalAttempt(lane, fenceKey, fromX, fromY, fromZ, lane and lane.goalRevision or 0, now)
        then
            logTraversalReject(record, zombie, lane, "traversal_rejected", "fence_repeat_same_side", "object=" .. tostring(fenceKey))
            return false, nil
        end
        if Internal.shouldSuppressSpecialAction(lane, fenceKey, now) then
            logTraversalReject(record, zombie, lane, "traversal_rejected", "fence_special_cooldown", "object=" .. tostring(fenceKey))
            return false, nil
        end
        traversalProfile = TraversalProfiles
            and TraversalProfiles.Resolve
            and TraversalProfiles.Resolve(
                "fence_climb",
                {
                    record = record,
                    body = zombie,
                    lane = lane,
                    obstacle = fence.object,
                    tall = fence.tall == true,
                },
                fence.tall == true and "tall" or "low"
            ) or {}
        travelDuration = tonumber(traversalProfile.travelDurationMs)
            or (fence.tall == true and 900 or 600)
        if not Internal.beginTraversalAction or not Internal.beginTraversalAction(zombie, record, lane, {
            kind = "fence_climb",
            anim = traversalProfile.anim
                or (
                    fence.tall == true
                    and "PNC_ClimbFenceTall"
                    or "PNC_ClimbFence"
                ),
            fromX = fromX,
            fromY = fromY,
            fromZ = fromZ,
            fromSquare = fenceFromSquare,
            toSquare = landingSquare,
            toX = landingX,
            toY = landingY,
            toZ = landingZ,
            travelDurationMs = travelDuration,
            startAnim = fence.tall ~= true
                and traversalProfile.startAnim or nil,
            endAnim = fence.tall ~= true
                and traversalProfile.endAnim or nil,
            upDurationMs = fence.tall ~= true
                and traversalProfile.upDurationMs or nil,
            crossingDurationMs = fence.tall ~= true
                and traversalProfile.crossingDurationMs or nil,
            finishHoldMs = tonumber(traversalProfile.finishHoldMs)
                or (fence.tall == true and 420 or 320),
        }) then
            logTraversalReject(record, zombie, lane, "traversal_rejected", "fence_runtime_unavailable", "object=" .. tostring(fenceKey))
            return false, nil
        end
        Internal.rememberSpecialAction(lane, fenceKey, now)
        if Internal.noteTraversalAttempt then
            Internal.noteTraversalAttempt(lane, "fence_climb", fenceKey, fromX, fromY, fromZ, landingX, landingY, landingZ, now, lane and lane.goalRevision or 0)
        end
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "fence_climb",
            "fence_climb",
            "from=" .. fromPoint .. " object=" .. Internal.describeSquare(fenceSquare) .. " to=" .. Internal.describeSquare(landingSquare) .. " goal=" .. Internal.describePoint(goalX, goalY, goalZ)
        )
        return true, "fence_climb"
    end

    return false, nil
end

function Internal.hasClosedPassageToward(zombie, goalX, goalY, goalZ)
    local query = Internal.TraversalQuery or TraversalQuery
    local passage
    if not query or not query.FindPassageToward or not query.IsClosedPassage then
        return false
    end
    passage = query.FindPassageToward(zombie, goalX, goalY, goalZ)
    return passage ~= nil and passage.object ~= nil
        and query.IsClosedPassage(passage.object)
end

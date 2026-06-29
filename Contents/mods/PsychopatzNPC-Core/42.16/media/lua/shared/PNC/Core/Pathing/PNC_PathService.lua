--[[
    PNC Path Service
    Owns live embodied path requests, repath recovery, door and window
    interaction, and abstract travel stepping for far-away NPC simulation.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
local Core = PNC.Core
local Const = PNC.Const
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local FakeLocomotion = PNC.FakeLocomotion
local getActionStateName
local isAtGoal
local logMoveWarning
local logMoveDebug

local GOAL_REFRESH_DELAY_MS = 120
local PROGRESS_TIMEOUT_MS = 2200
local SPECIAL_ACTION_COOLDOWN_MS = 1500
local RUN_START_DISTANCE = 4.50
local RUN_STOP_DISTANCE = 2.90

local function roundHalf(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function getSquare(x, y, z)
    if not getCell then
        return nil
    end
    return getCell():getGridSquare(math.floor(x), math.floor(y), z)
end

local function isSquareWalkable(x, y, z)
    local square = getSquare(x, y, z)
    if not square then
        return false
    end
    return square:isFree(false) and (not square:isSolid()) and (not square:isSolidTrans())
end

local function syncRecordPosition(record, zombie)
    if not record or not zombie then
        return
    end
    record.x = zombie:getX()
    record.y = zombie:getY()
    record.z = zombie:getZ()
end

local function getDirectStepSize(mode)
    if mode == "run" then
        return 0.28
    end
    if mode == "sneak" or mode == "crawl" then
        return 0.14
    end
    return 0.22
end

local function isMovementDebugEnabled(record)
    if record and record.runtime and record.runtime.debugMovement == true then
        return true
    end
    if PNC.Runtime and PNC.Runtime.debugMovement == true then
        return true
    end
    if Core and Core.IsRecordDebugEnabled then
        return Core.IsRecordDebugEnabled(record)
    end
    return PNC.Runtime and PNC.Runtime.debugEnabled == true
end

local function setWalkAnim(zombie, record, mode, force)
    local previousWalkType
    local walkType = "Walk"
    if mode == "run" then
        walkType = "Run"
    elseif mode == "sneak" then
        walkType = "SneakWalk"
    elseif mode == "crawl" then
        walkType = "Walk"
    end
    previousWalkType = zombie.getVariableString and zombie:getVariableString("PNCWalkType") or ""
    if force ~= true and previousWalkType == walkType then
        return
    end
    if previousWalkType == "" and zombie.setBumpType then
        zombie:setBumpType(mode == "run" and "PNC_IdleToRun" or "PNC_IdleToWalk")
    end
    if mode == "crawl" then
        Animation.Apply(zombie, record, "Crawl")
    else
        Animation.Apply(zombie, record, walkType)
    end
    if Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie)
    end
end

local function resetPathController(zombie)
    local behavior
    if not zombie then
        return
    end
    if getActionStateName and getActionStateName(zombie) == "walktoward" and zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    if zombie.getPathFindBehavior2 then
        behavior = zombie:getPathFindBehavior2()
        if behavior then
            behavior:update()
            behavior:cancel()
            behavior:reset()
        end
    end
    if zombie.setPath2 then
        zombie:setPath2(nil)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
end

local function hardResetMoveOwner(zombie)
    if not zombie then
        return
    end
    resetPathController(zombie)
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
end

getActionStateName = function(zombie)
    if LiveBodyControl and LiveBodyControl.GetActionStateName then
        return LiveBodyControl.GetActionStateName(zombie)
    end
    if not zombie or not zombie.getActionStateName then
        return ""
    end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

local function hasPath2(zombie)
    if not zombie or not zombie.getPath2 then
        return false
    end
    return zombie:getPath2() ~= nil
end

local function describeGoal(goal)
    if not goal then
        return "nil"
    end
    return tostring(goal.x) .. "," .. tostring(goal.y) .. "," .. tostring(goal.z)
end

local function describePoint(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function describeSquare(square)
    if not square then
        return "nil"
    end
    return describePoint(square:getX(), square:getY(), square:getZ())
end

local function describeRecord(record)
    if not record then
        return "npc[nil]"
    end
    return tostring(record.name or "Unknown NPC")
        .. "["
        .. tostring(record.id or "nil")
        .. "]"
        .. " faction="
        .. tostring(record.faction or "unknown")
        .. " job="
        .. tostring(record.activeJob or "nil")
        .. " behavior="
        .. tostring(record.activeBehavior or "nil")
        .. " order="
        .. tostring(record.orderSpec and record.orderSpec.kind or "none")
end

local function describeZombieTarget(zombie)
    local target
    local name
    if not zombie or not zombie.getTarget then
        return "nil"
    end
    target = zombie:getTarget()
    if not target then
        return "nil"
    end
    if target.getUsername then
        name = target:getUsername()
    elseif target.getDescriptor and target:getDescriptor() and target:getDescriptor().getForename then
        name = target:getDescriptor():getForename()
    end
    return tostring(name or tostring(target))
end

local function buildMoveLogMessage(record, zombie, lane, event, reason, extra)
    local goal = lane and lane.goal or nil
    local intentReason = lane and lane.intentReason or record and record.runtime and record.runtime.moveIntent and record.runtime.moveIntent.reason or nil
    local requestedBy = lane and lane.requestedByBehavior or record and record.activeBehavior or record and record.activeJob or "nil"
    local actionState = getActionStateName(zombie)
    return describeRecord(record)
        .. " move="
        .. tostring(event or "unknown")
        .. " phase="
        .. tostring(lane and lane.phase or "nil")
        .. " mode="
        .. tostring(lane and lane.mode or "nil")
        .. " reason="
        .. tostring(reason or "none")
        .. " intentReason="
        .. tostring(intentReason or "none")
        .. " requestedBy="
        .. tostring(requestedBy)
        .. " goal="
        .. describeGoal(goal)
        .. " revision="
        .. tostring(lane and lane.goalRevision or 0)
        .. " action="
        .. tostring(actionState ~= "" and actionState or "idle")
        .. " lastAction="
        .. tostring(lane and lane.lastActionState or (actionState ~= "" and actionState or "idle"))
        .. " path2="
        .. tostring(hasPath2(zombie))
        .. " owner="
        .. tostring(lane and lane.ownerMode or "none")
        .. " recoveries="
        .. tostring(lane and lane.recoveryCount or 0)
        .. " fallbacks="
        .. tostring(lane and lane.fallbackCount or 0)
        .. " target="
        .. describeZombieTarget(zombie)
        .. " pos="
        .. tostring(zombie and zombie.getX and string.format("%.2f", zombie:getX()) or "nil")
        .. ","
        .. tostring(zombie and zombie.getY and string.format("%.2f", zombie:getY()) or "nil")
        .. ","
        .. tostring(zombie and zombie.getZ and zombie:getZ() or "nil")
        .. (extra and extra ~= "" and (" " .. tostring(extra)) or "")
end

local function logMoveWarning(record, zombie, lane, event, reason, extra)
    local now = Core.Now()
    local key = tostring(event or "unknown")
        .. "|"
        .. tostring(reason or "none")
        .. "|"
        .. tostring(lane and lane.phase or "nil")
        .. "|"
        .. tostring(getActionStateName(zombie))
        .. "|"
        .. tostring(hasPath2(zombie))
    if lane and lane.lastWarnKey == key and (now - (tonumber(lane.lastWarnAt) or 0)) < 1500 then
        return
    end
    if lane then
        lane.lastWarnKey = key
        lane.lastWarnAt = now
    end
    Core.LogWarn(buildMoveLogMessage(record, zombie, lane, event, reason, extra))
end

local function logMoveDebug(record, zombie, lane, event, reason, extra)
    if not isMovementDebugEnabled(record) then
        return
    end
    Core.Log("DEBUG", buildMoveLogMessage(record, zombie, lane, event, reason, extra))
end

local function rememberSpecialAction(lane, key, now)
    if not lane then
        return
    end
    lane.lastSpecialActionKey = key
    lane.lastSpecialActionAt = now
end

local function shouldSuppressSpecialAction(lane, key, now)
    if not lane or not key then
        return false
    end
    return lane.lastSpecialActionKey == key and (now - (tonumber(lane.lastSpecialActionAt) or 0)) < SPECIAL_ACTION_COOLDOWN_MS
end


local function openDoorForNPC(zombie, object)
    local square
    local properties
    local doorSound
    if not object or object:IsOpen() then
        return false
    end

    if IsoDoor and IsoDoor.getDoubleDoorIndex and IsoDoor.getDoubleDoorIndex(object) > -1 then
        if object.isLocked and (object:isLocked() or object:isLockedByKey() or object:isObstructed()) then
            return false
        end
        IsoDoor.toggleDoubleDoor(object, true)
    elseif IsoDoor and IsoDoor.getGarageDoorIndex and IsoDoor.getGarageDoorIndex(object) > -1 then
        if object.isLocked and (object:isLocked() or object:isLockedByKey() or object:isObstructed()) then
            return false
        end
        IsoDoor.toggleGarageDoor(object, true)
    else
        if ((object.isLocked and object:isLocked()) or (object.isLockedByKey and object:isLockedByKey()) or (object.isObstructed and object:isObstructed())) then
            return false
        end
        square = object:getSquare()
        if not square then
            return false
        end
        object:DirtySlice()
        square:InvalidateSpecialObjectPaths()
        object:ToggleDoorSilent()
        square:RecalcProperties()
        object:syncIsoObject(false, 1, nil, nil)
        LuaEventManager.triggerEvent("OnContainerUpdate")
        if FBORenderChunk and object.invalidateRenderChunkLevel then
            object:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)
        end
    end

    properties = object:getProperties()
    doorSound = properties and properties:has("DoorSound") and properties:get("DoorSound") or "WoodDoor"
    if zombie.playSound then
        zombie:playSound(doorSound .. "Open")
    end
    return true
end

local function tryDoorOrWindowInteraction(zombie, record, lane, goalX, goalY, goalZ)
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
    local targetDx
    local targetDy
    local candidatesByGoal
    local actionKey
    local fromPoint
    local destSquare

    if not zombie or not getCell then
        return false, nil
    end

    now = Core.Now()
    cell = getCell()
    zx = math.floor(zombie:getX())
    zy = math.floor(zombie:getY())
    zz = zombie:getZ()
    fromPoint = describePoint(string.format("%.2f", zombie:getX()), string.format("%.2f", zombie:getY()), zz)
    fd = zombie:getForwardDirection()
    fdx = roundHalf(fd:getX())
    fdy = roundHalf(fd:getY())
    targetDx = roundHalf((goalX or zombie:getX()) - zombie:getX())
    targetDy = roundHalf((goalY or zombie:getY()) - zombie:getY())

    candidates = {
        { x = zx, y = zy, z = zz },
        { x = zx + fdx, y = zy + fdy, z = zz },
        { x = zx + targetDx, y = zy + targetDy, z = goalZ or zz },
        { x = zx + 1, y = zy, z = zz },
        { x = zx - 1, y = zy, z = zz },
        { x = zx, y = zy + 1, z = zz },
        { x = zx, y = zy - 1, z = zz },
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
                    facingSatisfied = zombie.isFacingObject and zombie:isFacingObject(object, 0.5)
                    if (instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object.isDoor and object:isDoor() == true)) then
                        if (not facingSatisfied) and zombie.faceThisObject then
                            zombie:faceThisObject(object)
                            facingSatisfied = true
                        end
                    end
                    if (instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object.isDoor and object:isDoor() == true)) and facingSatisfied then
                        objectSquare = object:getSquare()
                        actionKey = "door:" .. describeSquare(objectSquare)
                        if shouldSuppressSpecialAction(lane, actionKey, now) then
                            return false, nil
                        end
                        if openDoorForNPC(zombie, object) then
                            rememberSpecialAction(lane, actionKey, now)
                            logMoveWarning(record, zombie, lane, "door_open", "door_open", "from=" .. fromPoint .. " object=" .. describeSquare(objectSquare) .. " goal=" .. describePoint(goalX, goalY, goalZ))
                            return true, "door_open"
                        end
                    end
                    if instanceof(object, "IsoWindow") then
                        if (not facingSatisfied) and zombie.faceThisObject then
                            zombie:faceThisObject(object)
                            facingSatisfied = true
                        end
                    end
                    if instanceof(object, "IsoWindow") and facingSatisfied then
                        objectSquare = object:getSquare()
                        if (not object:IsOpen()) and (not object:isSmashed()) and (not object:isPermaLocked()) then
                            actionKey = "window_open:" .. describeSquare(objectSquare)
                            if shouldSuppressSpecialAction(lane, actionKey, now) then
                                return false, nil
                            end
                            object:ToggleWindow(zombie)
                            rememberSpecialAction(lane, actionKey, now)
                            logMoveWarning(record, zombie, lane, "window_open", "window_open", "from=" .. fromPoint .. " object=" .. describeSquare(objectSquare) .. " goal=" .. describePoint(goalX, goalY, goalZ))
                            return true, "window_open"
                        end
                        if object:canClimbThrough(zombie) then
                            actionKey = "window_climb:" .. describeSquare(objectSquare)
                            if shouldSuppressSpecialAction(lane, actionKey, now) then
                                return false, nil
                            end
                            if object.getOppositeSquare then
                                destSquare = object:getOppositeSquare()
                            else
                                destSquare = nil
                            end
                            if not destSquare or not isSquareWalkable(destSquare:getX() + 0.5, destSquare:getY() + 0.5, destSquare:getZ()) then
                                return false, nil
                            end
                            if Animation and Animation.PlayBump then
                                Animation.PlayBump(zombie, record, "ClimbWindow")
                            elseif zombie.setBumpType then
                                zombie:setBumpType("ClimbWindow")
                            end
                            zombie:setX(destSquare:getX() + 0.5)
                            zombie:setY(destSquare:getY() + 0.5)
                            zombie:setZ(destSquare:getZ())
                            syncRecordPosition(record, zombie)
                            rememberSpecialAction(lane, actionKey, now)
                            lane.specialMoveUntil = now + 450
                            lane.specialAnim = "ClimbWindow"
                            logMoveWarning(
                                record,
                                zombie,
                                lane,
                                "window_climb",
                                "window_climb",
                                "from=" .. fromPoint .. " object=" .. describeSquare(objectSquare) .. " to=" .. describeSquare(destSquare) .. " goal=" .. describePoint(goalX, goalY, goalZ)
                            )
                            return true, "window_climb"
                        end
                    end
                end
            end
        end
    end

    return false, nil
end

local function ensureMoveLane(record)
    local runtime
    local lane
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    lane = runtime.pathing or {}
    runtime.pathing = lane
    lane.id = lane.id or 0
    lane.phase = lane.phase or "idle"
    lane.mode = lane.mode or "walk"
    lane.stopDistance = tonumber(lane.stopDistance) or 0.7
    lane.goal = lane.goal or nil
    lane.pendingGoal = lane.pendingGoal or nil
    lane.startedAt = tonumber(lane.startedAt) or 0
    lane.lastIssueAt = tonumber(lane.lastIssueAt) or 0
    lane.lastProgressAt = tonumber(lane.lastProgressAt) or 0
    lane.cancelReason = lane.cancelReason or nil
    lane.blockReason = lane.blockReason or nil
    lane.intentReason = lane.intentReason or nil
    lane.requestedByJob = lane.requestedByJob or nil
    lane.requestedByBehavior = lane.requestedByBehavior or nil
    lane.requestedOrder = lane.requestedOrder or nil
    lane.lastWarnKey = lane.lastWarnKey or nil
    lane.lastWarnAt = tonumber(lane.lastWarnAt) or 0
    lane.goalRevision = tonumber(lane.goalRevision) or 0
    lane.recoveryCount = tonumber(lane.recoveryCount) or 0
    lane.fallbackCount = tonumber(lane.fallbackCount) or 0
    lane.lastRecoveryReason = lane.lastRecoveryReason or nil
    lane.lastActionState = lane.lastActionState or nil
    lane.lastDirectStepAt = tonumber(lane.lastDirectStepAt) or 0
    lane.lastStepAt = tonumber(lane.lastStepAt) or 0
    lane.lastStepDistance = tonumber(lane.lastStepDistance) or 0
    lane.lastStepLabel = lane.lastStepLabel or nil
    lane.lastRecoverAt = tonumber(lane.lastRecoverAt) or 0
    lane.noProgressCount = tonumber(lane.noProgressCount) or 0
    lane.lastSpecialActionKey = lane.lastSpecialActionKey or nil
    lane.lastSpecialActionAt = tonumber(lane.lastSpecialActionAt) or 0
    lane.specialMoveUntil = tonumber(lane.specialMoveUntil) or 0
    lane.specialAnim = lane.specialAnim or nil
    lane.resolvedMode = lane.resolvedMode or nil
    lane.animSpeed = tonumber(lane.animSpeed) or 1.0
    lane.lastSuppressAudioAt = tonumber(lane.lastSuppressAudioAt) or 0
    lane.ownerMode = lane.ownerMode or "idle"
    return lane
end

local function buildGoal(x, y, z, mode, stopDistance)
    return {
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        mode = tostring(mode or "walk"),
        stopDistance = tonumber(stopDistance) or 0.7,
    }
end

local function getGoalTolerance(mode, stopDistance)
    local tolerance = tostring(mode or "walk") == "run" and 1.75 or 1.0
    if mode == "sneak" or mode == "crawl" then
        tolerance = 0.6
    end
    if tonumber(stopDistance) and tonumber(stopDistance) > tolerance then
        tolerance = math.min(tonumber(stopDistance) * 1.25, tolerance + 0.75)
    end
    return tolerance
end

local function computeResolvedMode(record, lane, zombie, goal)
    local dist
    local previousMode
    if not lane or not goal then
        return "walk"
    end
    if lane.mode == "crawl" then
        return "crawl"
    end
    if lane.mode == "sneak" or (record and record.runtime and record.runtime.stealthActive == true) then
        return "sneak"
    end
    if lane.mode ~= "walk" and lane.mode ~= "run" then
        return tostring(lane.mode or "walk")
    end
    if not zombie then
        return tostring(lane.mode or "walk")
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), goal.x, goal.y)
    previousMode = tostring(lane.resolvedMode or lane.mode or "walk")
    if previousMode == "run" then
        if dist <= math.max(tonumber(lane.stopDistance) or 0.7, RUN_STOP_DISTANCE) then
            return "walk"
        end
        return "run"
    end
    if dist >= math.max((tonumber(lane.stopDistance) or 0.7) + 2.75, RUN_START_DISTANCE) then
        return "run"
    end
    return "walk"
end

local function computeAnimSpeedForMode(mode)
    if mode == "run" then
        return 1.22
    end
    if mode == "sneak" then
        return 0.86
    end
    if mode == "crawl" then
        return 0.70
    end
    return 1.10
end

local function refreshResolvedLocomotion(record, lane, zombie, goal)
    local resolvedMode = computeResolvedMode(record, lane, zombie, goal)
    if lane then
        lane.resolvedMode = resolvedMode
        lane.animSpeed = computeAnimSpeedForMode(resolvedMode)
    end
    return resolvedMode
end

local function getStopDistanceClass(stopDistance)
    local value = tonumber(stopDistance) or 0.7
    if value <= 0.35 then
        return "tight"
    end
    if value <= 0.9 then
        return "near"
    end
    return "wide"
end

local function goalsDiffer(currentGoal, nextGoal, currentMode)
    local tolerance
    if not currentGoal or not nextGoal then
        return true
    end
    tolerance = getGoalTolerance(currentMode or nextGoal.mode, nextGoal.stopDistance)
    return math.abs((currentGoal.x or 0) - (nextGoal.x or 0)) > tolerance
        or math.abs((currentGoal.y or 0) - (nextGoal.y or 0)) > tolerance
        or (currentGoal.z or 0) ~= (nextGoal.z or 0)
        or tostring(currentMode or "") ~= tostring(nextGoal.mode or "")
        or getStopDistanceClass(currentGoal.stopDistance) ~= getStopDistanceClass(nextGoal.stopDistance)
end

local function logMoveTransition(record, zombie, lane, verb, reason, extra)
    logMoveDebug(record, zombie, lane, verb, reason, extra)
end

local function setLanePhase(record, lane, phase, reason)
    if not lane or lane.phase == phase then
        return
    end
    lane.phase = phase
    logMoveTransition(record, nil, lane, phase, reason)
end

local function setLaneGoal(record, lane, goal)
    lane.id = (tonumber(lane.id) or 0) + 1
    lane.goalRevision = (tonumber(lane.goalRevision) or 0) + 1
    lane.goal = {
        x = goal.x,
        y = goal.y,
        z = goal.z,
        mode = goal.mode,
        stopDistance = goal.stopDistance,
    }
    lane.mode = goal.mode
    lane.stopDistance = goal.stopDistance
    lane.blockReason = nil
    lane.cancelReason = nil
    lane.recoveryCount = 0
    lane.fallbackCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.resolvedMode = nil
    lane.animSpeed = 1.0
    lane.ownerMode = "requested"
end

local function captureIntentContext(record, lane, intent)
    if not lane then
        return
    end
    lane.intentReason = intent and intent.reason or nil
    lane.requestedByJob = intent and intent.requestedByJob or tostring(record and record.activeJob or "none")
    lane.requestedByBehavior = intent and intent.requestedByBehavior or tostring(record and record.activeBehavior or record and record.activeJob or "none")
    lane.requestedOrder = intent and intent.requestedOrder or tostring(record and record.orderSpec and record.orderSpec.kind or "none")
end

local function applyHoldAnimation(zombie, record, lane)
    local healthState = record and record.health and tostring(record.health.state or "normal") or "normal"
    local attackAction = record and record.runtime and record.runtime.attackAction or nil
    if not zombie or not record then
        return
    end
    if attackAction and Core.Now() < (tonumber(attackAction.finishAt) or 0) then
        return
    end
    if healthState == "incapacitated" and Animation and Animation.ApplyDowned then
        Animation.ApplyDowned(zombie, record, false)
        return
    end
    if lane and lane.mode == "crawl" then
        Animation.Apply(zombie, record, "Crawl")
        return
    end
    if lane and (lane.mode == "sneak" or (record and record.runtime and record.runtime.stealthActive == true)) then
        Animation.Apply(zombie, record, "SneakWalk")
        return
    end
    Animation.Apply(zombie, record, "Idle")
end

isAtGoal = function(zombie, goal, stopDistance)
    local dist
    if not zombie or not goal then
        return false
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), goal.x, goal.y)
    return dist <= (tonumber(stopDistance) or 0.7) and zombie:getZ() == goal.z
end

local function consumeMoveIntent(record, lane, zombie)
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    local goal
    if not runtime then
        return "hold"
    end
    if not intent or intent.kind == "hold" then
        captureIntentContext(record, lane, intent)
        lane.pendingGoal = nil
        if lane.phase == "active" or lane.phase == "requested" then
            lane.cancelReason = intent and intent.reason or "hold"
            setLanePhase(record, lane, "cancel_pending", lane.cancelReason)
        elseif lane.phase ~= "idle" then
            setLanePhase(record, lane, "idle", intent and intent.reason or "hold")
        end
        return "hold"
    end

    goal = buildGoal(intent.x, intent.y, intent.z, intent.mode, intent.stopDistance)
    captureIntentContext(record, lane, intent)
    if zombie and isAtGoal(zombie, goal, goal.stopDistance) then
        lane.pendingGoal = nil
        lane.goal = goal
        lane.mode = goal.mode
        lane.stopDistance = goal.stopDistance
        if lane.phase == "active" or lane.phase == "requested" then
            lane.cancelReason = "arrived"
            setLanePhase(record, lane, "cancel_pending", "arrived")
        else
            setLanePhase(record, lane, "arrived", "intent_arrived")
        end
        return "arrived"
    end

    if lane.goal == nil or lane.phase == "idle" or lane.phase == "arrived" or lane.phase == "blocked" then
        setLaneGoal(record, lane, goal)
        lane.pendingGoal = nil
        setLanePhase(record, lane, "requested", "new_goal")
        return "requested"
    end

    if goalsDiffer(lane.goal, goal, lane.mode) then
        lane.pendingGoal = goal
        if lane.phase == "requested" then
            setLaneGoal(record, lane, goal)
            lane.pendingGoal = nil
            setLanePhase(record, lane, "requested", "goal_refresh")
            return "requested"
        end
        return "refresh_pending"
    end

    return "unchanged"
end

local function finalizeCancel(zombie, record, lane)
    if zombie then
        hardResetMoveOwner(zombie)
    end
    lane.pendingGoal = nil
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.startedAt = 0
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.resolvedMode = nil
    lane.animSpeed = 1.0
    lane.ownerMode = "idle"
    setLanePhase(record, lane, "idle", lane.cancelReason or "cancelled")
    applyHoldAnimation(zombie, record, lane)
    return true, "cancelled"
end

local function startRequestedMove(zombie, record, lane)
    local now
    local goal = lane and lane.goal or nil
    if not zombie or not lane or not goal then
        return false, "no_goal"
    end
    now = Core.Now()
    hardResetMoveOwner(zombie)
    lane.resolvedMode = refreshResolvedLocomotion(record, lane, zombie, goal)
    if FakeLocomotion and FakeLocomotion.PrepareBody then
        FakeLocomotion.PrepareBody(zombie, lane, now)
    end
    setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or goal.mode, true)
    lane.startedAt = now
    lane.lastIssueAt = now
    lane.lastProgressAt = now
    lane.lastX = zombie:getX()
    lane.lastY = zombie:getY()
    lane.lastActionState = getActionStateName(zombie)
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.ownerMode = "fake_locomotion"
    setLanePhase(record, lane, "active", "started")
    logMoveTransition(record, zombie, lane, "request_issued", "started")
    return true, "started"
end

local function completeMove(zombie, record, lane, phase, reason)
    if zombie then
        hardResetMoveOwner(zombie)
    end
    lane.pendingGoal = nil
    lane.startedAt = 0
    lane.lastIssueAt = 0
    lane.lastProgressAt = 0
    lane.cancelReason = phase == "arrived" and reason or lane.cancelReason
    lane.blockReason = phase == "blocked" and reason or nil
    lane.recoveryCount = 0
    lane.lastRecoveryReason = nil
    lane.lastRecoverAt = 0
    lane.noProgressCount = 0
    lane.lastStepAt = 0
    lane.lastStepDistance = 0
    lane.lastStepLabel = nil
    lane.lastSuppressAudioAt = 0
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.resolvedMode = nil
    lane.animSpeed = 1.0
    lane.ownerMode = phase == "blocked" and "blocked" or "idle"
    setLanePhase(record, lane, phase, reason)
    logMoveTransition(record, zombie, lane, "complete", reason)
    applyHoldAnimation(zombie, record, lane)
    return true, reason
end

local function refreshPendingGoal(zombie, record, lane, reason)
    if not lane or not lane.pendingGoal then
        return false
    end
    setLaneGoal(record, lane, lane.pendingGoal)
    lane.pendingGoal = nil
    setLanePhase(record, lane, "requested", reason or "refresh")
    return startRequestedMove(zombie, record, lane)
end

local function restartCurrentGoal(zombie, record, lane, reason)
    if not lane or not lane.goal then
        return false, "no_goal"
    end
    lane.ownerMode = "requested"
    setLanePhase(record, lane, "requested", reason or "restart")
    return startRequestedMove(zombie, record, lane)
end

local function updateActiveMove(zombie, record, lane)
    local goal = lane and lane.goal or nil
    local now
    local stepped
    local stepResult
    local interacted
    local interactType
    local suppressed
    local suppressedState
    local stepDistance

    if not zombie or not lane or not goal then
        return false, "no_goal"
    end

    now = Core.Now()
    refreshResolvedLocomotion(record, lane, zombie, goal)
    lane.lastActionState = getActionStateName(zombie)
    if LiveBodyControl and LiveBodyControl.SuppressZombieState then
        suppressed, suppressedState = LiveBodyControl.SuppressZombieState(zombie, lane, now)
    else
        suppressed = false
        suppressedState = nil
    end
    if suppressed then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        lane.lastActionState = getActionStateName(zombie)
        lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
        lane.lastRecoveryReason = suppressedState or lane.lastActionState
        lane.lastRecoverAt = now
        if FakeLocomotion and FakeLocomotion.PrepareBody then
            FakeLocomotion.PrepareBody(zombie, lane, now)
        end
        if lane.ownerMode ~= "window_climb" and lane.ownerMode ~= "window_open" then
            setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or "walk", false)
        end
        logMoveWarning(record, zombie, lane, "suppress_state", suppressedState or lane.lastActionState, "action=" .. tostring(suppressedState or lane.lastActionState))
        logMoveDebug(record, zombie, lane, "suppress_state", suppressedState or lane.lastActionState, "postAction=" .. tostring(lane.lastActionState))
    end
    if (lane.ownerMode == "window_climb" or lane.ownerMode == "window_open")
        and now < (tonumber(lane.specialMoveUntil) or 0)
    then
        lane.lastProgressAt = now
        logMoveDebug(record, zombie, lane, "special_cooldown", lane.ownerMode, "")
        return true, lane.ownerMode
    end

    if lane.pendingGoal and (now - (tonumber(lane.lastIssueAt) or 0)) >= GOAL_REFRESH_DELAY_MS then
        return refreshPendingGoal(zombie, record, lane, "goal_refresh")
    end

    if isAtGoal(zombie, goal, lane.stopDistance) then
        return completeMove(zombie, record, lane, "arrived", "arrived")
    end

    interacted, interactType = tryDoorOrWindowInteraction(zombie, record, lane, goal.x, goal.y, goal.z)
    if interacted then
        lane.lastIssueAt = now
        lane.lastProgressAt = now
        lane.noProgressCount = 0
        lane.lastStepAt = now
        lane.lastX = zombie:getX()
        lane.lastY = zombie:getY()
        if interactType == "door_open" then
            lane.ownerMode = "door_open"
            lane.specialMoveUntil = now + 180
            lane.specialAnim = nil
        elseif interactType == "window_open" then
            lane.ownerMode = "window_open"
            lane.specialMoveUntil = now + 250
            lane.specialAnim = nil
        else
            lane.ownerMode = "window_climb"
        end
        logMoveDebug(record, zombie, lane, "interact", interactType or "door_or_window", "")
        return true, interactType or "interact"
    end

    if FakeLocomotion and FakeLocomotion.PrepareBody then
        FakeLocomotion.PrepareBody(zombie, lane, now)
    end
    setWalkAnim(zombie, record, lane.resolvedMode or lane.mode or goal.mode, false)
    if FakeLocomotion and FakeLocomotion.StepTowardGoal then
        stepped, stepResult, stepDistance = FakeLocomotion.StepTowardGoal(zombie, record, lane, goal, now)
    else
        stepped = false
        stepResult = "missing_locomotion"
        stepDistance = 0
    end

    if stepped then
        lane.ownerMode = "fake_locomotion"
        lane.recoveryCount = 0
        lane.lastRecoveryReason = nil
        lane.lastRecoverAt = 0
        lane.noProgressCount = 0
        lane.lastIssueAt = now
        lane.lastActionState = getActionStateName(zombie)
        lane.specialAnim = nil
        syncRecordPosition(record, zombie)
        if isAtGoal(zombie, goal, lane.stopDistance) then
            return completeMove(zombie, record, lane, "arrived", "arrived")
        end
        logMoveDebug(record, zombie, lane, "progress", "fake_step", "step=" .. tostring(stepResult or "direct") .. " dist=" .. string.format("%.3f", tonumber(stepDistance) or 0))
        return true, "moving"
    end

    if (now - (tonumber(lane.lastProgressAt) or 0)) >= PROGRESS_TIMEOUT_MS then
        lane.noProgressCount = (tonumber(lane.noProgressCount) or 0) + 1
        lane.blockReason = "fake_locomotion_blocked"
        logMoveWarning(record, zombie, lane, "progress_timeout", lane.blockReason or "progress_timeout", "")
        if lane.noProgressCount >= 2 then
            logMoveWarning(record, zombie, lane, "blocked", "progress_timeout", "goal=" .. describeGoal(goal))
            return completeMove(zombie, record, lane, "blocked", "progress_timeout")
        end
        lane.lastProgressAt = now
        return true, "retry"
    end

    return true, "waiting"
end

function PathService.Reset(zombie, record)
    if record and record.runtime then
        record.runtime.pathing = nil
        record.runtime.moveIntent = nil
    end
    hardResetMoveOwner(zombie)
end

function PathService.MoveToward(record, zombie, targetX, targetY, targetZ, mode, stopDistance, reason)
    record.runtime = record.runtime or {}
    record.runtime.moveIntent = {
        kind = "move",
        x = tonumber(targetX) or record.x,
        y = tonumber(targetY) or record.y,
        z = tonumber(targetZ) or record.z or 0,
        mode = tostring(mode or "walk"),
        stopDistance = tonumber(stopDistance) or 0.7,
        reason = reason or "path_service_move",
        requestedByJob = tostring(record.activeJob or "none"),
        requestedByBehavior = tostring(record.activeBehavior or record.activeJob or "none"),
        requestedOrder = tostring(record.orderSpec and record.orderSpec.kind or "none"),
        combatReason = tostring(record.runtime.combatBlockReason or "none"),
        updatedAt = Core.Now(),
    }
    if zombie and isAtGoal(zombie, buildGoal(targetX, targetY, targetZ, mode, stopDistance), stopDistance) then
        return true, "arrived"
    end
    return true, "move_intent"
end

function PathService.Pump(record, zombie)
    local runtime = record and record.runtime or nil
    local lane
    local intentState
    if not zombie or not runtime then
        return false, "no_live_body"
    end

    lane = ensureMoveLane(record)
    intentState = consumeMoveIntent(record, lane, zombie)

    if lane.phase == "cancel_pending" then
        finalizeCancel(zombie, record, lane)
        intentState = consumeMoveIntent(record, lane, zombie)
    end

    if lane.phase == "requested" then
        return startRequestedMove(zombie, record, lane)
    end

    if lane.phase == "active" then
        return updateActiveMove(zombie, record, lane)
    end

    if intentState == "arrived" then
        applyHoldAnimation(zombie, record, lane)
        return true, "arrived"
    end

    applyHoldAnimation(zombie, record, lane)
    return false, "idle"
end

function PathService.AdvanceAbstract(record, targetX, targetY, targetZ, stopDistance)
    local dist
    local dx
    local dy
    local len
    local step = Const.ABSTRACT_TRAVEL_STEP
    stopDistance = tonumber(stopDistance) or 1.0
    dist = Core.Distance(record.x, record.y, targetX, targetY)
    if dist <= stopDistance and record.z == targetZ then
        return true
    end
    dx = targetX - record.x
    dy = targetY - record.y
    len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0 then
        return true
    end
    record.x = record.x + (dx / len) * math.min(step, len)
    record.y = record.y + (dy / len) * math.min(step, len)
    record.z = targetZ
    return false
end

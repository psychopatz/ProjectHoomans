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
local getActionStateName
local isAtGoal

local GOAL_REFRESH_DELAY_MS = 120
local NO_PROGRESS_STEP_MS = 700
local PROGRESS_TIMEOUT_MS = 1200
local DIRECT_STEP_COOLDOWN_MS = 250
local CONFLICT_RECOVERIES_BEFORE_STEP = 2

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
        return 0.55
    end
    if mode == "sneak" or mode == "crawl" then
        return 0.2
    end
    return 0.35
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

local function setWalkAnim(zombie, record, mode)
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
    if zombie.setUseless then
        zombie:setUseless(false)
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
    if zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
end

local function issuePathRequest(zombie, targetX, targetY, targetZ)
    local behavior
    if not zombie then
        return false
    end
    if getActionStateName(zombie) == "walktoward" and zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    if zombie.getPathFindBehavior2 then
        behavior = zombie:getPathFindBehavior2()
        if behavior and behavior.pathToLocation and behavior.update then
            behavior:pathToLocation(targetX, targetY, targetZ)
            behavior:update()
            return true
        end
    end
    if zombie.pathToLocationF then
        zombie:pathToLocationF(targetX, targetY, targetZ)
        return true
    end
    if zombie.pathToLocation then
        zombie:pathToLocation(targetX, targetY, targetZ)
        return true
    end
    return false
end

getActionStateName = function(zombie)
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

local function isRecoverableConflictState(actionState)
    if actionState == nil or actionState == "" or actionState == "walktoward" then
        return false
    end
    if actionState == "lunge" then
        return true
    end
    if string.find(actionState, "attack", 1, true) then
        return true
    end
    if string.find(actionState, "thump", 1, true) then
        return true
    end
    return false
end

local function incrementRecovery(lane, actionState, reason)
    if not lane then
        return
    end
    lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
    lane.lastRecoveryReason = reason
    lane.lastActionState = actionState or ""
end

local function shouldUseHybridStep(lane, now)
    if not lane then
        return false
    end
    if (now - (tonumber(lane.lastDirectStepAt) or 0)) < DIRECT_STEP_COOLDOWN_MS then
        return false
    end
    if (tonumber(lane.recoveryCount) or 0) >= CONFLICT_RECOVERIES_BEFORE_STEP then
        return true
    end
    return (now - (tonumber(lane.lastProgressAt) or 0)) >= NO_PROGRESS_STEP_MS
end

local function applyHybridDirectStep(zombie, record, lane, reason)
    local goal
    local zx
    local zy
    local step
    local dx
    local dy
    local len
    local nx
    local ny
    local candidates
    local i
    local candidate
    local arrived
    local now = Core.Now()

    if not zombie or not record or not lane or not lane.goal then
        return false, nil
    end

    goal = lane.goal
    zx = zombie:getX()
    zy = zombie:getY()
    step = getDirectStepSize(lane.mode or goal.mode)
    dx = goal.x - zx
    dy = goal.y - zy
    len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.001 then
        return true, "arrived"
    end

    nx = zx + (dx / len) * math.min(step, len)
    ny = zy + (dy / len) * math.min(step, len)
    candidates = {
        { x = nx, y = ny, z = goal.z },
        { x = nx, y = zy, z = goal.z },
        { x = zx, y = ny, z = goal.z },
    }

    for i = 1, #candidates do
        candidate = candidates[i]
        if isSquareWalkable(candidate.x, candidate.y, candidate.z) then
            hardResetMoveOwner(zombie)
            if zombie.faceLocationF then
                zombie:faceLocationF(goal.x, goal.y)
            end
            zombie:setX(candidate.x)
            zombie:setY(candidate.y)
            zombie:setZ(candidate.z)
            syncRecordPosition(record, zombie)
            lane.ownerMode = "hybrid_step"
            lane.fallbackCount = (tonumber(lane.fallbackCount) or 0) + 1
            lane.lastDirectStepAt = now
            lane.lastProgressAt = now
            lane.lastIssueAt = now
            lane.lastX = zombie:getX()
            lane.lastY = zombie:getY()
            lane.lastActionState = getActionStateName(zombie)
            logMoveWarning(record, zombie, lane, "hybrid_step", reason or "hybrid_step", "step=" .. tostring(i))
            logMoveDebug(record, zombie, lane, "hybrid_step", reason or "hybrid_step", "step=" .. tostring(i))
            arrived = isAtGoal(zombie, goal, lane.stopDistance)
            if not arrived then
                setWalkAnim(zombie, record, lane.mode or goal.mode)
                issuePathRequest(zombie, goal.x, goal.y, goal.z)
                lane.ownerMode = "engine_path"
            end
            return true, arrived and "arrived" or "hybrid_step"
        end
    end

    return false, nil
end

local function recoverConflictingState(zombie, record, lane, now)
    local actionState = getActionStateName(zombie)
    local goal = lane and lane.goal or nil
    local walkTowardPathConflict
    local recoveryReason
    local stepped
    local stepResult

    if not zombie or not record or not lane then
        return false, nil
    end

    walkTowardPathConflict = actionState == "walktoward" and hasPath2(zombie)
    if not walkTowardPathConflict and not isRecoverableConflictState(actionState) then
        return false, nil
    end

    recoveryReason = walkTowardPathConflict and "walktoward_path2_conflict" or actionState
    incrementRecovery(lane, actionState, recoveryReason)
    logMoveWarning(
        record,
        zombie,
        lane,
        "recover_conflict",
        recoveryReason,
        "recovering goal=" .. describeGoal(goal) .. " mode=" .. tostring(lane.mode or "walk")
    )
    logMoveDebug(record, zombie, lane, "recover_conflict", recoveryReason, "")

    if shouldUseHybridStep(lane, now or Core.Now()) then
        stepped, stepResult = applyHybridDirectStep(zombie, record, lane, recoveryReason)
        if stepped then
            return true, stepResult
        end
    end

    hardResetMoveOwner(zombie)
    lane.phase = "requested"
    lane.ownerMode = "engine_path"
    lane.startedAt = 0
    setWalkAnim(zombie, record, lane.mode or "walk")
    issuePathRequest(zombie, goal and goal.x or zombie:getX(), goal and goal.y or zombie:getY(), goal and goal.z or zombie:getZ())
    return true, "state_recovered"
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

local function tryDoorOrWindowInteraction(zombie, record, goalX, goalY, goalZ)
    local cell
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
    local facingSatisfied
    local targetDx
    local targetDy
    local candidatesByGoal

    if not zombie or not getCell then
        return false
    end

    cell = getCell()
    zx = math.floor(zombie:getX())
    zy = math.floor(zombie:getY())
    zz = zombie:getZ()
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
                        if openDoorForNPC(zombie, object) then
                            return true
                        end
                    end
                    if instanceof(object, "IsoWindow") then
                        if (not facingSatisfied) and zombie.faceThisObject then
                            zombie:faceThisObject(object)
                            facingSatisfied = true
                        end
                    end
                    if instanceof(object, "IsoWindow") and facingSatisfied then
                        if (not object:IsOpen()) and (not object:isSmashed()) and (not object:isPermaLocked()) then
                            object:ToggleWindow(zombie)
                            return true
                        end
                        if object:canClimbThrough(zombie) then
                            ClimbThroughWindowState.instance():setParams(zombie, object)
                            zombie:changeState(ClimbThroughWindowState.instance())
                            zombie:setBumpType("ClimbWindow")
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
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
    setWalkAnim(zombie, record, lane.mode or goal.mode)
    if not issuePathRequest(zombie, goal.x, goal.y, goal.z) then
        lane.blockReason = "path_request_failed"
        lane.ownerMode = "blocked"
        setLanePhase(record, lane, "blocked", lane.blockReason)
        logMoveWarning(record, zombie, lane, "blocked", lane.blockReason, "goal=" .. describeGoal(goal))
        applyHoldAnimation(zombie, record, lane)
        return false, "path_request_failed"
    end
    lane.startedAt = now
    lane.lastIssueAt = now
    lane.lastProgressAt = now
    lane.lastX = zombie:getX()
    lane.lastY = zombie:getY()
    lane.lastActionState = getActionStateName(zombie)
    lane.ownerMode = "engine_path"
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
    local behavior
    local behaviorResult
    local goal = lane and lane.goal or nil
    local now
    local zx
    local zy
    local moved
    local recovered
    local recoverResult
    local stepped
    local stepResult

    if not zombie or not lane or not goal then
        return false, "no_goal"
    end

    now = Core.Now()
    lane.lastActionState = getActionStateName(zombie)
    recovered, recoverResult = recoverConflictingState(zombie, record, lane, now)
    if recovered then
        lane.lastIssueAt = now
        lane.lastProgressAt = now
        lane.lastX = zombie:getX()
        lane.lastY = zombie:getY()
        if recoverResult == "arrived" then
            return completeMove(zombie, record, lane, "arrived", "hybrid_step")
        end
        return true, recoverResult or "state_recovered"
    end

    if zombie.getPathFindBehavior2 then
        behavior = zombie:getPathFindBehavior2()
        if behavior and behavior.update then
            behaviorResult = behavior:update()
        end
    end

    if lane.pendingGoal and (now - (tonumber(lane.lastIssueAt) or 0)) >= GOAL_REFRESH_DELAY_MS then
        return refreshPendingGoal(zombie, record, lane, "goal_refresh")
    end

    if isAtGoal(zombie, goal, lane.stopDistance) then
        return completeMove(zombie, record, lane, "arrived", "arrived")
    end

    if BehaviorResult and behaviorResult == BehaviorResult.Succeeded then
        return completeMove(zombie, record, lane, "arrived", "behavior_succeeded")
    end

    zx = zombie:getX()
    zy = zombie:getY()
    if lane.lastX ~= nil and lane.lastY ~= nil then
        moved = Core.Distance(lane.lastX, lane.lastY, zx, zy)
        if moved > 0.05 then
            lane.lastX = zx
            lane.lastY = zy
            lane.lastProgressAt = now
            lane.recoveryCount = 0
            lane.ownerMode = "engine_path"
            syncRecordPosition(record, zombie)
            logMoveDebug(record, zombie, lane, "progress", "engine_progress", string.format("moved=%.2f", moved))
            return true, "moving"
        end
    end

    if tryDoorOrWindowInteraction(zombie, record, goal.x, goal.y, goal.z) then
        lane.lastIssueAt = now
        lane.lastProgressAt = now
        lane.ownerMode = "engine_path"
        issuePathRequest(zombie, goal.x, goal.y, goal.z)
        logMoveDebug(record, zombie, lane, "interact", "door_or_window", "")
        return true, "interact"
    end

    if BehaviorResult and behaviorResult == BehaviorResult.Failed then
        if lane.pendingGoal then
            logMoveWarning(record, zombie, lane, "repath", "behavior_failed_pending", "")
            return refreshPendingGoal(zombie, record, lane, "behavior_failed")
        end
        logMoveWarning(record, zombie, lane, "repath", "behavior_failed_restart", "")
        return restartCurrentGoal(zombie, record, lane, "behavior_failed")
    end

    if shouldUseHybridStep(lane, now) then
        stepped, stepResult = applyHybridDirectStep(zombie, record, lane, "no_progress")
        if stepped then
            if stepResult == "arrived" then
                return completeMove(zombie, record, lane, "arrived", "hybrid_step")
            end
            return true, stepResult
        end
    end

    if (now - (tonumber(lane.lastProgressAt) or 0)) >= PROGRESS_TIMEOUT_MS then
        logMoveWarning(record, zombie, lane, "progress_timeout", lane.blockReason or "progress_timeout", "")
        if issuePathRequest(zombie, goal.x, goal.y, goal.z) then
            lane.lastIssueAt = now
            lane.lastProgressAt = now
            lane.lastX = zombie:getX()
            lane.lastY = zombie:getY()
            lane.ownerMode = "engine_path"
            logMoveTransition(record, zombie, lane, "refreshed", "progress_timeout")
            return true, "repath"
        end
        if (not isServer or not isServer()) and isSquareWalkable(goal.x, goal.y, goal.z) then
            zombie:setX(goal.x)
            zombie:setY(goal.y)
            zombie:setZ(goal.z)
            syncRecordPosition(record, zombie)
            return completeMove(zombie, record, lane, "arrived", "fallback_snap")
        end
        logMoveWarning(record, zombie, lane, "blocked", "progress_timeout", "goal=" .. describeGoal(goal))
        return completeMove(zombie, record, lane, "blocked", "progress_timeout")
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

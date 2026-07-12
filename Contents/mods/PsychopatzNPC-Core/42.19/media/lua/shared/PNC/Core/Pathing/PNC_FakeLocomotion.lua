--[[
    PNC Fake Locomotion
    Server-authoritative embodied movement for live NPC bodies. It keeps zombie
    AI disabled and advances bodies by small controlled steps so behaviors can
    share one locomotion authority in both singleplayer and multiplayer.
]]

PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}

local FakeLocomotion = PNC.FakeLocomotion
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local TraversalQuery = PNC.TraversalQuery

local MAX_STEP_DELTA_MS = 120
local MIN_STEP_INTERVAL_MS = 35

local function isSquareWalkable(x, y, z, fromX, fromY, fromZ)
    if TraversalQuery and TraversalQuery.CanStep and fromX ~= nil and fromY ~= nil and fromZ ~= nil then
        return TraversalQuery.CanStep(fromX, fromY, fromZ, x, y, z)
    end
    return TraversalQuery and TraversalQuery.CanOccupy and TraversalQuery.CanOccupy(x, y, z) or false, "occupied"
end

local function buildCandidate(label, x, y, z)
    return {
        label = label,
        x = x,
        y = y,
        z = z,
    }
end

local function resolveProfile(lane, mode)
    local profile = lane and lane.motionProfile or nil
    if profile then
        return profile
    end
    if LocomotionProfiles and LocomotionProfiles.GetBaseProfile then
        return LocomotionProfiles.GetBaseProfile(mode)
    end
    return {
        speed = 0.76,
        moveAnim = mode == "run" and "Run" or mode == "sneak" and "SneakWalk" or mode == "crawl" and "Crawl" or "Walk",
    }
end

local function getSpeedForMode(mode, lane)
    local profile = resolveProfile(lane, mode)
    return tonumber(profile and profile.speed) or 0.76
end

function FakeLocomotion.GetModeSpeed(mode)
    return getSpeedForMode(mode)
end

function FakeLocomotion.ComputeAnimSpeed(mode)
    if LocomotionProfiles and LocomotionProfiles.ComputeAnimSpeed then
        return LocomotionProfiles.ComputeAnimSpeed(mode)
    end
    return 1.0
end

local function computeStepDistance(lane, mode, now)
    local lastStepAt = tonumber(lane and lane.lastStepAt or 0) or 0
    local speed = getSpeedForMode(mode, lane)
    local deltaMs
    if lastStepAt <= 0 then
        return math.max(0.03, speed * 0.05), 50
    end
    deltaMs = math.max(0, now - lastStepAt)
    if deltaMs < MIN_STEP_INTERVAL_MS then
        return 0, deltaMs
    end
    deltaMs = math.min(deltaMs, MAX_STEP_DELTA_MS)
    return math.max(0.02, speed * (deltaMs / 1000)), deltaMs
end

local function buildStepCandidates(zx, zy, zz, goal, stepDistance, steeringSide)
    local dx = goal.x - zx
    local dy = goal.y - zy
    local len = math.sqrt((dx * dx) + (dy * dy))
    local ux
    local uy
    local px
    local py
    if len <= 0.0001 then
        return {}
    end
    ux = dx / len
    uy = dy / len
    px = -uy
    py = ux
    if tonumber(steeringSide) == -1 then
        px = -px
        py = -py
    end
    return {
        buildCandidate("direct", zx + (ux * stepDistance), zy + (uy * stepDistance), goal.z),
        buildCandidate("slide_preferred", zx + ((ux + (px * 0.55)) * stepDistance), zy + ((uy + (py * 0.55)) * stepDistance), goal.z),
        buildCandidate("axis_x", zx + (ux * stepDistance), zy, goal.z),
        buildCandidate("axis_y", zx, zy + (uy * stepDistance), goal.z),
        buildCandidate("hard_preferred", zx + (px * stepDistance), zy + (py * stepDistance), goal.z),
        buildCandidate("slide_other", zx + ((ux - (px * 0.55)) * stepDistance), zy + ((uy - (py * 0.55)) * stepDistance), goal.z),
        buildCandidate("hard_other", zx - (px * stepDistance), zy - (py * stepDistance), goal.z),
    }
end

function FakeLocomotion.PrepareBody(zombie, lane, now)
    local resolvedMode = lane and lane.resolvedMode or lane and lane.mode or "walk"
    local profile = resolveProfile(lane, resolvedMode)
    if not zombie then
        return
    end
    if LiveBodyControl and LiveBodyControl.ApplyHumanizedBodyFlags then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    if LiveBodyControl and LiveBodyControl.TrySilenceEmitter then
        LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    end
    if zombie.setRunning then
        zombie:setRunning(profile and profile.isRunning == true)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
end

function FakeLocomotion.StepTowardGoal(zombie, record, lane, goal, now)
    local stepDistance
    local zx
    local zy
    local zz
    local candidates
    local i
    local candidate
    local walkable
    local blockReason
    if not zombie or not record or not lane or not goal then
        return false, "invalid", 0
    end
    stepDistance = computeStepDistance(lane, lane and lane.resolvedMode or lane.mode or goal.mode, now)
    if stepDistance <= 0 then
        return false, "throttle", 0
    end
    zx = zombie:getX()
    zy = zombie:getY()
    zz = zombie:getZ()
    candidates = buildStepCandidates(zx, zy, goal.z, goal, stepDistance, lane.steeringSide)
    for i = 1, #candidates do
        candidate = candidates[i]
        walkable, blockReason = isSquareWalkable(candidate.x, candidate.y, candidate.z, zx, zy, zz)
        if i == 1 and not walkable and (blockReason == "door" or blockReason == "window" or blockReason == "fence") then
            lane.lastStepAt = now
            lane.lastStepDistance = 0
            lane.lastStepLabel = blockReason
            return false, "interaction_blocked", stepDistance
        end
        if walkable then
            if PNC.PathService and PNC.PathService.ApplyTravelFacing then
                PNC.PathService.ApplyTravelFacing(zombie, lane, candidate.x, candidate.y, now)
            elseif zombie.faceLocation then
                zombie:faceLocation(candidate.x, candidate.y)
            elseif zombie.faceLocationF then
                zombie:faceLocationF(candidate.x, candidate.y)
            end
            zombie:setX(candidate.x)
            zombie:setY(candidate.y)
            zombie:setZ(candidate.z)
            record.x = candidate.x
            record.y = candidate.y
            record.z = candidate.z
            lane.lastStepAt = now
            lane.lastStepDistance = stepDistance
            lane.lastStepLabel = candidate.label
            lane.lastProgressAt = now
            lane.lastX = candidate.x
            lane.lastY = candidate.y
            lane.lastZ = candidate.z
            if candidate.label == "direct" then
                lane.directStepCount = (tonumber(lane.directStepCount) or 0) + 1
                if lane.directStepCount >= 6 then
                    lane.steeringSide = nil
                end
            else
                lane.directStepCount = 0
                if lane.steeringSide == nil then
                    if candidate.label == "slide_other" or candidate.label == "hard_other" then
                        lane.steeringSide = -1
                    else
                        lane.steeringSide = 1
                    end
                end
            end
            if PNC.MotionHints and PNC.MotionHints.Remember then
                PNC.MotionHints.Remember(lane, zx, zy, zz, candidate.x, candidate.y, candidate.z, now, {
                    kind = "move",
                    speed = lane.speed,
                    profile = lane.motionProfile,
                })
            end
            return true, candidate.label, stepDistance
        end
    end
    lane.lastStepAt = now
    lane.lastStepDistance = 0
    lane.lastStepLabel = "blocked"
    lane.directStepCount = 0
    lane.steeringSide = tonumber(lane.steeringSide) == 1 and -1 or 1
    return false, "blocked", stepDistance
end

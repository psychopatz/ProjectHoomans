-- Shared fishing order projection. The server executor owns progress and
-- loot; this handler owns movement, facing, and live presentation.

PNC = PNC or {}
PNC.BehaviorFishing = PNC.BehaviorFishing or {}

local Fishing = PNC.BehaviorFishing
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon

local KIND = Const.ORDER_FISHING or "fishing"
local JOB = "Fishing"
-- The server starts fishing inside its activation radius. Keep the shared
-- behavior tolerance slightly wider than the old 0.8-tile movement threshold
-- so a valid shoreline position does not oscillate forever just outside the
-- animation point.
local FISHING_STAND_RADIUS = tonumber(Const.FISHING_INTERACTION_RADIUS)
    or 1.75

local function normalize(_, spec)
    spec = type(spec) == "table" and spec or {}
    return {
        kind = KIND,
        fishingJobId = tostring(spec.fishingJobId or ""),
        zoneId = tostring(spec.zoneId or ""),
        spotId = tostring(spec.spotId or ""),
        phase = tostring(spec.phase or "WAITING"),
        standX = tonumber(spec.standX),
        standY = tonumber(spec.standY),
        standZ = tonumber(spec.standZ) or 0,
        waterX = tonumber(spec.waterX),
        waterY = tonumber(spec.waterY),
        waterZ = tonumber(spec.waterZ) or 0,
    }
end

local function coordinates(record)
    local order = record and record.orderSpec or {}
    local runtime = record and record.runtime
        and record.runtime.fishing or nil
    return runtime and runtime.standX or order.standX,
        runtime and runtime.standY or order.standY,
        runtime and runtime.standZ or order.standZ or 0,
        runtime and runtime.waterX or order.waterX,
        runtime and runtime.waterY or order.waterY,
        runtime and runtime.waterZ or order.waterZ or 0
end

local function actorPosition(record, zombie)
    local x = zombie and zombie.getX and zombie:getX() or record.x
    local y = zombie and zombie.getY and zombie:getY() or record.y
    local z = zombie and zombie.getZ and zombie:getZ() or record.z
    return tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
end

local function recordAnimationRequest(record, sceneID, started, reason)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.fishingAnimationRequest = {
        scene = sceneID,
        ok = started == true,
        reason = tostring(reason or (started and "requested" or "rejected")),
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    }
end

function Fishing.Tick(record, zombie)
    local order = record and record.orderSpec or nil
    local standX, standY, standZ, waterX, waterY
    local actorX, actorY, actorZ
    local fishingRuntime
    local phase
    if not order or tostring(order.kind or "") ~= tostring(KIND) then
        return false
    end

    fishingRuntime = record.runtime and record.runtime.fishing or nil
    phase = tostring(fishingRuntime and fishingRuntime.phase
        or order.phase or "WAITING")
    record.activeJob = JOB
    record.activeBehavior = "Fishing:" .. phase
    if Common and Common.ClearCombatTarget then
        Common.ClearCombatTarget(record, "fishing", zombie)
    end

    standX, standY, standZ, waterX, waterY = coordinates(record)
    if not standX or not standY then
        record.activeBehavior = "Fishing:WaitingForSpot"
        if Common and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "fishing_no_spot")
        end
        return true
    end

    -- The server keeps the order alive while it retries equipment, output,
    -- or a fishing-spot claim. Do not walk toward the water during those
    -- waits: movement here used to make a failed tool handoff look like a
    -- navigation loop and could also move the NPC away from its home state.
    if phase == "TOOL_CHECK" or phase == "WAITING_FOR_TOOL"
        or phase == "WAITING_FOR_OUTPUT"
        or phase == "WAITING_FOR_SPOT"
    then
        record.activeBehavior = "Fishing:" .. phase
        if Common and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "fishing_" .. string.lower(phase))
        end
        return true
    end

    actorX, actorY, actorZ = actorPosition(record, zombie)
    if math.abs(actorZ - standZ) > 0.6
        or PNC.Core.Distance(actorX, actorY, standX, standY)
            > FISHING_STAND_RADIUS
    then
        if record.presenceState == Const.PRESENCE_ABSTRACT then
            record.activeBehavior = "Fishing:WaitingNearby"
            return true
        end
        if Common and Common.MoveRecord then
            Common.MoveRecord(record, zombie, standX, standY, standZ,
                "walk", 0.65, "fishing_spot")
        end
        return true
    end

    if Common and Common.HaltMovement then
        Common.HaltMovement(record, zombie, "fishing_spot")
    end
    if phase ~= "WAITING" and phase ~= "WORKING" then
        record.activeBehavior = "Fishing:" .. phase
        return true
    end
    if zombie and zombie.faceLocationF and waterX and waterY then
        zombie:faceLocationF(waterX, waterY)
    end

    if zombie and PNC.AnimationScenes
        and type(PNC.AnimationScenes.Request) == "function"
    then
        local scene = record.runtime and record.runtime.animationScene
        local lastAttemptAt = fishingRuntime
            and fishingRuntime.lastAttemptAt or nil
        local lastAnimatedAttemptAt = record.runtime
            and record.runtime.fishingAnimationAttemptAt or nil
        if scene and scene.id == "fishing.strike" then
            return true
        end
        if lastAttemptAt and lastAttemptAt ~= lastAnimatedAttemptAt then
            local started, requestReason = PNC.AnimationScenes.Request(
                record, zombie, "fishing.strike", {
                    reason = "fishing_attempt", repeatMode = "once",
                })
            recordAnimationRequest(
                record, "fishing.strike", started, requestReason
            )
            if started then
                record.runtime.fishingAnimationAttemptAt = lastAttemptAt
                return true
            end
        end
        if not scene or scene.id ~= "fishing.cast" then
            local started, requestReason = PNC.AnimationScenes.Request(
                record, zombie, "fishing.cast", {
                    reason = "fishing", repeatMode = "loop",
                }
            )
            recordAnimationRequest(
                record, "fishing.cast", started, requestReason
            )
        end
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(KIND, JOB)
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register(JOB, Fishing.Tick)
end

return Fishing

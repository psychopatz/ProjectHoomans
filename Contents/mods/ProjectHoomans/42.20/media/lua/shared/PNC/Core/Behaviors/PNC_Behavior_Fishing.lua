-- Shared fishing order projection. The server executor owns progress and
-- loot; this handler owns movement, facing, and live presentation.

PNC = PNC or {}
PNC.BehaviorFishing = PNC.BehaviorFishing or {}

local Fishing = PNC.BehaviorFishing
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon

local KIND = Const.ORDER_FISHING or "fishing"
local JOB = "Fishing"

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

function Fishing.Tick(record, zombie)
    local order = record and record.orderSpec or nil
    local standX, standY, standZ, waterX, waterY
    local actorX, actorY, actorZ
    if not order or tostring(order.kind or "") ~= tostring(KIND) then
        return false
    end

    record.activeJob = JOB
    record.activeBehavior = "Fishing:" .. tostring(order.phase or "WAITING")
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

    actorX, actorY, actorZ = actorPosition(record, zombie)
    if math.abs(actorZ - standZ) > 0.6
        or PNC.Core.Distance(actorX, actorY, standX, standY) > 0.8
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
    if zombie and zombie.faceLocationF and waterX and waterY then
        pcall(zombie.faceLocationF, zombie, waterX, waterY)
    end

    if zombie and PNC.AnimationScenes
        and type(PNC.AnimationScenes.Request) == "function"
    then
        local scene = record.runtime and record.runtime.animationScene
        if not scene or scene.id ~= "fishing.cast" then
            pcall(PNC.AnimationScenes.Request, record, zombie, "fishing.cast", {
                reason = "fishing", repeatMode = "loop",
            })
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

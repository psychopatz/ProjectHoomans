-- Presence-audit events emitted by abstract follow-owner movement.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local H = Companion.Internal.AbstractFollowOwnerMovementAudit
if type(H) ~= "table" then
    return Companion
end

local Core = H.Core
local Diagnostics = H.Diagnostics

function H.LogHeld(record, runtime, moveReason, targetX, targetY)
    if not Diagnostics or not Diagnostics.LogFollowerPresence then
        return
    end
    local activity = runtime.facilityActivity
    Diagnostics.LogFollowerPresence(
        "abstract_follow_move_held", {
            "npc=" .. tostring(record.id),
            "reason=" .. tostring(moveReason or "no_displacement"),
            "capability=" .. tostring(
                activity and activity.capability or "nil"),
            "phase=" .. tostring(activity and activity.phase or "nil"),
            "seating=" .. tostring(activity and activity.seating == true),
            "target=" .. tostring(targetX) .. "," .. tostring(targetY),
        }
    )
end

function H.LogTick(
    record,
    runtime,
    ownerResolved,
    now,
    beforeX,
    beforeY,
    beforeZ,
    targetX,
    targetY,
    targetZ,
    moved,
    arrived,
    movementSpeed,
    catchupApplied
)
    if not Diagnostics or not Diagnostics.LogFollowerPresence then
        return
    end
    local distanceAfter = Core.Distance(
        tonumber(record.x) or beforeX,
        tonumber(record.y) or beforeY,
        targetX,
        targetY
    )
    runtime.abstractFollowLastTickAt = now
    Diagnostics.LogFollowerPresence("abstract_follow_tick", {
        "npc=" .. tostring(record.id),
        "owner=" .. tostring(record.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(record.ownerOnlineID or "nil"),
        "ownerResolved=" .. tostring(ownerResolved),
        "from=" .. tostring(beforeX) .. "," .. tostring(beforeY)
            .. "," .. tostring(beforeZ),
        "to=" .. tostring(record.x) .. "," .. tostring(record.y)
            .. "," .. tostring(record.z),
        "target=" .. tostring(targetX) .. "," .. tostring(targetY)
            .. "," .. tostring(targetZ),
        "targetMode=exact_owner",
        "handoffRequested=" .. tostring(
            runtime.abstractFollowMaterializeRequested == true
        ),
        "distanceBefore=" .. tostring(
            Core.Distance(beforeX, beforeY, targetX, targetY)),
        "distanceAfter=" .. tostring(distanceAfter),
        "moved=" .. tostring(moved),
        "arrived=" .. tostring(arrived),
        "abstractSpeed=" .. tostring(movementSpeed),
        "catchup=" .. tostring(catchupApplied),
        "cadenceMs=" .. tostring(PNC.Const.TICK_ABSTRACT_MS or 3000),
    })
end

return Companion

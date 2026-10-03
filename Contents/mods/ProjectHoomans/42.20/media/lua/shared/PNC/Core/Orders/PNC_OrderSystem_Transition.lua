local OrderSystem = require "PNC/Core/Orders/PNC_OrderSystem_Base"
local Internal = OrderSystem.Internal or {}
local Core = Internal.Core
local Const = Internal.Const
local Skills = Internal.Skills
local wakeRecord = Internal.wakeRecord
local releaseCampBlockedTask = Internal.releaseCampBlockedTask
local cancelSemanticActionPlan = Internal.cancelSemanticActionPlan
local movementOrderKind = Internal.movementOrderKind

function OrderSystem.SetOrder(record, orderSpec)
    local zombie
    local previousOrder = record.orderSpec
    local previousKind = tostring(previousOrder and previousOrder.kind or "")
    local requestedKind = tostring(orderSpec
        and (orderSpec.kind or orderSpec.mode) or "")
    local activeFacility = record.runtime
        and record.runtime.facilityActivity or nil
    local pendingCampPlacement
    record.runtime = record.runtime or {}

    -- CampMovementCoordinator writes the placement lock before calling this
    -- function. Capture it across cleanup because facility/lease teardown can
    -- synchronously re-enter SetOrder and a nested order transition may clear
    -- runtime camp state before the requested camp order is normalized.
    if requestedKind == tostring(Const.ORDER_CAMP or "camp") then
        pendingCampPlacement = record.runtime.campPlacement
    end

    -- A facility activity owns the behavior tick regardless of which durable
    -- order was last persisted. This catches stale runtime activity left
    -- behind after a previous order transition, and it must happen before
    -- lease cleanup so the facility abort path cannot restore the old order
    -- over the camp request.
    if requestedKind ~= "facility_activity"
        and activeFacility
        and PNC.FacilityJobs
        and PNC.FacilityJobs.AbortForOrderChange
    then
        PNC.FacilityJobs.AbortForOrderChange(
            record,
            nil,
            requestedKind == tostring(Const.ORDER_CAMP or "camp")
                and "camp_entered" or "order_changed"
        )
        previousOrder = record.orderSpec
        previousKind = tostring(previousOrder and previousOrder.kind or "")
        activeFacility = record.runtime.facilityActivity
    end

    if requestedKind == tostring(Const.ORDER_CAMP or "camp") then
        cancelSemanticActionPlan(record, "camp_entered")
        local released, releaseReason = releaseCampBlockedTask(record)
        if released == false and Core.LogWarn then
            Core.LogWarn("camp_task_release_failed npc="
                .. tostring(record.id or "") .. " reason="
                .. tostring(releaseReason or "unknown"))
        end
        -- Re-read these after lease cleanup. ReleaseWorker restores the
        -- previous durable order through SetOrder before this camp order is
        -- installed.
        previousOrder = record.orderSpec
        previousKind = tostring(previousOrder and previousOrder.kind or "")
        activeFacility = record.runtime.facilityActivity
        if pendingCampPlacement
            and not record.runtime.campPlacement
        then
            record.runtime.campPlacement = pendingCampPlacement
        end
    end

    -- A blocking facility scene owns the behavior tick until it is stopped.
    -- Commands such as follow/home must revoke that lease before the new order
    -- is normalized; otherwise the old relaxing scene consumes every tick and
    -- the command appears to have been ignored.
    if activeFacility
        and requestedKind ~= "facility_activity"
        and (movementOrderKind(requestedKind)
            or previousKind == "facility_activity")
        and PNC.FacilityJobs
        and PNC.FacilityJobs.AbortForOrderChange
    then
        PNC.FacilityJobs.AbortForOrderChange(
            record,
            nil,
            requestedKind == tostring(Const.ORDER_CAMP or "camp")
                and "camp_entered" or "order_changed"
        )
    end

    if requestedKind == tostring(Const.ORDER_CAMP or "camp")
        and pendingCampPlacement
        and not record.runtime.campPlacement
    then
        record.runtime.campPlacement = pendingCampPlacement
    end

    record.orderSpec = OrderSystem.Normalize(record, orderSpec)
    if tostring(record.orderSpec.kind or "")
        ~= tostring(Const.ORDER_CAMP or "camp")
    then
        -- A queued camp placement is runtime coordination state, not a
        -- general NPC lock. Clear it when another durable order supersedes
        -- camp so stale placement data cannot block the next need/job.
        record.runtime.campPlacement = nil
        record.runtime.campZoneAssignment = nil
    elseif record.runtime.campPlacement
        and tostring(record.runtime.campPlacement.campID or "")
            ~= tostring(record.orderSpec.campId or "")
    then
        -- A new camp session must not inherit the previous session's queue
        -- state, even when the new order is also a camp order.
        record.runtime.campPlacement = nil
        record.runtime.campZoneAssignment = nil
    end
    -- A return complaint belongs only to the follow order that created it.
    -- Clear it at the durable order boundary so an NPC that is reassigned
    -- while abstract cannot later deliver stale follow-phase commentary.
    if previousKind == tostring(Const.ORDER_FOLLOW or "follow")
        and tostring(record.orderSpec.kind or "")
            ~= tostring(Const.ORDER_FOLLOW or "follow")
        and record.followerAbandonment
    then
        record.followerAbandonment = nil
    end
    if record.orderSpec.kind == Const.ORDER_FOLLOW then
        -- Keep an identity already resolved on the record: an order built by an
        -- NPC-to-NPC or rehydrated path may not carry one, and a nil write here
        -- would freeze a bodyless follower on its anchor.
        record.ownerUsername = record.orderSpec.ownerUsername
            or record.ownerUsername
        record.ownerOnlineID = record.orderSpec.ownerOnlineID
            or record.ownerOnlineID
    end
    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.followState = nil
    record.runtime.roaming = nil
    record.runtime.roamGoalX = nil
    record.runtime.roamGoalY = nil
    record.runtime.roamGoalZ = nil
    record.activeJob = nil
    record.activeBehavior = nil
    zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if PNC.PathService and PNC.PathService.Commands
        and PNC.PathService.Commands.Reset
    then
        PNC.PathService.Commands.Reset(record, zombie, "order_changed")
    elseif PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(zombie, record)
    else
        record.runtime.moveIntent = nil
        record.runtime.pathing = nil
    end
    if record.orderSpec.kind == Const.ORDER_PATROL and record.patrolIndex == nil then
        record.patrolIndex = 1
    end
    if Skills and Skills.SyncRecruitment then
        Skills.SyncRecruitment(record)
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "order")
    end
    if PNC.CampResourceService and PNC.CampResourceService.OnOrderChanged then
        PNC.CampResourceService.OnOrderChanged(
            record, previousOrder, record.orderSpec)
    end
    -- Camp is a durable order boundary. Need severity can already be high
    -- when a follower enters camp, so no severity_changed event is guaranteed
    -- to arrive after the order change. Wake tasking after the snapshot has
    -- been captured; facility_activity transitions are intentionally excluded
    -- so starting a need task cannot immediately re-enter task evaluation.
    if tostring(record.orderSpec.kind or "")
        == tostring(Const.ORDER_CAMP or "camp")
        and previousKind ~= tostring(Const.ORDER_CAMP or "camp")
        and record.orderSpec.ambientNoNeeds ~= true
        and PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        PNC.Tasking.Events.Emit("NPC_NEEDS_CHANGED", {
            npcId = record.id, source = "OrderSystem",
            entityId = record.id, cause = "CAMP_ENTERED",
        })
    end
    wakeRecord(record)
end


return OrderSystem

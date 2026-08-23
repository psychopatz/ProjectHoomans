PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

-- Long actions such as self-treatment own the selector for their whole
-- authority window. Extend a healthy selector without replaying it; if the
-- engine dropped the bumped state early, restart the same PNC-owned node.
function Animation.MaintainBump(
    zombie,
    record,
    bumpType,
    leaseUntil,
    options
)
    local modData
    local resolvedBumpType
    local now
    if not zombie then
        return false, "no_body"
    end
    now = Core and Core.Now and Core.Now() or 0
    resolvedBumpType = Animation.ResolveBumpType(bumpType)
    modData = zombie.getModData and zombie:getModData() or nil
    if modData
        and tostring(modData.PNC_BumpRequestedType or "")
            == tostring(resolvedBumpType)
        and Animation.IsBumpActionActive(zombie, now)
    then
        modData.PNC_BumpActionLeaseUntil = math.max(
            tonumber(modData.PNC_BumpActionLeaseUntil) or 0,
            tonumber(leaseUntil) or (
                now + Internal.BUMP_ACTION_LEASE_TIMEOUT_MS
            )
        )
        Internal.applyBumpLeaseBodyMode(zombie)
        return true, "bump_maintained"
    end
    return Animation.PlayBump(
        zombie,
        record,
        bumpType,
        {
            leaseUntil = leaseUntil,
            sceneId = options and options.sceneId or nil,
            sceneRevision = options
                and options.sceneRevision or nil,
        }
    )
end

function Animation.FinishBump(zombie, forceIdle)
    local modData
    if not zombie then
        return
    end
    if AnimationTrace and AnimationTrace.MarkFinishing then
        AnimationTrace.MarkFinishing(
            zombie,
            "finish_before"
        )
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if zombie.setVariable then
        -- BumpedState must observe both completion flags during its next
        -- ActionContext update. Clearing BumpAnimFinished in this same tick
        -- leaves the body permanently in the bumped action state.
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
    if modData then
        modData.PNC_BumpReleasePending = true
        modData.PNC_BumpReleaseAt = Core and Core.Now and Core.Now() or 0
        modData.PNC_BumpActionLease = true
    end
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(
            zombie,
            "finish_after",
            nil,
            true
        )
    end
end

function Animation.PumpBumpRelease(zombie, now)
    local modData
    local releaseAt
    local actionState
    if not zombie then
        return false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if not modData or modData.PNC_BumpReleasePending ~= true then
        return false
    end
    -- Let BumpedState observe the completion variables and run its normal
    -- exit before restoring PNC's otherwise-useless human shell mode.
    Internal.applyBumpLeaseBodyMode(zombie)
    now = tonumber(now) or Core and Core.Now and Core.Now() or 0
    releaseAt = tonumber(modData.PNC_BumpReleaseAt) or now
    if zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
    actionState = Internal.getActionStateName(zombie)
    if (now - releaseAt) < Internal.BUMP_RELEASE_SETTLE_MS
        or (
            actionState == "bumped"
            and (now - releaseAt) < Internal.BUMP_RELEASE_HARD_TIMEOUT_MS
        )
    then
        if AnimationTrace and AnimationTrace.Sample then
            AnimationTrace.Sample(
                zombie,
                "release_wait",
                now
            )
        end
        return true
    end
    -- BumpedState occasionally misses both completion latches after a native
    -- path/traversal handoff. Waiting forever leaves the NPC frozen in a
    -- mid-swing or climbing pose. Past the grace window, clear the selector
    -- and force only this demonstrably stuck action back to idle.
    if actionState == "bumped"
        and (now - releaseAt) >= Internal.BUMP_RELEASE_HARD_TIMEOUT_MS
    then
        if zombie.reportEvent then
            zombie:reportEvent("ActiveAnimFinishing")
        end
        if zombie.setBumpType then
            zombie:setBumpType("")
        end
        if zombie.changeState
            and ZombieIdleState
            and ZombieIdleState.instance
        then
            zombie:changeState(ZombieIdleState.instance())
        end
        if Core and Core.LogWarn then
            Core.LogWarn(
                "bump_release_recovered action=bumped requested="
                    .. tostring(modData.PNC_BumpRequestedType or "")
            )
        end
    end
    -- BumpedState.exit owns clearing BumpAnimFinished and BumpType. This
    -- fallback only normalizes a body that has already left that state.
    if zombie.setBumpType then
        zombie:setBumpType("")
    end
    modData.PNC_BumpReleasePending = nil
    modData.PNC_BumpReleaseAt = nil
    modData.PNC_BumpActionLease = nil
    modData.PNC_BumpActionLeaseUntil = nil
    modData.PNC_BumpActionLeaseStartedAt = nil
    modData.PNC_BumpRequestedType = nil
    modData.PNC_BumpKeepUseless = nil
    if AnimationTrace and AnimationTrace.End then
        AnimationTrace.End(
            zombie,
            "release_complete",
            now
        )
    end
    return false
end

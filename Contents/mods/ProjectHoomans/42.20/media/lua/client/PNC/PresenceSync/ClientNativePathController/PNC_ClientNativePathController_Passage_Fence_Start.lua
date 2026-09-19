--[[
    PNC Native Passage: start managed fence climbs.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared
local Fence = Passage.FenceInternal

local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl

local clearOwnedPath = Controller.ClearOwnedPath
local logState = Controller.LogState
local logPassageEvent = Shared.LogPassageEvent
local describeBody = Controller.DescribeBody

local function prepareFenceClimb(snapshot, body, state, passage, object)
    local toSquare = passage and passage.toSquare or nil
    local fromSquare = passage and passage.fromSquare or nil
    local profile
    local tall
    local upDuration
    local crossingDuration
    local finishHold
    local finishDuration
    local transferX
    local transferY
    if not toSquare then return false, nil end
    if not fromSquare and body.getSquare then
        fromSquare = body:getSquare()
    end
    if TraversalQuery and TraversalQuery.IsFenceApproachReady
        and not TraversalQuery.IsFenceApproachReady(
            body:getX(),
            body:getY(),
            fromSquare,
            toSquare,
            passage.dirX,
            passage.dirY
        )
    then
        return false, "native_fence_not_ready"
    end
    if TraversalQuery and TraversalQuery.CanTraverseAt
        and not TraversalQuery.CanTraverseAt(
            toSquare:getX() + 0.5,
            toSquare:getY() + 0.5,
            toSquare:getZ()
        )
    then
        return false, "native_fence_landing_blocked"
    end
    if not TraversalQuery
        or not TraversalQuery.GetFenceTransferPoint
    then
        return false, "native_fence_geometry_unavailable"
    end
    transferX, transferY = TraversalQuery.GetFenceTransferPoint(
        fromSquare,
        toSquare,
        body:getX(),
        body:getY()
    )
    if transferX == nil or transferY == nil then
        return false, "native_fence_geometry_invalid"
    end
    local _, isTall = TraversalQuery.IsFence(object)
    tall = isTall == true
    profile = TraversalProfiles
        and TraversalProfiles.Resolve
        and TraversalProfiles.Resolve(
            "fence_climb",
            {
                body = body,
                snapshot = snapshot,
                state = state,
                obstacle = object,
                tall = tall,
            },
            tall and "tall" or "low"
        ) or {}
    upDuration = tonumber(profile.upDurationMs)
        or Fence.Policy.ClimbUpMs
    crossingDuration = tonumber(profile.crossingDurationMs)
        or Fence.Policy.ClimbCrossMs
    finishHold = tonumber(profile.finishHoldMs) or 320
    finishDuration = tall
        and (tonumber(profile.travelDurationMs)
            or Fence.Policy.TallClimbFinishMs)
        or upDuration + crossingDuration + finishHold

    return {
        fromSquare = fromSquare,
        toSquare = toSquare,
        transferX = transferX,
        transferY = transferY,
        tall = tall,
        profile = profile,
        upDuration = upDuration,
        crossingDuration = crossingDuration,
        finishHold = finishHold,
        finishDuration = finishDuration,
    }, nil
end

local function startFenceClimb(snapshot, body, state, passage, object, now)
    local prepared, reason = prepareFenceClimb(
        snapshot, body, state, passage, object
    )
    if not prepared then return false, reason end
    local toSquare = prepared.toSquare
    local fromSquare = prepared.fromSquare
    local tall = prepared.tall
    local profile = prepared.profile
    local upDuration = prepared.upDuration
    local crossingDuration = prepared.crossingDuration
    local finishHold = prepared.finishHold
    clearOwnedPath(body, state)
    if LiveBodyControl and LiveBodyControl.ResetNativeMovementState then
        LiveBodyControl.ResetNativeMovementState(body)
    end
    -- PathFindBehavior2 may have entered vanilla ClimbOverFenceState on the
    -- collision frame before this controller observed the passage. Reset that
    -- state before installing the PNC bump scene; NPCs do not own player
    -- BodyDamage, so allowing the vanilla state to finish can throw in its
    -- fall-after-vault check.
    if LiveBodyControl and LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(body, state, now)
    end
    local key = "fence_climb:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    state.passageAction = {
        kind = "fence_climb", key = key, object = object,
        startedAt = now,
        finishAt = now + prepared.finishDuration,
        finishHoldMs = finishHold,
        twoPhase = tall ~= true,
        phase = tall and "single" or "up",
        travelDurationMs = tall
            and (tonumber(profile.travelDurationMs)
                or Fence.Policy.TallClimbFinishMs)
            or nil,
        upDurationMs = tall and nil or upDuration,
        upFinishAt = tall and nil or now + upDuration,
        crossingDurationMs = tall and nil or crossingDuration,
        -- The transfer event already marks the exact hand-off point. Do not
        -- add another settle frame for low fences; it presents as a brief
        -- freeze on the top rail before the crossing clip starts.
        transitionSettleMs = tall and nil or 0,
        startAnim = tall and nil
            or profile.startAnim or "PNC_LegacyClimbFenceStart",
        endAnim = tall and nil
            or profile.endAnim or "PNC_LegacyClimbFenceEnd",
        fromX = body:getX(), fromY = body:getY(),
        fromSquare = fromSquare,
        toSquare = toSquare,
        fenceKey = Fence.Key(object, passage),
        toX = prepared.transferX,
        toY = prepared.transferY,
        toZ = toSquare:getZ(),
    }
    if body.faceThisObject then body:faceThisObject(object) end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(body, snapshot,
            tall and "PNC_ClimbFenceTall"
                or "PNC_LegacyClimbFenceStart", {
                sceneId = "native_fence_climb",
                leaseUntil = state.passageAction.finishAt,
                keepManagedUseless = true,
            })
    end
    Fence.HoldBody(body)
    state.fenceDebugPhase = nil
    state.fenceDebugTimerFallbackLogged = nil
    state.lastProgressAt = now
    logPassageEvent(
        snapshot,
        body,
        state,
        state.passageAction,
        "start",
        tall == true and "tall_fence" or "low_fence"
    )
    logState(snapshot, "native_fence_climb_start", describeBody(body))
    return true, "native_fence_climb"
end

Fence.StartClimb = startFenceClimb

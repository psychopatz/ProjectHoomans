--[[
    PNC Native Passage: window traversal action setup.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared

local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles
local PathInternal = PNC.PathService
    and PNC.PathService.Internal or nil
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl

local clearOwnedPath = Controller.ClearOwnedPath
local beginMovementLease = Controller.BeginMovementLease
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local WINDOW_SMASH_IMPACT_MS = Controller.WINDOW_SMASH_IMPACT_MS
local WINDOW_SMASH_FINISH_MS = Controller.WINDOW_SMASH_FINISH_MS
local logPassageEvent = Shared.LogPassageEvent

local Window = Passage.WindowInternal or {}
Passage.WindowInternal = Window
Window.CooldownMs = 900
Window.LandingBackoffMs = 2500

local function startWindowSmash(
    snapshot,
    body,
    state,
    object,
    now
)
    clearOwnedPath(body, state)
    if LiveBodyControl and LiveBodyControl.ResetNativeMovementState then
        LiveBodyControl.ResetNativeMovementState(body)
    end
    local key = "window_smash:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    state.passageAction = {
        kind = "window_smash",
        key = key,
        object = object,
        startedAt = now,
        impactAt = now + WINDOW_SMASH_IMPACT_MS,
        finishAt = now + WINDOW_SMASH_FINISH_MS,
        applied = false,
    }
    state.lastProgressAt = now
    if body.faceThisObject then
        body:faceThisObject(object)
    end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(
            body,
            snapshot,
            "PNC_WindowSmash",
            {
                sceneId = "native_window_smash",
                leaseUntil = now + WINDOW_SMASH_FINISH_MS,
                keepManagedUseless = false,
            }
        )
    elseif body.setBumpType then
        body:setBumpType("PNC_WindowSmash")
    end
    beginMovementLease(body, state, key, now)
    logPassageEvent(
        snapshot,
        body,
        state,
        state.passageAction,
        "start",
        "window_smash"
    )
    logState(snapshot, "native_window_smash_start", describeBody(body))
    return true, "native_window_smash"
end

local function resolveWindowDestination(body, object, passage)
    local actorSquare = body and body.getSquare
        and body:getSquare() or nil
    local destination = passage and passage.toSquare or nil
    local objectSquare
    local oppositeSquare
    if destination then return destination end
    if PathInternal and PathInternal.passageWindowDestination then
        return PathInternal.passageWindowDestination(object, actorSquare)
    end
    objectSquare = object and object.getSquare and object:getSquare() or nil
    oppositeSquare = object and object.getOppositeSquare
        and object:getOppositeSquare() or nil
    if actorSquare and objectSquare
        and actorSquare:getX() == objectSquare:getX()
        and actorSquare:getY() == objectSquare:getY()
        and actorSquare:getZ() == objectSquare:getZ()
    then
        return oppositeSquare
    end
    if actorSquare and oppositeSquare
        and actorSquare:getX() == oppositeSquare:getX()
        and actorSquare:getY() == oppositeSquare:getY()
        and actorSquare:getZ() == oppositeSquare:getZ()
    then
        return objectSquare
    end
    return nil
end

local function startWindowClimb(
    snapshot,
    body,
    state,
    object,
    passage,
    now
)
    local destination = resolveWindowDestination(body, object, passage)
    local profile
    local travelDuration
    local finishHold
    local finishAt
    local key
    if not destination then
        return false, "native_window_destination_unavailable"
    end
    profile = TraversalProfiles
        and TraversalProfiles.Resolve
        and TraversalProfiles.Resolve(
            "window_climb",
            {
                body = body,
                snapshot = snapshot,
                state = state,
                obstacle = object,
            },
            "default"
        ) or {}
    travelDuration = math.max(
        250,
        tonumber(profile.travelDurationMs) or 700
    )
    finishHold = math.max(120, tonumber(profile.finishHoldMs) or 320)
    finishAt = now + travelDuration + math.min(finishHold, 320)
    clearOwnedPath(body, state)
    if LiveBodyControl and LiveBodyControl.ResetNativeMovementState then
        LiveBodyControl.ResetNativeMovementState(body)
    end
    -- Vanilla ClimbThroughWindowState assumes a player BodyDamage object and
    -- can throw while entering or finishing on an IsoZombie carrier. Use the
    -- same PNC-owned bump/position contract as fence traversal instead.
    if LiveBodyControl and LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(body, state, now)
    end
    key = "window_climb:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    state.passageAction = {
        kind = "window_climb",
        key = key,
        object = object,
        fromSquare = body.getSquare and body:getSquare() or nil,
        toSquare = destination,
        startedAt = now,
        phase = "single",
        travelDurationMs = travelDuration,
        finishHoldMs = finishHold,
        finishAt = finishAt,
        fromX = body:getX(),
        fromY = body:getY(),
        fromZ = body:getZ(),
        toX = destination:getX() + 0.5,
        toY = destination:getY() + 0.5,
        toZ = destination:getZ(),
    }
    if body.faceThisObject then body:faceThisObject(object) end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(
            body,
            snapshot,
            profile.anim or "PNC_ClimbWindow",
            {
                sceneId = "native_window_climb",
                leaseUntil = finishAt,
                -- This is the MP native controller, not the SP fake-body
                -- traversal lane. Keep ActionContext ticking while the
                -- custom window clip is active.
                keepManagedUseless = false,
            }
        )
    elseif body.setBumpType then
        body:setBumpType(profile.anim or "PNC_ClimbWindow")
    end
    beginMovementLease(body, state, key, now)
    state.lastProgressAt = now
    state.forcedTraversalUntil = nil
    state.forcedTraversalState = nil
    state.forcedTraversalAction = nil
    state.requestKey = nil
    logPassageEvent(
        snapshot,
        body,
        state,
        state.passageAction,
        "start",
        "window_climb"
    )
    logState(snapshot, "native_window_climb_start", describeBody(body))
    return true, "native_window_climb"
end

Window.StartSmash = startWindowSmash
Window.ResolveDestination = resolveWindowDestination
Window.StartClimb = startWindowClimb

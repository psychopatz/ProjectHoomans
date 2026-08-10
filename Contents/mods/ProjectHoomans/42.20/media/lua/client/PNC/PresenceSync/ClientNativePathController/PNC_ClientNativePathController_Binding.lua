--[[
    PNC Client Native Path Controller: snapshot binding
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
Internal.NativePathController =
    Internal.NativePathController or {}
local Controller = Internal.NativePathController
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local ensureState = Controller.EnsureState
local buildGoal = Controller.BuildGoal
local requestKey = Controller.RequestKey
local hasBodyActionLock = Controller.HasBodyActionLock
local clearOwnedPath = Controller.ClearOwnedPath
local beginMovementLease = Controller.BeginMovementLease
local finishPassageBump = Controller.FinishPassageBump

function Internal.BindNativePathSnapshot(snapshot, body, now)
    if not body
        or not Core
        or not Core.IsClientOnly
        or Core.IsClientOnly() ~= true
    then
        return false
    end
    now = tonumber(now)
        or (Core.Now and Core.Now() or 0)
    local state = ensureState(body)
    local goal = buildGoal(snapshot, body)
    local key = goal and requestKey(snapshot, goal) or nil
    state.snapshot = snapshot
    state.lastSeenAt = now
    state.releasePending = false
    if state.passageAction
        and snapshot
        and snapshot.visualState
        and snapshot.visualState.attackActive == true
    then
        finishPassageBump(body)
        state.passageAction = nil
    end
    -- Presence visuals run immediately after this bind. Release a delegated
    -- PathFindBehavior2 route here, before PlayBump selects the attack clip;
    -- waiting for the later OnZombieUpdate callback lets pathfind locomotion
    -- swallow the first (and often only) melee animation edge.
    if not goal
        and state.owned == true
        and (
            hasBodyActionLock(body)
            or (
                snapshot
                and snapshot.visualState
                and snapshot.visualState.attackActive == true
            )
        )
    then
        clearOwnedPath(body, state)
    end
    if goal
        and (
            state.requestKey ~= key
            or state.owned == true
        )
    then
        beginMovementLease(body, state, key, now)
    elseif not goal
        and LiveBodyControl
        and LiveBodyControl.EndNativeMovementLease
    then
        LiveBodyControl.EndNativeMovementLease(
            body,
            state.leaseKey
        )
        state.leaseKey = nil
    end
    if (goal or hasBodyActionLock(body))
        and LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            false,
            true
        )
    elseif (goal or hasBodyActionLock(body))
        and body.setUseless
    then
        body:setUseless(false)
    end
    return goal ~= nil
end



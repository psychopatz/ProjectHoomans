--[[
    PNC Client Native Path Controller: zombie-update lifecycle
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
local buildGoal = Controller.BuildGoal
local hasBodyActionLock = Controller.HasBodyActionLock
local clearOwnedPath = Controller.ClearOwnedPath

function Internal.OnNativePathZombieUpdate(body)
    local state = body
        and Sync.NativePathStateByBody[body] or nil
    local snapshot = state and state.snapshot or nil
    local modData = body and body.getModData and body:getModData() or nil
    local actionState = LiveBodyControl
        and LiveBodyControl.GetActionContextStateName
        and LiveBodyControl.GetActionContextStateName(body) or ""
    if state and state.releasePending == true then
        clearOwnedPath(body, state)
        Sync.NativePathStateByBody[body] = nil
        return
    end
    if not snapshot then
        return
    end
    -- Recover a vanilla passage ActionContext that survived after the native
    -- controller lost its action record. A live PNC passage is protected by
    -- state.passageAction or its traversal bump lease and must be left alone.
    if LiveBodyControl
        and LiveBodyControl.ResetNativePassageActionContext
        and LiveBodyControl.IsNativePassageState
        and LiveBodyControl.IsNativePassageState(actionState)
        and not (state and state.passageAction)
        and not (
            modData
            and modData.PNC_BumpActionLease == true
            and LiveBodyControl.IsTraversalBumpType
            and LiveBodyControl.IsTraversalBumpType(
                modData.PNC_BumpRequestedType
            )
        )
    then
        if LiveBodyControl.ResetNativePassageActionContext(body)
            and Core
            and Core.LogWarn
        then
            Core.LogWarn(
                "[PNC][PATH] orphaned_passage_context_recovered"
                    .. " npc=" .. tostring(snapshot.id or "nil")
                    .. " action=" .. tostring(actionState)
                    .. " bump=" .. tostring(
                        modData and modData.PNC_BumpRequestedType or ""
                    )
            )
        end
    end
    -- Match Bandits' ManageActionState boundary on every zombie frame. The
    -- engine owns locomotion/traversal, but never target selection or zombie
    -- feeding behavior for a managed human body.
    if LiveBodyControl and LiveBodyControl.SuppressVanillaIntent then
        LiveBodyControl.SuppressVanillaIntent(
            body,
            buildGoal(snapshot, body) ~= nil
                or hasBodyActionLock(body)
        )
    end
    Internal.UpdateNativePathController(
        snapshot,
        body,
        Core and Core.Now and Core.Now() or 0
    )
    -- On MP clients this handler owns the native path lane. Run the same
    -- pre-tryThump guard after the PNC passage probe so a missed geometry
    -- match cannot fall through to IsoZombie.tryThump().
    if LiveBodyControl and LiveBodyControl.BlockVanillaPassage then
        LiveBodyControl.BlockVanillaPassage(
            body,
            state,
            Core and Core.Now and Core.Now() or 0
        )
    end
end

function Internal.ClearNativePathControllers()
    local body
    local state
    for body, state in pairs(
        Sync.NativePathStateByBody or {}
    ) do
        clearOwnedPath(body, state)
    end
    Sync.NativePathStateByBody = {}
end

function Internal.PruneNativePathControllers(now)
    now = tonumber(now)
        or (Core and Core.Now and Core.Now() or 0)
    local body
    local state
    for body, state in pairs(
        Sync.NativePathStateByBody or {}
    ) do
        if now - (tonumber(state.lastSeenAt) or 0) >= 500 then
            if state.owned == true then
                -- PathFindBehavior2 lifecycle changes stay in the zombie's
                -- update event, just like Bandits' Move.onComplete.
                state.snapshot = nil
                state.releasePending = true
            else
                Sync.NativePathStateByBody[body] = nil
            end
        end
    end
end

if Events and Events.OnZombieUpdate then
    if Sync.NativePathZombieUpdateHandler then
        Events.OnZombieUpdate.Remove(
            Sync.NativePathZombieUpdateHandler
        )
    end
    Sync.NativePathZombieUpdateHandler =
        Internal.OnNativePathZombieUpdate
    Events.OnZombieUpdate.Add(
        Sync.NativePathZombieUpdateHandler
    )
end

return Internal

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local ActorControl = PNC.ActorControl
local VANILLA_PASSAGE_GUARD_LOGGED = Internal.VANILLA_PASSAGE_GUARD_LOGGED
local passageMovementState = Internal.passageMovementState
local isClosedPassageDoor = Internal.isClosedPassageDoor
local openPassageDoorAhead = Internal.openPassageDoorAhead
local isClientState = Internal.isClientState

function LiveBodyControl.BlockVanillaPassage(zombie, lane, now)
    local modData
    local actionState
    local object
    local kind
    local behavior
    local fenceHazard
    if not zombie then return false end
    modData = zombie.getModData and zombie:getModData() or nil
    object, kind = LiveBodyControl.GetVanillaPassageAhead(zombie)
    if not object then
        VANILLA_PASSAGE_GUARD_LOGGED[zombie] = nil
        return false
    end
    --[[
        A climbable passage ahead is the exact geometry where vanilla reaches
        IsoZombie.tryThump() -> IsoGameCharacter.climbThroughWindow() this same
        frame. Two things must happen before that:

        Heavy hand items are stowed earlier in the zombie-update lane by
        ClearHeavyItemsForClimbAhead (client only, because the failing packet is
        client only). Here native movement is stopped: the original guard only
        did this for bodies already in a PNC passage state, so a shell whose
        action state was idle - right after a window smash or a
        rematerialization, for example - fell through to the player-only climb.
    ]]
    local climbable = kind == "window"
        or kind == "window_frame"
        or kind == "thumpable"
    fenceHazard = kind == "fence"
    -- A hoppable low door or fence is vaulted through the player-only
    -- ClimbOverFenceState, which throws for an IsoZombie. It must be treated as
    -- a hazard on both sides, not just on the client.
    local vaultHazard = kind == "door"
        and LiveBodyControl.IsHoppableLowDoor(object)
    local moving = LiveBodyControl.IsNativeMoving(zombie)
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if not passageMovementState(actionState)
        and not ((climbable and isClientState() and moving)
            or vaultHazard
            or fenceHazard)
    then
        return false
    end
    if kind == "door" then
        if vaultHazard then
            -- Fall through to the block below. Opening a hoppable low door
            -- would only create the vaultable state that throws, so the PNC
            -- action runtime owns this crossing instead.
        elseif isClosedPassageDoor(object) then
            -- Open a closed door the body is pressed against and let the
            -- vanilla path continue, instead of cancelling movement and leaving
            -- the body to re-request a path that the closed door keeps failing.
            if openPassageDoorAhead(zombie, object, now) then
                return false, kind
            end
        else
            -- An already open, non-vaultable door is not a blockage.
            return false, kind
        end
    end
    if modData
        and modData.PNC_BumpActionLease == true
        and LiveBodyControl.IsTraversalBumpType(
            modData.PNC_BumpRequestedType
        )
    then
        return false
    end
    behavior = zombie.getPathFindBehavior2
        and zombie:getPathFindBehavior2() or nil
    if behavior then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
    end
    if zombie.setPath2 then zombie:setPath2(nil) end
    Internal.clearVanillaIntent(zombie)
    if (climbable or vaultHazard or fenceHazard)
        and LiveBodyControl.ResetNativeMovementState
    then LiveBodyControl.ResetNativeMovementState(zombie) end
    if LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(zombie, lane, now)
    elseif zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if PNC.PerformanceScalingDiagnostics
        and PNC.PerformanceScalingDiagnostics.Increment
    then
        if climbable then
            pcall(PNC.PerformanceScalingDiagnostics.Increment,
                "LiveBodyControl.VanillaClimbBlocked")
        elseif vaultHazard then
            pcall(PNC.PerformanceScalingDiagnostics.Increment,
                "LiveBodyControl.VanillaVaultBlocked")
        elseif fenceHazard then
            pcall(PNC.PerformanceScalingDiagnostics.Increment,
                "LiveBodyControl.VanillaFenceBlocked")
        end
    end
    if not VANILLA_PASSAGE_GUARD_LOGGED[zombie]
        and PNC.Core
        and PNC.Core.LogWarn
    then
        VANILLA_PASSAGE_GUARD_LOGGED[zombie] = true
        PNC.Core.LogWarn(
            "[PNC][PATH] vanilla_passage_guard kind=" .. tostring(kind)
                .. " action=" .. tostring(actionState)
                .. " bump=" .. tostring(
                    modData and modData.PNC_BumpRequestedType or ""
                )
        )
    end
    return true, kind
end

-- Recover a stale vanilla passage through the exposed character state and
-- traversal variables. ActionContext itself is internal Java userdata and
-- cannot be indexed or mutated from Lua in Build 42.
